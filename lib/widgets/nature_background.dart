import 'package:flutter/material.dart';

/// Static background with a photorealistic campus image
class NatureBackground extends StatelessWidget {
  final Widget child;

  const NatureBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/campus_background.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: child,
    );
  }
}
