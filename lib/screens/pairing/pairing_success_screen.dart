import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/app_session.dart';
import '../../services/pairing_payload.dart';
import '../../widgets/app_background.dart';
import '../../widgets/frosted_panel.dart';

class PairingSuccessScreen extends StatefulWidget {
  const PairingSuccessScreen({
    super.key,
    required this.session,
    required this.payload,
    required this.offline,
    required this.pairedUid,
  });

  final AppSession session;
  final PairingPayload payload;
  final bool offline;
  final String? pairedUid;

  @override
  State<PairingSuccessScreen> createState() => _PairingSuccessScreenState();
}

class _PairingSuccessScreenState extends State<PairingSuccessScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    HapticFeedback.lightImpact();
    await widget.session.completePairing(
      payload: widget.payload,
      offline: widget.offline,
      uid: widget.pairedUid,
    );
    if (!mounted) return;
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Paired')),
      body: AppBackground(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: FrostedPanel(
                borderRadius: BorderRadius.circular(26),
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) {
                        final t = Curves.elasticOut.transform(
                          _controller.value,
                        );
                        final scale = 0.85 + 0.15 * t;
                        return Transform.scale(
                          scale: scale,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  scheme.primary,
                                  Color.lerp(
                                    scheme.primary,
                                    scheme.secondary,
                                    0.42,
                                  )!,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(26),
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              size: 44,
                              color: Colors.white,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.offline ? 'Saved in demo mode' : 'Bench paired',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${widget.payload.host}:${widget.payload.port} - Token ${widget.payload.maskedToken()}',
                      style: TextStyle(
                        color: scheme.onSurface.withValues(alpha: 0.72),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (widget.pairedUid != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'UID: ${widget.pairedUid}',
                        style: TextStyle(
                          color: scheme.onSurface.withValues(alpha: 0.72),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 14),
                    Text(
                      widget.offline
                          ? 'When you are ready, enable Pair using server for the real enrollment flow.'
                          : 'Tap your NFC card on the bench again to log in.',
                      style: const TextStyle(height: 1.35),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _continue,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Continue'),
                          const SizedBox(width: 8),
                          Transform.rotate(
                            angle: math.pi,
                            child: const Icon(
                              Icons.arrow_back_rounded,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
