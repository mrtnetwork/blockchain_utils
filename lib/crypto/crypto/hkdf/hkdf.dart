import 'package:blockchain_utils/blockchain_utils.dart';

/// A Dart implementation of the HKDF (HMAC-based Key Derivation Function) as defined in RFC 5869.
/// This class supports both the extract and expand phases.
class HKDF {
  /// Pseudorandom key (output of HKDF-Extract if enabled)
  final List<int> ork;

  /// Internal HMAC instance used for HKDF-Expand
  final HMAC _hmac;

  /// Desired length of output keying material (OKM)
  final int length;

  /// Optional context/application-specific information
  final List<int> info;
  HKDF._(
      {required List<int> ork,
      required HMAC hmac,
      List<int>? info,
      required this.length})
      : ork = ork.asImmutableBytes,
        info = (info ?? []).asImmutableBytes,
        _hmac = hmac;
  factory HKDF(
      {required List<int> ikm,
      required HashFunc hash,
      int length = 32,
      List<int>? salt,
      List<int>? info,
      bool hkdfExtract = true}) {
    final h = hash();
    int iteration = (length / h.getDigestLength).ceil();
    if (iteration > 255) {
      throw CryptoException('Cannot expand to more than 255 blocks');
    }
    if (hkdfExtract) {
      final ork = HMAC.hmac(hash, salt ?? List<int>.filled(32, 0), ikm);
      return HKDF._(
          ork: ork, info: info, hmac: HMAC(hash, ork), length: length);
    }
    return HKDF._(ork: ikm, hmac: HMAC(hash, ikm), info: info, length: length);
  }
  // HMAC-SHA256 helper
  List<int> _hash(List<int> data) {
    try {
      return _hmac.update(data).digest();
    } finally {
      _hmac.reset();
    }
  }

  /// Derives the final output keying material (OKM) using HKDF-Expand
  List<int> derive({List<int> info = const []}) {
    int iteration = (length / _hmac.getDigestLength).ceil();
    List<int> okm = [];
    List<int> previousBlock = [];
    for (int i = 1; i <= iteration; i++) {
      final data = <int>[];
      data.addAll(previousBlock);
      data.addAll([...this.info, ...info]);
      data.add(i);
      previousBlock = _hash(data);
      okm.addAll(previousBlock);
    }

    return okm.sublist(0, length);
  }
}
