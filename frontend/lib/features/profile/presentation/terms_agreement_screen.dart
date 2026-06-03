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
const String _termsContent = '''OnePerDay 서비스 이용 약관

제1장 총칙

제1조 (목적)
본 약관은 "OnePerDay 팀"(이하 "회사"라 합니다)이 제공하는 스마트폰 어플리케이션 "OnePerDay" 및 관련 제반 서비스의 이용과 관련하여, 회사와 회원 간의 권리, 의무 및 책임사항, 서비스 이용 조건 및 절차 등 기본적인 사항을 규정함을 목적으로 합니다.

제2조 (용어의 정의)
1. "서비스"라 함은 회사가 스마트 기기를 통해 회원에게 제공하는 건강 맞춤 온보딩 설문 분석, 내 영양제 약장 관리, 바코드/OCR 스캔 제품 등록, 장바구니 안전성 검사, AI 챗봇 상담, 영양제 제품 검색 및 쇼핑 스토어 등 OnePerDay 어플리케이션 내의 모든 제반 서비스를 의미합니다.
2. "회원"이라 함은 본 약관에 동의하고 서비스에 가입하여 회사가 제공하는 서비스를 이용하는 고객을 말합니다.

제3조 (약관의 명시, 효력 및 개정)
회사는 관계법령을 위배하지 않는 범위에서 본 약관을 개정할 수 있으며, 개정 시 적용일자 7일 전부터 어플리케이션 내 고지사항을 통해 공지합니다.

제7조 (의학적 면책 조항)
[중요] 본 서비스에서 제공하는 건강 및 영양 정보는 정보 제공 및 일반 웰니스 관리 목적으로만 제공되며, 어떠한 경우에도 전문 의료진의 의학적 소견, 진료, 진단, 처방 또는 전문적 치료를 대체할 수 없습니다.

제10조 (청약철회 및 환불)
상품을 구매한 회원은 전자상거래법에 따라 상품 수령일로부터 7일 이내에 청약의 철회를 신청할 수 있습니다.

제15조 (준거법 및 관할법원)
회사와 회원 간에 제기된 소송은 대한민국 법을 준거법으로 하며, 서울중앙지방법원을 제1심 합의관할 법원으로 합니다.

본 약관은 2026년 5월 28일부터 효력을 가집니다.''';

const String _privacyContent = '''OnePerDay 개인정보 처리 방침

제1조 (개인정보의 처리 목적)
회사는 다음의 목적을 위하여 회원의 개인정보를 처리합니다.
1. 회원 가입 및 관리
2. 개인 맞춤 건강 가이드 및 분석 서비스 제공
3. 장바구니 안전성 검사 서비스 제공
4. AI 챗봇 상담 및 서비스 개선
5. 스토어 주문, 대금 결제 및 배송

제2조 (개인정보의 수집 항목)
■ 회원 가입 시: 소셜 연동 식별자, 닉네임, 이메일 주소
■ 건강 분석 서비스: 나이, 성별, 건강 상태, 생활 습관, 영양제 섭취 정보 (선택 동의)
■ 구매 시: 이름, 전화번호, 배송지 주소, 결제 수단 선택 정보

제3조 (개인정보의 보유 및 이용 기간)
■ 회원 탈퇴 시까지 보관
■ 전자상거래법에 따라 거래 기록은 5년간 보관

제4조 (개인정보의 파기)
개인정보가 불필요하게 되었을 때 지체 없이 파기합니다.

제7조 (정보주체의 권리)
회원은 언제든지 개인정보 열람, 정정, 삭제, 처리 정지를 요구할 수 있습니다.

■ 개인정보 보호책임자 연락처: support@oneperday.kr

본 개인정보 처리방침은 2026년 5월 28일부터 효력을 가집니다.''';
