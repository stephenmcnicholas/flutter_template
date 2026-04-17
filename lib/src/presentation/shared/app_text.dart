import 'package:flutter/material.dart';
import '../theme.dart';

/// Typography-aware text widget using design system tokens.
class AppText extends StatelessWidget {
  final String text;
  final AppTextStyle style;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final FontWeight? fontWeight;

  const AppText(
    this.text, {
    super.key,
    required this.style,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.fontWeight,
  });

  @override
  Widget build(BuildContext context) {
    final typography = context.themeExt<AppTypography>();

    TextStyle textStyle;
    switch (style) {
      case AppTextStyle.display:
        textStyle = typography.display;
        break;
      case AppTextStyle.headline:
        textStyle = typography.headline;
        break;
      case AppTextStyle.title:
        textStyle = typography.title;
        break;
      case AppTextStyle.body:
        textStyle = typography.body;
        break;
      case AppTextStyle.label:
        textStyle = typography.label;
        break;
      case AppTextStyle.caption:
        textStyle = typography.caption;
        break;
    }

    if (fontWeight != null) {
      textStyle = textStyle.copyWith(fontWeight: fontWeight);
    }

    // Only override color if explicitly provided, otherwise use theme default
    final finalStyle = color != null
        ? textStyle.copyWith(color: color)
        : textStyle;

    return Text(
      text,
      style: finalStyle,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// Typography style roles.
enum AppTextStyle {
  display,
  headline,
  title,
  body,
  label,
  caption,
}

