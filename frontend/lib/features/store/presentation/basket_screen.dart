import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simcap/core/constant/app_constants.dart';
import 'package:simcap/providers/supplement_provider.dart';
import 'package:simcap/features/cabinet/domain/dataModels/supplement_model.dart';
import 'package:simcap/services/intake_api_service.dart';

// 검사 결과 데이터 모델

enum _CheckStatus { safe, warning, danger }

class _ContraindicationResult {
  final String item1;
  final String item2;
  final String reason;
  final _CheckStatus status;
  const _ContraindicationResult({
    required this.item1,
    required this.item2,
    required this.reason,
    required this.status,
  });
}

class _OverdoseResult {
  final String nutrient;
  final double currentAmount;
  final double upperLimit;
  final String unit;

  _CheckStatus get status {
    if (upperLimit <= 0) return _CheckStatus.safe;

    final ratio = currentAmount / upperLimit;
    if (ratio >= 1.0) return _CheckStatus.danger;
    if (ratio >= 0.8) return _CheckStatus.warning;
    return _CheckStatus.safe;
  }

  const _OverdoseResult({
    required this.nutrient,
    required this.currentAmount,
    required this.upperLimit,
    required this.unit,
  });
}

class BasketScreen extends StatefulWidget {
  const BasketScreen({super.key});

  @override
  State<BasketScreen> createState() => _BasketScreenState();
}

class _BasketScreenState extends State<BasketScreen> {
  // 장바구니 데이터는 SupplementProvider에서 읽음
  // _cartItems 하드코딩 제거 → notifier.cartItems 사용

  // 검사 패널 표시 여부
  bool _showContraPanel = false;
  bool _showOverdosePanel = false;

  // 검사 로딩 상태
  bool _isContraLoading = false;
  bool _isOverdoseLoading = false;

  // 주문 처리 중 중복 탭 방지
  bool _isOrdering = false;

  // 검사 결과 (null = 아직 검사 안 함)
  List<_ContraindicationResult>? _contraResults;
  List<_OverdoseResult>? _overdoseResults;

