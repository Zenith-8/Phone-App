import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/server_config.dart';
import '../../services/app_session.dart';
import '../../services/nfc_login_server_client.dart';
import '../../services/pairing_payload.dart';
import '../../widgets/app_background.dart';
import '../../widgets/frosted_panel.dart';
import 'pairing_success_screen.dart';

/// First-time setup screen. The bench shows a 6-digit code on its display
/// when it sees an unknown NFC card; the user types that code in here along
/// with their name to register the card with their account.
class PairingScreen extends StatefulWidget {
  const PairingScreen({
    super.key,
    required this.session,
    this.initialPayload,
  });

  final AppSession session;

  /// Pre-filled payload (e.g. a previously cached partial pairing). The
  /// camera/QR / deep-link flow has been retired; this is left in place so
  /// callers that already pass a value don't need to be updated.
  final PairingPayload? initialPayload;

  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen> {
  final _codeCtrl = TextEditingController();
  final _firstCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initialPayload != null) {
      _codeCtrl.text = widget.initialPayload!.token;
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final parsed = PairingPayload.tryParse(_codeCtrl.text);
    if (parsed == null) {
      setState(() => _error = 'Code must be 4-12 digits.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    final first = _firstCtrl.text.trim();
    final last = _lastCtrl.text.trim();

    PairResponse? resp;
    try {
      resp = await const NfcLoginServerClient().pair(
        token: parsed.token,
        first: first,
        last: last,
      );
    } catch (e) {
      // The client itself catches the common failure modes, but defend
      // against any unexpected throw so the spinner can't get stuck.
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Network error: $e';
      });
      return;
    }
    if (!mounted) return;
    if (!resp.ok) {
      setState(() {
        _busy = false;
        _error = _friendlyError(resp.error);
      });
      return;
    }

    final uid = resp.uid;
    setState(() => _busy = false);

    final platform = Theme.of(context).platform;
    final isCupertino =
        platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;
    await Navigator.of(context).push<void>(
      isCupertino
          ? CupertinoPageRoute<void>(
              builder: (_) => PairingSuccessScreen(
                session: widget.session,
                payload: parsed,
                pairedUid: uid,
                offline: false,
              ),
            )
          : MaterialPageRoute<void>(
              builder: (_) => PairingSuccessScreen(
                session: widget.session,
                payload: parsed,
                pairedUid: uid,
                offline: false,
              ),
            ),
    );
  }

  String _friendlyError(String? raw) {
    switch (raw) {
      case null:
      case '':
        return 'Pairing failed. Please try again.';
      case 'token_expired':
        return 'That code has expired. Tap your card on the bench again to get a new one.';
      case 'token_unknown':
      case 'pair_failed':
        return 'Code not recognized. Double-check the digits on the bench display.';
      case 'timeout':
        return 'Server didn\'t respond in time. Check your network and retry.';
      case 'network_error':
        return 'Couldn\'t reach the server.';
      default:
        return 'Pairing failed: $raw';
    }
  }

  /// Accept a payload pushed from outside (e.g. session restore).
  void applyPayload(PairingPayload payload) {
    if (!mounted) return;
    setState(() {
      _codeCtrl.text = payload.token;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

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
        child: Form(
          key: _formKey,
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
                      'Tap your NFC card on the bench. The bench will show a '
                      '6-digit code. Type that code below along with your '
                      'name to link the card to your account.',
                      style: TextStyle(
                        color: scheme.onSurface.withValues(alpha: 0.72),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _codeCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(12),
                      ],
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 28,
                        letterSpacing: 6,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        labelText: 'Pairing code',
                        hintText: '------',
                        counterText: '',
                      ),
                      validator: (v) {
                        final s = (v ?? '').trim();
                        if (s.isEmpty) return 'Enter the code shown on the bench.';
                        if (PairingPayload.tryParse(s) == null) {
                          return 'Code must be digits only.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _firstCtrl,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.givenName],
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
                            controller: _lastCtrl,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.familyName],
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
                    if (_error != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        _error!,
                        style: TextStyle(
                          color: scheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _busy ? null : _submit,
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
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Server: $kDefaultServerHost:$kDefaultServerPort',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
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
              FrostedPanel(
                borderRadius: BorderRadius.circular(22),
                padding: EdgeInsets.zero,
                child: ListTile(
                  leading: Icon(Icons.info_outline_rounded,
                      color: scheme.primary),
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
      ),
    );
  }
}
