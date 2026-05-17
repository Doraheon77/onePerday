import { Injectable, Logger } from '@nestjs/common';
import { Conflict } from './entities/conflict.entity';
import { HttpService } from '@nestjs/axios';
import { ConfigService } from '@nestjs/config';
import { firstValueFrom } from 'rxjs';
import { PrismaService } from '../prisma/prisma.service';

interface UserConflictRecord {
  piilName: string;
  ingredients: string[];
  dailyDosage: number;
}

interface FilterResult {
  status: 'SAFE' | 'CAUTION' | 'DANGER';
  reasons: string[];
}

@Injectable()
export class ConflictService {
  private readonly logger = new Logger(ConflictService.name);
  private durApiKey: string;
  private readonly baseUrl = 'https://api.odcloud.kr/api/15089525/v1/uddi:3f2efdac-942b-494e-919f-8bdc583f65ea';

  // 두 성분간 병용금기 캐싱 (중복 API 요청 방지)
  private pairCache = new Map<string, boolean>();

  constructor(
    private readonly httpService: HttpService,
    private readonly configService: ConfigService,
    private readonly prisma: PrismaService,
  ) {
    this.durApiKey = this.configService.get<string>('DUR_API_KEY') || '';
  }

  async checkConflictsByIds(supplementIds: number[]) {
    if (!supplementIds || supplementIds.length === 0) {
      return [];
    }

    const supplementBigIntIds = supplementIds.map((id) => BigInt(id));

    const selectedSupplements = await this.prisma.supplements.findMany({
      where: {
        id: {
          in: supplementBigIntIds,
        },
      },
      include: {
        supplements_ingredients: true,
      },
    });

    const conflicts: Conflict[] = selectedSupplements.map((s) => ({
      name: s.product_name,
      ingredients: s.supplements_ingredients
        .map((si) => si.ingredient_name?.trim())
        .filter(Boolean) as string[],
    }));

    return this.checkConflicts(conflicts);
  }

  async checkConflicts(conflicts: Conflict[]) {
    const results: {
      conflicts: string[];
      reason: string;
      conflictingIngredients: string[]
    }[] = [];

    // 영양제간 병용금기 대조
    for (let i = 0; i < conflicts.length; i++) {
      for (let j = i + 1; j < conflicts.length; j++) {
        const conflictA = conflicts[i];
        const conflictB = conflicts[j];
        const exactConflicts = new Set<string>();

        // 두 약의 성분 쌍을 하나씩 대조
        for (const ingA of conflictA.ingredients) {
          for (const ingB of conflictB.ingredients) {
            const isTaboo = await this.checkPairConflict(ingA, ingB);
            if (isTaboo) {
              exactConflicts.add(ingA);
              exactConflicts.add(ingB);
            }
          }
        }

        if (exactConflicts.size > 0) {
          results.push({
            conflicts: [conflictA.name, conflictB.name],
            reason: '공공데이터포털(DUR) 기준 병용금기 성분 충돌 위험이 있습니다.',
            conflictingIngredients: Array.from(exactConflicts)
          });
        }
      }
    }

    return results.length > 0 ? results : { message: '충돌하는 영양제가 없음.' };
  }

  private async checkPairConflict(ingA: string, ingB: string): Promise<boolean> {
    const cacheKey1 = `${ingA}-${ingB}`;
    const cacheKey2 = `${ingB}-${ingA}`;

    // 이미 조회된 성분 조합은 캐시에서 바로 반환
    if (this.pairCache.has(cacheKey1)) return this.pairCache.get(cacheKey1)!;
    if (this.pairCache.has(cacheKey2)) return this.pairCache.get(cacheKey2)!;

    try {
      const url1 = `${this.baseUrl}?page=1&perPage=1&serviceKey=${this.durApiKey}&cond[성분명1::EQ]=${encodeURIComponent(ingA)}&cond[성분명2::EQ]=${encodeURIComponent(ingB)}`;
      const url2 = `${this.baseUrl}?page=1&perPage=1&serviceKey=${this.durApiKey}&cond[성분명1::EQ]=${encodeURIComponent(ingB)}&cond[성분명2::EQ]=${encodeURIComponent(ingA)}`;

      const [res1, res2] = await Promise.all([
        firstValueFrom(this.httpService.get(url1)),
        firstValueFrom(this.httpService.get(url2))
      ]);

      const hasConflict = (res1.data?.matchCount > 0) || (res2.data?.matchCount > 0);

      this.pairCache.set(cacheKey1, hasConflict);
      return hasConflict;
    } catch (error) {
      this.logger.error(`Failed to check pair conflict for: ${ingA} and ${ingB}`, error);
      return false; // 방어
    }
  }

}
