class Nutrient {
  final String name;
  final double value;
  final String unit;
  final double percent;

  Nutrient({
    required this.name,
    required this.value,
    required this.unit,
    required this.percent,
  });

  // DB(JSON) 데이터를 객체로 변환하는 생성자
  factory Nutrient.fromJson(Map<String, dynamic> json) {
    return Nutrient(
      name: json['name'] ?? '',
      value: (json['value'] ?? 0).toDouble(),
      unit: json['unit'] ?? '',
      percent: (json['percent'] ?? 0.0).toDouble(),
    );
  }
}

class Supplement {
  final String name;
  final String brand;
  final String? imagePath;
  final int remaining;
  final int total;
  final List<Nutrient> nutrients;
  final String analysisGuide;
  final String aiSummary;

  Supplement({
    required this.name,
    required this.brand,
    this.imagePath,
    required this.remaining,
    required this.total,
    required this.nutrients,
    this.analysisGuide = '이 영양제는 정해진 시간에 복용하는 것이 좋습니다.',
    this.aiSummary = '리뷰를 분석 중입니다.',
  });

  // DB 데이터를 영양제 객체로 변환
  factory Supplement.fromJson(Map<String, dynamic> json) {
    return Supplement(
      name: json['name'] ?? '',
      brand: json['brand'] ?? '',
      remaining: json['remaining'] ?? 0,
      total: json['total'] ?? 0,
      nutrients: (json['nutrients'] as List? ?? [])
          .map((n) => Nutrient.fromJson(n))
          .toList(),
      analysisGuide: json['analysisGuide'] ?? '이 영양제는 복합 성분 설계로 흡수율을 높였습니다.',
      aiSummary: json['aiSummary'] ?? '리뷰를 분석 중입니다.',
    );
  }
}
