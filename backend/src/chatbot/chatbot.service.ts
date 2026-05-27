import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { GeminiService } from '../ai/gemini.service';
import { ChatMessageDto } from './dto/chat-message.dto';

interface RetrievedProduct {
  id: bigint;
  product_name: string | null;
  brand_name: string | null;
  category: string | null;
  supplements_ingredients: {
    ingredient_name: string | null;
    amount: number | null;
    unit: string | null;
  }[];
}

@Injectable()
export class ChatbotService {
  private readonly logger = new Logger(ChatbotService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly geminiService: GeminiService,
  ) {}

  async answer(dto: ChatMessageDto) {
    const products = await this.retrieveProducts(dto.message);
    const safeProducts = products.filter(
      (product) => !this.isBlockedByProfile(product, dto.userProfile),
    );
    const blockedProducts = products.filter((product) =>
      this.isBlockedByProfile(product, dto.userProfile),
    );

    if (safeProducts.length === 0) {
      return {
        answer: this.buildNoRagAnswer(blockedProducts),
        products: safeProducts,
        filteredProducts: blockedProducts,
      };
    }

    const systemInstruction = this.buildSystemInstruction(
      safeProducts,
      blockedProducts,
      dto,
    );
    const userPrompt = [
      `사용자 질문: ${dto.message}`,
      '',
      '[최종 답변 생성 규칙]',
      '1. 아래 시스템 프롬프트의 [답변에 사용할 수 있는 DB 제품] 섹션만 근거로 답하세요.',
      '2. DB 제품 섹션에 없는 제품명, 성분, 효능, 복용법, 주의사항은 절대 생성하지 마세요.',
      '3. 질문에 필요한 근거가 DB 제품 섹션에 없으면 "DB 검색 결과만으로는 답변할 수 없습니다."라고 답하세요.',
      '4. 사용자 건강 정보는 추천 제외/주의 문장에만 사용하고, 새로운 의학 지식을 보태지 마세요.',
    ].join('\n');

    try {
      const answer = await this.geminiService.generateText(
        systemInstruction,
        userPrompt,
        { temperature: 0.0 },
      );

      return {
        answer,
        products: safeProducts,
        filteredProducts: blockedProducts,
      };
    } catch (error) {
      this.logger.warn(`Gemini fallback used: ${String(error)}`);
      return {
        answer: this.buildFallbackAnswer(dto.message, safeProducts, blockedProducts),
        products: safeProducts,
        filteredProducts: blockedProducts,
      };
    }
  }

  async retrieveProducts(message: string) {
    const terms = this.extractTerms(message);

    // 성분명 기준 1차 필터링
    const matchingIngredients = terms.length > 0
      ? await this.prisma.supplementsIngredients.findMany({
          where: {
            OR: terms.map((term) => ({
              ingredient_name: {
                contains: term,
                mode: 'insensitive' as const,
              },
            })),
          },
          select: { product_name: true },
        })
      : [];
    const matchingProductNames = matchingIngredients
      .map((mi) => mi.product_name)
      .filter(Boolean) as string[];

    const where =
      terms.length > 0
        ? {
            OR: [
              ...terms.flatMap((term) => [
                { product_name: { contains: term, mode: 'insensitive' as const } },
                { brand_name: { contains: term, mode: 'insensitive' as const } },
                { category: { contains: term, mode: 'insensitive' as const } },
              ]),
              ...(matchingProductNames.length > 0
                ? [{ product_name: { in: matchingProductNames } }]
                : []),
            ],
          }
        : {};

    const products = await this.prisma.supplementsTemp.findMany({
      where,
      take: 8,
    });

    const productNames = products.map((p) => p.product_name).filter(Boolean) as string[];
    const ingredients = await this.prisma.supplementsIngredients.findMany({
      where: { product_name: { in: productNames } },
    });

    return products.map((product) => ({
      ...product,
      supplements_ingredients: ingredients.filter((ing) => ing.product_name === product.product_name),
    }));
  }

