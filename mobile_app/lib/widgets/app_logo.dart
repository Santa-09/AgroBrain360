import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final double padding;
  final Color backgroundColor;
  final BorderRadius? borderRadius;

  const AppLogo({
    super.key,
    required this.size,
    this.padding = 6,
    this.backgroundColor = Colors.transparent,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius ?? BorderRadius.circular(size * 0.25),
      ),
      child: Image.asset(
        'assets/images/app_logo.png',
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.eco_rounded,
          color: Color(0xFF1A5C2A),
        ),
      ),
    );
  }
}
