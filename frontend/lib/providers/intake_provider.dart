import 'package:flutter/foundation.dart';
import '../models/check_safety_response.dart';
import '../services/intake_api_service.dart';

class IntakeProvider extends ChangeNotifier {
  final IntakeApiService _apiService = IntakeApiService();

  CheckSafetyResponse? _response;
  bool _isLoading = false;
  String? _error;

  CheckSafetyResponse? get response => _response;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> checkSafety({
    required List<int> supplementIds,
    required int age,
    required String gender,
    String? accessToken,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _response = await _apiService.checkSafety(
        supplementIds: supplementIds,
        age: age,
        gender: gender,
        accessToken: accessToken,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearResult() {
    _response = null;
    _error = null;
    notifyListeners();
  }
}