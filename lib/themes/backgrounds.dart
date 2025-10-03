// import 'dart:math' as math;
// import 'dart:math';
// import 'package:flutter/material.dart';

// class AnimatedGridPattern extends StatefulWidget {
//   final List<List<int>> squares;
//   final double gridSize;
//   final double skewAngle;

//   const AnimatedGridPattern({
//     Key? key,
//     required this.squares,
//     this.gridSize = 40,
//     this.skewAngle = 12,
//   }) : super(key: key);

//   @override
//   State<AnimatedGridPattern> createState() => _AnimatedGridPatternState();
// }

// class _AnimatedGridPatternState extends State<AnimatedGridPattern>
//     with TickerProviderStateMixin {
//   late List<AnimationController> _controllers;
//   late List<Animation<double>> _animations;
//   final math.Random _random = math.Random();

//   @override
//   void initState() {
//     super.initState();
//     _initializeAnimations();
//   }

//   void _initializeAnimations() {
//     // Create controllers with staggered start times
//     _controllers = List.generate(
//       widget.squares.length,
//       (index) {
//         final controller = AnimationController(
//           duration: Duration(milliseconds: 1500 + _random.nextInt(1000)),
//           vsync: this,
//         );

//         // Add a delayed start for each controller
//         Future.delayed(Duration(milliseconds: _random.nextInt(1000)), () {
//           controller.repeat(reverse: true);
//         });

//         return controller;
//       },
//     );

//     // Create animations with more dramatic opacity changes
//     _animations = _controllers.map((controller) {
//       return Tween<double>(begin: 0.1, end: 0.9).animate(
//         CurvedAnimation(
//           parent: controller,
//           // Use a custom curve for more interesting blinking effect
//           curve: Curves.easeInOutSine,
//         ),
//       );
//     }).toList();
//   }

