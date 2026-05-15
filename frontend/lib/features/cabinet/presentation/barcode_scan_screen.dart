import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:simcap/core/constant/app_constants.dart';

/// 통합 스캔 결과
class ScanResult {
  final String? barcodeValue;
  final BarcodeFormat? barcodeFormat;
  final File? imageFile;

  const ScanResult({this.barcodeValue, this.barcodeFormat, this.imageFile});

  bool get isBarcode => barcodeValue != null;
  bool get isOCR => imageFile != null;
}

typedef BarcodeScanResult = ScanResult;

class BarcodeScanScreen extends StatefulWidget {
  const BarcodeScanScreen({super.key});

  @override
  State<BarcodeScanScreen> createState() => _BarcodeScanScreenState();
}

class _BarcodeScanScreenState extends State<BarcodeScanScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );
  final ImagePicker _picker = ImagePicker();

  bool _hasScanned = false;
  bool _isTorchOn = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ── 바코드 자동 감지 ─────────────────────────────────────────────────────
  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    setState(() => _hasScanned = true);
    _controller.stop();
    _showBarcodeResultSheet(barcode);
  }

  // ── 촬영 버튼 → 라벨 OCR ────────────────────────────────────────────────
  Future<void> _captureForOCR() async {
    _controller.stop();
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
    );
    if (image == null) {
      _controller.start();
      return;
    }
    if (!mounted) return;
    context.pop(ScanResult(imageFile: File(image.path)));
  }

  // ── 갤러리 선택 → OCR ────────────────────────────────────────────────────
  Future<void> _pickGalleryForOCR() async {
    _controller.stop();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) {
      _controller.start();
      return;
    }
    if (!mounted) return;
    context.pop(ScanResult(imageFile: File(image.path)));
  }

  // ── 바코드 인식 결과 바텀시트 ────────────────────────────────────────────
  void _showBarcodeResultSheet(Barcode barcode) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '바코드 인식 완료',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.scaffoldBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatBarcodeName(barcode.format),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    barcode.rawValue ?? '-',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '이 바코드로 영양제 정보를 불러올게요',
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() => _hasScanned = false);
                      _controller.start();
                    },
                    child: const Text(
                      '다시 스캔',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      context.pop(
                        ScanResult(
                          barcodeValue: barcode.rawValue!,
                          barcodeFormat: barcode.format,
                        ),
                      );
                    },
                    child: const Text(
                      '이 바코드 사용',
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

  String _formatBarcodeName(BarcodeFormat format) {
    switch (format) {
      case BarcodeFormat.ean13:
        return 'EAN-13 바코드';
      case BarcodeFormat.ean8:
        return 'EAN-8 바코드';
      case BarcodeFormat.upcA:
        return 'UPC-A 바코드';
      case BarcodeFormat.upcE:
        return 'UPC-E 바코드';
      case BarcodeFormat.qrCode:
        return 'QR 코드';
      case BarcodeFormat.code128:
        return 'Code 128';
      case BarcodeFormat.code39:
        return 'Code 39';
      default:
        return '바코드';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isTorchOn ? Icons.flash_on : Icons.flash_off,
              color: _isTorchOn ? Colors.yellow : Colors.white,
            ),
            onPressed: () {
              _controller.toggleTorch();
              setState(() => _isTorchOn = !_isTorchOn);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // 카메라 전체화면
          Positioned.fill(
            child: MobileScanner(controller: _controller, onDetect: _onDetect),
          ),

          // 하단 버튼 영역만
          Positioned(bottom: 0, left: 0, right: 0, child: _buildBottomBar()),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.only(
        bottom: bottomPad + 24,
        top: 20,
        left: 40,
        right: 40,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black.withOpacity(0.8), Colors.transparent],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 갤러리
          _bottomButton(
            icon: Icons.photo_library_outlined,
            label: '갤러리',
            size: 48,
            onTap: _pickGalleryForOCR,
          ),

          const SizedBox(width: 24),

          // 촬영 버튼 (메인)
          _bottomButton(
            icon: Icons.camera_alt_rounded,
            label: '라벨 촬영',
            size: 72,
            onTap: _captureForOCR,
            primary: true,
          ),

          const SizedBox(width: 24),

          // 빈 공간 (좌우 균형)
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _bottomButton({
    required IconData icon,
    required String label,
    required double size,
    required VoidCallback onTap,
    bool primary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primary ? Colors.white : Colors.white.withOpacity(0.2),
              border: Border.all(color: Colors.white, width: primary ? 0 : 1.5),
            ),
            child: Icon(
              icon,
              color: primary ? Colors.black87 : Colors.white,
              size: primary ? 32 : 22,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 11,
              fontWeight: primary ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
