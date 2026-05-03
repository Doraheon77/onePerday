class IntakeResultModel {
  final String nutrientName;
  final double currentTotal;
  final double? upperLimit;
  final bool isExceeded;
  final String unit;

  IntakeResultModel({
    required this.nutrientName,
    required this.currentTotal,
    required this.upperLimit,
    required this.isExceeded,
    required this.unit,
  });

  factory IntakeResultModel.fromJson(Map<String, dynamic> json) {
    return IntakeResultModel(
      nutrientName: json['nutrientName'] ?? '',
      currentTotal: (json['currentTotal'] ?? 0).toDouble(),
      upperLimit: json['upperLimit'] != null
          ? (json['upperLimit'] as num).toDouble()
          : null,
      isExceeded: json['isExceeded'] ?? false,
      unit: json['unit'] ?? '',
    );
  }
}