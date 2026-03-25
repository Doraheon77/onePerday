import 'package:flutter/material.dart';

class SupplementCard extends StatelessWidget {
  final Map<String, dynamic> item;

  const SupplementCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    int remaining = item['remaining'] ?? 0;
    int total = item['total'] ?? 1; // 0으로 나누기 방지
    double progress = remaining / total;

    Color statusColor;
    if (progress <= 0.2) {
      statusColor = const Color(0xFFFF6B6B); // 진한 Red (위험)
    } else if (progress <= 0.5) {
      statusColor = const Color(0xFFFFC107); // 진한 Yellow (주의)
    } else {
      statusColor = const Color(0xFF388E3C); // 진한 Green (충분)
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // 메인 정보 영역
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      _buildCircleIcon(),
                      const SizedBox(width: 16),
                      _buildTextInfo(remaining),
                    ],
                  ),
                ),
              ),

              Container(
                width: 12,
                color: const Color(0xFFEEEEEE),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: FractionallySizedBox(
                    heightFactor: progress.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: statusColor, // 진해진 색상 적용
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCircleIcon() {
    return Container(
      width: 55,
      height: 55,
      decoration: const BoxDecoration(
        color: Color(0xFFF1F8E9),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.medication_rounded,
        color: Color(0xFF4CAF50),
        size: 28,
      ),
    );
  }

  Widget _buildTextInfo(int remaining) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            item['name'] ?? '',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 17,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item['brand'] ?? '',
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                "${remaining}정 남음",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(width: 8),
              _buildDDayBadge(remaining),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDDayBadge(int remaining) {
    Color badgeBgColor;
    Color badgeTextColor;

    if (remaining <= 7) {
      badgeBgColor = const Color(0xFFFFEBEB); // 연한 Red 배경
      badgeTextColor = const Color(0xFFFF6B6B); // 진한 Red 글자
    } else if (remaining <= 30) {
      badgeBgColor = const Color(0xFFFFFDE7); // 연한 Yellow 배경
      badgeTextColor = const Color(0xFFFFC107); // 진한 Yellow 글자
    } else {
      badgeBgColor = const Color(0xFFE8F5E9); // 연한 Green 배경
      badgeTextColor = const Color(0xFF388E3C); // 진한 Green 글자
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: badgeBgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        "D-$remaining",
        style: TextStyle(
          color: badgeTextColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
