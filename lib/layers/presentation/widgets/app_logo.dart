import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 32});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xff12352f),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.style, color: const Color(0xff9be0c8), size: size * 0.58),
          Positioned(
            right: size * 0.12,
            bottom: size * 0.12,
            child: Icon(
              Icons.monetization_on,
              color: const Color(0xffffcf4a),
              size: size * 0.34,
            ),
          ),
        ],
      ),
    );
  }
}
