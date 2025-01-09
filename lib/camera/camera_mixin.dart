import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';
import 'package:sensors_plus/sensors_plus.dart';

mixin CameraMixin {
  /// 檢查相機權限
  Future<bool> checkCameraPermission() async {
    final status = await Permission.camera.status;
    if (status.isGranted) {
      return true;
    }
    final result = await Permission.camera.request();
    return result.isGranted;
  }

  /// 設備方向
  Stream<DeviceOrientation> orientationStream() {
    final stream = accelerometerEventStream();
    return stream.map((event) {
      final DeviceOrientation orientation;
      if (event.z < -8.0) {
        orientation = DeviceOrientation.portraitUp;
      } else if (event.x > 5.0) {
        orientation = DeviceOrientation.landscapeRight;
      } else if (event.x < -5.0) {
        orientation = DeviceOrientation.landscapeLeft;
      } else {
        orientation = DeviceOrientation.portraitUp;
      }
      return orientation;
    });
  }

  /// 裁切圖片
  Future<File?> cropImage({
    required XFile xFile,
    required double height,
    required DeviceOrientation? orientation,
  }) async {
    // 處理後的圖片
    img.Image? processedImage;
    // 讀取原始圖片
    final bytes = File(xFile.path).readAsBytesSync();
    final originalImage = img.decodeImage(bytes);
    if (originalImage == null) {
      return null;
    }
    // 原始圖片的尺寸
    final imageWidth = originalImage.width;
    final imageHeight = originalImage.height;
    // 判斷是否為直向模式
    final isPortrait = orientation == DeviceOrientation.portraitUp ||
        orientation == DeviceOrientation.portraitDown;
    // 若為直向模式則進行裁切圖片，否則處理旋轉圖片
    if (isPortrait) {
      // 計算裁切區域
      final top = height * 0.5;
      // 計算圖片與螢幕的縮放比例
      final scaleY = imageHeight / (height * 2);
      // 將 top 和 height 轉換成圖片的像素範圍
      final cropTop = (top * scaleY).round();
      final cropHeight = (height * scaleY).round();
      // 確保裁切範圍不超過圖片邊界
      final finalCropTop = cropTop.clamp(0, imageHeight - cropHeight);
      // 裁切圖片
      processedImage = img.copyCrop(
        originalImage,
        x: 0,
        y: finalCropTop,
        width: imageWidth,
        height: cropHeight,
      );
    } else {
      // 若為橫向模式，處理旋轉
      final rotationAngle = getRotationAngle(orientation);
      processedImage = img.copyRotate(originalImage, angle: rotationAngle);
    }
    // 儲存處理後的圖片
    final croppedBytes = img.encodeJpg(processedImage, quality: 50);
    final croppedFile = File(xFile.path.replaceFirst('.jpg', '_cropped.jpg'));
    croppedFile.writeAsBytesSync(croppedBytes);
    return croppedFile;
  }

  /// 獲取旋轉角度
  int getRotationAngle(DeviceOrientation? orientation) {
    return switch (orientation) {
      DeviceOrientation.landscapeLeft => 90,
      DeviceOrientation.landscapeRight => -90,
      _ => 0,
    };
  }
}
