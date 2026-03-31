import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
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
                            backgroundColor: const Color(0xFF4CAF50),
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
              child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
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
          backgroundColor: Color(0xFFE8F5E9),
          child: Icon(Icons.person, size: 40, color: Color(0xFF4CAF50)),
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
                    color: Color(0xFF4CAF50),
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
                            ? const Color(0xFFE8F5E9)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                        border: isGoal
                            ? Border.all(
                                color: const Color(0xFF4CAF50).withOpacity(0.2),
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
                              ? const Color(0xFF2E7D32)
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
                  : const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSmoker
                    ? Colors.orange.withOpacity(0.2)
                    : const Color(0xFF4CAF50).withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isSmoker ? Icons.smoking_rooms : Icons.smoke_free,
                  color: isSmoker ? Colors.orange : const Color(0xFF4CAF50),
                ),
                const SizedBox(width: 12),
                Text(
                  _smokingStatus,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isSmoker
                        ? Colors.orange.shade900
                        : const Color(0xFF2E7D32),
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
