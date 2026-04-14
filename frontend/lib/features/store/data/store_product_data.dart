import 'package:simcap/features/store/presentation/supplement_detail_screen.dart';

// ── 스토어 더미 상품 데이터 ────────────────────────────────────────────────────
// TODO: 백엔드 연동 후 API 응답으로 교체
// 사용처:
//   - store_screen.dart: 추천 카드(recommendProducts), 인기 랭킹(rankingProducts)
//   - search_screen.dart: 검색 결과 필터링(allProducts)

// ── 전체 상품 목록 (10개) ─────────────────────────────────────────────────────
final List<StoreProduct> allProducts = [
  StoreProduct(
    id: 'p01',
    name: '고함량 비타민D 5000IU',
    brand: '심캡푸드',
    price: 28000,
    description:
        '햇빛을 충분히 쬐기 어려운 현대인을 위한 고함량 비타민D입니다. '
        '면역 기능 유지, 뼈 건강, 근육 기능에 도움을 줍니다.',
    purchaseUrl: 'https://smartstore.naver.com',
    nutrients: [
      NutrientInfo(
        name: '비타민 D3',
        amount: 5000,
        unit: 'IU',
        dailyPercent: 1.25,
      ),
      NutrientInfo(name: '비타민 K2', amount: 45, unit: 'mcg', dailyPercent: 0.6),
    ],
    contraindications: ['와파린 (항응고제) — 비타민K2와 상호작용', '칼슘 보충제 과다 복용 — 고칼슘혈증 위험'],
  ),
  StoreProduct(
    id: 'p02',
    name: '프리미엄 오메가3 1200mg',
    brand: '내추럴라이프',
    price: 32000,
    description: 'EPA·DHA 고순도 오메가3. 혈중 중성지방 감소와 혈행 개선에 도움을 줍니다.',
    purchaseUrl: 'https://smartstore.naver.com',
    nutrients: [
      NutrientInfo(
        name: 'EPA+DHA',
        amount: 1200,
        unit: 'mg',
        dailyPercent: 0.95,
      ),
      NutrientInfo(name: '비타민 E', amount: 10, unit: 'mg', dailyPercent: 0.67),
    ],
    contraindications: ['항응고제 복용자 주의 — 출혈 위험 증가 가능'],
  ),
  StoreProduct(
    id: 'p03',
    name: '마그네슘 글리시네이트 400mg',
    brand: '솔가',
    price: 24000,
    description: '흡수율 높은 글리시네이트 형태의 마그네슘. 근육 이완과 수면 개선에 도움을 줍니다.',
    purchaseUrl: 'https://smartstore.naver.com',
    nutrients: [
      NutrientInfo(name: '마그네슘', amount: 400, unit: 'mg', dailyPercent: 1.05),
    ],
    contraindications: ['신장 질환자 복용 전 의사 상담 권장'],
  ),
  StoreProduct(
    id: 'p04',
    name: '멀티비타민 포맨 포뮬라',
    brand: '센트룸',
    price: 19000,
    description: '남성에게 필요한 아연·비타민B군·셀레늄을 집중 보강한 멀티비타민입니다.',
    purchaseUrl: 'https://smartstore.naver.com',
    nutrients: [
      NutrientInfo(name: '비타민 C', amount: 100, unit: 'mg', dailyPercent: 1.0),
      NutrientInfo(
        name: '비타민 B12',
        amount: 2.4,
        unit: 'mcg',
        dailyPercent: 1.0,
      ),
      NutrientInfo(name: '아연', amount: 8.5, unit: 'mg', dailyPercent: 0.77),
    ],
    contraindications: [],
  ),
  StoreProduct(
    id: 'p05',
    name: '루테인 지아잔틴 20mg',
    brand: '뉴트리코어',
    price: 22000,
    description: '눈 건강을 위한 루테인·지아잔틴 복합 제품. 스마트기기 사용이 많은 현대인에게 적합합니다.',
    purchaseUrl: 'https://smartstore.naver.com',
    nutrients: [
      NutrientInfo(name: '루테인', amount: 20, unit: 'mg', dailyPercent: 0.67),
      NutrientInfo(name: '지아잔틴', amount: 4, unit: 'mg', dailyPercent: 0.5),
    ],
    contraindications: [],
  ),
  StoreProduct(
    id: 'p06',
    name: '프로바이오틱스 100억 유산균',
    brand: '종근당건강',
    price: 35000,
    description: '100억 CFU 복합 유산균으로 장 건강과 면역력을 동시에 케어합니다.',
    purchaseUrl: 'https://smartstore.naver.com',
    nutrients: [
      NutrientInfo(name: '유산균', amount: 100, unit: 'CFU(억)', dailyPercent: 1.0),
    ],
    contraindications: ['면역 억제제 복용자는 의사 상담 후 복용 권장'],
  ),
  StoreProduct(
    id: 'p07',
    name: '코큐텐 100mg 항산화',
    brand: '네이처메이드',
    price: 41000,
    description: '심장 건강과 에너지 대사에 관여하는 코엔자임Q10. 항산화 작용으로 세포 보호에 도움을 줍니다.',
    purchaseUrl: 'https://smartstore.naver.com',
    nutrients: [
      NutrientInfo(name: '코엔자임Q10', amount: 100, unit: 'mg', dailyPercent: 0.8),
    ],
    contraindications: ['혈압강하제·혈당강하제 병용 시 의사 상담 권장'],
  ),
  StoreProduct(
    id: 'p08',
    name: '밀크씨슬 실리마린 70%',
    brand: '나우푸드',
    price: 18000,
    description: '간 건강을 위한 밀크씨슬 추출물. 실리마린 70% 고함량으로 간세포 보호에 도움을 줍니다.',
    purchaseUrl: 'https://smartstore.naver.com',
    nutrients: [
      NutrientInfo(name: '실리마린', amount: 140, unit: 'mg', dailyPercent: 0.7),
    ],
    contraindications: ['호르몬 감수성 질환자 주의'],
  ),
  StoreProduct(
    id: 'p09',
    name: '칼슘 마그네슘 비타민D 복합',
    brand: '심캡푸드',
    price: 15000,
    description: '뼈 건강의 핵심 3가지 성분을 한 번에. 칼슘 흡수를 높이는 비타민D와 함께 설계했습니다.',
    purchaseUrl: 'https://smartstore.naver.com',
    nutrients: [
      NutrientInfo(name: '칼슘', amount: 500, unit: 'mg', dailyPercent: 0.5),
      NutrientInfo(name: '마그네슘', amount: 250, unit: 'mg', dailyPercent: 0.65),
      NutrientInfo(name: '비타민 D', amount: 1000, unit: 'IU', dailyPercent: 0.5),
    ],
    contraindications: ['신장결석 이력자 복용 전 의사 상담 권장'],
  ),
  StoreProduct(
    id: 'p10',
    name: '비오틴 5000mcg 헤어케어',
    brand: '스완슨',
    price: 12000,
    description: '모발·손톱 건강에 도움을 주는 고함량 비오틴. 탈모 고민이 있는 분께 추천합니다.',
    purchaseUrl: 'https://smartstore.naver.com',
    nutrients: [
      NutrientInfo(name: '비오틴', amount: 5000, unit: 'mcg', dailyPercent: 1.67),
    ],
    contraindications: [],
  ),
];

// ── 섹션별 편의 접근자 ─────────────────────────────────────────────────────────

/// 홈/스토어 추천 카드 — 앞 5개
List<StoreProduct> get recommendProducts => allProducts.take(5).toList();

/// 인기 랭킹 — 뒤 5개 (다른 상품 표시)
List<StoreProduct> get rankingProducts => allProducts.skip(5).toList();

/// 카테고리별 필터 (검색 화면용)
List<StoreProduct> filterByKeyword(String keyword) {
  if (keyword.trim().isEmpty) return allProducts;
  final q = keyword.toLowerCase();
  return allProducts
      .where(
        (p) =>
            p.name.toLowerCase().contains(q) ||
            p.brand.toLowerCase().contains(q) ||
            p.nutrients.any((n) => n.name.toLowerCase().contains(q)),
      )
      .toList();
}
