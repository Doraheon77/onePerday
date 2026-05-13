import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class RecommendService {
  constructor(private prisma: PrismaService) {}

  // 만성질환별 피해야 할 주의 성분 매핑
  // DB의 supplements_ingredients 테이블에 존재하는 '영양소명' 기준
  private readonly contraindicationMap: Record<string, string[]> = {
    '고혈압': ['나트륨', '감초'], 
    '당뇨': ['당류'], 
    '고지혈증': ['콜레스테롤', '포화지방산'], 
    '심장질환': ['나트륨'],
    '신장질환': ['칼륨', '인'], // 신장 기능 저하 시 배출이 어려운 미네랄
    '간질환': ['비타민 A', '철'], // 간 독성 주의 및 철분 과다 축적 방지
    '갑상선 질환': ['요오드'], // 갑상선 호르몬에 영향을 주는 요오드 주의
    '골다공증': ['인'], // 인 과다 섭취 시 칼슘 배출 촉진 우려
    '관절염': ['당류', '포화지방산'], // 염증 악화 가능성
    '빈혈': ['아연'], // 고용량 아연은 구리 흡수를 방해해 빈혈 악화 가능성
  };

  // 증상별 추천(가점 부여) 성분 매핑 (예시)
  private readonly benefitMap: Record<string, string[]> = {
    '피로': ['비타민B', '밀크씨슬', '홍삼', '테아닌', '마그네슘'],
    '안구건조': ['루테인', '지아잔틴', '오메가3', '비타민A'],
    '관절염': ['MSM', '글루코사민', '콘드로이친', '보스웰리아'],
    '수면장애': ['마그네슘', '테아닌', '락티움'],
    '면역력저하': ['아연', '비타민D', '비타민C', '프로폴리스'],
  };

  async getPersonalizedRecommendations(userId: string) {
    // 1. 사용자 건강 정보 조회 (users_info 테이블 사용)
    const userInfo = await this.prisma.users_info.findUnique({
      where: { id: userId },
    });

    if (!userInfo) {
      throw new NotFoundException('해당 사용자의 건강 정보를 찾을 수 없습니다.');
    }

    // 2. 피해야 할 성분(Avoid List) 도출
    const avoidIngredients = new Set<string>();

    // health_status(만성질환) 기반 주의 성분 추출 (문자열 내 포함 여부 또는 쉼표 분리 가정)
    if (userInfo.health_status) {
      const diseases = userInfo.health_status.split(',').map((d) => d.trim());
      for (const disease of diseases) {
        if (this.contraindicationMap[disease]) {
          this.contraindicationMap[disease].forEach((i) => avoidIngredients.add(i));
        }
      }
    }

    // symptoms(증상/알러지) 기반 주의 성분 추출
    if (userInfo.symptoms && Array.isArray(userInfo.symptoms)) {
      for (const symptom of userInfo.symptoms) {
        if (this.contraindicationMap[symptom]) {
          this.contraindicationMap[symptom].forEach((i) => avoidIngredients.add(i));
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
    const targetSymptoms = userInfo.symptoms || [];
    const targetIngredients = new Set<string>();

    for (const symptom of targetSymptoms) {
      if (this.benefitMap[symptom]) {
        this.benefitMap[symptom].forEach((i) => targetIngredients.add(i));
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
