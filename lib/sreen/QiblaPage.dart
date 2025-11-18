import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:vibration/vibration.dart';


class QiblaPage extends StatefulWidget {
  const QiblaPage({super.key});

  @override
  State<QiblaPage> createState() => _UltraQiblaPageProState();
}

class _UltraQiblaPageProState extends State<QiblaPage> with TickerProviderStateMixin {
  double? heading;
  double? qiblaDirection;
  StreamSubscription? _compassSub;

  late final AnimationController _pulseController;
  late final AnimationController _arrowController;
  bool _facing = false;
  DateTime _lastVibrate = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
      lowerBound: 0.0,
      upperBound: 1.0,
    )..repeat(reverse: true);

    _arrowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _determinePositionAndStart();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _arrowController.dispose();
    _compassSub?.cancel();
    super.dispose();
  }

  Future<void> _determinePositionAndStart() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) { _startCompass(); return; }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) { _startCompass(); return; }

    Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() { qiblaDirection = _calculateQibla(pos.latitude, pos.longitude); });
    _startCompass();
  }

  void _startCompass() {
    _compassSub = FlutterCompass.events!.listen((event) {
      if (!mounted) return;
      double? newHeading = event.heading;
      if (newHeading == null) return;

      if (heading != null && (newHeading - heading!).abs() < 0.5) return;
      setState(() { heading = newHeading; });

      if (qiblaDirection != null) {
        double diff = ((heading! - qiblaDirection!) + 360) % 360;
        bool facing = diff < 6 || diff > 354;

        if (facing != _facing) {
          setState(() => _facing = facing);
          _arrowController.forward(from: 0);
        }

        if (facing) {
          final now = DateTime.now();
          if (now.difference(_lastVibrate).inMilliseconds > 1500) {
            _lastVibrate = now;
            Vibration.hasVibrator().then((has) { if (has ?? false) Vibration.vibrate(duration: 60); });
          }
        }
      }
    });
  }

  double _calculateQibla(double lat, double lon) {
    const kaabaLat = 21.422487;
    const kaabaLon = 39.826206;
    double latRad = _degToRad(lat);
    double lonRad = _degToRad(lon);
    double kaabaLatRad = _degToRad(kaabaLat);
    double kaabaLonRad = _degToRad(kaabaLon);
    double deltaLon = kaabaLonRad - lonRad;
    double x = sin(deltaLon);
    double y = cos(latRad) * tan(kaabaLatRad) - sin(latRad) * cos(deltaLon);
    double brng = atan2(x, y);
    return (_radToDeg(brng) + 360) % 360;
  }

  double _degToRad(double deg) => deg * pi / 180;
  double _radToDeg(double rad) => rad * 180 / pi;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size.width * 0.85;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text('Ultra Qibla', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A3D91), Color(0xFF1761B0), Color(0xFF1F8AB0)],
          ),
        ),
        child: SafeArea(
          child: heading == null || qiblaDirection == null
              ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(height: 16),
                Text('جاري الحصول على الموقع وبوصلة الجهاز...', style: TextStyle(color: Colors.white70)),
              ],
            ),
          )
              : Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(size: Size(size, size), painter: QiblaCompassPainter(size: size)),
                AnimatedBuilder(
                  animation: _arrowController,
                  builder: (context, _) {
                    final rotationRad = _degToRad((qiblaDirection! - heading!) * -1);
                    return Transform.rotate(
                      angle: rotationRad,
                      child: Container(
                        width: 24,
                        height: size / 2,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFF700), Color(0xFFFFA500)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: Colors.yellowAccent.withOpacity(0.8), blurRadius: 16, offset: const Offset(0, 4)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                ScaleTransition(
                  scale: Tween(begin: 0.95, end: 1.15).animate(_pulseController),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _facing ? Colors.greenAccent : Colors.white.withOpacity(0.15),
                      boxShadow: [
                        BoxShadow(
                          color: _facing ? Colors.greenAccent.withOpacity(0.9) : Colors.white.withOpacity(0.06),
                          blurRadius: _facing ? 36 : 12,
                          spreadRadius: _facing ? 10 : 2,
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 40,
                  child: Column(
                    children: [
                      Text('زاوية القبلة: ${qiblaDirection!.toStringAsFixed(1)}°', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text('اتجاه الهاتف: ${heading!.toStringAsFixed(1)}°', style: const TextStyle(fontSize: 14, color: Colors.white70)),
                      const SizedBox(height: 8),
                      Text(_facing ? 'أنت على القبلة ✅' : 'قم بتدوير جهازك لتواجه القبلة', style: TextStyle(color: _facing ? Colors.greenAccent.shade400 : Colors.white70, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class QiblaCompassPainter extends CustomPainter {
  final double size;
  QiblaCompassPainter({required this.size});

  @override
  void paint(Canvas canvas, Size _) {
    final center = Offset(size / 2, size / 2);
    final radius = size / 2;

    final outer = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..shader = RadialGradient(colors: [Colors.white70, Colors.white24]).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, outer);

    final tickPaint = Paint()..color = Colors.white70.withOpacity(0.8);
    for (int i = 0; i < 360; i += 10) {
      final rad = i * pi / 180;
      final inner = radius - (i % 30 == 0 ? 20 : 12);
      final start = Offset(center.dx + inner * cos(rad), center.dy + inner * sin(rad));
      final end = Offset(center.dx + radius * cos(rad), center.dy + radius * sin(rad));
      tickPaint.strokeWidth = (i % 30 == 0 ? 2.0 : 1.0);
      canvas.drawLine(start, end, tickPaint);
    }

    final style = TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, shadows: [const Shadow(color: Colors.black54, blurRadius: 6)]);
    _drawText(canvas, 'N', center.dx, center.dy - radius + 32, style);
    _drawText(canvas, 'S', center.dx, center.dy + radius - 32, style);
    _drawText(canvas, 'E', center.dx + radius - 32, center.dy, style);
    _drawText(canvas, 'W', center.dx - radius + 32, center.dy, style);
  }

  void _drawText(Canvas canvas, String text, double x, double y, TextStyle style) {
    final tp = TextPainter(text: TextSpan(text: text, style: style), textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
