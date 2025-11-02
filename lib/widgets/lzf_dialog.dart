import 'package:flutter/material.dart';
import 'package:lzf_music/utils/theme_utils.dart';

class LZFDialog extends StatelessWidget {
  final Widget? title;
  final String? titleText;
  final Widget content;
  final String? confirmText;
  final VoidCallback? onConfirm;
  final String? cancelText;
  final VoidCallback? onCancel;
  final bool danger;
  final double width;

  const LZFDialog({
    super.key,
    this.title,
    this.titleText,
    required this.content,
    this.confirmText,
    this.onConfirm,
    this.cancelText,
    this.onCancel,
    this.danger = false,
    this.width = 400,
  });

  static Future<void> show(
    BuildContext context, {
    Widget? title,
    String? titleText,
    required Widget content,
    String? confirmText,
    VoidCallback? onConfirm,
    String? cancelText,
    VoidCallback? onCancel,
    bool danger = false,
    double width = 400,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => PopScope(
        onPopInvokedWithResult: (_, __) {
          onCancel?.call();
        },
        child: GestureDetector(
          onTap: () {}, // 阻止点击穿透
          child: LZFDialog(
            title: title,
            titleText: titleText,
            content: content,
            confirmText: confirmText,
            onConfirm: onConfirm,
            cancelText: cancelText,
            onCancel: onCancel,
            danger: danger,
            width: width,
          ),
        ),
      ),
    );
  }

  static void close(BuildContext context) {
    if (Navigator.of(context).canPop()) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: SizedBox(
        width: width,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 22.0, horizontal: 26.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null) ...[
                title!,
                const SizedBox(height: 16),
              ] else if (titleText != null) ...[
                Text(
                  titleText!,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
              ],
              content,
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (cancelText != null)
                    TextButton(
                      onPressed: () {
                        onCancel?.call();
                        Navigator.of(context).pop();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: ThemeUtils.select(
                          context,
                          light: Colors.grey[700],
                          dark: Colors.grey[300],
                        ),
                      ),
                      child: Text(cancelText!),
                    ),
                  if (cancelText != null && confirmText != null)
                    const SizedBox(width: 12),
                  if (confirmText != null)
                    TextButton(
                      onPressed: () {
                        onConfirm?.call();
                        Navigator.of(context).pop();
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: danger
                            ? Colors.red[800]
                            : ThemeUtils.primaryColor(context),
                        foregroundColor: danger
                            ? Colors.white
                            : ThemeUtils.select(
                                context,
                                light: Colors.white,
                                dark: Colors.black,
                              ),
                        elevation: 0,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(confirmText!),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
