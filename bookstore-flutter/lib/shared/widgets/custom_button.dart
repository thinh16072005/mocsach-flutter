import 'package:flutter/material.dart';

/// Nút hành động chính (CTA). Mặc định dùng style gold từ theme; có thể override màu.
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final Color? color;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = color != null
        ? (ThemeData.estimateBrightnessForColor(color!) == Brightness.dark
            ? Colors.white
            : scheme.onTertiary)
        : scheme.onTertiary;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: color != null
            ? ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: fg)
            : null,
        child: isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(color: fg, strokeWidth: 2.5),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
                  Text(text),
                ],
              ),
      ),
    );
  }
}
