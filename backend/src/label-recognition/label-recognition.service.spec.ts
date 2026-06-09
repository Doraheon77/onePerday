import { Test, TestingModule } from '@nestjs/testing';
import { LabelRecognitionService } from './label-recognition.service';
import { GeminiService } from '../ai/gemini.service';
import { SupplementSearchService } from '../supplement-search.service';
import { describe, beforeEach, afterEach, it, expect, jest } from '@jest/globals';
import * as path from 'path';
import { promises as fs } from 'fs';

describe('LabelRecognitionService', () => {
  let service: LabelRecognitionService;
  let mockGeminiService: jest.Mocked<GeminiService>;
  let mockSupplementSearchService: jest.Mocked<SupplementSearchService>;
  let originalFetch: typeof fetch;

  beforeEach(async () => {
    mockGeminiService = {
      generateText: jest.fn(),
      parseJsonObject: jest.fn(),
    } as any;

    mockSupplementSearchService = {
      searchTopOne: jest.fn(),
    } as any;

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        LabelRecognitionService,
        { provide: GeminiService, useValue: mockGeminiService },
        { provide: SupplementSearchService, useValue: mockSupplementSearchService },
      ],
    }).compile();

    service = module.get<LabelRecognitionService>(LabelRecognitionService);

    // Save and mock global fetch
    originalFetch = global.fetch;
    global.fetch = jest.fn() as any;

    // Set mock env variables
    process.env.CLOVA_OCR_INVOKE_URL = 'https://mock-clova-ocr.apigw.ntruss.com/custom/v1/123/abc/general';
    process.env.CLOVA_OCR_SECRET = 'mock-clova-secret-key';
  });

  afterEach(() => {
    global.fetch = originalFetch;
    delete process.env.CLOVA_OCR_INVOKE_URL;
    delete process.env.CLOVA_OCR_SECRET;
  });

  describe('runClovaOcr', () => {
    it('should correctly format request and call CLOVA OCR API', async () => {
      const mockImagePath = path.join(__dirname, 'test-image.jpg');
      const mockImageBuffer = Buffer.from('mock-image-bytes');

      // Mock fs.readFile
      jest.spyOn(fs, 'readFile').mockResolvedValue(mockImageBuffer);

      // Mock fetch response for CLOVA OCR
      const mockClovaResponse = {
        images: [
          {
            fields: [
              { inferText: '센트룸' },
              { inferText: '멀티' },
              { inferText: '구미' }
            ]
          }
        ]
      };

      (global.fetch as any).mockResolvedValue({
        ok: true,
        json: async () => mockClovaResponse,
      });

      // Call private method using any casting
      const result = await (service as any).runClovaOcr(mockImagePath);

      // Verify fs.readFile was called with image path
      expect(fs.readFile).toHaveBeenCalledWith(mockImagePath);

      // Verify fetch was called with correct parameters
      expect(global.fetch).toHaveBeenCalledWith(
        process.env.CLOVA_OCR_INVOKE_URL,
        expect.objectContaining({
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'X-OCR-SECRET': process.env.CLOVA_OCR_SECRET,
          },
        })
      );

      // Verify payload body
      const fetchCalls = (global.fetch as any).mock.calls;
      const requestBody = JSON.parse(fetchCalls[0][1].body);

      expect(requestBody.version).toBe('V2');
      expect(requestBody.requestId).toBeDefined();
      expect(requestBody.timestamp).toBeDefined();
      expect(requestBody.images[0].format).toBe('jpg');
      expect(requestBody.images[0].data).toBe(mockImageBuffer.toString('base64'));

      // Verify response parsing
      expect(result.text).toBe('센트룸\n멀티\n구미');
      expect(result.fields).toEqual(['센트룸', '멀티', '구미']);
    });

    it('should throw error when CLOVA_OCR API response is not ok', async () => {
      const mockImagePath = path.join(__dirname, 'test-image.jpg');
      jest.spyOn(fs, 'readFile').mockResolvedValue(Buffer.from('bytes'));

      (global.fetch as any).mockResolvedValue({
        ok: false,
        status: 500,
        text: async () => 'Internal Server Error',
      });

      await expect((service as any).runClovaOcr(mockImagePath)).rejects.toThrow(
        'CLOVA OCR failed with status 500'
      );
    });
  });

  describe('structureWithGemini', () => {
    it('should construct prompt and return structured object', async () => {
      const ocrText = '센트룸 멀티비타민 브랜드: 센트룸 성분: 비타민C, 비타민D';
      const geminiResponseText = JSON.stringify({
        productName: '센트룸 멀티비타민',
        brandName: '센트룸',
        nutrients: [
          { name: '비타민C', amount: 100, unit: 'mg' },
          { name: '비타민D', amount: 400, unit: 'IU' }
        ],
        rawTextSummary: '센트룸 멀티비타민 제품'
      });

      mockGeminiService.generateText.mockResolvedValue(geminiResponseText);
      mockGeminiService.parseJsonObject.mockReturnValue(JSON.parse(geminiResponseText));

      const result = await (service as any).structureWithGemini(ocrText);

      expect(mockGeminiService.generateText).toHaveBeenCalledWith(
        expect.stringContaining('영양제 라벨 OCR 텍스트를 제품 검색용 JSON으로 정리하는 파서'),
        expect.stringContaining(ocrText),
        expect.objectContaining({
          temperature: 0.0,
          responseMimeType: 'application/json',
        })
      );

      expect(result).toEqual({
        productName: '센트룸 멀티비타민',
        brandName: '센트룸',
        nutrients: [
          { name: '비타민C', amount: 100, unit: 'mg' },
          { name: '비타민D', amount: 400, unit: 'IU' }
        ],
        rawTextSummary: '센트룸 멀티비타민 제품'
      });
    });
  });
});
