import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/app_background.dart';
import '../widgets/app_mark.dart';
import '../widgets/frosted_panel.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _pages = <_OnboardingPageData>[
    _OnboardingPageData(
      icon: Icons.nfc_rounded,
      title: 'Tap in with NFC',
      body:
          'Tap your NFC card on the bench to start. If the card is new, the bench shows a QR pairing code.',
    ),
    _OnboardingPageData(
      icon: Icons.qr_code_scanner_rounded,
      title: 'Pair once',
      body:
          'On your first sign-in, scan the bench QR code to securely link your account to that machine.',
    ),
    _OnboardingPageData(
      icon: Icons.query_stats_rounded,
      title: 'Track every session',
      body:
          'Review recent workouts, weekly volume, and notes in one clean dashboard.',
    ),
  ];

  final _controller = PageController();
  double _page = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (!mounted) return;
      setState(() => _page = _controller.page ?? 0);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int get _index => _page.round().clamp(0, _pages.length - 1);
  bool get _isLast => _index == _pages.length - 1;

  Future<void> _next() async {
    HapticFeedback.lightImpact();
    if (_isLast) {
      widget.onDone();
      return;
    }
    await _controller.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome'),
        actions: [
          TextButton(onPressed: widget.onDone, child: const Text('Skip')),
        ],
      ),
      body: AppBackground(
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: AppMark(size: 48, heroTag: 'onboarding-mark'),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  itemBuilder: (context, i) {
                    final t = (_page - i).clamp(-1.0, 1.0);
                    final scale = 1 - 0.05 * t.abs();
                    final opacity = 1 - 0.25 * t.abs();

                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                      child: Transform.scale(
                        scale: scale,
                        child: Opacity(
                          opacity: opacity,
                          child: _OnboardingPageCard(
                            data: _pages[i],
                            pageDistance: t.abs(),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                child: FrostedPanel(
                  borderRadius: BorderRadius.circular(24),
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Column(
                    children: [
                      _Dots(
                        count: _pages.length,
                        page: _page,
                        activeColor: scheme.primary,
                        inactiveColor: scheme.outlineVariant,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _next,
                          child: Text(_isLast ? 'Get Started' : 'Continue'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tip: Use Simulate first sign-in in dashboard settings to re-run pairing.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.68),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPageCard extends StatelessWidget {
  const _OnboardingPageCard({required this.data, required this.pageDistance});

  final _OnboardingPageData data;
  final double pageDistance;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final spin = 0.02 * pageDistance * math.pi;

    return FrostedPanel(
      borderRadius: BorderRadius.circular(28),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Transform.rotate(
            angle: spin,
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    scheme.primary.withValues(alpha: 0.95),
                    Color.lerp(
                      scheme.primary,
                      scheme.secondary,
                      0.52,
                    )!.withValues(alpha: 0.95),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.3),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Icon(data.icon, size: 48, color: Colors.white),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Text(
            data.body,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.74),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}

class _Dots extends StatelessWidget {
  const _Dots({
    required this.count,
    required this.page,
    required this.activeColor,
    required this.inactiveColor,
  });

  final int count;
  final double page;
  final Color activeColor;
  final Color inactiveColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 7,
            width: _dotWidth(i),
            decoration: BoxDecoration(
              color: _dotColor(i),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
      ],
    );
  }

  double _dotWidth(int i) {
    final d = (page - i).abs().clamp(0.0, 1.0);
    return 7 + (18 * (1 - d));
  }

  Color _dotColor(int i) {
    final d = (page - i).abs().clamp(0.0, 1.0);
    return Color.lerp(activeColor, inactiveColor, d) ?? activeColor;
  }
}
