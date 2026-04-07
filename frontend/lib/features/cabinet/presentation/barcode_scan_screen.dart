import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:simcap/core/constant/app_constants.dart';

/// 바코드 스캔 결과
/// context.push('/cabinet/scan') 으로 진입,
/// context.pop(BarcodeScanResult) 으로 결과 반환
class BarcodeScanResult {
  final String rawValue; // 바코드 원본 값
  final BarcodeFormat format; // QR / EAN-13 / UPC-A 등

  const BarcodeScanResult({required this.rawValue, required this.format});
}

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

  bool _hasScanned = false; // 중복 감지 방지
  bool _isTorchOn = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 바코드 감지 콜백
  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;

    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    setState(() => _hasScanned = true);
    _controller.stop();

    // 진동 피드백 (선택 사항 — vibration 패키지 없이도 동작)
    _showResultSheet(barcode);
  }

  // 스캔 성공 후 결과 확인 Bottom Sheet
  void _showResultSheet(Barcode barcode) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isDismissible: false, // 배경 탭으로 닫기 방지
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 성공 아이콘
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

              // 인식된 바코드 값
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
                      _formatName(barcode.format),
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

              // 안내 문구
              Text(
                '이 바코드로 영양제 정보를 불러올게요',
                style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              ),
              const SizedBox(height: 24),

              // 버튼 영역
              Row(
                children: [
                  // 다시 스캔
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
                        Navigator.pop(context); // Sheet 닫기
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
                  // 이 바코드 사용
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
                        Navigator.pop(context); // Sheet 닫기
                        // 결과를 이전 화면(add_supplement_screen)으로 반환
                        context.pop(
                          BarcodeScanResult(
                            rawValue: barcode.rawValue!,
                            format: barcode.format,
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
        );
      },
    );
  }

  String _formatName(BarcodeFormat format) {
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
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          '바코드 스캔',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        // 플래시 토글 버튼
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
          // 카메라 미리보기
          MobileScanner(controller: _controller, onDetect: _onDetect),

          // 스캔 가이드 오버레이
          _buildScanOverlay(),
        ],
      ),
    );
  }

  Widget _buildScanOverlay() {
    return Column(
      children: [
        // 상단 어두운 영역
        Expanded(flex: 2, child: Container(color: Colors.black54)),

        // 중간 스캔 영역
        Row(
          children: [
            // 좌측 어두운 영역
            Expanded(child: Container(color: Colors.black54)),

            // 스캔 박스
            Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary, width: 2.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  // 모서리 강조선 4개
                  ..._buildCornerLines(),
                  // 스캔 중 애니메이션 라인
                  if (!_hasScanned) _buildScanLine(),
                ],
              ),
            ),

            // 우측 어두운 영역
            Expanded(child: Container(color: Colors.black54)),
          ],
        ),

        // 하단 안내 영역
        Expanded(
          flex: 3,
          child: Container(
            color: Colors.black54,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.qr_code_scanner,
                  color: Colors.white.withOpacity(0.8),
                  size: 32,
                ),
                const SizedBox(height: 16),
                Text(
                  '영양제 바코드를 박스 안에 맞춰주세요',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'EAN-13 · UPC-A · QR코드 지원',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 스캔 박스 모서리 강조선
  List<Widget> _buildCornerLines() {
    const double len = 24;
    const double thick = 3.5;
    const Color color = AppColors.primary;

    return [
      // 좌상단
      Positioned(
        top: 0,
        left: 0,
        child: _corner(len, thick, color, top: true, left: true),
      ),
      // 우상단
      Positioned(
        top: 0,
        right: 0,
        child: _corner(len, thick, color, top: true, left: false),
      ),
      // 좌하단
      Positioned(
        bottom: 0,
        left: 0,
        child: _corner(len, thick, color, top: false, left: true),
      ),
      // 우하단
      Positioned(
        bottom: 0,
        right: 0,
        child: _corner(len, thick, color, top: false, left: false),
      ),
    ];
  }

  Widget _corner(
    double len,
    double thick,
    Color color, {
    required bool top,
    required bool left,
  }) {
    return SizedBox(
      width: len,
      height: len,
      child: CustomPaint(
        painter: _CornerPainter(
          color: color,
          thick: thick,
          top: top,
          left: left,
        ),
      ),
    );
  }

  // 스캔 애니메이션 라인
  Widget _buildScanLine() {
    return _ScanLineAnimation();
  }
}

// 모서리선 CustomPainter
class _CornerPainter extends CustomPainter {
  final Color color;
  final double thick;
  final bool top;
  final bool left;

  _CornerPainter({
    required this.color,
    required this.thick,
    required this.top,
    required this.left,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thick
      ..strokeCap = StrokeCap.round;

    final double w = size.width;
    final double h = size.height;

    // 가로선
    canvas.drawLine(Offset(0, top ? 0 : h), Offset(w, top ? 0 : h), paint);
    // 세로선
    canvas.drawLine(Offset(left ? 0 : w, 0), Offset(left ? 0 : w, h), paint);
  }

  @override
  bool shouldRepaint(_CornerPainter old) => false;
}

// 스캔 라인 애니메이션
class _ScanLineAnimation extends StatefulWidget {
  @override
  State<_ScanLineAnimation> createState() => _ScanLineAnimationState();
}

class _ScanLineAnimationState extends State<_ScanLineAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _anim = Tween<double>(
      begin: 0.05,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Positioned(
        top: 260 * _anim.value - 1,
        left: 8,
        right: 8,
        child: Container(
          height: 2,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.85),
            borderRadius: BorderRadius.circular(1),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.4),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
