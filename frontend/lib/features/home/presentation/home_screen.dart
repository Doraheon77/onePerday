import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'notification_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _selectedDate = DateTime.now();

  int _notificationCount = 2; // 임시 알림 개수 (나중에 API 연동으로 바꿀 예정)

  final List<Map<String, dynamic>> _medications = [
    {'title': '프로바이오틱스 1캡슐', 'subtitle': '아침 식후', 'isDone': true},
    {'title': '마그네슘 2정', 'subtitle': '저녁 식후', 'isDone': false},
  ];

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
                      ..._medications
                          .asMap()
                          .entries
                          .map(
                            (entry) => _buildMedicationToggleCard(
                              entry.key,
                              entry.value,
                            ),
                          )
                          .toList(),
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

  // 달력 호출
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
                Row(
                  children: [
                    Badge(
                      label: Text('$_notificationCount'),
                      isLabelVisible: _notificationCount > 0, // 0개일 땐 숨김
                      backgroundColor: Colors.redAccent,
                      offset: const Offset(-2, 2),
                      child: IconButton(
                        icon: const Icon(
                          Icons.notifications_none_rounded,
                          color: Color(0xFF4CAF50),
                        ),
                        onPressed: () {
                          NotificationSheet.show(context);
                          setState(
                            () => _notificationCount = 0,
                          ); // 알림 개수 초기화 (실제 구현에서는 API 연동으로 관리)
                        },
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(4),
                      ),
                    ),
                    const SizedBox(width: 12),

                    const CircleAvatar(
                      radius: 16,
                      backgroundColor: Color(0xFFE8F5E9),
                      child: Icon(
                        Icons.person_outline_rounded,
                        size: 20,
                        color: Color(0xFF4CAF50),
                      ),
                    ),
                  ],
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
                    decoration: const BoxDecoration(
                      color: Color(0xFF4CAF50),
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

  Widget _buildMedicationToggleCard(int index, Map<String, dynamic> med) {
    bool isDone = med['isDone'];
    return GestureDetector(
      onTap: () => setState(() => _medications[index]['isDone'] = !isDone),
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
                : const Color(0xFFFFEBEE),
            child: Icon(
              isDone ? Icons.check : Icons.priority_high,
              color: Colors.white,
              size: 20,
            ),
          ),
          title: Text(
            med['title'],
            style: TextStyle(
              fontWeight: FontWeight.bold,
              decoration: isDone ? TextDecoration.lineThrough : null,
              color: isDone ? Colors.grey : Colors.black87,
            ),
          ),
          subtitle: Text(isDone ? "복용 완료" : med['subtitle']),
          trailing: Icon(
            isDone
                ? Icons.check_box_rounded
                : Icons.check_box_outline_blank_rounded,
            color: isDone ? const Color(0xFF4CAF50) : Colors.grey[400],
            size: 28,
          ),
        ),
      ),
    );
  }
}
