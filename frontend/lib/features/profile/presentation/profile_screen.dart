import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:simcap/core/constant/app_constants.dart';
import 'package:simcap/providers/supplement_provider.dart';
import 'package:simcap/services/notification_service.dart';
import 'package:simcap/features/profile/widgets/survey_chip_group.dart';
import 'package:simcap/features/profile/data/survey_data.dart';
import 'package:simcap/services/auth_service.dart';

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
      _isLoading = false;
    });
  }

  // 데이터 수정 및 저장 함수
  Future<void> _updateData(String key, List<String> newData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(key, newData);
    await _loadProfileData();
  }

  // 생활 습관(흡연) 업데이트 함수
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
                    onEdit: () => _showEditModal(
                      title: '알레르기',
                      options: SurveyData.allergies,
                      currentSelected: _allergies,
                      storageKey: 'selectedAllergies',
                      noneOption: SurveyData.noneOptionAllergy,
                    ),
                  ),

                  // 7. 생활 습관 섹션
                  _buildLifestyleSection(),
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
              onPressed: () => context.push('/profile/my-reviews'),
              child: const Text(
                '전체보기',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
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
        ),
      ],
    );
  }

  // 구매 기록 섹션 — Provider 데이터 연동
  Widget _buildPurchaseHistorySection() {
    final purchases = SupplementProvider.of(context).purchases;
    final recentPurchases = purchases.take(2).toList();
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

  // 메뉴 버튼 공통 위젯
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
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              '취소',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              '로그아웃',
              style: TextStyle(fontWeight: FontWeight.bold),
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
}
