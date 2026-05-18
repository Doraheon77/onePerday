class SurveyOption {
  final String label;
  final String imagePath;

  SurveyOption({required this.label, required this.imagePath});
}

class SurveyData {
  static const String noneOptionHealth = '질환 없음';
  static const String noneOptionAllergy = '알레르기 없음';

  static final List<SurveyOption> genderOptions = [
    SurveyOption(label: '남성', imagePath: 'assets/images/male.png'),
    SurveyOption(label: '여성', imagePath: 'assets/images/female.png'),
  ];

  static final List<SurveyOption> goals = [
    SurveyOption(label: '눈 건강', imagePath: 'assets/images/eye.png'),
    SurveyOption(label: '관절 건강', imagePath: 'assets/images/bone.png'),
    SurveyOption(label: '면역력 증진', imagePath: 'assets/images/shield.png'),
    SurveyOption(label: '피로 회복', imagePath: 'assets/images/energy.png'),
    SurveyOption(label: '장 건강', imagePath: 'assets/images/stomach.png'),
    SurveyOption(label: '피부 개선', imagePath: 'assets/images/skin.png'),
    SurveyOption(label: '뼈/치아 건강', imagePath: 'assets/images/bone.png'),
    SurveyOption(label: '혈행 개선', imagePath: 'assets/images/blood.png'),
    SurveyOption(label: '두뇌/기억력 개선', imagePath: 'assets/images/brain.png'),
    SurveyOption(label: '다이어트', imagePath: 'assets/images/weight.png'),
    SurveyOption(label: '스트레스 케어', imagePath: 'assets/images/stress.png'),
    SurveyOption(label: '모발/손톱 영양', imagePath: 'assets/images/hair.png'),
    SurveyOption(label: '간 건강', imagePath: 'assets/images/liver.png'),
  ];

  static final List<SurveyOption> healthIssues = [
    SurveyOption(label: '고혈압', imagePath: 'assets/images/blood_pressure.png'),
    SurveyOption(label: '당뇨', imagePath: 'assets/images/diabetes.png'),
    SurveyOption(label: '고지혈증', imagePath: 'assets/images/blood.png'),
    SurveyOption(label: '심장 질환', imagePath: 'assets/images/heart.png'),
    SurveyOption(label: '신장 질환', imagePath: 'assets/images/kidney.png'),
    SurveyOption(label: '간 질환', imagePath: 'assets/images/liver.png'),
    SurveyOption(label: '갑상선 질환', imagePath: 'assets/images/thyroid.png'),
    SurveyOption(label: '골다공증', imagePath: 'assets/images/bone_loss.png'),
    SurveyOption(label: '관절염', imagePath: 'assets/images/bone.png'),
    SurveyOption(label: '빈혈', imagePath: 'assets/images/anemia.png'),
    // DB 미매핑으로 제외된 레거시 항목:
    // SurveyOption(label: '역류성 식도염', imagePath: 'assets/images/stomach_fire.png'),
    // SurveyOption(label: '통풍', imagePath: 'assets/images/gout.png'),
    // SurveyOption(label: '위염', imagePath: 'assets/images/gastritis.png'),
  ];

  static final List<SurveyOption> allergies = [
    SurveyOption(label: '갑각류', imagePath: 'assets/images/shrimp.png'),
    SurveyOption(label: '대두', imagePath: 'assets/images/soy.png'),
    SurveyOption(label: '우유', imagePath: 'assets/images/milk.png'),
    SurveyOption(label: '견과류', imagePath: 'assets/images/nut.png'),
    SurveyOption(label: '밀', imagePath: 'assets/images/wheat.png'),
    SurveyOption(label: '메밀', imagePath: 'assets/images/buckwheat.png'),
    SurveyOption(label: '달걀', imagePath: 'assets/images/egg.png'),
    SurveyOption(label: '고등어', imagePath: 'assets/images/fish.png'),
    // DB 미매핑으로 제외된 레거시 항목:
    // SurveyOption(label: '복숭아', imagePath: 'assets/images/peach.png'),
    // SurveyOption(label: '토마토', imagePath: 'assets/images/tomato.png'),
  ];
}
