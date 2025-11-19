import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  bool _isLoadingLocation = true;
  String _statusMessage = 'جاري تحديد موقعك...';

  late final AnimationController _pulseController;
  late final AnimationController _arrowController;
  bool _facing = false;
  DateTime _lastVibrate = DateTime.fromMillisecondsSinceEpoch(0);

  // Cache keys
  static const String _cacheKeyLat = 'cached_latitude';
  static const String _cacheKeyLon = 'cached_longitude';
  static const String _cacheKeyQibla = 'cached_qibla';
  static const String _cacheKeyTimestamp = 'cached_timestamp';

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

    _initializeQibla();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _arrowController.dispose();
    _compassSub?.cancel();
    super.dispose();
  }

  /// 🔥 Pro Approach: Load cached location first, then optionally update
  Future<void> _initializeQibla() async {
    // 1. Try loading from cache first
    final cachedQibla = await _loadCachedQibla();

    if (cachedQibla != null) {
      // Cache hit! Use cached direction immediately
      setState(() {
        qiblaDirection = cachedQibla;
        _isLoadingLocation = false;
        _statusMessage = 'تم تحميل الموقع المحفوظ';
      });

      // Start compass with cached data
      _startCompass();

      // Optional: Update location in background (if cache is old)
      _updateLocationIfNeeded();
    } else {
      // No cache - must fetch location
      await _fetchAndCacheLocation();
    }
  }

  /// Load cached qibla direction from storage
  Future<double?> _loadCachedQibla() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedQibla = prefs.getDouble(_cacheKeyQibla);
      final cachedTimestamp = prefs.getInt(_cacheKeyTimestamp);

      if (cachedQibla != null && cachedTimestamp != null) {
        final cacheAge = DateTime.now().millisecondsSinceEpoch - cachedTimestamp;
        final cacheAgeDays = cacheAge / (1000 * 60 * 60 * 24);

        // Cache is valid for 30 days (people don't move cities often)
        if (cacheAgeDays < 30) {
          debugPrint('✅ Using cached Qibla: $cachedQibla° (${cacheAgeDays.toStringAsFixed(1)} days old)');
          return cachedQibla;
        } else {
          debugPrint('⚠️ Cache expired (${cacheAgeDays.toStringAsFixed(0)} days old)');
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading cache: $e');
    }
    return null;
  }

  /// Update location only if cache is old (> 7 days) or user requests it
  Future<void> _updateLocationIfNeeded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedTimestamp = prefs.getInt(_cacheKeyTimestamp);

      if (cachedTimestamp != null) {
        final cacheAge = DateTime.now().millisecondsSinceEpoch - cachedTimestamp;
        final cacheAgeDays = cacheAge / (1000 * 60 * 60 * 24);

        // Only update if cache is > 7 days old
        if (cacheAgeDays < 7) {
          debugPrint('ℹ️ Cache is fresh, skipping location update');
          return;
        }
      }

      // Cache is old - update silently in background
      debugPrint('🔄 Updating location in background...');
      await _fetchAndCacheLocation(silent: true);
    } catch (e) {
      debugPrint('⚠️ Background update failed: $e');
      // Ignore errors - we already have cached data
    }
  }

  /// Fetch location and cache it
  Future<void> _fetchAndCacheLocation({bool silent = false}) async {
    try {
      if (!silent) {
        setState(() {
          _isLoadingLocation = true;
          _statusMessage = 'جاري تحديد موقعك...';
        });
      }

      // Check if location service is enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('خدمة الموقع غير مفعلة');
      }

      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('لم يتم منح إذن الوصول للموقع');
      }

      // Get location with timeout
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      // Calculate qibla
      final qibla = _calculateQibla(pos.latitude, pos.longitude);

      // Cache the result
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_cacheKeyLat, pos.latitude);
      await prefs.setDouble(_cacheKeyLon, pos.longitude);
      await prefs.setDouble(_cacheKeyQibla, qibla);
      await prefs.setInt(_cacheKeyTimestamp, DateTime.now().millisecondsSinceEpoch);

      debugPrint('✅ Location cached: ${pos.latitude}, ${pos.longitude} → Qibla: $qibla°');

      if (!silent) {
        setState(() {
          qiblaDirection = qibla;
          _isLoadingLocation = false;
          _statusMessage = 'تم تحديد الموقع';
        });

        _startCompass();
      } else {
        // Silent update - just update qibla direction
        setState(() {
          qiblaDirection = qibla;
        });
      }
    } catch (e) {
      debugPrint('❌ Location error: $e');

      if (!silent) {
        setState(() {
          _isLoadingLocation = false;
          _statusMessage = 'تعذر تحديد الموقع. يرجى المحاولة لاحقاً.';
        });

        // Show error dialog
        if (mounted) {
          _showLocationErrorDialog(e.toString());
        }
      }
    }
  }

  /// Show error dialog with options
  void _showLocationErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('خطأ في تحديد الموقع'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(error),
            const SizedBox(height: 16),
            const Text(
              'يمكنك:\n'
                  '• تفعيل خدمة الموقع في الإعدادات\n'
                  '• منح التطبيق إذن الوصول للموقع\n'
                  '• إدخال مدينتك يدوياً',
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showManualLocationInput();
            },
            child: const Text('إدخال يدوي'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openLocationSettings();
            },
            child: const Text('فتح الإعدادات'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _fetchAndCacheLocation();
            },
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  /// Manual location input (fallback)
  void _showManualLocationInput() {
    // Common Algerian cities with coordinates
    final cities = {
      'Algiers': {'lat': 36.7538, 'lon': 3.0588},
      'Oran': {'lat': 35.6969, 'lon': -0.6331},
      'Constantine': {'lat': 36.365, 'lon': 6.6147},
      'Annaba': {'lat': 36.9, 'lon': 7.7667},
      'Blida': {'lat': 36.4703, 'lon': 2.8277},
      'Sétif': {'lat': 36.1905, 'lon': 5.4122},
      'Tlemcen': {'lat': 34.8780, 'lon': -1.3150},
    };

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('اختر مدينتك'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: cities.entries.map((entry) {
              return ListTile(
                title: Text(entry.key),
                onTap: () async {
                  final lat = entry.value['lat']!;
                  final lon = entry.value['lon']!;
                  final qibla = _calculateQibla(lat, lon);

                  // Cache manual location
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setDouble(_cacheKeyLat, lat);
                  await prefs.setDouble(_cacheKeyLon, lon);
                  await prefs.setDouble(_cacheKeyQibla, qibla);
                  await prefs.setInt(_cacheKeyTimestamp, DateTime.now().millisecondsSinceEpoch);

                  setState(() {
                    qiblaDirection = qibla;
                    _isLoadingLocation = false;
                  });

                  _startCompass();
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _startCompass() {
    _compassSub?.cancel(); // Cancel existing subscription

    _compassSub = FlutterCompass.events?.listen((event) {
      if (!mounted) return;

      double? newHeading = event.heading;
      if (newHeading == null) return;

      // Smooth filtering - ignore small changes
      if (heading != null && (newHeading - heading!).abs() < 0.5) return;

      setState(() { heading = newHeading; });

      if (qiblaDirection != null) {
        double diff = ((heading! - qiblaDirection!) + 360) % 360;
        bool facing = diff < 6 || diff > 354;

        if (facing != _facing) {
          setState(() => _facing = facing);
          _arrowController.forward(from: 0);
        }

        // Haptic feedback when facing Qibla
        if (facing) {
          final now = DateTime.now();
          if (now.difference(_lastVibrate).inMilliseconds > 1500) {
            _lastVibrate = now;
            Vibration.hasVibrator().then((has) {
              if (has ?? false) Vibration.vibrate(duration: 60);
            });
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
        title: const Text(
          'Ultra Qibla',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          // Refresh button to manually update location
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _fetchAndCacheLocation(),
            tooltip: 'تحديث الموقع',
          ),
        ],
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
          child: _isLoadingLocation
              ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: Colors.white),
                const SizedBox(height: 16),
                Text(
                  _statusMessage,
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
              : heading == null
              ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(height: 16),
                Text(
                  'جاري الاتصال بالبوصلة...',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          )
              : Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: Size(size, size),
                  painter: QiblaCompassPainter(size: size),
                ),
                AnimatedBuilder(
                  animation: _arrowController,
                  builder: (context, _) {
                    final rotationRad = _degToRad(
                        (qiblaDirection! - heading!) * -1);
                    return Transform.rotate(
                      angle: rotationRad,
                      child: Container(
                        width: 24,
                        height: size / 2,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFFFF700),
                              Color(0xFFFFA500)
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.yellowAccent
                                  .withOpacity(0.8),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                ScaleTransition(
                  scale: Tween(begin: 0.95, end: 1.15)
                      .animate(_pulseController),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _facing
                          ? Colors.greenAccent
                          : Colors.white.withOpacity(0.15),
                      boxShadow: [
                        BoxShadow(
                          color: _facing
                              ? Colors.greenAccent.withOpacity(0.9)
                              : Colors.white.withOpacity(0.06),
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
                      Text(
                        'زاوية القبلة: ${qiblaDirection!.toStringAsFixed(1)}°',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'اتجاه الهاتف: ${heading!.toStringAsFixed(1)}°',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _facing
                            ? 'أنت على القبلة ✅'
                            : 'قم بتدوير جهازك لتواجه القبلة',
                        style: TextStyle(
                          color: _facing
                              ? Colors.greenAccent.shade400
                              : Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
      ..shader = RadialGradient(
        colors: [Colors.white70, Colors.white24],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, outer);

    final tickPaint = Paint()..color = Colors.white70.withOpacity(0.8);
    for (int i = 0; i < 360; i += 10) {
      final rad = i * pi / 180;
      final inner = radius - (i % 30 == 0 ? 20 : 12);
      final start = Offset(
        center.dx + inner * cos(rad),
        center.dy + inner * sin(rad),
      );
      final end = Offset(
        center.dx + radius * cos(rad),
        center.dy + radius * sin(rad),
      );
      tickPaint.strokeWidth = (i % 30 == 0 ? 2.0 : 1.0);
      canvas.drawLine(start, end, tickPaint);
    }

    final style = TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.bold,
      shadows: [const Shadow(color: Colors.black54, blurRadius: 6)],
    );
    _drawText(canvas, 'N', center.dx, center.dy - radius + 32, style);
    _drawText(canvas, 'S', center.dx, center.dy + radius - 32, style);
    _drawText(canvas, 'E', center.dx + radius - 32, center.dy, style);
    _drawText(canvas, 'W', center.dx - radius + 32, center.dy, style);
  }

  void _drawText(Canvas canvas, String text, double x, double y, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}