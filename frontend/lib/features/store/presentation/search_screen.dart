import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  // 샘플 데이터: 최근 검색어
  List<String> _recentSearches = ['멀티비타민', '오메가3', '유산균', '루테인'];

  // 샘플 데이터: 인기 검색어
  final List<String> _popularSearches = [
    '비타민D 5000IU',
    '마그네슘 영양제',
    '다이어트 보조제',
    '밀크씨슬',
    '탈모 방지 비오틴',
    '임산부 엽산',
    '어린이 젤리 비타민',
    '남성용 활력제',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '영양제나 브랜드를 검색해 보세요',
            hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
            border: InputBorder.none,
          ),
          onSubmitted: (value) {
            // 검색 실행 로직 (필요 시 구현)
          },
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.grey),
              onPressed: () => setState(() => _searchController.clear()),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(height: 1),

            // --- 최근 검색어 섹션 ---
            if (_recentSearches.isNotEmpty) ...[
              _buildSectionHeader('최근 검색어', isClearAll: true),
              _buildRecentSearchChips(),
            ],

            const SizedBox(height: 16),

            // --- 인기 검색어 섹션 ---
            _buildSectionHeader('실시간 인기 검색어', isClearAll: false),
            _buildPopularSearchList(),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // 섹션 헤더 (제목 + 전체삭제 버튼)
  Widget _buildSectionHeader(String title, {required bool isClearAll}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          if (isClearAll)
            GestureDetector(
              onTap: () => setState(() => _recentSearches.clear()),
              child: const Text(
                '전체 삭제',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }

  // 최근 검색어 칩 리스트
  Widget _buildRecentSearchChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: _recentSearches.map((keyword) {
          return Chip(
            label: Text(keyword, style: const TextStyle(fontSize: 13)),
            backgroundColor: Colors.grey.shade100,
            side: BorderSide.none,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            onDeleted: () {
              setState(() => _recentSearches.remove(keyword));
            },
            deleteIcon: const Icon(Icons.close, size: 14),
          );
        }).toList(),
      ),
    );
  }

  // 인기 검색어 순위 리스트 (2열 배치)
  Widget _buildPopularSearchList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 20,
          childAspectRatio: 4,
        ),
        itemCount: _popularSearches.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              _searchController.text = _popularSearches[index];
            },
            child: Row(
              children: [
                Text(
                  '${index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4CAF50),
                    fontSize: 15,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _popularSearches[index],
                    style: const TextStyle(
                      fontSize: 14,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
