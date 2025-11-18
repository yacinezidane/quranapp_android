import 'package:flutter/material.dart';
import '../models/athkar_model.dart';
import '../services/api_service.dart';
import 'athkar_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Athkar> allCategories = [];
  List<Athkar> filteredCategories = [];
  TextEditingController searchController = TextEditingController();
  bool isLoading = true;

  final Color primary = const Color(0xFF0F4C75);
  final Color secondary = const Color(0xFF3282B8);
  final Color cardColor = Colors.white.withOpacity(0.85);

  @override
  void initState() {
    super.initState();
    _loadAthkar();
    searchController.addListener(_filterCategories);
  }

  void _loadAthkar() async {
    try {
      final data = await ApiService.fetchAthkar();
      setState(() {
        allCategories = data;
        filteredCategories = data;
        isLoading = false;
      });
    } catch (e) {
      print('خطأ أثناء تحميل البيانات: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _filterCategories() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredCategories = allCategories
          .where((athkar) => athkar.category.toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: secondary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'حصن المسلم',
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
                    hintText: "ابحث عن قسم...",
                    hintStyle: TextStyle(color: Colors.grey[700]),
                    border: InputBorder.none,
                    icon: Icon(Icons.search, color: primary),
                  ),
                ),
              ),

              // 🔹 قائمة الأقسام
              Expanded(
                child: isLoading
                    ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
                    : filteredCategories.isEmpty
                    ? const Center(
                  child: Text(
                    'لا توجد نتائج',
                    style: TextStyle(
                        color: Colors.white, fontSize: 18),
                  ),
                )
                    : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredCategories.length,
                  itemBuilder: (context, index) {
                    final athkar = filteredCategories[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                AthkarScreen(athkar: athkar),
                          ),
                        );
                      },
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
                            Expanded(
                              child: Text(
                                athkar.category,
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
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
