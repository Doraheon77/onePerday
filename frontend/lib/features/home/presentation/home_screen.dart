import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 모킹 데이터 (임시)
  final List<Map<String, dynamic>> morningBefore = [
    {'name': '비타민 D', 'checked': false},
    {'name': '오메가3', 'checked': true},
    {'name': '비타민 B Complex', 'checked': false},
  ];

  final List<Map<String, dynamic>> morningAfter = [
    {'name': '프로바이오틱스', 'checked': true},
    {'name': '멀티비타민 & 미네랄', 'checked': true},
  ];

  final List<Map<String, dynamic>> eveningAfter = [
    {'name': '마그네슘', 'checked': true},
    {'name': 'L-테아닌 + GABA', 'checked': true},
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          100,
        ), // Bottom Nav + FAB 여유
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 인사말 + 아바타
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '안녕하세요, 사용자님!',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '오늘 영양제 상태를 확인해보세요',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFFE8F5E9),
                  child: const Icon(Icons.person, color: Color(0xFF4CAF50)),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 녹색 상태 바 (얇게)
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 32),

            // 시간대별 섹션
            _buildTimeSection('아침·식전', morningBefore),
            const SizedBox(height: 24),
            _buildTimeSection('아침·식후', morningAfter),
            const SizedBox(height: 24),
            _buildTimeSection('저녁·식후', eveningAfter),
            const SizedBox(height: 80), // FAB + Bottom Nav 여유
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSection(String title, List<Map<String, dynamic>> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4CAF50),
            ),
          ),
        ),
        const SizedBox(height: 8),
        ...items.map(
          (item) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFFE8F5E9),
                child: const Icon(
                  Icons.circle,
                  size: 12,
                  color: Color(0xFF4CAF50),
                ),
              ),
              title: Text(
                item['name'] as String,
                style: const TextStyle(fontSize: 16),
              ),
              trailing: Switch(
                value: item['checked'] as bool,
                activeColor: const Color(0xFF4CAF50),
                inactiveThumbColor: Colors.grey,
                inactiveTrackColor: Colors.grey.shade300,
                onChanged: (value) {
                  setState(() {
                    item['checked'] = value;
                  });
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
