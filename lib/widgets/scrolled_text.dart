import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nes_ui/nes_ui.dart';

class RunningTextBanner extends StatefulWidget {
  const RunningTextBanner({super.key});

  @override
  State<RunningTextBanner> createState() => _RunningTextBannerState();
}

class _RunningTextBannerState extends State<RunningTextBanner> {
  final _texts = [
    "Welcome to URChat",
    "Messages will be automatically deleted after 7 days",
  ];

  int _currentTextIndex = 0;
  bool _isLargeScreen = false;
  final Color _brown = const Color(0xFF5C4033);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _isLargeScreen = MediaQuery.of(context).size.width > 600;
    _startTextCycle();
  }

  Future<void> _startTextCycle() async {
    while (mounted) {
      final text = _texts[_currentTextIndex];

      final textPainter = TextPainter(
        text: TextSpan(
          text: text,
          style: GoogleFonts.pressStart2p(
            fontSize: _isLargeScreen ? 12 : 10,
          ),
        ),
        maxLines: 1,
        textDirection: TextDirection.ltr,
      )..layout();

      final textWidth = textPainter.width;
      final screenWidth = MediaQuery.of(context).size.width;

      const scrollSpeedPxPerSec = 80.0;
      final scrollDuration =
          ((textWidth + screenWidth) / scrollSpeedPxPerSec) * 1000;

      final totalDuration = scrollDuration.toInt() + 1000;

      await Future.delayed(Duration(milliseconds: totalDuration), () {
        if (!mounted) return;
        setState(() {
          _currentTextIndex = (_currentTextIndex + 1) % _texts.length;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      width: double.infinity,
      alignment: Alignment.center,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: _buildCurrentTextItem(),
      ),
    );
  }

  Widget _buildCurrentTextItem() {
    return Align(
      key: ValueKey(_currentTextIndex),
      alignment: Alignment.center,
      child: SizedBox(
        width: double.infinity,
        child: Center(
          child: NesRunningText(
            text: _texts[_currentTextIndex],
            textStyle: GoogleFonts.pressStart2p(
              fontSize: _isLargeScreen ? 12 : 10,
              color: _brown,
            ),
          ),
        ),
      ),
    );
  }
}
