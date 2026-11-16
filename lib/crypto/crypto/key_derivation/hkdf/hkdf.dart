import 'package:blockchain_utils/crypto/crypto/hash/hash.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/binary/src/binary_operation.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// A Dart implementation of the HKDF (HMAC-based Key Derivation Function) as defined in RFC 5869.
/// This class supports both the extract and expand phases.
class HKDF {
  /// Pseudorandom key (output of HKDF-Extract if enabled)
  final List<int> _ork;

  /// Internal HMAC instance used for HKDF-Expand
  final BuSerializableHash _hmac;

  /// Desired length of output keying material (OKM)
  final int length;

  /// Optional context/application-specific information
  final List<int> _info;
  HKDF._({
    required List<int> ork,
    required BuSerializableHash hmac,
    List<int>? info,
    required this.length,
  }) : _ork = ork,
       _info = (info ?? []),
       _hmac = hmac;
  factory HKDF({
    required List<int> ikm,
    required CbHashFunc hash,
    int length = 32,
    List<int>? salt,
    List<int>? info,
    bool hkdfExtract = true,
  }) {
    final h = hash();
    if (length < 0) {
      throw CoreErrors.invalidOperationArguments(
        "HKDF",
        name: "length",
        reason: "Invalid length. Must be non-negative.",
      );
    }
    int iteration = (length / h.getDigestLength).ceil();
    if (iteration > 255) {
      throw CoreErrors.invalidOperationArguments(
        "HKDF",
        name: "length",
        reason: 'Cannot expand to more than 255 blocks.',
      );
    }
    if (hkdfExtract) {
      // BUG FIX: this used to default the salt to a hardcoded 32 zero
      // bytes. RFC 5869 §2.2 requires the default salt to be HashLen zero
      // bytes — HashLen is the *hash's own* digest length (e.g. 64 for
      // SHA-512), not always 32. Using the wrong default salt length
      // produces output that doesn't match the RFC or any other
      // RFC-5869-compliant HKDF implementation whenever no salt is given
      // and the hash's digest isn't 32 bytes.
      final ork = HMAC.hmac(
        hash,
        salt ?? List<int>.filled(h.getDigestLength, 0),
        ikm,
      );
      return HKDF._(
        ork: ork,
        info: info?.clone(),
        hmac: HMAC(hash, ork),
        length: length,
      );
    }
    return HKDF._(
      ork: ikm.clone(),
      hmac: HMAC(hash, ikm),
      info: info?.clone(),
      length: length,
    );
  }

  /// Strict RFC 5869 constructor: always Extract-then-Expand with a single
  /// `info` (constructor-only — there is no call-time `info` on
  /// [deriveRfc]). Omitted [salt] defaults to HashLen zeros per RFC §2.2.
  /// Kept separate from [HKDF.new] so the legacy dual-`info` surface stays
  /// untouched.
  factory HKDF.rfc({
    required List<int> ikm,
    required CbHashFunc hash,
    int length = 32,
    List<int>? salt,
    List<int>? info,
  }) {
    return HKDF(
      ikm: ikm,
      hash: hash,
      length: length,
      salt: salt,
      info: info,
      hkdfExtract: true,
    );
  }
  BuBytes _hash(List<int> data) {
    try {
      return _hmac.update(data).digest();
    } finally {
      _hmac.reset();
    }
  }

  /// Derives the final output keying material (OKM) using HKDF-Expand
  BuBytes derive({List<int> info = const []}) {
    return _expand([..._info, ...info]);
  }

  /// Strict RFC 5869 expand: constructor `info` only, no call-time `info`.
  /// Pairs with [HKDF.rfc]. Identical to `derive()` when no call-time info
  /// is passed.
  BuBytes deriveRfc() {
    return _expand(_info);
  }

  BuBytes _expand(List<int> info) {
    int iteration = (length / _hmac.getDigestLength).ceil();
    BuBytes okm = BuBytes.empty();
    List<int> previousBlock = [];
    for (int i = 1; i <= iteration; i++) {
      final data = <int>[];
      data.addAll(previousBlock);
      data.addAll(info);
      data.add(i);
      previousBlock = _hash(data);
      okm.addAll(previousBlock);
    }

    return okm.sublist(0, length);
  }

  void clean() {
    BinaryOps.zero(_info);
    BinaryOps.zero(_ork);
    _hmac.clean();
  }
}
