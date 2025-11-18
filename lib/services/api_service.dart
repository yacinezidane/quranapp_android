import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/athkar_model.dart';

class ApiService {
  static const String url =
      'https://raw.githubusercontent.com/rn0x/Adhkar-json/main/adhkar.json';

  static const String cacheKey = 'cached_athkar';

  static Future<List<Athkar>> fetchAthkar() async {
    try {
      // محاولة جلب البيانات من الإنترنت
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);

        // تخزين نسخة في الهاتف
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(cacheKey, response.body);

        return data.map((json) => Athkar.fromJson(json)).toList();
      } else {
        throw Exception('فشل تحميل البيانات من الإنترنت');
      }
    } catch (e) {
      // إذا فشل الاتصال بالإنترنت، جلب من التخزين المحلي
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(cacheKey);

      if (cachedData != null) {
        List<dynamic> data = json.decode(cachedData);
        return data.map((json) => Athkar.fromJson(json)).toList();
      } else {
        throw Exception('لا يمكن تحميل البيانات، ولا توجد بيانات محفوظة');
      }
    }
  }
}
