import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../network/api_client.dart';
import '../theme/app_colors.dart';

class CachedAvatarImage extends StatefulWidget {
  final String imageId;
  final String initials;
  final double size;
  final double loaderSize;
  final TextStyle? initialsStyle;

  const CachedAvatarImage({
    super.key,
    required this.imageId,
    required this.initials,
    this.size = 40,
    this.loaderSize = 20,
    this.initialsStyle,
  });

  @override
  State<CachedAvatarImage> createState() => _CachedAvatarImageState();
}

class _CachedAvatarImageState extends State<CachedAvatarImage> {
  late Future<Uint8List?> _imageFuture;

  @override
  void initState() {
    super.initState();
    _imageFuture = _loadImage();
  }

  @override
  void didUpdateWidget(covariant CachedAvatarImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageId != widget.imageId) {
      _imageFuture = _loadImage();
    }
  }

  Future<Uint8List?> _loadImage() {
    return Get.find<ApiClient>().getImageBytes(widget.imageId);
  }

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: FutureBuilder<Uint8List?>(
        future: _imageFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return SizedBox(
              width: widget.loaderSize,
              height: widget.loaderSize,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primaryOrange,
              ),
            );
          }

          if (snapshot.hasData && snapshot.data != null) {
            return Image.memory(
              snapshot.data!,
              width: widget.size,
              height: widget.size,
              fit: BoxFit.cover,
            );
          }

          return Text(
            widget.initials,
            style: widget.initialsStyle,
          );
        },
      ),
    );
  }
}
