import 'package:flutter/material.dart';

import 'app_prefs.dart';
import 'auth_prefs.dart';
import 'pairing_payload.dart';

class AppSession extends ChangeNotifier {
  bool _loaded = false;
  bool _seenOnboarding = false;
  bool _signedIn = false;
  String _email = 'demo@liftelligence.local';
  ThemeMode _themeMode = ThemeMode.system;

  bool _paired = false;
  bool _pairedOffline = false;
  PairingPayload? _payload;
  String? _pairedUid;

  bool get isLoaded => _loaded;
  bool get hasSeenOnboarding => _seenOnboarding;
  bool get isSignedIn => _signedIn;
  String get email => _email;
  ThemeMode get themeMode => _themeMode;

  bool get isPaired => _paired;
  bool get pairedOffline => _pairedOffline;
  PairingPayload? get pairingPayload => _payload;
  String? get pairedUid => _pairedUid;

  Future<void> load() async {
    _signedIn = await AppPrefs.loadSignedIn();
    _seenOnboarding = await AppPrefs.loadSeenOnboarding();
    _email = (await AppPrefs.loadUserEmail()) ?? _email;
    _themeMode = await AppPrefs.loadThemeMode();

    _paired = await AppPrefs.loadPaired();
    _pairedOffline = await AppPrefs.loadPairedOffline();
    _payload = await AppPrefs.loadPairingPayload();
    _pairedUid = await AppPrefs.loadPairedUid();

    _loaded = true;
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    _seenOnboarding = true;
    await AppPrefs.setSeenOnboarding(true);
    notifyListeners();
  }

  Future<void> signIn(String email) async {
    final trimmed = email.trim();
    _signedIn = true;
    _email = trimmed.isEmpty ? _email : trimmed;
    await AppPrefs.setSignedIn(true);
    await AppPrefs.setUserEmail(_email);
    notifyListeners();
  }

  Future<void> signOut() async {
    _signedIn = false;
    _paired = false;
    _pairedOffline = false;
    _payload = null;
    _pairedUid = null;

    await AppPrefs.clearSession();
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await AppPrefs.setThemeMode(mode);
    notifyListeners();
  }

  Future<void> resetPairing() async {
    _paired = false;
    _pairedOffline = false;
    _payload = null;
    _pairedUid = null;

    await AppPrefs.setPaired(false);
    await AppPrefs.setPairedOffline(false);
    await AppPrefs.setPairingPayload(null);
    await AppPrefs.setPairedUid(null);
    notifyListeners();
  }

  Future<void> completePairing({
    required PairingPayload payload,
    required bool offline,
    String? uid,
  }) async {
    _paired = true;
    _pairedOffline = offline;
    _payload = payload;
    _pairedUid = uid;

    await AppPrefs.setPaired(true);
    await AppPrefs.setPairedOffline(offline);
    await AppPrefs.setPairingPayload(payload);
    await AppPrefs.setPairedUid(uid);
    notifyListeners();
  }

  /// Clears all app state (including onboarding) so the app behaves like a fresh install.
  Future<void> resetApp() async {
    _loaded = true;
    _seenOnboarding = false;
    _signedIn = false;
    _paired = false;
    _pairedOffline = false;
    _payload = null;
    _pairedUid = null;
    _email = 'demo@liftelligence.local';
    _themeMode = ThemeMode.system;

    await AppPrefs.clearAll();
    await AuthPrefs.clear();
    notifyListeners();
  }
}
