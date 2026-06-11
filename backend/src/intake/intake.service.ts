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
  targetType: 'recommended' | 'adequate' | 'upper' | 'none';
  status: 'very_low' | 'low' | 'normal' | 'enough' | 'danger' | 'none';
  unit: string;
}

@Injectable()
export class IntakeService {
  constructor(private readonly prisma: PrismaService) { }

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
      ...(productIds.length > 0 ? [{ id: { in: productIds } }] : []),
      ...nameItems.map((item) => ({
        product_name: {
          contains: item.name!,
          mode: 'insensitive' as const,
        },
      })),
    ];

    // countMap
    const countMap = new Map<string, number>();
    for (const item of cartItems) {
      countMap.set(String(item.productId ?? item.name ?? ''), item.count ?? 1);
      if (item.name) {
        countMap.set(item.name, item.count ?? 1);
      }
    }

    const aggregated: Record<string, { total: number; unit: string }> = {};

    // ── Step 1: name으로 supplementsTemp 먼저 검색 (스토어와 동일 데이터 사용) ─
    const productNameCountMap = new Map<string, number>();

    // cartItem name 맵
    const cartNameMap = new Map<string, string>();
    for (const item of cartItems) {
      if (item.productId != null && item.name) {
        cartNameMap.set(String(item.productId), item.name);
      }
    }

    // 모든 아이템의 이름을 수집
    const allNames = [
      ...productIds.map(pid => cartNameMap.get(String(pid)) ?? '').filter(Boolean),
      ...nameItems.map(item => item.name!),
    ];

    // ── 1-1: 이름으로 supplementsTemp 검색 (스토어와 동일한 데이터 소스) ──
    const foundByName = new Set<string>(); // productId → found

    if (allNames.length > 0) {
      const tempByName = await this.prisma.supplementsTemp.findMany({
        where: {
          OR: allNames.map(name => ({
            product_name: { contains: name.substring(0, 8), mode: 'insensitive' as const },
          })),
        },
      });

      // 각 이름과 가장 유사한 supplementsTemp 항목 매핑
      const norm = (s: string) =>
        s.split('').filter(ch => ch.trim() !== '').join('').toLowerCase();

      for (const item of cartItems) {
        const itemName = item.name ?? '';
        if (!itemName) continue;
        const normItem = norm(itemName);
        const count = countMap.get(String(item.productId ?? item.name ?? '')) ?? 1;

        // 이름 유사도로 최적 매칭 찾기
        let bestMatch: typeof tempByName[0] | null = null;
        let bestScore = 0;

        for (const t of tempByName) {
          if (!t.product_name) continue;
          const normTemp = norm(t.product_name);
          const score = normTemp === normItem ? 2
            : (normTemp.includes(normItem) || normItem.includes(normTemp)) ? 1
            : 0;
          if (score > bestScore) {
            bestScore = score;
            bestMatch = t;
          }
        }

        if (bestMatch?.product_name && bestScore > 0) {
          foundByName.add(String(item.productId ?? item.name ?? ''));
          if (!productNameCountMap.has(bestMatch.product_name)) {
            productNameCountMap.set(bestMatch.product_name, count);
          }
        }
      }
    }

    // ── 1-2: 이름으로 못 찾은 항목 → ID로 폴백 ──────────────────────────
    const missingItems = cartItems.filter(item =>
      !foundByName.has(String(item.productId ?? item.name ?? ''))
    );

    if (missingItems.length > 0) {
      const missingIds = missingItems
        .map(item => this.toBigIntOrNull(item.productId))
        .filter((id): id is bigint => id !== null);

      if (missingIds.length > 0) {
        const [tempById, mainById] = await Promise.all([
          this.prisma.supplementsTemp.findMany({ where: { id: { in: missingIds } } }),
          this.prisma.supplements.findMany({ where: { id: { in: missingIds } } }),
        ]);

        const norm = (s: string) =>
          s.split('').filter(ch => ch.trim() !== '').join('').toLowerCase();

        for (const pid of missingIds) {
          const itemName = cartNameMap.get(String(pid)) ?? '';
          const normItem = norm(itemName);
          const count = countMap.get(String(pid)) ?? 1;

          const tempMatch = tempById.find(s => s.id.toString() === pid.toString());
          const mainMatch = mainById.find(s => s.id.toString() === pid.toString());

          let chosenProductName: string | null = null;

          if (tempMatch?.product_name && mainMatch?.product_name) {
            const normTemp = norm(tempMatch.product_name);
            const normMain = norm(mainMatch.product_name);
            const tempScore = (normTemp === normItem || normTemp.includes(normItem) || normItem.includes(normTemp)) ? 1 : 0;
            const mainScore = (normMain === normItem || normMain.includes(normItem) || normItem.includes(normMain)) ? 1 : 0;
            chosenProductName = mainScore > tempScore ? mainMatch.product_name : tempMatch.product_name;
          } else {
            chosenProductName = mainMatch?.product_name ?? tempMatch?.product_name ?? null;
          }

          if (chosenProductName && !productNameCountMap.has(chosenProductName)) {
            productNameCountMap.set(chosenProductName, count);
          }
        }
      }

      // nameItems 처리
      const nameOnlyItems = missingItems.filter(item => !item.productId && item.name);
      if (nameOnlyItems.length > 0) {
        const tempByName2 = await this.prisma.supplementsTemp.findMany({
          where: {
            OR: nameOnlyItems.map(item => ({
              product_name: { contains: item.name!, mode: 'insensitive' as const },
            })),
          },
        });
        for (const t of tempByName2) {
          if (!t.product_name) continue;
          const count = countMap.get(t.product_name) ?? 1;
          if (!productNameCountMap.has(t.product_name)) {
            productNameCountMap.set(t.product_name, count);
          }
        }
      }
    }

        // ── Step 2: 수집된 product_name으로 성분 한번에 조회 ─────────────────
    const productNamesArr = Array.from(productNameCountMap.keys());
    if (productNamesArr.length > 0) {
      const allIngredients = await this.prisma.supplementsIngredients.findMany({
        where: { product_name: { in: productNamesArr } },
      });

      // product_name별 성분 수 확인 (이름 직접 검색 필요 여부 판단용)
      const ingByProductName = new Map<string, typeof allIngredients>();
      for (const ing of allIngredients) {
        if (!ing.product_name) continue;
        if (!ingByProductName.has(ing.product_name)) {
          ingByProductName.set(ing.product_name, []);
        }
        ingByProductName.get(ing.product_name)!.push(ing);
      }

      for (const [productName, count] of productNameCountMap) {
        const ings = ingByProductName.get(productName) ?? [];

        // ── Fallback: 성분이 없으면 cartItem.name으로 직접 검색 ──────────
        let finalIngs = ings;
        if (ings.length === 0) {
          const itemName = cartNameMap.get(
            [...productNameCountMap.entries()]
              .find(([k]) => k === productName)?.[0] ?? ''
          ) ?? productName;

          // 이름으로 supplementsIngredients 직접 검색
          const nameIngs = await this.prisma.supplementsIngredients.findMany({
            where: {
              product_name: { contains: itemName.substring(0, 10), mode: 'insensitive' },
            },
          });
          finalIngs = nameIngs;
        }

        for (const ing of finalIngs) {
          const name = ing.ingredient_name?.trim();
          const amount = Number(ing.amount ?? 0);
          const unit = ing.unit?.trim() || 'mg';
          if (!name) continue;
          if (!aggregated[name]) aggregated[name] = { total: 0, unit };
          aggregated[name].total += amount * count;
        }
      }
    }

    const nutrientNames = Object.keys(aggregated);
    if (nutrientNames.length === 0) return [];

    // ── nutrientStandards 한번에 조회 (원본 로직 동일, N+1만 수정) ──────────
    const standards = await this.prisma.nutrientStandards.findMany({
      where: {
        nutrient_name: { in: nutrientNames },
        gender: this.mapGender(gender),
        age_min: { lte: BigInt(age) },
        age_max: { gte: BigInt(age) },
      },
    });
    const standardMap = new Map(standards.map((s) => [s.nutrient_name, s]));

    const results: IntakeResult[] = [];

    for (const [nutrientName, value] of Object.entries(aggregated)) {
      const avgRequirement = Number(standardMap.get(nutrientName)?.avg_requirement ?? 0);
      const recommendedIntake = Number(standardMap.get(nutrientName)?.recommended_intake ?? 0);
      const adequateIntake = Number(standardMap.get(nutrientName)?.adequate_intake ?? 0);
      const upperLimit = Number(standardMap.get(nutrientName)?.upper_limit ?? 0);

      const targetIntake =
        recommendedIntake > 0
          ? recommendedIntake
          : adequateIntake > 0
          ? adequateIntake
          : avgRequirement;

      let ratio = 0;
      let targetType: IntakeResult['targetType'] = 'none';
      let status: IntakeResult['status'] = 'none';

      if (targetIntake > 0) {
        ratio = value.total / targetIntake;
        targetType = recommendedIntake > 0 ? 'recommended' : 'adequate';

        if (ratio < 0.3) status = 'very_low';
        else if (ratio < 0.7) status = 'low';
        else if (ratio <= 1.0) status = 'normal';
        else status = 'enough';
      }

      if (upperLimit > 0 && value.total / upperLimit >= 1.0) {
        ratio = value.total / upperLimit;
        targetType = 'upper';
        status = 'danger';
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
      where: { user_uuid: userUuid, status: 'active' },
      include: {
        daily_supplements: { where: { date: today } },
      },
      orderBy: { created_at: 'desc' },
    });

    if (inventories.length === 0) return [];

    // supplement_id로 supplements + ingredients 별도 조회
    const supplementIds = [
      ...new Set(inventories.map((inv) => inv.supplement_id)),
    ];

    const supplements = await this.prisma.supplements.findMany({
      where: { id: { in: supplementIds } },
    });

    const suppProductNames = supplements
      .map((s) => s.product_name)
      .filter(Boolean) as string[];

    const allIngredients = suppProductNames.length > 0
      ? await this.prisma.supplementsIngredients.findMany({
          where: { product_name: { in: suppProductNames } },
        })
      : [];

    const supplementMap = new Map(
      supplements.map((s) => [s.id.toString(), s]),
    );

    const reminders = inventories.flatMap((item) => {
      const supplement = supplementMap.get(item.supplement_id.toString());
      const alarmTimes = Array.isArray(item.alarm_times)
        ? (item.alarm_times as string[])
        : [];

      const suppIngredients = allIngredients.filter(
        (ing) => ing.product_name === supplement?.product_name,
      );

      return alarmTimes.map((time, index) => {
        const log = item.daily_supplements.find(
          (daily) => daily.dose_index === index,
        );
        const isTaken = log?.is_taken === true;

        return {
          inventoryId: item.id.toString(),
          userUuid: item.user_uuid,
          supplementId: item.supplement_id.toString(),
          supplementName: supplement?.product_name ?? '',
          brandName: supplement?.brand_name ?? null,
          imageUrl: supplement?.image_url ?? null,
          doseIndex: index,
          supplementTime: time,
          date: today.toISOString().slice(0, 10),
          isTaken,
          status: this.getReminderStatus(time, isTaken),
          stockCount: item.stock_count ?? 0,
          totalCount: item.total_count ?? 0,
          ingredients: suppIngredients.map((ing) => ({
            ingredient_name: ing.ingredient_name,
            amount: ing.amount,
            unit: ing.unit,
          })),
        };
      });
    });

    return reminders.sort((a, b) => {
      const priority: Record<string, number> = {
        DUE: 1, MISSED: 2, UPCOMING: 3, TAKEN: 4,
      };
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
        where: { id: inventoryId, user_uuid: dto.userUuid, status: 'active' },
      });
      if (!inventory) throw new NotFoundException('Cabinet item not found');

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
        const dailyFrequency = Math.max(1, inventory.daily_frequency ?? 1);
        const dosePerTime = Math.max(
          1,
          Math.ceil((inventory.daily_dose ?? 1) / dailyFrequency),
        );
        await tx.supplementInventory.update({
          where: { id: inventoryId },
          data: {
            stock_count: Math.max(0, (inventory.stock_count ?? 0) - dosePerTime),
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
        where: { id: inventoryId, user_uuid: dto.userUuid, status: 'active' },
      });
      if (!inventory) throw new NotFoundException('Cabinet item not found');

      const existing = await tx.dailySupplements.findFirst({
        where: {
          user_uuid: dto.userUuid,
          inventory_id: inventoryId,
          date,
          dose_index: dto.doseIndex,
        },
      });

      if (!existing || !existing.is_taken) return existing;

      const log = await tx.dailySupplements.update({
        where: { id: existing.id },
        data: { is_taken: false, taken_at: null },
      });

      const dailyFrequency = Math.max(1, inventory.daily_frequency ?? 1);
      const dosePerTime = Math.max(
        1,
        Math.ceil((inventory.daily_dose ?? 1) / dailyFrequency),
      );
      const currentStock = inventory.stock_count ?? 0;
      const totalCount = inventory.total_count ?? 0;
      const nextStock = totalCount > 0
        ? Math.min(totalCount, currentStock + dosePerTime)
        : currentStock + dosePerTime;

      await tx.supplementInventory.update({
        where: { id: inventoryId },
        data: { stock_count: nextStock },
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
    return gender === 'male' ? '남자' : '여자';
  }

  private toBigIntOrNull(value: unknown) {
    if (value === null || value === undefined) return null;
    const raw = String(value).trim();
    if (!/^\d+$/.test(raw)) return null;
    return BigInt(raw);
  }
}