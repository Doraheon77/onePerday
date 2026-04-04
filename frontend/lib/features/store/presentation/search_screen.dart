import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class _FilterOption {
  final String label;
  final String? icon;
  const _FilterOption(this.label, {this.icon});
}

const _categories = [
  _FilterOption('비타민'),
  _FilterOption('미네랄'),
  _FilterOption('오메가3'),
  _FilterOption('유산균'),
  _FilterOption('단백질'),
  _FilterOption('눈 건강'),
  _FilterOption('관절/뼈'),
  _FilterOption('피부'),
  _FilterOption('다이어트'),
  _FilterOption('면역'),
];

const _ingredients = [
  _FilterOption('비타민C'),
  _FilterOption('비타민D'),
  _FilterOption('마그네슘'),
  _FilterOption('아연'),
  _FilterOption('루테인'),
  _FilterOption('콜라겐'),
  _FilterOption('EPA+DHA'),
  _FilterOption('유산균'),
  _FilterOption('밀크씨슬'),
  _FilterOption('엽산'),
];

const _priceRanges = [
  _FilterOption('1만원 이하'),
  _FilterOption('1~3만원'),
  _FilterOption('3~5만원'),
  _FilterOption('5만원 이상'),
];

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false; // 검색어 입력 중 여부

  // 선택된 필터 상태
  final Set<String> _selectedCategories = {};
  final Set<String> _selectedIngredients = {};
  String? _selectedPriceRange;

  // 최근 검색어
  List<String> _recentSearches = ['멀티비타민', '오메가3', '유산균', '루테인'];

  // 인기 검색어
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

  // 활성 필터 총 개수 (배지용)
  int get _activeFilterCount =>
      _selectedCategories.length +
      _selectedIngredients.length +
      (_selectedPriceRange != null ? 1 : 0);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final isSearching = _searchController.text.isNotEmpty;
      if (isSearching != _isSearching) {
        setState(() => _isSearching = isSearching);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearAllFilters() {
    setState(() {
      _selectedCategories.clear();
      _selectedIngredients.clear();
      _selectedPriceRange = null;
    });
  }

  void _submitSearch(String query) {
    if (query.trim().isEmpty) return;
    if (!_recentSearches.contains(query.trim())) {
      setState(() {
        _recentSearches.insert(0, query.trim());
        if (_recentSearches.length > 8) _recentSearches.removeLast();
      });
    }
    // TODO: 실제 검색 API 호출
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          const Divider(height: 1),
          // 검색어 있을 때만 필터 패널 표시
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            child: _isSearching ? _buildFilterPanel() : const SizedBox.shrink(),
          ),
          Expanded(
            child: _isSearching
                ? _buildSearchResultPlaceholder()
                : _buildDiscoveryView(),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => context.pop(),
      ),
      title: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: InputDecoration(
          hintText: '영양제나 브랜드를 검색해 보세요',
          hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
          border: InputBorder.none,
          // 활성 필터 개수 배지
          suffixIcon: _activeFilterCount > 0
              ? Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Chip(
                    label: Text(
                      '필터 $_activeFilterCount',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF4CAF50),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor: const Color(0xFFE8F5E9),
                    side: BorderSide.none,
                    padding: EdgeInsets.zero,
                    deleteIcon: const Icon(
                      Icons.close,
                      size: 13,
                      color: Color(0xFF4CAF50),
                    ),
                    onDeleted: _clearAllFilters,
                  ),
                )
              : null,
        ),
        onSubmitted: _submitSearch,
      ),
      actions: [
        if (_searchController.text.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.close, color: Colors.grey),
            onPressed: () => setState(() => _searchController.clear()),
          ),
      ],
    );
  }

  // 필터 패널 (검색어 입력 시 표시)
  Widget _buildFilterPanel() {
    return Container(
      color: const Color(0xFFF9FAFB),
      child: Column(
        children: [
          // 카테고리
          _buildFilterRow(
            label: '카테고리',
            options: _categories,
            selected: _selectedCategories,
            onTap: (label) => setState(() {
              _selectedCategories.contains(label)
                  ? _selectedCategories.remove(label)
                  : _selectedCategories.add(label);
            }),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          // 주요 성분
          _buildFilterRow(
            label: '주요 성분',
            options: _ingredients,
            selected: _selectedIngredients,
            onTap: (label) => setState(() {
              _selectedIngredients.contains(label)
                  ? _selectedIngredients.remove(label)
                  : _selectedIngredients.add(label);
            }),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          // 가격대 (단일 선택)
          _buildFilterRow(
            label: '가격대',
            options: _priceRanges,
            selected: _selectedPriceRange != null ? {_selectedPriceRange!} : {},
            onTap: (label) => setState(() {
              _selectedPriceRange = _selectedPriceRange == label ? null : label;
            }),
            singleSelect: true,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow({
    required String label,
    required List<_FilterOption> options,
    required Set<String> selected,
    required void Function(String) onTap,
    bool singleSelect = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 라벨
          SizedBox(
            width: 64,
            child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
            ),
          ),
          // 칩 스크롤
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(right: 16),
              child: Row(
                children: options.map((opt) {
                  final isSelected = selected.contains(opt.label);
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () => onTap(opt.label),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF4CAF50)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF4CAF50)
                                : Colors.grey.shade300,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Text(
                          opt.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 검색 결과 자리 (백엔드 연동 전 플레이스홀더)
  Widget _buildSearchResultPlaceholder() {
    final bool hasFilters = _activeFilterCount > 0;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 56, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            '"${_searchController.text}" 검색',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          if (hasFilters) ...[
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              runSpacing: 4,
              children:
                  [
                        ..._selectedCategories,
                        ..._selectedIngredients,
                        if (_selectedPriceRange != null) _selectedPriceRange!,
                      ]
                      .map(
                        (f) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            f,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF4CAF50),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                      .toList(),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            '검색 결과는 백엔드 연동 후 표시됩니다',
            style: TextStyle(fontSize: 13, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  // 검색어 없을 때 - 최근 · 인기 검색어
  Widget _buildDiscoveryView() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_recentSearches.isNotEmpty) ...[
            _buildSectionHeader('최근 검색어', isClearAll: true),
            _buildRecentSearchChips(),
          ],
          const SizedBox(height: 16),
          _buildSectionHeader('실시간 인기 검색어', isClearAll: false),
          _buildPopularSearchList(),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

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

  Widget _buildRecentSearchChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: _recentSearches.map((keyword) {
          return GestureDetector(
            onTap: () {
              _searchController.text = keyword;
              _submitSearch(keyword);
            },
            child: Chip(
              label: Text(keyword, style: const TextStyle(fontSize: 13)),
              backgroundColor: Colors.grey.shade100,
              side: BorderSide.none,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              onDeleted: () => setState(() => _recentSearches.remove(keyword)),
              deleteIcon: const Icon(Icons.close, size: 14),
            ),
          );
        }).toList(),
      ),
    );
  }

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
              _submitSearch(_popularSearches[index]);
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
