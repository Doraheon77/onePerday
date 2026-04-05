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
  String _userName = '사용자';
  String _userAge = '';
  String _userGender = '미설정';
  List<String> _goals = [];
  List<String> _healthIssues = [];
  List<String> _allergies = [];

  String _smokingStatus = '비흡연자';
  String _drinkingStatus = '마시지 않음';
  String _pregnancyStatus = '해당 없음';

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? '사용자';
      _userAge = prefs.getString('userAge') ?? '';
      _userGender =
          prefs.getString('gender') ?? prefs.getString('userGender') ?? '미설정';

      _goals = prefs.getStringList('selectedGoals') ?? [];
      _healthIssues = prefs.getStringList('selectedHealth') ?? [];
      _allergies = prefs.getStringList('selectedAllergies') ?? [];

      _smokingStatus = prefs.getString('smokingStatus') ?? '비흡연자';
      _drinkingStatus = prefs.getString('drinkingStatus') ?? '마시지 않음';
      _pregnancyStatus = prefs.getString('pregnancyStatus') ?? '해당 없음';

      _isLoading = false;
    });
  }

  Future<void> _toggleLifestyle(
    String key,
    String currentVal,
    String optionA,
    String optionB,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    String newVal = (currentVal == optionA) ? optionB : optionA;
    await prefs.setString(key, newVal);
    await _loadProfileData();
  }

  Future<void> _updateData(String key, List<String> newData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(key, newData);
    await _loadProfileData();
  }

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
                          child: const Text('변경사항 저장하기'),
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
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
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
                  _buildBasicInfoSection(),
                  const SizedBox(height: 32),
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
                  const Text(
                    '생활 습관 및 환경',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildLifestyleToggleTile(
                    title: '흡연 여부',
                    value: _smokingStatus,
                    icon: Icons.smoking_rooms,
                    isActive: _smokingStatus == '흡연 중',
                    onTap: () => _toggleLifestyle(
                      'smokingStatus',
                      _smokingStatus,
                      '비흡연자',
                      '흡연 중',
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildLifestyleToggleTile(
                    title: '음주 여부',
                    value: _drinkingStatus,
                    icon: Icons.local_bar,
                    isActive: _drinkingStatus == '마시는 중',
                    onTap: () => _toggleLifestyle(
                      'drinkingStatus',
                      _drinkingStatus,
                      '마시지 않음',
                      '마시는 중',
                    ),
                  ),
                  if (_userGender == '여성' || _userGender == '미설정') ...[
                    const SizedBox(height: 12),
                    _buildLifestyleToggleTile(
                      title: '임신/수유 상태',
                      value: _pregnancyStatus,
                      icon: Icons.pregnant_woman,
                      isActive: _pregnancyStatus == '임신 중이다',
                      onTap: () => _toggleLifestyle(
                        'pregnancyStatus',
                        _pregnancyStatus,
                        '해당 없음',
                        '임신 중이다',
                      ),
                    ),
                  ],
                  const SizedBox(height: 40),
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
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  '나이',
                  _userAge.isNotEmpty ? '$_userAge세' : '미입력',
                ),
              ),
              Container(width: 1, height: 30, color: Colors.grey.shade300),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: _buildInfoItem('성별', _userGender),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildProfileSection(
    String title,
    List<String> items, {
    required VoidCallback onEdit,
    bool isGoal = false,
  }) {
    final bool isEmpty =
        items.isEmpty || (items.length == 1 && items[0].contains('없음'));
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

  Widget _buildLifestyleToggleTile({
    required String title,
    required String value,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFFFF3E0) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? Colors.orange.withOpacity(0.2)
                : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isActive ? Colors.orange : Colors.grey.shade600,
              size: 22,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Spacer(),
            const Icon(Icons.sync, color: Colors.grey, size: 18),
          ],
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
