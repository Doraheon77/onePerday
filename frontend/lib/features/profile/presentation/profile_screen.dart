import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:simcap/core/constant/app_constants.dart';
import 'package:simcap/features/profile/widgets/survey_chip_group.dart';
import 'package:simcap/features/profile/data/survey_data.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // 데이터 상태 변수
  String _userName = '사용자';
  String _userAge = '';
  String _userGender = '미설정';
  List<String> _goals = [];
  List<String> _healthIssues = [];
  List<String> _allergies = [];
  String _smokingStatus = '비흡연자입니다';
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

                  // 2. 건강 목표 섹션
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

                  // 3. 질환 섹션
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

                  // 4. 알레르기 섹션
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

                  // 5. 생활 습관 섹션
                  _buildLifestyleSection(),

                  const SizedBox(height: 32),

                  // 6. 구매 기록 섹션
                  _buildPurchaseHistorySection(),

                  const SizedBox(height: 40),

                  // 메뉴 버튼들
                  _buildMenuButton(
                    '설문 데이터 다시하기',
                    Icons.refresh,
                    onTap: () => context.go('/onboarding'),
                  ),
                  _buildMenuButton('앱 설정', Icons.settings, onTap: () {}),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '생활 습관',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () {
            final newStatus = isSmoker ? '비흡연자입니다' : '흡연자입니다';
            _updateSmokingStatus(newStatus);
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isSmoker
                  ? const Color(0xFFFFF3E0)
                  : AppColors.primaryLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSmoker
                    ? Colors.orange.withOpacity(0.2)
                    : AppColors.primary.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isSmoker ? Icons.smoking_rooms : Icons.smoke_free,
                  color: isSmoker ? Colors.orange : AppColors.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  _smokingStatus,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isSmoker
                        ? Colors.orange.shade900
                        : AppColors.primaryDark,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.sync, size: 18, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 구매 기록 섹션
  Widget _buildPurchaseHistorySection() {
    // TODO: 백엔드 연동 후 실제 구매 기록 데이터로 교체
    // 예: final List<PurchaseRecord> _purchases = await PurchaseApi.getHistory();
    const bool hasData = false;

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
            // 전체보기 버튼 — 백엔드 연동 후 활성화
            TextButton(
              onPressed: null, // TODO: 전체 구매 기록 페이지로 이동
              child: Text(
                '전체보기',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (hasData)
          // 데이터 있을 때 — 백엔드 연동 후 실제 아이템으로 교체
          _buildPurchaseItem(
            productName: '예시 영양제',
            brand: '브랜드명',
            price: 28000,
            date: DateTime(2026, 3, 15),
            status: '배송 완료',
          )
        else
          _buildPurchaseEmptyState(),
      ],
    );
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
          OutlinedButton.icon(
            onPressed: () => context.go('/store'),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            icon: const Icon(
              Icons.storefront_outlined,
              size: 16,
              color: AppColors.primary,
            ),
            label: const Text(
              '스토어 바로가기',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
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
              color: isDelivered
                  ? AppColors.primaryLight
                  : const Color(0xFFFFF3CD),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isDelivered
                    ? AppColors.primaryDark
                    : const Color(0xFF8a6200),
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
