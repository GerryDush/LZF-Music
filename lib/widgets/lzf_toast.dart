
import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:async';

class LZFToast extends StatefulWidget {
  final String message;
  final VoidCallback? onDismiss;

  const LZFToast({Key? key, required this.message, this.onDismiss})
    : super(key: key);

  @override
  State<LZFToast> createState() => _LZFToastState();

  static void show(BuildContext context, String message) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => LZFToast(
        message: message,
        onDismiss: () {
          overlayEntry.remove();
        },
      ),
    );

    overlay.insert(overlayEntry);
  }
}

class _LZFToastState extends State<LZFToast>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _animationController.forward();
    Future.delayed(const Duration(milliseconds: 500)).then((_) => _dismiss());
  }

  Future<void> _dismiss() async {
    if (_animationController.isAnimating || !mounted) return;

    try {
      await _animationController.reverse();
    } catch (e) {
      print(e);
    }

    if (mounted) {
      widget.onDismiss?.call();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        // 点击空白处关闭
        onTap: _dismiss,
        behavior: HitTestBehavior.translucent,
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.85,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 20,
                      ),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? Colors.white.withOpacity(0.2)
                            : Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDarkMode
                              ? Colors.white.withOpacity(0.1)
                              : Colors.black.withOpacity(0.1),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              widget.message,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                height: 1.3,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
