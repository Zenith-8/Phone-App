import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../config/server_config.dart';
import '../../services/app_session.dart';
import '../../services/nfc_login_server_client.dart';
import '../../services/pairing_payload.dart';
import '../../widgets/app_background.dart';
import '../../widgets/frosted_panel.dart';
import 'pairing_scan_screen.dart';
import 'pairing_success_screen.dart';

class PairingScreen extends StatefulWidget {
  const PairingScreen({
    super.key,
    required this.session,
    this.initialPayload,
  });

  final AppSession session;

  /// Pre-filled payload from a deep link (if the app was opened via QR scan).
  final PairingPayload? initialPayload;

  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen> {
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  PairingPayload? _payload;
  bool _busy = false;
  bool _useServer = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _payload = widget.initialPayload;
  }

  @override
  void didUpdateWidget(covariant PairingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialPayload != null &&
        widget.initialPayload != oldWidget.initialPayload) {
      setState(() {
        _payload = widget.initialPayload;
        _error = null;
      });
    }
  }

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    final payload = await Navigator.of(
      context,
    ).push<PairingPayload?>(PairingScanScreen.route());
    if (!mounted || payload == null) return;
    setState(() {
      _payload = payload;
      _error = null;
    });
  }

  Future<void> _enterCode() async {
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
                  hintText: 'liftelligence://pair?nfc_id=...&token=...',
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
    setState(() {
      _payload = payload;
      _error = null;
    });
  }

  Future<void> _pair() async {
    if (_payload == null) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    final payload = _payload!;
    final first = _first.text.trim();
    final last = _last.text.trim();
    String? uid;
    var offline = !_useServer;

    if (_useServer) {
      final resp = await const NfcLoginServerClient().pair(
        token: payload.token,
        first: first,
        last: last,
      );
      if (!mounted) return;
      if (!resp.ok) {
        setState(() {
          _busy = false;
          _error = 'Pairing failed: ${resp.error ?? 'unknown_error'}';
        });
        return;
      }
      uid = resp.uid;
      offline = false;
    }

    if (!mounted) return;
    setState(() => _busy = false);

    final platform = Theme.of(context).platform;
    final isCupertino =
        platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;
    await Navigator.of(context).push<void>(
      isCupertino
          ? CupertinoPageRoute<void>(
              builder: (_) => PairingSuccessScreen(
                session: widget.session,
                payload: payload,
                pairedUid: uid,
                offline: offline,
              ),
            )
          : MaterialPageRoute<void>(
              builder: (_) => PairingSuccessScreen(
                session: widget.session,
                payload: payload,
                pairedUid: uid,
                offline: offline,
              ),
            ),
    );
  }

  /// Accept a payload pushed from outside (e.g. deep link arriving while
  /// already on this screen).
  void applyPayload(PairingPayload payload) {
    setState(() {
      _payload = payload;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final payload = _payload;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pair Bench'),
        actions: [
          TextButton(
            onPressed: _busy
                ? null
                : () async {
                    await widget.session.signOut();
                  },
            child: const Text('Sign out'),
          ),
        ],
      ),
      body: AppBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          children: [
            FrostedPanel(
              borderRadius: BorderRadius.circular(28),
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'First-time setup',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'When a bench sees an unknown NFC card, it shows a QR code. '
                    'Scan it with your phone camera to link the card to your account, '
                    'or use the scanner below.',
                    style: TextStyle(
                      color: scheme.onSurface.withValues(alpha: 0.72),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: _busy ? null : _scan,
                    icon: const Icon(Icons.qr_code_scanner_rounded),
                    label: Text(
                      payload == null ? 'Scan QR code' : 'Scan again',
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: _busy ? null : _enterCode,
                        icon: const Icon(Icons.keyboard_rounded),
                        label: const Text('Enter code'),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () {
                                setState(() {
                                  _payload = const PairingPayload(
                                    nfcId: 'DEMO_NFC_ID',
                                    token: 'DEMO_TOKEN',
                                  );
                                  _error = null;
                                });
                              },
                        child: const Text('Use demo'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Server: $kDefaultServerHost:$kDefaultServerPort',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Signed in as ${widget.session.email}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.68),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (payload == null) ...[
              const _EmptyState(
                title: 'Ready to scan',
                subtitle:
                    'Tap Scan QR code when the bench shows its pairing screen, '
                    'or scan the QR code with your phone camera.',
                icon: Icons.qr_code_rounded,
              ),
            ] else ...[
              FrostedPanel(
                borderRadius: BorderRadius.circular(24),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.nfc_rounded, color: scheme.primary),
                        const SizedBox(width: 10),
                        Text(
                          'NFC Card',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Card ID: ${payload.nfcId.toUpperCase()}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Token: ${payload.maskedToken()}',
                      style: TextStyle(
                        color: scheme.onSurface.withValues(alpha: 0.72),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _first,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [
                                    AutofillHints.givenName,
                                  ],
                                  decoration: const InputDecoration(
                                    labelText: 'First name',
                                  ),
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                      ? 'Required'
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _last,
                                  textInputAction: TextInputAction.done,
                                  autofillHints: const [
                                    AutofillHints.familyName,
                                  ],
                                  decoration: const InputDecoration(
                                    labelText: 'Last name',
                                  ),
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                      ? 'Required'
                                      : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          SwitchListTile.adaptive(
                            value: _useServer,
                            onChanged: _busy
                                ? null
                                : (v) => setState(() => _useServer = v),
                            title: const Text('Pair using server'),
                            subtitle: Text(
                              _useServer
                                  ? 'Sends the pairing token to the configured server.'
                                  : 'Saves pairing locally (demo mode).',
                              style: TextStyle(
                                color: scheme.onSurface.withValues(alpha: 0.72),
                              ),
                            ),
                            contentPadding: EdgeInsets.zero,
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              _error!,
                              style: TextStyle(
                                color: scheme.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: _busy ? null : _pair,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: _busy
                                  ? SizedBox(
                                      key: const ValueKey('busy'),
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: scheme.onPrimary,
                                      ),
                                    )
                                  : const Text(
                                      'Link NFC Card',
                                      key: ValueKey('idle'),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            FrostedPanel(
              borderRadius: BorderRadius.circular(22),
              padding: EdgeInsets.zero,
              child: ListTile(
                leading: Icon(
                  Icons.info_outline_rounded,
                  color: scheme.primary,
                ),
                title: const Text('What happens next?'),
                subtitle: const Text(
                  'After linking, tap your NFC card on the bench again. '
                  'The bench will recognize you and load your session.',
                  style: TextStyle(height: 1.35),
                ),
                isThreeLine: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FrostedPanel(
      borderRadius: BorderRadius.circular(24),
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 14),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: scheme.secondaryContainer.withValues(alpha: 0.68),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(icon, size: 34, color: scheme.onSecondaryContainer),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: scheme.onSurface.withValues(alpha: 0.72),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
