import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:simcap/features/store/presentation/review_screen.dart';
import 'package:simcap/services/api_config.dart';

class ReviewApiService {
  /// 특정 상품의 리뷰 목록 조회 API
  Future<List<ProductReview>> fetchReviews(String productId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/review/$productId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) {
          return ProductReview(
            id: json['review_id']?.toString() ?? '',
            productId: json['supplements_id']?.toString() ?? '',
            productName: '',
            userName: json['userName']?.toString() ?? '익명',
            rating: double.tryParse(json['score']?.toString() ?? '0') ?? 0.0,
            content: json['content']?.toString() ?? '',
            createdAt: json['write_time'] != null
                ? DateTime.parse(json['write_time'])
                : DateTime.now(),
          );
        }).toList();
      } else {
        throw Exception('리뷰 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('ReviewApiService.fetchReviews 에러: $e');
      return [];
    }
  }

  /// 리뷰 등록 API
  Future<bool> createReview({
    required String productId,
    required String userId,
    required double rating,
    required String content,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/review'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'productId': productId,
          'userId': userId,
          'score': rating.toInt(), // score는 1~5 정수로 변환하여 전송
          'content': content,
        }),
      );

      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      debugPrint('ReviewApiService.createReview 에러: $e');
      return false;
    }
  }
}
