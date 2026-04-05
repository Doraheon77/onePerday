import 'package:flutter/material.dart';
import 'package:simcap/core/constant/app_constants.dart';
import 'package:go_router/go_router.dart';

// 스토어 상품 데이터 모델
// TODO: 백엔드 연동 후 API 응답 모델로 교체
class StoreProduct {
  final String id;
  final String name;
  final String brand;
  final int price;
  final String description;
  final List<NutrientInfo> nutrients;
  final List<String> contraindications; // 병용 금지 약물/성분
  final List<StoreProduct> similarProducts;

  const StoreProduct({
    required this.id,
    required this.name,
    required this.brand,
    required this.price,
    required this.description,
    required this.nutrients,
    this.contraindications = const [],
    this.similarProducts = const [],
  });
}

class NutrientInfo {
  final String name;
  final double amount;
  final String unit;
  final double dailyPercent; // 일일 권장량 대비 %

  const NutrientInfo({
    required this.name,
    required this.amount,
    required this.unit,
    required this.dailyPercent,
  });
}

// 더미 데이터
// TODO: 실제 API로 교체
final _dummySimilar = <StoreProduct>[
  StoreProduct(
    id: 's1',
    name: '비타민D3 2000IU',
    brand: '네이처메이드',
    price: 18000,
    description: '',
    nutrients: [],
  ),
  StoreProduct(
    id: 's2',
    name: '비타민D+K2',
    brand: '솔가',
    price: 34000,
    description: '',
    nutrients: [],
  ),
  StoreProduct(
    id: 's3',
    name: '선샤인 비타민D',
    brand: '뉴트리코어',
    price: 15000,
    description: '',
    nutrients: [],
  ),
];

final dummyProduct = StoreProduct(
  id: 'p1',
  name: '고함량 비타민D 5000IU',
  brand: '심캡푸드',
  price: 28000,
  description:
      '햇빛을 충분히 쬐기 어려운 현대인을 위한 고함량 비타민D입니다. '
      '면역 기능 유지, 뼈 건강, 근육 기능에 도움을 줍니다. '
      '연질캡슐 형태로 흡수율을 높였습니다.',
  nutrients: [
    NutrientInfo(name: '비타민 D3', amount: 5000, unit: 'IU', dailyPercent: 1.25),
    NutrientInfo(name: '비타민 K2', amount: 45, unit: 'mcg', dailyPercent: 0.6),
    NutrientInfo(name: '비타민 E', amount: 10, unit: 'mg', dailyPercent: 0.67),
  ],
  contraindications: [
    '와파린 (항응고제) — 비타민K2와 상호작용',
    '칼슘 보충제 과다 복용 — 고칼슘혈증 위험',
    '티아자이드계 이뇨제 — 칼슘 수치 상승 가능',
  ],
  similarProducts: _dummySimilar,
);

class SupplementDetailScreen extends StatefulWidget {
  final StoreProduct product;

  const SupplementDetailScreen({super.key, required this.product});

  @override
  State<SupplementDetailScreen> createState() => _SupplementDetailScreenState();
}

class _SupplementDetailScreenState extends State<SupplementDetailScreen> {
  bool _contraExpanded = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(p),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBasicInfo(p),
                const SizedBox(height: 12),
                _buildNutrientChart(p.nutrients),
                const SizedBox(height: 12),
                _buildContraindications(p.contraindications),
                const SizedBox(height: 12),
                _buildSimilarProducts(p.similarProducts),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(p),
    );
  }

  // AppBar (이미지 영역 포함
  Widget _buildAppBar(StoreProduct p) {
    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      backgroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => context.pop(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.shopping_basket_outlined, color: Colors.black),
          onPressed: () => context.push('/store/basket'),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: AppColors.primaryFaint,
          child: const Center(
            child: Icon(
              Icons.medication_rounded,
              size: 100,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }

  // 기본 정보
  Widget _buildBasicInfo(StoreProduct p) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            p.brand,
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            p.name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '${_formatPrice(p.price)}원',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          Text(
            p.description,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  // 성분별 함량 도식화
  Widget _buildNutrientChart(List<NutrientInfo> nutrients) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('성분별 함량', icon: Icons.bar_chart_rounded),
          const SizedBox(height: 4),
          Text(
            '일일 권장량(DRI) 대비 함유량',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
          const SizedBox(height: 16),
          ...nutrients.map((n) => _buildNutrientRow(n)),
        ],
      ),
    );
  }

  Widget _buildNutrientRow(NutrientInfo n) {
    // 100% 초과 시 바를 빨간색으로
    final isOver = n.dailyPercent > 1.0;
    final clampedPercent = n.dailyPercent.clamp(0.0, 1.5);
    final barColor = isOver ? AppColors.danger : AppColors.primary;
    final percentLabel = '${(n.dailyPercent * 100).toStringAsFixed(0)}%';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                n.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  Text(
                    '${n.amount}${n.unit}',
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isOver
                          ? AppColors.dangerBg
                          : AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      percentLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isOver ? AppColors.danger : AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  // 배경 바
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  // 채워진 바
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOut,
                    height: 8,
                    width:
                        constraints.maxWidth *
                        (clampedPercent / 1.5).clamp(0.0, 1.0),
                    decoration: BoxDecoration(
                      color: barColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  // 100% 기준선
                  Positioned(
                    left: constraints.maxWidth * (1.0 / 1.5),
                    child: Container(
                      width: 1.5,
                      height: 8,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // 병용 금지 정보
  Widget _buildContraindications(List<String> items) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('병용 금지 약물·성분', icon: Icons.warning_amber_rounded),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Text(
              '등록된 병용 금지 정보가 없습니다.',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            )
          else ...[
            // 처음 1개는 항상 표시, 나머지는 접기/펼치기
            _buildContraItem(items.first),
            if (items.length > 1) ...[
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Column(
                  children: items.skip(1).map(_buildContraItem).toList(),
                ),
                crossFadeState: _contraExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 250),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => setState(() => _contraExpanded = !_contraExpanded),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _contraExpanded ? '접기' : '${items.length - 1}개 더 보기',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Icon(
                      _contraExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildContraItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 3),
            child: Icon(Icons.block, size: 15, color: AppColors.danger),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimilarProducts(List<StoreProduct> products) {
    if (products.isEmpty) return const SizedBox.shrink();

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('유사 제품 추천', icon: Icons.recommend_rounded),
          const SizedBox(height: 12),
          SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: products.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final sp = products[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SupplementDetailScreen(product: sp),
                      ),
                    );
                  },
                  child: Container(
                    width: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryFaint,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.medication_rounded,
                            color: AppColors.primary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            sp.name,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_formatPrice(sp.price)}원',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(StoreProduct p) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // 장바구니 담기
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                context.push('/store/basket');
              },
              child: const Text(
                '장바구니',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // 바로 구매
          Expanded(
            flex: 2,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              onPressed: () {
                // TODO: 네이버 스토어 등 외부 구매 페이지 연동
              },
              child: const Text(
                '바로 구매',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionTitle(String title, {required IconData icon}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }
}
