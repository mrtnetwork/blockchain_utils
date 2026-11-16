import 'dart:typed_data';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/api/api/api.dart';
import 'package:blockchain_utils/crypto/crypto/keys/sr25519/keys/keys.dart';
import 'package:blockchain_utils/crypto/crypto/keys/sr25519/keys/utils.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';
import 'package:blockchain_utils/utils/numbers/utils/bigint_utils.dart';
import 'package:blockchain_utils/crypto/crypto/group/ristretto/point/ristretto.dart';

enum ExpansionMode { uniform, ed25519 }

/// A Schnorrkel VRF pre-output (the raw VRF output point, pre-hashing).
class VRFPreOut with Equality {
  final BuBytes output;
  VRFPreOut(List<int> output)
    : output =
          output
              .exc(
                length: SchnorrkelKeyCost.vrfPreOutLength,
                operation: "VRFPreOut",
                reason: "Incorrect vrf length.",
              )
              .asImmutableBytes;
  BuBytes toBytes() => output.cloneBytes();

  @override
  List<dynamic> get variables => [output];
}

class VRFInOut with Equality {
  VRFInOut(List<int> input, List<int> output)
    : input =
          input
              .exc(
                length: SchnorrkelKeyCost.vrfPreOutLength,
                operation: "VRFInOut",
                reason: "Invalid VRFInOut input bytes length.",
              )
              .asImmutableBytes,
      output =
          output
              .exc(
                length: SchnorrkelKeyCost.vrfPreOutLength,
                operation: "VRFInOut",
                reason: "Invalid VRFInOut output bytes length.",
              )
              .asImmutableBytes;
  factory VRFInOut.fromBytes(List<int> bytes) {
    bytes.exc(
      length: SchnorrkelKeyCost.vrfPreOutLength * 2,
      operation: "VRFInOut.fromBytes",
      reason: "Invalid VRFInOut bytes length.",
    );
    return VRFInOut(
      bytes.sublist(0, SchnorrkelKeyCost.vrfPreOutLength),
      bytes.sublist(SchnorrkelKeyCost.vrfPreOutLength),
    );
  }
  final BuBytes input;
  final BuBytes output;

  RistrettoPoint get outputPoint => RistrettoPoint.fromBytes(output);
  RistrettoPoint get inputPoint => RistrettoPoint.fromBytes(input);

  BuBytes toBytes() => BuBytes([...input, ...output]);
  VRFPreOut toVRFPreOut() => VRFPreOut(output);
  @override
  List<dynamic> get variables => [input, output];
}

/// A Schnorrkel VRF proof (challenge `c` + response `s`).
class VRFProof with Equality {
  final BuBytes c;
  final BuBytes s;

  VRFProof(List<int> c, List<int> s)
    : c = c.asImmutableBytes,
      s = s.asImmutableBytes;

  factory VRFProof.fromBytes(List<int> bytes) {
    bytes.exc(
      length: SchnorrkelKeyCost.vrfProofLength,
      operation: "VRFProof.fromBytes",
      reason: "Invalid VRF bytes length.",
    );
    final c = SchnorrKeyUtils.toCanonical(bytes.sublist(0, 32));
    final s = SchnorrKeyUtils.toCanonical(bytes.sublist(32));
    if (c == null || s == null) {
      throw CoreErrors.invalidOperationArguments(
        "VRFProof",
        reason: "Invalid vrf proof bytes.",
      );
    }
    return VRFProof(c, s);
  }

  BigInt get cBigint => BigintUtils.fromBytes(c, byteOrder: Endian.little);
  BigInt get sBigint => BigintUtils.fromBytes(s, byteOrder: Endian.little);
  BuBytes toBytes() => BuBytes([...c, ...s]);

  @override
  List<dynamic> get variables => [c, s];
}

/// A 32-byte Schnorrkel "mini" secret key, expandable into a full
/// [SR25519PrivateKey] (key + nonce) via [toSecretKey].
class SchnorrkelMiniSecretKey with SecretState {
  SchnorrkelMiniSecretKey(List<int> bytes)
    : bytes = SecretBytes(
        bytes.exc(
          length: SchnorrkelKeyCost.miniSecretLength,
          operation: "SchnorrkelMiniSecretKey.fromBytes",
          reason: "Invalid secret key bytes length.",
        ),
      );
  final SecretBytes bytes;

  SecretBytes toBytes() => bytes.cloneBytes();

  SR25519PrivateKey toSecretKey([ExpansionMode mode = ExpansionMode.ed25519]) {
    final sk = bytes.useValue(
      (seed) => blockchainUtils.api.signing.sr25519.secretFromSeed(
        seed,
        uniform: mode == ExpansionMode.uniform,
      ),
    );
    return SR25519PrivateKey.fromBytes(sk);
  }

  @override
  void dispose() {
    bytes.zero();
  }
}
