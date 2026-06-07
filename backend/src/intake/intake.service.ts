import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CheckIntakeDto } from './dto/check-intake.dto';
import { CompleteIntakeDto } from './dto/complete-intake.dto';

export interface IntakeResult {
  nutrientName: string;

  currentTotal: number;

  avgRequirement: number;
  recommendedIntake: number;
  adequateIntake: number;
  upperLimit: number;

  ratio: number;

  targetType:
    | 'recommended'
    | 'adequate'
    | 'upper'
    | 'none';

  status:
    | 'very_low'
    | 'low'
    | 'normal'
    | 'enough'
    | 'danger'
    | 'none';

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
      ingredients: ingredients.filter(ing => ing.product_name === product.product_name),
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

      for (const ingredient of supplement.ingredients) {
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

      const avgRequirement = standard?.avg_requirement ?? 0;
      const recommendedIntake = standard?.recommended_intake ?? 0;
      const adequateIntake = standard?.adequate_intake ?? 0;
      const upperLimit = standard?.upper_limit ?? 0;

      const targetIntake =
        recommendedIntake > 0
          ? recommendedIntake
          : adequateIntake;

      let ratio = 0;

      let targetType:
        | 'recommended'
        | 'adequate'
        | 'upper'
        | 'none' = 'none';

      let status:
        | 'very_low'
        | 'low'
        | 'normal'
        | 'enough'
        | 'danger'
        | 'none' = 'none';

      if (targetIntake > 0) {
        ratio = value.total / targetIntake;

        targetType =
          recommendedIntake > 0
            ? 'recommended'
            : 'adequate';

        if (ratio < 0.3) {
          status = 'very_low';
        } else if (ratio < 0.7) {
          status = 'low';
        } else if (ratio <= 1.0) {
          status = 'normal';
        } else {
          status = 'enough';
        }
      }

      if (upperLimit > 0) {
        const upperRatio = value.total / upperLimit;

        if (upperRatio >= 1.0) {
          ratio = upperRatio;
          targetType = 'upper';
          status = 'danger';
        }
      }

      results.push({
        nutrientName,
        currentTotal: value.total,

        avgRequirement,
        recommendedIntake,
        adequateIntake,
        upperLimit,

        ratio,
        targetType,
        status,

        unit: value.unit,
      });
    }

