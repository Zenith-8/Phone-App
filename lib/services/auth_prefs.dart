import 'package:shared_preferences/shared_preferences.dart';

/// Persists optional "remember me" email for the login screen.
class AuthPrefs {
  static const _emailKey = 'liftelligence_saved_email';
  static const _rememberKey = 'liftelligence_remember_me';

  static Future<String?> loadSavedEmail() async {
    final p = await SharedPreferences.getInstance();
    if (p.getBool(_rememberKey) != true) return null;
    return p.getString(_emailKey);
  }

  static Future<void> saveRememberedEmail({required String email, required bool remember}) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_rememberKey, remember);
    if (remember) {
      await p.setString(_emailKey, email.trim());
    } else {
      await p.remove(_emailKey);
    }
  }

  static Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_emailKey);
    await p.remove(_rememberKey);
  }
}
