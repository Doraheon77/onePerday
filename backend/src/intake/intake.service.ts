import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CheckIntakeDto } from './dto/check-intake.dto';

export interface IntakeResult {
  nutrientName: string;
  currentTotal: number;
  upperLimit: number | null;
  isExceeded: boolean;
  unit: string;
}

@Injectable()
export class IntakeService {
  constructor(private readonly prisma: PrismaService) {}

  async checkOverdose(dto: CheckIntakeDto): Promise<IntakeResult[]> {
    const { supplementIds, age, gender } = dto;

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

    const aggregated: Record<string, { total: number; unit: string }> = {};

    for (const supplement of selectedSupplements) {
      for (const ingredient of supplement.supplements_ingredients) {
        const name = ingredient.ingredient_name?.trim();
        const amount = ingredient.amount ?? 0;
        const unit = ingredient.unit?.trim() || '';

        if (!name) continue;

        if (!aggregated[name]) {
          aggregated[name] = {
            total: 0,
            unit,
          };
        }

        aggregated[name].total += amount;
      }
    }

    const results: IntakeResult[] = [];

    for (const [name, value] of Object.entries(aggregated)) {
      const standard = await this.prisma.nutrientStandards.findFirst({
        where: {
          nutrient_name: name,
          gender: this.mapGenderToDbValue(gender),
          age_min: { lte: BigInt(age) },
          age_max: { gte: BigInt(age) },
        },
      });

      const upperLimit = standard?.upper_limit ?? null;

      results.push({
        nutrientName: name,
        currentTotal: value.total,
        upperLimit,
        isExceeded: upperLimit !== null ? value.total > upperLimit : false,
        unit: value.unit || 'mg',
      });
    }

    return results;
  }

  private mapGenderToDbValue(gender: 'male' | 'female'): string {
    if (gender === 'male') return '남';
    return '여';
  }
}