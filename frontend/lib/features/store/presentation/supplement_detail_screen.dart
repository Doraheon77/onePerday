import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:simcap/core/constant/app_constants.dart';
import 'package:simcap/features/cabinet/domain/dataModels/supplement_model.dart';
import 'package:simcap/routes/app_router.dart';
import 'package:simcap/features/store/presentation/review_screen.dart';
import 'package:simcap/providers/supplement_provider.dart';
import 'package:url_launcher/url_launcher.dart';
// import 'package:portone_flutter/v1.dart'; // purchase_screen으로 이동
import 'dart:convert';
import 'package:http/http.dart' as http;

// 스토어 상품 데이터 모델
// TODO: 백엔드 연동 후 API 응답 모델로 교체
class StoreProduct {
  final String id;
  final String name;
  final String brand;
  final int price;
  final String description;
  final List<NutrientInfo> nutrients;
  final List<String> contraindications;
  final List<StoreProduct> similarProducts;
  final String? purchaseUrl;
  final int dailyDose; // 1회 복용량
  final int dailyFrequency; // 하루 복용 횟수

  const StoreProduct({
    required this.id,
    required this.name,
    required this.brand,
    required this.price,
    required this.description,
    required this.nutrients,
    this.contraindications = const [],
    this.similarProducts = const [],
    this.purchaseUrl,
    this.dailyDose = 1,
    this.dailyFrequency = 1,
  });

  /// StoreProduct → Supplement 변환
  /// 스토어 상품을 캐비닛에 추가할 때 사용
  Supplement toSupplement() {
    return Supplement(
      name: name,
      brand: brand,
      remaining: 0,
      total: 0,
      dailyDose: dailyDose,
      dailyFrequency: dailyFrequency,
      nutrients: nutrients
          .map(
            (n) => Nutrient(
              name: n.name,
              value: n.amount,
              unit: n.unit,
              percent: n.dailyPercent,
            ),
          )
          .toList(),
      analysisGuide: description.isNotEmpty
          ? description
          : '이 영양제는 정해진 시간에 복용하는 것이 좋습니다.',
      aiSummary: '리뷰를 분석 중입니다.',
    );
  }
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
  bool _isPurchaseLoading = false;
  bool _isPaymentLoading = false;

  /// 이미 캐비닛에 등록된 영양제인지 여부 (이름 기준 비교)
  bool _isAlreadyInCabinet(BuildContext context) {
    final supplements = SupplementProvider.of(context).supplements;
    return supplements.any((s) => s.name == widget.product.name);
  }

  bool _hasOverdoseRiskWithCurrentProduct(BuildContext context) {
    final cabinets = SupplementProvider.of(context).supplements;

    final Map<String, double> totals = {};

    for (final s in cabinets) {
      for (final n in s.nutrients) {
        final key = n.name.trim().toLowerCase();
        totals[key] = (totals[key] ?? 0) + n.percent;
      }
    }

    for (final n in widget.product.nutrients) {
      final key = n.name.trim().toLowerCase();
      final total = (totals[key] ?? 0) + n.dailyPercent;

      if (total > 1.0) {
        return true;
      }
    }

    return false;
  }

  bool _blockIfOverdoseRisk(BuildContext context) {
    if (_hasOverdoseRiskWithCurrentProduct(context)) {
      return true;
    }

    return false;
  }

  /// 이미 장바구니에 있는지 여부
  bool _isInCart(BuildContext context) =>
      SupplementProvider.of(context).isInCart(widget.product.id);

