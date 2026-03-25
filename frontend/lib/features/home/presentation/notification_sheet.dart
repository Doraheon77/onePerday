import 'package:flutter/material.dart';

class NotificationSheet extends StatelessWidget {
  const NotificationSheet({super.key});

  // 알림창을 띄우는 정적(static) 함수
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      isScrollControlled: true, // 내용이 많을 경우 대비
      builder: (context) => const NotificationSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 임시 데이터 (나중에 이 부분만 API 연동으로 바꾸면 됨)
    final List<Map<String, dynamic>> notifications = [
      {
        'type': 'pill',
        'title': '복용 알림',
        'content': '아직 [마그네슘 2정]을 복용하지 않으셨어요!',
        'time': '10분 전',
        'isUrgent': true,
      },
      {
        'type': 'stock',
        'title': '재고 부족',
        'content': '[프로바이오틱스]가 3일분 남았습니다.',
        'time': '1시간 전',
        'isUrgent': false,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      height: MediaQuery.of(context).size.height * 0.6,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "알림",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const Divider(height: 30),
          Expanded(
            child: ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                return _buildNotificationItem(notifications[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> item) {
    bool isUrgent = item['isUrgent'] ?? false;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUrgent ? const Color(0xFFFFF3F3) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            item['type'] == 'pill'
                ? Icons.medication_liquid
                : Icons.inventory_2_outlined,
            color: isUrgent ? Colors.redAccent : const Color(0xFF4CAF50),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item['title'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      item['time'],
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item['content'],
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
