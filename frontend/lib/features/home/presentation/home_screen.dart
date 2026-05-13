import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:simcap/core/constant/app_constants.dart';
import 'package:simcap/features/cabinet/domain/dataModels/supplement_model.dart';
import 'package:simcap/providers/supplement_provider.dart';
import 'notification_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildWeeklyCalendar(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStreakCard(),
                      const SizedBox(height: 24),
                      Text(
                        _isSelectedToday ? '오늘의 영양 성분 분석' : '영양 성분 분석',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildNutritionCard(),
                      const SizedBox(height: 32),
                      Text(
                        _isSelectedToday
                            ? '오늘 남은 복용'
                            : '${_selectedDate.month}월 ${_selectedDate.day}일 복용 현황',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildMedicationList(),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomCalendar(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      locale: const Locale('ko', 'KR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  // ── 월간 복용 달력 바텀시트 ──────────────────────────────────────────────
  void _showMonthlyCalendar(BuildContext context, SupplementNotifier notifier) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _MonthlyCalendarSheet(notifier: notifier),
    );
  }

  // ── 주간 캘린더 ──────────────────────────────────────────────────────────
  Widget _buildWeeklyCalendar() {
    final notifier = SupplementProvider.of(context);
    final notificationCount = notifier.totalNotificationCount;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => _showCustomCalendar(context),
                  child: Row(
                    children: [
                      Text(
                        "${_selectedDate.month}. ${_selectedDate.day} "
                        "${DateFormat('E', 'ko_KR').format(_selectedDate)}요일",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const Icon(
                        Icons.arrow_drop_down,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
                Badge(
                  label: Text('$notificationCount'),
                  isLabelVisible: notificationCount > 0,
                  backgroundColor: Colors.redAccent,
                  offset: const Offset(-2, 2),
                  child: IconButton(
                    icon: const Icon(
                      Icons.notifications_none_rounded,
                      color: AppColors.primary,
                      size: 26,
                    ),
                    onPressed: () => NotificationSheet.show(context),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (index) {
              final DateTime now = DateTime.now();
              final DateTime firstDayOfWeek = now.subtract(
                Duration(days: now.weekday - 1),
              );
              final DateTime date = firstDayOfWeek.add(Duration(days: index));

              final bool isSelected =
                  date.day == _selectedDate.day &&
                  date.month == _selectedDate.month;
              final bool isFuture = date.isAfter(now);

              final notifier = SupplementProvider.of(context);
              final bool allDone = !isFuture && notifier.isAllDoneOn(date);
              final bool partialDone =
                  !isFuture && !allDone && notifier.hasDoseRecordOn(date);

              return Column(
                children: [
                  Text(
                    ["월", "화", "수", "목", "금", "토", "일"][index],
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? AppColors.primary : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => setState(() => _selectedDate = date),
                    child: Container(
                      width: 38,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        "${date.day}",
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: allDone ? AppColors.primary : Colors.transparent,
                      border: partialDone
                          ? Border.all(color: AppColors.primary, width: 1)
                          : null,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  // ── 복용 스트릭 & 통계 카드 ──────────────────────────────────────────────
  Widget _buildStreakCard() {
    final notifier = SupplementProvider.of(context);
    final streak = notifier.currentStreak;
    final best = notifier.bestStreak;
    final monthly = notifier.monthlyComplianceRate;
    final total = notifier.totalDoneDays;
    final done = notifier.todayDoneCount;
    final supplementTotal = notifier.todayTotalCount;

    // 영양제 미등록 시 안내 카드
    if (supplementTotal == 0) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Row(
          children: [
            Icon(Icons.add_circle_outline, color: Colors.white70, size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                '캐비닛에 영양제를 추가하면\n복용 통계를 확인할 수 있어요!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final todayRate = supplementTotal > 0 ? done / supplementTotal : 0.0;
    final streakMsg = streak == 0
        ? '오늘 복용을 시작해보세요!'
        : streak < 3
        ? '좋은 시작이에요! 계속해봐요 💪'
        : streak < 7
        ? '습관이 만들어지고 있어요 🌱'
        : streak < 30
        ? '대단해요! ${streak}일 연속 복용 중 🔥'
        : '믿기 어려운 기록이에요! 🏆';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단: 스트릭 + 오늘 진행도
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$streak',
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Padding(
                          padding: EdgeInsets.only(bottom: 6),
                          child: Text(
                            '일 연속',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      streakMsg,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              _buildCircularProgress(done, supplementTotal, todayRate),
            ],
          ),
          const SizedBox(height: 20),
          // 하단: 3개 통계 칩
          Row(
            children: [
              _buildStatChip(
                icon: Icons.calendar_month_outlined,
                label: '이번 달',
                value: '${(monthly * 100).round()}%',
                onTap: () => _showMonthlyCalendar(context, notifier),
              ),
              const SizedBox(width: 8),
              _buildStatChip(
                icon: Icons.emoji_events_outlined,
                label: '최고 기록',
                value: '$best일',
              ),
              const SizedBox(width: 8),
              _buildStatChip(
                icon: Icons.check_circle_outline,
                label: '총 복용',
                value: '$total일',
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── 원형 진행도 ──────────────────────────────────────────────────────────
  Widget _buildCircularProgress(int done, int total, double rate) {
    return SizedBox(
      width: 72,
      height: 72,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 72,
            height: 72,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: 6,
              color: Colors.white.withOpacity(0.2),
            ),
          ),
          SizedBox(
            width: 72,
            height: 72,
            child: CircularProgressIndicator(
              value: rate,
              strokeWidth: 6,
              color: Colors.white,
              backgroundColor: Colors.transparent,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$done/$total',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                '복용',
                style: TextStyle(color: Colors.white70, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── 통계 칩 ──────────────────────────────────────────────────────────────
  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(onTap != null ? 0.22 : 0.15),
            borderRadius: BorderRadius.circular(14),
            border: onTap != null
                ? Border.all(color: Colors.white.withOpacity(0.3))
                : null,
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.white70, size: 16),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: const TextStyle(color: Colors.white60, fontSize: 10),
                  ),
                  if (onTap != null)
                    const Icon(
                      Icons.chevron_right,
                      size: 10,
                      color: Colors.white60,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── 영양 성분 카드 ────────────────────────────────────────────────────────
  Widget _buildNutritionCard() {
    final supplements = SupplementProvider.of(context).supplements;
    final Map<String, double> totals = {};
    for (final s in supplements) {
      for (final n in s.nutrients) {
        totals[n.name.trim()] = (totals[n.name.trim()] ?? 0) + n.percent;
      }
    }
    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(5).toList();

    final boxDeco = BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 15,
          offset: const Offset(0, 4),
        ),
      ],
    );

    if (top.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        decoration: boxDeco,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart_outlined, size: 64, color: Colors.grey[200]),
            const SizedBox(height: 16),
            Text(
              '등록된 영양제가 없습니다',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '캐비닛에 영양제를 추가하면\n성분별 섭취량을 분석해 드려요',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[400],
                height: 1.6,
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () => context.go('/cabinet'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              icon: const Icon(Icons.add, size: 16, color: AppColors.primary),
              label: const Text(
                '영양제 추가하기',
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

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: boxDeco,
      child: Column(
        children: [
          ...top.map((e) => _buildBarGraph(e.key, e.value)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryFaint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 16,
                  color: AppColors.primary,
                ),
                SizedBox(width: 8),
                Text(
                  '적정 섭취량은 권장량의 70%~100% 사이입니다.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 바 그래프 ─────────────────────────────────────────────────────────────
  Widget _buildBarGraph(String label, double ratio) {
    // 0~100%: 초록, 100~150%: 주황(권장량 초과), 150%+: 빨강(상한 섭취량)
    final Color barColor = ratio > 1.5
        ? AppColors.danger
        : ratio > 1.0
        ? AppColors.warning
        : ratio >= 0.7
        ? AppColors.primary
        : AppColors.warning;
    final pct = '${(ratio * 100).round()}%';
    final statusNote = ratio > 1.5
        ? '상한 섭취량 초과'
        : ratio > 1.0
        ? '권장량 초과'
        : ratio >= 0.7
        ? '적정 섭취'
        : '섭취 부족';

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                pct,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: barColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0),
              backgroundColor: Colors.grey[100],
              color: barColor,
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 4),
          Text(statusNote, style: TextStyle(fontSize: 10, color: barColor)),
        ],
      ),
    );
  }

  // ── 복용 목록 ─────────────────────────────────────────────────────────────
  Widget _buildMedicationList() {
    final notifier = SupplementProvider.of(context);
    final supplements = notifier.todaySupplements;

    if (supplements.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: Text(
            '등록된 영양제가 없습니다.\n캐비닛에서 영양제를 추가해보세요!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, height: 1.6),
          ),
        ),
      );
    }

    return Column(
      children: supplements
          .map((s) => _buildMedicationToggleCard(s, notifier))
          .toList(),
    );
  }

  Widget _buildMedicationToggleCard(
    Supplement supplement,
    SupplementNotifier notifier,
  ) {
    final isDone = notifier.isDoneOn(supplement.name, _selectedDate);
    final isToday = _dateOnly(_selectedDate) == _dateOnly(DateTime.now());

    return GestureDetector(
      onTap: isToday
          ? () => notifier.toggleDose(supplement.name, date: _selectedDate)
          : null,
      child: _buildMedicationCard(supplement, isDone, isToday),
    );
  }

  Widget _buildMedicationCard(
    Supplement supplement,
    bool isDone,
    bool isToday,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDone ? AppColors.primaryFaint : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDone
              ? AppColors.primary.withOpacity(0.5)
              : Colors.grey.withOpacity(0.1),
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isDone
              ? AppColors.primary
              : isToday
              ? AppColors.dangerBg
              : Colors.grey.shade200,
          child: Icon(
            isDone ? Icons.check : Icons.priority_high,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          supplement.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: isDone ? TextDecoration.lineThrough : null,
            color: isDone ? Colors.grey : Colors.black87,
          ),
        ),
        subtitle: Text(
          isDone
              ? '복용 완료 · ${supplement.remaining}정 남음'
              : '${supplement.mealTiming.label} · ${supplement.remaining}정 남음',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isDone && supplement.remaining <= 7)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.dangerBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'D-${supplement.remaining}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.danger,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            Icon(
              isDone
                  ? Icons.check_box_rounded
                  : Icons.check_box_outline_blank_rounded,
              color: isDone
                  ? AppColors.primary
                  : isToday
                  ? Colors.grey[400]
                  : Colors.grey[200],
              size: 28,
            ),
          ],
        ),
      ),
    );
  }

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  bool get _isSelectedToday =>
      _dateOnly(_selectedDate) == _dateOnly(DateTime.now());
}

// ── 월간 복용 달력 바텀시트 ──────────────────────────────────────────────────
class _MonthlyCalendarSheet extends StatefulWidget {
  final SupplementNotifier notifier;
  const _MonthlyCalendarSheet({required this.notifier});

  @override
  State<_MonthlyCalendarSheet> createState() => _MonthlyCalendarSheetState();
}

class _MonthlyCalendarSheetState extends State<_MonthlyCalendarSheet> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    _month = DateTime(DateTime.now().year, DateTime.now().month);
  }

  DateTime get _today => DateTime.now();

  List<DateTime?> get _calendarDays {
    final firstDay = DateTime(_month.year, _month.month, 1);
    final lastDay = DateTime(_month.year, _month.month + 1, 0);
    final leadingBlanks = (firstDay.weekday - 1) % 7;
    return [
      ...List.filled(leadingBlanks, null),
      ...List.generate(
        lastDay.day,
        (i) => DateTime(_month.year, _month.month, i + 1),
      ),
    ];
  }

  String _dayStatus(DateTime day) {
    final n = widget.notifier;
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final d = DateTime(day.year, day.month, day.day);
    if (d.isAfter(today)) return 'future';
    // 현재 등록된 영양제가 없으면 복용 기록만으로 판단
    if (n.supplements.isEmpty) {
      return n.hasDoseRecordOn(d) ? 'partial' : 'none';
    }
    // 현재 영양제 기준으로 모두 복용했으면 allDone
    if (n.isAllDoneOn(d)) return 'allDone';
    // 일부라도 복용 기록이 있으면 partial
    if (n.hasDoseRecordOn(d)) return 'partial';
    return 'none';
  }

  @override
  Widget build(BuildContext context) {
    final now = _today;
    final days = _calendarDays;
    final isCurrentMonth = _month.year == now.year && _month.month == now.month;
    final lastDayOfMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final countDays = isCurrentMonth ? now.day : lastDayOfMonth;

    // 해당 월 복용 일수 계산
    // - 현재 영양제 모두 복용한 날: allDone (완전 복용)
    // - 일부라도 복용 기록 있는 날: partial (부분 복용)
    // 복용률은 완전 복용 기준으로 계산
    int doneDays = 0;
    int partialDays = 0;
    for (int i = 1; i <= countDays; i++) {
      final d = DateTime(_month.year, _month.month, i);
      if (widget.notifier.isAllDoneOn(d)) {
        doneDays++;
      } else if (widget.notifier.hasDoseRecordOn(d)) {
        partialDays++;
      }
    }
    final rate = countDays > 0 ? doneDays / countDays : 0.0;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      builder: (_, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          // 드래그 핸들
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),

          // 헤더: 월 이동
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: () => setState(() {
                  _month = DateTime(_month.year, _month.month - 1);
                }),
              ),
              Expanded(
                child: Text(
                  '${_month.year}년 ${_month.month}월',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: _month.year == now.year && _month.month == now.month
                    ? null
                    : () => setState(() {
                        _month = DateTime(_month.year, _month.month + 1);
                      }),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 월간 요약
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _summaryItem('완전 복용', '$doneDays일', AppColors.primary),
                _summaryItem('부분 복용', '$partialDays일', AppColors.warning),
                _summaryItem(
                  '미복용',
                  '${countDays - doneDays - partialDays}일',
                  Colors.grey,
                ),
                _summaryItem(
                  isCurrentMonth ? '이번 달' : '${_month.month}월',
                  '${(rate * 100).round()}%',
                  AppColors.primaryDark,
                ),
              ],
            ),
          ),

          // 요일 헤더
          Row(
            children: ['월', '화', '수', '목', '금', '토', '일']
                .map(
                  (d) => Expanded(
                    child: Text(
                      d,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[400],
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),

          // 날짜 그리드
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.0,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: days.length,
            itemBuilder: (_, i) {
              final day = days[i];
              if (day == null) return const SizedBox.shrink();
              final status = _dayStatus(day);
              final isToday =
                  day.year == now.year &&
                  day.month == now.month &&
                  day.day == now.day;
              return _buildDayCell(day, status, isToday);
            },
          ),
          const SizedBox(height: 20),

          // 범례
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendItem(AppColors.primary, '전체 복용'),
              const SizedBox(width: 16),
              _legendItem(AppColors.warning, '일부 복용'),
              const SizedBox(width: 16),
              _legendItem(Colors.grey[200]!, '미복용'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDayCell(DateTime day, String status, bool isToday) {
    Color bg;
    Color textColor;
    Widget? badge;

    switch (status) {
      case 'allDone':
        bg = AppColors.primary;
        textColor = Colors.white;
        badge = const Positioned(
          top: 2,
          right: 2,
          child: Icon(Icons.check_circle, size: 10, color: Colors.white70),
        );
        break;
      case 'partial':
        bg = AppColors.warning.withOpacity(0.25);
        textColor = Colors.orange.shade800;
        badge = Positioned(
          top: 2,
          right: 2,
          child: Icon(
            Icons.remove_circle,
            size: 10,
            color: Colors.orange.shade400,
          ),
        );
        break;
      case 'future':
        bg = Colors.transparent;
        textColor = Colors.grey[300]!;
        break;
      default:
        bg = Colors.grey[100]!;
        textColor = Colors.grey[500]!;
    }

    return Stack(
      children: [
        Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: isToday
                ? Border.all(color: AppColors.primary, width: 2)
                : null,
          ),
          child: Text(
            '${day.day}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
              color: isToday && status != 'allDone'
                  ? AppColors.primary
                  : textColor,
            ),
          ),
        ),
        if (badge != null) badge,
      ],
    );
  }

  Widget _summaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
      ],
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
      ],
    );
  }
}