//   @override
//   void dispose() {
//     for (var controller in _controllers) {
//       controller.dispose();
//     }
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return LayoutBuilder(
//       builder: (context, constraints) {
//         return Transform(
//           transform: Matrix4.skewY(widget.skewAngle * math.pi / 180),
//           child: CustomPaint(
//             size: Size(constraints.maxWidth * 1.4, constraints.maxHeight * 1.4),
//             painter: GridPatternPainter(
//               squares: widget.squares,
//               gridSize: widget.gridSize,
//               animations: _animations,
//             ),
//           ),
//         );
//       },
//     );
//   }
// }

// class GridPatternPainter extends CustomPainter {
//   final List<List<int>> squares;
//   final double gridSize;
//   final List<Animation<double>> animations;

//   GridPatternPainter({
//     required this.squares,
//     required this.gridSize,
//     required this.animations,
//   }) : super(repaint: Listenable.merge(animations));

//   @override
//   void paint(Canvas canvas, Size size) {
//     // Draw base grid with slightly darker lines
//     final gridPaint = Paint()
//       ..style = PaintingStyle.stroke
//       ..color = Colors.grey.withOpacity(0.4)
//       ..strokeWidth = 0.5;

//     // Draw vertical lines
//     for (double x = 0; x <= size.width * 1.8; x += gridSize) {
//       canvas.drawLine(
//         Offset(x, 0),
//         Offset(x, size.height * 1.5),
//         gridPaint,
//       );
//     }

//     // Draw horizontal lines
//     for (double y = 0; y <= size.height * 1.5; y += gridSize) {
//       canvas.drawLine(
//         Offset(0, y),
//         Offset(size.width, y),
//         gridPaint,
//       );
//     }

//     // Draw animated squares with a gradient effect
//     final fillPaint = Paint()..style = PaintingStyle.fill;

//     for (int i = 0; i < squares.length; i++) {
//       final square = squares[i];

//       // Create a gradient for each square
//       final Rect squareRect = Rect.fromLTWH(
//         square[0] * gridSize,
//         square[1] * gridSize,
//         gridSize - 1,
//         gridSize - 1,
//       );

//       // fillPaint.shader = RadialGradient(
//       //   center: Alignment.center,
//       //   radius: 1.0,
//       //   colors: [
//       //     Colors.blue.withOpacity(animations[i].value),
//       //     Colors.purple.withOpacity(animations[i].value * 0.7),
//       //   ],
//       // ).createShader(squareRect);
// // Colors.grey.withOpacity(0.4)
//       fillPaint.color = Colors.grey.withOpacity(0.3 * animations[i].value);

//       canvas.drawRect(squareRect, fillPaint);
//     }
//   }

//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
// }

// // Demo implementation with more squares
// class GridBlinkerDemo extends StatelessWidget {
//   const GridBlinkerDemo({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     // Generate more random squares for a more interesting pattern
//     final random = math.Random();
//     final squares = List.generate(
//       20,
//       (index) => [random.nextInt(20), random.nextInt(20)],
//     );

//     return LayoutBuilder(
//       builder: (context, constraints) {
//         return Container(
//           child: Stack(
//             alignment: Alignment.center,
//             children: [
//               Transform.translate(
//                 offset: Offset(0, -100), // Adjust this value to move up
//                 child: AnimatedGridPattern(
//                   squares: squares,
//                   gridSize: 30, // Smaller grid size for more squares
//                   skewAngle: 15, // Slightly more pronounced skew
//                 ),
//               ),
//               Text(
//                 'GRID PATTERN',
//                 style: Theme.of(context).textTheme.headlineLarge?.copyWith(
//                       fontWeight: FontWeight.w900,
//                       letterSpacing: -1,
//                       color: Colors.white.withOpacity(0.9),
//                     ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
// }

// class ButterflyFlapCurve extends Curve {
//   @override
//   double transform(double t) {
//     final double phase = t * 2 * pi;
//     double value =
//         0.6 * sin(phase) + 0.2 * sin(2 * phase) + 0.1 * sin(3 * phase);

//     if (value > 0.8) value = 0.8;
//     if (value < -0.8) value = -0.8;

//     return value;
//   }
// }

// class FlutterButterfly extends StatefulWidget {
//   final double width;
//   final double height;

//   const FlutterButterfly({
//     Key? key,
//     required this.width,
//     required this.height,
//   }) : super(key: key);

//   @override
//   State<FlutterButterfly> createState() => _FlutterButterflyState();
// }

// class _FlutterButterflyState extends State<FlutterButterfly>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<double> _flapAnimation;

//   @override
//   void initState() {
//     super.initState();

//     _controller = AnimationController(
//       duration: const Duration(milliseconds: 500),
//       vsync: this,
//     );

//     _flapAnimation = Tween<double>(
//       begin: -0.6,
//       end: 0.6,
//     ).animate(
//       CurvedAnimation(
//         parent: _controller,
//         curve: ButterflyFlapCurve(),
//       ),
//     );

//     _controller.addListener(() {
//       if (_controller.status == AnimationStatus.completed) {
//         _controller.duration = Duration(
//           milliseconds: 1200 + Random().nextInt(200) - 100,
//         );
//       }
//     });

//     _controller.repeat(reverse: false);
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     // Calculate wing positions based on container size
//     final wingSize = widget.height * 0.5; // Wing size proportional to height
//     final wingOffset =
//         widget.width * 0.167; // Offset from center (1/6 of width)
//     final bodyWidth =
//         widget.width * 0.033; // Body width (1/30 of container width)
//     final bodyHeight =
//         widget.height * 0.3; // Body height (0.3 of container height)

//     return Container(
//       width: widget.width,
//       height: widget.height,
//       child: AnimatedBuilder(
//         animation: _controller,
//         builder: (context, child) {
//           return Stack(
//             alignment: Alignment.center,
//             children: [
//               // Left Wing
//               Positioned(
//                 left: wingOffset,
//                 child: Transform(
//                   alignment: Alignment.centerRight,
//                   transform: Matrix4.identity()
//                     ..setEntry(3, 2, 0.002)
//                     ..rotateY(_flapAnimation.value)
//                     ..rotateZ(-0.2)
//                     ..rotateX(0.1 * sin(_controller.value * pi)),
//                   child: getFlutterLogo(true, wingSize),
//                 ),
//               ),
//               // Right Wing
//               Positioned(
//                 right: wingOffset,
//                 child: Transform(
//                   alignment: Alignment.centerLeft,
//                   transform: Matrix4.identity()
//                     ..setEntry(3, 2, 0.002)
//                     ..rotateY(-_flapAnimation.value)
//                     ..rotateZ(0.2)
//                     ..rotateX(0.1 * sin(_controller.value * pi)),
//                   child: getFlutterLogo(false, wingSize),
//                 ),
//               ),
//               // Body
//               Positioned(
//                 child: Transform(
//                   transform: Matrix4.identity()
//                     ..translate(
//                       0.0,
//                       2.0 * sin(_controller.value * 2 * pi),
//                       0.0,
//                     ),
//                   child: Container(
//                     width: bodyWidth,
//                     height: bodyHeight,
//                     decoration: BoxDecoration(
//                       color: Colors.white38,
//                       borderRadius: BorderRadius.circular(bodyWidth / 2),
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }
// }