  /// 장바구니에 추가 / 이미 있으면 수량 +1
  void _addToCart(BuildContext context) {
    final notifier = SupplementProvider.of(context);
    final p = widget.product;

    notifier.addToCart(
      CartItem(productId: p.id, name: p.name, brand: p.brand, price: p.price),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          notifier.isInCart(p.id)
              ? '${p.name} 수량을 추가했습니다.'
              : '${p.name}을(를) 장바구니에 담았습니다!',
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primary,
        action: SnackBarAction(
          label: '장바구니 보기',
          textColor: Colors.white,
          onPressed: () => context.push('/store/basket'),
        ),
      ),
    );
  }

  /// 캐비닛에 추가
  void _addToCabinet(BuildContext context) {
    // 이미 있으면 추가 안 함
    if (_isAlreadyInCabinet(context)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.product.name}은(는) 이미 캐비닛에 있습니다.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // 영양제 정보 페이지 거쳐서 등록 (복용 알림 설정 위함)
    context.push('/cabinet/info', extra: widget.product.toSupplement());
  }

  void _addToCabinetDirect(BuildContext context) {
    final notifier = SupplementProvider.of(context);
    notifier.addSupplement(widget.product.toSupplement());

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.product.name}을(를) 캐비닛에 추가했습니다!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primary,
        action: SnackBarAction(
          label: '캐비닛 보기',
          textColor: Colors.white,
          onPressed: () => context.go('/cabinet'),
        ),
      ),
    );
  }

  // ── 결제 수단 선택 바텀시트 ──────────────────────────────────────────────

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.danger,
      ),
    );
  }

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
                _buildReviewSummary(p),
                const SizedBox(height: 12),
                _buildSimilarProducts(p.similarProducts),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(context, p),
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
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: GestureDetector(
            onTap: () => context.push('/store/basket'),
            child: SizedBox(
              width: 48,
              height: 48,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  const Icon(
                    Icons.shopping_basket_outlined,
                    color: Colors.black,
                  ),
                  if (SupplementProvider.of(context).cartItems.isNotEmpty)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: const BoxDecoration(
                          color: AppColors.danger,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${SupplementProvider.of(context).cartItems.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
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
    // 0~100%: 초록, 100~150%: 주황(권장량 초과), 150%+: 빨강(상한 섭취량)
    final Color barColor = n.dailyPercent > 1.5
        ? AppColors.danger
        : n.dailyPercent > 1.0
        ? AppColors.warning
        : AppColors.primary;
    final Color badgeBg = n.dailyPercent > 1.5
        ? AppColors.dangerBg
        : n.dailyPercent > 1.0
        ? const Color(0xFFFFF3E0)
        : AppColors.primaryLight;
    final clampedPercent = n.dailyPercent.clamp(0.0, 1.5);
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
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      percentLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: barColor,
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
  void _showConsultPopup() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.local_hospital_outlined, color: AppColors.primary),
            SizedBox(width: 8),
            Text(
              '전문의 상담 안내',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          '영양제 복용에 관한 정확한 판단은 전문의와 상담하는 것이 가장 안전합니다.\n\n'
          '특히 만성질환, 임신, 약물 복용 중인 경우 반드시 전문의와 상의 후 복용하세요.',
          style: TextStyle(fontSize: 14, height: 1.6),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      '닫기',
                      style: TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      '확인',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContraindications(List<String> items) {
    final cabinets = SupplementProvider.of(context).supplements;

    // 캐비닛 영양제 성분 목록
    final cabinetNutrients = cabinets
        .expand((s) => s.nutrients.map((n) => n.name.toLowerCase()))
        .toSet();

    // 이 제품의 성분 중 병용금지 항목과 겹치는 것
    final productNutrientNames = widget.product.nutrients
        .map((n) => n.name.toLowerCase())
        .toSet();

    // 병용금지 충돌 (캐비닛 성분 vs 이 제품 병용금지 목록)
    final conflictItems = items.where((item) {
      final lower = item.toLowerCase();
      return cabinetNutrients.any(
        (n) => lower.contains(n) || n.contains(lower),
      );
    }).toList();

    // 과다복용 위험 성분 (캐비닛에 동일 성분 있는 경우)
    final overdoseRisks = widget.product.nutrients.where((n) {
      final lower = n.name.toLowerCase();
      return cabinetNutrients.any(
        (cn) => lower.contains(cn) || cn.contains(lower),
      );
    }).toList();

    final hasOverdose = overdoseRisks.isNotEmpty;
    final hasInteraction = conflictItems.isNotEmpty;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '병용금지 · 과다복용',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              if (!hasOverdose && !hasInteraction)
                GestureDetector(
                  onTap: _showConsultPopup,
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.info_outline,
                      size: 20,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // ── 과다복용 섹션 ─────────────────────────────────────────────
          Row(
            children: [
              const Icon(
                Icons.monitor_heart_outlined,
                size: 16,
                color: Colors.orange,
              ),
              const SizedBox(width: 6),
              const Text(
                '과다복용 위험',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (overdoseRisks.isEmpty)
            _buildSafeItem('중복 성분 없음')
          else
            ...overdoseRisks
                .map(
                  (n) =>
                      _buildContraItem('${n.name} — 캐비닛 영양제와 중복, 합산 섭취량 확인 필요'),
                )
                .toList(),

          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // ── 병용금지 섹션 ─────────────────────────────────────────────
          Row(
            children: [
              const Icon(
                Icons.block_outlined,
                size: 16,
                color: AppColors.danger,
              ),
              const SizedBox(width: 6),
              const Text(
                '병용 금지 약물·성분',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 캐비닛 충돌 항목
          if (conflictItems.isNotEmpty) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.dangerBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.warning_rounded,
                        size: 16,
                        color: AppColors.danger,
                      ),
                      SizedBox(width: 6),
                      Text(
                        '캐비닛 충돌 감지',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.danger,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ...conflictItems
                      .map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              const Text(
                                '• ',
                                style: TextStyle(color: AppColors.danger),
                              ),
                              Expanded(
                                child: Text(
                                  item,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ],
              ),
            ),
          ],

          // 전체 병용금지 목록
          if (items.isEmpty)
            _buildSafeItem('등록된 병용 금지 정보가 없습니다')
          else ...[
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

  Widget _safeChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 14,
            color: AppColors.primary,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(fontSize: 12, color: AppColors.primary),
          ),
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
            child: Icon(Icons.error_outline, size: 15, color: AppColors.danger),
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

  // 문제 없는 경우 — 체크 아이콘
  Widget _buildSafeItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 3),
            child: Icon(
              Icons.check_circle_outline,
              size: 15,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 리뷰 요약 섹션 ────────────────────────────────────────────────────
  Widget _buildReviewSummary(StoreProduct product) {
    final reviews = getDummyReviews(product.id);
    final avg = reviews.isEmpty
        ? 0.0
        : reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;
    final preview = reviews.take(2).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 헤더
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
            child: Row(
              children: [
                const Text(
                  '리뷰',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                // 평균 별점
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      avg.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.warning,
                      ),
                    ),
                    Text(
                      ' (${reviews.length})',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
                const Spacer(),
                TextButton(
                  onPressed: () =>
                      context.push('/store/review', extra: product),
                  child: const Text(
                    '전체보기',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          // 리뷰 미리보기 2개
          if (reviews.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                '아직 리뷰가 없습니다',
                style: TextStyle(fontSize: 13, color: Colors.grey[400]),
              ),
            )
          else
            ...preview.map((r) => _buildReviewPreviewRow(r)),
        ],
      ),
    );
  }

  Widget _buildReviewPreviewRow(ProductReview review) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < review.rating
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    size: 13,
                    color: i < review.rating
                        ? AppColors.warning
                        : Colors.grey[300],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                review.userName,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${review.createdAt.month}/${review.createdAt.day}',
                style: TextStyle(fontSize: 11, color: Colors.grey[400]),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            review.content,
            style: const TextStyle(fontSize: 13, height: 1.4),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
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
                  onTap: () => context.push('/store/detail', extra: sp),
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

  Widget _buildBottomBar(BuildContext context, StoreProduct p) {
    final bool alreadyAdded = _isAlreadyInCabinet(context);

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
          // 장바구니
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: _isInCart(context)
                    ? AppColors.primaryLight
                    : Colors.white,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => _addToCart(context),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isInCart(context)
                        ? Icons.shopping_cart_rounded
                        : Icons.shopping_cart_outlined,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isInCart(context) ? '담김' : '장바구니',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 캐비닛 추가
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: alreadyAdded
                    ? AppColors.primaryLight
                    : Colors.white,
                side: BorderSide(
                  color: alreadyAdded
                      ? AppColors.primary
                      : Colors.grey.shade300,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => _addToCabinet(context),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    alreadyAdded
                        ? Icons.check_circle_rounded
                        : Icons.add_circle_outline_rounded,
                    size: 16,
                    color: alreadyAdded
                        ? AppColors.primary
                        : Colors.grey.shade500,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    alreadyAdded ? '추가됨' : '내 캐비닛',
                    style: TextStyle(
                      color: alreadyAdded
                          ? AppColors.primary
                          : Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          Expanded(
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
              onPressed: _isPaymentLoading
                  ? null
                  : () => context.push('/store/purchase', extra: p),
              child: _isPaymentLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      '바로 구매',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
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

  Widget _sectionTitle(String title, {IconData? icon}) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 8),
        ],
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
