import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:quranapp/sreen/Home.dart';
import 'package:quranapp/sreen/PrayerTimesPage.dart';
import 'package:quranapp/sreen/QiblaPage.dart';
import 'package:quranapp/sreen/home_screen.dart';



class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  // Map لتخزين الصفحات المحمّلة
  final Map<int, Widget> _cachedScreens = {};

  List<String> labels = ["القرآن", "الأذكار","مواقيت الصلاة","القبلة"];
  List<IconData> icons = [Icons.menu_book, Icons.shield, Icons.access_time, Icons.explore];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  // Lazy load لكل صفحة مع حفظها بعد التحميل الأول
  Widget _getScreen(int index) {
    if (_cachedScreens.containsKey(index)) {
      return _cachedScreens[index]!;
    } else {
      Widget screen;
      switch(index) {
        case 0: screen = const HomePage(); break;
        case 1: screen = const HomeScreen(); break;
        case 2: screen = const PrayerTimesPage(); break;
        case 3: screen = const QiblaPage(); break;
        default: screen = const HomePage(); break;
      }
      _cachedScreens[index] = screen;
      return screen;
    }
  }

  @override
  Widget build(BuildContext context) {
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()!.requestNotificationsPermission();

    return Scaffold(
      backgroundColor: const Color(0xFFD8EEF9),
      body: _getScreen(_selectedIndex), // استخدم Lazy loading هنا
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF0F4C75).withOpacity(0.85),
              const Color(0xFF3282B8).withOpacity(0.85),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(labels.length, (index) {
            final bool isSelected = _selectedIndex == index;

            return GestureDetector(
              onTap: () => _onItemTapped(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: EdgeInsets.symmetric(
                  horizontal: isSelected ? 18 : 0,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withOpacity(0.25)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                  border: isSelected
                      ? Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  )
                      : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      icons[index],
                      color: isSelected ? Colors.white : Colors.white70,
                      size: 28,
                      shadows: isSelected
                          ? [
                        Shadow(
                            color: Colors.white.withOpacity(0.6),
                            blurRadius: 12)
                      ]
                          : [],
                    ),
                    if (isSelected) const SizedBox(width: 8),
                    if (isSelected)
                      Text(
                        labels[index],
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          fontFamily: 'Cairo',
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
