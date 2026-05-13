import 'package:flutter/material.dart';
import '../data/survey_data.dart';

class SurveyChipGroup extends StatelessWidget {
  final List<SurveyOption> options;
  final List<String> selectedValues;
  final Function(String, bool) onSelected;

  /// 한 줄에 표시할 카드 수. 기본값 4, 성별처럼 2개만 있을 때는 2로 지정
  final int columns;

  const SurveyChipGroup({
    super.key,
    required this.options,
    required this.selectedValues,
    required this.onSelected,
    this.columns = 4,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: columns == 2 ? 1.3 : 0.85,
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
                      width: columns == 2 ? 52 : 32,
                      height: columns == 2 ? 52 : 32,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.medication,
                        size: columns == 2 ? 44 : 28,
                        color: Colors.grey,
                      ),
                    ),
                  )
                else
                  Icon(
                    Icons.medication,
                    size: columns == 2 ? 44 : 28,
                    color: Colors.grey,
                  ),

                const SizedBox(height: 8),

                Text(
                  option.label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: columns == 2 ? 16 : 12,
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
