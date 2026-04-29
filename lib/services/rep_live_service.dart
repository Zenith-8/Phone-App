import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../config/server_config.dart';

/// One forwarded rep event from the nfc-login-server.
@immutable
class LiveRepEvent {
  const LiveRepEvent({
    required this.uid,
    required this.machine,
    required this.repId,
    required this.repCount,
    required this.receivedAt,
  });

  final String uid;
  final String machine;
  final int repId;
  final int repCount;
  final DateTime receivedAt;
}

/// Maintains a long-lived TCP connection to the nfc-login-server, registers
/// for live rep_event push for the given UID, and immediately acknowledges
/// each rep so the server can compute the round-trip processing time.
///
/// Phone-side processing latency (`phone_lat_us`) is measured against
/// `Stopwatch` (monotonic) so it doesn't depend on wall-clock sync.
class RepLiveService extends ChangeNotifier {
  RepLiveService({
    String host = kDefaultServerHost,
    int port = kDefaultServerPort,
  })  : _host = host,
        _port = port;

  final String _host;
  final int _port;

  Socket? _socket;
  StreamSubscription<List<int>>? _sub;
  String? _uid;
  bool _running = false;
  bool _connected = false;
  Timer? _reconnectTimer;
  final BytesBuilder _rxBuf = BytesBuilder(copy: false);
  int? _frameLen;

  int _repCount = 0;
  LiveRepEvent? _lastEvent;

  /// Most recent live rep count (0 when no event has been received yet, or
  /// before [start] has been called).
  int get repCount => _repCount;

  /// Most recent rep event, if any.
  LiveRepEvent? get lastEvent => _lastEvent;

  /// True while a TCP connection is open and registered with the server.
  bool get isConnected => _connected;

  /// Begin listening for rep events for [uid]. Idempotent: calling again with
  /// the same uid does nothing; calling with a different uid restarts.
  Future<void> start(String uid) async {
    if (_running && _uid == uid) return;
    await stop();
    _uid = uid;
    _running = true;
    _repCount = 0;
    _lastEvent = null;
    notifyListeners();
    unawaited(_connectLoop());
  }

  /// Tear down the connection and stop reconnecting.
  Future<void> stop() async {
    _running = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    await _sub?.cancel();
    _sub = null;
    try {
      _socket?.destroy();
    } catch (_) {}
    _socket = null;
    _connected = false;
    _rxBuf.clear();
    _frameLen = null;
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(stop());
    super.dispose();
  }

  Future<void> _connectLoop() async {
    while (_running) {
      try {
        final socket = await Socket.connect(_host, _port,
            timeout: const Duration(seconds: 6));
        socket.setOption(SocketOption.tcpNoDelay, true);
        _socket = socket;

        // Register the phone for the active UID. The server will push
        // rep_event frames over the same connection.
        _sendJson(<String, Object?>{
          'type': 'register_phone',
          'uid': _uid,
        });

        _sub = socket.listen(
          _onData,
          onError: (Object _) => _scheduleReconnect(),
          onDone: _scheduleReconnect,
          cancelOnError: true,
        );
        _connected = true;
        notifyListeners();
        return;
      } on SocketException catch (_) {
        await Future<void>.delayed(const Duration(milliseconds: 750));
      } on TimeoutException catch (_) {
        await Future<void>.delayed(const Duration(milliseconds: 750));
      } catch (_) {
        await Future<void>.delayed(const Duration(milliseconds: 750));
      }
    }
  }

  void _scheduleReconnect() {
    _connected = false;
    notifyListeners();
    _sub?.cancel();
    _sub = null;
    try {
      _socket?.destroy();
    } catch (_) {}
    _socket = null;
    _rxBuf.clear();
    _frameLen = null;
    if (!_running) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(milliseconds: 750), () {
      if (_running) unawaited(_connectLoop());
    });
  }

  void _sendJson(Map<String, Object?> obj) {
    final socket = _socket;
    if (socket == null) return;
    final jsonBytes = utf8.encode(jsonEncode(obj));
    final header = ByteData(4)..setUint32(0, jsonBytes.length, Endian.big);
    socket.add(header.buffer.asUint8List());
    socket.add(jsonBytes);
  }

  void _onData(List<int> chunk) {
    _rxBuf.add(chunk);
    while (true) {
      if (_frameLen == null) {
        if (_rxBuf.length < 4) return;
        final all = _rxBuf.takeBytes();
        final len =
            ByteData.sublistView(Uint8List.fromList(all)).getUint32(0, Endian.big);
        if (len <= 0 || len > 1024 * 1024) {
          _scheduleReconnect();
          return;
        }
        _frameLen = len;
        if (all.length > 4) _rxBuf.add(all.sublist(4));
      }
      if (_rxBuf.length < _frameLen!) return;

      final all = _rxBuf.takeBytes();
      final framePayload = Uint8List.sublistView(
          Uint8List.fromList(all), 0, _frameLen!);
      // Capture the moment we have the complete frame in hand. This is what
      // the server will subtract from the observed round-trip to get the
      // wire latency, so it should be as close as possible to "received".
      final phoneRecvSw = Stopwatch()..start();
      final remaining = all.length > _frameLen!
          ? all.sublist(_frameLen!)
          : const <int>[];
      _frameLen = null;
      if (remaining.isNotEmpty) _rxBuf.add(remaining);

      _handleFrame(framePayload, phoneRecvSw);
    }
  }

  void _handleFrame(Uint8List frame, Stopwatch phoneRecvSw) {
    Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(frame));
    } catch (_) {
      return;
    }
    if (decoded is! Map) return;

    final type = decoded['type']?.toString();
    if (type == 'rep_event') {
      final uid = decoded['uid']?.toString() ?? '';
      final machine = decoded['machine']?.toString() ?? '';
      final repId = (decoded['rep_id'] as num?)?.toInt() ?? 0;
      final repCount = (decoded['rep_count'] as num?)?.toInt() ?? 0;

      final ev = LiveRepEvent(
        uid: uid,
        machine: machine,
        repId: repId,
        repCount: repCount,
        receivedAt: DateTime.now(),
      );

      _repCount = repCount;
      _lastEvent = ev;
      // Notify listeners FIRST so the UI updates the rep count, then send the
      // ack. Phone-side processing latency therefore captures the time spent
      // dispatching to the UI tree (best-effort; widgets repaint on the next
      // frame, which the user will perceive as "displayed").
      notifyListeners();

      final phoneLatUs = phoneRecvSw.elapsedMicroseconds;
      _sendJson(<String, Object?>{
        'type': 'rep_ack',
        'uid': uid,
        'rep_id': repId,
        'phone_lat_us': phoneLatUs,
      });
      return;
    }

    // register_phone_response and any other server messages: ignore (we don't
    // need to act on them; failures will surface as broken connections).
  }
}
