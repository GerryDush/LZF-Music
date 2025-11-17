import 'package:flutter/material.dart';

enum RadixButtonVariant { solid, outline, ghost }
enum RadixButtonSize { small, medium, large }

class RadixButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final RadixButtonVariant variant;
  final RadixButtonSize size;
  final bool disabled;

  const RadixButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.variant = RadixButtonVariant.solid,
    this.size = RadixButtonSize.medium,
    this.disabled = false,
  });

  const RadixButton.icon({
    super.key,
    required this.label,
    required this.icon,
    this.onPressed,
    this.variant = RadixButtonVariant.solid,
    this.size = RadixButtonSize.medium,
    this.disabled = false,
  });

  @override
  State<RadixButton> createState() => _RadixButtonState();
}

class _RadixButtonState extends State<RadixButton> {
  bool _hover = false;
  bool _pressed = false;

  double get _height {
    switch (widget.size) {
      case RadixButtonSize.small:
        return 28;
      case RadixButtonSize.medium:
        return 36;
      case RadixButtonSize.large:
        return 44;
    }
  }

  double get _fontSize {
    switch (widget.size) {
      case RadixButtonSize.small:
        return 13;
      case RadixButtonSize.medium:
        return 14;
      case RadixButtonSize.large:
        return 15;
    }
  }

  double get _radius {
    switch (widget.size) {
      case RadixButtonSize.small:
        return 4;
      case RadixButtonSize.medium:
        return 4;
      case RadixButtonSize.large:
        return 10;
    }
  }

  EdgeInsets get _padding {
    switch (widget.size) {
      case RadixButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 10);
      case RadixButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 14);
      case RadixButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 18);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;
    final onColor = theme.colorScheme.onPrimary;
    final surface = theme.colorScheme.surface;
    
    final outline = theme.brightness == Brightness.dark ? Colors.white12 : Colors.black12;
    Color bgColor;
    Color borderColor;
    Color textColor;

    switch (widget.variant) {
      case RadixButtonVariant.solid:
        bgColor = widget.disabled
            ? color.withOpacity(0.35)
            : (_hover ? color.withOpacity(0.9) : color);
        borderColor = Colors.transparent;
        textColor = onColor;
        break;
      case RadixButtonVariant.outline:
        bgColor = surface;
        borderColor = ( _hover ? theme.colorScheme.primary.withOpacity(0.12) : outline );
        textColor = color;
        break;
      case RadixButtonVariant.ghost:
        bgColor = _pressed
            ? color.withOpacity(0.08)
            : (_hover ? color.withOpacity(0.04) : Colors.transparent);
        borderColor = Colors.transparent;
        textColor = color;
        break;
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() {
        _hover = false;
        _pressed = false;
      }),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.disabled ? null : widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: _height,
          padding: _padding,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(_radius),
            border: Border.all(color: borderColor, width: 1),
            
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: _fontSize,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              
              if (widget.icon != null)
                Icon(widget.icon, size: 20, color: textColor),
            ],
          ),
        ),
      ),
    );
  }
}