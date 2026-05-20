import { Injectable, Logger } from '@nestjs/common';
import { randomUUID } from 'crypto';
import { spawn } from 'child_process';
import { promises as fs } from 'fs';
import * as os from 'os';
import * as path from 'path';
import { GeminiService } from '../ai/gemini.service';
import { SupplementSearchService } from '../supplement-search.service';

interface YoloCropResult {
  success: boolean;
  cropPath?: string;
  confidence?: number;
  box?: number[];
  error?: string;
}

interface ClovaOcrResult {
  text: string;
  fields: string[];
}

interface StructuredLabel {
  productName: string;
  brandName?: string;
  nutrients?: { name: string; amount?: number; unit?: string }[];
  rawTextSummary?: string;
}

@Injectable()
export class LabelRecognitionService {
  private readonly logger = new Logger(LabelRecognitionService.name);

  constructor(
    private readonly geminiService: GeminiService,
    private readonly supplementSearchService: SupplementSearchService,
  ) {}

  async analyze(file: any) {
    const workDir = await fs.mkdtemp(path.join(os.tmpdir(), 'opd-label-'));
    const ext = this.getImageExtension(file.originalname, file.mimetype);
    const inputPath = path.join(workDir, `input.${ext}`);

    try {
      await fs.writeFile(inputPath, file.buffer);

      const yolo = await this.cropWithYolo(inputPath, workDir);
      if (!yolo.success || !yolo.cropPath) {
        throw new Error(yolo.error ?? 'YOLO 라벨 검출에 실패했습니다.');
      }

      const ocr = await this.runClovaOcr(yolo.cropPath);
      if (!ocr.text.trim()) {
        throw new Error('CLOVA OCR이 라벨 텍스트를 추출하지 못했습니다.');
      }

      const structured = await this.structureWithGemini(ocr.text);
      const match = await this.supplementSearchService.searchTopOne({
        product_name: structured.productName,
        brand_name: structured.brandName,
      });

      return {
        success: true,
        yolo: {
          confidence: yolo.confidence,
          box: yolo.box,
        },
        ocrText: ocr.text,
        structured,
        match,
      };
    } finally {
      if (process.env.KEEP_LABEL_PIPELINE_FILES !== 'true') {
        await fs.rm(workDir, { recursive: true, force: true });
      }
    }
  }

  private getImageExtension(originalName?: string, mimetype?: string) {
    const fromName = path.extname(originalName ?? '').replace('.', '');
    if (fromName) return fromName.toLowerCase() === 'jpeg' ? 'jpg' : fromName;
    if (mimetype?.includes('png')) return 'png';
    if (mimetype?.includes('webp')) return 'webp';
    return 'jpg';
  }

  private async cropWithYolo(
    inputPath: string,
    workDir: string,
  ): Promise<YoloCropResult> {
    const pythonBin = process.env.PYTHON_BIN ?? 'python';
    const modelPath =
      process.env.YOLO_MODEL_PATH ??
      path.resolve(
        process.cwd(),
        '..',
        '..',
        'onePerday-Feature-YOLO-SJ',
        'weights',
        'best.pt',
      );
    const scriptPath = path.resolve(process.cwd(), 'scripts', 'crop_label.py');

    await fs.access(scriptPath);
    await fs.access(modelPath);

    return new Promise((resolve, reject) => {
      const child = spawn(pythonBin, [scriptPath, modelPath, inputPath, workDir], {
        env: process.env,
        windowsHide: true,
      });

      let stdout = '';
      let stderr = '';

      child.stdout.on('data', (chunk) => {
        stdout += chunk.toString();
      });
      child.stderr.on('data', (chunk) => {
        stderr += chunk.toString();
      });
      child.on('error', reject);
      child.on('close', (code) => {
        if (code !== 0) {
          this.logger.error(`YOLO crop failed: ${stderr || stdout}`);
          reject(new Error(`YOLO crop failed with code ${code}`));
          return;
        }

        try {
          resolve(JSON.parse(stdout.trim()) as YoloCropResult);
        } catch (error) {
          reject(
            new Error(
              `YOLO crop returned invalid JSON: ${String(error)} ${stdout}`,
            ),
          );
        }
      });
    });
  }

  private async runClovaOcr(imagePath: string): Promise<ClovaOcrResult> {
    const invokeUrl = process.env.CLOVA_OCR_INVOKE_URL;
    const secret = process.env.CLOVA_OCR_SECRET;

    if (!invokeUrl || !secret) {
      throw new Error(
        'CLOVA_OCR_INVOKE_URL 또는 CLOVA_OCR_SECRET이 설정되지 않았습니다.',
      );
    }

    const ext = path.extname(imagePath).replace('.', '') || 'jpg';
    const imageData = await fs.readFile(imagePath);
    const response = await fetch(invokeUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-OCR-SECRET': secret,
      },
      body: JSON.stringify({
        version: 'V2',
        requestId: randomUUID(),
        timestamp: Date.now(),
        images: [
          {
            format: ext === 'jpg' ? 'jpg' : ext,
            name: path.basename(imagePath, path.extname(imagePath)),
            data: imageData.toString('base64'),
          },
        ],
      }),
    });

    if (!response.ok) {
      const body = await response.text();
      this.logger.error(`CLOVA OCR failed: ${response.status} ${body}`);
      throw new Error(`CLOVA OCR failed with status ${response.status}`);
    }

    const json = await response.json();
    const fields =
      json?.images
        ?.flatMap((image: { fields?: { inferText?: string }[] }) =>
          image.fields ?? [],
        )
        .map((field: { inferText?: string }) => field.inferText?.trim())
        .filter((text: string | undefined): text is string => Boolean(text)) ??
      [];

    return {
      text: fields.join('\n'),
      fields,
    };
  }

  private async structureWithGemini(ocrText: string): Promise<StructuredLabel> {
    const systemInstruction = [
      '당신은 영양제 라벨 OCR 텍스트를 제품 검색용 JSON으로 정리하는 파서입니다.',
      '반드시 JSON 객체만 반환하세요.',
      '제품명은 DB 검색에 사용할 수 있게 가장 가능성 높은 한글/영문 제품명을 선택합니다.',
      '성분은 라벨에서 읽힌 주요 영양성분만 배열로 정리합니다.',
    ].join('\n');

    const prompt = [
      '다음 OCR 텍스트에서 영양제 정보를 구조화하세요.',
      '',
      ocrText,
      '',
      '반환 형식:',
      '{"productName":"", "brandName":"", "nutrients":[{"name":"","amount":0,"unit":""}], "rawTextSummary":""}',
    ].join('\n');

    const text = await this.geminiService.generateText(systemInstruction, prompt, {
      temperature: 0.0,
      responseMimeType: 'application/json',
    });
    const parsed =
      this.geminiService.parseJsonObject<Record<string, unknown>>(text);

    return {
      productName: String(parsed.productName ?? '').trim(),
      brandName: parsed.brandName ? String(parsed.brandName).trim() : undefined,
      nutrients: Array.isArray(parsed.nutrients)
        ? parsed.nutrients.map((item) => {
            const nutrient = item as Record<string, unknown>;
            return {
              name: String(nutrient.name ?? '').trim(),
              amount:
                typeof nutrient.amount === 'number'
                  ? nutrient.amount
                  : Number(nutrient.amount) || undefined,
              unit: nutrient.unit ? String(nutrient.unit).trim() : undefined,
            };
          })
        : [],
      rawTextSummary: parsed.rawTextSummary
        ? String(parsed.rawTextSummary).trim()
        : undefined,
    };
  }
}
