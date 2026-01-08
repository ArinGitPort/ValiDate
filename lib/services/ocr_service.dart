import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:intl/intl.dart';

class OCRService {
  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<String> processImage(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final recognizedText = await _textRecognizer.processImage(inputImage);
    return recognizedText.text;
  }

  Future<DateTime?> extractDate(String imagePath) async {
    final text = await processImage(imagePath);
    // Regex for common date formats: MM/DD/YYYY, DD/MM/YYYY, YYYY-MM-DD, etc.
    // Simplifying for now.
    // Try to find typical patterns.
    final datePattern = RegExp(r'\d{1,2}[/-]\d{1,2}[/-]\d{2,4}');
    final match = datePattern.firstMatch(text);
    
    if (match != null) {
      final dateString = match.group(0);
      return _parseDate(dateString!);
    }
    return null;
  }

  DateTime? _parseDate(String dateStr) {
    List<String> formats = [
      'MM/dd/yyyy',
      'dd/MM/yyyy',
      'yyyy-MM-dd',
      'MM-dd-yyyy',
      'dd-MM-yyyy',
    ];

    for (var format in formats) {
      try {
        return DateFormat(format).parse(dateStr);
      } catch (e) {
        continue;
      }
    }
    return null;
  }

  void dispose() {
    _textRecognizer.close();
  }
}
