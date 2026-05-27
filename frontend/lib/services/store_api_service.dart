import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:simcap/features/store/presentation/supplement_detail_screen.dart';
import 'package:simcap/services/api_config.dart';

class StoreApiService {
  static const String baseUrl = ApiConfig.baseUrl;

  Future<List<StoreProduct>> fetchSupplements({
    String? keyword,
    bool record = false,
    List<String> categories = const [],
    List<String> ingredients = const [],
    String? priceRange,
  }) async {
    // 쿼리 파라미터 동적 생성
    final queryParams = <String, String>{};
    if (keyword != null && keyword.trim().isNotEmpty) {
      queryParams['keyword'] = keyword.trim();
      queryParams['record'] = record.toString();
    }
    if (categories.isNotEmpty) {
      queryParams['categories'] = categories.join(',');
    }
    if (ingredients.isNotEmpty) {
      queryParams['ingredients'] = ingredients.join(',');
    }
    if (priceRange != null && priceRange.isNotEmpty) {
      queryParams['priceRange'] = priceRange;
    }

    final uri = Uri.parse('$baseUrl/supplements').replace(queryParameters: queryParams.isEmpty ? null : queryParams);
    final response = await http.get(uri);

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

  // [개선된 코드] 유저 ID를 받아 맞춤 추천 영양제를 반환하는 함수 추가
  Future<List<StoreProduct>> fetchRecommendedSupplements(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/recommend?userId=$userId'),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('추천 영양제 목록 조회 실패: ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    final results = decoded as List<dynamic>? ?? [];

    return results
        .map((e) => StoreProduct.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // [개선된 코드] 실시간 인기 검색어 목록을 가져오는 함수 추가
  Future<List<String>> fetchPopularSearches() async {
    final response = await http.get(
      Uri.parse('$baseUrl/supplements/popular'),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('인기 검색어 조회 실패: ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    final results = decoded as List<dynamic>? ?? [];
    return results.map((e) => e.toString()).toList();
  }
}
