import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../app/theme/app_colors.dart';

class AppImage extends StatelessWidget {
  const AppImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.memCacheWidth,
    this.memCacheHeight,
    this.errorIcon = Icons.hotel,
    this.errorIconSize = 48,
  });

  final String url;
  final BoxFit fit;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final IconData errorIcon;
  final double errorIconSize;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return Container(
        color: AppColors.warmSand,
        child: Icon(errorIcon, size: errorIconSize, color: AppColors.textSecondary),
      );
    }

    if (url.startsWith('assets/') || url.startsWith('assets')) {
      return Image.asset(
        url,
        fit: fit,
        cacheWidth: memCacheWidth,
        cacheHeight: memCacheHeight,
        errorBuilder: (_, __, ___) => Container(
          color: AppColors.warmSand,
          child: Icon(errorIcon, size: errorIconSize, color: AppColors.textSecondary),
        ),
      );
    }

    if (url.startsWith('/') || url.contains(':\\') || url.contains(':/')) {
      final file = File(url);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: fit,
          cacheWidth: memCacheWidth,
          cacheHeight: memCacheHeight,
          errorBuilder: (_, __, ___) => Container(
            color: AppColors.warmSand,
            child: Icon(errorIcon, size: errorIconSize, color: AppColors.textSecondary),
          ),
        );
      }
    }

    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      memCacheWidth: memCacheWidth,
      memCacheHeight: memCacheHeight,
      maxWidthDiskCache: 800,
      maxHeightDiskCache: 600,
      placeholder: (_, __) => Container(color: AppColors.border),
      errorWidget: (_, __, ___) => Container(
        color: AppColors.warmSand,
        child: Icon(errorIcon, size: errorIconSize, color: AppColors.textSecondary),
      ),
    );
  }
}
