import 'package:flutter/material.dart';
import 'package:lzf_music/utils/theme_utils.dart';
// 假设这是你项目里的 RadixButton 定义，如果没有，下面代码里我用 InkWell 模拟了无边框效果
import './lzf_button.dart'; 

/// 对齐方式枚举
enum RadixSelectAlign {
  left,
  center, 
  right,
}

class RadixSelect extends StatefulWidget {
  final String? value;
  final String? placeholder;
  final List<String> items;
  final ValueChanged<String> onChanged;
  final RadixButtonSize size;
  final Widget Function(String)? itemBuilder;
  
  // --- 新增参数 ---
  final IconData? icon;           // 仅显示图标 (覆盖 label)
  final double menuWidth;         // 弹出菜单宽度
  final RadixSelectAlign align;   // 对齐方式
  final bool hideBorder;          // 是否隐藏边框
  final double borderRadius;      // 按钮圆角

  const RadixSelect({
    super.key,
    this.value,
    this.placeholder,
    required this.items,
    required this.onChanged,
    this.size = RadixButtonSize.medium,
    // 默认值
    this.icon,
    this.menuWidth = 220.0,
    this.align = RadixSelectAlign.left,
    this.hideBorder = false,
    this.borderRadius = 6.0,
    this.itemBuilder,
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
    final renderBox = _triggerKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => _DropdownOverlay(
        triggerOffset: offset,
        triggerSize: size,
        items: widget.items,
        selectedValue: widget.value,
        menuWidth: widget.menuWidth, // 传入自定义宽度
        align: widget.align,         // 传入自定义对齐
        onItemTap: (val) {
          widget.onChanged(val);
          _removeOverlay();
        },
        onClose: _removeOverlay,
        itemBuilder: widget.itemBuilder,
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
        borderRadius: widget.borderRadius,
        icon: widget.icon??Icons.arrow_drop_down,
        size: widget.size,
        onPressed: _toggleMenu,
        variant: RadixButtonVariant.outline,
        activeColor: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

}

//
// ======================================
// ⬇️ Dropdown Overlay
// ======================================
//

class _DropdownOverlay extends StatefulWidget {
  final Offset triggerOffset;
  final Size triggerSize;
  final List<String> items;
  final String? selectedValue;
  final ValueChanged<String> onItemTap;
  final VoidCallback onClose;
  final Widget Function(String) ?itemBuilder;
  
  // 新增
  final double menuWidth;
  final RadixSelectAlign align;

  const _DropdownOverlay({
    required this.triggerOffset,
    required this.triggerSize,
    required this.items,
    required this.selectedValue,
    required this.onItemTap,
    required this.onClose,
    required this.menuWidth,
    required this.align,
    this.itemBuilder,
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
    final menuWidth = widget.menuWidth;
    const sideOffset = 6.0;
    const screenPadding = 10.0;

    final size = MediaQuery.of(context).size;
    
    // 按钮的坐标信息
    final buttonLeft = widget.triggerOffset.dx;
    final buttonWidth = widget.triggerSize.width;
    final buttonTop = widget.triggerOffset.dy;
    final buttonHeight = widget.triggerSize.height;

    // ============================================================
    // 1. 水平方向逻辑：决定使用 Positioned 的 left 还是 right 属性
    // ============================================================
    
    double? posLeft;
    double? posRight;
    bool isRightAligned = false; // 用于决定动画锚点

    // 默认：左对齐 (菜单左边缘 == 按钮左边缘)
    // 判断：如果 (按钮左边 + 菜单宽) 超过了屏幕右边界，就切换为右对齐
    if (buttonLeft + menuWidth > size.width - screenPadding) {
      // --- 右对齐模式 ---
      isRightAligned = true;
      // 计算 Positioned(right: ...)，即距离屏幕右侧的距离
      // 距离 = 屏幕总宽 - 按钮右边缘
      posRight = size.width - (buttonLeft + buttonWidth);
      
      // 边界保护：如果右侧距离小于 padding（极右），强制设为 padding
      if (posRight < screenPadding) posRight = screenPadding;
    } else {
      // --- 左对齐模式 ---
      isRightAligned = false;
      posLeft = buttonLeft;
      
      // 边界保护：如果左侧小于 padding（极左），强制设为 padding
      if (posLeft < screenPadding) posLeft = screenPadding;
    }


    // ============================================================
    // 2. 垂直方向逻辑：决定使用 Positioned 的 top 还是 bottom
    //    (虽然 Positioned 通常只用 top，但为了计算弹出位置，这里算出 top 值)
    // ============================================================

    final estimatedHeight = (widget.items.length * 38.0) + 16.0;
    final bottomSpace = size.height - (buttonTop + buttonHeight);
    final topSpace = buttonTop;

    bool showAbove = false;
    // 如果下方不够放 且 上方空间更大，则向上弹出
    if (bottomSpace < estimatedHeight && topSpace > bottomSpace) {
      showAbove = true;
    }

    double top;
    double? maxHeight;

    if (showAbove) {
      // 向上弹出：top = 按钮顶部 - 菜单高度 - 间距
      // 注意：这里需要给 BoxConstraints 传 maxHeight，否则菜单可能会盖住按钮或溢出屏幕顶端
      top = buttonTop - estimatedHeight - sideOffset;
      // 修正 top 不能小于屏幕边缘
      if (top < screenPadding) {
        top = screenPadding;
        maxHeight = topSpace - sideOffset - screenPadding;
      }
    } else {
      // 向下弹出
      top = buttonTop + buttonHeight + sideOffset;
      // 修正高度
      maxHeight = bottomSpace - sideOffset - screenPadding;
    }

    // ============================================================
    // 3. 动画锚点 (Alignment)
    // ============================================================
    Alignment alignment;
    if (showAbove) {
      // 向上弹出：锚点在下方
      alignment = isRightAligned ? Alignment.bottomRight : Alignment.bottomLeft;
    } else {
      // 向下弹出：锚点在上方
      alignment = isRightAligned ? Alignment.topRight : Alignment.topLeft;
    }

    final theme = Theme.of(context);
    final surface = ThemeUtils.select(context, light: Colors.white, dark: const Color(0xff1f1f1f));
    final borderColor = theme.brightness == Brightness.dark ? Colors.white10 : Colors.black12;

    return Stack(
      children: [
        GestureDetector(
          onTap: widget.onClose,
          child: Container(color: Colors.transparent, width: double.infinity, height: double.infinity),
        ),
        
        // 核心修改在这里：根据计算结果，分别设置 left 或 right
        Positioned(
          top: top,
          left: posLeft,   // 如果是左对齐，这里有值，posRight 为 null
          right: posRight, // 如果是右对齐，这里有值，posLeft 为 null
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) => Transform.scale(
              scale: _scale.value,
              alignment: alignment, 
              child: Opacity(opacity: _opacity.value, child: child),
            ),
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                width: menuWidth,
                constraints: maxHeight != null ? BoxConstraints(maxHeight: maxHeight) : null,
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: borderColor),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: widget.items.map((e) => _DropdownItem(
                      item: e,
                      isSelected: e == widget.selectedValue,
                      onTap: () => widget.onItemTap(e),
                      itemBuilder: widget.itemBuilder,
                    )).toList(),
                  ),
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
  final String item;
  final bool isSelected;
  final VoidCallback onTap;
  final Widget Function(String) ?itemBuilder;

  const _DropdownItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
    this.itemBuilder,
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

    Widget content;
    if (widget.itemBuilder != null) {
      // 使用自定义 itemBuilder
      content = widget.itemBuilder!(widget.item);
    } else {
      // 默认样式
      content = Row(
        children: [
          Expanded(
            child: Text(
              widget.item,
              style: TextStyle(
                color: widget.isSelected ? color : textColor,
                fontSize: 14,
                fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          if (widget.isSelected)
            Icon(Icons.check, size: 16, color: color),
        ],
      );
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: (_hover ? color.withOpacity(0.08) : Colors.transparent),
              borderRadius: BorderRadius.circular(4),
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}