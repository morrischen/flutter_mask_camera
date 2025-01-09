import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_mask_camera/camera/camera_mixin.dart';
import 'package:flutter_mask_camera/camera/mask_camera_view.dart';
import 'package:flutter_mask_camera/camera/rectangle_clipping.dart';
import 'package:flutter_mask_camera/extension/dialog_extension.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 相機拍照頁面
class CameraDialog extends ConsumerStatefulWidget {
  const CameraDialog(
      {required this.title, super.key});

  /// 標題
  final String title;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _CameraDialogState();
}

class _CameraDialogState extends ConsumerState<CameraDialog>
    with WidgetsBindingObserver, DialogMixin, CameraMixin {
  /// 是否相機全螢幕模式
  bool isCameraFullMode = true;

  @override
  void initState() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final contentHeight = _getContentHeight(context);
    return Container(
      color: Colors.black,
      padding: EdgeInsets.only(
          top: MediaQueryData.fromView(View.of(context)).padding.top),
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          title: Text(
            widget.title,
            style: const TextStyle(color: Colors.white),
          ),
          leading: IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: MaskCameraView(
                contentHeight: contentHeight,
                rectangleTitle: AppLocalizations.of(context)!.takePicture,
                rectanglePosition: RectanglePosition.bottom,
                onTakePicture: ({File? file, DeviceOrientation? orientation}) =>
                    _takePicture(file: file, orientation: orientation),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 處理拍照
  Future<void> _takePicture(
      {File? file, DeviceOrientation? orientation}) async {
    if (mounted && file != null) {
      Navigator.pop(context, file);
    }
  }

  /// 取得內容高度
  double _getContentHeight(BuildContext context) {
    final mediaQuery = MediaQueryData.fromView(View.of(context));
    return mediaQuery.size.height -
        kToolbarHeight -
        kBottomNavigationBarHeight -
        mediaQuery.padding.top -
        mediaQuery.padding.bottom -
        84;
  }
}