// Widget getFlutterLogo(bool isMirrored, double size) {
//   if (isMirrored) {
//     return Transform(
//       alignment: Alignment.center,
//       transform: Matrix4.rotationY(pi),
//       child: FlutterLogo(size: size),
//     );
//   } else {
//     return FlutterLogo(size: size);
//   }
// }

// class ButterflyDemo extends StatefulWidget {
//   const ButterflyDemo({Key? key}) : super(key: key);

//   @override
//   State<ButterflyDemo> createState() => _ButterflyDemoState();
// }

// class _ButterflyDemoState extends State<ButterflyDemo> {
//   // List to store butterfly configurations
//   final List<ButterflyConfig> butterflies = [];
//   static const int numberOfButterflies =
//       15; // Change this to adjust number of butterflies

//   @override
//   void initState() {
//     super.initState();
//     // Create random butterflies with different delays and paths
//     final random = Random();

//     for (int i = 0; i < numberOfButterflies; i++) {
//       butterflies.add(
//         ButterflyConfig(
//           // Random delay between 0 and 5 seconds
//           delay: Duration(milliseconds: random.nextInt(5000)),
//           // Random duration between 6 and 10 seconds
//           duration: Duration(seconds: 6 + random.nextInt(5)),
//           // Random starting X position between 20% and 80% of screen width
//           startXPercent: 0.2 + (random.nextDouble() * 0.6),
//           // Random size between 0.8 and 1.2 of original size
//           scale: 0.8 + (random.nextDouble() * 0.4),
//         ),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(
//         top: true,
//         bottom: false,
//         left: false,
//         right: false,
//         child: LayoutBuilder(builder: (context, constraints) {
//           return Stack(
//             children: butterflies.map((config) {
//               return FutureBuilder(
//                 future: Future.delayed(config.delay),
//                 builder: (context, snapshot) {
//                   if (snapshot.connectionState != ConnectionState.done) {
//                     return const SizedBox.shrink();
//                   }

//                   return MovingButterfly(
//                     screenHeight: constraints.maxHeight,
//                     screenWidth: constraints.maxWidth,
//                     duration: config.duration,
//                     startXPercent: config.startXPercent,
//                     scale: config.scale,
//                   );
//                 },
//               );
//             }).toList(),
//           );
//         }),
//       ),
//     );
//   }
// }

// // Configuration class for each butterfly
// class ButterflyConfig {
//   final Duration delay;
//   final Duration duration;
//   final double startXPercent;
//   final double scale;

//   ButterflyConfig({
//     required this.delay,
//     required this.duration,
//     required this.startXPercent,
//     required this.scale,
//   });
// }

// class MovingButterfly extends StatefulWidget {
//   final double screenHeight;
//   final double screenWidth;
//   final Duration duration;
//   final double startXPercent;
//   final double scale;

//   const MovingButterfly({
//     Key? key,
//     required this.screenHeight,
//     required this.screenWidth,
//     this.duration = const Duration(seconds: 6),
//     this.startXPercent = 0.5,
//     this.scale = 1.0,
//   }) : super(key: key);

//   @override
//   State<MovingButterfly> createState() => _MovingButterflyState();
// }

// class _MovingButterflyState extends State<MovingButterfly>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<double> _animation;
//   late Offset _start;
//   late Offset _end;
//   late Offset _control1;
//   late Offset _control2;

//   @override
//   void initState() {
//     super.initState();

//     final random = Random();

//     // Initialize start point with random X position
//     _start = Offset(
//       widget.screenWidth * widget.startXPercent,
//       widget.screenHeight - 100,
//     );

//     // Random end point at top of screen
//     _end = Offset(
//       widget.screenWidth * (0.2 + random.nextDouble() * 0.6),
//       100,
//     );

//     // Create more random control points for varied paths
//     _control1 = Offset(
//       widget.screenWidth * (0.1 + random.nextDouble() * 0.8),
//       widget.screenHeight * (0.5 + random.nextDouble() * 0.3),
//     );
//     _control2 = Offset(
//       widget.screenWidth * (0.1 + random.nextDouble() * 0.8),
//       widget.screenHeight * (0.2 + random.nextDouble() * 0.3),
//     );

