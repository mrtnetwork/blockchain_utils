import 'package:blockchain_utils/protocol/bip/bip/bip32/bip32_key_data.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/protocol/bip/bip/bip32/slip10/slip10_mldsa65_key_derivator.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/exception/exceptions.dart';

/// Master generator constants, mirrors `Bip32Slip10MstKeyGeneratorConst`.
class Slip10Mldsa65MstKeyGeneratorConst {
  /// Minimum seed length in bytes (128 bits, same as SLIP-10).
  static const int seedMinByteLen = 16;

  /// Maximum seed length in bytes (512 bits, per NEP-649 reference impl).
  static const int seedMaxByteLen = 64;

  /// HMAC key bytes for ML-DSA-65 (`"ML-DSA-65 seed"`, SLIP-10
  /// `<curve> + " seed"` convention, matching slips#1968).
  static const List<int> hmacKeyMldsa65Bytes = [
    77, // M
    76, // L
    45, // -
    68, // D
    83, // S
    65, // A
    45, // -
    54, // 6
    53, // 5
    32, // space
    115, // s
    101, // e
    101, // e
    100, // d
  ];
}

/// Master node generator for SLIP-10 ML-DSA-65, mirrors
/// `Bip32Slip10Ed25519MstKeyGenerator`.
///
/// No retry loop: any 32-byte sequence is a valid ML-DSA KeyGen seed, so
/// generation always succeeds (NEP-649 drops SLIP-10 step 4).
class Slip10Mldsa65MstKeyGenerator implements ISlip10Mldsa65MstKeyGenerator {
  const Slip10Mldsa65MstKeyGenerator();

  @override
  Slip10Mldsa65MasterKey generateFromSeed(List<int> seedBytes) {
    if (seedBytes.length < Slip10Mldsa65MstKeyGeneratorConst.seedMinByteLen ||
        seedBytes.length > Slip10Mldsa65MstKeyGeneratorConst.seedMaxByteLen) {
      throw CoreErrors.invalidOperationArguments(
        'generateFromSeed',
        name: 'seedBytes',
        reason: 'Invalid seed length.',
      );
    }
    final hmac = QuickCrypto.hmacSha512Hash(
      Slip10Mldsa65MstKeyGeneratorConst.hmacKeyMldsa65Bytes,
      seedBytes,
    );
    const hmacHalfLen = QuickCrypto.hmacSha512DigestSize ~/ 2;
    return Slip10Mldsa65MasterKey(
      key: hmac.sublist(0, hmacHalfLen),
      chainCode: Bip32ChainCode(hmac.sublist(hmacHalfLen)),
    );
  }
}
