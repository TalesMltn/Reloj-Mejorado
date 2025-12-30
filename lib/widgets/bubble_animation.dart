// lib/widgets/bubble_animation.dart
import 'dart:math';
import 'package:flutter/material.dart';

class BubbleAnimation extends StatefulWidget {
  const BubbleAnimation({super.key});

  @override
  State<BubbleAnimation> createState() => _BubbleAnimationState();
}

class _BubbleAnimationState extends State<BubbleAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  final double size = 4 + Random().nextDouble() * 8; // Tamaño aleatorio entre 4 y 12
  final double left = Random().nextDouble() * 100; // Posición horizontal aleatoria

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(seconds: 12 + Random().nextInt(15)), // Duración aleatoria 12-27s
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: 1.1, end: -0.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Positioned(
          left: left * MediaQuery.of(context).size.width / 100,
          bottom: _animation.value * MediaQuery.of(context).size.height,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.cyan.withOpacity(0.6),
              boxShadow: [
                BoxShadow(
                  color: Colors.cyan.withOpacity(0.9),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}