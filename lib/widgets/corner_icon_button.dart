import 'package:flutter/material.dart';

/// 角落图标按钮
/// 
/// 统一处理底部角落位置的图标按钮样式
class CornerIconButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final double size;
  final Color? color;
  final double opacity;
  final String? tooltip;

  const CornerIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.size = 28,
    this.color,
    this.opacity = 0.9,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final actualColor = (color ?? Colors.white).withOpacity(opacity);
    
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(
        icon,
        color: actualColor,
        size: size,
      ),
    );
  }
}

/// 位于底部的角落按钮组
class BottomCornerButtons extends StatelessWidget {
  final Widget? leftButton;
  final Widget? rightButton;

  const BottomCornerButtons({
    super.key,
    this.leftButton,
    this.rightButton,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (leftButton != null)
          Positioned(
            left: 0,
            bottom: 0,
            child: leftButton!,
          ),
        if (rightButton != null)
          Positioned(
            right: 0,
            bottom: 0,
            child: rightButton!,
          ),
      ],
    );
  }
}
