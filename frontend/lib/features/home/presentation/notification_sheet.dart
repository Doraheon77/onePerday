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

    // 오늘 미복용 회차 목록 (영양제 + 회차 인덱스)
    final List<({Supplement s, int index, TimeOfDay? time})> undoneTodayList =
        [];
    final today = DateTime.now();
    for (final s in supplements) {
      if (s.remaining <= 0) continue; // 소진 영양제 제외
      for (int i = 0; i < s.dailyFrequency; i++) {
        if (!notifier.isDoneOnIndex(s.id, today, i)) {
          final time = s.alarmTimes.length > i ? s.alarmTimes[i] : null;
          undoneTodayList.add((s: s, index: i, time: time));
        }
      }
    }

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
                        ...undoneTodayList.map(
                          (item) =>
                              _buildPillItem(item.s, item.index, item.time),
                        ),
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
  Widget _buildPillItem(Supplement s, int doseIndex, TimeOfDay? time) {
    String timeLabel = '';
    if (time != null) {
      final isPm = time.hour >= 12;
      final h = time.hour == 0
          ? 12
          : (time.hour > 12 ? time.hour - 12 : time.hour);
      final m = time.minute.toString().padLeft(2, '0');
      timeLabel = '${isPm ? "오후" : "오전"} $h:$m';
    }
    final doseLabel = s.dailyFrequency > 1
        ? ' (${doseIndex + 1}회차${timeLabel.isNotEmpty ? " · $timeLabel" : ""})'
        : timeLabel.isNotEmpty
        ? ' · $timeLabel'
        : '';

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
                Text(
                  '복용 알림$doseLabel',
                  style: const TextStyle(fontWeight: FontWeight.bold),
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
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              size: 44,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '모든 알림을 확인했어요!',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '오늘 복용을 모두 완료하면 알림이 사라집니다 🎉',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[500],
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  // 복용 시점 배지
}
