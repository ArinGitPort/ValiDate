import 'dart:io';
import 'package:flutter/material.dart';

class ReceiptThumbnail extends StatelessWidget {
  final String? imagePath;
  final double size;

  const ReceiptThumbnail({super.key, required this.imagePath, this.size = 50});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: imagePath != null && File(imagePath!).existsSync()
          ? Image.file(
              File(imagePath!),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 20),
            )
          : const Icon(Icons.receipt, size: 20, color: Colors.grey),
    );
  }
}
