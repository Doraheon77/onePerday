import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class RecommendService {
  constructor(private prisma: PrismaService) { }

  // 만성질환별 피해야 할 주의 성분 매핑 (DB의 conditions 컬럼 ID 기준)
  // 1: 고혈압, 2: 당뇨, 3: 고지혈증, 4: 심장질환, 5: 신장질환, 6: 간질환, 7: 갑상선 질환, 8: 골다공증, 9: 관절염, 10: 빈혈
  private readonly contraindicationMap: Record<string, string[]> = {
    '1': ['나트륨', '감초'],
    '2': ['당류'],
    '3': ['콜레스테롤', '포화지방산'],
    '4': ['나트륨'],
    '5': ['칼륨', '인'],
    '6': ['비타민 A', '철'],
    '7': ['요오드'],
    '8': ['인'],
    '9': ['당류', '포화지방산'],
    '10': ['아연'],
  };

  // 건강 목표 ID에 따른 DB target_area 분석용 매칭 키워드 정의
  private readonly goalKeywordMap: Record<string, string[]> = {
    '1': ['눈', '망막'],             // 눈 건강
    '2': ['관절'],                  // 관절 건강
    '3': ['면역계', '면역'],         // 면역력 증진
    '4': ['에너지', '피로', '근육', '세포'], // 피로 회복
    '5': ['장', '소화계'],           // 장 건강
    '6': ['피부'],                  // 피부 개선
    '7': ['뼈', '치아'],             // 뼈/치아 건강
    '8': ['심혈관', '혈관', '심장'],  // 혈행 개선
    '9': ['뇌', '신경계'],           // 두뇌/기억력 개선
    '10': ['지방', '콜레스테롤'],    // 다이어트
    '11': ['수면', '스트레스', '신경계'], // 스트레스 케어
    '12': ['머리', '손톱', '발톱', '모발'], // 모발/손톱 영양
    '13': ['간'],                  // 간 건강
  };

  // 알레르기 ID별 키워드 매핑 (DB의 allergies 컬럼 ID 기준)
  // 1: 견과류, 2: 갑각류, 3: 생선, 4: 유제품, 5: 달걀, 6: 글루텐, 7: 대두
  private readonly allergyMap: Record<string, string> = {
    '1': '견과류',
    '2': '갑각류',
    '3': '생선',
    '4': '유제품',
    '5': '달걀',
    '6': '글루텐',
    '7': '대두',
  };

  async getPersonalizedRecommendations(userId: string) {
    // 1. 사용자 건강 정보 조회 (users_info 테이블 사용)
    let userInfo: any = null;
    try {
      userInfo = await this.prisma.usersInfo.findUnique({
        where: { id: userId },
      });
    } catch (error) {
      // UUID 형식 불일치 등 예외 발생 시 기본값으로 대응하기 위해 null 유지
    }

    if (!userInfo) {
      userInfo = {
        id: userId,
        name: '사용자',
        gender: null,
        birth_year: null,
        health_goals: [],
        conditions: [],
        allergies: [],
        special_notes: [],
        created_at: new Date(),
      };
    }

    // health_goals(건강 목표) 및 conditions(만성질환)은 BigInt 배열로 들어옵니다.
    // 2. 피해야 할 성분(Avoid List) 도출
    const avoidIngredients = new Set<string>();

    // conditions(만성질환 ID) 기반 주의 성분 추출
    if (userInfo.conditions && Array.isArray(userInfo.conditions)) {
      for (const conditionId of userInfo.conditions) {
        const idStr = conditionId.toString();
        if (this.contraindicationMap[idStr]) {
          this.contraindicationMap[idStr].forEach((i) => avoidIngredients.add(i));
        }
      }
    }

    const avoidList = Array.from(avoidIngredients);

    // 2.2 알레르기 유발성분 한글 키워드 도출 (DB의 allergies 컬럼 ID 기준)
    const avoidAllergyKeywords = new Set<string>();
    if (userInfo.allergies && Array.isArray(userInfo.allergies)) {
      for (const allergyId of userInfo.allergies) {
        const idStr = allergyId.toString();
        if (this.allergyMap[idStr]) {
          avoidAllergyKeywords.add(this.allergyMap[idStr]);
        }
      }
    }
    const allergyList = Array.from(avoidAllergyKeywords);

    // 3. 영양제 1차 필터링 (가격이 NULL이 아니고 만성질환 주의 성분이 포함되지 않은 영양제)
    const conflictingProducts = avoidList.length > 0
      ? await this.prisma.supplementsIngredients.findMany({
        where: {
          OR: avoidList.map((ingredient) => ({
            ingredient_name: { contains: ingredient },
          })),
        },
        select: { product_name: true },
      })
      : [];
    const conflictingProductNames = conflictingProducts
      .map((cp) => cp.product_name)
      .filter(Boolean) as string[];

    const dbSupplementsTemp = await this.prisma.supplementsTemp.findMany({
      where: {
        price: { not: null }, // 가격이 NULL인 항목 제외
        ...(conflictingProductNames.length > 0 && {
          product_name: {
            notIn: conflictingProductNames,
          },
        }),
      },
    });

    const productNames = dbSupplementsTemp.map((p) => p.product_name).filter(Boolean) as string[];
    const ingredients = await this.prisma.supplementsIngredients.findMany({
      where: { product_name: { in: productNames } },
    });

    const dbSupplements = dbSupplementsTemp.map((product) => ({
      ...product,
      supplements_ingredients: ingredients.filter((ing) => ing.product_name === product.product_name),
    }));

    // 3.2 알레르기 소거 (DB 상세 정보 공백 보완을 위해 영양제명, 브랜드명 및 성분명 통합 체크)
    const safeSupplements = dbSupplements.filter((supplement) => {
      if (allergyList.length === 0) return true;

      const productName = supplement.product_name || '';
      const brandName = supplement.brand_name || '';
      const ingredients = supplement.ingredients.map(
        (i) => i.ingredient_name || '',
      );

      // 알레르기 유발 물질이 상품명, 브랜드명 또는 성분 중 하나에라도 포함되어 있으면 소거
      const hasAllergyConflict = allergyList.some((allergy) => {
        if (productName.includes(allergy)) return true;
        if (brandName.includes(allergy)) return true;
        if (ingredients.some((ing) => ing.includes(allergy))) return true;
        return false;
      });

      return !hasAllergyConflict;
    });

    // 4. 영양제 2차 필터링 (맞춤 추천 스코어링)
    const targetIngredients = new Set<string>();

    // health_goals(목표 ID) 기반 가점 대상 성분 추출
    if (userInfo.health_goals && Array.isArray(userInfo.health_goals)) {
      // DB에서 실시간으로 영양성분 가이드 테이블 전체 조회
      const guides = await this.prisma.nutrientGuide.findMany();

      for (const goalId of userInfo.health_goals) {
        const idStr = goalId.toString();
        const keywords = this.goalKeywordMap[idStr] || [];

        // 유저의 건강 목표 키워드가 target_area에 들어 있는 성분들을 동적으로 수집
        for (const guide of guides) {
          if (!guide.nutrient_name || !guide.target_area) continue;

          const targetAreas = guide.target_area;

          const isMatched = targetAreas.some((area) =>
            keywords.some((keyword) => area.includes(keyword))
          );

          if (isMatched) {
            targetIngredients.add(guide.nutrient_name);
          }
        }
      }
    }

    // 타겟 성분이 있다면 스코어링, 없다면 기본 정렬
    const recommendedList = safeSupplements.map((supplement) => {
      const productName = supplement.product_name || '';
      const brandName = supplement.brand_name || '';
      const ingredients = supplement.ingredients.map(
        (i) => i.ingredient_name || '',
      );

      const score = this.calculateGoalScore(
        productName,
        brandName,
        ingredients,
        targetIngredients,
      );

      return {
        ...supplement,
        score,
      };
    });

    // 5. 점수 내림차순 정렬 (점수가 높은 것이 위로 오도록)
    recommendedList.sort((a, b) => b.score - a.score);

    // 상위 10개만 반환 (필요시 조절 가능)
    const topRecommendations = recommendedList.slice(0, 10);

    // 6. 유저 연령/성별 기반 일일 권장량(dailyPercent) 계산 추가
    const currentYear = new Date().getFullYear();
    const userAge = userInfo.birth_year ? currentYear - userInfo.birth_year : 30;
    const mappedGender = this.mapGender(userInfo.gender);

    const standards = await this.prisma.nutrientStandards.findMany({
      where: {
        gender: mappedGender,
        age_min: { lte: userAge },
        age_max: { gte: userAge },
      }
    });

    const enrichedRecommendations = topRecommendations.map((product) => {
      const mappedIngredients = product.ingredients.map((ing) => {
        const std = standards.find((s) => s.nutrient_name === ing.ingredient_name);
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

    // BigInt 직렬화 처리 (JSON 파싱/문자열화)
    return JSON.parse(
      JSON.stringify(enrichedRecommendations, (key, value) =>
        typeof value === 'bigint' ? value.toString() : value,
      ),
    );
  }

  /**
   * 건강 목표 가치 대비 맞춤 추천 점수를 산출하는 도우미 함수 (향후 확장 가능 구조)
   */
  private calculateGoalScore(
    productName: string,
    brandName: string,
    ingredients: string[],
    targetIngredients: Set<string>,
  ): number {
    let score = 0;
    const targets = Array.from(targetIngredients);

    for (const target of targets) {
      // 1. 상품명이나 브랜드명에 가점 목표 성분이 포함된 경우 (DB 성분 정보 보완)
      if (productName.includes(target) || brandName.includes(target)) {
        score += 15; // 상품명/브랜드명 일치는 직관성이 높으므로 15점 가점
      }
      // 2. 실제 성분 데이터베이스에 성분이 매칭되는 경우
      const hasIngredient = ingredients.some((ing) => ing.includes(target));
      if (hasIngredient) {
        score += 10;
      }
    }

    return score;
  }

  /**
   * 유저 프로필 성별('남성'/'여성')을 데이터베이스 표준 성별('남자'/'여자')로 매핑
   */
  private mapGender(gender: string | null): string {
    if (!gender) return '남자';
    const g = gender.trim();
    if (g === '남성' || g === '남자' || g.toLowerCase() === 'male' || g.toLowerCase() === 'm') {
      return '남자';
    }
    if (g === '여성' || g === '여자' || g.toLowerCase() === 'female' || g.toLowerCase() === 'f') {
      return '여자';
    }
    return '남자'; // 기본값 폴백
  }
}
