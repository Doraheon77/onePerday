import 'package:flutter/material.dart';
import 'package:simcap/core/constant/app_constants.dart';
import 'package:simcap/features/cabinet/widgets/supplement_card.dart';
import 'package:simcap/features/cabinet/domain/dataModels/supplement_model.dart';
import 'package:simcap/providers/supplement_provider.dart';
import 'package:go_router/go_router.dart';

class CabinetScreen extends StatefulWidget {
  const CabinetScreen({super.key});

  @override
  State<CabinetScreen> createState() => _CabinetScreenState();
}

class _CabinetScreenState extends State<CabinetScreen> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 검색 모드 진입
  void _startSearch() {
    setState(() => _isSearching = true);
  }

  // 검색 모드 종료 + 초기화
  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  // 이름 또는 브랜드 기준 필터링
  List<Supplement> _filtered(List<Supplement> all) {
    if (_searchQuery.isEmpty) return all;
    final q = _searchQuery.toLowerCase();
    return all
        .where(
          (s) =>
              s.name.toLowerCase().contains(q) ||
              s.brand.toLowerCase().contains(q),
        )
        .toList();
  }

  Future<void> _navigateAndAddSupplement() async {
    final notifier = SupplementProvider.of(context);
    final Supplement? newSupplement = await context.push<Supplement>(
      '/cabinet/add',
    );

    if (newSupplement != null) {
      notifier.addSupplement(newSupplement);
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
      backgroundColor: AppColors.scaffoldBg,
      appBar: _isSearching ? _buildSearchAppBar() : _buildNormalAppBar(),
      body: Column(
        children: [
          // 검색 중이 아닐 때만 요약 카드 표시
          if (!_isSearching) _buildSummaryCard(),
          Expanded(
            child: Builder(
              builder: (context) {
                final all = SupplementProvider.of(context).supplements;
                final filtered = _filtered(all);
                return _buildList(filtered, all.length);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateAndAddSupplement,
        label: const Text('영양제 추가'),
        icon: const Icon(Icons.add),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  PreferredSizeWidget _buildNormalAppBar() {
    return AppBar(
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
          onPressed: _startSearch,
        ),
      ],
    );
  }

  // 검색바
  PreferredSizeWidget _buildSearchAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black87),
        onPressed: _stopSearch,
      ),
      title: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: InputDecoration(
          hintText: '영양제 이름 또는 브랜드 검색',
          hintStyle: TextStyle(fontSize: 14, color: Colors.grey[400]),
          border: InputBorder.none,
          // 입력값 있을 때 X 버튼
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                  onPressed: () => setState(() {
                    _searchController.clear();
                    _searchQuery = '';
                  }),
                )
              : null,
        ),
        onChanged: (v) => setState(() => _searchQuery = v),
      ),
    );
  }

  // 영양제 목록
  Widget _buildList(List<Supplement> filtered, int totalCount) {
    // 검색 결과 없음
    if (_isSearching && filtered.isEmpty) {
      return _buildEmptySearchResult();
    }

    // 등록된 영양제 없음
    if (totalCount == 0) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: filtered.length,
      itemBuilder: (context, index) => SupplementCard(item: filtered[index]),
    );
  }

  // 빈 상태 — 영양제 미등록
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.medication_outlined, size: 56, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            '등록된 영양제가 없습니다',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '아래 버튼으로 영양제를 추가해보세요',
            style: TextStyle(fontSize: 13, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  // 빈 상태 — 검색 결과 없음
  Widget _buildEmptySearchResult() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 56, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            '"$_searchQuery" 검색 결과 없음',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '영양제 이름 또는 브랜드를 확인해주세요',
            style: TextStyle(fontSize: 13, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final count = SupplementProvider.of(context).supplements.length;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
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
            '$count개의 영양제',
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
