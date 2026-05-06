import 'dart:math' as math;

import 'package:flutter/material.dart';

void main() {
  runApp(const BpmApp());
}

const Color _heartRed = Color(0xFFC1221F);
const Color _pageBackground = Color(0xFFFFFFFF);
const String _heartAsset = 'assets/images/logo_bpm.png';

class BpmApp extends StatelessWidget {
  const BpmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BPM',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: _heartRed),
        fontFamily: 'Arial',
        scaffoldBackgroundColor: _pageBackground,
        useMaterial3: true,
      ),
      home: const HeartRateScreen(),
    );
  }
}

class HeartRateScreen extends StatefulWidget {
  const HeartRateScreen({super.key});

  @override
  State<HeartRateScreen> createState() => _HeartRateScreenState();
}

class _HeartRateScreenState extends State<HeartRateScreen> {
  double _bpm = 80;
  bool _showSplash = true;

  int get _roundedBpm => _bpm.round();

  PulseStatus get _status {
    if (_roundedBpm <= 60) {
      return PulseStatus.tired;
    }
    if (_roundedBpm >= 121) {
      return PulseStatus.alert;
    }
    return PulseStatus.healthy;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 450),
          child: _showSplash
              ? SplashView(
                  key: const ValueKey('splash'),
                  onStart: () => setState(() => _showSplash = false),
                )
              : HeartRateDashboard(
                  key: const ValueKey('dashboard'),
                  bpm: _roundedBpm,
                  status: _status,
                  onBpmChanged: (value) => setState(() => _bpm = value),
                ),
        ),
      ),
    );
  }
}

class SplashView extends StatelessWidget {
  const SplashView({super.key, required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BpmLogo(size: 132, labelSize: 52),
          const SizedBox(height: 42),
          FilledButton(
            onPressed: onStart,
            style: FilledButton.styleFrom(
              backgroundColor: _heartRed,
              foregroundColor: Colors.white,
              minimumSize: const Size(180, 54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              textStyle: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
            child: const Text('Iniciar'),
          ),
        ],
      ),
    );
  }
}

class HeartRateDashboard extends StatelessWidget {
  const HeartRateDashboard({
    super.key,
    required this.bpm,
    required this.status,
    required this.onBpmChanged,
  });

