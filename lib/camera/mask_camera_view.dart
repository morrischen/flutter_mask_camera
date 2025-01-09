import 'dart:io';

import 'package:camera/camera.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_mask_camera/camera/camera_mixin.dart';
import 'package:flutter_mask_camera/camera/flash_widget.dart';
import 'package:flutter_mask_camera/camera/rectangle_clipping.dart';
import 'package:flutter_mask_camera/extension/dialog_extension.dart';
import 'package:flutter_mask_camera/gen/assets.gen.dart';
import 'package:flutter_mask_camera/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

class MaskCameraView extends ConsumerStatefulWidget {
  const MaskCameraView(
      {required this.contentHeight,
      required this.rectangleTitle,
      required this.rectanglePosition,
      this.lockCaptureToPortrait = true,
      this.onTakePicture,
      super.key});

  /// 內容高度
  final double contentHeight;

  /// 矩形裁切遮罩標題
  final String rectangleTitle;

  /// 矩形位置
  final RectanglePosition rectanglePosition;

  /// 是否鎖定拍照方向為直立向上
  final bool lockCaptureToPortrait;

  /// 拍照完成事件，回傳File與DeviceOrientation
  final void Function({File? file, DeviceOrientation? orientation})?
      onTakePicture;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _MaskCameraViewState();
}

class _MaskCameraViewState extends ConsumerState<MaskCameraView>
    with WidgetsBindingObserver, DialogMixin, CameraMixin {
  /// 相機控制器
  CameraController? _cameraController;

  /// 設備方向
  late final _orientationProvider =
      StreamProvider.autoDispose<DeviceOrientation>((ref) {
    final stream = orientationStream();
    return stream;
  });

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
    super.initState();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _cameraController;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.resumed) {
      _initializeCameraController(cameraController.description);
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(child: _buildCameraPreview()),
              Positioned.fill(child: _buildRectangleClipping())
            ],
          ),
        ),
        // 相機控制列
        _buildCameraControl(),
      ],
    );
  }

  /// 相機預覽
  Widget _buildCameraPreview() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return Container();
    }
    return AspectRatio(
      aspectRatio: _cameraController!.value.aspectRatio,
      child: CameraPreview(_cameraController!),
    );
  }

  /// 相機控制列
  Widget _buildCameraControl() {
    final CameraController? cameraController = _cameraController;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return Container();
    }
    return Consumer(builder: (context, ref, _) {
      final orientation = ref.watch(_orientationProvider).value;
      return Column(
        children: [
          Container(
            padding:
                const EdgeInsets.only(left: 12, top: 12, right: 12, bottom: 0),
            color: Colors.white,
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  flex: 1,
                  child: Container(),
                ),
                Expanded(
                  flex: 1,
                  child: _buildRotationButton(
                    orientation: orientation,
                    child: IconButton(
                      key: const Key('takePicture'),
                      iconSize: 72,
                      padding: EdgeInsets.zero,
                      icon: Assets.icons.icCamera.svg(),
                      onPressed: () => takePicture(orientation),
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    child: _buildRotationButton(
                      orientation: orientation,
                      child: FLashWidget(
                        mode: cameraController.value.flashMode,
                        onPressed: (mode) => setFlashMode(mode),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
          // safe area padding
          Container(
              color: Colors.white,
              width: double.infinity,
              height: MediaQueryData.fromView(View.of(context)).padding.bottom)
        ],
      );
    });
  }

  /// 矩形裁剪
  Widget _buildRectangleClipping() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return Container();
    }
    return RectangleClipping(
        title: widget.rectangleTitle,
        height: widget.contentHeight * 0.5,
        position: widget.rectanglePosition);
  }

  /// 旋轉按鈕
  Widget _buildRotationButton(
      {required DeviceOrientation? orientation, required Widget child}) {
    return AnimatedRotation(
      duration: const Duration(milliseconds: 200),
      turns: switch (orientation) {
        DeviceOrientation.portraitUp => 0,
        DeviceOrientation.landscapeRight => .25,
        DeviceOrientation.landscapeLeft => -.25,
        _ => 0,
      },
      child: child,
    );
  }

  /// 初始化相機
  Future<void> _initializeCamera() async {
    final cameraDescription = await _getCameraDescription();
    if (!mounted) {
      return;
    }
    if (cameraDescription == null) {
      showAlertDialog(
          title: AppLocalizations.of(context)!.dialogErrorTitle,
          content: AppLocalizations.of(context)!.noCameraDescription);
      return;
    }
    await _initializeCameraController(cameraDescription);
  }

  /// 取得相機描述
  Future<CameraDescription?> _getCameraDescription() async {
    final cameras = await availableCameras();
    return cameras
        .firstWhereOrNull((e) => e.lensDirection == CameraLensDirection.back);
  }

  /// 初始化相機控制器
  Future<void> _initializeCameraController(
      CameraDescription cameraDescription) async {
    final hasPermission = await checkCameraPermission();
    if (!hasPermission) {
      if (!mounted) {
        return;
      }
      // 顯示無相機權限提示
      await showAlertDialog(
        title: AppLocalizations.of(context)!.noCameraPermission,
        onConfirm: () async => await openAppSettings(),
      );
      // 重新初始化相機控制器
      _initializeCameraController(cameraDescription);
      return;
    }
    final CameraController cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.high,
      imageFormatGroup: ImageFormatGroup.jpeg,
      enableAudio: false,
    );
    _cameraController = cameraController;
    try {
      await cameraController.initialize();
      // 鎖定拍照方向為直立向上
      if (widget.lockCaptureToPortrait) {
        await _cameraController
            ?.lockCaptureOrientation(DeviceOrientation.portraitUp);
      }
      await setFlashMode(FlashMode.auto);
      if (mounted) {
        setState(() {});
      }
    } on CameraException catch (e) {
      kLogger.e('相機初始化失敗', error: e);
      if (mounted) {
        showAlertDialog(
            title: AppLocalizations.of(context)!.dialogErrorTitle,
            content: AppLocalizations.of(context)!
                .cameraStartError(e.description ?? ''));
      }
    }
  }

  /// 拍照
  Future<void> takePicture(DeviceOrientation? orientation) async {
    File? croppedImage;
    try {
      final xFile = await _cameraController?.takePicture();
      if (xFile != null) {
        croppedImage = await cropImage(
            xFile: xFile,
            height: widget.contentHeight,
            position: widget.rectanglePosition,
            orientation: orientation);
      }
      widget.onTakePicture?.call(file: croppedImage, orientation: orientation);
    } catch (e, s) {
      kLogger.d('拍照失敗', error: e, stackTrace: s);
    }
  }

  /// 設定閃光燈模式
  Future<void> setFlashMode(FlashMode mode) async {
    if (_cameraController == null) {
      return;
    }
    try {
      await _cameraController?.setFlashMode(mode);
    } on CameraException catch (e) {
      kLogger.d('設定閃光燈模式失敗', error: e);
    }
  }
}
