import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class UserService {
  static const String _userIdKey = 'user_id';
  static const Uuid _uuid = Uuid();

  /// Get the current user ID, generating one if it doesn't exist
  static Future<String> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString(_userIdKey);

    if (userId == null || userId.isEmpty) {
      // Generate a new user ID
      userId = _uuid.v4();
      await prefs.setString(_userIdKey, userId);
      print('🆔 Generated new user ID: $userId');
    } else {
      print('🆔 Using existing user ID: $userId');
    }

    return userId;
  }

  /// Clear the stored user ID (useful for testing or logout)
  static Future<void> clearUserId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    print('🆔 User ID cleared');
  }
}
