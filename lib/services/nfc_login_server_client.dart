import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../config/server_config.dart';
import '../models/workout.dart';

class PairResponse {
  const PairResponse({
    required this.ok,
    this.uid,
    this.error,
  });

  final bool ok;
  final String? uid;
  final String? error;
}

/// Minimal Dart client for `nfc-login-server` (TCP + length-prefixed JSON).
class NfcLoginServerClient {
  const NfcLoginServerClient();

  /// Sends a pair request to the server.
  ///
  /// [host] and [port] default to the values in `server_config.dart` so
  /// callers do not need to pass them unless overriding.
  Future<PairResponse> pair({
    String host = kDefaultServerHost,
    int port = kDefaultServerPort,
    required String token,
    required String first,
    required String last,
    Duration timeout = const Duration(seconds: 4),
  }) async {
    final socket = await Socket.connect(host, port, timeout: timeout);
    try {
      socket.setOption(SocketOption.tcpNoDelay, true);

      final req = <String, Object?>{
        'type': 'pair',
        'token': token,
        'first': first,
        'last': last,
      };
      final jsonBytes = utf8.encode(jsonEncode(req));
      final header = ByteData(4)..setUint32(0, jsonBytes.length, Endian.big);
      socket.add(header.buffer.asUint8List());
      socket.add(jsonBytes);
      await socket.flush();

      final respBytes = await _readFrame(socket, timeout: timeout);
      final decoded = jsonDecode(utf8.decode(respBytes));
      if (decoded is! Map) {
        return const PairResponse(ok: false, error: 'invalid_response');
      }

      final ok = decoded['ok'] == true;
      final uid = decoded['uid']?.toString();
      final error = decoded['error']?.toString();
      return PairResponse(ok: ok, uid: uid, error: error);
    } on TimeoutException {
      return const PairResponse(ok: false, error: 'timeout');
    } on SocketException catch (_) {
      return const PairResponse(ok: false, error: 'network_error');
    } on FormatException catch (_) {
      return const PairResponse(ok: false, error: 'invalid_json');
    } finally {
      socket.destroy();
    }
  }

  /// Fetches workout history for the given NFC UID from the server.
  Future<List<Workout>> getWorkouts({
    String host = kDefaultServerHost,
    int port = kDefaultServerPort,
    required String uid,
    Duration timeout = const Duration(seconds: 6),
  }) async {
    final socket = await Socket.connect(host, port, timeout: timeout);
    try {
      socket.setOption(SocketOption.tcpNoDelay, true);

      final req = <String, Object?>{
        'type': 'get_workouts',
        'uid': uid,
      };
      final jsonBytes = utf8.encode(jsonEncode(req));
      final header = ByteData(4)..setUint32(0, jsonBytes.length, Endian.big);
      socket.add(header.buffer.asUint8List());
      socket.add(jsonBytes);
      await socket.flush();

      final respBytes = await _readFrame(socket, timeout: timeout);
      final decoded = jsonDecode(utf8.decode(respBytes));
      if (decoded is! Map) return [];

      final ok = decoded['ok'] == true;
      if (!ok) return [];

      final rawList = decoded['workouts'];
      if (rawList is! List) return [];

      return rawList
          .whereType<Map<String, dynamic>>()
          .map(Workout.fromServerJson)
          .toList();
    } on TimeoutException {
      return [];
    } on SocketException catch (_) {
      return [];
    } on FormatException catch (_) {
      return [];
    } finally {
      socket.destroy();
    }
  }

  /// Reads one length-prefixed frame using a single stream subscription so
  /// that data arriving in a single TCP segment isn't lost between reads.
  static Future<Uint8List> _readFrame(Socket socket, {required Duration timeout}) async {
    final completer = Completer<Uint8List>();
    final buffer = BytesBuilder(copy: false);
    int? payloadLen;
    late final StreamSubscription<List<int>> sub;

    void tryComplete() {
      if (completer.isCompleted) return;

      // Phase 1: need at least 4 bytes for the length header.
      if (payloadLen == null) {
        if (buffer.length < 4) return;
        final all = buffer.takeBytes();
        payloadLen = ByteData.sublistView(Uint8List.fromList(all)).getUint32(0, Endian.big);
        if (payloadLen! <= 0 || payloadLen! > 1024 * 1024) {
          completer.completeError(const FormatException('invalid length'));
          sub.cancel();
          return;
        }
        // Put remaining bytes back.
        if (all.length > 4) {
          buffer.add(all.sublist(4));
        }
      }

      // Phase 2: need payloadLen bytes of actual data.
      if (buffer.length >= payloadLen!) {
        final all = buffer.takeBytes();
        completer.complete(Uint8List.sublistView(Uint8List.fromList(all), 0, payloadLen!));
        sub.cancel();
      }
    }

    sub = socket.listen(
      (chunk) {
        buffer.add(chunk);
        tryComplete();
      },
      onError: (Object err) {
        if (!completer.isCompleted) completer.completeError(err);
        sub.cancel();
      },
      onDone: () {
        if (!completer.isCompleted) {
          completer.completeError(const SocketException('connection closed'));
        }
        sub.cancel();
      },
      cancelOnError: true,
    );

    // Kick in case bytes were already buffered before we subscribed.
    tryComplete();

    return completer.future.timeout(timeout, onTimeout: () {
      sub.cancel();
      throw TimeoutException('read timeout');
    });
  }
}
