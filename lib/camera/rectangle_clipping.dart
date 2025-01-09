import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mask_camera/camera/camera_mixin.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum RectanglePosition { top, center, bottom }

/// 矩形裁切遮罩
class RectangleClipping extends ConsumerStatefulWidget {
  const RectangleClipping(
      {this.title = '',
      this.height = 275,
      this.position = RectanglePosition.center,
      super.key});

  /// 裁切遮罩標題
  final String title;

  /// 矩形高度
  final double height;

  /// 矩形位置
  final RectanglePosition position;

  @override
  ConsumerState<RectangleClipping> createState() => _RectangleClippingState();
}

class _RectangleClippingState extends ConsumerState<RectangleClipping>
    with CameraMixin {
  /// 設備方向
  late final _orientationProvider =
      StreamProvider.autoDispose<DeviceOrientation>((ref) {
    final stream = orientationStream();
    return stream;
  });

  /// 是否啟用瞄準框
  bool _enableTarget = false;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _enableTarget = true;
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // 判斷是否為直立方向
    final orientation = ref.watch(_orientationProvider).value;
    final isCenterPosition = widget.position == RectanglePosition.center;
    final isPortrait = orientation == DeviceOrientation.portraitUp ||
        orientation == DeviceOrientation.portraitDown;
    return Stack(
      children: [
        // 矩形裁切遮罩
        _buildRectangle(
            isCenterPosition: isCenterPosition, isPortrait: isPortrait),
        // 相機瞄準框
        if (_enableTarget)
          _buildCameraTarget(
              context: context,
              isCenterPosition: isCenterPosition,
              isPortrait: isPortrait),
      ],
    );
  }

  /// 矩形裁切遮罩
  Widget _buildRectangle(
      {required bool isCenterPosition, required bool isPortrait}) {
    // 若為中間遮罩且不為直立方向，則不顯示矩形裁切遮罩
    if (isCenterPosition && !isPortrait) {
      return Container();
    }
    return CustomPaint(
      size: MediaQueryData.fromView(View.of(context)).size,
      painter:
          RectanglePainter(height: widget.height, position: widget.position),
    );
  }

  /// 相機瞄準框
  ///
  /// 根據矩形的位置和裝置的方向來決定瞄準框的對齊方式和尺寸。
  /// 如果矩形位置為中心 (center)，會考慮裝置方向來設定對齊和尺寸，
  /// 否則瞄準框會顯示在畫面的頂部或底部。
  ///
  /// - [isCenterPosition]：指示矩形位置是否為中心。
  /// - [isPortrait]：指示裝置方向是否為直立方向。
  Widget _buildCameraTarget({
    required BuildContext context,
    required bool isCenterPosition,
    required bool isPortrait,
  }) {
    // 設定瞄準框的對齊方式
    // 如果位置為中心且裝置為直立，對齊至指定位置（center、top、bottom）
    // 如果位置為中心但裝置為水平，對齊至畫面中央
    final alignment = isCenterPosition && isPortrait
        ? _getAlignment()
        : isCenterPosition
            ? Alignment.center
            : _getAlignment();
    // 設定瞄準框的寬度和高度
    // 若為直立方向或非中心位置，寬度設為螢幕寬度，高度設為指定的矩形高度
    final width = isPortrait || !isCenterPosition
        ? MediaQueryData.fromView(View.of(context)).size.width
        : null;
    final height = isPortrait || !isCenterPosition ? widget.height : null;
    return Align(
      alignment: alignment,
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          children: [
            // 左上角瞄準框
            _buildTargetFrame(left: 16, top: 16),
            // 右上角瞄準框
            _buildTargetFrame(
                right: 16, top: 16, crossAxisAlignment: CrossAxisAlignment.end),
            // 左下角瞄準框
            _buildTargetFrame(left: 16, bottom: 16, reverse: true),
            // 右下角瞄準框
            _buildTargetFrame(
                right: 16,
                bottom: 16,
                reverse: true,
                crossAxisAlignment: CrossAxisAlignment.end),
            // 拍照文字提示
            if (widget.title.isNotEmpty) _buildPrompt(isCenterPosition),
          ],
        ),
      ),
    );
  }

  /// 相機角落瞄準框
  Widget _buildTargetFrame({
    double? left,
    double? top,
    double? right,
    double? bottom,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start,
    bool reverse = false,
  }) {
    return Positioned(
      left: left,
      top: top,
      right: right,
      bottom: bottom,
      child: Column(
        crossAxisAlignment: crossAxisAlignment,
        children: [
          Container(
            width: reverse ? 2 : 40,
            height: reverse ? 40 : 2,
            color: Colors.white,
          ),
          Container(
            width: reverse ? 40 : 2,
            height: reverse ? 2 : 40,
            color: Colors.white,
          ),
        ],
      ),
    );
  }

  /// 拍照文字提示
  Widget _buildPrompt(bool isCenterPosition) {
    Alignment alignment = Alignment.topCenter;
    EdgeInsets padding = const EdgeInsets.only(top: 16);
    int quarterTurns = 0;
    // 獲取目前的裝置方向
    final orientation = ref.watch(_orientationProvider).value;
    // 設定文字的對齊、間距和旋轉角度
    if (isCenterPosition) {
      switch (orientation) {
        case DeviceOrientation.landscapeLeft:
          alignment = Alignment.centerLeft;
          padding = const EdgeInsets.only(left: 16);
          // 旋轉 270 度
          quarterTurns = 3;
          break;
        case DeviceOrientation.landscapeRight:
          alignment = Alignment.centerRight;
          padding = const EdgeInsets.only(right: 16);
          // 旋轉 90 度
          quarterTurns = 1;
          break;
        default:
          break;
      }
    }
    return Container(
      alignment: alignment,
      padding: padding,
      child: RotatedBox(
        quarterTurns: quarterTurns,
        child: Text(
          widget.title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.8),
                offset: const Offset(2, 2),
                blurRadius: 10,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 相機瞄準框對齊方式
  Alignment _getAlignment() {
    switch (widget.position) {
      case RectanglePosition.top:
        return Alignment.topCenter;
      case RectanglePosition.center:
        return Alignment.center;
      case RectanglePosition.bottom:
        return Alignment.bottomCenter;
    }
  }
}

/// 矩形畫筆
class RectanglePainter extends CustomPainter {
  const RectanglePainter(
      {this.height = 275, this.position = RectanglePosition.center});

  /// 矩形高度
  final double height;

  /// 矩形位置
  final RectanglePosition position;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.5);
    canvas.drawPath(
        Path.combine(
          PathOperation.difference,
          Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
          Path()
            ..addRRect(
              RRect.fromRectAndCorners(
                Rect.fromCenter(
                  center: _getRectanglePosition(size),
                  width: size.width,
                  height: height,
                ),
              ),
            )
            ..close(),
        ),
        paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }

  /// 取得矩形位置
  Offset _getRectanglePosition(Size size) {
    switch (position) {
      case RectanglePosition.top:
        return Offset(size.width * 0.5, height * 0.5);
      case RectanglePosition.center:
        return Offset(size.width * 0.5, size.height * 0.5);
      case RectanglePosition.bottom:
        return Offset(size.width * 0.5, size.height - height * 0.5);
    }
  }
}
