import 'package:flutter/material.dart';
import 'smart_image.dart';

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
      child: imagePath != null && imagePath!.isNotEmpty
          ? SmartImage(
              imagePath: imagePath,
              fit: BoxFit.cover,
              width: size,
              height: size,
            )
          : const Icon(Icons.receipt, size: 20, color: Colors.grey),
    );
  }
}
