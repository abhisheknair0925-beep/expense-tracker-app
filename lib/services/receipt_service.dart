import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Service for picking, storing, and managing receipt images.
///
/// OCR-ready structure: add google_mlkit_text_recognition here
/// in the future — the extraction method is already stubbed.
class ReceiptService {
  ReceiptService._();
  static final ReceiptService instance = ReceiptService._();

  final _picker = ImagePicker();

  /// Pick receipt image from camera or gallery.
  Future<File?> pickReceipt({bool fromCamera = false}) async {
    try {
      final xFile = await _picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (xFile == null) return null;
      return _saveToAppDir(File(xFile.path));
    } catch (e) {
      debugPrint('Error picking receipt: $e');
      return null;
    }
  }

  /// Copy the picked image to the app's documents directory.
  Future<File> _saveToAppDir(File source) async {
    final dir = await getApplicationDocumentsDirectory();
    final receiptDir = Directory('${dir.path}/receipts');
    if (!await receiptDir.exists()) await receiptDir.create(recursive: true);

    final fileName = 'receipt_${DateTime.now().millisecondsSinceEpoch}${p.extension(source.path)}';
    final dest = File('${receiptDir.path}/$fileName');
    return source.copy(dest.path);
  }

  /// Delete a stored receipt.
  Future<void> deleteReceipt(String path) async {
    final file = File(path);
    if (await file.exists()) await file.delete();
  }

  /// Check if receipt file still exists.
  Future<bool> receiptExists(String path) async => File(path).exists();

  // ═══════════════════════════════════════════════════════════════════
  // OCR STUB — Ready for future integration
  // ═══════════════════════════════════════════════════════════════════

  /// OCR-ready stub. Replace this with actual OCR logic:
  ///
  /// ```dart
  /// import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
  ///
  /// Future<String?> extractText(String imagePath) async {
  ///   final recognizer = TextRecognizer();
  ///   final inputImage = InputImage.fromFilePath(imagePath);
  ///   final result = await recognizer.processImage(inputImage);
  ///   recognizer.close();
  ///   return result.text;
  /// }
  /// ```
  Future<Map<String, dynamic>?> extractReceiptData(String imagePath) async {
    // Stub — returns null until OCR is implemented
    debugPrint('OCR stub called for: $imagePath');
    return null;
  }
}
