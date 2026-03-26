import 'package:flutter/material.dart';
import 'package:simcap/features/cabinet/widgets/supplement_card.dart';
import 'package:simcap/features/cabinet/domain/dataModels/supplement_model.dart';
import 'package:go_router/go_router.dart';

class CabinetScreen extends StatefulWidget {
  const CabinetScreen({super.key});

  @override
  State<CabinetScreen> createState() => _CabinetScreenState();
}

class _CabinetScreenState extends State<CabinetScreen> {
  List<Supplement> _mySupplements = [
    Supplement(
      name: '비타민D 제품',
      brand: '브랜드 1',
      remaining: 60,
      total: 90,
      analysisGuide: '지용성 비타민이므로 식후에 복용하면 흡수율이 더 높습니다.',
      nutrients: [
        Nutrient(name: '비타민 D', value: 1000, unit: 'IU', percent: 0.8),
      ],
    ),
    Supplement(
      name: '오메가3 제품',
      brand: '브랜드 2',
      remaining: 15,
      total: 60,
      analysisGuide: '특유의 비린내를 방지하려면 찬물과 함께 복용하세요.',
      nutrients: [
        Nutrient(name: 'EPA+DHA', value: 1200, unit: 'mg', percent: 0.95),
        Nutrient(name: '비타민 E', value: 15, unit: 'mg', percent: 0.4),
      ],
    ),
    Supplement(
      name: '마그네슘 제품',
      brand: '브랜드 3',
      remaining: 3,
      total: 30,
      analysisGuide: '취침 전 복용 시 근육 이완과 숙면에 도움을 줄 수 있습니다.',
      nutrients: [Nutrient(name: '마그네슘', value: 400, unit: 'mg', percent: 1.1)],
    ),
  ];

  Future<void> _navigateAndAddSupplement() async {
    final Supplement? newSupplement = await context.push<Supplement>(
      '/cabinet/add',
    );

    if (newSupplement != null) {
      setState(() {
        _mySupplements.add(newSupplement);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${newSupplement.name}이(가) 등록되었습니다!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          '내 영양제 캐비닛',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black87),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSummaryCard(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _mySupplements.length,
              itemBuilder: (context, index) {
                final item = _mySupplements[index];
                return SupplementCard(item: item);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 70),
        child: FloatingActionButton.extended(
          // ✅ 수정된 네비게이션 함수 연결
          onPressed: _navigateAndAddSupplement,
          label: const Text('영양제 추가'),
          icon: const Icon(Icons.add),
          backgroundColor: const Color(0xFF4CAF50),
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF4CAF50),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4CAF50).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '현재 복용 중',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            '${_mySupplements.length}개의 영양제',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