    return results;
  }

  async getTodayReminders(userUuid: string) {
    const today = this.getDateOnly(new Date());

    const inventories = await this.prisma.supplementInventory.findMany({
      where: {
        user_uuid: userUuid,
        status: 'active',
      },
      include: {
        supplements: true,
        daily_supplements: {
          where: {
            date: today,
          },
        },
      },
      orderBy: {
        created_at: 'desc',
      },
    });

    const reminders = inventories.flatMap((item) => {
      const alarmTimes = Array.isArray(item.alarm_times)
        ? (item.alarm_times as string[])
        : [];

      return alarmTimes.map((time, index) => {
        const log = item.daily_supplements.find(
          (daily) => daily.dose_index === index,
        );

        const isTaken = log?.is_taken === true;

        return {
          inventoryId: item.id.toString(),
          userUuid: item.user_uuid,
          supplementId: item.supplement_id.toString(),
          supplementName: item.supplements.product_name,
          brandName: item.supplements.brand_name,
          imageUrl: item.supplements.image_url,
          doseIndex: index,
          supplementTime: time,
          date: today.toISOString().slice(0, 10),
          isTaken,
          status: this.getReminderStatus(time, isTaken),
          stockCount: item.stock_count ?? 0,
          totalCount: item.total_count ?? 0,
        };
      });
    });

    return reminders.sort((a, b) => {
      const priority = { DUE: 1, MISSED: 2, UPCOMING: 3, TAKEN: 4 };

      if (priority[a.status] !== priority[b.status]) {
        return priority[a.status] - priority[b.status];
      }

      return a.supplementTime.localeCompare(b.supplementTime);
    });
  }

  async completeIntake(dto: CompleteIntakeDto) {
    const date = this.getDateOnly(new Date(dto.date));
    const inventoryId = BigInt(dto.inventoryId);

    return this.prisma.$transaction(async (tx) => {
      const inventory = await tx.supplementInventory.findFirst({
        where: {
          id: inventoryId,
          user_uuid: dto.userUuid,
          status: 'active',
        },
      });

      if (!inventory) {
        throw new NotFoundException('Cabinet item not found');
      }

      const existing = await tx.dailySupplements.findFirst({
        where: {
          user_uuid: dto.userUuid,
          inventory_id: inventoryId,
          date,
          dose_index: dto.doseIndex,
        },
      });

      const wasAlreadyTaken = existing?.is_taken === true;

      const log = existing
        ? await tx.dailySupplements.update({
            where: {
              id: existing.id,
            },
            data: {
              is_taken: true,
              taken_at: existing.taken_at ?? new Date(),
              supplement_time: dto.supplementTime ?? existing.supplement_time,
            },
          })
        : await tx.dailySupplements.create({
            data: {
              user_uuid: dto.userUuid,
              inventory_id: inventoryId,
              date,
              dose_index: dto.doseIndex,
              supplement_time: dto.supplementTime,
              is_taken: true,
              taken_at: new Date(),
            },
          });

      if (!wasAlreadyTaken) {
        const dailyDose = inventory.daily_dose ?? 1;
        const dailyFrequency = inventory.daily_frequency ?? 1;
        const dosePerTime = Math.max(1, Math.ceil(dailyDose / dailyFrequency));
        const currentStock = inventory.stock_count ?? 0;
        const nextStock = Math.max(0, currentStock - dosePerTime);

        await tx.supplementInventory.update({
          where: {
            id: inventoryId,
          },
          data: {
            stock_count: nextStock,
          },
        });
      }

      return log;
    });
  }

  async cancelIntake(dto: CompleteIntakeDto) {
    const date = this.getDateOnly(new Date(dto.date));
    const inventoryId = BigInt(dto.inventoryId);

    return this.prisma.$transaction(async (tx) => {
      const inventory = await tx.supplementInventory.findFirst({
        where: {
          id: inventoryId,
          user_uuid: dto.userUuid,
          status: 'active',
        },
      });

      if (!inventory) {
        throw new NotFoundException('Cabinet item not found');
      }

      const existing = await tx.dailySupplements.findFirst({
        where: {
          user_uuid: dto.userUuid,
          inventory_id: inventoryId,
          date,
          dose_index: dto.doseIndex,
        },
      });

      if (!existing || !existing.is_taken) {
        return existing;
      }

      const log = await tx.dailySupplements.update({
        where: {
          id: existing.id,
        },
        data: {
          is_taken: false,
          taken_at: null,
        },
      });

      const dailyDose = inventory.daily_dose ?? 1;
      const dailyFrequency = inventory.daily_frequency ?? 1;
      const dosePerTime = Math.max(1, Math.ceil(dailyDose / dailyFrequency));
      const currentStock = inventory.stock_count ?? 0;
      const totalCount = inventory.total_count ?? 0;
      const nextStock = totalCount > 0 
          ? Math.min(totalCount, currentStock + dosePerTime)
          : currentStock + dosePerTime;

      await tx.supplementInventory.update({
        where: {
          id: inventoryId,
        },
        data: {
          stock_count: nextStock,
        },
      });

      return log;
    });
  }

  private getDateOnly(date: Date) {
    return new Date(date.getFullYear(), date.getMonth(), date.getDate());
  }

  private getReminderStatus(
    supplementTime: string,
    isTaken: boolean,
  ): 'UPCOMING' | 'DUE' | 'MISSED' | 'TAKEN' {
    if (isTaken) return 'TAKEN';

    const now = new Date();
    const [hour, minute] = supplementTime.split(':').map(Number);
    const target = new Date(now);
    target.setHours(hour, minute, 0, 0);

    const dueEnd = new Date(target.getTime() + 60 * 60 * 1000);

    if (now < target) return 'UPCOMING';
    if (now <= dueEnd) return 'DUE';
    return 'MISSED';
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
