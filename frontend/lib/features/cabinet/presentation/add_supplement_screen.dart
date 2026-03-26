import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:simcap/features/cabinet/domain/dataModels/supplement_model.dart';

class AddSupplementScreen extends StatefulWidget {
  const AddSupplementScreen({super.key});

  @override
  State<AddSupplementScreen> createState() => _AddSupplementScreenState();
}

class _AddSupplementScreenState extends State<AddSupplementScreen> {
  bool _isInputVisible = true;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  bool _showNameError = false;

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

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  void _adjustQuantity(TextEditingController controller, int delta) {
    int currentValue = int.tryParse(controller.text) ?? 0;
    int newValue = (currentValue + delta).clamp(0, 999);
    controller.text = newValue.toString();
    setState(() {});
  }

  void _onRegister() {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      setState(() => _showNameError = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('제품명을 입력해주세요!'),
          backgroundColor: Color(0xFFFF6B6B),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // 데이터 모델 생성 (기존 로직)
    final newSupplement = Supplement(
      name: name,
      brand: _brandController.text.trim(),
      imagePath: _selectedImage?.path,
      remaining: int.tryParse(_remainingController.text) ?? 0,
      total: (int.tryParse(_remainingController.text) ?? 0) + 30,
      nutrients: _nutrientController.text
          .split(',')
          .where((e) => e.trim().isNotEmpty)
          .map(
            (e) => Nutrient(name: e.trim(), value: 0, unit: '', percent: 0.7),
          )
          .toList(),
      analysisGuide: "방금 등록된 영양제입니다.",
      aiSummary: "분석 데이터 준비 중",
    );

    FocusManager.instance.primaryFocus?.unfocus();

    if (mounted) {
      Navigator.pop(context, newSupplement);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          '영양제 등록',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildImageUploadSection(),
            const SizedBox(height: 24),

            _buildSectionTitle('기본 정보'),
            // 제품명 입력창에 에러 상태 연결
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
            _buildQuantityStepper('1회 복용량 (정/캡슐)', _dosageController),
            _buildQuantityStepper('하루 복용 횟수', _frequencyController),

            const SizedBox(height: 12),
            _buildRemainingQuantitySection(),

            const SizedBox(height: 40),
            _buildRegisterButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildImageUploadSection() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFEEEEEE)),
          image: _selectedImage != null
              ? DecorationImage(
                  image: FileImage(_selectedImage!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: _selectedImage == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.add_a_photo_rounded,
                    size: 40,
                    color: Color(0xFF4CAF50),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '라벨 사진 찍기 또는 업로드',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '자동으로 정보를 입력해드려요',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                ],
              )
            : Container(
                alignment: Alignment.bottomRight,
                padding: const EdgeInsets.all(12),
                child: CircleAvatar(
                  backgroundColor: Colors.black.withOpacity(0.5),
                  child: const Icon(Icons.edit, color: Colors.white),
                ),
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
        border: Border.all(color: const Color(0xFFEEEEEE)),
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
              color: Color(0xFF4CAF50),
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
                  selectedColor: const Color(0xFFE8F5E9),
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? const Color(0xFF4CAF50)
                        : Colors.black54,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: isSelected
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFFEEEEEE),
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
          color: hasError ? const Color(0xFFFF6B6B) : const Color(0xFFEEEEEE),
          width: hasError ? 1.5 : 1,
        ),
      ),
      child: TextField(
        controller: controller,
        onChanged: (val) {
          if (hasError && val.isNotEmpty) {
            setState(() => _showNameError = false);
          }
        },
        maxLines: isMultiLine ? 3 : 1,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
          border: InputBorder.none,
          // 에러 텍스트 표시
          errorText: hasError ? '제품명을 입력해 주세요' : null,
          errorStyle: const TextStyle(height: 0),
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
          backgroundColor: const Color(0xFF4CAF50),
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
