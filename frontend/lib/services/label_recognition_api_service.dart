import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:simcap/services/api_config.dart';

class LabelRecognitionResult {
  final String ocrText;
  final StructuredLabel structured;
  final SupplementMatch? match;
  final double? yoloConfidence;

  const LabelRecognitionResult({
    required this.ocrText,
    required this.structured,
    required this.match,
    required this.yoloConfidence,
  });

  factory LabelRecognitionResult.fromJson(Map<String, dynamic> json) {
    final matchJson = json['match'] as Map<String, dynamic>?;
    final data = matchJson?['data'] as Map<String, dynamic>?;
    final yolo = json['yolo'] as Map<String, dynamic>?;

    return LabelRecognitionResult(
      ocrText: json['ocrText'] as String? ?? '',
      structured: StructuredLabel.fromJson(
        json['structured'] as Map<String, dynamic>? ??
            const <String, dynamic>{},
      ),
      match: data == null ? null : SupplementMatch.fromJson(data, matchJson),
      yoloConfidence: (yolo?['confidence'] as num?)?.toDouble(),
    );
  }
}

class StructuredLabel {
  final String productName;
  final String brandName;
  final List<StructuredNutrient> nutrients;

  const StructuredLabel({
    required this.productName,
    required this.brandName,
    required this.nutrients,
  });

  factory StructuredLabel.fromJson(Map<String, dynamic> json) {
    return StructuredLabel(
      productName: json['productName'] as String? ?? '',
      brandName: json['brandName'] as String? ?? '',
      nutrients: (json['nutrients'] as List<dynamic>? ?? const [])
          .map((item) => StructuredNutrient.fromJson(item))
          .toList(),
    );
  }
}

class StructuredNutrient {
  final String name;
  final double? amount;
  final String unit;

  const StructuredNutrient({
    required this.name,
    required this.amount,
    required this.unit,
  });

  factory StructuredNutrient.fromJson(dynamic json) {
    final data = json is Map<String, dynamic>
        ? json
        : const <String, dynamic>{};
    return StructuredNutrient(
      name: data['name'] as String? ?? '',
      amount: (data['amount'] as num?)?.toDouble(),
      unit: data['unit'] as String? ?? '',
    );
  }
}

class SupplementMatch {
  final String id;
  final String productName;
  final String brandName;
  final String? imageUrl;
  final int? price;
  final double confidence;
  final List<MatchedIngredient> ingredients;

  const SupplementMatch({
    required this.id,
    required this.productName,
    required this.brandName,
    required this.imageUrl,
    required this.price,
    required this.confidence,
    required this.ingredients,
  });

  factory SupplementMatch.fromJson(
    Map<String, dynamic> json,
    Map<String, dynamic>? matchJson,
  ) {
    final rawIngredients = json['supplements_ingredients'] ?? json['ingredients'];
    return SupplementMatch(
      id: json['id']?.toString() ?? '',
      productName: json['product_name'] as String? ?? '',
      brandName: json['brand_name'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      price: int.tryParse(json['price']?.toString() ?? ''),
      confidence: (matchJson?['confidence'] as num?)?.toDouble() ?? 0,
      ingredients: (rawIngredients as List<dynamic>? ?? const [])
          .map((item) => MatchedIngredient.fromJson(item))
          .toList(),
    );
  }
}

class MatchedIngredient {
  final String name;
  final double? amount;
  final String unit;

  const MatchedIngredient({
    required this.name,
    required this.amount,
    required this.unit,
  });

  factory MatchedIngredient.fromJson(dynamic json) {
    if (json is String) {
      return MatchedIngredient(
        name: json,
        amount: null,
        unit: '',
      );
    }
    final data = json is Map<String, dynamic>
        ? json
        : const <String, dynamic>{};
    return MatchedIngredient(
      name: (data['ingredient_name'] ?? data['name'] ?? '').toString(),
      amount: (data['amount'] as num?)?.toDouble() ?? (data['value'] as num?)?.toDouble(),
      unit: (data['unit'] ?? '').toString(),
    );
  }
}

class LabelRecognitionApiService {
  Future<LabelRecognitionResult> analyze(File imageFile) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.baseUrl}/label-recognition/analyze'),
    );
    request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('라벨 인식 실패: ${response.body}');
    }

    return LabelRecognitionResult.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
}
