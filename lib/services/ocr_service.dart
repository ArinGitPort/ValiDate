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
    // Strategy 1: Look for numbered items (1, 2, 3, etc.) which are common in receipts
    List<String> numberedItems = [];
    
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      
      // Match lines starting with numbers like "1 ", "2 ", "1|", etc.
      if (RegExp(r'^[1-4]\s+').hasMatch(line) || RegExp(r'^[1-4]\|').hasMatch(line)) {
        // Extract the item name (remove the number prefix and any trailing codes/prices)
        String itemText = line.replaceFirst(RegExp(r'^[1-4]\s+'), '').replaceFirst(RegExp(r'^[1-4]\|'), '');
        
        // Remove trailing numbers, codes, and "pcs"
        itemText = itemText.replaceAll(RegExp(r'\s+\d{4,}\s*$'), ''); // Remove long numbers (codes)
        itemText = itemText.replaceAll(RegExp(r'\s+\d+\s*pcs\s*$'), ''); // Remove "X pcs"
        itemText = itemText.replaceAll(RegExp(r'\s+[A-Z0-9]{5,}\s*$'), ''); // Remove codes
        
        if (itemText.isNotEmpty && itemText.length > 5) {
          numberedItems.add(itemText.trim());
        }
      }
    }
    
    if (numberedItems.isNotEmpty) {
      // Return first item or combine first few if they're related
      return numberedItems.first;
    }
    
    // Strategy 2: Look for description sections
    List<String> itemLines = [];
    bool inBillToSection = false;
    bool inDescriptionSection = false;
    int sectionStartIndex = -1;
    
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final upper = line.toUpperCase();
      
      // Skip price/tax patterns
      if (RegExp(r'\d+[,\.]\d+').hasMatch(line) && 
          (upper.contains('PCS') || upper.contains('TAX') || upper.contains('TOTAL'))) {
        continue;
      }
      
      // Skip BILL TO sections entirely
      if (upper.contains('BILL TO') || upper.contains('SOLD TO')) {
        inBillToSection = true;
        inDescriptionSection = false;
        continue;
      }
      
      // Exit BILL TO section when we hit DESCRIPTION or similar
      if (inBillToSection && (upper.contains('DESCRIPTION') || 
          upper.contains('PARTICULARS') ||
          upper.contains('ITEM') ||
          upper.contains('PRODUCT'))) {
        inBillToSection = false;
        inDescriptionSection = true;
        sectionStartIndex = i;
        continue;
      }
      
      // Skip lines while in BILL TO
      if (inBillToSection) continue;
      
      // Find description/item section
      if (!inDescriptionSection && (upper.contains('DESCRIPTION') || 
          upper.contains('PARTICULARS') ||
          upper.contains('ITEM') ||
          upper.contains('PRODUCT'))) {
        inDescriptionSection = true;
        sectionStartIndex = i;
        continue;
      }
      
      // Stop at totals/amounts
      if (upper.contains('SUBTOTAL') || 
          (upper.contains('TOTAL') && !upper.contains('TOTAL PAYMENT')) ||
          upper.contains('AMOUNT') && (upper.contains('DUE') || upper.contains('TOTAL')) ||
          upper.contains('TAX')) {
        break;
      }
      
      // Collect items after description header
      if (inDescriptionSection && i > sectionStartIndex) {
        // Skip pure number/currency lines
        if (RegExp(r'^[\d\s,.\₱\$Rs]+$').hasMatch(line)) continue;
        
        // Skip column headers
        if (upper == 'AMOUNT' || upper == 'TOTAL' || upper == 'QTY' || upper == 'QUANTITY') continue;
        
        // Stop at payment/transaction information
        if (upper.contains('CARD NUMBER') ||
            upper.contains('CARD TYPE') ||
            upper.contains('STATUS') ||
            upper.contains('DATE/TIME') ||
            upper.contains('PAYMENT') ||
            upper.contains('TRANSACTION') ||
            upper.contains('REFERENCE') ||
            upper.contains('APPROVAL')) {
          break;
        }
        
        // Skip very short lines (likely not product names)
        if (line.length < 5) continue;
        
        itemLines.add(line);
        
        // For simple items, stop after first meaningful line
        if (itemLines.length == 1 && !line.toLowerCase().contains('unit of')) {
          break;
        }
        
        // Collect several item lines for multi-line products (computer builds)
        if (itemLines.length >= 5) break;
      }
    }
    
    if (itemLines.isNotEmpty) {
      // For multi-line items (like computer builds), combine them
      return itemLines.join(' - ').replaceAll(RegExp(r'\s+'), ' ').trim();
    }
    
    // Strategy 3: Look for lines with quantity/unit patterns
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lower = line.toLowerCase();
      final upper = line.toUpperCase();
      
      // Skip if we're in a BILL TO or address section
      if (upper.contains('BILL TO') || 
          upper.contains('SOLD TO') ||
          lower.contains('street') ||
          lower.contains('avenue') ||
          lower.contains('rizal') ||
          lower.contains('manila') ||
          lower.contains('philippines')) {
        continue;
      }
      
      // Skip tax/price lines
      if (upper.contains('TAX') || upper.contains('PCS - ')) continue;
      
      // Look for product indicators
      if ((lower.contains('unit of') || 
           lower.contains('qty') ||
           lower.contains('pcs') ||
           lower.contains('set of') ||
           RegExp(r'^\d+\s+(unit|pcs|set|pc)').hasMatch(lower)) &&
          line.length > 10) {
        // Get this line and the next few lines (for multi-part descriptions)
        List<String> combined = [line];
        for (var j = i + 1; j < i + 5 && j < lines.length; j++) {
          final nextLine = lines[j];
          // Stop at amounts/totals
          if (RegExp(r'^[\d\s,.\₱\$]+$').hasMatch(nextLine)) break;
          if (nextLine.toUpperCase().contains('SUBTOTAL')) break;
          if (nextLine.toUpperCase().contains('TOTAL')) break;
          
          if (nextLine.length > 5) {
            combined.add(nextLine);
          }
        }
        return combined.join(' - ').replaceAll(RegExp(r'\s+'), ' ').trim();
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
