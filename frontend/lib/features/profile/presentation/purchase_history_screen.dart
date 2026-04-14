import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:simcap/core/constant/app_constants.dart';
import 'package:simcap/providers/supplement_provider.dart';

class PurchaseHistoryScreen extends StatelessWidget {
  const PurchaseHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final purchases = SupplementProvider.of(context).purchases;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          '구매 기록',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        centerTitle: true,
      ),
      body: purchases.isEmpty
          ? _buildEmptyState(context)
          : _buildList(context, purchases),
    );
  }

  // 빈 상태
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            '구매 기록이 없습니다',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '스토어에서 영양제를 구매하면\n여기서 기록을 확인할 수 있어요',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[400],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          OutlinedButton.icon(
            onPressed: () => context.go('/store'),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            icon: const Icon(
              Icons.storefront_outlined,
              size: 16,
              color: AppColors.primary,
            ),
            label: const Text(
              '스토어 바로가기',
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

  // 구매 기록 리스트
  Widget _buildList(BuildContext context, List<PurchaseRecord> purchases) {
    // 날짜(일) 기준으로 그룹핑
    final Map<String, List<PurchaseRecord>> grouped = {};
    for (final r in purchases) {
      final key = _dateLabel(r.orderedAt);
      grouped.putIfAbsent(key, () => []).add(r);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final dateKey = grouped.keys.elementAt(index);
        final records = grouped[dateKey]!;
        return _buildDateGroup(context, dateKey, records);
      },
    );
  }

  // 날짜 그룹 헤더 + 카드 목록
  Widget _buildDateGroup(
    BuildContext context,
    String dateLabel,
    List<PurchaseRecord> records,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 날짜 헤더
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          child: Text(
            dateLabel,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[500],
            ),
          ),
        ),
        // 해당 날짜의 주문 카드들
        ...records.map((r) => _buildOrderCard(context, r)),
        const SizedBox(height: 8),
      ],
    );
  }

  // 주문 카드
  Widget _buildOrderCard(BuildContext context, PurchaseRecord record) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // 카드 헤더 (주문번호 + 상태 배지)
          _buildCardHeader(record),
          const Divider(height: 1),
          // 상품 목록
          _buildItemList(record),
          const Divider(height: 1),
          // 카드 푸터 (총액 + 버튼)
          _buildCardFooter(context, record),
        ],
      ),
    );
  }

  Widget _buildCardHeader(PurchaseRecord record) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Row(
        children: [
          // 주문 아이콘
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: AppColors.primaryFaint,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shopping_bag_outlined,
              size: 18,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.displayTitle,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  record.id,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[400],
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          // 상태 배지
          _buildStatusBadge(record.status),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(PurchaseStatus status) {
    Color bg, fg;
    IconData icon;

    switch (status) {
      case PurchaseStatus.ordered:
        bg = const Color(0xFFFFF3CD);
        fg = const Color(0xFF8a6200);
        icon = Icons.schedule_rounded;
        break;
      case PurchaseStatus.shipping:
        bg = const Color(0xFFE3F2FD);
        fg = const Color(0xFF1565C0);
        icon = Icons.local_shipping_outlined;
        break;
      case PurchaseStatus.delivered:
        bg = AppColors.primaryLight;
        fg = AppColors.primaryDark;
        icon = Icons.check_circle_rounded;
        break;
      case PurchaseStatus.cancelled:
        bg = AppColors.dangerBg;
        fg = AppColors.danger;
        icon = Icons.cancel_outlined;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemList(PurchaseRecord record) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: record.items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return Padding(
            padding: EdgeInsets.only(
              bottom: i < record.items.length - 1 ? 10 : 0,
            ),
            child: Row(
              children: [
                // 상품 이미지 자리
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primaryFaint,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.medication_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.brand,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${_formatPrice(item.totalPrice)}원',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      '${_formatPrice(item.price)}원 × ${item.count}개',
                      style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCardFooter(BuildContext context, PurchaseRecord record) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 총 결제 금액
          Row(
            children: [
              Text(
                '총 결제',
                style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              ),
              const SizedBox(width: 8),
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
          // 액션 버튼 — 상태별 분기
          _buildActionButton(context, record),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, PurchaseRecord record) {
    switch (record.status) {
      case PurchaseStatus.ordered:
      case PurchaseStatus.shipping:
        // 배송 조회 (백엔드 연동 후 실제 배송 추적 연결)
        return _actionBtn(
          label: '배송 조회',
          icon: Icons.local_shipping_outlined,
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('배송 조회는 백엔드 연동 후 지원됩니다.'),
              behavior: SnackBarBehavior.floating,
            ),
          ),
          outlined: true,
        );
      case PurchaseStatus.delivered:
        // 재구매 → 스토어로 이동
        return _actionBtn(
          label: '재구매',
          icon: Icons.refresh_rounded,
          onTap: () => context.go('/store'),
          outlined: false,
        );
      case PurchaseStatus.cancelled:
        return const SizedBox.shrink();
    }
  }

  Widget _actionBtn({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required bool outlined,
  }) {
    if (outlined) {
      return OutlinedButton.icon(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        icon: Icon(icon, size: 14, color: AppColors.primary),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
    return ElevatedButton.icon(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      icon: Icon(icon, size: 14),
      label: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  // 헬퍼
  String _dateLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(day).inDays;

    if (diff == 0) return '오늘';
    if (diff == 1) return '어제';
    if (diff < 7) return '$diff일 전';
    return '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }
}
