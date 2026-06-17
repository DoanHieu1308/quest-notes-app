import 'dart:math';

import 'package:flutter/material.dart';

class CoinBurst extends StatefulWidget {
  const CoinBurst({super.key, required this.amount, required this.onDone});

  final int amount;
  final VoidCallback onDone;

  @override
  State<CoinBurst> createState() => _CoinBurstState();
}

class _CoinBurstState extends State<CoinBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward().whenComplete(widget.onDone);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final random = Random(widget.amount);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = Curves.easeOutCubic.transform(controller.value);
        final size = MediaQuery.of(context).size;
        return Stack(
          children: [
            Center(
              child: Opacity(
                opacity: 1 - controller.value,
                child: Transform.scale(
                  scale: 0.7 + t * 0.7,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xffffcf4a),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 20),
                      ],
                    ),
                    child: Text(
                      '+${widget.amount} xu',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            ...List.generate(18, (index) {
              final angle = random.nextDouble() * pi * 2;
              final radius = 40 + random.nextDouble() * 160 * t;
              return Positioned(
                left: size.width / 2 + cos(angle) * radius,
                top: size.height / 2 + sin(angle) * radius,
                child: Opacity(
                  opacity: 1 - controller.value,
                  child: Transform.rotate(
                    angle: t * pi * 3,
                    child: const Icon(
                      Icons.monetization_on,
                      color: Color(0xffffb000),
                      size: 30,
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}
