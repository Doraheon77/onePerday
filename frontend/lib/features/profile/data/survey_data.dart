class SurveyOption {
  final String id; // DB name 컬럼 (영문, 백엔드 연동용)
  final String label; // 화면 표시 한글명
  final String imagePath;

  SurveyOption({
    required this.id,
    required this.label,
    required this.imagePath,
  });
}

class SurveyData {
  static const String noneOptionHealth = '질환 없음';
  static const String noneOptionAllergy = '알레르기 없음';

  // ── 성별 ─────────────────────────────────────────────────────────────────
  static final List<SurveyOption> genderOptions = [
    SurveyOption(
      id: 'male',
      label: '남성',
      imagePath: 'assets/images/sex/male.png',
    ),
    SurveyOption(
      id: 'female',
      label: '여성',
      imagePath: 'assets/images/sex/female.png',
    ),
  ];

  // ── 건강 목표 (health_goals_list 기준) ────────────────────────────────────
  static final List<SurveyOption> goals = [
    SurveyOption(
      id: 'energy',
      label: '활력/피로 개선',
      imagePath: 'assets/images/health_goal/energy.png',
    ),
    SurveyOption(
      id: 'eye_health',
      label: '눈 건강',
      imagePath: 'assets/images/health_goal/eye.png',
    ),
    SurveyOption(
      id: 'immunity',
      label: '면역력 증진',
      imagePath: 'assets/images/health_goal/shield.png',
    ),
    SurveyOption(
      id: 'gut_health',
      label: '장 건강',
      imagePath: 'assets/images/health_goal/stomach.png',
    ),
    SurveyOption(
      id: 'skin_health',
      label: '피부 개선',
      imagePath: 'assets/images/health_goal/skin.png',
    ),
    SurveyOption(
      id: 'weight_management',
      label: '체중 관리',
      imagePath: 'assets/images/health_goal/weight.png',
    ),
    SurveyOption(
      id: 'cardiovascular',
      label: '심혈관 건강',
      imagePath: 'assets/images/health_goal/blood.png',
    ),
    SurveyOption(
      id: 'joint_health',
      label: '관절 건강',
      imagePath: 'assets/images/health_goal/bone.png',
    ),
    SurveyOption(
      id: 'bone_health',
      label: '뼈/골다공증',
      imagePath: 'assets/images/health_goal/bone_loss.png',
    ),
    SurveyOption(
      id: 'brain_health',
      label: '두뇌/기억력',
      imagePath: 'assets/images/health_goal/brain.png',
    ),
    SurveyOption(
      id: 'sleep',
      label: '수면 개선',
      imagePath: 'assets/images/health_goal/stress.png',
    ),
    SurveyOption(
      id: 'hair_nail',
      label: '모발/손톱',
      imagePath: 'assets/images/health_goal/hair.png',
    ),
  ];

  // ── 만성질환 (chronic_conditions_list 기준) ───────────────────────────────
  static final List<SurveyOption> healthIssues = [
    SurveyOption(
      id: 'hypertension',
      label: '고혈압',
      imagePath: 'assets/images/chronic_condition/blood_pressure.png',
    ),
    SurveyOption(
      id: 'diabetes',
      label: '당뇨',
      imagePath: 'assets/images/chronic_condition/diabetes.png',
    ),
    SurveyOption(
      id: 'hyperlipidemia',
      label: '고지혈증',
      imagePath: 'assets/images/chronic_condition/cholesterol.png',
    ),
    SurveyOption(
      id: 'heart_disease',
      label: '심장질환',
      imagePath: 'assets/images/chronic_condition/heart.png',
    ),
    SurveyOption(
      id: 'kidney_disease',
      label: '신장질환',
      imagePath: 'assets/images/chronic_condition/kidney.png',
    ),
    SurveyOption(
      id: 'liver_disease',
      label: '간질환',
      imagePath: 'assets/images/chronic_condition/liver.png',
    ),
    SurveyOption(
      id: 'thyroid_disorder',
      label: '갑상선 질환',
      imagePath: 'assets/images/chronic_condition/thyroid.png',
    ),
    SurveyOption(
      id: 'osteoporosis',
      label: '골다공증',
      imagePath: 'assets/images/health_goal/bone_loss.png',
    ),
    SurveyOption(
      id: 'arthritis',
      label: '관절염',
      imagePath: 'assets/images/health_goal/bone.png',
    ),
    SurveyOption(
      id: 'anemia',
      label: '빈혈',
      imagePath: 'assets/images/chronic_condition/anemia.png',
    ),
  ];

  // ── 알레르기 (allergies_list 기준) ────────────────────────────────────────
  static final List<SurveyOption> allergies = [
    SurveyOption(
      id: 'nuts',
      label: '견과류',
      imagePath: 'assets/images/allergies_list/nut.png',
    ),
    SurveyOption(
      id: 'shellfish',
      label: '갑각류',
      imagePath: 'assets/images/allergies_list/shrimp.png',
    ),
    SurveyOption(
      id: 'fish',
      label: '생선',
      imagePath: 'assets/images/allergies_list/fish.png',
    ),
    SurveyOption(
      id: 'dairy',
      label: '유제품',
      imagePath: 'assets/images/allergies_list/milk.png',
    ),
    SurveyOption(
      id: 'eggs',
      label: '달걀',
      imagePath: 'assets/images/allergies_list/egg.png',
    ),
    SurveyOption(
      id: 'gluten',
      label: '글루텐',
      imagePath: 'assets/images/allergies_list/wheat.png',
    ),
    SurveyOption(
      id: 'soy',
      label: '대두',
      imagePath: 'assets/images/allergies_list/soy.png',
    ),
  ];
}
