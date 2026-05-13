import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:simcap/features/store/presentation/supplement_detail_screen.dart';

class StoreApiService {
  static const String baseUrl = 'http://10.0.2.2:3000';

  Future<List<StoreProduct>> fetchSupplements() async {
    final response = await http.get(
      Uri.parse('$baseUrl/supplements'),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('영양제 목록 조회 실패: ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    // NestJS 백엔드에서 배열로 응답이 올 것이라 가정
    final results = decoded as List<dynamic>? ?? [];

    return results
        .map((e) => StoreProduct.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
