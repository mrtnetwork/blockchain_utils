import 'package:blockchain_utils/utils/binary/src/utils.dart';

/// One participant's nonce pair + public commitments (RFC 9591
/// Section 5.1), shared by both engine suites (`P` is the point type,
/// `S` the scalar type: `Secp256k1Fr` on secp256k1, `Ed25519Fr` on
/// Ed25519).
class FrostEngineNonces<P, S> {
  final S hidingNonce;
  final S bindingNonce;
  final P hidingCommitment;
  final P bindingCommitment;

  const FrostEngineNonces({
    required this.hidingNonce,
    required this.bindingNonce,
    required this.hidingCommitment,
    required this.bindingCommitment,
  });

  FrostEngineCommitment<P> commitment(int identifier) {
    return FrostEngineCommitment(
      id: identifier,
      hidingCommitment: hidingCommitment,
      bindingCommitment: bindingCommitment,
    );
  }
}

/// One participant's entry in the commitment list (RFC 9591
/// Section 4.3), shared by both engine suites. `id` is a plain 1-based
/// `u32`-range participant counter (wire order + sorting need ordering,
/// which field types deliberately lack); scalar values use `S`.
class FrostEngineCommitment<P> {
  final int id;
  final P hidingCommitment;
  final P bindingCommitment;

  const FrostEngineCommitment({
    required this.id,
    required this.hidingCommitment,
    required this.bindingCommitment,
  });
}

/// Shamir share for one participant (RFC 9591 Appendix C.1), shared
/// by both engine suites (`S` is the suite scalar type).
class FrostEngineShare<S> {
  final S identifier;
  final S secretShare;

  const FrostEngineShare({required this.identifier, required this.secretShare});
}

/// Hex helpers for test vectors (hex-encoded values).
class FrostEngineHex {
  static List<int> decode(String hex) {
    return BytesUtils.fromHexString(hex.replaceAll(RegExp(r'\s+'), ''));
  }

  static String encode(List<int> bytes) {
    return BytesUtils.toHexString(bytes);
  }
}
