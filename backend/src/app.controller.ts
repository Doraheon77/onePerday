import { Controller, Get, Post, Delete, Body, Param, Query, Patch, UseInterceptors, UploadedFile, BadRequestException } from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { AppService } from './app.service';
import { PrismaService } from './prisma/prisma.service';
import { SupplementSearchService } from './supplement-search.service';
import type { LlmExtracted } from './supplement-search.service';
import * as path from 'path';
import * as fs from 'fs';
import { spawn } from 'child_process';
import { SupabaseService } from './supabase/supabase.service';

@Controller()
export class AppController {
  constructor(
    private readonly appService: AppService,
    private readonly prisma: PrismaService,
    private readonly searchService: SupplementSearchService,
    private readonly supabaseService: SupabaseService,
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
    if (userGender === '남성' || userGender === 'male') userGender = '남자';
    else if (userGender === '여성' || userGender === 'female') userGender = '여자';

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

    // ── 핵심 수정: supplementsTemp에 ingredients relation 없음
    // → supplementsIngredients 먼저 조회 후 product_name으로 필터링
    const andConditions: any[] = [];

    if (categories.length > 0) {
      const catNutrients = mappedNutrients.length > 0 ? mappedNutrients : categories;
      const catFilter = catNutrients.map(nut => ({
        ingredient_name: { contains: nut, mode: 'insensitive' as const },
      }));
      const catProductContains = catNutrients.map(nut => ({
        product_name: { contains: nut, mode: 'insensitive' },
      }));

      // supplementsIngredients에서 matching product_name 먼저 조회
      const catMatchedIngs = await this.prisma.supplementsIngredients.findMany({
        where: { OR: catFilter },
        select: { product_name: true },
      });
      const catProductNames = [...new Set(
        catMatchedIngs.map(i => i.product_name).filter(Boolean) as string[]
      )];

      andConditions.push({
        OR: [
          ...(catProductNames.length > 0 ? [{ product_name: { in: catProductNames } }] : []),
          ...catProductContains,
        ],
      });
    }

    if (ingredients.length > 0) {
      const ingFilter = ingredients.map(nut => ({
        ingredient_name: { contains: nut, mode: 'insensitive' as const },
      }));
      const ingProductContains = ingredients.map(nut => ({
        product_name: { contains: nut, mode: 'insensitive' },
      }));

      // supplementsIngredients에서 matching product_name 먼저 조회
      const ingMatchedIngs = await this.prisma.supplementsIngredients.findMany({
        where: { OR: ingFilter },
        select: { product_name: true },
      });
      const ingProductNames = [...new Set(
        ingMatchedIngs.map(i => i.product_name).filter(Boolean) as string[]
      )];

      andConditions.push({
        OR: [
          ...(ingProductNames.length > 0 ? [{ product_name: { in: ingProductNames } }] : []),
          ...ingProductContains,
        ],
      });
    }

    if (keyword && keyword.trim().length > 0) {
      andConditions.push({
        OR: [
          { product_name: { contains: keyword.trim(), mode: 'insensitive' } },
          { brand_name: { contains: keyword.trim(), mode: 'insensitive' } },
        ],
      });
    }

    if (andConditions.length > 0) {
      whereClause.AND = andConditions;
    }

    const dataTemp = await this.prisma.supplementsTemp.findMany({
      take: 20,
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
      },
    });

    const enrichedData = data.map(product => {
      const mappedIngredients = product.ingredients.map(ing => {
        const std = standards.find(s => s.nutrient_name === ing.ingredient_name);
        const dri = std?.recommended_intake || std?.adequate_intake || std?.avg_requirement || null;
        const amount = ing.amount || 0;

        let dailyPercent = 0;
        if (dri && dri > 0) {
          dailyPercent = Number((amount / dri).toFixed(4));
        }

        return { ...ing, dailyPercent };
      });

      return { ...product, ingredients: mappedIngredients };
    });

