class DebugConfig {
  // 🔧 TOGGLE THIS TO ENABLE/DISABLE DEBUG MODE
  static const bool isDebugMode = true;  // ← Set to false for production

  // Debug info
  static void log(String message) {
    if (isDebugMode) {
      print('🐛 DEBUG: $message');
    }
  }
}