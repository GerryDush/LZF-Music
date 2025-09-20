import 'package:flutter/widgets.dart';

/// SFIcon is a widget that displays an SF Symbol v6.
/// It is a wrapper around Text widget.
/// It takes an IconData as input and displays the corresponding SF Symbol.
/// Optional parameters: fontSize, fontWeight, color, shadows, textDirection and semanticsLabel.
class SFIcon extends StatelessWidget {
  const SFIcon(
    this.icon, {
    Key? key,
    this.fontSize = 24,
    this.fontWeight = FontWeight.normal,
    this.color,
    this.shadows,
    this.textDirection,
    this.semanticsLabel,
  }) : super(key: key);

  final IconData icon;
  final double? fontSize;
  final FontWeight? fontWeight;
  final Color? color;
  final List<Shadow>? shadows;
  final TextDirection? textDirection;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    final textDirection = this.textDirection ?? Directionality.of(context);

    final iconWeight = fontWeight?.value.toDouble() ?? iconTheme.weight;

    final iconOpacity = iconTheme.opacity ?? 1.0;
    var iconColor = color ?? iconTheme.color!;
    if (iconOpacity != 1.0) {
      iconColor = iconColor.withValues(alpha: iconColor.a * iconOpacity);
    }

    return Text(
      String.fromCharCode(icon.codePoint),
      textDirection: textDirection,
      semanticsLabel: semanticsLabel,
      style: TextStyle(
        fontVariations: <FontVariation>[
          if (iconWeight != null) FontVariation('wght', iconWeight),
        ],
        inherit: false,
        fontFamily: SFIcons._kFontFamily,
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: iconColor,
        shadows: shadows,
      ),
    );
  }
}

@staticIconProvider
class SFIcons {
  static const _kFontFamily = 'SFIcons';
  static const IconData sf_icon_listbullet = IconData(
    0xe905,
    fontFamily: _kFontFamily,
  );
  static const IconData sf_icon_musicpages = IconData(
    0xe907,
    fontFamily: _kFontFamily,
  );
}
