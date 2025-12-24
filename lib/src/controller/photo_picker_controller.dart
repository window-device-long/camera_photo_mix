// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

class PhotoPickerController extends ChangeNotifier {
  static const int pageSize = 60;
  static const int preloadThreshold = 300;

  final ScrollController scrollController = ScrollController();

  AssetPathEntity? _path;
  final List<AssetEntity> assets = [];

  int _page = 0;
  int _totalCount = 0;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;

  bool get isLoading => _isLoading;

  PhotoPickerController(BuildContext context) {
    scrollController.addListener(() => _onScroll(context));
    _init(context);
  }

  Future<void> _init(BuildContext context) async {
    final ps = await PhotoManager.requestPermissionExtend();
    if (!ps.hasAccess) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    final paths = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      onlyAll: true,
    );

    if (paths.isEmpty) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    _path = paths.first;
    _totalCount = await _path!.assetCountAsync;

    await _loadPage(context, 0, clear: true);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadPage(
    BuildContext context,
    int page, {
    bool clear = false,
  }) async {
    if (_path == null) return;

    final result = await _path!.getAssetListPaged(page: page, size: pageSize);

    // 🔥 PRELOAD THUMBNAIL
    for (final asset in result) {
      final provider = AssetEntityImageProvider(
        asset,
        isOriginal: false,
        thumbnailSize: const ThumbnailSize.square(200),
      );
      precacheImage(provider, context);
    }

    if (clear) assets.clear();
    assets.addAll(result);

    _page = page;
    _hasMore = assets.length < _totalCount;
    _isLoadingMore = false;

    notifyListeners();
  }

  void _onScroll(BuildContext context) {
    if (!_hasMore || _isLoadingMore || _isLoading) return;

    if (scrollController.position.pixels >
        scrollController.position.maxScrollExtent - preloadThreshold) {
      _isLoadingMore = true;
      _loadPage(context, _page + 1);
    }
  }

  void disposeController() {
    scrollController.dispose();
  }
}
