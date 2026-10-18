import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/ocr_service.dart';
import 'review_receipt_screen.dart';

class ScanReceiptScreen extends StatefulWidget {
  const ScanReceiptScreen({super.key});

  @override
  State<ScanReceiptScreen> createState() => _ScanReceiptScreenState();
}

class _ScanReceiptScreenState extends State<ScanReceiptScreen> {
  final ImagePicker _picker = ImagePicker();
  final OcrService _ocrService = OcrService();
  bool _isProcessing = false;
  String _statusMessage = '';

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _pickAndProcessImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() {
        _isProcessing = true;
        _statusMessage = 'Đang nhận diện chữ viết qua ML Kit On-device...';
      });

      final parsedData = await _ocrService.processImage(pickedFile.path);

      if (!mounted) return;

      setState(() {
        _isProcessing = false;
      });

      // Navigate to Review Screen
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => ReviewReceiptScreen(
            imagePath: pickedFile.path,
            parsedData: parsedData,
          ),
        ),
      );

      if (result == true && mounted) {
        Navigator.pop(context, true); // Return to home and reload
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể xử lý ảnh: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _runDemoScan() async {
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Đang chạy demo quét hóa đơn VKU...';
    });

    await Future.delayed(const Duration(milliseconds: 900));
    final parsedData = await _ocrService.processImage('demo_receipt.jpg');

    if (!mounted) return;

    setState(() => _isProcessing = false);

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ReviewReceiptScreen(
          imagePath: '',
          parsedData: parsedData,
        ),
      ),
    );

    if (result == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Quét Hóa Đơn OCR', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 20),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Đặt hóa đơn phẳng trong khung và đảm bảo đủ ánh sáng để OCR nhận diện chính xác',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                  ),
                ),
                const Spacer(),

                // Viewfinder / Target Reticle
                Center(
                  child: Container(
                    width: 290,
                    height: 380,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF38BDF8), width: 2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Stack(
                      children: [
                        // Corner highlights
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(width: 24, height: 24, decoration: const BoxDecoration(
                            border: Border(top: BorderSide(color: Colors.white, width: 3), left: BorderSide(color: Colors.white, width: 3)),
                          )),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(width: 24, height: 24, decoration: const BoxDecoration(
                            border: Border(top: BorderSide(color: Colors.white, width: 3), right: BorderSide(color: Colors.white, width: 3)),
                          )),
                        ),
                        Positioned(
                          bottom: 8,
                          left: 8,
                          child: Container(width: 24, height: 24, decoration: const BoxDecoration(
                            border: Border(bottom: BorderSide(color: Colors.white, width: 3), left: BorderSide(color: Colors.white, width: 3)),
                          )),
                        ),
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(width: 24, height: 24, decoration: const BoxDecoration(
                            border: Border(bottom: BorderSide(color: Colors.white, width: 3), right: BorderSide(color: Colors.white, width: 3)),
                          )),
                        ),
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.crop_free, size: 64, color: Colors.white.withValues(alpha: 0.3)),
                              const SizedBox(height: 12),
                              Text(
                                'Khung Quét Hóa Đơn',
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // Action Bar
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E293B),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Gallery Button
                          _buildOptionButton(
                            icon: Icons.photo_library_outlined,
                            label: 'Thư viện',
                            onTap: () => _pickAndProcessImage(ImageSource.gallery),
                          ),
                          // Camera Shutter Button
                          GestureDetector(
                            onTap: () => _pickAndProcessImage(ImageSource.camera),
                            child: Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF2563EB),
                                border: Border.all(color: Colors.white, width: 4),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF2563EB).withValues(alpha: 0.5),
                                    blurRadius: 16,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.camera_alt, color: Colors.white, size: 32),
                            ),
                          ),
                          // Demo Scan Button
                          _buildOptionButton(
                            icon: Icons.flash_on,
                            label: 'Demo Quét',
                            onTap: _runDemoScan,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Processing Loading Overlay
            if (_isProcessing)
              Container(
                color: Colors.black.withValues(alpha: 0.8),
                alignment: Alignment.center,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                  margin: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF38BDF8), width: 1.5),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF38BDF8)),
                        strokeWidth: 3,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _statusMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Offline On-Device AI • Bảo mật 100%',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF334155),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
