import { Test, TestingModule } from '@nestjs/testing';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { PrismaService } from './prisma/prisma.service';
import { SupplementSearchService } from './supplement-search.service';
import { SupabaseService } from './supabase/supabase.service';
import { LabelRecognitionService } from './label-recognition/label-recognition.service';
import { describe, beforeEach, it, expect, jest } from '@jest/globals';
import { BadRequestException } from '@nestjs/common';

describe('AppController', () => {
  let appController: AppController;
  let mockLabelRecognitionService: jest.Mocked<LabelRecognitionService>;

  beforeEach(async () => {
    mockLabelRecognitionService = {
      analyze: jest.fn(),
    } as any;

    const app: TestingModule = await Test.createTestingModule({
      controllers: [AppController],
      providers: [
        AppService,
        {
          provide: PrismaService,
          useValue: {},
        },
        {
          provide: SupplementSearchService,
          useValue: {},
        },
        {
          provide: SupabaseService,
          useValue: {},
        },
        {
          provide: LabelRecognitionService,
          useValue: mockLabelRecognitionService,
        },
      ],
    }).compile();

    appController = app.get<AppController>(AppController);
  });

  describe('root', () => {
    it('should return "OnePerDay!"', () => {
      expect(appController.getHello()).toBe('OnePerDay!');
    });
  });

  describe('uploadSupplementOcr', () => {
    it('should throw BadRequestException if file is not provided', async () => {
      await expect(appController.uploadSupplementOcr(null)).rejects.toThrow(
        BadRequestException,
      );
    });

    it('should successfully map structured result when matching supplement is found', async () => {
      const mockFile = { buffer: Buffer.from('test') };
      const mockResult = {
        success: true,
        structured: {
          productName: '원래 제품명',
          brandName: '원래 브랜드',
          nutrients: [{ name: '비타민C' }],
        },
        match: {
          status: 'found',
          data: {
            id: 99,
            product_name: '매칭된 제품명',
            brand_name: '매칭된 브랜드',
            image_url: 'https://images.com/prod.jpg',
            ingredients: [
              { ingredient_name: '비타민C' },
              { ingredient_name: '아연' }
            ]
          }
        }
      };

      mockLabelRecognitionService.analyze.mockResolvedValue(mockResult as any);

      const response = await appController.uploadSupplementOcr(mockFile);

      expect(response).toEqual({
        productName: '매칭된 제품명',
        brandName: '매칭된 브랜드',
        nutrients: '비타민C, 아연',
        imageUrl: 'https://images.com/prod.jpg',
        id: '99',
        supplementId: '99',
      });
    });

    it('should return structured OCR data with fallback if database match is not found', async () => {
      const mockFile = { buffer: Buffer.from('test') };
      const mockResult = {
        success: true,
        structured: {
          productName: '인식된 제품명',
          brandName: '인식된 브랜드',
          nutrients: [
            { name: '오메가3' },
            { name: '루테인' }
          ],
        },
        match: {
          status: 'not_found',
        }
      };

      mockLabelRecognitionService.analyze.mockResolvedValue(mockResult as any);

      const response = await appController.uploadSupplementOcr(mockFile);

      expect(response).toEqual({
        productName: '인식된 제품명',
        brandName: '인식된 브랜드',
        nutrients: '오메가3, 루테인',
        imageUrl: undefined,
        id: undefined,
        supplementId: undefined,
      });
    });

    it('should return predefined recovery fallback data when pipeline throws an error', async () => {
      const mockFile = { buffer: Buffer.from('test') };
      mockLabelRecognitionService.analyze.mockRejectedValue(new Error('API Timeout'));

      const response = await appController.uploadSupplementOcr(mockFile);

      expect(response).toEqual({
        productName: '멀티비타민 골드',
        brandName: '시뮬레이션 브랜드',
        nutrients: '비타민C, 비타민D, 아연',
        error: 'API Timeout',
      });
    });
  });
});