//     _controller = AnimationController(
//       duration: widget.duration,
//       vsync: this,
//     );

//     _animation = CurvedAnimation(
//       parent: _controller,
//       curve: Curves.easeInOutCubic,
//     );

//     // Start the animation
//     _controller.forward();

//     // Loop the animation with new random paths
//     _controller.addStatusListener((status) {
//       if (status == AnimationStatus.completed) {
//         _regenerateControlPoints();
//         _controller.reverse();
//       } else if (status == AnimationStatus.dismissed) {
//         _regenerateControlPoints();
//         _controller.forward();
//       }
//     });
//   }

//   void _regenerateControlPoints() {
//     final random = Random();

//     // Generate new end point
//     _end = Offset(
//       widget.screenWidth * (0.2 + random.nextDouble() * 0.6),
//       100,
//     );

//     // Generate new control points
//     _control1 = Offset(
//       widget.screenWidth * (0.1 + random.nextDouble() * 0.8),
//       widget.screenHeight * (0.5 + random.nextDouble() * 0.3),
//     );
//     _control2 = Offset(
//       widget.screenWidth * (0.1 + random.nextDouble() * 0.8),
//       widget.screenHeight * (0.2 + random.nextDouble() * 0.3),
//     );
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   // Calculate position along the Bézier curve
//   Offset _calculatePosition(double t) {
//     // Cubic Bézier curve formula
//     final double u = 1 - t;
//     final double tt = t * t;
//     final double uu = u * u;
//     final double uuu = uu * u;
//     final double ttt = tt * t;

//     final double x = uuu * _start.dx +
//         3 * uu * t * _control1.dx +
//         3 * u * tt * _control2.dx +
//         ttt * _end.dx;
//     final double y = uuu * _start.dy +
//         3 * uu * t * _control1.dy +
//         3 * u * tt * _control2.dy +
//         ttt * _end.dy;

//     return Offset(x, y);
//   }

//   // Calculate rotation angle based on the curve's tangent
//   double _calculateRotation(double t) {
//     // Calculate the derivative of the Bézier curve
//     final double epsilon = 0.001;
//     final Offset currentPos = _calculatePosition(t);
//     final Offset nextPos = _calculatePosition(t + epsilon);

//     // Calculate the angle of movement
//     return atan2(nextPos.dy - currentPos.dy, nextPos.dx - currentPos.dx);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return AnimatedBuilder(
//       animation: _animation,
//       builder: (context, child) {
//         final position = _calculatePosition(_animation.value);
//         final rotation = _calculateRotation(_animation.value);

//         final bool isGoingUp =
//             !_controller.status.toString().contains("reverse");
//         final adjustedRotation =
//             isGoingUp ? rotation + pi / 2 : rotation - pi / 2;

//         // Scale the butterfly size
//         final scaledWidth = 50 * widget.scale;
//         final scaledHeight = 35 * widget.scale;

//         return Positioned(
//           left: position.dx - (scaledWidth / 2),
//           top: position.dy - (scaledHeight / 2),
//           child: Transform.rotate(
//             angle: adjustedRotation,
//             child: FlutterButterfly(
//               width: scaledWidth,
//               height: scaledHeight,
//             ),
//           ),
//         );
//       },
//     );
//   }
// }

// class MeteorShower extends StatefulWidget {
//   final Widget child;
//   final int numberOfMeteors;
//   final Duration duration;

//   const MeteorShower({
//     Key? key,
//     required this.child,
//     this.numberOfMeteors = 10,
//     this.duration = const Duration(seconds: 10),
//   }) : super(key: key);

//   @override
//   _MeteorShowerState createState() => _MeteorShowerState();
// }

// class _MeteorShowerState extends State<MeteorShower>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   List<Meteor> _meteors = [];
//   final double meteorAngle = pi / 4;

