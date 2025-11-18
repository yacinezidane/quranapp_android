import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as quran;
import 'Shared.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TextEditingController searchController = TextEditingController();
  List<int> filteredSurahs = List.generate(114, (i) => i + 1);

  final Color primary = const Color(0xFF0F4C75); // أزرق داكن
  final Color secondary = const Color(0xFF3282B8); // أزرق فاتح
  final Color cardColor = Colors.white.withOpacity(0.85); // شفافية البطاقة
  final Color bg = const Color(0xFFE0F0FF); // خلفية فاتحة

  @override
  void initState() {
    super.initState();
    searchController.addListener(_filter);
  }

  void _filter() {
    String q = searchController.text.trim();
    setState(() {
      filteredSurahs = q.isEmpty
          ? List.generate(114, (i) => i + 1)
          : List.generate(114, (i) => i + 1)
          .where((n) => quran.getSurahNameArabic(n).contains(q))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "القرآن الكريم",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 26,
            color: Colors.white,
          ),
        ),
      ),

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F4C75), Color(0xFF3282B8)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 🔹 البحث
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: TextField(
                  controller: searchController,
                  textAlign: TextAlign.right,
                  style: TextStyle(color: primary, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    hintText: "ابحث عن سورة...",
                    hintStyle: TextStyle(color: Colors.grey[700]),
                    border: InputBorder.none,
                    icon: Icon(Icons.search, color: primary),
                  ),
                ),
              ),

              // 🔹 قائمة السور
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredSurahs.length,
                  itemBuilder: (context, index) {
                    final surah = filteredSurahs[index];

                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SurahScreen(surahNumber: surah),
                        ),
                      ),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: [
                              cardColor,
                              cardColor.withOpacity(0.95),
                            ],
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Row(
                          children: [
                            // رقم السورة
                            Container(
                              height: 50,
                              width: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black12, blurRadius: 5)
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  "$surah",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: primary,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 16),

                            // اسم السورة وعدد الآيات
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    quran.getSurahNameArabic(surah),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "${quran.getVerseCount(surah)} آية",
                                    style: TextStyle(
                                      color: Colors.grey[800],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Icon(Icons.arrow_forward_ios,
                                color: primary, size: 20),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
