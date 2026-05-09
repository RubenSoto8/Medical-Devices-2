import 'dart:convert';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
void main() {
  runApp(const Spo2App());
}

const Color _primaryColor = Color(0xFF34758A);
const Color _pageBackground = Color(0xFFFFFFFF);
const String _logoAsset = 'assets/images/logo_spo2.png';

class Spo2App extends StatelessWidget {
  const Spo2App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SpO2',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: _primaryColor),
        fontFamily: 'Arial',
        scaffoldBackgroundColor: _pageBackground,
        useMaterial3: true,
      ),
      home: const Spo2Screen(),
    );
  }
}

class Spo2Screen extends StatefulWidget {
  const Spo2Screen({super.key});

  @override
  State<Spo2Screen> createState() => _Spo2ScreenState();
}

class _Spo2ScreenState extends State<Spo2Screen> {
  double _spo2 = 98;
  bool _showSplash = true;

  BluetoothConnection? _connection;
  bool _isConnected = false;
  String _btStatus = 'Desconectado';
  String _buffer = '';

  int get _roundedSpo2 => _spo2.round();

  Spo2Status get _status {
    if (_roundedSpo2 >= 95) {
      return Spo2Status.optimal;
    }
    if (_roundedSpo2 >= 91) {
      return Spo2Status.watch;
    }
    if (_roundedSpo2 >= 86) {
      return Spo2Status.alert;
    }
    return Spo2Status.critical;
  }

  Future<void> _connectToHC05() async {
  setState(() => _btStatus = 'Buscando...');

  try {
    // 1. Obtener lista de dispositivos vinculados
    List<BluetoothDevice> devices = await FlutterBluetoothSerial.instance.getBondedDevices();
    
    // --- NUEVO: DEPURACIÓN ---
    // Mira tu consola en VS Code/Android Studio. Si no sale nada aquí, 
    // el problema son los permisos del celular o el GPS apagado.
    for (var d in devices) {
      debugPrint('App detectó vinculado: "${d.name}" con dirección: ${d.address}');
    }
    BluetoothDevice? hc05;
    try {
      hc05 = devices.firstWhere((d) {
        String deviceName = d.name?.replaceAll(' ', '').toUpperCase() ?? '';
        return deviceName.contains('HC05') || deviceName.contains('HC-05');
      });
    } catch (e) {
      hc05 = null;
    }

    if (hc05 == null) {
      setState(() => _btStatus = devices.isEmpty 
          ? 'Error: Lista vacía (Permisos/GPS?)' 
          : 'HC-05 no hallado en lista');
      return;
    }

    setState(() => _btStatus = 'Conectando a ${hc05!.name}...');
    
    final connection = await BluetoothConnection.toAddress(hc05.address).timeout(
      const Duration(seconds: 15),
    );

    setState(() {
      _connection = connection;
      _isConnected = true;
      _btStatus = 'Conectado';
    });

    _connection!.input!.listen((Uint8List data) {
      _buffer += utf8.decode(data);
      if (_buffer.contains('\n')) {
        final lines = _buffer.split('\n');
        _buffer = lines.last;
        for (int i = 0; i < lines.length - 1; i++) {
          if (lines[i].trim().isNotEmpty) {
            _parseLine(lines[i].trim());
          }
        }
      }
    }).onDone(() {
      if (mounted) {
        setState(() {
          _isConnected = false;
          _btStatus = 'Desconectado';
        });
      }
    });
  } catch (e) {
    debugPrint('Error de Bluetooth: $e');
    if (mounted) {
      setState(() => _btStatus = 'Error: $e');
    }
  }
}
 
  void _parseLine(String line) {
    try {
      final spo2Part = line.split('|').firstWhere((p) => p.startsWith('SPO2:'));
      final spo2 = double.tryParse(spo2Part.replaceFirst('SPO2:', '').trim());
 
      if (spo2 != null && spo2 >= 80 && spo2 <= 100) {
        setState(() => _spo2 = spo2);
      }
    } catch (_) {
    }
  }
 