  // 주문하기
  Future<void> _placeOrder(BuildContext context) async {
    if (_isOrdering) return;

    final notifier = SupplementProvider.of(context);
    final checkedItems = notifier.cartItems.where((i) => i.checked).toList();
    if (checkedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('주문할 상품을 선택해주세요.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isOrdering = true);

    // 장바구니 아이템 → PurchaseItem 변환
    final purchaseItems = checkedItems.map((i) => i.toPurchaseItem()).toList();

    // Provider에 구매 기록 저장
    final record = notifier.addPurchase(purchaseItems);
    notifier.clearCheckedCartItems(); // 주문된 항목 장바구니에서 제거

    setState(() => _isOrdering = false);

    if (mounted) _showOrderCompleteDialog(context, record);
  }

  void _showOrderCompleteDialog(BuildContext context, PurchaseRecord record) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '주문이 완료되었습니다!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              record.id,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[400],
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 16),
            // 주문 요약 카드
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.scaffoldBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...record.items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${item.name} × ${item.count}',
                              style: const TextStyle(fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${_formatPrice(item.totalPrice)}원',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '총 결제',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${_formatPrice(record.totalPrice)}원',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/profile');
            },
            child: const Text('구매 기록 보기', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            onPressed: () {
              Navigator.pop(context);
              context.pop();
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  // 더미 검사 로직 (백엔드 연동 전)
  /// 성분 및 상호작용 검사
  /// - 장바구니 상품 이름 기반 중복 성분 확인
  /// - 사용자 질환/알레르기와 교차 확인 (SharedPreferences)
  Future<void> _runContraCheck() async {
    setState(() {
      _isContraLoading = true;
      _showContraPanel = true;
      _showOverdosePanel = false;
    });

    final notifier = SupplementProvider.of(context);
    // CartItem: productId, name, brand, price, count, checked
    final checkedItems = notifier.cartItems.where((c) => c.checked).toList();

    // SharedPreferences에서 사용자 건강 정보 로드
    final prefs = await SharedPreferences.getInstance();
    final userHealth = prefs.getStringList('selectedHealth') ?? [];
    final userAllergies = prefs.getStringList('selectedAllergies') ?? [];

    await Future.delayed(const Duration(milliseconds: 600));

    final results = <_ContraindicationResult>[];

    // 1. 상품명 기반 중복 성분 검사
    // CartItem에는 nutrients 필드가 없으므로 상품명으로 성분 추정
    final dangerousPairs = <(List<String>, String, String)>[
      (['비타민A', '비타민 A', '레티놀'], '비타민 A', '지용성 비타민 — 합산 시 독성 위험'),
      (['비타민D', '비타민 D', 'D3'], '비타민 D', '지용성 비타민 — 합산 시 고칼슘혈증 위험'),
      (['비타민E', '비타민 E', '토코페롤'], '비타민 E', '혈액 응고 억제 중복 — 출혈 위험 증가'),
      (['칼슘', 'Ca', '탄산칼슘', 'calcium'], '칼슘', '고칼슘혈증 위험'),
      (['아연', 'Zinc', 'zinc', '징크'], '아연', '면역 독성 위험 — 구리 흡수 방해'),
      (['철분', '철', 'Iron', 'iron'], '철분', '철 과부하 — 산화 스트레스 증가'),
      (['오메가3', '오메가-3', 'EPA', 'DHA', '어유'], '오메가3', '혈액 희석 효과 중복 — 출혈 위험'),
    ];

    for (final pair in dangerousPairs) {
      final aliases = pair.$1;
      final nutrientName = pair.$2;
      final reason = pair.$3;

      // 상품명에 해당 성분 키워드가 포함된 상품 찾기
      final matching = checkedItems
          .where(
            (c) => aliases.any(
              (a) => c.name.toLowerCase().contains(a.toLowerCase()),
            ),
          )
          .toList();

      if (matching.length >= 2) {
        results.add(
          _ContraindicationResult(
            item1: matching[0].name,
            item2: matching[1].name,
            reason: '[$nutrientName 중복] $reason',
            status: _CheckStatus.warning,
          ),
        );
      }
    }

    // 2. 사용자 질환과 상품명 교차 검사
    const healthWarnings = {
      '당뇨': [('크롬', '혈당 과도 저하 위험'), ('알파리포산', '저혈당 위험')],
      '고혈압': [('감초', '혈압 상승 가능'), ('나트륨', '혈압 상승 가능')],
      '갑상선 질환': [
        ('아이오딘', '갑상선 기능 악화 가능'),
        ('요오드', '갑상선 기능 악화 가능'),
        ('켈프', '요오드 과다'),
      ],
      '신장 질환': [('마그네슘', '신장 부담 증가'), ('칼륨', '고칼륨혈증 위험')],
      '빈혈': [('칼슘', '철분 흡수 방해 — 빈혈 악화 가능')],
      '골다공증': [('알루미늄', '칼슘 흡수 방해')],
      '통풍': [('비타민C', '고용량 시 요산 증가 가능'), ('퓨린', '요산 수치 상승')],
    };

    for (final disease in userHealth) {
      final warnings = healthWarnings[disease];
      if (warnings == null) continue;
      for (final w in warnings) {
        final nutrient = w.$1;
        final reason = w.$2;
        for (final item in checkedItems) {
          if (item.name.toLowerCase().contains(nutrient.toLowerCase())) {
            results.add(
              _ContraindicationResult(
                item1: item.name,
                item2: '[$disease 보유]',
                reason: reason,
                status: _CheckStatus.danger,
              ),
            );
          }
        }
      }
    }

    // 3. 알레르기 성분 교차 검사
    const allergyMap = {
      '갑각류': ['크릴', '크릴오일', 'krill', '새우', '게'],
      '대두': ['대두', '콩', 'soy', '이소플라본'],
      '우유': ['유청', 'whey', '카세인', '유단백'],
      '견과류': ['아몬드', '호두', '캐슈', '견과'],
      '밀': ['밀', '글루텐'],
      '달걀': ['달걀', '계란', 'egg'],
      '고등어': ['어유', 'fish oil', '오메가3', '오메가-3'],
    };

    for (final allergy in userAllergies) {
      final keywords = allergyMap[allergy];
      if (keywords == null) continue;
      for (final item in checkedItems) {
        final nameLower = item.name.toLowerCase();
        if (keywords.any((k) => nameLower.contains(k.toLowerCase()))) {
          results.add(
            _ContraindicationResult(
              item1: item.name,
              item2: '[$allergy 알레르기]',
              reason: '$allergy 알레르기 유발 성분 포함 가능 — 섭취 전 전문의 상담 권장',
              status: _CheckStatus.danger,
            ),
          );
        }
      }
    }

    setState(() {
      _isContraLoading = false;
      _contraResults = results;
    });
  }

  Future<void> _runOverdoseCheck() async {
  setState(() {
    _isOverdoseLoading = true;
    _showOverdosePanel = true;
    _showContraPanel = false;
  });

  try {
    final notifier = SupplementProvider.of(context);
    final checkedItems = notifier.cartItems.where((c) => c.checked).toList();

    final api = IntakeApiService();

    final results = await api.checkOverdoseByCartItems(
      cartItems: checkedItems,
      age: 24,
      gender: 'female',
    );

    setState(() {
      _isOverdoseLoading = false;
      _overdoseResults = results.map((r) {
        return _OverdoseResult(
          nutrient: r.nutrientName,
          currentAmount: r.currentTotal,
          upperLimit: r.upperLimit,
          unit: r.unit,
        );
      }).toList();
    });
  } catch (e) {
    setState(() {
      _isOverdoseLoading = false;
      _overdoseResults = [];
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('과다섭취 검사 중 오류 발생: $e'),
      ),
    );
  }
}

  // _checkedCount / _totalPrice는 build() 안에서 notifier를 통해 직접 접근

  @override
  Widget build(BuildContext context) {
    final notifier = SupplementProvider.of(context);
    final cartItems = notifier.cartItems;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: Text(
          '장바구니${cartItems.isEmpty ? '' : ' (${cartItems.length})'}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: cartItems.isNotEmpty
            ? [
                TextButton(
                  onPressed: () => notifier.setAllCartChecked(
                    !cartItems.every((i) => i.checked),
                  ),
                  child: Text(
                    cartItems.every((i) => i.checked) ? '전체 해제' : '전체 선택',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ]
            : null,
      ),
      body: Column(
        children: [
          Expanded(
            child: cartItems.isEmpty
                ? _buildEmptyCart()
                : ListView(
                    children: [
                      // 장바구니 상품 목록
                      ...cartItems.asMap().entries.map(
                        (e) => _buildCartItem(e.value, e.key, notifier),
                      ),

                      // 안전성 검사 섹션
                      if (cartItems.isNotEmpty) ...[
                        _buildCheckButtons(),
                        // 병용금지 결과 패널
                        AnimatedSize(
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeOut,
                          child: _showContraPanel
                              ? _buildContraPanel()
                              : const SizedBox.shrink(),
                        ),
                        // 과다섭취 결과 패널
                        AnimatedSize(
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeOut,
                          child: _showOverdosePanel
                              ? _buildOverdosePanel()
                              : const SizedBox.shrink(),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ],
                  ),
          ),
          _buildPaymentSummary(),
        ],
      ),
    );
  }

  // 장바구니 상품 카드
  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            '장바구니가 비어있습니다',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '스토어에서 영양제를 담아보세요',
            style: TextStyle(fontSize: 13, color: Colors.grey[400]),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => context.go('/store'),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            icon: const Icon(
              Icons.storefront_outlined,
              size: 16,
              color: AppColors.primary,
            ),
            label: const Text(
              '스토어 보러가기',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(CartItem item, int index, SupplementNotifier notifier) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          Checkbox(
            value: item.checked,
            activeColor: AppColors.primary,
            onChanged: (_) => notifier.toggleCartChecked(item.productId),
          ),
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.medication, color: Colors.grey),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.brand,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  item.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_formatPrice(item.price)}원',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          _buildCountController(item, notifier),
        ],
      ),
    );
  }

  Widget _buildCountController(CartItem item, SupplementNotifier notifier) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.remove_circle_outline, size: 20),
          onPressed: () => notifier.updateCartCount(item.productId, -1),
        ),
        Text('${item.count}'),
        IconButton(
          icon: const Icon(Icons.add_circle_outline, size: 20),
          onPressed: () => notifier.updateCartCount(item.productId, 1),
        ),
      ],
    );
  }

  Widget _buildCheckButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Text(
              '안전성 검사',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
          Row(
            children: [
              // 병용금지 검사
              Expanded(
                child: _CheckButton(
                  icon: Icons.biotech_outlined,
                  label: '성분 상호작용',
                  description: '질환·알레르기·중복 확인',
                  color: AppColors.danger,
                  bgColor: AppColors.dangerSoftBg,
                  isActive: _showContraPanel,
                  isLoading: _isContraLoading,
                  onTap: SupplementProvider.of(context).cartCheckedCount >= 1
                      ? () => _showContraPanel && !_isContraLoading
                            ? setState(() => _showContraPanel = false)
                            : _runContraCheck()
                      : null,
                  disabledHint: '1개 이상 선택 필요',
                ),
              ),
              const SizedBox(width: 10),
              // 과다섭취 검사
              Expanded(
                child: _CheckButton(
                  icon: Icons.warning_amber_rounded,
                  label: '과다섭취 검사',
                  description: '일일 상한량 초과 확인',
                  color: AppColors.warning,
                  bgColor: AppColors.warningBg,
                  isActive: _showOverdosePanel,
                  isLoading: _isOverdoseLoading,
                  onTap: SupplementProvider.of(context).cartCheckedCount >= 1
                      ? () => _showOverdosePanel && !_isOverdoseLoading
                            ? setState(() => _showOverdosePanel = false)
                            : _runOverdoseCheck()
                      : null,
                  disabledHint: '1개 이상 선택 필요',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 병용금지 결과 패널
  Widget _buildContraPanel() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 패널 헤더
          _buildPanelHeader(
            icon: Icons.biotech_outlined,
            title: '성분 상호작용 검사 결과',
            color: AppColors.danger,
            onClose: () => setState(() => _showContraPanel = false),
          ),
          const Divider(height: 1),
          // 로딩 중
          if (_isContraLoading)
            const _LoadingIndicator(message: '성분 간 충돌을 분석하고 있어요...')
          // 결과 없음
          else if (_contraResults == null || _contraResults!.isEmpty)
            const _EmptyResult(message: '성분 상호작용 문제가 발견되지 않았습니다.')
          // 결과 표시
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: _contraResults!.map(_buildContraRow).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContraRow(_ContraindicationResult r) {
    final color = r.status == _CheckStatus.danger
        ? AppColors.danger
        : AppColors.warning;
    final bgColor = r.status == _CheckStatus.danger
        ? AppColors.dangerSoftBg
        : AppColors.warningBg;
    final label = r.status == _CheckStatus.danger ? '주의 필요' : '경고';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 두 제품 + 화살표
          Row(
            children: [
              Expanded(child: _productBadge(r.item1, color)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.swap_horiz, size: 18, color: color),
              ),
              Expanded(child: _productBadge(r.item2, color)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 14, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  r.reason,
                  style: TextStyle(fontSize: 12, color: color, height: 1.4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _productBadge(String name, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        name,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  // 과다섭취 결과 패널
  Widget _buildOverdosePanel() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPanelHeader(
            icon: Icons.warning_amber_rounded,
            title: '과다섭취 검사 결과',
            color: AppColors.warning,
            onClose: () => setState(() => _showOverdosePanel = false),
          ),
          const Divider(height: 1),
          if (_isOverdoseLoading)
            const _LoadingIndicator(message: '일일 상한 섭취량을 분석하고 있어요...')
          else if (_overdoseResults == null || _overdoseResults!.isEmpty)
            const _EmptyResult(message: '과다섭취 위험 성분이 발견되지 않았습니다.')
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 범례
                  Row(
                    children: [
                      _legend(AppColors.primary, '안전'),
                      const SizedBox(width: 12),
                      _legend(AppColors.warning, '주의 (80% 이상)'),
                      const SizedBox(width: 12),
                      _legend(AppColors.danger, '초과'),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ..._overdoseResults!.map(_buildOverdoseBar),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOverdoseBar(_OverdoseResult r) {
    final ratio = (r.currentAmount / r.upperLimit).clamp(0.0, 1.5);
    final displayRatio = ratio.clamp(0.0, 1.0);

    Color barColor;
    Color textColor;
    String statusLabel;
    switch (r.status) {
      case _CheckStatus.danger:
        barColor = AppColors.danger;
        textColor = AppColors.danger;
        statusLabel = '초과';
        break;
      case _CheckStatus.warning:
        barColor = AppColors.warning;
        textColor = AppColors.warning;
        statusLabel = '주의';
        break;
      case _CheckStatus.safe:
        barColor = AppColors.primary;
        textColor = AppColors.primary;
        statusLabel = '안전';
    }

    final percentText = '${(ratio * 100).toStringAsFixed(0)}%';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                r.nutrient,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  Text(
                    '${r.currentAmount.toStringAsFixed(0)}${r.unit} / 상한 ${r.upperLimit.toStringAsFixed(0)}${r.unit}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: barColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$percentText $statusLabel',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          LayoutBuilder(
            builder: (context, constraints) => Stack(
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
                  width: constraints.maxWidth * displayRatio,
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
            ),
          ),
        ],
      ),
    );
  }

  // 결제 요약
  Widget _buildPaymentSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '총 결제 예정 금액',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_formatPrice(SupplementProvider.of(context).cartTotalPrice)}원',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _isOrdering ? null : () => _placeOrder(context),
                child: _isOrdering
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        '주문하기',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPanelHeader({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onClose,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: Colors.grey),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }

  Widget _legend(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.black54),
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

class _CheckButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final Color bgColor;
  final bool isActive;
  final bool isLoading;
  final VoidCallback? onTap;
  final String disabledHint;

  const _CheckButton({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.bgColor,
    required this.isActive,
    required this.isLoading,
    required this.onTap,
    required this.disabledHint,
  });

  @override
  Widget build(BuildContext context) {
    final bool disabled = onTap == null;
    return GestureDetector(
      onTap: disabled
          ? () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(disabledHint),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 1),
              ),
            )
          : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive ? color : Colors.grey.shade200,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                isLoading
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: color,
                        ),
                      )
                    : Icon(
                        icon,
                        size: 18,
                        color: disabled ? Colors.grey[300] : color,
                      ),
                const Spacer(),
                if (isActive && !isLoading)
                  Icon(Icons.keyboard_arrow_up, size: 16, color: color),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: disabled ? Colors.grey[400] : Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              description,
              style: TextStyle(
                fontSize: 11,
                color: disabled ? Colors.grey[300] : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingIndicator extends StatelessWidget {
  final String message;
  const _LoadingIndicator({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          const CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 2.5,
          ),
          const SizedBox(height: 14),
          Text(
            message,
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _EmptyResult extends StatelessWidget {
  final String message;
  const _EmptyResult({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: 10),
          Text(
            message,
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
