import 'package:flutter/material.dart';
import 'package:simcap/features/cabinet/domain/dataModels/supplement_model.dart';

// 복용 기록 모델
// 날짜별로 어떤 영양제를 복용했는지 추적
class DoseRecord {
  final String supplementName; // Supplement.name을 키로 사용
  final DateTime date; // 복용한 날짜 (시간은 무시, 날짜만 비교)

  const DoseRecord({required this.supplementName, required this.date});
}

// SupplementProvider — 앱 전역 영양제 상태 관리
// InheritedWidget 기반: 외부 패키지 없이 동작
class SupplementProvider extends InheritedNotifier<SupplementNotifier> {
  const SupplementProvider({
    super.key,
    required SupplementNotifier notifier,
    required super.child,
  }) : super(notifier: notifier);

  /// 트리 어디서든 `SupplementProvider.of(context)` 로 접근
  static SupplementNotifier of(BuildContext context) {
    final provider = context
        .dependOnInheritedWidgetOfExactType<SupplementProvider>();
    assert(provider != null, 'SupplementProvider가 위젯 트리에 없습니다.');
    return provider!.notifier!;
  }
}

// SupplementNotifier — 실제 상태 + 비즈니스 로직
class SupplementNotifier extends ChangeNotifier {
  // TODO: 백엔드 연동 후 API 응답으로 초기화
  List<Supplement> _supplements = [
    Supplement(
      name: '비타민D 제품',
      brand: '브랜드 1',
      remaining: 60,
      total: 90,
      dailyDose: 1,
      mealTiming: MealTiming.afterMeal,
      analysisGuide: '지용성 비타민이므로 식후에 복용하면 흡수율이 더 높습니다.',
      nutrients: [
        Nutrient(name: '비타민 D', value: 1000, unit: 'IU', percent: 0.8),
      ],
    ),
    Supplement(
      name: '오메가3 제품',
      brand: '브랜드 2',
      remaining: 15,
      total: 60,
      dailyDose: 1,
      mealTiming: MealTiming.afterMeal,
      analysisGuide: '특유의 비린내를 방지하려면 찬물과 함께 복용하세요.',
      nutrients: [
        Nutrient(name: 'EPA+DHA', value: 1200, unit: 'mg', percent: 0.95),
        Nutrient(name: '비타민 E', value: 15, unit: 'mg', percent: 0.4),
      ],
    ),
    Supplement(
      name: '마그네슘 제품',
      brand: '브랜드 3',
      remaining: 3,
      total: 30,
      dailyDose: 1,
      mealTiming: MealTiming.beforeSleep,
      analysisGuide: '취침 전 복용 시 근육 이완과 숙면에 도움을 줄 수 있습니다.',
      nutrients: [Nutrient(name: '마그네슘', value: 400, unit: 'mg', percent: 1.1)],
    ),
  ];

  // 날짜별 복용 기록 (오늘 복용 여부 판단에 사용)
  final List<DoseRecord> _doseHistory = [];

  List<Supplement> get supplements => List.unmodifiable(_supplements);

  /// 오늘 복용해야 할 영양제 목록 (전체)
  List<Supplement> get todaySupplements => List.unmodifiable(_supplements);

  // 복용 여부 조회
  int get undoneCount => _supplements.where((s) => !isDoneToday(s.name)).length;

  // 재고가 7정 이하로 남은 영양제 개수
  int get lowStockCount => _supplements.where((s) => s.remaining <= 7).length;

  // 홈 화면 배지에 표시할 전체 알림 개수
  int get totalNotificationCount => undoneCount + lowStockCount;

  /// 특정 날짜에 해당 영양제를 복용했는지 여부
  bool isDoneOn(String supplementName, DateTime date) {
    final day = _dateOnly(date);
    return _doseHistory.any(
      (r) => r.supplementName == supplementName && _dateOnly(r.date) == day,
    );
  }

  /// 오늘 해당 영양제를 복용했는지 여부
  bool isDoneToday(String supplementName) =>
      isDoneOn(supplementName, DateTime.now());

  /// 특정 날짜에 복용 기록이 하나라도 있는지 여부 (캘린더 도트용)
  bool hasDoseRecordOn(DateTime date) {
    final day = _dateOnly(date);
    return _doseHistory.any((r) => _dateOnly(r.date) == day);
  }

  /// 특정 날짜에 모든 영양제를 복용 완료했는지 여부 (완전 완료 도트용)
  bool isAllDoneOn(DateTime date) {
    if (_supplements.isEmpty) return false;
    return _supplements.every((s) => isDoneOn(s.name, date));
  }

  /// 복용 체크/해제 토글.
  /// - 체크 시: 복용 기록 추가 + remaining -= dailyDose
  /// - 해제 시: 복용 기록 삭제 + remaining += dailyDose (되돌리기)
  void toggleDose(String supplementName, {DateTime? date}) {
    final targetDate = date ?? DateTime.now();
    final idx = _supplements.indexWhere((s) => s.name == supplementName);
    if (idx == -1) return;

    final supplement = _supplements[idx];
    final alreadyDone = isDoneOn(supplementName, targetDate);

    if (alreadyDone) {
      // 복용 해제: 기록 삭제 + remaining 복구
      _doseHistory.removeWhere(
        (r) =>
            r.supplementName == supplementName &&
            _dateOnly(r.date) == _dateOnly(targetDate),
      );
      _supplements[idx] = supplement.copyWith(
        remaining: supplement.remaining + supplement.dailyDose,
      );
    } else {
      // 복용 완료: 기록 추가 + remaining 차감 (0 미만 방지)
      _doseHistory.add(
        DoseRecord(supplementName: supplementName, date: targetDate),
      );
      final newRemaining = (supplement.remaining - supplement.dailyDose).clamp(
        0,
        supplement.total,
      );
      _supplements[idx] = supplement.copyWith(remaining: newRemaining);
    }

    notifyListeners();
  }

  // 캐비닛 CRUD

  void addSupplement(Supplement supplement) {
    _supplements.add(supplement);
    notifyListeners();
  }

  void updateSupplement(int index, Supplement updated) {
    if (index < 0 || index >= _supplements.length) return;
    _supplements[index] = updated;
    notifyListeners();
  }

  void removeSupplement(String name) {
    _supplements.removeWhere((s) => s.name == name);
    _doseHistory.removeWhere((r) => r.supplementName == name);
    notifyListeners();
  }

  /// 시간을 제거하고 날짜만 반환 (날짜 비교용)
  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
}
