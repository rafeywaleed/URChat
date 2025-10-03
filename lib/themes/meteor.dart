import 'dart:math';
import 'package:flutter/material.dart';

class MeteorShower extends StatefulWidget {
  final bool isDark;
  final Widget child;
  final int numberOfMeteors;
  final Duration duration;

  const MeteorShower(
      {Key? key,
      required this.child,
      this.numberOfMeteors = 10,
      this.duration = const Duration(seconds: 10),
      required this.isDark})
      : super(key: key);

  @override
  _MeteorShowerState createState() => _MeteorShowerState();
}

class _MeteorShowerState extends State<MeteorShower>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<Meteor> _meteors = [];
  final double meteorAngle = pi / 4;
  late Color meteorColor;

  @override
  void initState() {
    super.initState();
    meteorColor = widget.isDark ? Colors.white : Colors.black;
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant MeteorShower oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isDark != widget.isDark) {
      setState(() {
        meteorColor = widget.isDark ? Colors.white : Colors.black;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _initializeMeteors(Size size) {
    if (_meteors.isEmpty) {
      _meteors = List.generate(
          widget.numberOfMeteors, (_) => Meteor(meteorAngle, size));
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        _initializeMeteors(size);

        return Stack(
          children: [
            widget.child,
            ...List.generate(widget.numberOfMeteors, (index) {
              return AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final meteor = _meteors[index];
                  final progress = ((_controller.value - meteor.delay) % 1.0) /
                      meteor.duration;
                  if (progress < 0 || progress > 1) return SizedBox.shrink();

                  return Positioned(
                    left: meteor.startX +
                        (meteor.endX - meteor.startX) * progress,
                    top: meteor.startY +
                        (meteor.endY - meteor.startY) * progress,
                    child: Opacity(
                      opacity: (1 - progress) * 0.8,
                      child: Transform.rotate(
                        angle: 315 * (pi / 180),
                        child: CustomPaint(
                          size: Size(2, 20),
                          painter: MeteorPainter(meteorColor: meteorColor),
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ],
        );
      },
    );
  }
}

class MeteorPainter extends CustomPainter {
  final Color meteorColor;

  MeteorPainter({required this.meteorColor});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint trailPaint = Paint()
      ..shader = LinearGradient(
        colors: [meteorColor, meteorColor.withOpacity(0)],
        end: Alignment.topCenter,
        begin: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), trailPaint);

    final Paint circlePaint = Paint()
      ..color = meteorColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(size.width / 2, size.height), 2, circlePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class Meteor {
  final double startX;
  final double startY;
  late double endX;
  late double endY;
  final double delay;
  final double duration;

  Meteor(double baseAngle, Size size)
      : startX = Random().nextDouble() * size.width / 2,
        startY = Random().nextDouble() * size.height / 4 - size.height / 4,
        delay = Random().nextDouble(),
        duration = 0.3 + Random().nextDouble() * 0.7 {
    // Randomize angle between 60° and 90° (pi/3 to pi/2)
    final angle = (pi / 3) + Random().nextDouble() * (pi / 2 - pi / 3);
    var distance = size.height * 0.9;
    endX = startX + cos(angle) * distance;
    endY = startY + sin(angle) * distance;
  }
}
