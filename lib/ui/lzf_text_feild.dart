import 'package:flutter/material.dart';



/// ============================
/// RadixTextField 组件
/// ============================

enum RadixFieldSize { small, medium, large }

class RadixTextField extends StatefulWidget {
  final TextEditingController controller;
  final String? label;
  final String? placeholder;
  final Widget? leading;
  final Widget? trailing;
  final bool clearable;
  final bool enabled;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final RadixFieldSize size;

  const RadixTextField({
    super.key,
    required this.controller,
    this.label,
    this.placeholder,
    this.leading,
    this.trailing,
    this.clearable = false,
    this.enabled = true,
    this.errorText,
    this.onChanged,
    this.size = RadixFieldSize.small,
  });

  @override
  State<RadixTextField> createState() => _RadixTextFieldState();
}

class _RadixTextFieldState extends State<RadixTextField> {
  late FocusNode _focusNode;
  bool _hover = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  double get _height {
    switch (widget.size) {
      case RadixFieldSize.small:
        return 36;
      case RadixFieldSize.medium:
        return 44;
      case RadixFieldSize.large:
        return 52;
    }
  }

  double get _fontSize {
    switch (widget.size) {
      case RadixFieldSize.small:
        return 13;
      case RadixFieldSize.medium:
        return 14;
      case RadixFieldSize.large:
        return 16;
    }
  }

  EdgeInsets get _padding {
    switch (widget.size) {
      case RadixFieldSize.small:
        return const EdgeInsets.symmetric(horizontal: 10);
      case RadixFieldSize.medium:
        return const EdgeInsets.symmetric(horizontal: 12);
      case RadixFieldSize.large:
        return const EdgeInsets.symmetric(horizontal: 14);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFocused = _focusNode.hasFocus;
    final isError = widget.errorText != null && widget.errorText!.isNotEmpty;
    final enabled = widget.enabled;

    // 基础颜色
    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;
    final outline = theme.brightness == Brightness.dark ? Colors.white12 : Colors.black12;
    final muted = theme.brightness == Brightness.dark ? Colors.white38 : Colors.black45;


    final borderColor = isError
        ? Colors.redAccent
        : (isFocused ? primary : ( _hover ? theme.colorScheme.primary.withOpacity(0.12) : outline ));

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.label != null) ...[
            Padding(
              padding: EdgeInsets.only(left: widget.leading != null ? 2 : 0, bottom: 6),
              child: Text(
                widget.label!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: onSurface.withOpacity(0.75),
                ),
              ),
            ),
          ],
          AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            
            
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: isFocused?borderColor:Colors.transparent, width: 1),
            
            ),
            child: Container(
              height: _height,
              padding: _padding,
              decoration: BoxDecoration(
              color: enabled ? surface : surface.withOpacity(0.9),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: borderColor, width: 1.0),
              
            ),
              child: Row(
              children: [
                if (widget.leading != null) ...[
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: IconTheme(
                      data: IconThemeData(size: _fontSize + 2, color: muted),
                      child: widget.leading!,
                    ),
                  ),
                ],
                Expanded(
                  child: IgnorePointer(
                    ignoring: !enabled,
                    child: TextField(
                      controller: widget.controller,
                      focusNode: _focusNode,
                      style: TextStyle(fontSize: _fontSize, color: onSurface),
                      decoration: InputDecoration(
                        isCollapsed: true,
                        border: InputBorder.none,
                        hintText: widget.placeholder,
                        hintStyle: TextStyle(fontSize: _fontSize, color: onSurface.withOpacity(0.45)),
                        contentPadding: EdgeInsets.zero,
                      ),
                      cursorColor: primary,
                      onChanged: widget.onChanged,
                    ),
                  ),
                ),
                // clear 按钮优先级高于 trailing
                if (widget.clearable && widget.controller.text.isNotEmpty && enabled) ...[
                  GestureDetector(
                    onTap: () {
                      widget.controller.clear();
                      widget.onChanged?.call('');
                      // 保持 focus
                      FocusScope.of(context).requestFocus(_focusNode);
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Icon(Icons.close, size: _fontSize + 2, color: muted),
                    ),
                  ),
                ] else if (widget.trailing != null) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: IconTheme(
                      data: IconThemeData(size: _fontSize + 2, color: muted),
                      child: widget.trailing!,
                    ),
                  ),
                ],
              ],
            ),
            ),
          ),
          if (isError) ...[
            const SizedBox(height: 6),
            Text(
              widget.errorText!,
              style: TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}