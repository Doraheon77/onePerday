import 'package:flutter/material.dart';
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
      context.go('/home');
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
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
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
      ),
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
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 40),
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
