import 'dart:math';
import 'package:flutter/material.dart';

class ButterflyFlapCurve extends Curve {
  @override
  double transform(double t) {
    final double phase = t * 2 * pi;
    double value =
        0.6 * sin(phase) + 0.2 * sin(2 * phase) + 0.1 * sin(3 * phase);

    if (value > 0.8) value = 0.8;
    if (value < -0.8) value = -0.8;

    return value;
  }
}

class FlutterButterfly extends StatefulWidget {
  final double width;
  final double height;

  const FlutterButterfly({
    Key? key,
    required this.width,
    required this.height,
  }) : super(key: key);

  @override
  State<FlutterButterfly> createState() => _FlutterButterflyState();
}

class _FlutterButterflyState extends State<FlutterButterfly>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _flapAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _flapAnimation = Tween<double>(
      begin: -0.6,
      end: 0.6,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: ButterflyFlapCurve(),
      ),
    );

    _controller.addListener(() {
      if (_controller.status == AnimationStatus.completed) {
        _controller.duration = Duration(
          milliseconds: 1200 + Random().nextInt(200) - 100,
        );
      }
    });

    _controller.repeat(reverse: false);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Calculate wing positions based on container size
    final wingSize = widget.height * 0.5; // Wing size proportional to height
    final wingOffset =
        widget.width * 0.167; // Offset from center (1/6 of width)
    final bodyWidth =
        widget.width * 0.033; // Body width (1/30 of container width)
    final bodyHeight =
        widget.height * 0.3; // Body height (0.3 of container height)

    return Container(
      width: widget.width,
      height: widget.height,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Left Wing
              Positioned(
                left: wingOffset,
                child: Transform(
                  alignment: Alignment.centerRight,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.002)
                    ..rotateY(_flapAnimation.value)
                    ..rotateZ(-0.2)
                    ..rotateX(0.1 * sin(_controller.value * pi)),
                  child: getFlutterLogo(true, wingSize),
                ),
              ),
              // Right Wing
              Positioned(
                right: wingOffset,
                child: Transform(
                  alignment: Alignment.centerLeft,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.002)
                    ..rotateY(-_flapAnimation.value)
                    ..rotateZ(0.2)
                    ..rotateX(0.1 * sin(_controller.value * pi)),
                  child: getFlutterLogo(false, wingSize),
                ),
              ),
              // Body
              Positioned(
                child: Transform(
                  transform: Matrix4.identity()
                    ..translate(
                      0.0,
                      2.0 * sin(_controller.value * 2 * pi),
                      0.0,
                    ),
                  child: Container(
                    width: bodyWidth,
                    height: bodyHeight,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.black87, Colors.black54],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey,
                          blurRadius: 4,
                          spreadRadius: 1,
                        )
                      ],
                      borderRadius: BorderRadius.circular(bodyWidth / 2),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

Widget getFlutterLogo(bool isMirrored, double size) {
  if (isMirrored) {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.rotationY(pi),
      child: CustomPaint(
        size: Size(size, size),
        painter: _PinkWingPainter(),
      ),
    );
  } else {
    return CustomPaint(
      size: Size(size, size),
      painter: _PinkWingPainter(),
    );
  }
}

class _PinkWingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final dotPaint = Paint()..color = Colors.grey;
    canvas.drawCircle(Offset(size.width * 0.3, size.height * 0.3), 4, dotPaint);
    canvas.drawCircle(Offset(size.width * 0.6, size.height * 0.6), 3, dotPaint);
    final Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final Gradient gradient = RadialGradient(
      colors: [Colors.pink.shade200, Colors.pink.shade700],
      center: Alignment.topCenter,
      radius: 1.0,
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width * 0.1, size.height * 0.5);
    path.quadraticBezierTo(
        size.width * 0.5, 0, size.width * 0.9, size.height * 0.5);
    path.quadraticBezierTo(
        size.width * 0.5, size.height, size.width * 0.1, size.height * 0.5);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
