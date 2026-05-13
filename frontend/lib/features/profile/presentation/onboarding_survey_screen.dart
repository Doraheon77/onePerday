import 'package:flutter/material.dart';
import 'package:simcap/core/constant/app_constants.dart';
import 'package:simcap/features/store/data/store_product_data.dart';
import 'package:simcap/features/store/presentation/supplement_detail_screen.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/survey_chip_group.dart';
import '../data/survey_data.dart';

class OnboardingSurveyScreen extends StatefulWidget {
  const OnboardingSurveyScreen({super.key});

  @override
  State<OnboardingSurveyScreen> createState() => _OnboardingSurveyScreenState();
}

class _OnboardingSurveyScreenState extends State<OnboardingSurveyScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();

  int _currentPage = 0;
  String _searchQuery = "";

  String? userName;
  String? userAge;
  String? userGender;
  List<String> selectedGoals = [];
  List<String> selectedHealth = [];
  List<String> selectedAllergies = [];
  String? smokingStatus;
  String? drinkingStatus;
  String? pregnancyStatus;

  @override
  void dispose() {
    _pageController.dispose();
    _searchController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _saveSurveyData() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('userName', userName ?? '');
    await prefs.setString('userAge', userAge ?? '');
    await prefs.setString('userGender', userGender ?? '');
    await prefs.setStringList('selectedGoals', selectedGoals);
    await prefs.setStringList('selectedHealth', selectedHealth);
    await prefs.setStringList('selectedAllergies', selectedAllergies);
    await prefs.setString('smokingStatus', smokingStatus ?? '비흡연자입니다');
    await prefs.setString('drinkingStatus', drinkingStatus ?? '비음주자입니다');

    String finalPregnancy = (userGender == '남성')
        ? '해당 없음'
        : (pregnancyStatus ?? '미선택');
    await prefs.setString('pregnancyStatus', finalPregnancy);

    await prefs.setBool('isOnboardingComplete', true);
  }

  void _onItemToggled(
    String val,
    bool isSelected,
    List<String> targetList,
    String noneOption,
  ) {
    setState(() {
      if (val == noneOption) {
        if (isSelected) {
          targetList.clear();
          targetList.add(noneOption);
        } else {
          targetList.remove(noneOption);
        }
      } else {
        targetList.remove(noneOption);
        isSelected ? targetList.add(val) : targetList.remove(val);
      }
    });
  }

  void _nextPage() {
    _searchController.clear();
    setState(() => _searchQuery = "");
    if (_currentPage < 5) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      // 온보딩 완료 → 추천 화면 먼저 표시
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        isDismissible: false,
        builder: (_) => _RecommendSheet(
          goals: selectedGoals,
          onStart: () {
            Navigator.pop(context);
            context.go('/home');
          },
        ),
      );
    }
  }

  void _goToStep(int stepIndex) {
    Navigator.pop(context);
    _pageController.animateToPage(
      stepIndex,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutQuart,
    );
  }

  List<SurveyOption> _getFilteredOptions(
    List<SurveyOption> options, {
    String? noneOption,
  }) {
    final filtered = options
        .where((opt) => opt.label.contains(_searchQuery))
        .toList();

    if (noneOption != null) {
      return [
        SurveyOption(label: noneOption, imagePath: 'assets/images/none.png'),
        ...filtered,
      ];
    }
    return filtered;
  }

  void _showSummaryModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        final bottomPad = MediaQuery.of(context).padding.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            32,
            24,
            bottomPad > 0 ? bottomPad + 16 : 40,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '입력하신 정보를 확인해주세요',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              _buildSummaryRow(
                '기본 정보',
                '${userName ?? "이름 없음"} / ${userAge ?? "0"}세 / ${userGender ?? "미선택"}',
                0,
              ),
              _buildSummaryRow(
                '복용 목적',
                selectedGoals.isEmpty ? '없음' : selectedGoals.join(', '),
                1,
              ),
              _buildSummaryRow(
                '보유 질환',
                selectedHealth.isEmpty ? '질환 없음' : selectedHealth.join(', '),
                2,
              ),
              _buildSummaryRow(
                '알레르기',
                selectedAllergies.isEmpty
                    ? '알레르기 없음'
                    : selectedAllergies.join(', '),
                3,
              ),
              _buildSummaryRow('흡연 여부', smokingStatus ?? '미선택', 4),

              _buildSummaryRow('음주 여부', drinkingStatus ?? '미선택', 4),
              if (userGender == '여성')
                _buildSummaryRow('임신 여부', pregnancyStatus ?? '미선택', 4),
              const SizedBox(height: 40),
              _buildFullWidthButton('네, 맞아요! 분석 시작하기', () async {
                await _saveSurveyData();
                if (!mounted) return;
                Navigator.pop(context);
                _nextPage();
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryRow(String title, String content, int stepIndex) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _goToStep(stepIndex),
            style: TextButton.styleFrom(
              backgroundColor: Colors.grey.shade100,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              '수정',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: (_currentPage > 0 && _currentPage < 5)
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  size: 20,
                  color: Colors.black,
                ),
                onPressed: () => _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.ease,
                ),
              )
            : null,
      ),
      body: Column(
        children: [
          _buildProgressBar(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (idx) => setState(() => _currentPage = idx),
              children: [
                _buildBasicInfoStep(),
                _buildGoalStep(),
                _buildHealthStep(),
                _buildAllergyStep(),
                _buildLifestyleStep(),
                _buildCompletionStep(),
              ],
            ),
          ),
          _buildBottomButton(),
        ],
      ),
    );
  }

  Widget _buildBasicInfoStep() {
    return _surveyLayout(
      title: '정확한 분석을 위해\n기본 정보를 알려주세요.',
      subtitle: '이름과 나이, 성별에 따라 권장량이 달라집니다.',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameController,
            onChanged: (val) => setState(() => userName = val),
            decoration: InputDecoration(
              labelText: '이름 (또는 닉네임)',
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _ageController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(3),
            ],
            onChanged: (val) => setState(() => userAge = val),
            decoration: InputDecoration(
              labelText: '나이 (세)',
              hintText: '숫자만 입력해주세요',
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            "성별",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SurveyChipGroup(
            options: [
              SurveyOption(label: '남성', imagePath: 'assets/images/male.png'),
              SurveyOption(label: '여성', imagePath: 'assets/images/female.png'),
            ],
            selectedValues: userGender != null ? [userGender!] : [],
            onSelected: (val, isSelected) =>
                setState(() => userGender = isSelected ? val : null),
            columns: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildGoalStep() => _surveyLayout(
    title: '어디가 고민이신가요?',
    subtitle: '고민에 맞는 영양제를 추천해 드릴게요.',
    content: Column(
      children: [
        _buildSearchField(),
        SurveyChipGroup(
          options: _getFilteredOptions(SurveyData.goals),
          selectedValues: selectedGoals,
          onSelected: (val, isSelected) => setState(
            () =>
                isSelected ? selectedGoals.add(val) : selectedGoals.remove(val),
          ),
        ),
      ],
    ),
  );

  Widget _buildHealthStep() => _surveyLayout(
    title: '현재 앓고 계신\n질환이 있으신가요?',
    subtitle: '질환에 따라 주의해야 할 성분을 알려드려요.',
    content: Column(
      children: [
        _buildSearchField(),
        SurveyChipGroup(
          options: _getFilteredOptions(
            SurveyData.healthIssues,
            noneOption: SurveyData.noneOptionHealth,
          ),
          selectedValues: selectedHealth,
          onSelected: (val, isSelected) => _onItemToggled(
            val,
            isSelected,
            selectedHealth,
            SurveyData.noneOptionHealth,
          ),
        ),
      ],
    ),
  );

  Widget _buildAllergyStep() => _surveyLayout(
    title: '특별히 조심해야 할\n알레르기가 있으신가요?',
    subtitle: '알레르기 유발 성분이 포함된 제품을 제외해 드릴게요.',
    content: Column(
      children: [
        _buildSearchField(),
        SurveyChipGroup(
          options: _getFilteredOptions(
            SurveyData.allergies,
            noneOption: SurveyData.noneOptionAllergy,
          ),
          selectedValues: selectedAllergies,
          onSelected: (val, isSelected) => _onItemToggled(
            val,
            isSelected,
            selectedAllergies,
            SurveyData.noneOptionAllergy,
          ),
        ),
      ],
    ),
  );

  Widget _buildLifestyleStep() {
    return _surveyLayout(
      title: '평소 생활 습관에 대해\n알려주세요.',
      subtitle: '생활 환경에 따라 꼭 필요한 영양소가 달라집니다.',
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSelectionGroup(
              '흡연 여부',
              ['비흡연자', '흡연 중'],
              smokingStatus,
              (val) => setState(() => smokingStatus = val),
            ),
            const SizedBox(height: 24),
            _buildSelectionGroup(
              '음주 여부',
              ['마시지 않음', '음주 중'],
              drinkingStatus,
              (val) => setState(() => drinkingStatus = val),
            ),
            if (userGender == '여성') ...[
              const SizedBox(height: 24),
              _buildSelectionGroup(
                '임신 여부',
                ['해당 없음', '임신 중'],
                pregnancyStatus,
                (val) => setState(() => pregnancyStatus = val),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionGroup(
    String groupTitle,
    List<String> options,
    String? currentValue,
    ValueChanged<String?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          groupTitle,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        ...options.map((option) {
          final isSelected = currentValue == option;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF4CAF50)
                    : Colors.grey.shade200,
                width: 2,
              ),
              color: isSelected ? const Color(0xFFE8F5E9) : Colors.white,
            ),
            child: RadioListTile<String>(
              title: Text(
                option,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 15,
                ),
              ),
              value: option,
              groupValue: currentValue,
              activeColor: const Color(0xFF4CAF50),
              onChanged: onChanged,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              controlAffinity: ListTileControlAffinity.trailing,
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildCompletionStep() => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.celebration_rounded,
            size: 100,
            color: Color(0xFF4CAF50),
          ),
          const SizedBox(height: 40),
          const Text(
            '설문 완료!',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            '${userName ?? "사용자"}님의 건강 데이터를 바탕으로\n꼭 필요한 영양 성분을 분석하고 있습니다...',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 60),
          const SizedBox(
            width: 200,
            child: LinearProgressIndicator(
              minHeight: 2,
              color: Color(0xFF4CAF50),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _surveyLayout({
    required String title,
    required String subtitle,
    required Widget content,
  }) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 32),
          content,
        ],
      ),
    );
  }

  Widget _buildSearchField() => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: TextField(
      controller: _searchController,
      onChanged: (val) => setState(() => _searchQuery = val),
      decoration: InputDecoration(
        hintText: '찾으시는 항목을 검색해보세요',
        prefixIcon: const Icon(Icons.search, color: Colors.grey),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    ),
  );

  Widget _buildProgressBar() {
    if (_currentPage >= 5) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_currentPage + 1} / 6',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4CAF50),
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (_currentPage + 1) / 6,
            backgroundColor: const Color(0xFFF5F5F5),
            color: const Color(0xFF4CAF50),
            minHeight: 6,
            borderRadius: BorderRadius.circular(10),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    bool isEnabled = false;

    if (_currentPage == 0) {
      isEnabled =
          (userName?.isNotEmpty ?? false) &&
          (userAge?.isNotEmpty ?? false) &&
          userGender != null;
    } else if (_currentPage == 1) {
      isEnabled = selectedGoals.isNotEmpty;
    } else if (_currentPage == 2) {
      isEnabled = selectedHealth.isNotEmpty;
    } else if (_currentPage == 3) {
      isEnabled = selectedAllergies.isNotEmpty;
    } else if (_currentPage == 4) {
      isEnabled = smokingStatus != null;
    } else {
      isEnabled = true;
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        10,
        24,
        bottomPad > 0 ? bottomPad + 16 : 40,
      ),
      child: _buildFullWidthButton(
        _currentPage == 5
            ? 'OnePerDay 시작하기'
            : (_currentPage == 4 ? '분석하기' : '다음'),
        isEnabled
            ? () => (_currentPage == 4 ? _showSummaryModal() : _nextPage())
            : null,
      ),
    );
  }

  Widget _buildFullWidthButton(String label, VoidCallback? onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4CAF50),
          disabledBackgroundColor: Colors.grey.shade300,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ── 온보딩 완료 후 추천 영양제 바텀시트 ─────────────────────────────────────
class _RecommendSheet extends StatelessWidget {
  final List<String> goals;
  final VoidCallback onStart;

  const _RecommendSheet({required this.goals, required this.onStart});

  // 건강 목표 키워드 → 추천 상품 매핑
  List<StoreProduct> _getRecommended() {
    final Map<String, List<String>> goalKeywords = {
      '다이어트': ['오메가', '코큐텐', '유산균'],
      '근육': ['멀티비타민', '마그네슘'],
      '면역': ['비타민D', '멀티비타민', '유산균'],
      '피로': ['코큐텐', '마그네슘', '멀티비타민'],
      '눈 건강': ['루테인'],
      '장 건강': ['유산균'],
      '뼈 건강': ['비타민D', '마그네슘'],
      '혈관': ['오메가', '코큐텐'],
      '간 건강': ['밀크씨슬'],
      '수면': ['마그네슘'],
    };

    final Set<String> keywords = {};
    for (final goal in goals) {
      for (final entry in goalKeywords.entries) {
        if (goal.contains(entry.key) || entry.key.contains(goal)) {
          keywords.addAll(entry.value);
        }
      }
    }

    // 키워드에 매칭되는 상품 필터링
    final matched = allProducts
        .where((p) => keywords.any((k) => p.name.contains(k)))
        .toList();

    // 매칭이 없으면 상위 3개 반환
    return matched.isEmpty
        ? allProducts.take(3).toList()
        : matched.take(4).toList();
  }

  @override
  Widget build(BuildContext context) {
    final recommended = _getRecommended();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 핸들
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 헤더
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '맞춤 영양제 추천',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            goals.isEmpty
                                ? '인기 영양제를 확인해보세요'
                                : '${goals.take(2).join(', ')} 목표에 맞는 영양제예요',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 추천 상품 목록
                ...recommended.map(
                  (product) => GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/store/detail', extra: product);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.scaffoldBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.medication_rounded,
                              color: AppColors.primary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  product.brand,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${(product.price / 1000).toStringAsFixed(0)}천원',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // 시작 버튼
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: onStart,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      '앱 시작하기',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