  @override
  void dispose() {
    _connection?.dispose();
    super.dispose();
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
                  spo2: _roundedSpo2,
                  status: _status,
                  onSpo2Changed: (value) => setState(() => _spo2 = value),
                  isConnected: _isConnected,
                  btStatus: _btStatus,
                  onConnect: _connectToHC05,
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
          const Spo2Logo(size: 150),
          const SizedBox(height: 42),
          FilledButton(
            onPressed: onStart,
            style: FilledButton.styleFrom(
              backgroundColor: _primaryColor,
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
    required this.spo2,
    required this.status,
    required this.onSpo2Changed,
    required this.isConnected,
    required this.btStatus,
    required this.onConnect,
  });

  final int spo2;
  final Spo2Status status;
  final ValueChanged<double> onSpo2Changed;
  final bool isConnected;
  final String btStatus;
  final VoidCallback onConnect;

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
                const Spo2Logo(size: 48),
                const SizedBox(height: 18),
                Spo2Card(spo2: spo2),
                const SizedBox(height: 26),
                Center(
                  child: CapybaraStatus(
                    status: status,
                    size: compact ? 172 : 210,
                  ),
                ),
                const SizedBox(height: 24),
                BtStatusBar(
                  status: btStatus,
                  isConnected: isConnected,
                  onConnect: onConnect,
                ),
                const SizedBox(height: 12),
                Spo2Slider(
                 spo2: spo2,
                  onChanged: isConnected
                      ? null
                      : onSpo2Changed,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
class BtStatusBar extends StatelessWidget {
  const BtStatusBar({
    super.key,
    required this.status,
    required this.isConnected,
    required this.onConnect,
  });
 
  final String status;
  final bool isConnected;
  final VoidCallback onConnect;
 
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
          color: isConnected ? Colors.green : Colors.grey,
        ),
        const SizedBox(width: 8),
        Text(status),
        const Spacer(),
        if (!isConnected)
          FilledButton.icon(
            onPressed: onConnect,
            icon: const Icon(Icons.bluetooth),
            label: const Text('Conectar HC-05'),
            style: FilledButton.styleFrom(backgroundColor: _primaryColor),
          ),
      ],
    );
  }
}

class Spo2Logo extends StatelessWidget {
  const Spo2Logo({
    super.key,
    required this.size,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Image.asset(
        _logoAsset,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Text(
              '%\nSpO2',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _primaryColor,
                fontSize: size * 0.28,
                fontWeight: FontWeight.w900,
                height: 0.9,
              ),
            ),
          );
        },
      ),
    );
  }
}

class Spo2Card extends StatelessWidget {
  const Spo2Card({super.key, required this.spo2});

  final int spo2;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 92),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: BoxDecoration(
        color: _primaryColor,
        borderRadius: BorderRadius.circular(28),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          '$spo2 % SpO2',
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

class Spo2Slider extends StatelessWidget {
  const Spo2Slider({
    super.key,
    required this.spo2,
    required this.onChanged,
  });

  final int spo2;
  final ValueChanged<double>? onChanged;

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
            activeTrackColor: _primaryColor,
            inactiveTrackColor: _primaryColor.withValues(alpha: 0.18),
            thumbColor: _primaryColor,
            overlayColor: _primaryColor.withValues(alpha: 0.12),
            valueIndicatorColor: _primaryColor,
          ),
          child: Slider(
            value: spo2.toDouble(),
            min: 80,
            max: 100,
            divisions: 20,
            label: '$spo2 % SpO2',
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

  final Spo2Status status;
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
          status.characterLabel,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 27,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          status.healthLabel,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

enum Spo2Status {
  optimal(
    'Sano como Manzano',
    '\u00F3ptimo',
    'assets/images/manzano.png',
  ),
  watch(
    'Achicopalado',
    'vigilar',
    'assets/images/achicopalao.png',
  ),
  alert(
    'ahhhh',
    'alerta',
    'assets/images/ahhhhh.png',
  ),
  critical(
    'AAHHH',
    'Se recomienda consultar a un m\u00E9dico',
    'assets/images/AAHH.png',
  );

  const Spo2Status(this.characterLabel, this.healthLabel, this.assetPath);
  final String characterLabel;
  final String healthLabel;
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
      ..color = _primaryColor
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

  final Spo2Status status;

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 220;
    final sy = size.height / 220;

    canvas.save();
    canvas.scale(sx, sy);

    switch (status) {
      case Spo2Status.watch:
        _drawTired(canvas);
        break;
      case Spo2Status.optimal:
        _drawHealthy(canvas);
        break;
      case Spo2Status.alert:
      case Spo2Status.critical:
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
