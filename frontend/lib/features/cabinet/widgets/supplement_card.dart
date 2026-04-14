import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:simcap/features/cabinet/domain/dataModels/supplement_model.dart';

class SupplementCard extends StatelessWidget {
  final Supplement item;

  const SupplementCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    int remaining = item.remaining;
    int total = item.total == 0 ? 1 : item.total;
    double progress = (remaining / total).clamp(0.0, 1.0);

    Color statusColor;
    if (progress <= 0.2) {
      statusColor = const Color(0xFFFF6B6B);
    } else if (progress <= 0.5) {
      statusColor = const Color(0xFFFFC107);
    } else {
      statusColor = const Color(0xFF4CAF50);
    }

    return GestureDetector(
      onTap: () => context.push('/cabinet/detail', extra: item),
      child: Container(
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
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 32, 20),
                child: Row(
                  children: [
                    _buildCircleIcon(),
                    const SizedBox(width: 16),
                    _buildTextInfo(remaining),
                  ],
                ),
              ),

              Positioned(
                top: 0,
                bottom: 0,
                right: 0,
                child: Container(
                  width: 10,
                  color: const Color(0xFFF3F4F6),
                  alignment: Alignment.bottomCenter,
                  child: FractionallySizedBox(
                    heightFactor: progress,
                    child: Container(
                      width: 10,
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(5),
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
      width: 50,
      height: 50,
      decoration: const BoxDecoration(
        color: Color(0xFFF1F8E9),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.medication_rounded,
        color: Color(0xFF4CAF50),
        size: 26,
      ),
    );
  }

  Widget _buildTextInfo(int remaining) {
    final int? daysLeft = item.daysUntilEmpty;

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            item.name.isEmpty ? '제품명 없음' : item.name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            item.brand.isEmpty ? '브랜드 정보 없음' : item.brand,
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '${remaining}정 남음',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(width: 8),
              // daysLeft가 null이면 배지 숨김 (dailyDose 미설정 방어)
              if (daysLeft != null) _buildDDayBadge(daysLeft),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDDayBadge(int daysLeft) {
    // 오늘 소진 또는 이미 소진
    if (daysLeft <= 0) {
      return _badge('소진', const Color(0xFFFFEBEB), const Color(0xFFFF6B6B));
    }

    // D-Day 문자열: 7일 이하 D-7, 이후 D-30 형식
    final label = 'D-$daysLeft';

    if (daysLeft <= 7) {
      return _badge(label, const Color(0xFFFFEBEB), const Color(0xFFFF6B6B));
    } else if (daysLeft <= 30) {
      return _badge(label, const Color(0xFFFFFDE7), const Color(0xFFFFC107));
    } else {
      return _badge(label, const Color(0xFFE8F5E9), const Color(0xFF4CAF50));
    }
  }

  Widget _badge(String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}