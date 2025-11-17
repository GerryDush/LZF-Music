import 'package:flutter/material.dart';
import './lzf_button.dart';


class RadixSelect extends StatefulWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;
  final RadixButtonSize size;

  const RadixSelect({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.size = RadixButtonSize.medium,
  });

  @override
  State<RadixSelect> createState() => _RadixSelectState();
}

class _RadixSelectState extends State<RadixSelect> {
  final GlobalKey _triggerKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  void _toggleMenu() {
    if (_isOpen) {
      _removeOverlay();
    } else {
      _showOverlay();
    }
  }

  void _showOverlay() {
    final renderBox =
        _triggerKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => _DropdownOverlay(
        triggerOffset: offset,
        triggerSize: size,
        items: widget.items,
        selectedValue: widget.value, // ✅ 传入当前选中项
        onItemTap: (val) {
          widget.onChanged(val);
          _removeOverlay();
        },
        onClose: _removeOverlay,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) setState(() => _isOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: _triggerKey,
      child: RadixButton.icon(
        label: widget.value,
        icon: Icons.arrow_drop_down,
        size: widget.size,
        onPressed: _toggleMenu,
        variant: RadixButtonVariant.outline,
      ),
    );
  }
}

//
// ======================================
// 🔘 Radix Button
// ======================================
//


//
// ======================================
// ⬇️ Dropdown Overlay + Item
// ======================================
//

class _DropdownOverlay extends StatefulWidget {
  final Offset triggerOffset;
  final Size triggerSize;
  final List<String> items;
  final String selectedValue;
  final ValueChanged<String> onItemTap;
  final VoidCallback onClose;

  const _DropdownOverlay({
    required this.triggerOffset,
    required this.triggerSize,
    required this.items,
    required this.selectedValue,
    required this.onItemTap,
    required this.onClose,
  });

  @override
  State<_DropdownOverlay> createState() => _DropdownOverlayState();
}

class _DropdownOverlayState extends State<_DropdownOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 150))
      ..forward();

    _scale = Tween(begin: 0.96, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _opacity = Tween(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const menuWidth = 220.0;
    const sideOffset = 6.0;

    double left = widget.triggerOffset.dx;
    double top =
        widget.triggerOffset.dy + widget.triggerSize.height + sideOffset;

    final theme = Theme.of(context);
    final surface = theme.colorScheme.surface;
    final borderColor =
        theme.brightness == Brightness.dark ? Colors.white10 : Colors.black12;

    return Stack(
      children: [
        GestureDetector(
          onTap: widget.onClose,
          child: Container(color: Colors.transparent, width: double.infinity, height: double.infinity),
        ),
        Positioned(
          left: left,
          top: top,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) => Transform.scale(
              scale: _scale.value,
              alignment: Alignment.topLeft,
              child: Opacity(opacity: _opacity.value, child: child),
            ),
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(4),
              child: Container(
                width: menuWidth,
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: borderColor),
                ),
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  children: widget.items
                      .map((e) => _DropdownItem(
                            text: e,
                            isSelected: e == widget.selectedValue, // ✅ 当前选中项
                            onTap: () => widget.onItemTap(e),
                          ))
                      .toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DropdownItem extends StatefulWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  const _DropdownItem({
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_DropdownItem> createState() => _DropdownItemState();
}

class _DropdownItemState extends State<_DropdownItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final textColor = Theme.of(context).colorScheme.onSurface;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Padding(padding: EdgeInsets.symmetric(horizontal: 4),child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: (_hover ? color.withOpacity(0.08) : Colors.transparent),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.text,
                  style: TextStyle(
                    color:widget.isSelected
                ? color:textColor,
                    fontSize: 14,
                    fontWeight:
                        widget.isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              if (widget.isSelected)
                Icon(Icons.check, size: 16, color: color),
            ],
          ),
        ),
      ),),
    );
  }
}