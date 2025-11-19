import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notifications_service.dart';
import '../config/debug_config.dart';

// ============================================
// CONSTANTS
// ============================================

const List<String> kAlgerianCities = [
  "Adrar", "Chlef", "Laghouat", "Oum El Bouaghi", "Batna", "Béjaïa", "Biskra",
  "Béchar", "Blida", "Bouira", "Tamanrasset", "Tébessa", "Tlemcen", "Tiaret",
  "Tizi Ouzou", "Algiers", "Djelfa", "Jijel", "Sétif", "Saïda", "Skikda",
  "Sidi Bel Abbès", "Annaba", "Guelma", "Constantine", "Médéa", "Mostaganem",
  "M'Sila", "Mascara", "Ouargla", "Oran", "El Bayadh", "Illizi",
  "Bordj Bou Arreridj", "Boumerdès", "El Tarf", "Tindouf", "Tissemsilt",
  "El Oued", "Khenchela", "Souk Ahras", "Tipaza", "Mila", "Aïn Defla",
  "Naâma", "Aïn Témouchent", "Ghardaïa", "Relizane"
];

// ============================================
// PRAYER TIMES PAGE
// ============================================

class PrayerTimesPage extends StatefulWidget {
  const PrayerTimesPage({super.key});

  @override
  State<PrayerTimesPage> createState() => _PrayerTimesPageState();
}

class _PrayerTimesPageState extends State<PrayerTimesPage> {
  Map<String, String> timings = {};
  String selectedCity = "Algiers";
  bool loading = true;
  String nextPrayer = "";
  Duration remaining = Duration.zero;
  Timer? countdownTimer;
  String errorMessage = "";

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // Initialize notification service
    await NotificationService.initialize();

