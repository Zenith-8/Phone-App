import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'pairing_payload.dart';

/// Device-local preferences for app session + pairing state.
///
/// Keep this separate from [AuthPrefs], which only stores the optional
/// "remembered email" value for the login screen.
abstract final class AppPrefs {
  static const _signedInKey = 'liftelligence_signed_in';
  static const _userEmailKey = 'liftelligence_user_email';
  static const _themeModeKey = 'liftelligence_theme_mode';
  static const _seenOnboardingKey = 'liftelligence_seen_onboarding';

  static const _pairedKey = 'liftelligence_paired';
  static const _pairedOfflineKey = 'liftelligence_paired_offline';
  static const _pairedUidKey = 'liftelligence_paired_uid';
  static const _pairHostKey = 'liftelligence_pair_host';
  static const _pairPortKey = 'liftelligence_pair_port';
  static const _pairTokenKey = 'liftelligence_pair_token';

  static Future<bool> loadSignedIn() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_signedInKey) ?? false;
  }

  static Future<void> setSignedIn(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_signedInKey, v);
  }

  static Future<String?> loadUserEmail() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_userEmailKey);
  }

  static Future<void> setUserEmail(String? email) async {
    final p = await SharedPreferences.getInstance();
    if (email == null || email.trim().isEmpty) {
      await p.remove(_userEmailKey);
      return;
    }
    await p.setString(_userEmailKey, email.trim());
  }

  static Future<ThemeMode> loadThemeMode() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_themeModeKey);
    return switch (raw) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  static Future<void> setThemeMode(ThemeMode mode) async {
    final p = await SharedPreferences.getInstance();
    final raw = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await p.setString(_themeModeKey, raw);
  }

  static Future<bool> loadSeenOnboarding() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_seenOnboardingKey) ?? false;
  }

  static Future<void> setSeenOnboarding(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_seenOnboardingKey, v);
  }

  static Future<bool> loadPaired() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_pairedKey) ?? false;
  }

  static Future<void> setPaired(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_pairedKey, v);
  }

  static Future<bool> loadPairedOffline() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_pairedOfflineKey) ?? false;
  }

  static Future<void> setPairedOffline(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_pairedOfflineKey, v);
  }

  static Future<String?> loadPairedUid() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_pairedUidKey);
  }

  static Future<void> setPairedUid(String? uid) async {
    final p = await SharedPreferences.getInstance();
    if (uid == null || uid.trim().isEmpty) {
      await p.remove(_pairedUidKey);
      return;
    }
    await p.setString(_pairedUidKey, uid.trim());
  }

  static Future<PairingPayload?> loadPairingPayload() async {
    final p = await SharedPreferences.getInstance();
    final host = p.getString(_pairHostKey);
    final port = p.getInt(_pairPortKey);
    final token = p.getString(_pairTokenKey);
    if (host == null || host.isEmpty || port == null || token == null || token.isEmpty) return null;
    return PairingPayload(host: host, port: port, token: token);
  }

  static Future<void> setPairingPayload(PairingPayload? payload) async {
    final p = await SharedPreferences.getInstance();
    if (payload == null) {
      await p.remove(_pairHostKey);
      await p.remove(_pairPortKey);
      await p.remove(_pairTokenKey);
      return;
    }
    await p.setString(_pairHostKey, payload.host);
    await p.setInt(_pairPortKey, payload.port);
    await p.setString(_pairTokenKey, payload.token);
  }

  /// Clears only session + pairing state (keeps theme and onboarding flags).
  static Future<void> clearSession() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_signedInKey);
    await p.remove(_userEmailKey);
    await p.remove(_pairedKey);
    await p.remove(_pairedOfflineKey);
    await p.remove(_pairedUidKey);
    await p.remove(_pairHostKey);
    await p.remove(_pairPortKey);
    await p.remove(_pairTokenKey);
  }

  static Future<void> clearAll() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_signedInKey);
    await p.remove(_userEmailKey);
    await p.remove(_themeModeKey);
    await p.remove(_seenOnboardingKey);
    await p.remove(_pairedKey);
    await p.remove(_pairedOfflineKey);
    await p.remove(_pairedUidKey);
    await p.remove(_pairHostKey);
    await p.remove(_pairPortKey);
    await p.remove(_pairTokenKey);
  }
}
