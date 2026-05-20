import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:simcap/services/api_config.dart';

class IntakeApiService {
  Future<List<IntakeResult>> checkOverdoseByCartItems({
    required List<dynamic> cartItems,
    required int age,
    required String gender,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/intake/check-safety'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'age': age,
        'gender': gender,
        'cartItems': cartItems.map(_cartItemToJson).toList(),
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

  Map<String, dynamic> _cartItemToJson(dynamic item) {
    if (item is Map) {
      return {
        'productId': item['productId'],
        'name': item['name'],
        'brand': item['brand'],
        'count': item['count'] ?? 1,
      };
    }

    return {
      'productId': item.productId,
      'name': item.name,
      'brand': item.brand,
      'count': item.count,
    };
  }
}

class IntakeResult {
  final String nutrientName;
  final double currentTotal;
  final double upperLimit;
  final bool isExceeded;
  final String unit;
  final String status;

  IntakeResult({
    required this.nutrientName,
    required this.currentTotal,
    required this.upperLimit,
    required this.isExceeded,
    required this.unit,
    required this.status,
  });

  factory IntakeResult.fromJson(Map<String, dynamic> json) {
    return IntakeResult(
      nutrientName: json['nutrientName'] ?? '',
      currentTotal: (json['currentTotal'] ?? 0).toDouble(),
      upperLimit: (json['upperLimit'] ?? 0).toDouble(),
      isExceeded: json['isExceeded'] ?? false,
      unit: json['unit'] ?? '',
      status: json['status'] ?? 'safe',
    );
  }
}
