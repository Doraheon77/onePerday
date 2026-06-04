import { Injectable, Logger } from '@nestjs/common';

interface GenerateOptions {
  temperature?: number;
  responseMimeType?: 'application/json' | 'text/plain';
}

interface GenerateGroundingOptions {
  temperature?: number;
  enableGrounding?: boolean;
  thinkingLevel?: 'minimal' | 'low' | 'medium' | 'high';
}

export interface GroundingChunk {
  web?: { title: string; uri: string };
}

export interface GroundingMetadata {
  webSearchQueries?: string[];
  groundingChunks?: GroundingChunk[];
}

export interface GeminiGroundedResult {
  text: string;
  groundingMetadata?: GroundingMetadata;
}

@Injectable()
export class GeminiService {
  private readonly logger = new Logger(GeminiService.name);

  // ────────────────────────────────────────────────────────
  // 기존 메서드 — 하위 호환 유지 (OCR 등 다른 호출 지점)
  // ────────────────────────────────────────────────────────
  async generateText(
    systemInstruction: string,
    userPrompt: string,
    options: GenerateOptions = {},
  ): Promise<string> {
    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) {
      throw new Error('GEMINI_API_KEY is not configured.');
    }

    const model = process.env.GEMINI_MODEL ?? 'gemini-3.5-flash';
    const url =
      `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent` +
      `?key=${apiKey}`;

    const response = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        systemInstruction: {
          parts: [{ text: systemInstruction }],
        },
        contents: [
          {
            role: 'user',
            parts: [{ text: userPrompt }],
          },
        ],
        generationConfig: {
          temperature: options.temperature ?? 0.2,
          ...(options.responseMimeType
            ? { responseMimeType: options.responseMimeType }
            : {}),
        },
      }),
    });

    if (!response.ok) {
      const body = await response.text();
      this.logger.error(`Gemini request failed: ${response.status} ${body}`);
      throw new Error(`Gemini request failed with status ${response.status}`);
    }

    const json = await response.json();
    const parts = json?.candidates?.[0]?.content?.parts ?? [];
    const text = parts
      .map((part: { text?: string }) => part.text ?? '')
      .join('\n')
      .trim();

    if (!text) {
      throw new Error('Gemini returned an empty response.');
    }

    return text;
  }

  // ────────────────────────────────────────────────────────
  // 그라운딩 + 추론 강화 메서드 — 챗봇 전용
  // Google Search 그라운딩, thinkingLevel 설정 포함
  // ────────────────────────────────────────────────────────
  async generateTextWithGrounding(
    systemInstruction: string,
    userPrompt: string,
    options: GenerateGroundingOptions = {},
  ): Promise<GeminiGroundedResult> {
    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) {
      throw new Error('GEMINI_API_KEY is not configured.');
    }

    const model = process.env.GEMINI_MODEL ?? 'gemini-3.5-flash';
    const url =
      `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent` +
      `?key=${apiKey}`;

    const enableGrounding = options.enableGrounding ?? true;
    const thinkingLevel = options.thinkingLevel ?? 'high';

    const requestBody: Record<string, unknown> = {
      systemInstruction: {
        parts: [{ text: systemInstruction }],
      },
      contents: [
        {
          role: 'user',
          parts: [{ text: userPrompt }],
        },
      ],
      generationConfig: {
        temperature: options.temperature ?? 0.3,
        thinkingConfig: {
          thinkingLevel,
        },
      },
    };

    // Google Search 그라운딩 활성화
    if (enableGrounding) {
      requestBody.tools = [{ google_search: {} }];
    }

    this.logger.debug(
      `[Gemini] Grounding=${enableGrounding}, ThinkingLevel=${thinkingLevel}`,
    );

    const response = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(requestBody),
    });

    if (!response.ok) {
      const body = await response.text();
      this.logger.error(`Gemini request failed: ${response.status} ${body}`);
      throw new Error(`Gemini request failed with status ${response.status}`);
    }

    const json = await response.json();
    const candidate = json?.candidates?.[0];

    // 텍스트 추출
    const parts = candidate?.content?.parts ?? [];
    const text = parts
      .map((part: { text?: string }) => part.text ?? '')
      .join('\n')
      .trim();

    if (!text) {
      throw new Error('Gemini returned an empty response.');
    }

    // 그라운딩 메타데이터 추출
    const rawGrounding = candidate?.groundingMetadata;
    const groundingMetadata: GroundingMetadata | undefined = rawGrounding
      ? {
          webSearchQueries: rawGrounding.webSearchQueries ?? [],
          groundingChunks: (rawGrounding.groundingChunks ?? []).map(
            (chunk: { web?: { title?: string; uri?: string } }) => ({
              web: chunk.web
                ? {
                    title: chunk.web.title ?? '',
                    uri: chunk.web.uri ?? '',
                  }
                : undefined,
            }),
          ),
        }
      : undefined;

    if (groundingMetadata?.groundingChunks?.length) {
      this.logger.debug(
        `[Gemini] Grounding sources: ${groundingMetadata.groundingChunks.length} chunks`,
      );
    }

    return { text, groundingMetadata };
  }

  parseJsonObject<T extends Record<string, unknown>>(text: string): T {
    const trimmed = text.trim();
    const fenced = trimmed.match(/```(?:json)?\s*([\s\S]*?)```/i);
    const candidate = fenced?.[1] ?? trimmed;
    const jsonStart = candidate.indexOf('{');
    const jsonEnd = candidate.lastIndexOf('}');

    if (jsonStart === -1 || jsonEnd === -1 || jsonEnd < jsonStart) {
      throw new Error('No JSON object found in Gemini response.');
    }

    return JSON.parse(candidate.slice(jsonStart, jsonEnd + 1)) as T;
  }
}
