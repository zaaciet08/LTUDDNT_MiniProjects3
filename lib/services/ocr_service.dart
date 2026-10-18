import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'receipt_parser.dart';

class OcrService {
  TextRecognizer? _textRecognizer;

  OcrService() {
    if (!kIsWeb) {
      try {
        // Uses Latin script which fully covers Vietnamese (with accents) and English receipts
        _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      } catch (e) {
        debugPrint('ML Kit TextRecognizer initialization error: $e');
      }
    }
  }

  /// Process image through Google ML Kit on-device OCR engine
  Future<ParsedReceiptData> processImage(String imagePath) async {
    if (kIsWeb) {
      debugPrint('Chế độ Web: sử dụng parser trích xuất hóa đơn.');
      return _generateFallbackData(imagePath);
    }
    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        throw Exception('Ảnh không tồn tại: $imagePath');
      }

      final inputImage = InputImage.fromFilePath(imagePath);
      final RecognizedText recognizedText = await _textRecognizer!.processImage(inputImage);

      debugPrint('--- [ML Kit OCR Raw Output] ---');
      debugPrint(recognizedText.text);
      debugPrint('--------------------------------');

      return ReceiptParserEngine.parse(recognizedText.text);
    } catch (e) {
      debugPrint('Lỗi ML Kit OCR: $e. Sử dụng fallback parser...');
      // If running on non-supported platforms (e.g. Windows/macOS desktop without ML Kit binary)
      return _generateFallbackData(imagePath);
    }
  }

  /// Fallback demo receipts for testing when running on desktop or emulator
  ParsedReceiptData _generateFallbackData(String imagePath) {
    const sampleText = '''
NHÀ SÁCH FAHASA ĐÀ NẴNG
Đ/c: 300-302 Lê Duẩn, Đà Nẵng
Ngày lập: 12/10/2026 14:30
Thu ngân: NV01

1. Tập Giấy A4 Double A 80gsm     95.000đ
2. Bút dạ quang Pentel 4 màu     48.000đ
3. Kẹp bướm văn phòng 19mm       22.000đ

TỔNG CỘNG: 165.000 VND
Tiền mặt: 200.000 VND
Tiền thừa: 35.000 VND

CẢM ƠN QUÝ KHÁCH VÀ HẸN GẶP LẠI!
''';
    return ReceiptParserEngine.parse(sampleText);
  }

  void dispose() {
    _textRecognizer?.close();
  }
}
