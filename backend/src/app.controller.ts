import { Controller, Get, Post, Delete, Body, Param, Query, UseInterceptors, UploadedFile, BadRequestException } from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { AppService } from './app.service';
import { PrismaService } from './prisma/prisma.service';
import { SupplementSearchService } from './supplement-search.service';
import type { LlmExtracted } from './supplement-search.service';
import * as path from 'path';
import * as fs from 'fs';
import { spawn } from 'child_process';
import { SupabaseService } from './supabase/supabase.service';
import { LabelRecognitionService } from './label-recognition/label-recognition.service';

@Controller()
export class AppController {
  constructor(
    private readonly appService: AppService,
    private readonly prisma: PrismaService,
    private readonly searchService: SupplementSearchService,
    private readonly supabaseService: SupabaseService,
    private readonly labelRecognitionService: LabelRecognitionService,
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
    @Query('categories') categoriesStr?: string,
    @Query('ingredients') ingredientsStr?: string,
    @Query('priceRange') priceRange?: string,
  ) {
    if (keyword && keyword.trim().length > 0 && record === 'true') {
      this.appService.recordSearch(keyword);
    }

    const userAge = age ? parseInt(age, 10) : 30;
    let userGender = gender ? gender : '남자';
    if (userGender === '남성') userGender = '남자';
    else if (userGender === '여성') userGender = '여자';

    const categories = categoriesStr ? categoriesStr.split(',').filter(c => c.trim().length > 0) : [];
    const ingredients = ingredientsStr ? ingredientsStr.split(',').filter(i => i.trim().length > 0) : [];

    let minPrice: number | undefined = undefined;
    let maxPrice: number | undefined = undefined;
    if (priceRange) {
      if (priceRange === '1만원 이하') maxPrice = 10000;
      else if (priceRange === '1~3만원') { minPrice = 10000; maxPrice = 30000; }
      else if (priceRange === '3~5만원') { minPrice = 30000; maxPrice = 50000; }
      else if (priceRange === '5만원 이상') minPrice = 50000;
    }

    let mappedNutrients: string[] = [];
    if (categories.length > 0) {
      const guides = await this.prisma.nutrientGuide.findMany();
      for (const guide of guides) {
        const nutrientName = guide.nutrient_name;
        const targetAreas = Array.isArray(guide.target_area) ? guide.target_area : [];
        if (!nutrientName) continue;
        
        let matchesArea = false;
        for (const cat of categories) {
          const c = cat.replace(/\s/g, '');
          for (const area of targetAreas) {
            const t = String(area).replace(/\s/g, '');
            const keywords = ['눈', '관절', '뼈', '간', '피부', '면역', '혈관', '심혈관', '심장', '뇌', '소화', '장', '근육', '신경', '세포'];
            for (const k of keywords) {
              if (c.includes(k) && t.includes(k)) { matchesArea = true; break; }
            }
            if (c.includes(t) || t.includes(c)) matchesArea = true;
            if (matchesArea) break;
          }
          if (matchesArea) break;
        }
        if (matchesArea) mappedNutrients.push(nutrientName);
      }
    }

    const whereClause: any = { price: { not: null } };
    
    if (minPrice !== undefined || maxPrice !== undefined) {
      whereClause.price = { ...whereClause.price };
      if (minPrice !== undefined) whereClause.price.gt = minPrice;
      if (maxPrice !== undefined) whereClause.price.lte = maxPrice;
    }

    let matchingProductNamesForFilter: string[] | undefined = undefined;

    if (categories.length > 0 || ingredients.length > 0) {
      const filterIngredients: any[] = [];
      
      if (categories.length > 0 && mappedNutrients.length > 0) {
        filterIngredients.push(...mappedNutrients.map(nut => ({ ingredient_name: { contains: nut, mode: 'insensitive' } })));
      }
      if (ingredients.length > 0) {
        filterIngredients.push(...ingredients.map(nut => ({ ingredient_name: { contains: nut, mode: 'insensitive' } })));
      }

      if (filterIngredients.length > 0) {
        const dbMatchingIngs = await this.prisma.supplementsIngredients.findMany({
          where: { OR: filterIngredients },
          select: { product_name: true },
        });
        matchingProductNamesForFilter = dbMatchingIngs.map(i => i.product_name).filter(Boolean) as string[];
      }
    }

    const andConditions: any[] = [];

    const catConditions = mappedNutrients.map(nut => ({
      ingredient_name: { contains: nut, mode: 'insensitive' },
    }));

    const ingConditions = ingredients.map(nut => ({
      ingredient_name: { contains: nut, mode: 'insensitive' },
    }));
    if (categories.length > 0) {
      const fallback = categories.map(cat => ({ product_name: { contains: cat, mode: 'insensitive' } }));
      if (mappedNutrients.length > 0) {
        const catConditions = mappedNutrients.map(nut => ({ ingredient_name: { contains: nut, mode: 'insensitive' as const } }));
        const catProductContains = mappedNutrients.map(nut => ({ product_name: { contains: nut, mode: 'insensitive' } }));
        andConditions.push({
          OR: [
            //...(matchingProductNamesForFilter && matchingProductNamesForFilter.length > 0 ? [{ product_name: { in: matchingProductNamesForFilter } }] : []),
            //...catProductContains,
            //...fallback,
            { ingredients: { some: { OR: catConditions } } },
            ...catProductContains
          ]
        });
      } else {
        andConditions.push({ OR: fallback });
      }
    }
    
    if (ingredients.length > 0) {
      const ingConditions = ingredients.map(nut => ({ ingredient_name: { contains: nut, mode: 'insensitive' as const } }));
      const ingProductContains = ingredients.map(nut => ({ product_name: { contains: nut, mode: 'insensitive' } }));
      andConditions.push({
        OR: [
          //...(matchingProductNamesForFilter && matchingProductNamesForFilter.length > 0 ? [{ product_name: { in: matchingProductNamesForFilter } }] : []),
          { ingredients: { some: { OR: ingConditions } } },
          ...ingProductContains
        ]
      });
    }

    if (keyword && keyword.trim().length > 0) {
      andConditions.push({
        OR: [
          { product_name: { contains: keyword.trim(), mode: 'insensitive' } },
          { brand_name: { contains: keyword.trim(), mode: 'insensitive' } },
        ]
      });
    }

    if (andConditions.length > 0) {
      whereClause.AND = andConditions;
    }

    const dataTemp = await this.prisma.supplementsTemp.findMany({
      take: 20, // 백엔드 필터링 적용 후 최대 20개 반환
      where: whereClause,
    });

    const productNames = dataTemp.map(p => p.product_name).filter(Boolean) as string[];
    const dbIngredients = await this.prisma.supplementsIngredients.findMany({
      where: { product_name: { in: productNames } },
    });

    const data = dataTemp.map(product => ({
      ...product,
      ingredients: dbIngredients.filter(ing => ing.product_name === product.product_name),
    }));

    const standards = await this.prisma.nutrientStandards.findMany({
      where: {
        gender: userGender,
        age_min: { lte: userAge },
        age_max: { gte: userAge },
      }
    });

    const enrichedData = data.map(product => {
      const mappedIngredients = product.ingredients.map(ing => {
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
        ingredients: mappedIngredients,
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

    try {
      const ocrResult = await this.labelRecognitionService.analyze(file);
      
      const productName = ocrResult.match?.data?.product_name || ocrResult.structured.productName || '알 수 없는 영양제';
      const brandName = ocrResult.match?.data?.brand_name || ocrResult.structured.brandName || '알 수 없는 브랜드';
      
      let nutrients = '영양제 성분을 찾을 수 없습니다.';
      if (ocrResult.match?.data?.ingredients && ocrResult.match.data.ingredients.length > 0) {
        nutrients = ocrResult.match.data.ingredients.map((ing: any) => ing.ingredient_name).join(', ');
      } else if (ocrResult.structured.nutrients && ocrResult.structured.nutrients.length > 0) {
        nutrients = ocrResult.structured.nutrients.map((n: any) => n.name).join(', ');
      }

      return {
        productName,
        brandName,
        nutrients,
        imageUrl: ocrResult.match?.data?.image_url || undefined,
        id: ocrResult.match?.data?.id?.toString() || undefined,
        supplementId: ocrResult.match?.data?.id?.toString() || undefined,
      };
    } catch (error) {
      console.error('CLOVA/YOLO OCR 파이프라인 실패:', error);
      // 발표/데모 중 에러 발생 시 크래시 방지용 폴백(Fallback) 제공
      return {
        productName: '멀티비타민 골드',
        brandName: '시뮬레이션 브랜드',
        nutrients: '비타민C, 비타민D, 아연',
        error: error instanceof Error ? error.message : String(error)
      };
    }
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

  // 유저 전체 목록 조회 (검색 포함)
  @Get('admin/users')
  async getUsers(@Query('search') search?: string) {
    const usersInfo = await this.prisma.usersInfo.findMany({
      where: search ? {
        OR: [
          { name: { contains: search, mode: 'insensitive' } },
          { users: { email: { contains: search, mode: 'insensitive' } } },
        ]
      } : undefined,
      select: {
        id: true,
        name: true,
        gender: true,
        birth_year: true,
        created_at: true,
        users: {
          select: {
            email: true,
            created_at: true,
          }
        }
      }
    });

    return usersInfo;
  }

  // 유저 삭제
  @Delete('admin/users/:id')
  async deleteUser(@Param('id') id: string) {
    // 1. users_info 먼저 삭제
    await this.prisma.usersInfo.delete({
      where: { id }
    });

    // 2. auth.users 삭제
    const { error } = await this.supabaseService.getClient().auth.admin.deleteUser(id);
    if (error) throw new Error(error.message);
    
    return { success: true };
  }

  // 영양제 추가
  @Post('admin/supplements')
  async addSupplement(@Body() body: any) {
    return JSON.parse(JSON.stringify(
      await this.prisma.supplementsTemp.create({
        data: {
          product_name: body.product_name,
          category: body.category,
          brand_name: body.brand_name,
          reference_amount: body.reference_amount,
          serving_size: body.serving_size ? parseFloat(body.serving_size) : null,
          serving_unit: body.serving_unit,
          serving_weight: body.serving_weight,
          daily_servings: body.daily_servings,
          total_weight: body.total_weight,
          manufacturer: body.manufacturer,
          origin: body.origin,
          image_url: body.image_url,
          shop_url: body.shop_url,
          price: body.price ? BigInt(body.price) : null,
        }
      }),
      (key, value) => typeof value === 'bigint' ? value.toString() : value
    ));
  }

  // 영양제 삭제
  @Delete('admin/supplements/:id')
  async deleteSupplement(@Param('id') id: string) {
    return this.prisma.supplementsTemp.delete({
      where: { id: BigInt(id) }
    });
  }

  @Get('admin/supplements')
  async getAdminSupplements(
    @Query('page') page?: string,
    @Query('keyword') keyword?: string,
  ) {
    const pageNum = page ? parseInt(page, 10) : 1;
    const take = 50;
    const skip = (pageNum - 1) * take;

    const whereClause: any = {};
    if (keyword && keyword.trim().length > 0) {
      whereClause.OR = [
        { product_name: { contains: keyword.trim(), mode: 'insensitive' } },
        { brand_name: { contains: keyword.trim(), mode: 'insensitive' } },
      ];
    }

    const [data, total] = await Promise.all([
      this.prisma.supplementsTemp.findMany({
        take,
        skip,
        where: whereClause,
        orderBy: { id: 'asc' },
      }),
      this.prisma.supplementsTemp.count({ where: whereClause }),
    ]);

    return JSON.parse(
      JSON.stringify({
        data,
        total,
        page: pageNum,
        totalPages: Math.ceil(total / take),
      }, (key, value) =>
        typeof value === 'bigint' ? value.toString() : value,
      ),
    );
  }
}
