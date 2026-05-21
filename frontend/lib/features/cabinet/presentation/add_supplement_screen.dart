import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:simcap/core/constant/app_constants.dart';
import 'package:simcap/features/cabinet/domain/dataModels/supplement_model.dart';
import 'package:simcap/features/cabinet/presentation/barcode_scan_screen.dart';

// ── 탭 인덱스 상수 ───────────────────────────────────────────────────────────
// 0: 라벨 촬영  /  1: 바코드 스캔  /  2: 직접 입력
const int _tabLabel = 0;
const int _tabBarcode = 1;
const int _tabManual = 2;

class AddSupplementScreen extends StatefulWidget {
  /// 편집 모드: 기존 영양제 전달 시 폼에 데이터 자동 입력
  /// null이면 신규 등록 모드
  final Supplement? initialItem;

  const AddSupplementScreen({super.key, this.initialItem});

  @override
  State<AddSupplementScreen> createState() => _AddSupplementScreenState();
}

class _AddSupplementScreenState extends State<AddSupplementScreen>
    with SingleTickerProviderStateMixin {
  // ── 탭 상태 ─────────────────────────────────────────────────────────────
  late final TabController _tabController;
  int _selectedTab = _tabLabel; // 초기: 라벨 촬영

  // ── OCR 상태 ─────────────────────────────────────────────────────────────
  bool _isLoadingOCR = false;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  // ── 바코드 상태 ──────────────────────────────────────────────────────────
  String? _scannedBarcode;

  // ── 폼 상태 ─────────────────────────────────────────────────────────────
  bool _showNameError = false;
  MealTiming _selectedMealTiming = MealTiming.afterMeal;

  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _nutrientController = TextEditingController();
  int _dailyDose = 1; // 1회 복용량
  int _dailyFrequency = 1; // 하루 복용 횟수
  List<TimeOfDay> _alarmTimes = []; // 사용자 지정 알림 시간
  final _remainingController = TextEditingController(text: '30');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this)
      ..addListener(() {
        if (_tabController.indexIsChanging) return;
        setState(() => _selectedTab = _tabController.index);
      });

    // 편집 모드: 기존 데이터로 폼 초기화 + 직접 입력 탭으로 고정
    final item = widget.initialItem;
    if (item != null) {
      _nameController.text = item.name;
      _brandController.text = item.brand;
      _nutrientController.text = item.nutrients.map((n) => n.name).join(', ');
      _remainingController.text = item.remaining.toString();
      _dailyDose = item.dailyDose;
      _dailyFrequency = item.dailyFrequency;
      _alarmTimes = List.from(item.alarmTimes);
      _selectedMealTiming = item.mealTiming;
      // 편집 모드는 직접 입력 탭으로 시작
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _tabController.animateTo(_tabManual);
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _brandController.dispose();
    _nutrientController.dispose();
    _remainingController.dispose();
    super.dispose();
  }

  // ── OCR 처리 ─────────────────────────────────────────────────────────────
  Future<void> _processOCR(File imageFile) async {
    setState(() => _isLoadingOCR = true);
    try {
      // 실제 NestJS 백엔드 OCR API 호출 (동적 환경 주소 사용)
      final uri = Uri.parse('${AppConstants.apiBaseUrl}/supplements/ocr');
      final request = http.MultipartRequest('POST', uri);

      // 파일 추가
      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> result = json.decode(
          utf8.decode(response.bodyBytes),
        );

        if (!mounted) return;
        setState(() {
          _nameController.text = result['productName'] ?? '알 수 없는 영양제';
          _brandController.text = result['brandName'] ?? '알 수 없는 브랜드';
          _nutrientController.text = result['nutrients'] ?? '비타민C, 비타민D, 아연';
          _isLoadingOCR = false;
          // OCR 완료 → 직접 입력 탭으로 자동 이동
          _tabController.animateTo(_tabManual);
        });
      } else {
        throw Exception(
          'Server responded with status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('OCR Upload Error: $e');
      if (!mounted) return;
      setState(() => _isLoadingOCR = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OCR 분석에 실패했습니다. 내용을 직접 확인해주세요.')),
      );
      // 실패하더라도 사용자가 직접 입력할 수 있도록 탭 이동
      _tabController.animateTo(_tabManual);
    }
  }

  // ── 이미지 선택 ──────────────────────────────────────────────────────────
  Future<void> _pickFromCamera() async {
    // ---- 기존 코드 주석 처리 시작 ----
    // final XFile? image = await _picker.pickImage(
    //   source: ImageSource.camera,
    //   imageQuality: 90,
    // );
    // if (image != null) _handlePickedImage(File(image.path));
    // ---- 기존 코드 주석 처리 끝 ----

    // 앱 내장 카메라(In-App Camera) 화면으로 이동하여 결과 반환받기
    final imagePath = await context.push<String>('/cabinet/label-camera');
    if (imagePath != null && mounted) {
      _handlePickedImage(File(imagePath));
    }
  }

  Future<void> _pickFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) _handlePickedImage(File(image.path));
  }

  Future<void> _handlePickedImage(File imageFile) async {
    setState(() => _selectedImage = imageFile);
    await _processOCR(imageFile);
  }

  // ── 바코드 스캔 이동 ─────────────────────────────────────────────────────
  Future<void> _navigateToScan() async {
    final result = await context.push<BarcodeScanResult>('/cabinet/scan');
    if (result == null || !mounted) return;

    // TODO: result.rawValue로 백엔드 상품 조회 후 폼 자동 완성
    setState(() {
      _scannedBarcode = result.rawValue;
      _nameController.text = result.rawValue; // 임시 — API 연동 후 교체
      // 바코드 결과 수신 → 직접 입력 탭으로 이동
      _tabController.animateTo(_tabManual);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('바코드 인식 완료: ${result.rawValue}'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primary,
      ),
    );
  }

  // ── 수량 조절 ─────────────────────────────────────────────────────────────
  // ── 등록 ─────────────────────────────────────────────────────────────────
  void _onRegister() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _showNameError = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('제품명을 입력해주세요!'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final newSupplement = Supplement(
      name: name,
      brand: _brandController.text.trim(),
      imagePath: _selectedImage?.path,
      remaining: int.tryParse(_remainingController.text) ?? 0,
      total: (int.tryParse(_remainingController.text) ?? 0) + 30,
      dailyDose: _dailyDose,
      dailyFrequency: _dailyFrequency,
      alarmTimes: _alarmTimes,
      mealTiming: _selectedMealTiming,
      nutrients: _nutrientController.text
          .split(',')
          .where((e) => e.trim().isNotEmpty)
          .map(
            (e) => Nutrient(name: e.trim(), value: 0, unit: '', percent: 0.7),
          )
          .toList(),
      analysisGuide: '방금 등록된 영양제입니다.',
      aiSummary: '분석 데이터 준비 중',
    );

    FocusManager.instance.primaryFocus?.unfocus();
    if (mounted) Navigator.pop(context, newSupplement);
  }

  // ════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // ── 상단 탭바 ───────────────────────────────────────────────
          _buildTabBar(),
          const Divider(height: 1),
          // ── 탭 콘텐츠 ───────────────────────────────────────────────
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: _buildTabContent(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _selectedTab == _tabManual
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: _buildRegisterButton(),
              ),
            )
          : null,
    );
  }

  // ── AppBar ──────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    final isEditMode = widget.initialItem != null;
    const tabTitles = ['라벨 촬영', '바코드 스캔', '직접 입력'];
    return AppBar(
      title: Text(
        isEditMode ? '영양제 수정' : tabTitles[_selectedTab],
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  // ── 탭바 ────────────────────────────────────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: Colors.grey,
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          fontFamily: 'Pretendard',
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontFamily: 'Pretendard',
        ),
        indicatorColor: AppColors.primary,
        indicatorWeight: 2.5,
        tabs: const [
          Tab(icon: Icon(Icons.camera_alt_rounded, size: 18), text: '라벨 촬영'),
          Tab(
            icon: Icon(Icons.qr_code_scanner_rounded, size: 18),
            text: '바코드 스캔',
          ),
          Tab(icon: Icon(Icons.edit_note_rounded, size: 18), text: '직접 입력'),
        ],
      ),
    );
  }

  // ── 탭 콘텐츠 분기 ──────────────────────────────────────────────────────
  Widget _buildTabContent() {
    switch (_selectedTab) {
      case _tabLabel:
        return _buildLabelTab();
      case _tabBarcode:
        return _buildBarcodeTab();
      case _tabManual:
        return _buildManualTab();
      default:
        return _buildLabelTab();
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  //  탭 0 — 라벨 촬영
  // ════════════════════════════════════════════════════════════════════════
  Widget _buildLabelTab() {
    return SingleChildScrollView(
      key: const ValueKey('label'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          children: [
            // 라벨 프리뷰 / 촬영 유도 카드
            GestureDetector(
              onTap: _isLoadingOCR ? null : _pickFromCamera,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _isLoadingOCR
                        ? AppColors.primary
                        : AppColors.primary.withOpacity(0.2),
                    width: _isLoadingOCR ? 2 : 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: _isLoadingOCR
                    ? _buildOCRLoading()
                    : _selectedImage != null
                    ? _buildImagePreviewInCard()
                    : _buildLabelGuide(),
              ),
            ),
            const SizedBox(height: 24),

            // 카메라 / 갤러리 버튼 행
            if (!_isLoadingOCR) ...[
              Row(
                children: [
                  Expanded(
                    child: _buildSourceButton(
                      icon: Icons.camera_alt_rounded,
                      label: '카메라 촬영',
                      onTap: _pickFromCamera,
                      filled: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSourceButton(
                      icon: Icons.photo_library_outlined,
                      label: '갤러리 선택',
                      onTap: _pickFromGallery,
                      filled: false,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 선택된 이미지 있을 때 재선택 안내
              if (_selectedImage != null)
                TextButton(
                  onPressed: () => setState(() => _selectedImage = null),
                  child: Text(
                    '사진 다시 선택',
                    style: TextStyle(color: Colors.grey[500], fontSize: 13),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLabelGuide() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: AppColors.primaryLight,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.camera_alt_rounded,
            size: 52,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          '라벨을 촬영해주세요',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'AI가 성분 정보를 자동으로 분석해요',
          style: TextStyle(fontSize: 13, color: Colors.grey[500]),
        ),
        const SizedBox(height: 16),
        // 촬영 가이드 힌트
        _buildHintChip('영양제 라벨이 선명하게 보이도록 촬영하세요'),
      ],
    );
  }

  Widget _buildImagePreviewInCard() {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Image.file(_selectedImage!, fit: BoxFit.cover),
        ),
        // 어두운 오버레이 + 분석 완료 뱃지
        Positioned(
          bottom: 12,
          left: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
                SizedBox(width: 6),
                Text(
                  '분석 완료 — 직접 입력 탭에서 확인하세요',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOCRLoading() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(color: AppColors.primary),
        const SizedBox(height: 20),
        const Text(
          'AI가 성분을 분석하고 있어요...',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          '잠시만 기다려 주세요',
          style: TextStyle(fontSize: 13, color: Colors.grey[500]),
        ),
      ],
    );
  }

  Widget _buildSourceButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool filled,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: filled ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: filled ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: filled ? Colors.white : Colors.black87),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: filled ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHintChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.scaffoldBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.info_outline, size: 14, color: Colors.grey),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  //  탭 1 — 바코드 스캔
  // ════════════════════════════════════════════════════════════════════════
  Widget _buildBarcodeTab() {
    return SingleChildScrollView(
      key: const ValueKey('barcode'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          children: [
            // 스캔 안내 카드
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.shippingBg),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: AppColors.shippingBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.qr_code_scanner_rounded,
                      size: 52,
                      color: AppColors.shippingFg,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '바코드로 빠르게 등록',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '영양제 포장의 바코드를 스캔하면\n제품 정보를 자동으로 불러와요',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[500],
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // 스캔된 바코드 결과 표시
                  if (_scannedBarcode != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '인식된 바코드',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                                Text(
                                  _scannedBarcode!,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryDark,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // 초기화 버튼
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.grey,
                            ),
                            onPressed: () =>
                                setState(() => _scannedBarcode = null),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // 스캔 시작 버튼
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _navigateToScan,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.shippingFg,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.qr_code_scanner_rounded),
                      label: Text(
                        _scannedBarcode != null ? '다시 스캔하기' : '스캔 시작',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // 지원 바코드 안내
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'EAN-13 · UPC-A · QR코드 형식을 지원합니다',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  //  탭 2 — 직접 입력
  // ════════════════════════════════════════════════════════════════════════
  Widget _buildManualTab() {
    return ListView(
      key: const ValueKey('manual'),
      padding: const EdgeInsets.all(20),
      children: [
        // OCR/바코드로 이미지 선택된 경우 미리보기 표시
        if (_selectedImage != null) _buildSelectedImagePreview(),

        // 바코드 인식 결과 뱃지
        if (_scannedBarcode != null) _buildBarcodeBadge(),

        _buildSectionTitle('기본 정보'),
        _buildInputField(
          '제품명 입력',
          _nameController,
          hasError: _showNameError && _nameController.text.isEmpty,
        ),
        _buildInputField('브랜드명 입력 (선택사항)', _brandController),
        _buildInputField(
          '주요 성분 (예: 비타민C, 아연)',
          _nutrientController,
          isMultiLine: true,
        ),

        const SizedBox(height: 24),
        _buildSectionTitle('복용 및 수량 설정'),
        _buildMealTimingSelector(),
        _buildQuantityStepper(
          '1회 복용량 (정/캡슐)',
          _dailyDose,
          (v) => setState(() => _dailyDose = v),
        ),
        _buildQuantityStepper('하루 복용 횟수', _dailyFrequency, (v) {
          setState(() {
            _dailyFrequency = v;
            // 횟수가 바뀌면 알림 시간 초기화 (기본값으로)
            _alarmTimes = [];
          });
        }),

        const SizedBox(height: 8),
        _buildAlarmTimesSection(),

        const SizedBox(height: 12),
        _buildRemainingQuantitySection(),
        const SizedBox(height: 40),
      ],
    );
  }

  // 바코드 인식 결과 뱃지 (직접 입력 탭 상단)
  Widget _buildBarcodeBadge() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.shippingBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.barcodeBorder),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.qr_code_scanner_rounded,
            size: 16,
            color: AppColors.shippingFg,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '바코드 인식됨: $_scannedBarcode',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.shippingFg,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  //  공통 위젯
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildSelectedImagePreview() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              _selectedImage!,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '사진 업로드 완료',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '정보가 자동으로 입력되었습니다',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _selectedImage = null),
            icon: const Icon(Icons.close, size: 20, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildMealTimingSelector() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '복용 시점',
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Row(
            children: MealTiming.values.map((timing) {
              final isSelected = _selectedMealTiming == timing;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedMealTiming = timing),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.dividerBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _mealTimingIcon(timing),
                          size: 18,
                          color: isSelected ? Colors.white : Colors.grey[500],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          timing.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  IconData _mealTimingIcon(MealTiming timing) {
    switch (timing) {
      case MealTiming.beforeMeal:
        return Icons.lunch_dining_outlined;
      case MealTiming.afterMeal:
        return Icons.restaurant_outlined;
      case MealTiming.beforeSleep:
        return Icons.bedtime_outlined;
      case MealTiming.anytime:
        return Icons.access_time_outlined;
    }
  }

  Widget _buildInputField(
    String hint,
    TextEditingController controller, {
    bool isMultiLine = false,
    bool isNumber = false,
    bool hasError = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: hasError ? AppColors.danger : AppColors.border,
          width: hasError ? 1.5 : 1,
        ),
      ),
      child: TextField(
        controller: controller,
        onChanged: (val) {
          if (hasError && val.isNotEmpty)
            setState(() => _showNameError = false);
        },
        maxLines: isMultiLine ? 3 : 1,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
          border: InputBorder.none,
          errorText: hasError ? '제품명을 입력해 주세요' : null,
          errorStyle: const TextStyle(height: 0),
        ),
      ),
    );
  }

  Widget _buildQuantityStepper(
    String label,
    int value,
    void Function(int) onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          // 감소 버튼
          GestureDetector(
            onTap: () {
              if (value > 1) onChanged(value - 1);
            },
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: value > 1 ? Colors.grey : Colors.grey.shade300,
                ),
              ),
              child: Icon(
                Icons.remove,
                size: 16,
                color: value > 1 ? Colors.grey : Colors.grey.shade300,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 숫자 표시
          Container(
            width: 44,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$value',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 증가 버튼
          GestureDetector(
            onTap: () {
              if (value < 99) onChanged(value + 1);
            },
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary),
              ),
              child: const Icon(Icons.add, size: 16, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  // ── 알림 시간 설정 섹션 ────────────────────────────────────────────────
  Widget _buildAlarmTimesSection() {
    final defaultTimes = _getDefaultPreviewTimes();
    final displayTimes = _alarmTimes.isNotEmpty ? _alarmTimes : defaultTimes;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.alarm, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  '복용 알림 시간',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              if (_alarmTimes.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: const Text(
                    '기본값',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else
                TextButton(
                  onPressed: () => setState(() => _alarmTimes = []),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    '초기화',
                    style: TextStyle(fontSize: 12, color: AppColors.danger),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...List.generate(displayTimes.length, (i) {
                final time = displayTimes[i];
                final isCustom = _alarmTimes.isNotEmpty;
                return GestureDetector(
                  onTap: () => _pickAlarmTime(i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isCustom
                          ? AppColors.primary
                          : AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(
                        color: isCustom
                            ? AppColors.primary
                            : AppColors.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: isCustom ? Colors.white : AppColors.primary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _formatTime(time),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isCustom
                                ? Colors.white
                                : AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              if (_alarmTimes.isEmpty)
                GestureDetector(
                  onTap: () async {
                    final defaults = _getDefaultPreviewTimes();
                    setState(() => _alarmTimes = List.from(defaults));
                    await _pickAlarmTime(0);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit_outlined, size: 14, color: Colors.grey),
                        SizedBox(width: 5),
                        Text(
                          '직접 설정',
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _alarmTimes.isEmpty
                ? '기본 시간으로 알림이 설정됩니다. 탭해서 직접 설정하세요.'
                : '알림 시간을 탭하면 변경할 수 있습니다.',
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  List<TimeOfDay> _getDefaultPreviewTimes() {
    switch (_dailyFrequency) {
      case 1:
        switch (_selectedMealTiming) {
          case MealTiming.beforeMeal:
            return [const TimeOfDay(hour: 7, minute: 30)];
          case MealTiming.afterMeal:
            return [const TimeOfDay(hour: 8, minute: 30)];
          case MealTiming.beforeSleep:
            return [const TimeOfDay(hour: 22, minute: 0)];
          case MealTiming.anytime:
            return [const TimeOfDay(hour: 9, minute: 0)];
        }
      case 2:
        return [
          const TimeOfDay(hour: 8, minute: 0),
          const TimeOfDay(hour: 19, minute: 0),
        ];
      case 3:
        return [
          const TimeOfDay(hour: 8, minute: 0),
          const TimeOfDay(hour: 13, minute: 0),
          const TimeOfDay(hour: 19, minute: 0),
        ];
      default:
        return List.generate(
          _dailyFrequency,
          (i) => TimeOfDay(hour: (8 + i * 4) % 24, minute: 0),
        );
    }
  }

  Future<void> _pickAlarmTime(int index) async {
    final currentTimes = _alarmTimes.isNotEmpty
        ? _alarmTimes
        : _getDefaultPreviewTimes();
    final initial = index < currentTimes.length
        ? currentTimes[index]
        : const TimeOfDay(hour: 9, minute: 0);

    final picked = await showDialog<TimeOfDay>(
      context: context,
      builder: (_) => _DrumRollTimePicker(initialTime: initial),
    );

    if (picked != null && mounted) {
      setState(() {
        if (_alarmTimes.isEmpty) {
          _alarmTimes = List.from(_getDefaultPreviewTimes());
        }
        if (index < _alarmTimes.length) {
          _alarmTimes[index] = picked;
        } else {
          _alarmTimes.add(picked);
        }
      });
    }
  }

  String _formatTime(TimeOfDay time) {
    final period = time.hour < 12 ? '오전' : '오후';
    final h = time.hour == 0
        ? 12
        : time.hour <= 12
        ? time.hour
        : time.hour - 12;
    final m = time.minute.toString().padLeft(2, '0');
    return '$period $h:$m';
  }

  Widget _buildRemainingQuantitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputField(
          '현재 남은 수량 (정/캡슐)',
          _remainingController,
          isNumber: true,
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [30, 60, 90, 120, 180].map((val) {
              final isSelected = _remainingController.text == val.toString();
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text('$val정'),
                  selected: isSelected,
                  onSelected: (_) => setState(
                    () => _remainingController.text = val.toString(),
                  ),
                  selectedColor: AppColors.primaryLight,
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.primary : Colors.black54,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : AppColors.border,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.black54,
        ),
      ),
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _onRegister,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Text(
          widget.initialItem != null ? '수정 완료' : '캐비닛에 추가하기',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ── 드럼롤 스타일 시간 선택 다이얼로그 ────────────────────────────────────────
class _DrumRollTimePicker extends StatefulWidget {
  final TimeOfDay initialTime;
  const _DrumRollTimePicker({required this.initialTime});

  @override
  State<_DrumRollTimePicker> createState() => _DrumRollTimePickerState();
}

class _DrumRollTimePickerState extends State<_DrumRollTimePicker> {
  late int _hour; // 1 ~ 12
  late int _minute; // 0 ~ 59
  late bool _isAm;

  late FixedExtentScrollController _hourCtrl;
  late FixedExtentScrollController _minuteCtrl;
  late FixedExtentScrollController _periodCtrl;

  static const double _itemH = 52.0;
  static const int _loopCount = 100; // 무한 스크롤 효과용 반복 수

  @override
  void initState() {
    super.initState();
    final h = widget.initialTime.hour;
    _isAm = h < 12;
    _hour = h == 0
        ? 12
        : h > 12
        ? h - 12
        : h;
    _minute = widget.initialTime.minute;

    // 가운데 위치에서 시작 (무한 스크롤 효과)
    final hourMid = (_loopCount ~/ 2) * 12 + (_hour - 1);
    final minuteMid = (_loopCount ~/ 2) * 60 + _minute;

    _hourCtrl = FixedExtentScrollController(initialItem: hourMid);
    _minuteCtrl = FixedExtentScrollController(initialItem: minuteMid);
    _periodCtrl = FixedExtentScrollController(initialItem: _isAm ? 0 : 1);
  }

  @override
  void dispose() {
    _hourCtrl.dispose();
    _minuteCtrl.dispose();
    _periodCtrl.dispose();
    super.dispose();
  }

  TimeOfDay get _result {
    int h = _hour % 12;
    if (!_isAm) h += 12;
    return TimeOfDay(hour: h, minute: _minute);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 제목
            const Text(
              '알림 시간 설정',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // 드럼롤 휠
            SizedBox(
              height: _itemH * 3,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 선택 영역 하이라이트
                  Container(
                    height: _itemH,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  Row(
                    children: [
                      // 오전/오후
                      Expanded(
                        flex: 3,
                        child: _buildWheel(
                          controller: _periodCtrl,
                          itemCount: 2,
                          looped: false,
                          onSelected: (i) => setState(() => _isAm = i == 0),
                          builder: (i) => _wheelItem(
                            i == 0 ? '오전' : '오후',
                            selected: (_isAm ? 0 : 1) == i,
                          ),
                        ),
                      ),
                      // 시
                      Expanded(
                        flex: 3,
                        child: _buildWheel(
                          controller: _hourCtrl,
                          itemCount: 12 * _loopCount,
                          looped: true,
                          onSelected: (i) => setState(() => _hour = i % 12 + 1),
                          builder: (i) => _wheelItem(
                            '${i % 12 + 1}',
                            selected: (i % 12 + 1) == _hour,
                            large: true,
                          ),
                        ),
                      ),
                      // 구분자
                      const Text(
                        ':',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      // 분
                      Expanded(
                        flex: 3,
                        child: _buildWheel(
                          controller: _minuteCtrl,
                          itemCount: 60 * _loopCount,
                          looped: true,
                          onSelected: (i) => setState(() => _minute = i % 60),
                          builder: (i) => _wheelItem(
                            (i % 60).toString().padLeft(2, '0'),
                            selected: (i % 60) == _minute,
                            large: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // 상단/하단 그라데이션 페이드
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Column(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.white,
                                    Colors.white.withOpacity(0.0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: _itemH),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Colors.white,
                                    Colors.white.withOpacity(0.0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 버튼
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    child: const Text(
                      '취소',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, _result),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    child: const Text(
                      '확인',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWheel({
    required FixedExtentScrollController controller,
    required int itemCount,
    required bool looped,
    required void Function(int) onSelected,
    required Widget Function(int) builder,
  }) {
    return ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: _itemH,
      diameterRatio: 1.4,
      perspective: 0.003,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: onSelected,
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: itemCount,
        builder: (_, i) => builder(i),
      ),
    );
  }

  Widget _wheelItem(String text, {bool selected = false, bool large = false}) {
    return Center(
      child: Text(
        text,
        style: TextStyle(
          fontSize: large ? 26 : 18,
          fontWeight: selected ? FontWeight.bold : FontWeight.w400,
          color: selected ? AppColors.primary : Colors.grey[400],
        ),
      ),
    );
  }
}
