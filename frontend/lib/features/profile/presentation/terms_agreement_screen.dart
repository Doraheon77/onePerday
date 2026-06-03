import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simcap/core/constant/app_constants.dart';

class TermsAgreementScreen extends StatefulWidget {
  const TermsAgreementScreen({super.key});

  @override
  State<TermsAgreementScreen> createState() => _TermsAgreementScreenState();
}

class _TermsAgreementScreenState extends State<TermsAgreementScreen> {
  bool _agreeAll = false;
  bool _agreeTerms = false;
  bool _agreePrivacy = false;
  bool _agreeAge = false;

  void _updateAll(bool? val) {
    setState(() {
      _agreeAll = val ?? false;
      _agreeTerms = _agreeAll;
      _agreePrivacy = _agreeAll;
      _agreeAge = _agreeAll;
    });
  }

  void _updateItem() {
    setState(() {
      _agreeAll = _agreeTerms && _agreePrivacy && _agreeAge;
    });
  }

  bool get _canProceed => _agreeTerms && _agreePrivacy && _agreeAge;

  Future<void> _onAgree() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('termsAgreed', true);
    if (!mounted) return;
    context.go('/onboarding');
  }

  void _showPolicyDetail(String title, String content) {
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

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          '서비스 이용 동의',
          style: TextStyle(
            color: Colors.black,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          const Divider(height: 1),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 32),
                  // 헤더
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.medication_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'OnePerDay 시작하기',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '아래 약관에 동의하시면\n서비스를 이용하실 수 있습니다.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // 전체 동의
                  GestureDetector(
                    onTap: () => _updateAll(!_agreeAll),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: _agreeAll
                            ? AppColors.primaryLight
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _agreeAll
                              ? AppColors.primary
                              : Colors.grey.shade200,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _agreeAll
                                ? Icons.check_circle
                                : Icons.check_circle_outline,
                            color: _agreeAll
                                ? AppColors.primary
                                : Colors.grey.shade400,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            '전체 동의',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 8),

                  // 개별 항목
                  _buildAgreementItem(
                    value: _agreeTerms,
                    label: '서비스 이용 약관 동의',
                    required: true,
                    onChanged: (v) {
                      setState(() => _agreeTerms = v ?? false);
                      _updateItem();
                    },
                    onView: () => _showPolicyDetail('서비스 이용 약관', _termsContent),
                  ),
                  const SizedBox(height: 10),
                  _buildAgreementItem(
                    value: _agreePrivacy,
                    label: '개인정보 처리방침 동의',
                    required: true,
                    onChanged: (v) {
                      setState(() => _agreePrivacy = v ?? false);
                      _updateItem();
                    },
                    onView: () =>
                        _showPolicyDetail('개인정보 처리방침', _privacyContent),
                  ),
                  const SizedBox(height: 10),
                  _buildAgreementItem(
                    value: _agreeAge,
                    label: '만 14세 이상 확인',
                    required: true,
                    onChanged: (v) {
                      setState(() => _agreeAge = v ?? false);
                      _updateItem();
                    },
                  ),
                ],
              ),
            ),
          ),

          // 동의하고 시작하기 버튼
          Padding(
            padding: EdgeInsets.fromLTRB(24, 8, 24, bottomPad + 16),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _canProceed ? _onAgree : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: Colors.grey.shade300,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  '동의하고 시작하기',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgreementItem({
    required bool value,
    required String label,
    required bool required,
    required ValueChanged<bool?> onChanged,
    VoidCallback? onView,
  }) {
    return Row(
      children: [
        Checkbox(
          value: value,
          onChanged: (v) {
            onChanged(v);
            _updateItem();
          },
          activeColor: AppColors.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          side: BorderSide(color: Colors.grey.shade400),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            onTap: () => onChanged(!value),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 14, color: Colors.black87),
                children: [
                  if (required)
                    const TextSpan(
                      text: '[필수] ',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  TextSpan(text: label),
                ],
              ),
            ),
          ),
        ),
        if (onView != null)
          TextButton(
            onPressed: onView,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              '보기',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
      ],
    );
  }
}

// ── 약관 내용 ──────────────────────────────────────────────────────────────
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
