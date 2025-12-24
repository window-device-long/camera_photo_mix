import 'dart:io';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

typedef OnOriginReady = void Function(File file);

class AssetThumbnailWithOriginLoader extends StatefulWidget {
  const AssetThumbnailWithOriginLoader({
    super.key,
    required this.asset,
    required this.onOriginReady,
    this.onTap,
  });

  final AssetEntity asset;
  final OnOriginReady onOriginReady;
  final VoidCallback? onTap;

  @override
  State<AssetThumbnailWithOriginLoader> createState() =>
      _AssetThumbnailWithOriginLoaderState();
}

class _AssetThumbnailWithOriginLoaderState
    extends State<AssetThumbnailWithOriginLoader> {
  bool _isDownloading = false;
  bool _hasOriginLocal = false;
  bool _checkedLocal = false;

  double _progress = 0;
  PMProgressHandler? _progressHandler;

  @override
  void initState() {
    super.initState();
    _checkOriginLocal();
  }

  Future<void> _checkOriginLocal() async {
    final isLocal = await widget.asset.isLocallyAvailable(isOrigin: true);
    if (!mounted) return;

    setState(() {
      _hasOriginLocal = isLocal;
      _checkedLocal = true;
    });
  }

  Future<void> loadOriginIfNeeded() async {
    if (_isDownloading) return;

    setState(() {
      _isDownloading = true;
      _progress = 0;
    });

    _progressHandler = PMProgressHandler();

    File? file;

    try {
      // 🔥 CHỐT: CHỈ TIN FILE TRẢ VỀ
      file = await widget.asset.loadFile(
        isOrigin: true,
        progressHandler: _progressHandler,
      );
    } catch (_) {
      file = null;
    }

    if (!mounted) return;

    // 🔑 VALIDATE FILE
    final valid = file != null && file.existsSync() && file.lengthSync() > 0;

    if (valid) {
      setState(() {
        _hasOriginLocal = true;
      });

      widget.onOriginReady(file!);
    }

    setState(() {
      _isDownloading = false;
      _progressHandler = null;
      _progress = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap ?? loadOriginIfNeeded,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            /// 🖼️ THUMBNAIL – LUÔN HIỂN THỊ
            AssetEntityImage(
              widget.asset,
              fit: BoxFit.cover,
              thumbnailSize: const ThumbnailSize.square(300),
              isOriginal: false,
            ),

            /// ☁️ ICLOUD ICON
            if (_checkedLocal && !_hasOriginLocal && !_isDownloading)
              const Positioned(
                top: 6,
                left: 6,
                child: Icon(
                  Icons.cloud_download,
                  size: 18,
                  color: Colors.white70,
                ),
              ),

            /// 🔄 LOADING
            if (_isDownloading)
              Container(
                color: Colors.black45,
                alignment: Alignment.center,
                child: StreamBuilder<PMProgressState>(
                  stream: _progressHandler?.stream,
                  initialData: const PMProgressState(0, PMRequestState.prepare),
                  builder: (_, snap) {
                    final p = snap.data?.progress ?? _progress;

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          value: p > 0 ? p : null,
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Downloading ${(p * 100).toInt()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
