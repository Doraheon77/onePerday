import 'package:flutter/material.dart';
import '../data/survey_data.dart';

class SurveyChipGroup extends StatelessWidget {
  final List<SurveyOption> options;
  final List<String> selectedValues;
  final Function(String, bool) onSelected;

  const SurveyChipGroup({
    super.key,
    required this.options,
    required this.selectedValues,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, // 한 줄에 4개 배치
        crossAxisSpacing: 8, // 가로 간격
        mainAxisSpacing: 8, // 세로 간격
        childAspectRatio: 0.85, // subLabel이 빠졌으므로 높이를 살짝 줄임
      ),
      itemCount: options.length,
      itemBuilder: (context, index) {
        final option = options[index];
        final bool isSelected = selectedValues.contains(option.label);

        return GestureDetector(
          onTap: () => onSelected(option.label, !isSelected),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFE8F5E9) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF4CAF50)
                    : Colors.grey.shade200,
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 이미지/아이콘 영역
                if (option.imagePath.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      option.imagePath,
                      width: 32,
                      height: 32,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.medication,
                        size: 28,
                        color: Colors.grey,
                      ),
                    ),
                  )
                else
                  const Icon(Icons.medication, size: 28, color: Colors.grey),

                const SizedBox(height: 8),

                // 메인 라벨 (subLabel 제거됨)
                Text(
                  option.label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected
                        ? const Color(0xFF2E7D32)
                        : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
