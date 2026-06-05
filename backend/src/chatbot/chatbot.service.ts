import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { GeminiService, GroundingChunk } from '../ai/gemini.service';
import { ChatMessageDto } from './dto/chat-message.dto';

interface RetrievedProduct {
  id: bigint;
  product_name: string | null;
  brand_name: string | null;
  category: string | null;
  ingredients: {
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

  // ────────────────────────────────────────────────────────
  // 메인 응답 로직 — DB 검색 + 인터넷 그라운딩 + 고추론(High)
  // ────────────────────────────────────────────────────────
  async answer(dto: ChatMessageDto) {
    const products = await this.retrieveProducts(dto.message);
    const safeProducts = products.filter(
      (product) => !this.isBlockedByProfile(product, dto.userProfile),
    );
    const blockedProducts = products.filter((product) =>
      this.isBlockedByProfile(product, dto.userProfile),
    );

    const systemInstruction = this.buildSystemInstruction(
      safeProducts,
      blockedProducts,
      dto,
    );
    const userPrompt = this.buildUserPrompt(dto.message, safeProducts.length);

    try {
      // Google Search 그라운딩 활성화 + 추론 레벨 High
      const result = await this.geminiService.generateTextWithGrounding(
        systemInstruction,
        userPrompt,
        {
          temperature: 0.3,
          enableGrounding: true,
          thinkingLevel: 'high',
        },
      );

      return {
        answer: result.text,
        products: safeProducts,
        filteredProducts: blockedProducts,
        sources: this.formatGroundingSources(
          result.groundingMetadata?.groundingChunks,
        ),
      };
    } catch (error) {
      this.logger.warn(`Gemini fallback used: ${String(error)}`);
      return {
        answer: this.buildFallbackAnswer(dto.message, safeProducts, blockedProducts),
        products: safeProducts,
        filteredProducts: blockedProducts,
        sources: [],
      };
    }
  }

  // ────────────────────────────────────────────────────────
  // 그라운딩 출처 포맷팅 — 프론트엔드에서 활용 가능한 형태로 변환
  // ────────────────────────────────────────────────────────
  private formatGroundingSources(
    chunks?: GroundingChunk[],
  ): { title: string; url: string }[] {
    if (!chunks || chunks.length === 0) return [];
    return chunks
      .filter((chunk) => chunk.web?.uri)
      .map((chunk) => ({
        title: chunk.web?.title ?? '출처',
        url: chunk.web?.uri ?? '',
      }));
  }

  // ────────────────────────────────────────────────────────
  // DB 검색 — 사용자 메시지에서 핵심 키워드를 추출하여 제품 조회
  // ────────────────────────────────────────────────────────
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
      ingredients: ingredients.filter((ing) => ing.product_name === product.product_name),
    }));
  }

  // ────────────────────────────────────────────────────────
  // 키워드 추출 — 한국어 어미/조사를 정규화한 뒤 불용어 제거
  //
  // [수정] 기존 문제: '좋아요', '있나요', '먹어도' 등 한국어
  // 문장의 어미가 stopWords에 포함되어 있어, 반말·존댓말 표현에
  // 따라 의미 있는 검색 키워드까지 함께 제거되던 버그 수정.
  // → 어미/조사를 먼저 strip한 뒤 어근만 남겨 불용어와 비교.
  // ────────────────────────────────────────────────────────
  private extractTerms(message: string) {
    // 1) 특수문자 제거 & 토큰 분리
    const tokens = message
      .replace(/[^\p{L}\p{N}\s]/gu, ' ')
      .split(/\s+/)
      .map((t) => t.trim())
      .filter(Boolean);

    // 2) 한국어 어미·조사 정규화 — 반말/존댓말 차이를 흡수
    const suffixPattern = new RegExp(
      '(이요|에요|예요|인가요|인가|을까요|을까|는요|나요|' +
      '해도|어도|여도|하면|으면|이면|해요|하죠|죠|하고|' +
      '할까요|할까|은요|ㅂ니다|습니다|세요|십시오|' +
      '인데요|인데|거든요|거든|잖아요|잖아|는데요|는데|' +
      '어요|아요|여요)$',
    );

    const normalized = tokens.map((token) =>
      token.replace(suffixPattern, ''),
    ).filter((t) => t.length >= 1);

    // 3) 의미 없는 일반 동사·접속사만 제거 (영양 키워드는 보존)
    const stopWords = new Set([
      '영양제', '추천해', '추천', '알려', '설명', '궁금',
      '뭐', '뭔가', '어떤', '어떻게', '왜',
      '그리고', '그런데', '그래서', '근데',
      '좀', '제가', '저는', '나는', '내가',
      '해주', '알려줘', '말해줘', '해줘',
      '수', '있', '없', '것', '거',
    ]);

    const terms = Array.from(
      new Set(
        normalized.filter((term) => term.length >= 2 && !stopWords.has(term)),
      ),
    ).slice(0, 8);

    this.logger.debug(`[extractTerms] "${message}" → [${terms.join(', ')}]`);
    return terms;
  }

  // ────────────────────────────────────────────────────────
  // 시스템 프롬프트 — 4-Tier 지식 계층 + 인터넷 검색 그라운딩
  //                  + 고추론(High) 최적화
  // ────────────────────────────────────────────────────────
  private buildSystemInstruction(
    products: RetrievedProduct[],
    blockedProducts: RetrievedProduct[],
    dto: ChatMessageDto,
  ) {
    const profile = dto.userProfile;
    const currentSupplements = dto.currentSupplements ?? [];
    const hasDbProducts = products.length > 0;

    return [
      // ── 역할 정의 ──
      '# 역할',
      '당신은 OnePerDay 영양제 관리 앱의 AI 영양 상담사입니다.',
      '사용자가 편하게 말을 걸면 친근하고 정확하게 답변합니다.',
      '당신은 DB 데이터와 인터넷 검색을 활용하여 근거 기반의 신뢰할 수 있는 상담을 제공합니다.',
      '',

      // ── 대화 스타일 ──
      '# 대화 스타일',
      '- 항상 한국어 존댓말(해요체)로 답변합니다.',
      '- 사용자가 반말, 존댓말, 줄임말, 구어체 어떤 말투로 질문하든 동일하게 성실히 답변합니다.',
      '- 말투, 맞춤법, 문법 오류를 이유로 답변을 거부하지 않습니다.',
      '- 딱딱한 시스템 메시지 톤이 아닌, 친근한 영양사 선생님 톤을 유지합니다.',
      '- 답변은 간결하되 충분히 설명합니다. 글머리 기호(•)를 활용해 가독성을 높입니다.',
      '',

      // ── 4-Tier 지식 계층 규칙 ──
      '# 지식 사용 규칙 (4-Tier 계층)',
      '',
      '## Tier 1 — DB 제품 데이터 (최우선)',
      '아래 [DB 제품 데이터]에 해당 제품이 있으면, 반드시 이 데이터를 1순위 근거로 사용합니다.',
      '- DB에 있는 제품명, 브랜드명, 성분, 함량은 DB 값 그대로만 인용합니다.',
      '- DB에 없는 제품의 이름이나 성분을 임의로 생성하지 않습니다.',
      '- DB 제품에 대해 답변할 때는 반드시 "[DB]" 태그를 붙여 출처를 밝힙니다.',
      '',
      '## Tier 1.5 — 인터넷 검색 결과 (보조 근거)',
      'Google Search를 통해 검색된 정보가 있으면 활용할 수 있습니다.',
      '- 반드시 "[검색]" 태그를 붙여 출처를 표시합니다.',
      '- 검색 결과만으로 특정 제품을 추천하지 않습니다. DB에 없는 제품명을 검색 결과에서 가져와 추천하는 것은 금지합니다.',
      '- 검색 결과는 일반 영양 정보 보충, 복용법 확인, 최신 연구 참고 용도로만 사용합니다.',
      '- 검색 결과가 DB 데이터와 충돌하면 DB 데이터를 우선합니다.',
      '- 출처 URL이 있다면 답변 하단에 참고 링크로 표시합니다.',
      '',
      '## Tier 2 — 일반 영양학 상식 (보조 허용)',
      'DB에 직접 관련 제품이 없거나, 사용자의 질문이 일반적인 영양 상식에 해당하는 경우:',
      '- 널리 검증된 영양학적 사실(예: 비타민D는 지용성이라 식후 복용이 좋다, 철분과 칼슘은 함께 먹으면 흡수를 방해한다 등)은 활용할 수 있습니다.',
      '- 단, 이때 "일반적으로 알려진 바로는~", "영양학적으로~" 등 일반 지식임을 명시합니다.',
      '- Tier 2 지식으로 답변하더라도 특정 브랜드 제품명을 임의로 만들어 추천하지 않습니다.',
      '',
      '## Tier 3 — 답변 불가 영역 (거절)',
      '다음에 해당하면 반드시 정중하게 거절합니다:',
      '- 특정 질병의 진단, 처방, 치료 방법에 관한 질문',
      '- 의약품(처방약, 일반의약품)과의 상호작용 판단',
      '- 확실하지 않은 최신 연구 결과나 논쟁 중인 학설',
      '- 영양제와 무관한 질문 (날씨, 뉴스, 코딩 등)',
      '- 거절 시 "이 부분은 전문 의료진과 상담하시는 것을 권장드려요 😊" 등으로 안내합니다.',
      '',

      // ── 중복·과다 복용 검사 규칙 ──
      '# 중복·과다 복용 검사 규칙',
      '사용자가 이미 [현재 등록된 영양제]에서 복용 중인 성분이 새 추천 제품에도 포함되어 있다면:',
      '- 중복 성분명과 합산 예상 섭취량을 표시합니다.',
      '- 일일 상한 섭취량(UL)을 초과할 가능성이 있으면 "⚠️" 이모지와 함께 경고합니다.',
      '- 예시: "이미 복용 중인 \'솔가 비타민D\'에 비타민D3 2000IU가 포함되어 있어요. 합산 시 UL(4000IU)에 가까워지므로 주의가 필요해요."',
      '- 중복이 있더라도 UL 이내라면 "현재 복용량과 합산해도 안전 범위 내예요"라고 안심시켜 줍니다.',
      '',

      // ── 성분 상호작용 참고표 ──
      '# 성분 상호작용 참고표',
      '다음은 널리 알려진 주요 성분 간 상호작용입니다. 답변 시 참고하세요:',
      '- 철분 ↔ 칼슘: 동시 복용 시 흡수 방해 → 2시간 간격 권장',
      '- 비타민C ↔ 철분: 비타민C가 철분 흡수 촉진 → 동시 복용 권장',
      '- 마그네슘 ↔ 칼슘: 고용량 동시 복용 시 흡수 경쟁 → 시간 분리 권장',
      '- 아연 ↔ 구리: 고용량 아연이 구리 흡수 억제 → 장기 복용 시 주의',
      '- 비타민D ↔ 칼슘: 비타민D가 칼슘 흡수 촉진 → 동시 복용 권장',
      '- 오메가3 ↔ 비타민E: 함께 복용 시 산화 방지 효과 → 동시 복용 가능',
      '- 비타민K ↔ 항응고제(와파린 등): 비타민K가 약물 효과 감소 → Tier 3 거절 대상',
      '- 유산균 ↔ 항생제: 항생제가 유산균 효과 감소 → 2시간 간격 권장',
      '',

      // ── 안전 규칙 ──
      '# 안전 규칙',
      '1. 추천 제외 제품: [추천 제외 제품]에 나열된 제품은 절대 추천하지 않습니다. 사유도 간결하게만 언급합니다.',
      '2. 사용자 건강 정보 활용: 아래 건강 정보를 참고하여 주의사항을 안내하되, 새로운 의학적 진단을 내리지 않습니다.',
      '3. 면책: 건강 관련 답변 끝에는 "정확한 판단은 의사·약사와 상담해 주세요."를 자연스럽게 덧붙입니다.',
      '4. 과다복용 위험: 일일 상한 섭취량(UL) 관련 질문에는 보수적으로 답변합니다.',
      '5. 임산부·수유부: 임신/수유 상태인 사용자에게는 비타민A(레티놀), 고용량 카페인 등 주의 성분을 강조합니다.',
      '',

      // ── 출처 표시 규칙 ──
      '# 출처 표시 규칙',
      '- DB 데이터를 근거로 한 정보: [DB] 태그 사용',
      '- 인터넷 검색 결과 기반 정보: [검색] 태그 사용',
      '- 일반 영양학 상식: 별도 태그 없이 "일반적으로~", "영양학적으로~"',
      '- 출처 태그는 해당 문장 앞에 붙입니다.',
      '- 검색 출처가 있다면 답변 마지막에 "📎 참고:" 섹션으로 URL을 정리합니다.',
      '',

      // ── 응답 형식 ──
      '# 응답 형식',
      '- 답변 길이: 200~500자 사이를 목표로 합니다. 복잡한 질문은 초과 가능.',
      '- 제품 추천 시 구조: ① 제품 정보 → ② 핵심 성분/효과 → ③ 복용법 → ④ 주의사항',
      '- 일반 상식 답변 시 구조: ① 핵심 답변 → ② 부연 설명 → ③ 실천 팁',
      '- 이모지는 답변당 1~2개만 자연스럽게 사용합니다.',
      '- 목록은 글머리 기호(•)로 통일하고, 중요 키워드는 **굵게** 표시합니다.',
      '',

      // ── 사용자 건강 프로필 ──
      '# 사용자 건강 정보',
      `- 이름: ${profile?.name || '미입력'}`,
      `- 성별: ${profile?.gender || '미입력'}`,
      `- 나이: ${profile?.age ?? '미입력'}`,
      `- 건강 목표: ${(profile?.goals ?? []).join(', ') || '미입력'}`,
      `- 보유 질환: ${(profile?.healthConditions ?? []).join(', ') || '없음'}`,
      `- 알레르기: ${(profile?.allergies ?? []).join(', ') || '없음'}`,
      `- 흡연: ${profile?.smokingStatus || '미입력'}`,
      `- 음주: ${profile?.drinkingStatus || '미입력'}`,
      `- 임신/수유: ${profile?.pregnancyStatus || '미입력'}`,
      '',

      // ── 현재 복용 중인 영양제 ──
      '# 현재 등록된 영양제',
      currentSupplements.length
        ? currentSupplements
            .map((item) => {
              const nutrients =
                item.nutrients?.map((nutrient) => {
                  const valueStr = nutrient.value != null
                    ? ` ${nutrient.value}${nutrient.unit ?? ''}`
                    : '';
                  return `${nutrient.name}${valueStr}`;
                }).join(', ') ||
                '성분 미입력';
              return `- ${item.name} (${item.brand || '브랜드 미입력'}): ${nutrients}`;
            })
            .join('\n')
        : '등록된 영양제 없음',
      '',

      // ── DB 제품 데이터 ──
      '# DB 제품 데이터',
      hasDbProducts
        ? products.map((product) => this.formatProduct(product)).join('\n')
        : '(검색된 DB 제품 없음 — Tier 1.5 또는 Tier 2로 답변하세요)',
      '',

      // ── 추천 제외 제품 ──
      '# 추천 제외 제품',
      blockedProducts.length
        ? blockedProducts.map((product) => this.formatProduct(product)).join('\n')
        : '없음',
      '',

      // ── Few-shot 예시 ──
      '# 답변 예시',
      '',
      '## 예시 1: DB 제품이 있는 경우 (Tier 1)',
      '사용자: 비타민D 제품 있어?',
      '답변: 저희 DB에서 비타민D 관련 제품을 찾았어요!',
      '• **[제품명]** — [브랜드], 비타민D3 [함량] 함유 [DB]',
      '비타민D는 지용성이라 식사 후에 드시면 흡수가 더 잘 돼요. 😊',
      '',
      '## 예시 2: DB 제품이 없는 일반 질문 (Tier 2)',
      '사용자: 철분이랑 칼슘 같이 먹어도 돼?',
      '답변: 일반적으로 철분과 칼슘은 동시 복용 시 서로 흡수를 방해할 수 있어요.',
      '• 최소 2시간 간격을 두고 드시는 걸 추천드려요.',
      '• 철분은 공복에, 칼슘은 식후에 드시면 각각 흡수율이 좋아요.',
      '',
      '## 예시 3: 답변 거절 (Tier 3)',
      '사용자: 혈압약이랑 오메가3 같이 먹어도 되나요?',
      '답변: 처방 의약품과 영양제의 상호작용은 개인 상태에 따라 달라질 수 있어서,',
      '이 부분은 담당 의사 또는 약사와 꼭 상담해 보시는 걸 권장드려요. 😊',
      '',
      '## 예시 4: DB 제품 + 인터넷 검색 보충 (Tier 1 + 1.5)',
      '사용자: 루테인 제품 추천해줘',
      '답변: 저희 DB에서 루테인 관련 제품을 찾았어요!',
      '• **[제품명]** — [브랜드], 루테인 [함량] 함유 [DB]',
      '[검색] 루테인은 하루 10~20mg 섭취가 권장되며, 지용성이라 식후에 드시면 흡수가 좋아요.',
      '현재 복용 중인 영양제에 루테인 성분이 없으시니 안심하고 드셔도 괜찮아요. 😊',
      '',
      '## 예시 5: 복용 중 영양제와 중복 경고',
      '사용자: 비타민D 더 먹어도 될까?',
      '답변: 현재 복용 중인 \'[기존 제품명]\'에 이미 비타민D3 2000IU가 포함되어 있어요.',
      '⚠️ 추가로 드시면 합산 섭취량이 일일 상한(UL: 4000IU)에 가까워질 수 있으니 주의해 주세요.',
      '추가 보충이 필요하시다면 1000IU 이하의 저용량 제품을 추천드려요.',
    ].join('\n');
  }

  // ────────────────────────────────────────────────────────
  // 사용자 프롬프트 — 질문 원문 + Tier 분류 힌트
  // ────────────────────────────────────────────────────────
  private buildUserPrompt(message: string, dbProductCount: number) {
    const tierHint = dbProductCount > 0
      ? `참고: DB에서 ${dbProductCount}개 관련 제품을 찾았습니다. Tier 1(DB 근거) 우선으로 답변하세요. 필요하다면 인터넷 검색(Tier 1.5)으로 복용법 등을 보충하세요.`
      : '참고: DB에서 관련 제품을 찾지 못했습니다. 인터넷 검색(Tier 1.5) 또는 일반 영양 상식(Tier 2)으로 답변하되, 불확실하면 Tier 3(거절)하세요.';

    return [
      `사용자 질문: ${message}`,
      '',
      tierHint,
    ].join('\n');
  }

  // ────────────────────────────────────────────────────────
  // 제품 포맷팅
  // ────────────────────────────────────────────────────────
  private formatProduct(product: RetrievedProduct) {
    const ingredients = product.ingredients
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

  // ────────────────────────────────────────────────────────
  // 사용자 프로필 기반 제품 차단 판정
  // ────────────────────────────────────────────────────────
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
      ...product.ingredients.map(
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

  // ────────────────────────────────────────────────────────
  // Fallback 답변 — LLM 호출 실패 시 DB 결과만으로 최소 응답
  // ────────────────────────────────────────────────────────
  private buildFallbackAnswer(
    message: string,
    products: RetrievedProduct[],
    blockedProducts: RetrievedProduct[],
  ) {
    if (products.length === 0) {
      return this.buildNoRagFallback(blockedProducts);
    }

    const first = products[0];
    const blockedText = blockedProducts.length
      ? `\n\n참고로 ${blockedProducts
          .map((item) => item.product_name)
          .join(', ')} 제품은 회원님의 건강 정보를 고려해 추천에서 제외했어요.`
      : '';

    return [
      `"${message}"와 관련하여 DB에서 ${first.product_name} 제품을 찾았어요.`,
      '현재 AI 상담 연결이 원활하지 않아 상세한 분석은 잠시 후 다시 시도해 주세요.',
      blockedText,
    ].join('\n');
  }

  private buildNoRagFallback(blockedProducts: RetrievedProduct[]) {
    const blockedText = blockedProducts.length
      ? `\n\n건강 정보 기준 제외 제품: ${blockedProducts
          .map((item) => item.product_name)
          .join(', ')}`
      : '';

    return [
      '현재 AI 상담 연결이 원활하지 않아요.',
      '잠시 후 다시 질문해 주시면 정확한 답변을 드릴게요! 😊',
      blockedText,
    ].join('\n');
  }
}
