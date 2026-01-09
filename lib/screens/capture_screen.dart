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
  final WarrantyItem? item; // Null implies new item

  const CaptureScreen({super.key, this.item});

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _storeCtrl = TextEditingController();
  final _serialCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();

  String? _imagePath;
  DateTime? _selectedDate;
  bool _isLoading = false;

  final OCRService _ocrService = OCRService();

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _populateForm(widget.item!);
    } else {
      // Auto launch camera for new items
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_imagePath == null) {
          _pickImage();
        }
      });
    }
  }

  void _populateForm(WarrantyItem item) {
    _nameCtrl.text = item.name;
    _storeCtrl.text = item.storeName;
    _serialCtrl.text = item.serialNumber;
    _durationCtrl.text = item.warrantyPeriodInMonths.toString();
    _imagePath = item.imagePath;
    _selectedDate = item.purchaseDate;
    _dateCtrl.text = DateFormat('yyyy-MM-dd').format(item.purchaseDate);
  }

  Future<void> _pickImage() async {
    // Show dialog to choose between camera and gallery
    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(LucideIcons.camera),
                title: const Text('Camera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(LucideIcons.image),
                title: const Text('Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );

    if (source == null) {
      // User cancelled the dialog
      if (mounted && _imagePath == null) Navigator.pop(context);
      return;
    }

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source);
    if (picked != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = path.basename(picked.path);
      final savedImage = await File(picked.path).copy('${appDir.path}/$fileName');

      setState(() {
        _imagePath = savedImage.path;
      });

      _scanImageForDate(savedImage.path);
    } else {
      // User cancelled image picker, maybe pop?
      if (mounted && _imagePath == null) Navigator.pop(context);
    }
  }

  Future<void> _scanImageForDate(String path) async {
    setState(() => _isLoading = true);
    
    try {
      // Extract all available data
      final data = await _ocrService.extractReceiptData(path);
      
      if (mounted) {
        // Auto-fill store name if detected
        if (data['storeName'] != null && _storeCtrl.text.isEmpty) {
          setState(() {
            _storeCtrl.text = data['storeName'];
          });
        }
        
        // Auto-fill item name if detected
        if (data['itemName'] != null && _nameCtrl.text.isEmpty) {
          setState(() {
            _nameCtrl.text = data['itemName'];
          });
        }
        
        // Auto-fill date if detected
        if (data['date'] != null) {
          setState(() {
            _selectedDate = data['date'];
            _dateCtrl.text = DateFormat('yyyy-MM-dd').format(data['date']);
          });
        }
        
        // Show feedback
        List<String> detected = [];
        if (data['storeName'] != null) detected.add('Store');
        if (data['itemName'] != null) detected.add('Item');
        if (data['date'] != null) detected.add('Date');
        
        if (detected.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Detected: ${detected.join(', ')}")),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No data detected. Please enter manually.")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("OCR Error: ${e.toString()}")),
        );
      }
    }
    
    setState(() => _isLoading = false);
  }

  void _saveItem() {
    if (_formKey.currentState!.validate() && _imagePath != null && _selectedDate != null) {
      final isEditing = widget.item != null;
      
      final newItem = WarrantyItem(
        id: isEditing ? widget.item!.id : const Uuid().v4(),
        name: _nameCtrl.text,
        storeName: _storeCtrl.text,
        purchaseDate: _selectedDate!,
        warrantyPeriodInMonths: int.tryParse(_durationCtrl.text) ?? 12,
        serialNumber: _serialCtrl.text,
        // Preserve or default category. In future, add category picker.
        category: isEditing ? widget.item!.category : "Gadgets", 
        imagePath: _imagePath!,
        notificationsEnabled: isEditing ? widget.item!.notificationsEnabled : true,
        isArchived: isEditing ? widget.item!.isArchived : false,
      );

      final provider = Provider.of<WarrantyProvider>(context, listen: false);
      
      if (isEditing) {
        provider.updateWarranty(newItem);
      } else {
        provider.addWarranty(newItem);
      }
      
      Navigator.pop(context);
    } else if (_imagePath == null) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Receipt image missing")));
    } else if (_selectedDate == null) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Date required")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrow_left, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.item != null ? 'Edit Warranty' : 'Add Warranty'),
        centerTitle: true,
        actions: [
          if (_imagePath != null)
            IconButton(
              icon: const Icon(LucideIcons.refresh_cw, size: 20),
              onPressed: _pickImage,
              tooltip: 'Retake',
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
          children: [
            // Header Image
            SizedBox(
              height: 250,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _imagePath != null 
                    ? Image.file(File(_imagePath!), fit: BoxFit.cover)
                    : Container(color: Colors.black, child: const Icon(Icons.camera_alt, color: Colors.white)),
                  
                  
                  // Gradient Overlay
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Form
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_isLoading) ...[
                      const LinearProgressIndicator(), 
                      const SizedBox(height: 16)
                    ],

                    _buildField(_nameCtrl, "Item Name"),
                    const SizedBox(height: 16),
                    _buildField(_storeCtrl, "Store Name"),
                    const SizedBox(height: 16),
                    _buildField(_serialCtrl, "Serial Number", isRequired: false),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
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
                            child: AbsorbPointer(
                              child: _buildField(_dateCtrl, "Purchase Date", icon: LucideIcons.calendar),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(child: _buildField(_durationCtrl, "Warranty Period (Months)", isNumber: true)),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _saveItem,
                        child: const Text("Save Warranty"),
                      ),
                    ),
                    const SizedBox(height: 32), // Safe area
                  ],
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, {bool isNumber = false, IconData? icon, bool isRequired = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          validator: isRequired ? (v) => v!.isEmpty ? "Required" : null : null,
          decoration: InputDecoration(
            suffixIcon: icon != null ? Icon(icon, size: 18) : null,
          ),
        ),
      ],
    );
  }
}
