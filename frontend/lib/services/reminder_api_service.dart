import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:simcap/core/constant/app_constants.dart';

class ReminderApiService {
  Future<ReminderData> fetchTodayReminders({required String userUuid}) async {
    final response = await http.get(
      Uri.parse('${AppConstants.apiBaseUrl}/reminders/today/$userUuid'),
      headers: AppConstants.headers,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('리마인더 조회 실패: ${response.body}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final data = decoded['data'];

    if (data is! Map<String, dynamic>) {
      throw Exception('리마인더 응답 형식 오류: ${response.body}');
    }

    return ReminderData.fromJson(data);
  }
}

class ReminderData {
  final List<DoseReminder> doseReminders;
  final List<StockReminder> stockReminders;

  ReminderData({required this.doseReminders, required this.stockReminders});

  int get totalCount => doseReminders.length + stockReminders.length;

  bool get isEmpty => doseReminders.isEmpty && stockReminders.isEmpty;

  factory ReminderData.fromJson(Map<String, dynamic> json) {
    final doseList = json['doseReminders'] as List<dynamic>? ?? [];
    final stockList = json['stockReminders'] as List<dynamic>? ?? [];

    return ReminderData(
      doseReminders: doseList
          .map((e) => DoseReminder.fromJson(e as Map<String, dynamic>))
          .toList(),
      stockReminders: stockList
          .map((e) => StockReminder.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class DoseReminder {
  final String inventoryId;
  final String supplementId;
  final String supplementName;
  final String? brandName;
  final String? imageUrl;
  final int doseIndex;
  final String supplementTime;
  final String date;
  final bool isTaken;
  final String status;

  DoseReminder({
    required this.inventoryId,
    required this.supplementId,
    required this.supplementName,
    required this.brandName,
    required this.imageUrl,
    required this.doseIndex,
    required this.supplementTime,
    required this.date,
    required this.isTaken,
    required this.status,
  });

  factory DoseReminder.fromJson(Map<String, dynamic> json) {
    return DoseReminder(
      inventoryId: json['inventoryId']?.toString() ?? '',
      supplementId: json['supplementId']?.toString() ?? '',
      supplementName: json['supplementName']?.toString() ?? '',
      brandName: json['brandName']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      doseIndex: int.tryParse(json['doseIndex']?.toString() ?? '') ?? 0,
      supplementTime: json['supplementTime']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      isTaken: json['isTaken'] == true,
      status: json['status']?.toString() ?? 'UPCOMING',
    );
  }
}

class StockReminder {
  final String inventoryId;
  final String supplementId;
  final String supplementName;
  final String? brandName;
  final String? imageUrl;
  final int stockCount;
  final int totalCount;
  final int dailyDose;
  final int dailyFrequency;
  final int? daysLeft;
  final String status;

  StockReminder({
    required this.inventoryId,
    required this.supplementId,
    required this.supplementName,
    required this.brandName,
    required this.imageUrl,
    required this.stockCount,
    required this.totalCount,
    required this.dailyDose,
    required this.dailyFrequency,
    required this.daysLeft,
    required this.status,
  });

  factory StockReminder.fromJson(Map<String, dynamic> json) {
    return StockReminder(
      inventoryId: json['inventoryId']?.toString() ?? '',
      supplementId: json['supplementId']?.toString() ?? '',
      supplementName: json['supplementName']?.toString() ?? '',
      brandName: json['brandName']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      stockCount: int.tryParse(json['stockCount']?.toString() ?? '') ?? 0,
      totalCount: int.tryParse(json['totalCount']?.toString() ?? '') ?? 0,
      dailyDose: int.tryParse(json['dailyDose']?.toString() ?? '') ?? 1,
      dailyFrequency:
          int.tryParse(json['dailyFrequency']?.toString() ?? '') ?? 1,
      daysLeft: json['daysLeft'] == null
          ? null
          : int.tryParse(json['daysLeft'].toString()),
      status: json['status']?.toString() ?? 'LOW_STOCK',
    );
  }
}
