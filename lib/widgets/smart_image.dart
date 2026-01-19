import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../theme/app_theme.dart';

/// Smart image widget that handles both local file paths and network URLs
class SmartImage extends StatelessWidget {
  final String? imagePath;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? placeholder;
  final Widget? errorWidget;

  const SmartImage({
    super.key,
    required this.imagePath,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    debugPrint('SmartImage: Loading image from: $imagePath');
    
    if (imagePath == null || imagePath!.isEmpty) {
      debugPrint('SmartImage: Path is null or empty');
      return _buildError();
    }

    // Check if it's a network URL
    final cleanPath = imagePath!.trim().toLowerCase();
    if (cleanPath.startsWith('http://') || cleanPath.startsWith('https://')) {
      debugPrint('SmartImage: Detected as NETWORK image');
      return CachedNetworkImage(
        imageUrl: imagePath!,
        fit: fit,
        width: width,
        height: height,
        placeholder: (context, url) => placeholder ?? _buildPlaceholder(),
        errorWidget: (context, url, error) {
          debugPrint('SmartImage: Network image error: $error');
          return errorWidget ?? _buildError();
        },
      );
    }

    // Otherwise treat as local file
    final file = File(imagePath!);
    return Image.file(
      file,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (context, error, stackTrace) => errorWidget ?? _buildError(),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppTheme.inputFill,
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _buildError() {
    return Container(
      color: AppTheme.inputFill,
      child: const Center(
        child: Icon(LucideIcons.image, color: AppTheme.secondaryText),
      ),
    );
  }
}
