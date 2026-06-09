import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:simcap/core/constant/app_constants.dart';
import 'package:simcap/features/store/presentation/supplement_detail_screen.dart';
import 'package:simcap/services/store_api_service.dart';
import 'package:simcap/services/auth_service.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  List<StoreProduct> _allProducts = [];
  List<StoreProduct> _recommendedProducts = []; // 신규 추가: 맞춤 추천 영양제 리스트
  bool _isLoading = true;

  String _selectedRankCategory = '여성';
  String _selectedPriceRange = '전체';

  final PageController _pageController = PageController(initialPage: 0);
  int _currentBannerPage = 0;
  Timer? _bannerTimer;

  final List<Map<String, dynamic>> _banners = [
    {'title': '신규 브랜드 입점\n전품목 20% 할인', 'color': AppColors.primaryDark},
    {'title': '환절기 면역력 강화\n비타민D 특별전', 'color': const Color(0xFF1976D2)},
    {'title': '첫 구매 고객님께 드리는\n무료 배송 쿠폰', 'color': const Color(0xFFF57C00)},
  ];

  @override
  void initState() {
    super.initState();
    _fetchProducts();

    _bannerTimer = Timer.periodic(const Duration(milliseconds: 3500), (timer) {
      if (_currentBannerPage < _banners.length - 1) {
        _currentBannerPage++;
      } else {
        _currentBannerPage = 0;
      }

      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentBannerPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchProducts() async {
    try {
      final service = StoreApiService();

      // Supabase Auth 연동을 통한 로그인 사용자별 동적 UUID 로드 (비로그인 상태일 시 기존 하드코딩 UUID를 폴백으로 사용)
      final authService = AuthService();
      final user = authService.currentUser;
      final String currentUserId =
          user?.id ?? 'bc49b355-8ea3-4e6e-9331-52d1d4c46d99';

      // [개선된 코드] 전체 리스트와 맞춤 추천 리스트를 동시에 조회
      // 사용자 성별/나이 조회 후 전달
      final userInfo = await authService.getUserInfo();
      final int userAge = userInfo?['birth_year'] != null
          ? DateTime.now().year - (userInfo!['birth_year'] as int)
          : 30;
      final rawGender = (userInfo?['gender'] as String?)?.toLowerCase() ?? '';
      final String userGender =
          (rawGender == 'male' ||
              rawGender == '남성' ||
              rawGender == '남자' ||
              rawGender == 'm')
          ? 'male'
          : 'female';

      final results = await Future.wait([
        service.fetchSupplements(gender: userGender, age: userAge),
        service.fetchRecommendedSupplements(
          currentUserId,
        ), // 인덱스 1: 나를 위한 추천 리스트
      ]);

      setState(() {
        _allProducts = results[0];
        _recommendedProducts = results[1];
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('DB 로드 에러: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleRefresh() async {
    await _fetchProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          '스토어',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            // ✅ Navigator.pushNamed 대신 context.push 사용
            onPressed: () => context.push('/store/search'),
          ),
          IconButton(
            icon: const Icon(
              Icons.shopping_basket_outlined,
              color: Colors.black,
            ),
            onPressed: () => context.push('/store/basket'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAutoSliderBanner(),
              _buildSectionTitle('나를 위한 추천'),
              _buildRecommendList(),
              _buildSectionTitle('선물 카테고리'),
              _buildGiftCategories(),
              const SizedBox(height: 20),
              _buildSectionTitle('실시간 인기 랭킹'),
              _buildRankingFilters(),
              _buildRankingList(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildAutoSliderBanner() {
    return Column(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.width * 9 / 16,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentBannerPage = index);
            },
            itemCount: _banners.length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _banners[index]['color'],
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _banners[index]['title'],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      height: 1.4,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_banners.length, (index) {
            bool isCurrent = _currentBannerPage == index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 6,
              width: isCurrent ? 18 : 6,
              decoration: BoxDecoration(
                color: isCurrent ? AppColors.primary : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildRecommendList() {
    // [개선된 코드] 맞춤 추천 결과 사용 및 요청하신 3개 제한 적용
    final displayList = _recommendedProducts.take(3).toList();

    return SizedBox(
      height: MediaQuery.of(context).size.width * 9 / 16,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        // 세로 ScrollView와 제스처 충돌 방지 — 가로 스크롤 명시적 허용
        physics: const AlwaysScrollableScrollPhysics(),
        clipBehavior: Clip.none,
        itemCount: displayList.length,
        itemBuilder: (context, index) {
          final product = displayList[index];
          return GestureDetector(
            onTap: () => context.push('/store/detail', extra: product),
            child: Container(
              width: 140,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryFaint,
                      shape: BoxShape.circle,
                    ),
                    clipBehavior: Clip.hardEdge,
                    // 기존 코드: 아이콘 하드코딩
                    // child: const Icon(
                    //   Icons.medication_rounded,
                    //   color: AppColors.primary,
                    //   size: 28,
                    // ),
                    // API 연동 코드: 실제 이미지 렌더링
                    child:
                        product.imageUrl != null && product.imageUrl!.isNotEmpty
                        ? Image.network(
                            product.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                                  Icons.medication_rounded,
                                  color: AppColors.primary,
                                  size: 28,
                                ),
                          )
                        : const Icon(
                            Icons.medication_rounded,
                            color: AppColors.primary,
                            size: 28,
                          ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatPrice(product.price)}원',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGiftCategories() {
    // 카테고리명과 검색 키워드 및 필터 매핑
    final categories = [
      {
        'label': '부모님',
        'icon': Icons.favorite_outline,
        'extra': {
          'categories': ['관절/뼈', '오메가3'],
          'ingredients': ['비타민C'],
          'priceRange': '5만원 이상',
        },
      },
      {
        'label': '수험생',
        'icon': Icons.school_outlined,
        'extra': {
          'categories': ['눈 건강', '면역'],
          'ingredients': ['비타민C'],
          'priceRange': '3~5만원',
        },
      },
      {
        'label': '운동매니아',
        'icon': Icons.fitness_center_outlined,
        'extra': {
          'categories': ['단백질'],
          'ingredients': ['마그네슘'],
        },
      },
      {
        'label': '직장인',
        'icon': Icons.work_outline,
        'extra': {
          'categories': ['눈 건강'],
          'ingredients': ['밀크씨슬', '유산균'],
        },
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.9,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          return GestureDetector(
            onTap: () => context.push(
              '/store/search',
              extra: cat['extra'], // 필터 정보 전달
            ),
            child: Column(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primaryLight,
                  radius: 28,
                  child: Icon(
                    cat['icon'] as IconData,
                    size: 24,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  cat['label'] as String,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRankingFilters() {
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: ['여성', '남성', '주니어', '시니어'].map((cat) {
              final isSelected = _selectedRankCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(cat),
                  selected: isSelected,
                  onSelected: (val) =>
                      setState(() => _selectedRankCategory = cat),
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: ['전체', '1~3만원', '3~5만원', '5만원 이상'].map((price) {
              final isSelected = _selectedPriceRange == price;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(price, style: const TextStyle(fontSize: 12)),
                  selected: isSelected,
                  onSelected: (val) =>
                      setState(() => _selectedPriceRange = price),
                  shape: const StadiumBorder(),
                  selectedColor: AppColors.primaryLight,
                  checkmarkColor: AppColors.primary,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildRankingList() {
    // 기존 코드: var products = allProducts.where((p) {
    // API 연동 코드: _allProducts 사용
    var products = _allProducts.where((p) {
      switch (_selectedPriceRange) {
        case '1만원 이하':
          return p.price < 10000;
        case '1~3만원':
          return p.price >= 10000 && p.price < 30000;
        case '3~5만원':
          return p.price >= 30000 && p.price < 50000;
        case '5만원 이상':
          return p.price >= 50000;
        default:
          return true; // '전체'
      }
    }).toList();

    // 결과 없음
    if (products.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.search_off_rounded, size: 48, color: Colors.grey[300]),
              const SizedBox(height: 12),
              Text(
                '$_selectedPriceRange 해당 상품이 없습니다',
                style: TextStyle(fontSize: 14, color: Colors.grey[400]),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: products.length,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final product = products[index];
        final rank = index + 1;
        final rankColor = rank == 1
            ? const Color(0xFFFFB300)
            : rank == 2
            ? const Color(0xFF9E9E9E)
            : rank == 3
            ? const Color(0xFF8D6E63)
            : AppColors.primary;

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 6),
          onTap: () => context.push('/store/detail', extra: product),
          leading: SizedBox(
            width: 40,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$rank',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: rankColor,
                  ),
                ),
              ],
            ),
          ),
          title: Text(
            product.name,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '${product.brand}  ·  ${_formatPrice(product.price)}원',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
          trailing: const Icon(
            Icons.arrow_forward_ios,
            size: 14,
            color: Colors.grey,
          ),
        );
      },
    );
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }
}