  final int bpm;
  final PulseStatus status;
  final ValueChanged<double> onBpmChanged;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 380;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            compact ? 20 : 28,
            18,
            compact ? 20 : 28,
            22,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const BpmLogo(size: 38, labelSize: 18),
                const SizedBox(height: 18),
                BpmCard(bpm: bpm),
                const SizedBox(height: 26),
                Center(
                  child: CapybaraStatus(
                    status: status,
                    size: compact ? 172 : 210,
                  ),
                ),
                const SizedBox(height: 24),
                BpmSlider(
                  bpm: bpm,
                  onChanged: onBpmChanged,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class BpmLogo extends StatelessWidget {
  const BpmLogo({
    super.key,
    required this.size,
    this.labelSize,
  });

  final double size;
  final double? labelSize;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Image.asset(
        _heartAsset,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: CustomPaint(painter: HeartPainter())),
              if (labelSize != null) ...[
                SizedBox(width: math.max(4, size * 0.06)),
                Text(
                  'bpm',
                  style: TextStyle(
                    color: _heartRed,
                    fontSize: labelSize,
                    fontWeight: FontWeight.w900,
                    height: 0.9,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class BpmCard extends StatelessWidget {
  const BpmCard({super.key, required this.bpm});

  final int bpm;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 92),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: BoxDecoration(
        color: _heartRed,
        borderRadius: BorderRadius.circular(28),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          '$bpm  bpm',
          maxLines: 1,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 50,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class BpmSlider extends StatelessWidget {
  const BpmSlider({
    super.key,
    required this.bpm,
    required this.onChanged,
  });

  final int bpm;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Simulador MAX30102',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.black87,
                fontWeight: FontWeight.w800,
              ),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: _heartRed,
            inactiveTrackColor: _heartRed.withValues(alpha: 0.18),
            thumbColor: _heartRed,
            overlayColor: _heartRed.withValues(alpha: 0.12),
            valueIndicatorColor: _heartRed,
          ),
          child: Slider(
            value: bpm.toDouble(),
            min: 40,
            max: 160,
            divisions: 120,
            label: '$bpm bpm',
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class CapybaraStatus extends StatelessWidget {
  const CapybaraStatus({
    super.key,
    required this.status,
    required this.size,
  });

  final PulseStatus status;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox.square(
          dimension: size,
          child: Image.asset(
            status.assetPath,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return CustomPaint(
                painter: CapybaraPainter(status),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(
          status.label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 27,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

enum PulseStatus {
  tired('Achicopalado', 'assets/images/achicopalado.png'),
  healthy('Sano como manzano', 'assets/images/manzano.png'),
  alert('Aaahhh!!!', 'assets/images/aahhh.png');

  const PulseStatus(this.label, this.assetPath);
  final String label;
  final String assetPath;
}

class HeartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / 100;
    final scaleY = size.height / 100;

    canvas.save();
    canvas.scale(scaleX, scaleY);

    final body = Paint()
      ..color = _heartRed
      ..style = PaintingStyle.fill;
    final shade = Paint()
      ..color = const Color(0xFF8B1816).withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.2;
    final blue = Paint()
      ..color = const Color(0xFF54B7D9)
      ..style = PaintingStyle.fill;

    final heartPath = Path()
      ..moveTo(48, 90)
      ..cubicTo(20, 76, 11, 52, 20, 33)
      ..cubicTo(28, 14, 49, 20, 51, 36)
      ..cubicTo(58, 19, 82, 19, 88, 39)
      ..cubicTo(96, 66, 72, 84, 48, 90);

    canvas.drawPath(heartPath, body);
    canvas.drawCircle(const Offset(30, 45), 17, body);
    canvas.drawCircle(const Offset(70, 43), 16, body);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(20, 6, 13, 35),
        const Radius.circular(8),
      ),
      blue,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(42, 0, 10, 35),
        const Radius.circular(7),
      ),
      body,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(62, 4, 11, 34),
        const Radius.circular(7),
      ),
      body,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(79, 22, 14, 11),
        const Radius.circular(8),
      ),
      body,
    );

    final highlight = Paint()
      ..color = const Color(0xFFE94845)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(const Rect.fromLTWH(23, 34, 32, 30), math.pi, 1.5, false, highlight);
    canvas.drawPath(
      Path()
        ..moveTo(46, 55)
        ..cubicTo(41, 64, 41, 74, 45, 82)
        ..moveTo(58, 50)
        ..cubicTo(67, 58, 69, 69, 65, 80)
        ..moveTo(32, 66)
        ..cubicTo(26, 69, 23, 74, 24, 81),
      shade,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CapybaraPainter extends CustomPainter {
  CapybaraPainter(this.status);

  final PulseStatus status;

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 220;
    final sy = size.height / 220;

    canvas.save();
    canvas.scale(sx, sy);

    switch (status) {
      case PulseStatus.tired:
        _drawTired(canvas);
        break;
      case PulseStatus.healthy:
        _drawHealthy(canvas);
        break;
      case PulseStatus.alert:
        _drawAlert(canvas);
        break;
    }

    canvas.restore();
  }

  void _drawBaseBody(
    Canvas canvas, {
    required Rect bodyRect,
    required bool sitting,
    bool armsUp = false,
    bool sleepy = false,
    bool alert = false,
  }) {
    final outline = Paint()
      ..color = const Color(0xFF724737)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fur = Paint()
      ..color = const Color(0xFFD39A6A)
      ..style = PaintingStyle.fill;
    final belly = Paint()
      ..color = const Color(0xFFFFE6BA)
      ..style = PaintingStyle.fill;

    canvas.drawOval(bodyRect, fur);
    canvas.drawOval(bodyRect, outline);

    if (sitting) {
      canvas.drawOval(const Rect.fromLTWH(75, 118, 70, 72), belly);
    }

    final leftEar = Path()
      ..moveTo(68, 63)
      ..quadraticBezierTo(57, 40, 81, 50)
      ..quadraticBezierTo(84, 57, 79, 67);
    final rightEar = Path()
      ..moveTo(139, 64)
      ..quadraticBezierTo(150, 41, 126, 50)
      ..quadraticBezierTo(123, 57, 129, 67);
    canvas.drawPath(leftEar, fur);
    canvas.drawPath(rightEar, fur);
    canvas.drawPath(leftEar, outline);
    canvas.drawPath(rightEar, outline);

    _drawFace(canvas, sleepy: sleepy, alert: alert);

    final armPaint = Paint()
      ..color = const Color(0xFFD39A6A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    final armOutline = Paint()
      ..color = const Color(0xFF724737)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    if (armsUp) {
      canvas.drawLine(const Offset(72, 120), const Offset(41, 82), armPaint);
      canvas.drawLine(const Offset(148, 120), const Offset(180, 83), armPaint);
      canvas.drawLine(const Offset(72, 120), const Offset(41, 82), armOutline);
      canvas.drawLine(const Offset(148, 120), const Offset(180, 83), armOutline);
    } else {
      canvas.drawLine(const Offset(83, 129), const Offset(72, 161), armPaint);
      canvas.drawLine(const Offset(137, 129), const Offset(149, 161), armPaint);
      canvas.drawLine(const Offset(83, 129), const Offset(72, 161), armOutline);
      canvas.drawLine(const Offset(137, 129), const Offset(149, 161), armOutline);
    }

    final footPaint = Paint()
      ..color = const Color(0xFFB77D55)
      ..style = PaintingStyle.fill;
    canvas.drawOval(const Rect.fromLTWH(59, 171, 44, 19), footPaint);
    canvas.drawOval(const Rect.fromLTWH(117, 171, 44, 19), footPaint);
  }

  void _drawFace(Canvas canvas, {bool sleepy = false, bool alert = false}) {
    final dark = Paint()
      ..color = const Color(0xFF4C3029)
      ..style = PaintingStyle.fill;
    final blush = Paint()
      ..color = const Color(0xFFE98972).withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;
    final snout = Paint()
      ..color = const Color(0xFFB8795E)
      ..style = PaintingStyle.fill;
    final line = Paint()
      ..color = const Color(0xFF4C3029)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final white = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    if (sleepy) {
      canvas.drawLine(const Offset(78, 101), const Offset(92, 105), line);
      canvas.drawLine(const Offset(128, 105), const Offset(142, 101), line);
    } else if (alert) {
      canvas.drawCircle(const Offset(84, 100), 7, white);
      canvas.drawCircle(const Offset(136, 100), 7, white);
      canvas.drawCircle(const Offset(84, 100), 3.8, dark);
      canvas.drawCircle(const Offset(136, 100), 3.8, dark);
    } else {
      canvas.drawCircle(const Offset(83, 103), 4.5, dark);
      canvas.drawCircle(const Offset(137, 103), 4.5, dark);
    }

    canvas.drawOval(const Rect.fromLTWH(94, 104, 33, 30), snout);
    canvas.drawCircle(const Offset(110, 116), 4.5, dark);
    canvas.drawCircle(const Offset(75, 124), 10, blush);
    canvas.drawCircle(const Offset(146, 124), 10, blush);

    if (alert) {
      canvas.drawOval(const Rect.fromLTWH(101, 127, 18, 21), dark);
    } else if (sleepy) {
      canvas.drawArc(const Rect.fromLTWH(101, 125, 20, 13), 0.1, math.pi - 0.2, false, line);
    } else {
      canvas.drawArc(const Rect.fromLTWH(99, 120, 24, 22), 0.15, math.pi - 0.3, false, line);
      canvas.drawLine(const Offset(110, 120), const Offset(110, 128), line);
    }
  }

  void _drawHealthy(Canvas canvas) {
    _drawSparkles(canvas);
    _drawBaseBody(
      canvas,
      bodyRect: const Rect.fromLTWH(52, 50, 116, 142),
      sitting: false,
      armsUp: true,
    );
    final mouth = Paint()
      ..color = const Color(0xFFE98972)
      ..style = PaintingStyle.fill;
    canvas.drawOval(const Rect.fromLTWH(101, 126, 18, 23), mouth);
  }

  void _drawTired(Canvas canvas) {
    _drawBaseBody(
      canvas,
      bodyRect: const Rect.fromLTWH(56, 48, 108, 146),
      sitting: true,
      sleepy: true,
    );
  }

  void _drawAlert(Canvas canvas) {
    _drawSweat(canvas);
    _drawBaseBody(
      canvas,
      bodyRect: const Rect.fromLTWH(56, 48, 108, 146),
      sitting: true,
      alert: true,
    );
  }

  void _drawSparkles(Canvas canvas) {
    final sparkle = Paint()
      ..color = const Color(0xFF8ACDA0)
      ..style = PaintingStyle.fill;
    for (final offset in const [
      Offset(37, 64),
      Offset(181, 78),
      Offset(43, 154),
      Offset(176, 151),
    ]) {
      final path = Path()
        ..moveTo(offset.dx, offset.dy - 15)
        ..quadraticBezierTo(offset.dx + 4, offset.dy - 4, offset.dx + 15, offset.dy)
        ..quadraticBezierTo(offset.dx + 4, offset.dy + 4, offset.dx, offset.dy + 15)
        ..quadraticBezierTo(offset.dx - 4, offset.dy + 4, offset.dx - 15, offset.dy)
        ..quadraticBezierTo(offset.dx - 4, offset.dy - 4, offset.dx, offset.dy - 15);
      canvas.drawPath(path, sparkle);
    }
  }

  void _drawSweat(Canvas canvas) {
    final sweat = Paint()
      ..color = const Color(0xFF64BCE7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(132, 50), const Offset(137, 62), sweat);
    canvas.drawLine(const Offset(145, 52), const Offset(150, 66), sweat);
    canvas.drawLine(const Offset(156, 60), const Offset(162, 74), sweat);
  }

  @override
  bool shouldRepaint(covariant CapybaraPainter oldDelegate) {
    return oldDelegate.status != status;
  }
}