    return JSON.parse(
      JSON.stringify(enrichedData, (key, value) =>
        typeof value === 'bigint' ? value.toString() : value,
      ),
    );
  }

  @Get('supplements/popular')
  getPopularSupplements() {
    return this.appService.getPopularSearches();
  }

  @Post('supplements/ocr')
  @UseInterceptors(FileInterceptor('image'))
  async uploadSupplementOcr(@UploadedFile() file: any) {
    if (!file) {
      throw new BadRequestException('이미지 파일이 전송되지 않았습니다.');
    }

    const uploadDir = 'c:\\capstone\\onePerday\\backend\\uploads';
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }

    const filePath = path.join(uploadDir, `${Date.now()}-${file.originalname || 'photo.jpg'}`);
    fs.writeFileSync(filePath, file.buffer);

    const pythonScript = path.resolve(process.cwd(), '..', 'ai', 'ocr.py');

    return new Promise((resolve) => {
      const pyProcess = spawn('python', [pythonScript, filePath], {
        env: { ...process.env, PYTHONIOENCODING: 'utf-8' },
      });
      let stdoutData = '';
      let stderrData = '';

      pyProcess.stdout.on('data', (data) => { stdoutData += data.toString(); });
      pyProcess.stderr.on('data', (data) => { stderrData += data.toString(); });

      pyProcess.on('close', async (code) => {
        try { fs.unlinkSync(filePath); } catch (e) { console.error('임시 파일 삭제 실패:', e); }

        if (code !== 0) {
          console.error('파이썬 OCR 실행 실패:', stderrData);
          resolve({
            productName: '멀티비타민 골드',
            brandName: '시뮬레이션 브랜드',
            nutrients: '비타민C, 비타민D, 아연',
            error: stderrData,
          });
          return;
        }

        const rawText = stdoutData.trim();
        const parsed = this.parseOcrText(rawText);

        if (parsed.productName !== '알 수 없는 영양제' && parsed.productName.trim() !== '') {
          try {
            const allSupplementsTemp = await this.prisma.supplementsTemp.findMany();
            const productNames = allSupplementsTemp.map(s => s.product_name).filter(Boolean) as string[];
            const ingredients = await this.prisma.supplementsIngredients.findMany({
              where: { product_name: { in: productNames } },
            });
            const allSupplements = allSupplementsTemp.map(product => ({
              ...product,
              ingredients: ingredients.filter(ing => ing.product_name === product.product_name),
            }));

            const targetName = parsed.productName.replace(/\s+/g, '').toLowerCase();
            let bestMatch: any = null;
            let highestSimilarity = 0;

            for (const supp of allSupplements) {
              if (!supp.product_name) continue;
              const dbName = supp.product_name.replace(/\s+/g, '').toLowerCase();

              if (dbName === targetName || dbName.includes(targetName) || targetName.includes(dbName)) {
                bestMatch = supp;
                highestSimilarity = 1.0;
                break;
              }

              const longer = dbName.length > targetName.length ? dbName : targetName;
              const shorter = dbName.length > targetName.length ? targetName : dbName;
              if (longer.length === 0) continue;

              const matrix: number[][] = [];
              for (let i = 0; i <= shorter.length; i++) matrix[i] = [i];
              for (let j = 0; j <= longer.length; j++) matrix[0][j] = j;

              for (let i = 1; i <= shorter.length; i++) {
                for (let j = 1; j <= longer.length; j++) {
                  if (shorter.charAt(i - 1) === longer.charAt(j - 1)) {
                    matrix[i][j] = matrix[i - 1][j - 1];
                  } else {
                    matrix[i][j] = Math.min(
                      matrix[i - 1][j - 1] + 1,
                      Math.min(matrix[i][j - 1] + 1, matrix[i - 1][j] + 1),
                    );
                  }
                }
              }
              const distance = matrix[shorter.length][longer.length];
              const sim = (longer.length - distance) / longer.length;

              if (sim > highestSimilarity) {
                highestSimilarity = sim;
                bestMatch = supp;
              }
            }

            if (bestMatch && highestSimilarity >= 0.7) {
              parsed.productName = bestMatch.product_name;
              parsed.brandName = bestMatch.brand_name || parsed.brandName;
              parsed.imageUrl = bestMatch.image_url || undefined;
              parsed.id = bestMatch.id.toString();

              if (bestMatch.ingredients && bestMatch.ingredients.length > 0) {
                parsed.nutrients = bestMatch.ingredients.map(ing => ing.ingredient_name).join(', ');
              }
            }
          } catch (e) {
            console.error('DB 매칭 실패:', e);
          }
        }

        resolve(parsed);
      });
    });
  }

  private parseOcrText(text: string): { productName: string; brandName: string; nutrients: string; imageUrl?: string; id?: string } {
    let productName = '알 수 없는 영양제';
    let brandName = '알 수 없는 브랜드';
    let nutrients = '영양제 성분을 찾을 수 없습니다.';

    const brandMatch = text.match(/Brand:\s*([^\n]+)/i);
    if (brandMatch) {
      const parsedBrand = brandMatch[1].trim();
      const lowerBrand = parsedBrand.toLowerCase();
      if (lowerBrand !== 'unknown' && parsedBrand !== '[Brand name in Korean]' && parsedBrand !== '알 수 없음') {
        brandName = parsedBrand;
      }
    }

    const productMatch = text.match(/Product:\s*([^\n]+)/i);
    if (productMatch) {
      const parsedProduct = productMatch[1].trim();
      const lowerProduct = parsedProduct.toLowerCase();
      if (lowerProduct !== 'unknown' && parsedProduct !== '[Product name in Korean]' && parsedProduct !== '알 수 없음') {
        productName = parsedProduct;
      }
    }

    const nutrientList: string[] = [];
    const knownNutrients = [
      '비타민A', '비타민B', '비타민C', '비타민D', '비타민E', '비타민K',
      '아연', '마그네슘', '칼슘', '철분', '유산균', '프로바이오틱스',
      '루테인', '밀크씨슬', '오메가3', '엽산', '비오틴', '셀레늄', '크롬',
    ];

    for (const nut of knownNutrients) {
      if (text.includes(nut)) nutrientList.push(nut);
    }

    if (nutrientList.length > 0) nutrients = nutrientList.join(', ');

    return { productName, brandName, nutrients };
  }

  @Post('supplements/search')
  async searchSupplement(@Body() body: LlmExtracted) {
    const result = await this.searchService.search(body);
    return JSON.parse(
      JSON.stringify(result, (key, value) =>
        typeof value === 'bigint' ? value.toString() : value,
      ),
    );
  }

  @Get('admin/users')
  async getUsers(@Query('search') search?: string) {
    const usersInfo = await this.prisma.usersInfo.findMany({
      where: search ? {
        OR: [
          { name: { contains: search, mode: 'insensitive' } },
          { users: { email: { contains: search, mode: 'insensitive' } } },
        ],
      } : undefined,
      select: {
        id: true,
        name: true,
        gender: true,
        birth_year: true,
        created_at: true,
        users: { select: { email: true, created_at: true } },
      },
    });
    return usersInfo;
  }

  @Delete('admin/users/:id')
  async deleteUser(@Param('id') id: string) {
    await this.prisma.usersInfo.delete({ where: { id } });
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

  @Delete('admin/supplements/:id')
  async deleteSupplement(@Param('id') id: string) {
    return this.prisma.supplementsTemp.delete({ where: { id: BigInt(id) } });
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
      this.prisma.supplementsTemp.findMany({ take, skip, where: whereClause, orderBy: { id: 'asc' } }),
      this.prisma.supplementsTemp.count({ where: whereClause }),
    ]);

    return JSON.parse(
      JSON.stringify({
        data, total, page: pageNum, totalPages: Math.ceil(total / take),
      }, (key, value) => typeof value === 'bigint' ? value.toString() : value),
    );
  }

  // 대시보드
  @Get('admin/dashboard')
  async getDashboard() {
    const [totalUsers, totalSupplements, todayUsers] = await Promise.all([
      this.prisma.usersInfo.count(),
      this.prisma.supplements.count(),
      this.prisma.usersInfo.count({
        where: {
          created_at: {
            gte: new Date(new Date().setHours(0, 0, 0, 0)),
          }
        }
      }),
    ]);

    return { totalUsers, totalSupplements, todayUsers };
  }  

  @Patch('admin/users/:id')
  async updateUser(@Param('id') id: string, @Body() body: any) {
    return this.prisma.usersInfo.update({
      where: { id },
      data: {
        name: body.name,
        gender: body.gender,
        birth_year: body.birth_year ? parseInt(body.birth_year) : null,
      }
    });
  }

  @Patch('admin/supplements/:id')
  async updateSupplement(@Param('id') id: string, @Body() body: any) {
    return JSON.parse(JSON.stringify(
      await this.prisma.supplementsTemp.update({
        where: { id: BigInt(id) },
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
}
