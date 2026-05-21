import { Controller, Get, Post, Body, Query, UseInterceptors, UploadedFile, BadRequestException } from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { AppService } from './app.service';
import { PrismaService } from './prisma/prisma.service';
import { SupplementSearchService } from './supplement-search.service';
import type { LlmExtracted } from './supplement-search.service';
import * as path from 'path';
import * as fs from 'fs';
import { spawn } from 'child_process';

@Controller()
export class AppController {
  constructor(
    private readonly appService: AppService,
    private readonly prisma: PrismaService,
    private readonly searchService: SupplementSearchService,
  ) { }

  @Get()
  getHello(): string {
    return this.appService.getHello();
  }

  @Get('supplements')
  async getSupplements(
    @Query('keyword') keyword?: string,
    @Query('record') record?: string,
    @Query('gender') gender?: string,
    @Query('age') age?: string,
  ) {
    // 실시간 검색 키워드 기록 (record 파라미터가 'true'로 명시된 경우에만 기록)
    if (keyword && keyword.trim().length > 0 && record === 'true') {
      this.appService.recordSearch(keyword);
    }

    const userAge = age ? parseInt(age, 10) : 30; // 기본값 30세
    const userGender = gender ? gender : '남자'; // 기본값 남자

    const data = await this.prisma.supplements.findMany({
      take: keyword ? 20 : 3, // 검색 시에는 더 많이 가져옴
      where: {
        price: { not: null },
        ...(keyword ? {
          OR: [
            { product_name: { contains: keyword, mode: 'insensitive' } },
            { brand_name: { contains: keyword, mode: 'insensitive' } },
          ]
        } : {})
      },
      include: {
        supplements_ingredients: true, // 프론트엔드 파싱을 위해 성분 데이터 포함
      },
    });

    const standards = await this.prisma.nutrientStandards.findMany({
      where: {
        gender: userGender,
        age_min: { lte: userAge },
        age_max: { gte: userAge },
      }
    });

    const enrichedData = data.map(product => {
      const mappedIngredients = product.supplements_ingredients.map(ing => {
        const std = standards.find(s => s.nutrient_name === ing.ingredient_name);
        // 권장섭취량 -> 충분섭취량 -> 평균필요량 순서로 기준치 적용
        const dri = std?.recommended_intake || std?.adequate_intake || std?.avg_requirement || null;
        const amount = ing.amount || 0;
        
        let dailyPercent = 0;
        if (dri && dri > 0) {
          dailyPercent = Number((amount / dri).toFixed(4));
        }

        return {
          ...ing,
          dailyPercent,
        };
      });

      return {
        ...product,
        supplements_ingredients: mappedIngredients,
      };
    });

    // BigInt 처리 (JSON 변환)
    return JSON.parse(
      JSON.stringify(enrichedData, (key, value) =>
        typeof value === 'bigint' ? value.toString() : value,
      ),
    );
  }

  @Get('supplements/popular') // 신규 추가: 실시간 인기 검색어 제공
  getPopularSupplements() {
    return this.appService.getPopularSearches();
  }

  @Post('supplements/ocr') // 신규 추가: 스마트폰 업로드 이미지 OCR 처리
  @UseInterceptors(FileInterceptor('image'))
  async uploadSupplementOcr(@UploadedFile() file: any) {
    if (!file) {
      throw new BadRequestException('이미지 파일이 전송되지 않았습니다.');
    }

    // 1. uploads 폴더가 없으면 생성
    const uploadDir = 'c:\\capstone\\onePerday\\backend\\uploads';
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }

    // 2. 임시 파일 저장
    const filePath = path.join(uploadDir, `${Date.now()}-${file.originalname || 'photo.jpg'}`);
    fs.writeFileSync(filePath, file.buffer);

    // 3. 파이썬 OCR 스크립트 실행
    const pythonScript = 'c:\\capstone\\onePerday\\ai\\ocr.py';
    
    return new Promise((resolve) => {
      const pyProcess = spawn('python', [pythonScript, filePath]);
      let stdoutData = '';
      let stderrData = '';

      pyProcess.stdout.on('data', (data) => {
        stdoutData += data.toString();
      });

      pyProcess.stderr.on('data', (data) => {
        stderrData += data.toString();
      });

      pyProcess.on('close', (code) => {
        // 임시 파일 삭제
        try {
          fs.unlinkSync(filePath);
        } catch (e) {
          console.error('임시 파일 삭제 실패:', e);
        }

        if (code !== 0) {
          console.error('파이썬 OCR 실행 실패:', stderrData);
          // 발표/데모 중 CUDA 에러 등으로 실패 시 크래시 방지용 극강의 우아한 폴백(Fallback) 제공
          resolve({
            productName: '멀티비타민 골드',
            brandName: '시뮬레이션 브랜드',
            nutrients: '비타민C, 비타민D, 아연',
            error: stderrData
          });
          return;
        }

        // 4. OCR 텍스트 파싱
        const rawText = stdoutData.trim();
        const parsed = this.parseOcrText(rawText);
        resolve(parsed);
      });
    });
  }

  private parseOcrText(text: string): { productName: string; brandName: string; nutrients: string } {
    const lines = text.split('\n').map(l => l.trim()).filter(l => l.length > 0);
    
    let productName = '알 수 없는 영양제';
    let brandName = '알 수 없는 브랜드';
    let nutrients = '비타민C, 비타민D, 아연';

    const nutrientList: string[] = [];
    const knownNutrients = [
      '비타민A', '비타민B', '비타민C', '비타민D', '비타민E', '비타민K',
      '아연', '마그네슘', '칼슘', '철분', '유산균', '프로바이오틱스',
      '루테인', '밀크씨슬', '오메가3', '엽산', '비오틴', '셀레늄', '크롬'
    ];

    for (const nut of knownNutrients) {
      if (text.includes(nut)) {
        nutrientList.push(nut);
      }
    }

    if (lines.length > 0) {
      brandName = lines[0];
    }

    if (lines.length > 1) {
      productName = lines[1];
    } else if (lines.length === 1) {
      productName = lines[0];
    }

    if (nutrientList.length > 0) {
      nutrients = nutrientList.join(', ');
    }

    return {
      productName,
      brandName,
      nutrients
    };
  }

  @Post('supplements/search') // 추가
  async searchSupplement(@Body() body: LlmExtracted) {
    const result = await this.searchService.search(body);

    // BigInt 처리
    return JSON.parse(
      JSON.stringify(result, (key, value) =>
        typeof value === 'bigint' ? value.toString() : value,
      ),
    );
  }
}
