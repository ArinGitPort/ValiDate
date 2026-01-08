import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';

import '../models/warranty_item.dart';
import '../providers/warranty_provider.dart';
import '../services/ocr_service.dart';

class CaptureScreen extends StatefulWidget {
  const CaptureScreen({super.key});

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _storeCtrl = TextEditingController();
  final _serialCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _durationCtrl = TextEditingController(); // in months

  String? _imagePath;
  DateTime? _selectedDate;
  bool _isProcessingOCR = false;

  final OCRService _ocrService = OCRService();

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source);
    if (picked != null) {
      // Save permanently
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = path.basename(picked.path);
      final savedImage = await File(picked.path).copy('${appDir.path}/$fileName');

      setState(() {
        _imagePath = savedImage.path;
      });

      // Run OCR
      _scanImageForDate(savedImage.path);
    }
  }

  Future<void> _scanImageForDate(String path) async {
    setState(() => _isProcessingOCR = true);
    final date = await _ocrService.extractDate(path);
    if (date != null && mounted) {
       setState(() {
         _selectedDate = date;
         _dateCtrl.text = DateFormat('yyyy-MM-dd').format(date);
       });
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text("Date detected and auto-filled!")),
       );
    }
    setState(() => _isProcessingOCR = false);
  }

  void _saveItem() {
    if (_formKey.currentState!.validate() && _imagePath != null && _selectedDate != null) {
      final newItem = WarrantyItem(
        id: const Uuid().v4(),
        name: _nameCtrl.text,
        storeName: _storeCtrl.text,
        purchaseDate: _selectedDate!,
        warrantyPeriodInMonths: int.tryParse(_durationCtrl.text) ?? 12,
        serialNumber: _serialCtrl.text,
        category: "Gadgets", // Default for now, could be dropdown
        imagePath: _imagePath!,
      );

      Provider.of<WarrantyProvider>(context, listen: false).addWarranty(newItem);
      Navigator.pop(context);
    } else if (_imagePath == null) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please attach a receipt image.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("New Warranty")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Picker
              GestureDetector(
                onTap: () => _pickImage(ImageSource.camera),
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[800]!),
                  ),
                  child: _imagePath != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(File(_imagePath!), fit: BoxFit.cover),
                              if (_isProcessingOCR)
                                const Center(child: CircularProgressIndicator()),
                            ],
                          ),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.camera, size: 48, color: Colors.grey),
                            SizedBox(height: 8),
                            Text("Tap to capture receipt", style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: "Item Name"),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _storeCtrl,
                decoration: const InputDecoration(labelText: "Store Name"),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _serialCtrl,
                decoration: const InputDecoration(labelText: "Serial Number"),
                validator: (v) => v!.isEmpty ? "Critical for claims" : null,
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _dateCtrl,
                      decoration: const InputDecoration(
                        labelText: "Purchase Date",
                        suffixIcon: Icon(LucideIcons.calendar),
                      ),
                      readOnly: true,
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (d != null) {
                          setState(() {
                            _selectedDate = d;
                            _dateCtrl.text = DateFormat('yyyy-MM-dd').format(d);
                          });
                        }
                      },
                      validator: (v) => v!.isEmpty ? "Required" : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _durationCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Months"),
                      validator: (v) => v!.isEmpty ? "Required" : null,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveItem,
                child: const Text("Save Warranty"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
