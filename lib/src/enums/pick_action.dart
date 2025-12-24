import 'dart:io';

sealed class PickerAction {}

class GalleryResult extends PickerAction {
  final File file;

  GalleryResult({required this.file});
}

class GalleryDeferredResult extends PickerAction {
  final Future<File?> Function() resolveFile;

  GalleryDeferredResult({required this.resolveFile});
}

class CameraAction extends PickerAction {}
