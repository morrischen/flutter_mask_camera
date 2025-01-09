import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_mask_camera/colors.dart';
import 'package:gap/gap.dart';

/// 彈窗mixin
mixin DialogMixin<T extends StatefulWidget> on State<T> {
  /// 顯示警告彈窗
  Future<bool?> showAlertDialog(
      {String? title,
      String? content,
      String? confirm,
      String? back,
      TextAlign? titleAlign,
      VoidCallback? onConfirm,
      VoidCallback? onBack,
      bool barrierDismissible = true}) {
    return context.showAlertDialog(
      title: title,
      content: content,
      confirm: confirm,
      back: back,
      titleAlign: titleAlign,
      onConfirm: onConfirm,
      onBack: onBack,
      barrierDismissible: barrierDismissible,
    );
  }
}

/// 彈窗擴充
extension DialogExt on BuildContext {
  /// 顯示警告彈窗
  Future<bool?> showAlertDialog(
      {String? title,
      String? content,
      String? confirm,
      String? back,
      TextAlign? titleAlign,
      VoidCallback? onConfirm,
      VoidCallback? onBack,
      bool barrierDismissible = true}) {
    if (!mounted) {
      return Future<bool?>.value(null);
    }
    Future<void> effectiveOnBack() async {
      onBack?.call();
    }

    Future<void> effectiveOnConfirm() async {
      onConfirm?.call();
    }

    return showDialog<bool>(
        context: this,
        barrierDismissible: barrierDismissible,
        builder: (context) {
          if (defaultTargetPlatform == TargetPlatform.iOS) {
            return CupertinoAlertDialog(
              title: title != null
                  ? Text(title,
                      style: const TextStyle(color: Colors.white),
                      textAlign: titleAlign)
                  : null,
              content: content != null ? Text(content) : null,
              actions: [
                if (onBack != null)
                  CupertinoDialogAction(
                    key: const Key('dialog_cancel'),
                    onPressed: effectiveOnBack,
                    isDestructiveAction: true,
                    child: Text(back ?? AppLocalizations.of(context)!.cancel),
                  ),
                CupertinoDialogAction(
                  key: const Key('dialog_confirm'),
                  onPressed: effectiveOnConfirm,
                  isDefaultAction: true,
                  child: Text(confirm ?? AppLocalizations.of(context)!.confirm),
                )
              ],
            );
          }
          return AlertDialog(
            title: title != null
                ? Text(title,
                    style: const TextStyle(color: Colors.white),
                    textAlign: titleAlign)
                : null,
            content: content != null ? Text(content) : null,
            titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600, color: AppColors.description),
            contentTextStyle: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.description),
            actions: [
              if (onBack != null)
                TextButton(
                    key: const Key('dialog_cancel'),
                    onPressed: effectiveOnBack,
                    child: Text(
                      back ?? AppLocalizations.of(context)!.cancel,
                      style: const TextStyle(color: AppColors.red),
                    )),
              TextButton(
                  key: const Key('dialog_confirm'),
                  onPressed: effectiveOnConfirm,
                  child:
                      Text(confirm ?? AppLocalizations.of(context)!.confirm)),
            ],
          );
        });
  }
}

class CRMDialog extends StatelessWidget {
  const CRMDialog(
      {required this.title,
      required this.image,
      super.key,
      this.content = '',
      this.actions = const [],
      this.barrierDismissible = true});

  /// 標題
  final String title;

  /// 圖片
  final Widget image;

  /// 內文
  final String content;

  /// 按鈕
  final List<Widget> actions;

  /// 點擊空白處是否關閉彈窗
  final bool barrierDismissible;

  @override
  Widget build(BuildContext context) {
    final rawActions = <Widget>[];
    if (actions.isNotEmpty) {
      for (var i = 0; i < actions.length; i++) {
        rawActions.add(
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48, minWidth: 124),
              child: Padding(
                padding: i == actions.length - 1
                    ? EdgeInsets.zero
                    : const EdgeInsets.only(right: 16),
                child: actions[i],
              ),
            ),
          ),
        );
      }
    }
    return PopScope(
      canPop: barrierDismissible,
      child: Dialog(
        backgroundColor: AppColors.dialogBackground,
        surfaceTintColor: AppColors.dialogBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Material(
              elevation: 1.5,
              color: AppColors.dialogBackground,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: SizedBox(
                height: 48,
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    title,
                    maxLines: 1,
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            Container(
              height: 1,
              width: double.infinity,
              color: AppColors.divider,
            ),
            const Gap(24),
            image,
            const Gap(16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Text(
                content,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            const Gap(24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: rawActions,
              ),
            ),
            const Gap(24)
          ],
        ),
      ),
    );
  }
}