//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       vsync: this,
//       duration: widget.duration,
//     )..repeat();
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   void _initializeMeteors(Size size) {
//     if (_meteors.isEmpty) {
//       _meteors = List.generate(
//           widget.numberOfMeteors, (_) => Meteor(meteorAngle, size));
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return LayoutBuilder(
//       builder: (context, constraints) {
//         final size = Size(constraints.maxWidth, constraints.maxHeight);
//         _initializeMeteors(size);

//         return Stack(
//           children: [
//             widget.child,
//             ...List.generate(widget.numberOfMeteors, (index) {
//               return AnimatedBuilder(
//                 animation: _controller,
//                 builder: (context, child) {
//                   final meteor = _meteors[index];
//                   final progress = ((_controller.value - meteor.delay) % 1.0) /
//                       meteor.duration;
//                   if (progress < 0 || progress > 1) return SizedBox.shrink();

//                   return Positioned(
//                     left: meteor.startX +
//                         (meteor.endX - meteor.startX) * progress,
//                     top: meteor.startY +
//                         (meteor.endY - meteor.startY) * progress,
//                     child: Opacity(
//                       opacity: (1 - progress) * 0.8,
//                       child: Transform.rotate(
//                         angle: 315 * (pi / 180),
//                         child: CustomPaint(
//                           size: Size(2, 20),
//                           painter: MeteorPainter(),
//                         ),
//                       ),
//                     ),
//                   );
//                 },
//               );
//             }),
//           ],
//         );
//       },
//     );
//   }
// }

// class MeteorPainter extends CustomPainter {
//   @override
//   void paint(Canvas canvas, Size size) {
//     final Paint trailPaint = Paint()
//       ..shader = LinearGradient(
//         colors: [Colors.white, Colors.white.withOpacity(0)],
//         end: Alignment.topCenter,
//         begin: Alignment.bottomCenter,
//       ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

//     canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), trailPaint);

//     final Paint circlePaint = Paint()
//       ..color = Colors.white
//       ..style = PaintingStyle.fill;

//     canvas.drawCircle(Offset(size.width / 2, size.height), 2, circlePaint);
//   }

//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
// }

// class Meteor {
//   final double startX;
//   final double startY;
//   late double endX;
//   late double endY;
//   final double delay;
//   final double duration;

//   Meteor(double angle, Size size)
//       : startX = Random().nextDouble() * size.width / 2,
//         startY = Random().nextDouble() * size.height / 4 - size.height / 4,
//         delay = Random().nextDouble(),
//         duration = 0.3 + Random().nextDouble() * 0.7 {
//     var distance = size.height / 3;
//     endX = startX + cos(angle) * distance;
//     endY = startY + sin(angle) * distance;
//   }
// }

// class MeteorDemo extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     final size = MediaQuery.of(context).size;
//     return Center(
//       child: SizedBox(
//         width: size.width * 0.8, // 80% of screen width
//         height: size.height * 0.8, // 80% of screen height
//         child: Stack(
//           alignment: Alignment.center,
//           children: [
//             MeteorShower(
//               numberOfMeteors: 10,
//               duration: Duration(seconds: 5),
//               child: Container(
//                 width: double.infinity,
//                 height: 200,
//                 decoration: BoxDecoration(
//                   border: Border.all(
//                     color: Color.fromARGB(255, 96, 96, 96),
//                     width: 2,
//                   ),
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 child: Center(
//                   child: FittedBox(
//                     fit: BoxFit.scaleDown,
//                     child: Text(
//                       'Meteor shower',
//                       style: TextStyle(
//                         fontSize: 32,
//                         fontWeight: FontWeight.w600,
//                         foreground: Paint()
//                           ..shader = LinearGradient(
//                             colors: [
//                               Colors.white,
//                               Colors.white.withOpacity(0.2)
//                             ],
//                             begin: Alignment.topLeft,
//                             end: Alignment.bottomRight,
//                           ).createShader(Rect.fromLTWH(0, 0, 200, 70)),
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class ChatBackground extends StatelessWidget {
//   final int themeIndex;
//   const ChatBackground({super.key, required this.themeIndex});

//   @override
//   Widget build(BuildContext context) {
//     switch (themeIndex) {
//       case 2: // Cute
//         return const Positioned.fill(child: ButterflyDemo());
//       case 1: // Modern
//         return Positioned.fill(
//           child: AnimatedGridPattern(
//             squares: List.generate(20, (i) => [i % 5, i ~/ 5]),
//             gridSize: 40,
//             skewAngle: 12,
//           ),
//         );
//       case 0: // Elegant
//       default:
//         return Positioned.fill(
//           child: MeteorShower(
//             child: Container(), // Transparent child
//             numberOfMeteors: 14,
//             duration: const Duration(seconds: 8),
//           ),
//         );
//     }
//   }
// }
