import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
      backgroundColor: const Color(0xFFF9FAFB),
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
                      const Text(
                        '오늘의 영양 성분 분석',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildNutritionCard(),
                      const SizedBox(height: 32),
                      const Text(
                        '오늘 남은 복용',
                        style: TextStyle(
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
              primary: Color(0xFF4CAF50),
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
                        "${_selectedDate.month}. ${_selectedDate.day} ${DateFormat('E', 'ko_KR').format(_selectedDate)}요일",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4CAF50),
                        ),
                      ),
                      const Icon(
                        Icons.arrow_drop_down,
                        color: Color(0xFF4CAF50),
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
                      color: Color(0xFF4CAF50),
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
              DateTime now = DateTime.now();
              DateTime firstDayOfWeek = now.subtract(
                Duration(days: now.weekday - 1),
              );
              DateTime date = firstDayOfWeek.add(Duration(days: index));
              bool isSelected =
                  date.day == _selectedDate.day &&
                  date.month == _selectedDate.month;
              return Column(
                children: [
                  Text(
                    ["월", "화", "수", "목", "금", "토", "일"][index],
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? const Color(0xFF4CAF50) : Colors.grey,
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
                            ? const Color(0xFF4CAF50)
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
                      color: isSelected
                          ? const Color(0xFF4CAF50)
                          : Colors.transparent,
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

  Widget _buildNutritionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildBarGraph('비타민 D', 0.8),
          _buildBarGraph('마그네슘', 0.4),
          _buildBarGraph('오메가3', 1.3),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F8E9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 16,
                  color: Color(0xFF4CAF50),
                ),
                SizedBox(width: 8),
                Text(
                  "적정 섭취량은 권장량의 70%~100% 사이입니다.",
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF2E7D32),
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

  Widget _buildBarGraph(String label, double ratio) {
    Color statusColor = ratio > 1.0
        ? Colors.redAccent
        : (ratio >= 0.7 ? const Color(0xFF4CAF50) : Colors.orangeAccent);
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "${(ratio * 100).round()}%",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0),
              backgroundColor: Colors.grey[100],
              color: statusColor,
              minHeight: 12,
            ),
          ),
        ],
      ),
    );
  }

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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDone ? const Color(0xFFF1F8E9) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDone
                ? const Color(0xFF4CAF50).withOpacity(0.5)
                : Colors.grey.withOpacity(0.1),
          ),
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: isDone
                ? const Color(0xFF4CAF50)
                : isToday
                    ? const Color(0xFFFFEBEE)
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
              // 재고가 부족할 때 표시되는 D-day 배지
              if (!isDone && supplement.remaining <= 7)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEB),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'D-${supplement.remaining}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFFFF6B6B),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              Icon(
                isDone
                    ? Icons.check_box_rounded
                    : Icons.check_box_outline_blank_rounded,
                color: isDone
                    ? const Color(0xFF4CAF50)
                    : isToday
                        ? Colors.grey[400]
                        : Colors.grey[200],
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
}