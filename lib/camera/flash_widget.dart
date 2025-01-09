import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mask_camera/gen/assets.gen.dart';

class FLashWidget extends StatelessWidget {
  const FLashWidget({
    required this.mode,
    required this.onPressed,
    super.key,
  });

  final FlashMode mode;
  final void Function(FlashMode mode) onPressed;

  @override
  Widget build(BuildContext context) {
    switch (mode) {
      case FlashMode.off:
        return IconButton(
          iconSize: 48,
          padding: EdgeInsets.zero,
          icon: Assets.icons.icFlashOff.svg(),
          onPressed: () => onPressed(FlashMode.auto),
        );
      case FlashMode.auto:
        return IconButton(
          iconSize: 48,
          padding: EdgeInsets.zero,
          icon: Assets.icons.icFlashAuto.svg(),
          onPressed: () => onPressed(FlashMode.always),
        );
      case FlashMode.always:
        return IconButton(
          iconSize: 48,
          padding: EdgeInsets.zero,
          icon: Assets.icons.icFlashAlways.svg(),
          onPressed: () => onPressed(FlashMode.torch),
        );
      case FlashMode.torch:
        return IconButton(
          iconSize: 48,
          padding: EdgeInsets.zero,
          icon: Assets.icons.icFlashTorch.svg(),
          onPressed: () => onPressed(FlashMode.off),
        );
    }
  }
}
