import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:intl/intl.dart';

class OCRService {
  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<String> processImage(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final recognizedText = await _textRecognizer.processImage(inputImage);
    return recognizedText.text;
  }

  Future<Map<String, dynamic>> extractReceiptData(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final recognizedText = await _textRecognizer.processImage(inputImage);
    
    final lines = recognizedText.text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    
    return {
      'storeName': _extractStoreName(lines),
      'date': await extractDate(imagePath),
      'itemName': _extractItemName(lines),
      'rawText': recognizedText.text,
    };
  }

  String? _extractStoreName(List<String> lines) {
    if (lines.isEmpty) return null;
    
    // Strategy 1: First non-empty line that's not a number/symbol is usually the store
    for (var i = 0; i < (lines.length > 8 ? 8 : lines.length); i++) {
      final line = lines[i];
      
      // Skip very short lines
      if (line.length < 3) continue;
      
      // Skip lines that are mostly numbers or symbols
      final letterCount = line.replaceAll(RegExp(r'[^a-zA-Z]'), '').length;
      if (letterCount < 3) continue;
      
      // Skip common header words
      final upper = line.toUpperCase();
      if (upper.contains('INVOICE') || 
          upper.contains('RECEIPT') ||
          upper.contains('BILL') ||
          upper.startsWith('PHONE') ||
          upper.startsWith('TEL') ||
          upper.startsWith('ADDRESS') ||
          RegExp(r'^\d{2}\/\d{2}\/\d{4}').hasMatch(line)) {
        continue;
      }
      
      // This is likely the store name
      return line;
    }
    
    // Fallback: return first line with decent length
    return lines.firstOrNull;
  }

  String? _extractItemName(List<String> lines) {
    // Multiple strategies to find item names
    
    // Strategy 1: Look for section headers
    List<String> itemLines = [];
    bool foundDescriptionSection = false;
    int descriptionIndex = -1;
    
    for (var i = 0; i < lines.length; i++) {
      final upper = lines[i].toUpperCase();
      
      // Find description/item section
      if (upper.contains('DESCRIPTION') || 
          upper.contains('PARTICULARS') ||
          upper.contains('ITEM') ||
          upper == 'BILL TO' ||
          upper.contains('PRODUCT')) {
        foundDescriptionSection = true;
        descriptionIndex = i;
        continue;
      }
      
      // Stop at totals
      if (upper.contains('SUBTOTAL') || 
          upper.contains('TOTAL') && !upper.contains('TOTAL PAYMENT') ||
          upper.contains('AMOUNT') && upper.contains('DUE') ||
          upper.contains('TAX')) {
        break;
      }
      
      // Collect items after description header
      if (foundDescriptionSection && i > descriptionIndex) {
        // Skip pure number/amount lines
        if (RegExp(r'^[\d\s,.\₱\$]+$').hasMatch(lines[i])) continue;
        
        // Skip headers like "AMOUNT", "TOTAL"
        if (lines[i].toUpperCase() == 'AMOUNT' || 
            lines[i].toUpperCase() == 'TOTAL') continue;
        
        itemLines.add(lines[i]);
        
        // Get first 3-4 item-like lines
        if (itemLines.length >= 4) break;
      }
    }
    
    if (itemLines.isNotEmpty) {
      // For multi-line items (like computer builds), combine them
      return itemLines.join(' - ').replaceAll(RegExp(r'\s+'), ' ').trim();
    }
    
    // Strategy 2: Look for lines with specific patterns (unit, qty, etc.)
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lower = line.toLowerCase();
      
      if ((lower.contains('unit of') || 
           lower.contains('qty') ||
           lower.startsWith('1 ') ||
           lower.startsWith('2 ') ||
           lower.startsWith('x ')) &&
          line.length > 10) {
        // Get this line and maybe the next couple
        List<String> combined = [line];
        for (var j = i + 1; j < i + 3 && j < lines.length; j++) {
          if (!RegExp(r'^[\d\s,.\₱\$]+$').hasMatch(lines[j]) && 
              lines[j].length > 5) {
            combined.add(lines[j]);
          }
        }
        return combined.join(' - ');
      }
    }
    
    return null;
  }

  Future<DateTime?> extractDate(String imagePath) async {
    final text = await processImage(imagePath);
    // Regex for common date formats: MM/DD/YYYY, DD/MM/YYYY, YYYY-MM-DD, etc.
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
