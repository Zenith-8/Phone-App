import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../services/pairing_payload.dart';
import '../../widgets/frosted_panel.dart';

class PairingScanScreen extends StatefulWidget {
  const PairingScanScreen({super.key});

  static Route<PairingPayload?> route() {
    final isCupertino =
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
    if (isCupertino) {
      return CupertinoPageRoute<PairingPayload?>(
        builder: (_) => const PairingScanScreen(),
      );
    }
    return MaterialPageRoute<PairingPayload?>(
      builder: (_) => const PairingScanScreen(),
    );
  }

  @override
  State<PairingScanScreen> createState() => _PairingScanScreenState();
}

class _PairingScanScreenState extends State<PairingScanScreen>
    with SingleTickerProviderStateMixin {
  late final MobileScannerController _controller;
  late final AnimationController _scanAnim;
  bool _popping = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      facing: CameraFacing.back,
      detectionSpeed: DetectionSpeed.noDuplicates,
      formats: const [BarcodeFormat.qrCode],
    );
    _scanAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scanAnim.dispose();
    super.dispose();
  }

  Future<void> _pop(PairingPayload? payload) async {
    if (_popping) return;
    _popping = true;
    await _controller.stop();
    if (!mounted) return;
    Navigator.of(context).pop(payload);
  }

  void _onDetect(BarcodeCapture capture) {
    if (_popping) return;
    for (final b in capture.barcodes) {
      final raw = b.rawValue;
      if (raw == null) continue;
      final parsed = PairingPayload.tryParse(raw);
      if (parsed != null) {
        HapticFeedback.mediumImpact();
        _pop(parsed);
        return;
      }
    }
  }

  Future<void> _manualEntry() async {
    final controller = TextEditingController();
    final scheme = Theme.of(context).colorScheme;
    final payload = await showModalBottomSheet<PairingPayload?>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            0,
            16,
            MediaQuery.viewInsetsOf(context).bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Enter pairing code',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'Paste the QR contents (starts with `liftelligence://pair`).',
                style: TextStyle(
                  color: scheme.onSurface.withValues(alpha: 0.72),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                minLines: 2,
                maxLines: 5,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Pairing URL',
                  hintText: 'liftelligence://pair?host=...&port=...&token=...',
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () {
                  final parsed = PairingPayload.tryParse(controller.text);
                  Navigator.of(context).pop(parsed);
                },
                child: const Text('Use code'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    controller.dispose();
    if (!mounted) return;
    if (payload == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not a valid pairing code.')),
      );
      return;
    }
    _pop(payload);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const cutoutSize = 260.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR'),
        actions: [
          IconButton(
            tooltip: 'Manual entry',
            onPressed: _manualEntry,
            icon: const Icon(Icons.keyboard_rounded),
          ),
          IconButton(
            tooltip: 'Flash',
            onPressed: () => _controller.toggleTorch(),
            icon: const Icon(Icons.flashlight_on_rounded),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
              errorBuilder: (context, error, _) {
                return _ScannerErrorPanel(
                  message: error.errorDetails?.message ?? 'Camera unavailable.',
                  onManual: _manualEntry,
                );
              },
            ),
          ),
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _scanAnim,
              builder: (context, _) {
                final t = _scanAnim.value;
                final y = (t < 0.5) ? t * 2 : (1 - t) * 2;
                final scanY = (cutoutSize * 0.1) + (cutoutSize * 0.8) * y;

                return CustomPaint(
                  painter: _QrOverlayPainter(
                    color: scheme.scrim.withValues(alpha: 0.62),
                    stroke: scheme.primary.withValues(alpha: 0.9),
                    cutoutSize: cutoutSize,
                    scanLineOffset: scanY,
                  ),
                );
              },
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: FrostedPanel(
                borderRadius: BorderRadius.circular(20),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Row(
                  children: [
                    Icon(Icons.qr_code_scanner_rounded, color: scheme.primary),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Point your camera at the bench QR code.',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _pop(
                        const PairingPayload(
                          host: '127.0.0.1',
                          port: 5001,
                          token: 'DEMO_TOKEN',
                        ),
                      ),
                      child: const Text('Demo'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerErrorPanel extends StatelessWidget {
  const _ScannerErrorPanel({required this.message, required this.onManual});

  final String message;
  final VoidCallback onManual;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: FrostedPanel(
            borderRadius: BorderRadius.circular(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.videocam_off_rounded, size: 40, color: scheme.error),
                const SizedBox(height: 12),
                Text(
                  'Camera access needed',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: scheme.onSurface.withValues(alpha: 0.72),
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: onManual,
                  icon: const Icon(Icons.keyboard_rounded),
                  label: const Text('Enter code manually'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QrOverlayPainter extends CustomPainter {
  const _QrOverlayPainter({
    required this.color,
    required this.stroke,
    required this.cutoutSize,
    required this.scanLineOffset,
  });

  final Color color;
  final Color stroke;
  final double cutoutSize;
  final double scanLineOffset;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final cutoutRect = Rect.fromCenter(
      center: center,
      width: cutoutSize,
      height: cutoutSize,
    );
    final cutoutRRect = RRect.fromRectAndRadius(
      cutoutRect,
      const Radius.circular(22),
    );

    final overlay = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(cutoutRRect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(overlay, Paint()..color = color);

    const corner = 26.0;
    const sw = 4.0;
    final p = Paint()
      ..color = stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.round;

    void cornerPath(Offset start, Offset a, Offset b) {
      canvas.drawLine(start, a, p);
      canvas.drawLine(start, b, p);
    }

    cornerPath(
      cutoutRect.topLeft,
      cutoutRect.topLeft + const Offset(corner, 0),
      cutoutRect.topLeft + const Offset(0, corner),
    );
    cornerPath(
      cutoutRect.topRight,
      cutoutRect.topRight + const Offset(-corner, 0),
      cutoutRect.topRight + const Offset(0, corner),
    );
    cornerPath(
      cutoutRect.bottomLeft,
      cutoutRect.bottomLeft + const Offset(corner, 0),
      cutoutRect.bottomLeft + const Offset(0, -corner),
    );
    cornerPath(
      cutoutRect.bottomRight,
      cutoutRect.bottomRight + const Offset(-corner, 0),
      cutoutRect.bottomRight + const Offset(0, -corner),
    );

    final lineY = cutoutRect.top + scanLineOffset;
    final line = Rect.fromLTWH(
      cutoutRect.left + 18,
      lineY,
      cutoutRect.width - 36,
      2,
    );

    final grad = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        stroke.withValues(alpha: 0),
        stroke.withValues(alpha: 0.9),
        stroke.withValues(alpha: 0),
      ],
      stops: const [0.0, 0.5, 1.0],
      transform: GradientRotation(math.pi * 0.02),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(line, const Radius.circular(99)),
      Paint()..shader = grad.createShader(line),
    );
  }

  @override
  bool shouldRepaint(covariant _QrOverlayPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.stroke != stroke ||
        oldDelegate.cutoutSize != cutoutSize ||
        oldDelegate.scanLineOffset != scanLineOffset;
  }
}
