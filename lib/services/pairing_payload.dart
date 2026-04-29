/// A pairing code shown by the bench (`cpp-senior-design`) and typed in by
/// the user. The code is a short numeric string (currently 6 digits); the
/// server is responsible for validating it and resolving the underlying NFC
/// UID, so the phone never has to know which physical card is being paired.
class PairingPayload {
  const PairingPayload({required this.token});

  final String token;

  /// Strip any spaces / separators users may have copied between digits and
  /// return the resulting code if it looks valid (4-12 digits). Returns null
  /// for empty / non-numeric inputs.
  static PairingPayload? tryParse(String raw) {
    final stripped = raw.replaceAll(RegExp(r'\s+'), '').trim();
    if (stripped.isEmpty) return null;
    if (!RegExp(r'^[0-9]+$').hasMatch(stripped)) return null;
    if (stripped.length < 4 || stripped.length > 12) return null;
    return PairingPayload(token: stripped);
  }

  /// Display the code with a thin space splitting it in half (e.g. "123 456").
  String pretty() {
    if (token.length <= 3) return token;
    final half = token.length ~/ 2;
    return '${token.substring(0, half)} ${token.substring(half)}';
  }

  String maskedToken({int keep = 4}) {
    if (token.length <= keep) return token;
    return '${token.substring(0, keep)}…';
  }
}
