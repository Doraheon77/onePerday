import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:simcap/core/constant/app_constants.dart';
import 'package:simcap/features/cabinet/domain/dataModels/supplement_model.dart';
import 'package:simcap/providers/supplement_provider.dart';

class NotificationSheet extends StatelessWidget {
  const NotificationSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      isScrollControlled: true,
      builder: (context) => const NotificationSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifier = SupplementProvider.of(context);
    final supplements = notifier.supplements;

    // 오늘 미복용 영양제
    final List<Supplement> undoneTodayList = supplements
        .where((s) => !notifier.isDoneToday(s.name))
        .toList();

    // 잔여량 7정 이하 (재구매 필요)
    final List<Supplement> lowStockList = supplements
        .where((s) => s.remaining <= AppConstants.lowStockThreshold)
        .toList();

    final bool isEmpty = undoneTodayList.isEmpty && lowStockList.isEmpty;

    return Container(
      padding: const EdgeInsets.all(24),
      height: MediaQuery.of(context).size.height * 0.6,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    '알림',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  if (!isEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        '${undoneTodayList.length + lowStockList.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const Divider(height: 30),

          Expanded(
            child: isEmpty
                ? _buildEmptyState()
                : ListView(
                    children: [
                      // 섹션 1: 오늘 미복용 알림
                      if (undoneTodayList.isNotEmpty) ...[
                        _buildSectionLabel('오늘 복용 알림', Icons.medication_liquid),
                        ...undoneTodayList.map((s) => _buildPillItem(s)),
                        const SizedBox(height: 8),
                      ],

                      // 섹션 2: 재구매 필요 알림
                      if (lowStockList.isNotEmpty) ...[
                        _buildSectionLabel(
                          '재구매 알림',
                          Icons.shopping_bag_outlined,
                        ),
                        ...lowStockList.map((s) => _buildStockItem(context, s)),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // 섹션 라벨
  Widget _buildSectionLabel(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 15, color: Colors.grey[500]),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[500],
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  // 미복용 알림 카드
  Widget _buildPillItem(Supplement s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3F3),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.medication_liquid,
            color: Colors.redAccent,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '복용 알림',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    _timingBadge(s.mealTiming),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '[${s.name}]을(를) 아직 복용하지 않으셨어요!',
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 재구매 알림 카드
  Widget _buildStockItem(BuildContext context, Supplement s) {
    final int? daysLeft = s.daysUntilEmpty;
    final bool isCritical = s.remaining <= AppConstants.criticalStockThreshold;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCritical ? const Color(0xFFFFF3F3) : const Color(0xFFFFFDE7),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            color: isCritical ? Colors.redAccent : const Color(0xFFFFC107),
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '재고 부족',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    // D-Day 배지
                    if (daysLeft != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isCritical
                              ? const Color(0xFFFF6B6B)
                              : const Color(0xFFFFC107),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          daysLeft <= 0 ? '오늘 소진' : 'D-$daysLeft',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '[${s.name}]이(가) ${s.remaining}정 남았습니다.',
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
                const SizedBox(height: 8),
                // 스토어 이동 버튼
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/store');
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '스토어에서 재구매',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isCritical
                              ? Colors.redAccent
                              : const Color(0xFF4CAF50),
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 11,
                        color: isCritical
                            ? Colors.redAccent
                            : const Color(0xFF4CAF50),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 알림 없음 상태
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 56,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            '새로운 알림이 없습니다',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '오늘의 복용을 모두 완료했어요!',
            style: TextStyle(fontSize: 13, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  // 복용 시점 배지
  Widget _timingBadge(MealTiming timing) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        timing.label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Color(0xFF4CAF50),
        ),
      ),
    );
  }
}
