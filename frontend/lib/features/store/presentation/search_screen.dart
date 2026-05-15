import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:simcap/core/constant/app_constants.dart';
import 'package:simcap/features/store/data/store_product_data.dart';
import 'package:simcap/features/store/presentation/supplement_detail_screen.dart';

// 필터 데이터
class _FilterOption {
  final String label;
  const _FilterOption(this.label);
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
  /// 외부에서 진입 시 초기 검색어 설정 (선물 카테고리 탭 등)
  final String initialKeyword;

  const SearchScreen({super.key, this.initialKeyword = ''});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';

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

  int get _activeFilterCount =>
      _selectedCategories.length +
      _selectedIngredients.length +
      (_selectedPriceRange != null ? 1 : 0);

  @override
  void initState() {
    super.initState();
    // 초기 검색어가 있으면 진입 즉시 검색 상태로 설정
    if (widget.initialKeyword.isNotEmpty) {
      _searchController.text = widget.initialKeyword;
      _isSearching = true;
      _searchQuery = widget.initialKeyword;
    }
    _searchController.addListener(() {
      final searching = _searchController.text.isNotEmpty;
      if (searching != _isSearching) {
        setState(() => _isSearching = searching);
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
            child: _isSearching ? _buildSearchResults() : _buildDiscoveryView(),
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
          suffixIcon: _activeFilterCount > 0
              ? Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Chip(
                    label: Text(
                      '필터 $_activeFilterCount',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor: AppColors.primaryLight,
                    side: BorderSide.none,
                    padding: EdgeInsets.zero,
                    deleteIcon: const Icon(
                      Icons.close,
                      size: 13,
                      color: AppColors.primary,
                    ),
                    onDeleted: _clearAllFilters,
                  ),
                )
              : null,
        ),
        onChanged: (v) => setState(() => _searchQuery = v),
        onSubmitted: _submitSearch,
      ),
      actions: [
        if (_searchController.text.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.close, color: Colors.grey),
            onPressed: () => setState(() {
              _searchController.clear();
              _searchQuery = '';
            }),
          ),
      ],
    );
  }

  // 필터 패널
  Widget _buildFilterPanel() {
    return Container(
      color: AppColors.scaffoldBg,
      child: Column(
        children: [
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
          _buildFilterRow(
            label: '가격대',
            options: _priceRanges,
            selected: _selectedPriceRange != null ? {_selectedPriceRange!} : {},
            onTap: (label) => setState(() {
              _selectedPriceRange = _selectedPriceRange == label ? null : label;
            }),
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
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
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
                          color: isSelected ? AppColors.primary : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
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

  // 상품 카드
  Widget _buildSearchResults() {
    // 이름·브랜드·성분 기준 필터링
    final results = filterByKeyword(_searchQuery);

    // 활성 필터 헤더 (필터 선택 시 표시)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 결과 카운트 + 활성 필터 칩 행
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Text(
                '총 ${results.length}개',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 8),
              // 활성 필터 칩
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children:
                        [
                              ..._selectedCategories,
                              ..._selectedIngredients,
                              if (_selectedPriceRange != null)
                                _selectedPriceRange!,
                            ]
                            .map(
                              (f) => Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: GestureDetector(
                                  onTap: () => setState(() {
                                    _selectedCategories.remove(f);
                                    _selectedIngredients.remove(f);
                                    if (_selectedPriceRange == f) {
                                      _selectedPriceRange = null;
                                    }
                                  }),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryLight,
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          f,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(
                                          Icons.close,
                                          size: 11,
                                          color: AppColors.primary,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // 결과 목록
        Expanded(
          child: results.isEmpty
              ? _buildEmptyResult()
              : NotificationListener<ScrollStartNotification>(
                  onNotification: (_) {
                    FocusScope.of(context).unfocus();
                    return false;
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: results.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 80),
                    itemBuilder: (context, index) =>
                        _buildProductCard(results[index]),
                  ),
                ),
        ),
      ],
    );
  }

  // 상품 카드
  Widget _buildProductCard(StoreProduct product) {
    return InkWell(
      onTap: () => context.push('/store/detail', extra: product),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // 상품 이미지
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.primaryFaint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.medication_rounded,
                color: AppColors.primary,
                size: 30,
              ),
            ),
            const SizedBox(width: 14),
            // 상품 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.brand,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 2),
                  // 검색어 하이라이트
                  _buildHighlightedText(product.name, _searchQuery),
                  const SizedBox(height: 4),
                  // 성분 태그 (최대 3개)
                  if (product.nutrients.isNotEmpty)
                    Wrap(
                      spacing: 4,
                      children: product.nutrients
                          .take(3)
                          .map(
                            (n) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.scaffoldBg,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Text(
                                n.name,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                ],
              ),
            ),
            // 가격
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${_formatPrice(product.price)}원',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: Colors.grey,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 검색어 하이라이트 텍스트
  Widget _buildHighlightedText(String text, String query) {
    if (query.isEmpty) {
      return Text(
        text,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    final lower = text.toLowerCase();
    final queryLow = query.toLowerCase();
    final matchIdx = lower.indexOf(queryLow);

    if (matchIdx == -1) {
      return Text(
        text,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
        children: [
          // 매칭 앞 부분
          if (matchIdx > 0) TextSpan(text: text.substring(0, matchIdx)),
          // 하이라이트 구간
          TextSpan(
            text: text.substring(matchIdx, matchIdx + query.length),
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              backgroundColor: AppColors.primaryLight,
            ),
          ),
          // 매칭 뒤 부분
          if (matchIdx + query.length < text.length)
            TextSpan(text: text.substring(matchIdx + query.length)),
        ],
      ),
    );
  }

  // 검색 결과 없음
  Widget _buildEmptyResult() {
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
          const SizedBox(height: 8),
          Text(
            '다른 검색어를 입력하거나\n필터를 조정해보세요',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey[400]),
          ),
          if (_activeFilterCount > 0) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _clearAllFilters,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              icon: const Icon(
                Icons.filter_alt_off_outlined,
                size: 16,
                color: AppColors.primary,
              ),
              label: const Text(
                '필터 초기화',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }

  // 검색어 없을 때 (최근 · 인기 검색어)
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
                    color: AppColors.primary,
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
