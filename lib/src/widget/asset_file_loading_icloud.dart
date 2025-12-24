import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

typedef OnTapStarted = void Function();
typedef OnImageResolved = void Function(File file);

class AssetThumbnailWithFallback extends StatefulWidget {
  const AssetThumbnailWithFallback({
    super.key,
    required this.asset,
    required this.onResolved,
    this.onTapStarted,
  });

  final AssetEntity asset;
  final ValueChanged<File> onResolved;
  final VoidCallback? onTapStarted;

  @override
  State<AssetThumbnailWithFallback> createState() =>
      _AssetThumbnailWithFallbackState();
}

class _AssetThumbnailWithFallbackState
    extends State<AssetThumbnailWithFallback> {
  bool _loading = false;
  bool _checkedLocal = false;
  bool _hasOriginLocal = false;

  PMProgressHandler? _progress;

  @override
  void initState() {
    super.initState();
    _checkLocal();
  }

  Future<void> _checkLocal() async {
    try {
      final local = await widget.asset.isLocallyAvailable(isOrigin: true);
      if (!mounted) return;
      setState(() {
        _hasOriginLocal = local;
        _checkedLocal = true;
      });
    } catch (_) {
      _checkedLocal = true;
    }
  }

  Future<void> _handleTap() async {
    if (_loading) return;

    widget.onTapStarted?.call();
    setState(() => _loading = true);

    File? file;

    try {
      // 1️⃣ originFile (local)
      file = await widget.asset.originFile;
      if (_valid(file)) {
        widget.onResolved(file!);
        return;
      }

      // 2️⃣ iCloud load
      _progress = PMProgressHandler();
      file = await widget.asset.loadFile(
        isOrigin: true,
        progressHandler: _progress,
      );
      if (_valid(file)) {
        widget.onResolved(file!);
        return;
      }

      // 3️⃣ file thường
      file = await widget.asset.file;
      if (_valid(file)) {
        widget.onResolved(file!);
        return;
      }

      // 4️⃣ 🔥 FALLBACK THUMBNAIL
      final thumb = await widget.asset.thumbnailDataWithSize(
        const ThumbnailSize(1024, 1024),
        quality: 90,
      );

      if (thumb != null && thumb.isNotEmpty) {
        final f = File(
          '${Directory.systemTemp.path}/thumb_${widget.asset.id}.jpg',
        );
        await f.writeAsBytes(thumb);
        widget.onResolved(f);
        return;
      }
    } catch (_) {
      // ignore
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _valid(File? f) => f != null && f.existsSync() && f.lengthSync() > 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          /// 🖼️ THUMBNAIL – LUÔN CÓ
          AssetEntityImage(
            widget.asset,
            fit: BoxFit.cover,
            thumbnailSize: const ThumbnailSize.square(300),
            isOriginal: false,
          ),

          /// ☁️ ICLOUD ICON
          if (_checkedLocal && !_hasOriginLocal && !_loading)
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
          if (_loading)
            Container(
              color: Colors.black45,
              alignment: Alignment.center,
              child: StreamBuilder<PMProgressState>(
                stream: _progress?.stream,
                initialData: const PMProgressState(0, PMRequestState.prepare),
                builder: (_, snap) {
                  final p = snap.data?.progress ?? 0;
                  return Center(
                    child: CircularProgressIndicator(
                      value: p > 0 ? p : null,
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
