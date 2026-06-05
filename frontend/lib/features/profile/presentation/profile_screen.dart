import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:simcap/core/constant/app_constants.dart';
import 'package:simcap/providers/supplement_provider.dart';
import 'package:simcap/services/notification_service.dart';
import 'package:simcap/features/profile/widgets/survey_chip_group.dart';
import 'package:simcap/features/profile/data/survey_data.dart';
import 'package:simcap/services/auth_service.dart';
import 'package:simcap/core/supabase/supabase_client.dart';
import 'package:simcap/services/review_api_service.dart';
import 'package:simcap/features/store/presentation/review_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // 데이터 상태 변수
  String _userName = '사용자';
  String _userAge = '';
  List<String> _goals = [];
  List<String> _healthIssues = [];
  List<String> _allergies = [];
  String _smokingStatus = '비흡연자입니다';
  String _drinkingStatus = '마시지 않음';
  String _pregnancyStatus = '해당 없음';
  String _userGender = '';
  bool _isLoading = true;
  List<ProductReview> _myReviews = [];

  // 알림 및 설정 관련 상태 변수
  bool _durNotificationEnabled = true;
  bool _intakeReminderEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  // 로컬 저장소에서 데이터 불러오기
  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // 온보딩에서 저장된 기본 정보 로드
      _userName = prefs.getString('userName') ?? '사용자';
      _userAge = prefs.getString('userAge') ?? '';

      _userGender =
          prefs.getString('gender') ?? prefs.getString('userGender') ?? '미설정';

      // 설문 데이터 로드
      _goals = prefs.getStringList('selectedGoals') ?? [];
      _healthIssues = prefs.getStringList('selectedHealth') ?? [];
      _allergies = prefs.getStringList('selectedAllergies') ?? [];
      _smokingStatus = prefs.getString('smokingStatus') ?? '비흡연자입니다';
      _drinkingStatus = prefs.getString('drinkingStatus') ?? '마시지 않음';
      _pregnancyStatus = prefs.getString('pregnancyStatus') ?? '해당 없음';

      // 앱 설정 데이터 로드
      _durNotificationEnabled = prefs.getBool('durNotificationEnabled') ?? true;
      _intakeReminderEnabled = prefs.getBool('intakeReminderEnabled') ?? true;

      _isLoading = false;
    });

    final user = AuthService().currentUser;
    if (user != null) {
      try {
        final reviews = await ReviewApiService().fetchUserReviews(user.id);
        if (mounted) {
          setState(() {
            _myReviews = reviews;
          });
        }
      } catch (e) {
        debugPrint('내가 쓴 리뷰 가져오기 에러: $e');
      }
    }
  }

  // 데이터 수정 및 저장 함수
  Future<void> _updateData(String key, List<String> newData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(key, newData);
    await _loadProfileData();

    // Supabase DB 실시간 클라우드 동기화
    final authService = AuthService();
    final user = authService.currentUser;
    if (user != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 12),
                Text('클라우드에 변경사항 동기화 중...'),
              ],
            ),
            duration: Duration(milliseconds: 600),
          ),
        );
      }

      try {
        final goals = prefs.getStringList('selectedGoals') ?? [];
        final health = prefs.getStringList('selectedHealth') ?? [];
        final allergies = prefs.getStringList('selectedAllergies') ?? [];

        final name = prefs.getString('userName') ?? _userName;
        final gender =
            prefs.getString('gender') ??
            prefs.getString('userGender') ??
            _userGender;
        final ageStr = prefs.getString('userAge') ?? _userAge;

        int birthYearVal = int.tryParse(ageStr) ?? 0;
        if (birthYearVal > 0 && birthYearVal < 120) {
          birthYearVal = DateTime.now().year - birthYearVal;
        }

        await authService.completeOnboarding(
          name: name,
          gender: gender,
          birthYear: birthYearVal,
          conditions: health,
          allergies: allergies,
          healthGoals: goals,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('저장되었습니다.'),
              backgroundColor: AppColors.primary,
              duration: Duration(seconds: 1),
            ),
          );
        }
      } catch (e) {
        debugPrint('DB 실시간 동기화 에러: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚠️ 동기화 실패: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  // 생활 습관(흡연) 업데이트 함수 (생활 습관은 로컬 캐시에 저장되며 백엔드 추천 스코어링에는 영향을 주지 않으므로 로컬 저장소에 보관)
  Future<void> _updateSmokingStatus(String status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('smokingStatus', status);
    await _loadProfileData();
  }

  Future<void> _updateDrinkingStatus(String status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('drinkingStatus', status);
    await _loadProfileData();
  }

  Future<void> _updatePregnancyStatus(String status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pregnancyStatus', status);
    await _loadProfileData();
  }

  // 편집 모달 로직
  void _showEditModal({
    required String title,
    required List<SurveyOption> options,
    required List<String> currentSelected,
    required String storageKey,
    String? noneOption,
  }) {
    List<String> tempSelected = List.from(currentSelected);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              maxChildSize: 0.9,
              expand: false,
              builder: (_, scrollController) {
                return Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$title 편집',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        children: [
                          SurveyChipGroup(
                            options: noneOption != null
                                ? [
                                    SurveyOption(
                                      id: 'none',
                                      label: noneOption,
                                      imagePath: 'assets/images/none.png',
                                    ),
                                    ...options,
                                  ]
                                : options,
                            selectedValues: tempSelected,
                            onSelected: (val, isSelected) {
                              setModalState(() {
                                if (noneOption != null && val == noneOption) {
                                  if (isSelected) {
                                    tempSelected.clear();
                                    tempSelected.add(noneOption);
                                  } else {
                                    tempSelected.remove(noneOption);
                                  }
                                } else {
                                  if (noneOption != null) {
                                    tempSelected.remove(noneOption);
                                  }
                                  isSelected
                                      ? tempSelected.add(val)
                                      : tempSelected.remove(val);
                                }
                              });
                            },
                          ),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                      child: SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: () async {
                            await _updateData(storageKey, tempSelected);
                            if (mounted) Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            '변경사항 저장하기',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          '마이페이지',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 40),

                  // 1. 기본 정보 섹션 (나이/성별)
                  _buildBasicInfoSection(),
                  const SizedBox(height: 32),

                  // 2. 구매 기록 섹션 (위로 이동)
                  _buildPurchaseHistorySection(),
                  const SizedBox(height: 32),

                  // 3. 내가 쓴 리뷰 섹션 (위로 이동)
                  _buildMyReviewsSection(),
                  const SizedBox(height: 32),

                  // 4. 나의 건강 목표 (아래로 이동)
                  _buildProfileSection(
                    '나의 건강 목표',
                    _goals,
                    isGoal: true,
                    onEdit: () => _showEditModal(
                      title: '건강 목표',
                      options: SurveyData.goals,
                      currentSelected: _goals,
                      storageKey: 'selectedGoals',
                    ),
                  ),

                  // 5. 질환 섹션
                  _buildProfileSection(
                    '주의가 필요한 질환',
                    _healthIssues,
                    isGoal: true,
                    onEdit: () => _showEditModal(
                      title: '보유 질환',
                      options: SurveyData.healthIssues,
                      currentSelected: _healthIssues,
                      storageKey: 'selectedHealth',
                      noneOption: SurveyData.noneOptionHealth,
                    ),
                  ),

                  // 6. 알레르기 섹션
                  _buildProfileSection(
                    '나의 알레르기',
                    _allergies,
                    isGoal: true,
                    onEdit: () => _showEditModal(
                      title: '알레르기',
                      options: SurveyData.allergies,
                      currentSelected: _allergies,
                      storageKey: 'selectedAllergies',
                      noneOption: SurveyData.noneOptionAllergy,
                    ),
                  ),

                  // 7. 생활 습관 섹션
                  _buildProfileSection(
                    '생활 습관',
                    [
                          _smokingStatus,
                          _drinkingStatus,
                          if (_userGender == '여성') _pregnancyStatus,
                        ]
                        .where((s) => s != null && s.isNotEmpty)
                        .cast<String>()
                        .toList(),
                    onEdit: () => _showLifestyleEditModal(),
                  ),
                  const SizedBox(height: 40),

                  // 메뉴 버튼 (설문 다시하기 제거)
                  _buildMenuButton(
                    '앱 설정',
                    Icons.settings,
                    onTap: _showAppSettingsSheet,
                  ),
                  const SizedBox(height: 24),
                  _buildLogoutButton(),
                ],
              ),
            ),
    );
  }

  // 헤더
  Widget _buildHeader() {
    return Row(
      children: [
        const CircleAvatar(
          radius: 35,
          backgroundColor: AppColors.primaryLight,
          child: Icon(Icons.person, size: 40, color: AppColors.primary),
        ),
        const SizedBox(width: 20),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$_userName 님, 반갑습니다!',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              '오늘도 건강한 하루 되세요.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ],
    );
  }

  // 나의 기본 정보 섹션
  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '나의 기본 정보',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '나이',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _userAge.isNotEmpty ? '$_userAge세' : '미입력',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 30, color: Colors.grey.shade300),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '성별',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _userGender, // 💡 여기서 미설정이 나오면 로드 시 키값을 확인해야 합니다.
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showLifestyleEditModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final isSmoker = _smokingStatus == '흡연자입니다';
          final isDrinker = _drinkingStatus == '음주 중';
          final isPregnant = _pregnancyStatus == '임신 중';
          final isWoman = _userGender == '여성';

          return Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              32,
              24,
              MediaQuery.of(ctx).padding.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '생활 습관 편집',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                // 흡연
                _buildLifestyleToggle(
                  ctx: ctx,
                  setModalState: setModalState,
                  label: '흡연 여부',
                  value: isSmoker,
                  trueLabel: '흡연자',
                  falseLabel: '비흡연자',
                  onChanged: (v) async {
                    await _updateSmokingStatus(v ? '흡연자입니다' : '비흡연자입니다');
                    setModalState(() {});
                  },
                ),
                const SizedBox(height: 12),

                // 음주
                _buildLifestyleToggle(
                  ctx: ctx,
                  setModalState: setModalState,
                  label: '음주 여부',
                  value: isDrinker,
                  trueLabel: '음주 중',
                  falseLabel: '마시지 않음',
                  onChanged: (v) async {
                    await _updateDrinkingStatus(v ? '음주 중' : '마시지 않음');
                    setModalState(() {});
                  },
                ),

                // 임신 (여성만)
                if (isWoman) ...[
                  const SizedBox(height: 12),
                  _buildLifestyleToggle(
                    ctx: ctx,
                    setModalState: setModalState,
                    label: '임신 여부',
                    value: isPregnant,
                    trueLabel: '임신 중',
                    falseLabel: '해당 없음',
                    onChanged: (v) async {
                      await _updatePregnancyStatus(v ? '임신 중' : '해당 없음');
                      setModalState(() {});
                    },
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      '완료',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
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

  Widget _buildLifestyleToggle({
    required BuildContext ctx,
    required StateSetter setModalState,
    required String label,
    required bool value,
    required String trueLabel,
    required String falseLabel,
    required Function(bool) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          Row(
            children: [
              Text(
                value ? trueLabel : falseLabel,
                style: TextStyle(
                  color: value ? AppColors.primary : Colors.grey,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 8),
              Switch(
                value: value,
                onChanged: onChanged,
                activeColor: AppColors.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 프로필 정보 섹션 (목표, 질환, 알레르기)
  Widget _buildProfileSection(
    String title,
    List<String> items, {
    required VoidCallback onEdit,
    bool isGoal = false,
  }) {
    final bool isEmpty =
        items.isEmpty || (items.length == 1 && (items[0].contains('없음')));

    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: onEdit,
                child: const Text(
                  '편집',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isEmpty)
            const Text(
              '등록된 정보가 없습니다.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 10,
              children: items
                  .map(
                    (item) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isGoal
                            ? AppColors.primaryLight
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                        border: isGoal
                            ? Border.all(
                                color: AppColors.primary.withOpacity(0.2),
                              )
                            : null,
                      ),
                      child: Text(
                        item,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isGoal
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: isGoal
                              ? AppColors.primaryDark
                              : Colors.black87,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  // 생활 습관 섹션
  Widget _buildLifestyleSection() {
    final bool isSmoker = _smokingStatus == '흡연자입니다';
    final bool isDrinker = _drinkingStatus == '음주 중';
    final bool isPregnant = _pregnancyStatus == '임신 중';
    final bool isWoman = _userGender == '여성';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '생활 습관',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // ── 흡연 ────────────────────────────────────────────────────────
        _buildLifestyleCard(
          icon: isSmoker ? Icons.smoking_rooms : Icons.smoke_free,
          label: _smokingStatus,
          isActive: isSmoker,
          activeColor: Colors.orange,
          activeBg: AppColors.smokingBg,
          onTap: () => _updateSmokingStatus(isSmoker ? '비흡연자입니다' : '흡연자입니다'),
        ),
        const SizedBox(height: 10),

        // ── 음주 ────────────────────────────────────────────────────────
        _buildLifestyleCard(
          icon: isDrinker ? Icons.local_bar_rounded : Icons.no_drinks_outlined,
          label: _drinkingStatus,
          isActive: isDrinker,
          activeColor: Colors.purple,
          activeBg: AppColors.drinkingBg,
          onTap: () => _updateDrinkingStatus(isDrinker ? '마시지 않음' : '음주 중'),
        ),

        // ── 임신 (여성만 표시) ──────────────────────────────────────────
        if (isWoman) ...[
          const SizedBox(height: 10),
          _buildLifestyleCard(
            icon: isPregnant
                ? Icons.pregnant_woman_rounded
                : Icons.pregnant_woman_outlined,
            label: _pregnancyStatus,
            isActive: isPregnant,
            activeColor: Colors.pink,
            activeBg: AppColors.pregnancyBg,
            onTap: () => _updatePregnancyStatus(isPregnant ? '해당 없음' : '임신 중'),
          ),
        ],
      ],
    );
  }

  /// 생활 습관 공통 토글 카드
  Widget _buildLifestyleCard({
    required IconData icon,
    required String label,
    required bool isActive,
    required Color activeColor,
    required Color activeBg,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isActive ? activeBg : AppColors.primaryLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? activeColor.withOpacity(0.25)
                : AppColors.primary.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isActive ? activeColor : AppColors.primary),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isActive ? activeColor : AppColors.primaryDark,
              ),
            ),
            const Spacer(),
            const Icon(Icons.sync, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // 내가 쓴 리뷰 섹션
  Widget _buildMyReviewsSection() {
    final recentReviews = _myReviews;
    final hasReviews = recentReviews.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '내가 쓴 리뷰',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: hasReviews
                  ? () => context.push('/profile/my-reviews')
                  : null,
              child: Text(
                '전체보기',
                style: TextStyle(
                  color: hasReviews ? AppColors.primary : Colors.grey[400],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (!hasReviews)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.scaffoldBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.rate_review_outlined,
                  size: 36,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 8),
                Text(
                  '아직 작성한 리뷰가 없습니다',
                  style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                ),
                const SizedBox(height: 4),
                Text(
                  '구매한 상품에 리뷰를 남겨보세요',
                  style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                ),
              ],
            ),
          )
        else
          ...recentReviews
              .take(3)
              .map(
                (r) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.productName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: List.generate(
                                5,
                                (i) => Icon(
                                  i < r.rating
                                      ? Icons.star_rounded
                                      : Icons.star_outline_rounded,
                                  size: 14,
                                  color: i < r.rating
                                      ? Colors.amber
                                      : Colors.grey.shade300,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              r.content,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              Text(
                                '상세보기',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[400],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                size: 14,
                                color: Colors.grey[400],
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            r.createdAt
                                .toString()
                                .substring(0, 10)
                                .replaceAll('-', '.'),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
      ],
    );
  }

  // 구매 기록 섹션 — Provider 데이터 연동
  Widget _buildPurchaseHistorySection() {
    final purchases = SupplementProvider.of(context).purchases;
    final recentPurchases = purchases.take(3).toList();
    final hasData = recentPurchases.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '구매 기록',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: hasData
                  ? () => context.push('/profile/purchases')
                  : null,
              child: Text(
                '전체보기',
                style: TextStyle(
                  color: hasData ? AppColors.primary : Colors.grey[400],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (hasData)
          ...recentPurchases.map((r) => _buildPurchaseItemFromRecord(r))
        else
          _buildPurchaseEmptyState(),
      ],
    );
  }

  // Provider 데이터 기반 구매 아이템 카드
  Widget _buildPurchaseItemFromRecord(PurchaseRecord record) {
    Color badgeBg, badgeFg;
    switch (record.status) {
      case PurchaseStatus.ordered:
        badgeBg = AppColors.orderedBg;
        badgeFg = AppColors.orderedFg;
        break;
      case PurchaseStatus.shipping:
        badgeBg = AppColors.shippingBg;
        badgeFg = AppColors.shippingFg;
        break;
      case PurchaseStatus.delivered:
        badgeBg = AppColors.primaryLight;
        badgeFg = AppColors.primaryDark;
        break;
      case PurchaseStatus.cancelled:
        badgeBg = AppColors.dangerBg;
        badgeFg = AppColors.danger;
        break;
    }
    final isCancelled = record.status == PurchaseStatus.cancelled;

    return GestureDetector(
      onTap: () => context.push('/profile/purchases'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isCancelled ? Colors.grey.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isCancelled
                    ? Colors.grey.shade100
                    : AppColors.primaryFaint,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.medication_rounded,
                color: isCancelled ? Colors.grey[400] : AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.displayTitle,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isCancelled ? Colors.grey : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        _pfmt(record.totalPrice),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isCancelled
                              ? Colors.grey[400]
                              : AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _dlabel(record.orderedAt),
                        style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                record.status.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: badgeFg,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _dlabel(DateTime dt) {
    final now = DateTime.now();
    final diff = DateTime(
      now.year,
      now.month,
      now.day,
    ).difference(DateTime(dt.year, dt.month, dt.day)).inDays;
    if (diff == 0) return '오늘';
    if (diff == 1) return '어제';
    if (diff < 7) return '$diff일 전';
    return '${dt.month}.${dt.day}';
  }

  String _pfmt(int price) {
    String s = price.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return '${buf.toString()}원';
  }

  // 구매 기록 — 빈 상태 플레이스홀더
  Widget _buildPurchaseEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            '구매 기록이 없습니다',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '스토어에서 영양제를 구매하면\n여기서 기록을 확인할 수 있어요',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[400],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: OutlinedButton.icon(
              onPressed: () => context.go('/store'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                minimumSize: const Size(0, 40),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              icon: const Icon(
                Icons.storefront_outlined,
                size: 15,
                color: AppColors.primary,
              ),
              label: const Text(
                '스토어 바로가기',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 구매 기록 — 개별 아이템 (백엔드 연동 후 사용)
  Widget _buildPurchaseItem({
    required String productName,
    required String brand,
    required int price,
    required DateTime date,
    required String status,
  }) {
    final bool isDelivered = status == '배송 완료';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // 상품 이미지 자리
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primaryFaint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.medication_rounded,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  brand,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  productName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${_formatPrice(price)}원',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${date.month}.${date.day}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 배송 상태 배지
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isDelivered ? AppColors.primaryLight : AppColors.orderedBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isDelivered
                    ? AppColors.primaryDark
                    : AppColors.orderedFg,
              ),
            ),
          ),
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

  // ── 로그아웃 ────────────────────────────────────────────────────────────
  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '로그아웃',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('로그아웃하면 저장된 설문 정보가 초기화됩니다.\n계속하시겠습니까?'),
        actions: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      '취소',
                      style: TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      '로그아웃',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    //  Supabase 로그아웃
    await AuthService().signOut();

    // SharedPreferences 전체 초기화
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;
    // 메모리 상태도 초기화
    SupplementProvider.of(context).clearAll();
    // 로그인 화면으로 이동 (스택 전체 교체)
    context.go('/login');
  }

  void _showAppSettingsSheet() async {
    // 현재 저장된 설정값 로드
    final prefs = await SharedPreferences.getInstance();
    bool doseAlarm = prefs.getBool('setting_dose_alarm') ?? true;
    bool restockAlarm = prefs.getBool('setting_restock_alarm') ?? true;

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).padding.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '앱 설정',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              // 복용 알림 토글
              _settingToggleRow(
                icon: Icons.alarm_rounded,
                title: '복용 알림',
                subtitle: '영양제 복용 시간에 알림을 보냅니다',
                value: doseAlarm,
                onChanged: (val) async {
                  setSheetState(() => doseAlarm = val);
                  await prefs.setBool('setting_dose_alarm', val);
                  final notifier = SupplementProvider.of(context);
                  if (val) {
                    // 알림 켜기 — 모든 영양제 알림 재등록
                    await NotificationService.instance.scheduleAllDoseAlarms(
                      notifier.supplements.toList(),
                    );
                  } else {
                    // 알림 끄기 — 모든 복용 알림 취소
                    await NotificationService.instance.cancelAllDoseAlarms();
                  }
                },
              ),
              const Divider(height: 24),
              // 재구매 알림 토글
              _settingToggleRow(
                icon: Icons.shopping_bag_outlined,
                title: '재구매 알림',
                subtitle: '소진 임박 시 알림을 보냅니다',
                value: restockAlarm,
                onChanged: (val) async {
                  setSheetState(() => restockAlarm = val);
                  await prefs.setBool('setting_restock_alarm', val);
                  if (val) {
                    final notifier = SupplementProvider.of(context);
                    await NotificationService.instance.checkAndNotifyLowStock(
                      notifier.supplements.toList(),
                    );
                  }
                  // 끄기: 재구매 알림은 다음 체크 시 자동 무시
                },
              ),
              const Divider(height: 24),
              Row(
                children: [
                  const Icon(Icons.info_outline, size: 20, color: Colors.grey),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '앱 버전',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'v1.0.0',
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _settingToggleRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.primary,
        ),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _logout,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: const BorderSide(color: AppColors.danger),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: const Icon(
          Icons.logout_rounded,
          size: 18,
          color: AppColors.danger,
        ),
        label: const Text(
          '로그아웃',
          style: TextStyle(
            color: AppColors.danger,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(
    String title,
    IconData icon, {
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Colors.grey.shade700),
      title: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: Colors.grey,
      ),
      onTap: onTap,
    );
  }

  void _showPolicySheet(String type) {
    final isTerms = type == 'terms';
    final title = isTerms ? '서비스 이용 약관' : '개인정보 처리방침';
    final content = isTerms ? _termsContent : _privacyContent;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, controller) => Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                controller: controller,
                padding: const EdgeInsets.all(20),
                child: Text(
                  content,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.7,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                MediaQuery.of(ctx).padding.bottom + 16,
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '확인',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const String _termsContent = '''# OnePerDay 서비스 이용 약관

**제1장 총칙**

**제1조 (목적)**
본 약관은 "OnePerDay 팀"(이하 "회사"라 합니다)이 제공하는 스마트폰 어플리케이션 "OnePerDay"(이하 "어플리케이션" 또는 "서비스"라 합니다) 및 관련 제반 서비스의 이용과 관련하여, 회사와 회원(이하 "이용자" 또는 "회원"이라 합니다) 간의 권리, 의무 및 책임사항, 서비스 이용 조건 및 절차 등 기본적인 사항을 규정함을 목적으로 합니다.

**제2조 (용어의 정의)**
본 약관에서 사용하는 용어의 정의는 다음과 같습니다.
1. "서비스"라 함은 회사가 스마트 기기를 통해 회원에게 제공하는 건강 맞춤 온보딩 설문 분석, 내 영양제 약장 관리, 바코드/OCR 스캔 제품 등록, 장바구니 안전성 검사(성분 상호작용 및 과다섭취 분석), AI 챗봇 상담, 영양제 제품 검색 및 쇼핑 스토어 등 OnePerDay 어플리케이션 내의 모든 제반 서비스를 의미합니다.
2. "회원"이라 함은 본 약관에 동의하고 서비스에 가입하여 회사가 제공하는 서비스를 이용하는 고객을 말합니다.
3. "계정(ID)"이라 함은 회원의 식별과 서비스 이용을 위하여 회원이 제공하고 회사가 승인한 카카오, 구글 등 소셜 연동 계정 정보를 의미합니다.
4. "콘텐츠"라 함은 서비스 내에서 제공되는 영양 성분 정보, AI 요약 가이드, 분석 결과, 챗봇 답변, 텍스트, 이미지, 리뷰 등 디지털 형태의 모든 정보 및 자료를 의미합니다.
5. "스토어"라 함은 어플리케이션 내에서 영양제 및 건강기능식품 관련 상품을 탐색하고 구매할 수 있는 가상 또는 실제의 온라인 쇼핑 공간을 의미합니다.

**제3조 (약관의 명시, 효력 및 개정)**
1. 회사는 본 약관의 내용을 회원이 쉽게 알 수 있도록 어플리케이션 내의 설정 또는 회원가입 화면에 게시합니다.
2. 회사는 관계법령을 위배하지 않는 범위에서 본 약관을 개정할 수 있습니다.
3. 약관을 개정할 경우에는 적용일자 및 개정 사유를 명시하여 현행 약관과 함께 개정 약관의 적용일자 7일 전(회원에게 불리하거나 중대한 사항의 변경은 30일 전)부터 어플리케이션 내 고지사항 등을 통해 공지합니다.
4. 회원이 개정 약관의 적용에 동의하지 않는 경우, 회원은 서비스 이용 계약을 해지(탈퇴)할 수 있습니다. 회사가 개정 약관을 공지하면서 회원에게 "기간 내에 의사표시를 하지 않으면 동의한 것으로 본다"는 뜻을 명확히 공지하였음에도 회원이 명시적으로 거부 의사를 표시하지 아니한 경우, 개정 약관에 동의한 것으로 봅니다.

---

**제2장 회원가입 및 계정 관리**

**제4조 (이용계약의 성립 및 회원가입)**
1. 서비스 이용계약은 회원이 되고자 하는 자가 본 약관의 내용에 대하여 동의를 한 다음, 소셜 계정(카카오, 구글 등)을 연동하여 가입 신청을 하고 회사가 이를 승인함으로써 성립합니다.
2. 회사는 다음 각 호에 해당하는 신청에 대하여는 승인을 하지 않거나 사후에 이용계약을 해지할 수 있습니다.
   * 가입 신청자가 본 약관에 의하여 이전에 회원자격을 상실한 적이 있는 경우
   * 타인의 소셜 계정을 도용하거나 허위의 정보를 기재한 경우
   * 만 14세 미만 아동이 법정대리인의 동의 없이 가입을 신청한 경우
   * 회사의 기술상 혹은 업무상 서비스 제공이 불가능한 경우

**제5조 (회원 계정 및 정보의 관리)**
1. 회원은 본인의 소셜 연동 계정에 대한 관리 책임이 있으며, 이를 제3자에게 이용하도록 하여서는 안 됩니다. 소셜 계정의 관리 소홀이나 부정 사용으로 인해 발생하는 모든 책임은 회원 본인에게 있습니다.
2. 회원은 개인정보 관리 화면을 통하여 언제든지 본인의 개인정보를 열람하고 수정할 수 있습니다. 수정을 소홀히 하여 발생한 불이익은 회원 본인의 책임입니다.

---

**제3장 서비스의 이용 및 제공**

**제6조 (서비스의 내용)**
회사가 회원에게 제공하는 서비스의 구체적인 내용은 다음과 같습니다.
1. **온보딩 건강 설문 및 분석**: 회원의 기본 프로필, 복용 목적, 보유 질환, 알레르기 유발 물질, 평소 생활 습관 등의 데이터를 기초로 맞춤형 권장 영양 성분 정보를 제안합니다.
2. **내 영양제 약장 관리 (보관함 및 섭취 알림)**: 복용 중인 영양제를 보관함에 등록하고, 잔여량 추적, 섭취 등록 및 알림 기능을 제공합니다.
3. **스마트 카메라 스캔 (바코드/OCR)**: 스마트 기기의 카메라를 활용하여 영양제 라벨이나 바코드를 스캔하여 제품 정보를 식별하고 자동으로 등록해 주는 편의를 제공합니다.
4. **장바구니 안전성 검사**: 장바구니에 담은 영양제 제품 간의 성분 중복 여부, 일일 상한량 초과 섭취 여부(과다섭취 검사), 회원의 기저질환이나 알레르기 성분과의 충돌 여부(성분 상호작용 검사)를 사전에 분석하여 경고 및 분석 리포트를 제공합니다.
5. **AI 챗봇 상담**: LLM(대형 언어 모델) 등 인공지능 기술을 기반으로 영양 성분이나 섭취 주의사항 등에 대한 질문에 실시간 답변을 제공합니다.
6. **스토어 서비스**: 영양제 제품 검색, 리뷰 작성 및 조회, 제품 주문 및 결제(시뮬레이션 포함) 기능을 제공합니다.

**제7조 (의학적 면책 조항 - 필라이즈 벤치마킹 및 법적 책임 제한)**
1. **[중요]** **본 서비스(어플리케이션 분석 가이드, 안전성 검사 결과 리포트, AI 챗봇의 모든 답변을 포함하되 이에 국한되지 않음)에서 제공하는 건강 및 영양 정보는 정보 제공 및 일반 웰니스 관리 목적으로만 제공되며, 어떠한 경우에도 의사, 약사, 한의사 등 전문 의료진의 의학적 소견, 진료, 진단, 처방 또는 전문적 치료를 대체할 수 없습니다.**
2. 회원이 본 서비스에서 얻은 정보를 바탕으로 특정 영양제를 복용하거나 중단하는 등 섭취 결정을 내릴 경우, 이는 전적으로 회원 본인의 판단과 책임하에 이루어집니다. 
3. 회원은 기저질환, 알레르기, 특정 약물 복용 여부, 임신, 수유 등 개별적인 신체 상태에 적합한 영양제 섭취를 위해 반드시 복용 전 보건의료 전문가와 상담하여 최종 의학적 진단을 받아야 합니다.
4. 회사는 개별 회원의 신체 특성을 완전무결하게 파악할 수 없으므로, 서비스 내에서 발생한 정보나 권장 사항의 오류, 또는 회원의 오인 및 맹신으로 인해 발생한 신체적 이상, 부작용, 물질적 손해에 대하여 회사의 고의 또는 중과실이 없는 한 법적 책임을 지지 않습니다.

**제8조 (AI 서비스 및 챗봇 이용 안내)**
1. AI 챗봇은 기계 학습 및 자연어 처리 기술에 기반하여 자동화된 답변을 생성하므로, 사실과 다른 답변(환각 현상, Hallucination)이나 최신 의학 정보가 미반영된 불완전한 정보가 포함될 수 있습니다. 
2. 회원은 AI 챗봇이 제공한 정보를 전적으로 신뢰해서는 안 되며, 중요한 보건학적 결정 시에는 반드시 공식 의학 정보나 전문가의 소견을 교차 검증해야 합니다.

---

**제4장 스토어 이용 및 전자상거래 규정**

**제9조 (구매 신청 및 계약의 성립)**
1. 회원은 어플리케이션 내 스토어에서 제공하는 상품의 상세 정보를 확인한 후 구매를 신청할 수 있습니다.
2. 스토어 내에서 계약은 회원의 구매 신청에 대하여 회사가 수신확인통지를 하고, 이 통지가 회원에게 도달한 시점에 성립합니다.
3. 구매 전 장바구니 단계에서 제공되는 "안전성 검사" 기능은 회원의 합리적인 선택을 돕기 위한 참고 자료일 뿐이며, 최종 구매 신청 여부는 회원의 전적인 판단에 따릅니다.

**제10조 (청약철회 및 환불 - 전자상거래법 준수)**
1. 회사의 상품을 구매한 회원은 『전자상거래 등에서의 소비자보호에 관한 법률』에 따라 상품 수령일로부터 7일 이내에 청약의 철회(반품 및 환불)를 신청할 수 있습니다.
2. 단, 다음 각 호에 해당하는 경우에는 회원의 청약철회가 제한됩니다.
   * 회원에게 책임 있는 사유로 상품이 멸실 또는 훼손된 경우
   * 회원이 상품의 포장을 개봉하거나 훼손하여 상품 가치가 현저히 상실된 경우 (단, 상품 내용을 확인하기 위해 겉포장 등을 개봉한 경우는 제외)
   * 회원의 사용 또는 일부 소비에 의하여 상품의 가치가 현저히 감소한 경우 (예: 영양제 통의 실(Seal)을 개봉하거나 일부 섭취한 경우)
   * 시간의 경과에 의하여 재판매가 곤란할 정도로 상품의 가치가 현저히 감소한 경우
3. 해외 구매 대행 상품(직구)의 경우, 통관 절차 및 해외 공급처의 반품 규정에 따라 별도의 반품 비용(국제 왕복 배송비 등)이 부과될 수 있으며, 가입 시 상품 상세 페이지에 사전 고지된 특별 규정이 우선 적용됩니다.

---

**제5장 계약 당사자의 의무 및 면책**

**제11조 (회사의 의무)**
1. 회사는 관련 법령과 본 약관이 금지하거나 미풍양속에 반하는 행위를 하지 않으며, 지속적이고 안정적인 서비스를 제공하기 위해 최선을 다합니다.
2. 회사는 회원이 안전하게 서비스를 이용할 수 있도록 개인정보 및 민감정보(건강 정보) 보호를 위한 보안 시스템을 구축하고 개인정보 처리방침을 준수합니다.

**제12조 (회원의 의무)**
1. 회원은 서비스를 이용할 때 다음 각 호의 행위를 하여서는 안 됩니다.
   * 회원가입 및 온보딩 건강 설문 시 타인의 정보 도용 또는 허위 사실 유포
   * 회사가 제공하는 정보 및 어플리케이션 소스 코드의 무단 변경, 역설계(Reverse Engineering), 배포 및 상업적 목적 활용
   * 회사 및 제3자의 지식재산권, 명예 등 권리를 침해하는 행위
   * 서비스의 안정적인 운영을 방해할 수 있는 해킹, 바이러스 유포, 부적절한 리뷰 등록 행위
2. 회원은 본인의 건강을 해치지 않도록 서비스 내 권장량 지침 외에도 제품 패키지에 기재된 공식 섭취량 및 주의사항을 반드시 준수하여 이용해야 합니다.

**제13조 (서비스 이용 제한)**
회사는 회원이 본 약관의 의무를 위반하거나 서비스의 정상적인 운영을 방해한 경우, 경고, 일시정지, 영구이용정지, 회원 탈퇴 등의 단계적 조치로 서비스 이용을 제한할 수 있습니다.

**제14조 (손해배상 및 면책)**
1. 회사는 천재지변, 전시, 디도스(DDoS) 공격, 기간통신사업자의 회선 장애 등 불가항력으로 인하여 서비스를 제공할 수 없는 경우에는 서비스 제공에 관한 책임이 면제됩니다.
2. 회사는 회원의 귀책사유로 인한 서비스 이용 장애에 대하여 책임을 지지 않습니다.
3. 회사는 서비스 내 등록된 제품 정보의 제원 오류(제조사의 성분 변경 미반영 등)로 인해 발생한 직·간접적 손해에 대해 고의 또는 중과실이 없는 한 배상 책임을 지지 않습니다.
4. AI 챗봇이 생성한 답변 내용의 임의적 판단 오류에 대해 회사는 법적 책임을 지지 않으며, 최종 판단은 전적으로 회원 본인의 몫입니다.

---

**제6장 기타**

**제15조 (준거법 및 관할법원)**
1. 회사와 회원 간에 제기된 소송은 대한민국 법을 준거법으로 합니다.
2. 회사와 회원 간에 발생한 분쟁에 관한 소송은 민사소송법상의 관할법원에 제기하며, 당사자 간 합의가 이루어지지 않을 경우 회사의 본사 소재지를 관할하는 법원(또는 서울중앙지방법원)을 제1심 합의관할 법원으로 합니다.

**부칙**
본 약관은 2026년 5월 28일부터 효력을 가집니다.
''';

const String _privacyContent = '''# OnePerDay 개인정보 처리 방침

"OnePerDay 팀"(이하 "회사"라 합니다)은 정보주체인 이용자(이하 "회원"이라 합니다)의 개인정보를 매우 소중하게 생각하며, 『개인정보 보호법』, 『정보통신망 이용촉진 및 정보보호 등에 관한 법률』 등 개인정보 보호 관련 대한민국 법령을 철저히 준수하고 있습니다.

회사는 본 개인정보 처리방침을 통하여 회원이 제공하는 개인정보 및 건강에 관한 민감정보가 어떠한 용도와 방식으로 처리되고 있으며, 보호를 위해 어떤 조치가 취해지고 있는지 알려드립니다.

---

**제1조 (개인정보의 처리 목적)**
회사는 다음의 목적을 위하여 회원의 개인정보를 처리합니다. 처리하고 있는 개인정보는 다음의 목적 이외의 용도로는 사용되지 않으며, 이용 목적이 변경되는 경우에는 개인정보 보호법 제18조에 따라 별도의 동의를 받는 등 필요한 조치를 이행할 예정입니다.

1. **회원 가입 및 관리**: 소셜 연동 로그인을 통한 회원 식별 및 본인 확인, 가입 의사 확인, 회원자격 유지·관리, 제한적 본인 확인제 시행에 따른 본인확인, 서비스 부정이용 방지, 각종 고지·통지 등을 목적으로 개인정보를 처리합니다.
2. **개인 맞춤 건강 가이드 및 분석 서비스 제공**: 온보딩 건강 설문 데이터를 분석하여 회원의 신체 특성에 따른 권장 영양소 매칭, 보관함(약장) 관리 및 섭취 기록 등록, 잔여량 섭취 알림(Reminder) 발송 등의 개인화된 핵심 서비스를 제공합니다.
3. **장바구니 안전성 검사 서비스 제공**: 장바구니 내 등록 영양제 성분의 중복 섭취 및 일일 상한량 초과 여부 분석, 회원의 질환 및 알레르기 성분과의 병용 위험(상호작용) 분석 결과를 연동 및 제공합니다.
4. **AI 챗봇 상담 및 서비스 개선**: 인공지능 기반 영양 상담 기능을 제공하고, 질의응답 처리 및 서비스 고도화를 위한 기계 학습 데이터 분석을 목적으로 합니다.
5. **스토어 주문, 대금 결제 및 배송**: 상품 검색, 상품 주문 및 계약 성립, 대금 결제(결제 승인 결과 처리 포함), 상품 배송 및 통관 절차 지원, 반품/취소/환불 등 거래 사후 관리를 목적으로 개인정보를 처리합니다.
6. **고객 상담 및 민원 처리**: 이용자 문의사항 확인, 사실 조사를 위한 연락·통지, 처리결과 통보 등을 목적으로 합니다.

---

**제2조 (개인정보의 수집 항목 및 방법)**
회사는 서비스 제공을 위해 필요한 최소한의 개인정보를 수집하며, 특히 건강과 관련된 정보는 법령상 민감정보로 규정되어 있어 **일반 개인정보와 구분하여 별도의 명시적 동의**를 얻은 후에만 수집 및 처리합니다.

1. **회원 가입 시 수집하는 일반 개인정보 (필수)**
   * **수집 항목**: 소셜 연동 식별자(구글/카카오 고유 ID), 닉네임, 프로필 사진, 이메일 주소
2. **맞춤형 건강 분석 및 서비스를 위한 민감 정보 (선택 - 동의 시 수집)**
   * **수집 항목**:
     * 신체 정보: 나이(연령), 성별
     * 건강 상태 정보: 복용 목적(건강 고민/목표), 보유 중인 기저질환 정보, 보유 중인 알레르기 유발 물질 및 성분 정보
     * 생활 습관 정보: 흡연 상태 여부, 음주 상태 여부, 임신 여부(여성 회원에 한함)
     * 영양제 섭취 정보: 보관 중인 영양제 정보(제품명, 브랜드, 함량, 영양 성분), 일일 섭취 여부 및 섭취 주기 기록
3. **스토어 결제 및 배송 시 수집하는 개인정보 (상품 구매 시 수집)**
   * **수집 항목**:
     * 주문자 정보: 이름, 전화번호, 이메일
     * 배송 정보: 수령인 이름, 배송지 주소, 수령인 전화번호, 배송 메시지
     * 결제 정보: 결제수단 선택 정보 및 결제 승인 결과 데이터 (※ 단, 보안 신뢰성 확보를 위하여 실제 카드번호, 계좌번호, 결제 비밀번호 등 세부 결제 정보는 회사의 서버에 원천적으로 저장되지 않으며 결제 대행사(PG)를 통해 처리됩니다.)
     * [해외 직구 상품 구매 시] 개인통관고유부호 (관세법에 따른 필수 수집)
4. **서비스 이용 과정에서 자동 수집되는 정보**
   * **수집 항목**: IP 주소, 쿠키, 기기 정보(기기 모델명, OS 버전, ADID/IDFA 등 기기 식별자), 서비스 이용 기록(방문 일시, 검색 기록, 장바구니 담기, 클릭 행동 로그 등)
5. **개인정보 수집 방법**
   * 어플리케이션 설치 후 최초 소셜 가입 화면을 통한 연동 수집
   * 온보딩 건강 설문 과정에서 이용자의 직접 입력 및 터치 입력
   * 상품 구매 단계에서의 직접 기재 및 입력
   * 서비스 이용 과정에서 생성 정보 수집 툴을 통한 자동 기록 수집
   * 카메라 기능을 이용한 이미지 촬영 시(바코드/OCR 스캔) 일시적 이미지 처리 (※ 분석 목적으로 일시 활용될 뿐, 원본 촬영 이미지는 별도 서버에 저장되지 않고 즉시 파기됩니다.)

---

**제3조 (개인정보의 보유 및 이용 기간)**
1. 회사는 회원으로부터 개인정보 수집 시에 동의받은 보유 및 이용 기간 또는 법령에 따른 보유 및 이용 기간 내에서 개인정보를 처리하고 보유합니다.
2. 각각의 개인정보 보유 및 이용 기간은 다음과 같습니다.
   * **어플리케이션 가입 및 이용 정보**: **회원 탈퇴(이용계약 해지) 시까지**
   * 다만, 회원 탈퇴 시에도 관계 법령의 규정에 의하여 보존할 필요가 있는 경우, 회사는 아래와 같이 법령에서 정한 일정 기간 동안 회원 정보를 안전하게 보관합니다.
     * **『전자상거래 등에서의 소비자보호에 관한 법률』에 따른 보존**
       * 계약 또는 청약철회 등에 관한 기록: **5년**
       * 대금결제 및 재화 등의 공급에 관한 기록: **5년**
       * 소비자의 불만 또는 분쟁처리에 관한 기록: **3년**
       * 표시/광고에 관한 기록: **6개월**
     * **『통신비밀보호법』에 따른 보존**
       * 웹사이트/앱 방문 로그 기록: **3개월**

---

**제4조 (개인정보의 파기 절차 및 방법)**
1. 회사는 개인정보 보유기간의 경과, 처리 목적 달성 등 개인정보가 불필요하게 되었을 때에는 지체 없이 해당 개인정보를 파기합니다.
2. 회원이 회원 탈퇴를 요청하거나 개인정보 동의를 철회하는 경우 수집된 정보는 즉시 파기 프로세스에 진입합니다.
3. 파기 방법은 다음과 같습니다.
   * **전자적 파일 형태**: 복구 및 재생이 불가능하도록 기술적 방법(데이터 영구 삭제 등)을 사용하여 안전하게 파기합니다.
   * **인쇄물 또는 서면**: 종이 문서의 경우 분쇄기로 분쇄하거나 소각하여 완전히 파기합니다.

---

**제5조 (개인정보의 제3자 제공)**
1. 회사는 회원의 개인정보를 제1조(개인정보의 처리 목적)에서 명시한 범위 내에서만 처리하며, 회원의 사전 동의가 있거나 관련 법령의 특별한 규정이 있는 경우를 제외하고는 원칙적으로 제3자에게 개인정보를 제공하지 않습니다.
2. 단, 원활한 거래 이행과 배송을 위하여 구매 단계에서 동의를 얻은 후 아래와 같이 개인정보를 제공할 수 있습니다.
   * **제공받는 자**: 배송 대행 업체 및 택배사
   * **제공 목적**: 주문 상품 배송 및 위치 조회 서비스 제공
   * **제공 항목**: 수령인 이름, 배송지 주소, 전화번호, 배송 메시지
   * **보유 및 이용기간**: 배송 완료 후 목적 달성 즉시 파기 (단, 전자상거래법 등 관계 법령에 따른 보관 의무 기간 적용)

---

**제6조 (개인정보 처리의 위탁)**
1. 회사는 원활한 서비스 제공과 기술 인프라 운영을 위하여 개인정보 처리 업무 중 일부를 외부에 위탁하고 있습니다. 위탁 시 관련 법령에 따라 위탁 계약서 내에 개인정보 안전 관리 조치, 비밀유지 의무, 재위탁 금지 등을 명확히 규정하고 수탁자를 관리·감독합니다.
2. 현재 위탁하고 있는 대상 및 업무는 다음과 같습니다.
   * **위탁 대상 (수탁자)**: 클라우드 인프라 호스팅 제공사 (예: AWS 등)
     * **위탁 업무**: 서비스 데이터 보관 및 서버 인프라 안정성 유지
   * **위탁 대상 (수탁자)**: 알림톡 및 문자 발송 서비스 제공사
     * **위탁 업무**: 복용 알림 메세지 발송, 인증 문자 발송, 주문 정보 고지
   * **위탁 대상 (수탁자)**: PG 결제 대행사
     * **위탁 업무**: 스토어 상품 구매에 따른 카드/가상계좌 등 대금 결제 처리
   * **위탁 대상 (수탁자)**: AI API 서비스 파트너사
     * **위탁 업무**: AI 챗봇과의 대화 처리 (※ 이 경우 이용자가 직접 입력한 대화 텍스트만이 비식별화 처리되어 전달되며, 회원의 민감한 프로필이나 상세 건강 상태 정보는 원칙적으로 전송되지 않습니다.)

---

**제7조 (정보주체와 법정대리인의 권리·의무 및 행사방법)**
1. 회원은 회사에 대해 언제든지 다음 각 호의 개인정보 보호 관련 권리를 행사할 수 있습니다.
   * 개인정보 열람 요구
   * 오류 등이 있을 경우 정정 요구
   * 삭제 요구
   * 처리 정지 요구
2. 권리 행사는 회사에 대해 서면, 이메일, 고객센터 문의 등을 통하여 하실 수 있으며, 회사는 이에 대해 지체 없이 조치하겠습니다.
3. 회원이 개인정보의 오류에 대한 정정 및 삭제를 요구한 경우, 회사는 정정 및 삭제를 완료할 때까지 당해 개인정보를 이용하거나 제공하지 않습니다.
4. 만 14세 미만 아동의 가입 신청 시에는 법정대리인의 동의가 필수적이며, 법정대리인은 아동의 개인정보에 대하여 동일한 권리를 행사할 수 있습니다.

---

**제8조 (개인정보의 기술적·관리적 보호 조치)**
회사는 회원의 개인정보를 취급함에 있어 분실, 도난, 유출, 변조 또는 훼손되지 않도록 안전성 확보를 위하여 다음과 같은 기술적·관리적 대책을 강구하고 있습니다.

1. **개인정보 및 민감정보의 암호화**: 회원의 비밀번호, 소셜 고유 식별자, 건강 관련 민감 데이터는 대한민국 표준 암호화 알고리즘을 적용하여 안전하게 암호화되어 저장 및 관리됩니다.
2. **해킹 등에 대비한 기술적 대책**: 네트워크상의 개인정보를 안전하게 전송할 수 있도록 보안 통신 프로토콜(SSL/TLS)을 사용하며, 방화벽 및 침입 탐지 시스템을 설치하여 외부로부터의 무단 접근을 통제하고 있습니다.
3. **취급 직원의 최소화 및 교육**: 회사의 개인정보 취급 직원을 최소한으로 한정하며, 정기적인 개인정보 보호 교육을 실시하여 관리적 보안 의무를 강조하고 있습니다.
4. **접속 기록의 보관**: 개인정보처리시스템에 접속한 기록을 최소 1년 이상 보관·관리하여 위조, 변조, 도난, 분실되지 않도록 보관합니다.

---

**제9조 (개인정보 보호책임자 및 담당 부서)**
회사는 개인정보 처리에 관한 업무를 총괄해서 책임지고, 개인정보 처리와 관련한 정보주체의 불만처리 및 피해구제 등을 위하여 아래와 같이 개인정보 보호책임자를 지정하고 있습니다.

* **개인정보 보호책임자**
  * 부서/이름: OnePerDay 운영단 정보보호 담당자
  * 연락처: support@oneperday.kr (또는 어플리케이션 내 1:1 고객센터 문의)

회원은 회사의 서비스를 이용하시면서 발생한 모든 개인정보 보호 관련 문의, 불만 처리, 피해 구제 등에 관한 사항을 개인정보 보호책임자 및 담당 부서로 문의하실 수 있습니다. 회사는 회원의 문의에 대해 신속하고 성실하게 답변 및 처리해 드릴 것입니다.

---

**제10조 (개인정보 처리방침의 변경)**
1. 본 개인정보 처리방침은 적용일자로부터 시행됩니다.
2. 관계 법령의 개정, 정부의 보안 기술 지침 변경 또는 서비스 내용의 추가·삭제에 따라 개인정보 처리방침을 개정할 경우, 개정 적용일자 최소 7일 전부터 어플리케이션 고지사항을 통해 개정 사유와 내용을 고지할 것입니다.

**부칙**
본 개인정보 처리방침은 2026년 5월 28일부터 효력을 가집니다.
''';
