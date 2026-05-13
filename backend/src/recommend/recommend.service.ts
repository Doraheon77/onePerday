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

  // 건강 목표별 추천 성분 매핑 (DB의 health_goals 컬럼 ID 기준)
  // 1: 눈 건강, 2: 관절, 3: 면역력, 4: 활력, 5: 장 건강, 6: 피부, 7: 뼈, 8: 심혈관, 9: 두뇌, 10: 체중, 11: 수면, 12: 모발/손톱
  private readonly benefitMap: Record<string, string[]> = {
    '1': ['루테인', '지아잔틴', '오메가3', '비타민A'],
    '2': ['MSM', '글루코사민', '콘드로이친', '보스웰리아'],
    '3': ['아연', '비타민D', '비타민C', '프로폴리스'],
    '4': ['비타민B', '밀크씨슬', '홍삼', '테아닌', '마그네슘'],
    '5': ['유산균', '프로바이오틱스', '프리바이오틱스'],
    '6': ['콜라겐', '비타민C', '히알루론산'],
    '7': ['칼슘', '비타민D', '마그네슘', '비타민K'],
    '8': ['오메가3', '코엔자임Q10', '홍삼'],
    '9': ['오메가3', '포스파티딜세린', '은행잎'],
    '10': ['가르시니아', '카테킨', 'CLA'],
    '11': ['마그네슘', '테아닌', '락티움'],
    '12': ['비오틴', '맥주효모', '콜라겐'],
  };

  async getPersonalizedRecommendations(userId: string) {
    // 1. 사용자 건강 정보 조회 (users_info 테이블 사용)
    const userInfo = await this.prisma.users_info.findUnique({
      where: { id: userId },
    });

    if (!userInfo) {
      throw new NotFoundException('해당 사용자의 건강 정보를 찾을 수 없습니다.');
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

    // 3. 영양제 1차 필터링 (가격이 NULL이 아니고 주의 성분이 포함되지 않은 영양제)
    const safeSupplements = await this.prisma.supplements.findMany({
      where: {
        price: { not: null }, // 가격이 NULL인 항목 제외
        ...(avoidList.length > 0 && {
          NOT: {
            supplements_ingredients: {
              some: {
                OR: avoidList.map((ingredient) => ({
                  ingredient_name: { contains: ingredient },
                })),
              },
            },
          },
        }),
      },
      include: {
        supplements_ingredients: true, // 점수 계산을 위해 성분 정보 가져오기
      },
    });

    // 4. 영양제 2차 필터링 (맞춤 추천 스코어링)
    const targetIngredients = new Set<string>();

    // health_goals(목표 ID) 기반 가점 대상 성분 추출
    if (userInfo.health_goals && Array.isArray(userInfo.health_goals)) {
      for (const goalId of userInfo.health_goals) {
        const idStr = goalId.toString();
        if (this.benefitMap[idStr]) {
          this.benefitMap[idStr].forEach((i) => targetIngredients.add(i));
        }
      }
    }

    // 타겟 성분이 있다면 스코어링, 없다면 기본 정렬
    const recommendedList = safeSupplements.map((supplement) => {
      let score = 0;
      const ingredients = supplement.supplements_ingredients.map((i) => i.ingredient_name || '');

      // 가점 로직: 타겟 성분이 포함되어 있으면 점수 부여
      ingredients.forEach((ingredient) => {
        Array.from(targetIngredients).forEach((target) => {
          if (ingredient.includes(target)) {
            score += 10;
          }
        });
      });

      return {
        ...supplement,
        score,
      };
    });

    // 5. 점수 내림차순 정렬 (점수가 높은 것이 위로 오도록)
    recommendedList.sort((a, b) => b.score - a.score);

    // 상위 10개만 반환 (필요시 조절 가능)
    const topRecommendations = recommendedList.slice(0, 10);

    // BigInt 직렬화 처리 (JSON 파싱/문자열화)
    return JSON.parse(
      JSON.stringify(topRecommendations, (key, value) =>
        typeof value === 'bigint' ? value.toString() : value,
      ),
    );
  }
}
