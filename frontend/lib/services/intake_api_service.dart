import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:simcap/core/constant/app_constants.dart';

class IntakeApiService {
  String get baseUrl => AppConstants.apiBaseUrl;

  Future<List<IntakeResult>> checkOverdoseByCartItems({
    required List<dynamic> cartItems,
    required int age,
    required String gender,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/intake/check-safety'),
      headers: AppConstants.headers,
      body: jsonEncode({
        'age': age,
        'gender': gender,
        'cartItems': cartItems.map((item) {
          if (item is Map<String, dynamic>) {
            return item;
          }

          return {
            'productId': item.productId,
            'name': item.name,
            'brand': item.brand,
            'count': item.count,
          };
        }).toList(),
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('과다섭취 검사 실패: ${response.body}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final results = decoded['results'] as List<dynamic>? ?? [];

    return results
        .map((e) => IntakeResult.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> completeIntake({
    required String userUuid,
    required String inventoryId,
    required int doseIndex,
    required String date,
    required String supplementTime,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/intake/complete'),
      headers: AppConstants.headers,
      body: jsonEncode({
        'userUuid': userUuid,
        'inventoryId': int.parse(inventoryId),
        'doseIndex': doseIndex,
        'date': date,
        'supplementTime': supplementTime,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('복용 완료 저장 실패: ${response.body}');
    }
  }

  Future<void> cancelIntake({
    required String userUuid,
    required String inventoryId,
    required int doseIndex,
    required String date,
    required String supplementTime,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/intake/cancel'),
      headers: AppConstants.headers,
      body: jsonEncode({
        'userUuid': userUuid,
        'inventoryId': int.parse(inventoryId),
        'doseIndex': doseIndex,
        'date': date,
        'supplementTime': supplementTime,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('복용 취소 실패: ${response.body}');
    }
  }
}

class IntakeResult {
  final String nutrientName;
  final double currentTotal;
  final double recommendedIntake;
  final double adequateIntake;
  final double upperLimit;
  final bool isExceeded;
  final String unit;
  final String status;

  IntakeResult({
    required this.nutrientName,
    required this.currentTotal,
    required this.recommendedIntake,
    required this.adequateIntake,
    required this.upperLimit,
    required this.isExceeded,
    required this.unit,
    required this.status,
  });

  factory IntakeResult.fromJson(Map<String, dynamic> json) {
    final status = json['status']?.toString() ?? 'safe';

    return IntakeResult(
      nutrientName: json['nutrientName']?.toString() ?? '',
      currentTotal: _toDouble(json['currentTotal']),
      recommendedIntake: _toDouble(json['recommendedIntake']),
      adequateIntake: _toDouble(json['adequateIntake']),
      upperLimit: _toDouble(json['upperLimit']),
      isExceeded: json['isExceeded'] == true || status == 'danger',
      unit: json['unit']?.toString() ?? '',
      status: status,
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
