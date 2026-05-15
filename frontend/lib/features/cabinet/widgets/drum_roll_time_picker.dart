import 'package:flutter/material.dart';
import 'package:simcap/core/constant/app_constants.dart';

// ── 드럼롤 스타일 시간 선택 다이얼로그 ────────────────────────────────────────
class DrumRollTimePicker extends StatefulWidget {
  final TimeOfDay initialTime;
  const DrumRollTimePicker({required this.initialTime});

  @override
  State<DrumRollTimePicker> createState() => DrumRollTimePickerState();
}

class DrumRollTimePickerState extends State<DrumRollTimePicker> {
  late int _hour; // 1 ~ 12
  late int _minute; // 0 ~ 59
  late bool _isAm;

  late FixedExtentScrollController _hourCtrl;
  late FixedExtentScrollController _minuteCtrl;
  late FixedExtentScrollController _periodCtrl;

  static const double _itemH = 52.0;
  static const int _loopCount = 100; // 무한 스크롤 효과용 반복 수

  @override
  void initState() {
    super.initState();
    final h = widget.initialTime.hour;
    _isAm = h < 12;
    _hour = h == 0
        ? 12
        : h > 12
        ? h - 12
        : h;
    _minute = widget.initialTime.minute;

    // 가운데 위치에서 시작 (무한 스크롤 효과)
    final hourMid = (_loopCount ~/ 2) * 12 + (_hour - 1);
    final minuteMid = (_loopCount ~/ 2) * 60 + _minute;

    _hourCtrl = FixedExtentScrollController(initialItem: hourMid);
    _minuteCtrl = FixedExtentScrollController(initialItem: minuteMid);
    _periodCtrl = FixedExtentScrollController(initialItem: _isAm ? 0 : 1);
  }

  @override
  void dispose() {
    _hourCtrl.dispose();
    _minuteCtrl.dispose();
    _periodCtrl.dispose();
    super.dispose();
  }

  TimeOfDay get _result {
    int h = _hour % 12;
    if (!_isAm) h += 12;
    return TimeOfDay(hour: h, minute: _minute);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 제목
            const Text(
              '알림 시간 설정',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // 드럼롤 휠
            SizedBox(
              height: _itemH * 3,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 선택 영역 하이라이트
                  Container(
                    height: _itemH,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  Row(
                    children: [
                      // 오전/오후
                      Expanded(
                        flex: 3,
                        child: _buildWheel(
                          controller: _periodCtrl,
                          itemCount: 2,
                          looped: false,
                          onSelected: (i) => setState(() => _isAm = i == 0),
                          builder: (i) => _wheelItem(
                            i == 0 ? '오전' : '오후',
                            selected: (_isAm ? 0 : 1) == i,
                          ),
                        ),
                      ),
                      // 시
                      Expanded(
                        flex: 3,
                        child: _buildWheel(
                          controller: _hourCtrl,
                          itemCount: 12 * _loopCount,
                          looped: true,
                          onSelected: (i) => setState(() => _hour = i % 12 + 1),
                          builder: (i) => _wheelItem(
                            '${i % 12 + 1}',
                            selected: (i % 12 + 1) == _hour,
                            large: true,
                          ),
                        ),
                      ),
                      // 구분자
                      const Text(
                        ':',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      // 분
                      Expanded(
                        flex: 3,
                        child: _buildWheel(
                          controller: _minuteCtrl,
                          itemCount: 60 * _loopCount,
                          looped: true,
                          onSelected: (i) => setState(() => _minute = i % 60),
                          builder: (i) => _wheelItem(
                            (i % 60).toString().padLeft(2, '0'),
                            selected: (i % 60) == _minute,
                            large: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // 상단/하단 그라데이션 페이드
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Column(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.white,
                                    Colors.white.withOpacity(0.0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: _itemH),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Colors.white,
                                    Colors.white.withOpacity(0.0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 버튼
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    child: const Text(
                      '취소',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, _result),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    child: const Text(
                      '확인',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWheel({
    required FixedExtentScrollController controller,
    required int itemCount,
    required bool looped,
    required void Function(int) onSelected,
    required Widget Function(int) builder,
  }) {
    return ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: _itemH,
      diameterRatio: 1.4,
      perspective: 0.003,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: onSelected,
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: itemCount,
        builder: (_, i) => builder(i),
      ),
    );
  }

  Widget _wheelItem(String text, {bool selected = false, bool large = false}) {
    return Center(
      child: Text(
        text,
        style: TextStyle(
          fontSize: large ? 26 : 18,
          fontWeight: selected ? FontWeight.bold : FontWeight.w400,
          color: selected ? AppColors.primary : Colors.grey[400],
        ),
      ),
    );
  }
}