    // Load prayer times
    await _loadSavedCityAndTimings();
  }

  Future<void> _loadSavedCityAndTimings() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCity = prefs.getString('city');
    if (savedCity != null) selectedCity = savedCity;

    final today = DateTime.now().day;
    final savedDay = prefs.getInt('saved_day') ?? today;
    final savedTimings = prefs.getString('timings_$selectedCity');

    if (savedTimings != null && savedDay == today) {
      timings = Map<String, String>.from(jsonDecode(savedTimings));
      loading = false;
      _startCountdown();
      await _scheduleAllPrayers();
    } else {
      await _fetchPrayerTimes(selectedCity);
    }
    setState(() {});
  }

  Future<void> _fetchPrayerTimes(String city) async {
    setState(() {
      loading = true;
      errorMessage = "";
    });

    try {
      final timestamp = (DateTime.now().millisecondsSinceEpoch / 1000).round();
      final url = Uri.parse(
          "https://api.aladhan.com/v1/timingsByCity/$timestamp?city=$city&country=Algeria&method=2");

      final res = await http.get(url);
      final data = jsonDecode(res.body);

      if (data["code"] == 200) {
        final Map<String, dynamic> t = data["data"]["timings"];
        timings = {
          "الفجر": t["Fajr"],
          "الشروق": t["Sunrise"],
          "الظهر": t["Dhuhr"],
          "العصر": t["Asr"],
          "المغرب": t["Maghrib"],
          "العشاء": t["Isha"],
        };

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('city', city);
        await prefs.setString('timings_$city', jsonEncode(timings));
        await prefs.setInt('saved_day', DateTime.now().day);

        loading = false;
        _startCountdown();
        await _scheduleAllPrayers();
      } else {
        throw Exception("API returned code: ${data['code']}");
      }
    } catch (e) {
      setState(() {
        loading = false;
        errorMessage = "فشل تحميل المواقيت: $e";
      });
      DebugConfig.log('Error fetching prayer times: $e');
    }

    setState(() {});
  }

  Future<void> _scheduleAllPrayers() async {
    await NotificationService.cancelAllNotifications();

    int notificationId = 0;
    final now = DateTime.now();

    for (var entry in timings.entries) {
      final prayerName = entry.key;
      final timeString = entry.value;

      // Skip Sunrise (not a prayer time)
      if (prayerName == "الشروق") continue;

      final parts = timeString.split(":");
      DateTime scheduleTime = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );

      // If time has passed today, schedule for tomorrow
      if (scheduleTime.isBefore(now)) {
        scheduleTime = scheduleTime.add(const Duration(days: 1));
      }

      await NotificationService.scheduleNotification(
        id: notificationId++,
        prayerName: prayerName,
        scheduleTime: scheduleTime,
      );
    }

    DebugConfig.log('Scheduled $notificationId prayer notifications');
  }

  void _startCountdown() {
    countdownTimer?.cancel();
    _updateCountdown();
    countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateCountdown();
    });
  }

  void _updateCountdown() {
    final now = DateTime.now();
    DateTime? next;
    String? prayerName;

    timings.forEach((name, time) {
      if (name == "الشروق") return; // Skip sunrise

      final parts = time.split(":");
      final prayerTime = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );

      if (prayerTime.isAfter(now) && (next == null || prayerTime.isBefore(next!))) {
        next = prayerTime;
        prayerName = name;
      }
    });

    if (next == null) {
      // Next prayer is Fajr tomorrow
      final fajrTime = timings["الفجر"]!.split(":");
      next = DateTime(
        now.year,
        now.month,
        now.day + 1,
        int.parse(fajrTime[0]),
        int.parse(fajrTime[1]),
      );
      prayerName = "الفجر";
    }

    setState(() {
      nextPrayer = prayerName!;
      remaining = next!.difference(now);
    });
  }

  Future<void> _changeCity() async {
    final city = await showSearch<String>(
      context: context,
      delegate: CitySearchDelegate(kAlgerianCities),
    );

    if (city != null && city.isNotEmpty) {
      setState(() => selectedCity = city);
      await _fetchPrayerTimes(city);
    }
  }

  // 🔥 DEBUG: Test notification immediately
  Future<void> _testNotificationNow() async {
    await NotificationService.showInstantNotification("الاختبار");

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ تم إرسال إشعار تجريبي!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // 🔥 DEBUG: Schedule test notification in 10 seconds
  Future<void> _testNotificationIn10Seconds() async {
    final testTime = DateTime.now().add(const Duration(seconds: 10));

    await NotificationService.scheduleNotification(
      id: 999,
      prayerName: "الاختبار (10 ثواني)",
      scheduleTime: testTime,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⏰ سيظهر إشعار تجريبي بعد 10 ثواني'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  // 🔥 DEBUG: Show pending notifications
  Future<void> _showPendingNotifications() async {
    final pending = await NotificationService.getPendingNotifications();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('الإشعارات المجدولة'),
        content: pending.isEmpty
            ? const Text('لا توجد إشعارات مجدولة')
            : SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: pending.length,
            itemBuilder: (context, index) {
              final notification = pending[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text('${notification.id}'),
                  ),
                  title: Text(notification.title ?? 'No title'),
                  subtitle: Text(notification.body ?? 'No body'),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  // 🔥 DEBUG: Clear all notifications
  Future<void> _clearAllNotifications() async {
    await NotificationService.cancelAllNotifications();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🗑️ تم حذف جميع الإشعارات المجدولة'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(d.inHours)}:${twoDigits(d.inMinutes % 60)}:${twoDigits(d.inSeconds % 60)}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'مواقيت الصلاة',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 26,
            color: Colors.white,
          ),
        ),
        actions: [
          // 🔥 ONLY SHOW DEBUG MENU IF DEBUG MODE IS ENABLED
          if (DebugConfig.isDebugMode) ...[
            PopupMenuButton<String>(
              icon: const Icon(Icons.bug_report, color: Colors.amber),
              tooltip: 'Debug Menu',
              onSelected: (value) {
                switch (value) {
                  case 'test_now':
                    _testNotificationNow();
                    break;
                  case 'test_10s':
                    _testNotificationIn10Seconds();
                    break;
                  case 'show_pending':
                    _showPendingNotifications();
                    break;
                  case 'clear_all':
                    _clearAllNotifications();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'test_now',
                  child: Row(
                    children: [
                      Icon(Icons.notifications_active, size: 20),
                      SizedBox(width: 8),
                      Text('إشعار فوري'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'test_10s',
                  child: Row(
                    children: [
                      Icon(Icons.timer, size: 20),
                      SizedBox(width: 8),
                      Text('إشعار بعد 10 ثواني'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'show_pending',
                  child: Row(
                    children: [
                      Icon(Icons.list, size: 20),
                      SizedBox(width: 8),
                      Text('عرض المجدولة'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'clear_all',
                  child: Row(
                    children: [
                      Icon(Icons.delete_sweep, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text(
                        'حذف كل الإشعارات',
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F4C75), Color(0xFF3282B8)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            // Main content
            loading
                ? const Center(
                child: CircularProgressIndicator(color: Colors.white))
                : errorMessage.isNotEmpty
                ? _buildErrorWidget()
                : _buildPrayerTimesContent(),

            // 🐛 DEBUG BANNER (bottom-right corner)
            if (DebugConfig.isDebugMode)
              Positioned(
                bottom: 16,
                right: 16,
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bug_report, size: 16, color: Colors.black87),
                      SizedBox(width: 4),
                      Text(
                        'DEBUG MODE',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 64),
            const SizedBox(height: 16),
            Text(
              errorMessage,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _fetchPrayerTimes(selectedCity),
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrayerTimesContent() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildCitySelector(),
            const SizedBox(height: 25),
            _buildNextPrayerCard(),
            const SizedBox(height: 25),
            _buildPrayerTimesList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCitySelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.2),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_city, color: Colors.white, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "المدينة: $selectedCity",
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
          ElevatedButton.icon(
            onPressed: _changeCity,
            icon: const Icon(Icons.edit, size: 18),
            label: const Text("تغيير"),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextPrayerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.90),
            Colors.white.withOpacity(0.70)
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          const Text(
            "الصلاة القادمة",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            nextPrayer,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F4C75),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.timer_outlined, color: Color(0xFF0F4C75)),
              const SizedBox(width: 8),
              Text(
                _formatDuration(remaining),
                style: const TextStyle(
                  fontSize: 24,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerTimesList() {
    return Expanded(
      child: ListView(
        children: timings.entries.map((entry) {
          final isNext = entry.key == nextPrayer;

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: isNext
                    ? [
                  const Color(0xFF0F4C75).withOpacity(0.9),
                  const Color(0xFF3282B8).withOpacity(0.9)
                ]
                    : [
                  Colors.white.withOpacity(0.90),
                  Colors.white.withOpacity(0.70)
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: ListTile(
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              leading: Icon(
                Icons.access_time_rounded,
                color: isNext ? Colors.white : const Color(0xFF0F4C75),
                size: 30,
              ),
              title: Text(
                entry.key,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isNext ? Colors.white : Colors.black87,
                ),
              ),
              trailing: Text(
                entry.value,
                style: TextStyle(
                  fontSize: 20,
                  color: isNext ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ============================================
// CITY SEARCH DELEGATE
// ============================================

class CitySearchDelegate extends SearchDelegate<String> {
  final List<String> cities;

  CitySearchDelegate(this.cities);

  @override
  List<Widget>? buildActions(BuildContext context) => [
    IconButton(
      icon: const Icon(Icons.clear),
      onPressed: () => query = '',
    ),
  ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () => close(context, ''),
  );

  @override
  Widget buildResults(BuildContext context) {
    final results =
    cities.where((c) => c.toLowerCase().contains(query.toLowerCase()));
    return _buildList(results);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions =
    cities.where((c) => c.toLowerCase().contains(query.toLowerCase()));
    return _buildList(suggestions);
  }

  Widget _buildList(Iterable<String> items) {
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final city = items.elementAt(index);
        return ListTile(
          leading: const Icon(Icons.location_city),
          title: Text(city),
          onTap: () => close(context, city),
        );
      },
    );
  }
}