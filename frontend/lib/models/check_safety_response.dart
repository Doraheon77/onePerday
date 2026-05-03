import 'intake_result_model.dart';

class CheckSafetyResponse {
  final bool success;
  final bool hasWarning;
  final List<IntakeResultModel> results;

  CheckSafetyResponse({
    required this.success,
    required this.hasWarning,
    required this.results,
  });

  factory CheckSafetyResponse.fromJson(Map<String, dynamic> json) {
    return CheckSafetyResponse(
      success: json['success'] ?? false,
      hasWarning: json['hasWarning'] ?? false,
      results: (json['results'] as List<dynamic>? ?? [])
          .map((e) => IntakeResultModel.fromJson(e))
          .toList(),
    );
  }
}