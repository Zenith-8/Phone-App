import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

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

  Future<PairResponse> pair({
    required String host,
    required int port,
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

  static Future<Uint8List> _readFrame(Socket socket, {required Duration timeout}) async {
    final header = await _readExact(socket, 4, timeout: timeout);
    final len = ByteData.sublistView(header).getUint32(0, Endian.big);
    if (len == 0 || len > 1024 * 1024) {
      throw const FormatException('invalid length');
    }
    return _readExact(socket, len, timeout: timeout);
  }

  static Future<Uint8List> _readExact(Socket socket, int length, {required Duration timeout}) async {
    final completer = Completer<Uint8List>();
    final buffer = BytesBuilder(copy: false);
    late final StreamSubscription<List<int>> sub;

    void finish() {
      if (completer.isCompleted) return;
      completer.complete(buffer.takeBytes());
      sub.cancel();
    }

    void fail(Object err) {
      if (completer.isCompleted) return;
      completer.completeError(err);
      sub.cancel();
    }

    sub = socket.listen(
      (chunk) {
        buffer.add(chunk);
        if (buffer.length >= length) {
          final bytes = buffer.takeBytes();
          final out = Uint8List.sublistView(bytes, 0, length);
          if (!completer.isCompleted) {
            completer.complete(out);
          }
          sub.cancel();
        }
      },
      onError: fail,
      onDone: finish,
      cancelOnError: true,
    );

    return completer.future.timeout(timeout, onTimeout: () {
      sub.cancel();
      throw TimeoutException('read timeout');
    });
  }
}