  private extractTerms(message: string) {
    const normalized = message
      .replace(/[^\p{L}\p{N}\s]/gu, ' ')
      .split(/\s+/)
      .map((term) => term.trim())
      .filter(Boolean);

    const stopWords = new Set([
      '영양제',
      '추천',
      '복용',
      '먹어도',
      '먹는',
      '언제',
      '좋아요',
      '있나요',
      '부작용',
      '같이',
      '하면',
      '안되는',
      '차이',
      '공복',
    ]);

    return Array.from(
      new Set(
        normalized.filter((term) => term.length >= 2 && !stopWords.has(term)),
      ),
    ).slice(0, 8);
  }

  private buildSystemInstruction(
    products: RetrievedProduct[],
    blockedProducts: RetrievedProduct[],
    dto: ChatMessageDto,
  ) {
    const profile = dto.userProfile;
    const currentSupplements = dto.currentSupplements ?? [];

    return [
      '당신은 OnePerDay 앱의 DB RAG 전용 응답 엔진입니다.',
      '모델 기준: Flash 계열 저지연 모델. 창의적 생성보다 근거 제한과 거절을 최우선으로 합니다.',
      '',
      '[절대 규칙]',
      '1. 답변의 유일한 지식 출처는 [답변에 사용할 수 있는 DB 제품] 섹션입니다.',
      '2. DB 제품 섹션에 없는 제품명, 브랜드명, 성분명, 용량, 효능, 부작용, 복용 시간, 상호작용은 절대 말하지 않습니다.',
      '3. 일반 상식, 사전지식, 의학/영양학 배경지식, 인터넷 지식을 사용하지 않습니다.',
      '4. 질문이 일반 건강상담이어도 DB 제품 섹션에 근거가 없으면 답하지 않습니다.',
      '5. 추론해서 보충하지 않습니다. 비어 있는 값, 미상 값, 유사해 보이는 제품 정보를 채워 넣지 않습니다.',
      '6. 추천 제외 제품은 추천하지 않습니다. 제외 사유도 아래 데이터에 근거한 범위에서만 짧게 말합니다.',
      '7. 근거 부족 시 반드시 "DB 검색 결과만으로는 답변할 수 없습니다."라고 답합니다.',
      '',
      '[답변 형식]',
      '- 한국어로 답합니다.',
      '- 먼저 DB 근거가 있는지 말합니다.',
      '- 제품을 언급할 때는 DB 제품명 그대로만 씁니다.',
      '- DB에 근거가 있는 항목만 짧은 bullet로 답합니다.',
      '- DB 근거 밖 설명, 일반 복용 팁, 의학 조언, 임의 주의사항은 금지합니다.',
      '',
      '[사용자 건강 정보]',
      `이름: ${profile?.name || '미입력'}`,
      `성별: ${profile?.gender || '미입력'}`,
      `나이: ${profile?.age ?? '미입력'}`,
      `건강 목표: ${(profile?.goals ?? []).join(', ') || '미입력'}`,
      `보유 질환: ${(profile?.healthConditions ?? []).join(', ') || '없음'}`,
      `알러지: ${(profile?.allergies ?? []).join(', ') || '없음'}`,
      `흡연: ${profile?.smokingStatus || '미입력'}`,
      `음주: ${profile?.drinkingStatus || '미입력'}`,
      `임신/수유: ${profile?.pregnancyStatus || '미입력'}`,
      '',
      '[현재 등록된 영양제]',
      currentSupplements.length
        ? currentSupplements
            .map((item) => {
              const nutrients =
                item.nutrients?.map((nutrient) => nutrient.name).join(', ') ||
                '성분 미입력';
              return `- ${item.name} (${item.brand || '브랜드 미입력'}): ${nutrients}`;
            })
            .join('\n')
        : '등록된 영양제 없음',
      '',
      '[답변에 사용할 수 있는 DB 제품]',
      products.length
        ? products.map((product) => this.formatProduct(product)).join('\n')
        : '검색된 DB 제품 없음',
      '',
      '[사용자 정보 기준 추천 제외 제품]',
      blockedProducts.length
        ? blockedProducts.map((product) => this.formatProduct(product)).join('\n')
        : '없음',
    ].join('\n');
  }

