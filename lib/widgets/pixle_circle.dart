import 'dart:math';
import 'package:flutter/material.dart';

class PixelCircle extends StatelessWidget {
  final Color color;
  final String label;

  const PixelCircle({
    super.key,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: PolygonClipper(sides: 15),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          // border: Border.all(
          //   strokeAlign: BorderSide.strokeAlignInside,
          //   color: Colors.black,
          //   style: BorderStyle.solid,
          //   width: 2,
          // ),
        ),
        width: 44,
        height: 44,
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 20,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class PolygonClipper extends CustomClipper<Path> {
  final int sides;
  PolygonClipper({this.sides = 12});

  @override
  Path getClip(Size size) {
    final path = Path();
    final angle = (2 * pi) / sides;
    final radius = min(size.width, size.height) / 2;
    final center = Offset(size.width / 2, size.height / 2);

    for (int i = 0; i < sides; i++) {
      final x = center.dx + radius * cos(angle * i - pi / 2);
      final y = center.dy + radius * sin(angle * i - pi / 2);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
