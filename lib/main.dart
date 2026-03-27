import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/pairing/pairing_screen.dart';
import 'screens/splash_screen.dart';
import 'services/app_session.dart';
import 'services/pairing_payload.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final session = AppSession();
  unawaited(session.load());
  runApp(LiftelligenceApp(session: session));
}

class LiftelligenceApp extends StatelessWidget {
  const LiftelligenceApp({super.key, required this.session});

  final AppSession session;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        return MaterialApp(
          title: 'LIFTelligence',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: session.themeMode,
          home: AppRoot(session: session),
        );
      },
    );
  }
}

class AppRoot extends StatefulWidget {
  const AppRoot({super.key, required this.session});

  final AppSession session;

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSub;

  @override
  void initState() {
    super.initState();
    _appLinks = AppLinks();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    // Handle the URI that launched the app (cold start).
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) _handleUri(initialUri);
    } catch (_) {
      // No initial link or platform doesn't support it.
    }

    // Handle URIs while the app is already running (warm resume).
    _linkSub = _appLinks.uriLinkStream.listen(_handleUri);
  }

  void _handleUri(Uri uri) {
    final payload = PairingPayload.tryParse(uri.toString());
    if (payload == null) return;

    final session = widget.session;
    if (session.isSignedIn && !session.isPaired) {
      // Already on (or heading to) the pairing screen — push directly.
      session.setPendingDeepLink(payload);
    } else if (session.isPaired) {
      // Already paired — reset pairing so the new deep link takes effect.
      session.resetPairing().then((_) {
        session.setPendingDeepLink(payload);
      });
    } else {
      // Not signed in yet — store for later.
      session.setPendingDeepLink(payload);
    }
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;

    final Widget child;
    if (!session.isLoaded) {
      child = const SplashScreen(key: ValueKey('splash'));
    } else if (!session.hasSeenOnboarding) {
      child = OnboardingScreen(
        key: const ValueKey('onboarding'),
        onDone: () => session.completeOnboarding(),
      );
    } else if (!session.isSignedIn) {
      child = LoginScreen(
        key: const ValueKey('login'),
        onLogin: (email) => session.signIn(email),
      );
    } else if (!session.isPaired) {
      child = PairingScreen(
        key: const ValueKey('pairing'),
        session: session,
        initialPayload: session.consumePendingDeepLink(),
      );
    } else {
      child = DashboardScreen(
        key: const ValueKey('dashboard'),
        onLogout: () => session.signOut(),
        onResetPairing: () => session.resetPairing(),
        onResetApp: () => session.resetApp(),
        userEmail: session.email,
        pairingPayload: session.pairingPayload,
        pairedOffline: session.pairedOffline,
        themeMode: session.themeMode,
        onThemeModeChanged: (m) => session.setThemeMode(m),
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final fade = FadeTransition(opacity: animation, child: child);
        final offsetTween = Tween<Offset>(
          begin: const Offset(0.02, 0.01),
          end: Offset.zero,
        );
        return SlideTransition(
          position: animation
              .drive(CurveTween(curve: Curves.easeOutCubic))
              .drive(offsetTween),
          child: fade,
        );
      },
      child: child,
    );
  }
}
