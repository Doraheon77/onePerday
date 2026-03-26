import 'dart:io';
import 'package:flutter/material.dart';
import 'package:simcap/features/cabinet/domain/dataModels/supplement_model.dart';

class CabinetDetailScreen extends StatelessWidget {
  final Supplement item;

  const CabinetDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '상세 정보',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 헤더 영역
            _buildProductHeader(),
            const Divider(height: 1, thickness: 8, color: Color(0xFFF5F5F5)),

            // 복용 상태 정보
            _buildStatusSection(),
            const Divider(height: 1, thickness: 8, color: Color(0xFFF5F5F5)),

            // 성분 및 함량 분석
            _buildNutrientAnalysisSection(),
            const Divider(height: 1, thickness: 8, color: Color(0xFFF5F5F5)),

            // AI 리뷰 요약
            _buildAIReviewSummary(),
          ],
        ),
      ),
      bottomNavigationBar: _buildActionButtons(context),
    );
  }

  Widget _buildProductHeader() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F8E9),
              borderRadius: BorderRadius.circular(20),
            ),
            // ✅ 이미지 유무에 따른 분기 처리
            child: (item.imagePath != null && item.imagePath!.isNotEmpty)
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.file(
                      File(item.imagePath!),
                      fit: BoxFit.cover,
                      // 이미지 로드 에러 시 기본 아이콘 표시
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.medication_rounded,
                        size: 45,
                        color: Color(0xFF4CAF50),
                      ),
                    ),
                  )
                : const Icon(
                    Icons.medication_rounded,
                    size: 45,
                    color: Color(0xFF4CAF50),
                  ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.brand.isEmpty ? '브랜드 정보 없음' : item.brand,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  item.name.isEmpty ? '제품명 없음' : item.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '복용 현황',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.inventory_2_outlined,
            '남은 수량',
            '${item.remaining}정',
          ),
          _buildInfoRow(
            Icons.calendar_month_outlined,
            '전체 용량',
            '${item.total}정',
          ),
          _buildInfoRow(
            Icons.notifications_active_outlined,
            '알림 설정',
            '오전 09:00',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[400]),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Colors.black54)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildNutrientAnalysisSection() {
    final List<Nutrient> nutrients = item.nutrients;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '성분 및 함량 분석',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          if (nutrients.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text('등록된 성분 정보가 없습니다.'),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: nutrients.length,
              itemBuilder: (context, index) {
                return _buildNutrientBar(nutrients[index]);
              },
            ),
          const SizedBox(height: 12),
          _buildAnalysisGuide(),
        ],
      ),
    );
  }

  Widget _buildNutrientBar(Nutrient n) {
    Color barColor = const Color(0xFF4CAF50);
    if (n.percent >= 1.0) {
      barColor = const Color(0xFFFF6B6B);
    } else if (n.percent < 0.3) {
      barColor = const Color(0xFFFFC107);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    n.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${n.value.toInt()}${n.unit}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
              Text(
                '하루 기준치 ${(n.percent * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: barColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Stack(
            children: [
              Container(
                height: 10,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              FractionallySizedBox(
                widthFactor: n.percent.clamp(0.0, 1.0),
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisGuide() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8E9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.lightbulb_outline,
            size: 16,
            color: Color(0xFF4CAF50),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              item.analysisGuide.isEmpty
                  ? '이 영양제는 정해진 시간에 꾸준히 복용하는 것이 좋습니다.'
                  : item.analysisGuide,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF2E7D32),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIReviewSummary() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text(
                'AI 리뷰 분석 요약',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Spacer(),
              Icon(Icons.auto_awesome, size: 16, color: Colors.blueAccent),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              item.aiSummary.isEmpty ? '아직 분석된 리뷰 데이터가 없습니다.' : item.aiSummary,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      decoration: const BoxDecoration(color: Colors.white),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Color(0xFF4CAF50), width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                '리뷰 작성하기',
                style: TextStyle(
                  color: Color(0xFF4CAF50),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                '구매처 이동',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
