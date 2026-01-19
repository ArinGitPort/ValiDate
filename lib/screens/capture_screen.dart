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
import '../utils/category_data.dart';
import '../theme/app_theme.dart';
import '../widgets/smart_image.dart';

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
  
  // New State for Warranty Period
  final _periodValueCtrl = TextEditingController();
  String _selectedPeriodUnit = "Months"; // "Days", "Weeks", "Months", "Years"
  bool _isLifetime = false;

  String? _imagePath;
  DateTime? _selectedDate;
  String _selectedCategory = "others";
  bool _isLoading = false;
  bool _isPickingImage = false; // Guard to prevent multiple picker calls

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

  List<String> _additionalImages = [];

  // ... (previous methods)

  int get _calculatedMonths {
    if (_isLifetime) return 9999;
    
    final val = int.tryParse(_periodValueCtrl.text) ?? 0;
    switch (_selectedPeriodUnit) {
      case 'Years': return val * 12;
      case 'Weeks': return (val / 4.3).round();
      case 'Days': return (val / 30).round();
      default: return val; // Months
    }
  }

  void _populateForm(WarrantyItem item) {
    _nameCtrl.text = item.name;
    _storeCtrl.text = item.storeName;
    _serialCtrl.text = item.serialNumber;
    _imagePath = item.imagePath;
    _selectedDate = item.purchaseDate;
    _dateCtrl.text = DateFormat('yyyy-MM-dd').format(item.purchaseDate);
    
    // Validate category exists, else default to 'others'
    final exists = CategoryData.categories.any((c) => c.id == item.category);
    _selectedCategory = exists ? item.category : 'others';
    _additionalImages = List.from(item.additionalDocuments);

    // Populate Warranty Period
    if (item.warrantyPeriodInMonths > 1000) {
      _isLifetime = true;
      _periodValueCtrl.text = "";
    } else {
      _isLifetime = false;
      _periodValueCtrl.text = item.warrantyPeriodInMonths.toString();
      _selectedPeriodUnit = "Months"; // Default to months for existing data
    }
  }

  Future<void> _pickAdditionalImage() async {
    if (_isPickingImage) return; // Prevent multiple simultaneous calls
    _isPickingImage = true;
    
    try {
      final picker = ImagePicker();
      final pickedFiles = await picker.pickMultiImage();
      
      if (pickedFiles.isNotEmpty) {
         final appDir = await getApplicationDocumentsDirectory();
         List<String> newPaths = [];

         for (var picked in pickedFiles) {
            final fileName = path.basename(picked.path);
            final savedImage = await File(picked.path).copy('${appDir.path}/${DateTime.now().millisecondsSinceEpoch}_$fileName');
            newPaths.add(savedImage.path);
         }

         if (mounted) {
           setState(() {
             _additionalImages.addAll(newPaths);
           });
         }
      }
    } finally {
      _isPickingImage = false;
    }
  }

  Future<void> _pickImage() async {
    if (_isPickingImage) return;
    _isPickingImage = true;

    try {
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
    } finally {
      _isPickingImage = false;
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

  void _saveItem() async {
    if (_formKey.currentState!.validate() && _imagePath != null && _selectedDate != null) {
      final isEditing = widget.item != null;
      final provider = Provider.of<WarrantyProvider>(context, listen: false);
      
      // For new items, userId will be set by the provider
      final newItem = WarrantyItem(
        id: isEditing ? widget.item!.id : const Uuid().v4(),
        userId: isEditing ? widget.item!.userId : '', // Provider will set this
        name: _nameCtrl.text,
        storeName: _storeCtrl.text,
        purchaseDate: _selectedDate!,
        warrantyPeriodInMonths: _calculatedMonths,
        serialNumber: _serialCtrl.text,
        category: _selectedCategory, 
        imageUrl: _imagePath, // Local path - provider will upload
        additionalDocuments: _additionalImages,
        notificationsEnabled: isEditing ? widget.item!.notificationsEnabled : true,
        isArchived: isEditing ? widget.item!.isArchived : false,
      );
      
      if (isEditing) {
        await provider.updateWarranty(newItem);
      } else {
        await provider.addWarranty(
          newItem,
          extraDocs: _additionalImages,
        );
      }
      
      if (mounted) Navigator.pop(context);
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
                    ? SmartImage(imagePath: _imagePath, fit: BoxFit.cover)
                    : Container(color: AppTheme.primaryDark, child: const Icon(Icons.camera_alt, color: AppTheme.white)),
                  
                  
                  // Gradient Overlay
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, AppTheme.primaryDark.withValues(alpha: 0.7)],
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
                    
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
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
                          const SizedBox(height: 16),
                          
                          // Composite Warranty Input
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Warranty Period", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.secondaryText)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: TextFormField(
                                      controller: _periodValueCtrl,
                                      enabled: !_isLifetime,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        hintText: "0",
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                        filled: true,
                                        fillColor: _isLifetime ? Colors.grey.shade100 : AppTheme.inputFill,
                                      ),
                                      validator: (v) {
                                        if (_isLifetime) return null;
                                        if (v == null || v.isEmpty) return "Required";
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 2,
                                    child: DropdownButtonFormField<String>(
                                      key: ValueKey(_selectedPeriodUnit),
                                      initialValue: _selectedPeriodUnit,
                                      onChanged: _isLifetime ? null : (v) => setState(() => _selectedPeriodUnit = v ?? "Months"),
                                      items: ["Days", "Weeks", "Months", "Years"].map((u) => DropdownMenuItem(value: u, child: Text(u, overflow: TextOverflow.ellipsis))).toList(),
                                      decoration: InputDecoration(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                        filled: true,
                                        fillColor: _isLifetime ? Colors.grey.shade100 : AppTheme.inputFill,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        value: _isLifetime,
                        onChanged: (v) {
                          setState(() {
                            _isLifetime = v ?? false;
                            if (_isLifetime) {
                              _periodValueCtrl.clear();
                            }
                          });
                        },
                        title: const Text("Lifetime / Perpetual Warranty", style: TextStyle(fontSize: 14)),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        activeColor: AppTheme.primaryBrand,
                      ),
                    const SizedBox(height: 16),

                    // Category Dropdown
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Category", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.secondaryText)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          key: ValueKey(_selectedCategory),
                          initialValue: _selectedCategory,
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                          items: CategoryData.categories.map((c) {
                            return DropdownMenuItem(
                              value: c.id,
                              child: Row(
                                children: [
                                  Icon(c.icon, size: 18, color: c.color),
                                  const SizedBox(width: 12),
                                  Text(c.label),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Additional Documents Section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Your Documents", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.secondaryText)),
                            TextButton.icon(
                              onPressed: _pickAdditionalImage,
                              icon: const Icon(LucideIcons.plus, size: 16),
                              label: const Text("Add"),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_additionalImages.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            decoration: BoxDecoration(
                              color: AppTheme.inputFill,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.dividerColor),
                            ),
                            child: Center(
                              child: Text(
                                "No additional documents",
                                style: TextStyle(color: AppTheme.secondaryText, fontSize: 12),
                              ),
                            ),
                          )
                        else
                          SizedBox(
                            height: 100,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _additionalImages.length,
                              separatorBuilder: (c, i) => const SizedBox(width: 12),
                              itemBuilder: (context, index) {
                                final path = _additionalImages[index];
                                return Stack(
                                  children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: SmartImage(
                                          imagePath: path,
                                          fit: BoxFit.cover,
                                          width: 100,
                                          height: 100,
                                        ),
                                      ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: InkWell(
                                          onTap: () {
                                            showDialog(
                                              context: context,
                                              builder: (ctx) => AlertDialog(
                                                title: const Text("Remove Document?"),
                                                content: const Text("This will remove the document from this warranty."),
                                                actions: [
                                                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
                                                  TextButton(
                                                    onPressed: () {
                                                      setState(() {
                                                        _additionalImages.removeAt(index);
                                                      });
                                                      Navigator.pop(ctx);
                                                    },
                                                    child: const Text("Remove", style: TextStyle(color: Colors.red)),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(alpha: 0.5),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(LucideIcons.x, size: 12, color: AppTheme.white),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
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
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.secondaryText)),
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
