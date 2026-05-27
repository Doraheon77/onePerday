import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CheckIntakeDto } from './dto/check-intake.dto';

export interface IntakeResult {
  nutrientName: string;
  currentTotal: number;
  recommendedIntake: number;
  adequateIntake: number;
  upperLimit: number;
  status: 'safe' | 'warning' | 'danger';
  unit: string;
}
@Injectable()
export class IntakeService {
  constructor(private readonly prisma: PrismaService) {}

  async checkOverdose(dto: CheckIntakeDto): Promise<IntakeResult[]> {
    const { cartItems, age, gender } = dto;

    if (!cartItems || cartItems.length === 0) {
      return [];
    }

    const productIds = cartItems
      .map((item) => this.toBigIntOrNull(item.productId))
      .filter((id): id is bigint => id !== null && id <= BigInt(2147483647));
    const nameItems = cartItems.filter(
      (item) => this.toBigIntOrNull(item.productId) === null && item.name,
    );
    const searchConditions = [
      ...(productIds.length > 0
        ? [
            {
              id: {
                in: productIds,
              },
            },
          ]
        : []),
      ...nameItems.map((item) => ({
        product_name: {
          contains: item.name!,
          mode: 'insensitive' as const,
        },
      })),
    ];

    if (searchConditions.length === 0) {
      return [];
    }

    const supplementsTemp = await this.prisma.supplementsTemp.findMany({
      where: {
        OR: searchConditions,
      },
    });

    const productNames = supplementsTemp.map(s => s.product_name).filter(Boolean) as string[];
    const ingredients = await this.prisma.supplementsIngredients.findMany({
      where: { product_name: { in: productNames } },
    });

    const supplements = supplementsTemp.map(product => ({
      ...product,
      supplements_ingredients: ingredients.filter(ing => ing.product_name === product.product_name),
    }));

    const countMap = new Map<string, number>();
    for (const item of cartItems) {
      countMap.set(String(item.productId ?? item.name ?? ''), item.count ?? 1);
      if (item.name) {
        countMap.set(item.name, item.count ?? 1);
      }
    }

    const aggregated: Record<string, { total: number; unit: string }> = {};

    for (const supplement of supplements) {
      const count =
        countMap.get(String(supplement.id)) ??
        countMap.get(supplement.product_name || '') ??
        1;

      for (const ingredient of supplement.supplements_ingredients) {
        const name = ingredient.ingredient_name?.trim();
        const amount = ingredient.amount ?? 0;
        const unit = ingredient.unit?.trim() || 'mg';

        if (!name) continue;

        if (!aggregated[name]) {
          aggregated[name] = {
            total: 0,
            unit,
          };
        }

        aggregated[name].total += amount * count;
      }
    }

    const results: IntakeResult[] = [];

    for (const [nutrientName, value] of Object.entries(aggregated)) {
      // const debugStandards = await this.prisma.nutrientStandards.findMany({
      //   where: {
      //     nutrient_name: {
      //       contains: nutrientName,
      //     },
      //   },
      //   take: 5,
      // });
      // console.log('기준표 후보:', debugStandards);

      const standard = await this.prisma.nutrientStandards.findFirst({
        where: {
          nutrient_name: nutrientName,
          gender: this.mapGender(gender),
          age_min: {
            lte: Number(age),
          },
          age_max: {
            gte: Number(age),
          },
        },
      });

      //console.log('조회 성분:', nutrientName);
      //console.log('조회 gender:', this.mapGender(gender));
      //console.log('조회 결과:', standard);

      const recommendedIntake = standard?.recommended_intake ?? 0;
      const adequateIntake = standard?.adequate_intake ?? 0;
      const upperLimit = standard?.upper_limit ?? 0;
      const targetIntake =
        recommendedIntake > 0 ? recommendedIntake : adequateIntake;

      let status: 'safe' | 'warning' | 'danger' = 'safe';

      if (upperLimit > 0 && value.total >= upperLimit) {
        status = 'danger';
      } else if (targetIntake > 0 && value.total >= targetIntake) {
        status = 'warning';
      }

      results.push({
        nutrientName,
        currentTotal: value.total,
        recommendedIntake,
        adequateIntake,
        upperLimit,
        status,
        unit: value.unit,
      });
    }

    return results;
  }

  private mapGender(gender: 'male' | 'female') {
    if (gender === 'male') return '남자';
    return '여자';
  }

  private toBigIntOrNull(value: unknown) {
    if (value === null || value === undefined) return null;
    const raw = String(value).trim();
    if (!/^\d+$/.test(raw)) return null;
    return BigInt(raw);
  }
}
