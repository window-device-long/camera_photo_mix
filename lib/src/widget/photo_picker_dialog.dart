import 'dart:io';

import 'package:camera_photo_mix/src/controller/photo_picker_controller.dart';
import 'package:camera_photo_mix/src/enums/pick_action.dart';
import 'package:camera_photo_mix/src/widget/asset_file_loading_icloud.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

typedef OnPickDeferred = Future<void> Function();

class PhotoPickerDialog extends StatefulWidget {
  const PhotoPickerDialog({super.key, this.onPickStarted});

  final OnPickDeferred? onPickStarted;

  @override
  State<PhotoPickerDialog> createState() => _PhotoPickerDialogState();
}

class _PhotoPickerDialogState extends State<PhotoPickerDialog> {
  late final PhotoPickerController controller;

  bool _demoDownloading = false;
  int selectedDemoIndex = 0;
  double _demoProgress = 0;

  final List<String> demoTitles = [
    "assets/images/01.jpg",
    "assets/images/02.jpg",
    "assets/images/03.jpg",
    "assets/images/04.jpeg",
  ];

  Future<File?> _loadDemoToFile(String assetPath) async {
    setState(() {
      _demoDownloading = true;
      _demoProgress = 0;
    });

    try {
      for (int i = 1; i <= 5; i++) {
        await Future.delayed(const Duration(milliseconds: 120));
        if (!mounted) return null;
        setState(() => _demoProgress = i / 5);
      }

      final byteData = await DefaultAssetBundle.of(context).load(assetPath);
      final tempDir = Directory.systemTemp;

      final file = File('${tempDir.path}/${assetPath.split('/').last}');

      await file.writeAsBytes(byteData.buffer.asUint8List());

      return file;
    } catch (_) {
      return null;
    } finally {
      if (mounted) {
        setState(() => _demoDownloading = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    controller = PhotoPickerController(context);
    controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    controller.disposeController();
    super.dispose();
  }

  void _openCamera() {
    if (!mounted) return;

    Navigator.of(context, rootNavigator: true).pop(CameraAction());
  }

  // ===== DEMO BAR =====
  Widget _buildDemoBar() {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemCount: demoTitles.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final bool selected = index == selectedDemoIndex;
          return GestureDetector(
            onTap: _demoDownloading
                ? null
                : () async {
                    widget.onPickStarted?.call();
                    setState(() => selectedDemoIndex = index);

                    final file = await _loadDemoToFile(demoTitles[index]);

                    if (!mounted || file == null) return;

                    Navigator.of(
                      context,

                      rootNavigator: true,
                    ).pop(GalleryResult(file: file));
                  },
            child: ClipRRect(
              borderRadius: BorderRadiusGeometry.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 72,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: selected ? Colors.white : Colors.grey.shade800,
                  image: DecorationImage(
                    image: AssetImage(demoTitles[index]),
                    fit: BoxFit.cover,
                  ),
                ),
                alignment: Alignment.center,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const Text(
                  'Select Image',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            _buildDemoBar(),

            const Divider(color: Colors.white24),

            // ===== GALLERY GRID =====
            Expanded(
              child: controller.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : GridView.builder(
                      controller: controller.scrollController,
                      padding: const EdgeInsets.all(8),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 4,
                            mainAxisSpacing: 4,
                          ),
                      itemCount: controller.assets.length + 1,
                      itemBuilder: (context, index) {
                        // 📷 CAMERA TILE
                        if (index == 0) {
                          return GestureDetector(
                            onTap: _openCamera,
                            child: Container(
                              color: Colors.grey.shade800,
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          );
                        }

                        final asset = controller.assets[index - 1];
                        return _buildAssetItem(asset);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssetItem(AssetEntity asset) {
    return AssetThumbnailWithOriginLoader(
      asset: asset,
      onOriginReady: (file) {
        if (!mounted) return;

        Navigator.of(
          context,
          rootNavigator: true,
        ).pop(GalleryResult(file: file));
      },
      onTap: () {
        widget.onPickStarted?.call();
      },
    );
  }
}

class _ShimmerBox extends StatefulWidget {
  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return FractionallySizedBox(
          widthFactor: 0.3,
          alignment: Alignment(-1 + 2 * _controller.value, 0),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.white.withOpacity(0.15),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
