import 'dart:io';
import 'package:simcap/core/constant/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:simcap/features/cabinet/domain/dataModels/supplement_model.dart';

class AddSupplementScreen extends StatefulWidget {
  const AddSupplementScreen({super.key});

  @override
  State<AddSupplementScreen> createState() => _AddSupplementScreenState();
}

class _AddSupplementScreenState extends State<AddSupplementScreen> {
  // 화면 모드 제어 (false: 사진 업로드 대기, true: 입력 폼)
  bool _isManualInputMode = false;
  // OCR 분석 중 로딩 상태
  bool _isLoadingOCR = false;

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  bool _showNameError = false;
  MealTiming _selectedMealTiming = MealTiming.afterMeal; // 기본값: 식후

  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _nutrientController = TextEditingController();
  final _dosageController = TextEditingController(text: '1');
  final _frequencyController = TextEditingController(text: '1');
  final _remainingController = TextEditingController(text: '30');

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _nutrientController.dispose();
    _dosageController.dispose();
    _frequencyController.dispose();
    _remainingController.dispose();
    super.dispose();
  }

  // OCR 연동 로직
  Future<void> _processOCR(File imageFile) async {
    setState(() => _isLoadingOCR = true);

    try {
      // TODO : 팀원이 만든 OCR 분석 함수를 여기서 호출 필요
      // 예: final result = await YourTeamMemberOCRService.analyze(imageFile);

      // (가짜 데이터 시뮬레이션 - 2초 대기)
      await Future.delayed(const Duration(seconds: 2));

      // 가짜 분석 데이터를 화면에 반영 (실제 결과로 교체 필요)
      setState(() {
        _nameController.text = "멀티비타민 골드"; // result.productName으로 추후 교체
        _brandController.text = "시뮬레이션 브랜드"; // result.brandName으로 추후 교체
        _nutrientController.text =
            "비타민C, 비타민D, 아연"; // result.nutrients.join(', ')

        _isLoadingOCR = false;
        _isManualInputMode = true; // 분석 완료 후 입력 폼으로 전환
      });
    } catch (e) {
      setState(() => _isLoadingOCR = false);
      // 에러 발생 시 사용자에게 알리고 수동 모드로 전환
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OCR 분석에 실패했습니다. 내용을 직접 확인해주세요.')),
      );
      setState(() => _isManualInputMode = true);
    }
  }

  // 갤러리에서 사진 선택
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final imageFile = File(image.path);
      setState(() {
        _selectedImage = imageFile;
      });
      // 사진 선택 직후 OCR 프로세스 시작
      await _processOCR(imageFile);
    }
  }

  // 수량 조절 로직
  void _adjustQuantity(TextEditingController controller, int delta) {
    int currentValue = int.tryParse(controller.text) ?? 0;
    int newValue = (currentValue + delta).clamp(0, 999);
    controller.text = newValue.toString();
    setState(() {});
  }

  // 등록 버튼 클릭 로직
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
      dailyDose: int.tryParse(_dosageController.text) ?? 1,
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

    if (mounted) {
      Navigator.pop(context, newSupplement);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: Text(
          _isManualInputMode ? '정보 입력' : '영양제 등록',
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
          onPressed: () {
            if (_isManualInputMode && _selectedImage == null) {
              setState(() => _isManualInputMode = false);
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _isManualInputMode
              ? _buildManualInputForm()
              : _buildAutoUploadView(),
        ),
      ),
      bottomNavigationBar: _isManualInputMode
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

  // 자동 업로드 (OCR 로딩 포함)
  Widget _buildAutoUploadView() {
    return Column(
      key: const ValueKey('auto'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Center(
          child: GestureDetector(
            onTap: _isLoadingOCR ? null : _pickImage,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              height: 350,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.1),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: _isLoadingOCR
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'AI가 성분을 분석하고 있어요...',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '잠시만 기다려 주세요',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    )
                  : Column(
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
                            size: 60,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          '라벨 촬영하기',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '영양제 라벨을 찍으면\nAI가 정보를 자동으로 입력해요',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
        const SizedBox(height: 40),
        if (!_isLoadingOCR)
          TextButton(
            onPressed: () => setState(() => _isManualInputMode = true),
            child: const Text(
              '직접 입력할게요',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 15,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
      ],
    );
  }

  // 정보 입력 폼
  Widget _buildManualInputForm() {
    return ListView(
      key: const ValueKey('manual'),
      padding: const EdgeInsets.all(20),
      children: [
        if (_selectedImage != null) _buildSelectedImagePreview(),

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
        _buildQuantityStepper('1회 복용량 (정/캡슐)', _dosageController),
        _buildQuantityStepper('하루 복용 횟수', _frequencyController),

        const SizedBox(height: 12),
        _buildRemainingQuantitySection(),
        const SizedBox(height: 40),
      ],
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

  Widget _buildSelectedImagePreview() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
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
            onPressed: () => setState(() {
              _selectedImage = null;
              // 사진 삭제 시 컨트롤러 값도 지울지 여부는 선택사항입니다.
            }),
            icon: const Icon(Icons.close, size: 20, color: Colors.grey),
          ),
        ],
      ),
    );
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

  Widget _buildQuantityStepper(String label, TextEditingController controller) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, color: Colors.grey),
            onPressed: () => _adjustQuantity(controller, -1),
          ),
          SizedBox(
            width: 40,
            child: TextField(
              controller: controller,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(border: InputBorder.none),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.add_circle_outline,
              color: AppColors.primary,
            ),
            onPressed: () => _adjustQuantity(controller, 1),
          ),
        ],
      ),
    );
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
              bool isSelected = _remainingController.text == val.toString();
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
        child: const Text(
          '캐비닛에 추가하기',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