  private formatProduct(product: RetrievedProduct) {
    const ingredients = product.supplements_ingredients
      .map((ingredient) => {
        const amount =
          ingredient.amount != null
            ? `${ingredient.amount}${ingredient.unit ?? ''}`
            : '';
        return `${ingredient.ingredient_name ?? '성분명 미상'}${amount ? ` ${amount}` : ''}`;
      })
      .join(', ');

    return `- ${product.product_name} / 브랜드: ${
      product.brand_name ?? '미상'
    } / 카테고리: ${product.category ?? '미상'} / 성분: ${
      ingredients || '성분 데이터 없음'
    }`;
  }

  private isBlockedByProfile(
    product: RetrievedProduct,
    profile: ChatMessageDto['userProfile'],
  ) {
    const allergies = profile?.allergies ?? [];
    const healthConditions = profile?.healthConditions ?? [];
    if (allergies.length === 0 && healthConditions.length === 0) return false;

    const searchable = [
      product.product_name,
      product.brand_name,
      product.category,
      ...product.supplements_ingredients.map(
        (ingredient) => ingredient.ingredient_name,
      ),
    ]
      .filter(Boolean)
      .join(' ')
      .toLowerCase();

    const allergyKeywords: Record<string, string[]> = {
      갑각류: ['크릴', '새우', '게', 'shellfish', 'krill'],
      생선: ['어유', '오메가', 'fish', 'dha', 'epa'],
      유제품: ['유청', '우유', 'whey', 'milk', 'casein'],
      달걀: ['달걀', '계란', 'egg'],
      글루텐: ['글루텐', '밀', 'wheat', 'gluten'],
      대두: ['대두', '콩', 'soy'],
      견과류: ['견과', '아몬드', '호두', 'nut'],
    };

    const healthKeywords: Record<string, string[]> = {
      신장질환: ['마그네슘', '칼륨', 'potassium', 'magnesium'],
      간질환: ['고함량', '레티놀', '비타민a'],
      갑상선질환: ['요오드', '아이오딘', '켈프', 'iodine', 'kelp'],
      고혈압: ['나트륨', '감초', 'sodium', 'licorice'],
      빈혈: ['칼슘', 'calcium'],
    };

    const matchedAllergy = allergies.some((allergy) =>
      (allergyKeywords[allergy] ?? [allergy]).some((keyword) =>
        searchable.includes(keyword.toLowerCase()),
      ),
    );

    const matchedHealth = healthConditions.some((condition) =>
      (healthKeywords[condition.replace(/\s/g, '')] ?? [condition]).some(
        (keyword) => searchable.includes(keyword.toLowerCase()),
      ),
    );

    return matchedAllergy || matchedHealth;
  }

  private buildFallbackAnswer(
    message: string,
    products: RetrievedProduct[],
    blockedProducts: RetrievedProduct[],
  ) {
    if (products.length === 0) {
      return this.buildNoRagAnswer(blockedProducts);
    }

    const first = products[0];
    const blockedText = blockedProducts.length
      ? `\n\n추천 제외 제품: ${blockedProducts
          .map((item) => item.product_name)
          .join(', ')} 제품은 추천에서 제외했습니다.`
      : '';

    return [
      `DB 검색 결과에서 "${message}"와 관련된 제품으로 ${first.product_name}을(를) 찾았습니다.`,
      '다만 LLM 응답 생성이 실패하여 DB 검색 결과 외 내용은 제공하지 않습니다.',
      blockedText,
    ].join('\n');
  }

  private buildNoRagAnswer(blockedProducts: RetrievedProduct[]) {
    const blockedText = blockedProducts.length
      ? `\n\n사용자 건강 정보 기준으로 제외된 DB 제품: ${blockedProducts
          .map((item) => item.product_name)
          .join(', ')}`
      : '';

    return [
      'DB 검색 결과만으로는 답변할 수 없습니다.',
      'OnePerDay DB RAG 검색 결과에 포함된 제품과 필드만 근거로 답변하도록 제한되어 있습니다.',
      blockedText,
    ].join('\n');
  }
}
