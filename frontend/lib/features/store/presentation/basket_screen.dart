import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:simcap/core/constant/app_constants.dart';
import 'package:simcap/providers/supplement_provider.dart';

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
  final List<Map<String, dynamic>> _cartItems = [
    {
      'name': '멀티비타민 포 맨',
      'brand': '심캡푸드',
      'price': 25000,
      'count': 1,
      'checked': true,
    },
    {
      'name': '고함량 오메가3',
      'brand': '내추럴라이프',
      'price': 32000,
      'count': 2,
      'checked': true,
    },
  ];

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

    final checkedItems = _cartItems.where((i) => i['checked'] == true).toList();
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
    final purchaseItems = checkedItems
        .map(
          (i) => PurchaseItem(
            name: i['name'] as String,
            brand: i['brand'] as String,
            price: i['price'] as int,
            count: i['count'] as int,
          ),
        )
        .toList();

    // Provider에 구매 기록 저장
    final record = SupplementProvider.of(context).addPurchase(purchaseItems);

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
  Future<void> _runContraCheck() async {
    setState(() {
      _isContraLoading = true;
      _showContraPanel = true;
      _showOverdosePanel = false;
    });
    await Future.delayed(const Duration(milliseconds: 900));
    setState(() {
      _isContraLoading = false;
      // TODO: 백엔드 API 호출로 교체
      _contraResults = [
        const _ContraindicationResult(
          item1: '멀티비타민 포 맨',
          item2: '고함량 오메가3',
          reason: '비타민E 중복 함유 — 합산 시 일일 상한 섭취량 초과 가능',
          status: _CheckStatus.warning,
        ),
        const _ContraindicationResult(
          item1: '멀티비타민 포 맨',
          item2: '고함량 오메가3',
          reason: '혈액 응고 억제 효과 중복 (오메가3 + 비타민K) — 항응고제 복용자 주의',
          status: _CheckStatus.danger,
        ),
      ];
    });
  }

  Future<void> _runOverdoseCheck() async {
    setState(() {
      _isOverdoseLoading = true;
      _showOverdosePanel = true;
      _showContraPanel = false;
    });
    await Future.delayed(const Duration(milliseconds: 900));
    setState(() {
      _isOverdoseLoading = false;
      // TODO: 백엔드 API 호출로 교체
      _overdoseResults = [
        const _OverdoseResult(
          nutrient: '비타민 A',
          currentAmount: 700,
          upperLimit: 3000,
          unit: 'μg',
        ),
        const _OverdoseResult(
          nutrient: '비타민 D',
          currentAmount: 4200,
          upperLimit: 4000,
          unit: 'IU',
        ),
        const _OverdoseResult(
          nutrient: '비타민 E',
          currentAmount: 330,
          upperLimit: 400,
          unit: 'mg',
        ),
        const _OverdoseResult(
          nutrient: 'EPA+DHA',
          currentAmount: 1200,
          upperLimit: 3000,
          unit: 'mg',
        ),
        const _OverdoseResult(
          nutrient: '아연',
          currentAmount: 8,
          upperLimit: 35,
          unit: 'mg',
        ),
      ];
    });
  }

  int get _checkedCount => _cartItems.where((i) => i['checked'] == true).length;

  int get _totalPrice => _cartItems
      .where((i) => i['checked'])
      .fold(0, (sum, i) => sum + (i['price'] as int) * (i['count'] as int));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          '장바구니',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                // 장바구니 상품 목록
                ..._cartItems.asMap().entries.map(
                  (e) => _buildCartItem(e.value, e.key),
                ),

                // 안전성 검사 섹션
                if (_cartItems.isNotEmpty) ...[
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
  Widget _buildCartItem(Map<String, dynamic> item, int index) {
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
            value: item['checked'],
            activeColor: const Color(0xFF4CAF50),
            onChanged: (val) => setState(() => item['checked'] = val),
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
                  item['brand'],
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  item['name'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_formatPrice(item['price'] as int)}원',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4CAF50),
                  ),
                ),
              ],
            ),
          ),
          _buildCountController(index),
        ],
      ),
    );
  }

  Widget _buildCountController(int index) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.remove_circle_outline, size: 20),
          onPressed: () => setState(() {
            if (_cartItems[index]['count'] > 1) _cartItems[index]['count']--;
          }),
        ),
        Text('${_cartItems[index]['count']}'),
        IconButton(
          icon: const Icon(Icons.add_circle_outline, size: 20),
          onPressed: () => setState(() => _cartItems[index]['count']++),
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
                  icon: Icons.block_outlined,
                  label: '병용금지 검사',
                  description: '성분 간 충돌 확인',
                  color: const Color(0xFFFF6B6B),
                  bgColor: const Color(0xFFFFF0F0),
                  isActive: _showContraPanel,
                  isLoading: _isContraLoading,
                  onTap: _checkedCount >= 2
                      ? () => _showContraPanel && !_isContraLoading
                            ? setState(() => _showContraPanel = false)
                            : _runContraCheck()
                      : null,
                  disabledHint: '2개 이상 선택 필요',
                ),
              ),
              const SizedBox(width: 10),
              // 과다섭취 검사
              Expanded(
                child: _CheckButton(
                  icon: Icons.warning_amber_rounded,
                  label: '과다섭취 검사',
                  description: '일일 상한량 초과 확인',
                  color: const Color(0xFFFFC107),
                  bgColor: const Color(0xFFFFFDE7),
                  isActive: _showOverdosePanel,
                  isLoading: _isOverdoseLoading,
                  onTap: _checkedCount >= 1
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
            icon: Icons.block_outlined,
            title: '병용금지 검사 결과',
            color: const Color(0xFFFF6B6B),
            onClose: () => setState(() => _showContraPanel = false),
          ),
          const Divider(height: 1),
          // 로딩 중
          if (_isContraLoading)
            const _LoadingIndicator(message: '성분 간 충돌을 분석하고 있어요...')
          // 결과 없음
          else if (_contraResults == null || _contraResults!.isEmpty)
            const _EmptyResult(message: '병용금지 성분이 발견되지 않았습니다.')
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
        ? const Color(0xFFFF6B6B)
        : const Color(0xFFFFC107);
    final bgColor = r.status == _CheckStatus.danger
        ? const Color(0xFFFFF0F0)
        : const Color(0xFFFFFDE7);
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
            color: const Color(0xFFFFC107),
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
                      _legend(const Color(0xFF4CAF50), '안전'),
                      const SizedBox(width: 12),
                      _legend(const Color(0xFFFFC107), '주의 (80% 이상)'),
                      const SizedBox(width: 12),
                      _legend(const Color(0xFFFF6B6B), '초과'),
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
        barColor = const Color(0xFFFF6B6B);
        textColor = const Color(0xFFFF6B6B);
        statusLabel = '초과';
        break;
      case _CheckStatus.warning:
        barColor = const Color(0xFFFFC107);
        textColor = const Color(0xFFFFC107);
        statusLabel = '주의';
        break;
      case _CheckStatus.safe:
        barColor = const Color(0xFF4CAF50);
        textColor = const Color(0xFF4CAF50);
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
                  '${_formatPrice(_totalPrice)}원',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4CAF50),
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
                  backgroundColor: const Color(0xFF4CAF50),
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
            color: Color(0xFF4CAF50),
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
            color: Color(0xFF4CAF50),
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
