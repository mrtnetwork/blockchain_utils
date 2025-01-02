import 'package:blockchain_utils/bip/bip/bip32/base/ibip32_key_derivator.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_ex.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_key_data.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_keys.dart';
import 'package:blockchain_utils/bip/ecc/curve/elliptic_curve_types.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/point/edwards.dart';
import 'package:blockchain_utils/utils/utils.dart';

/// Define an abstract class 'Bip32KholawEd25519KeyDerivatorBase' that implements the 'IBip32KeyDerivator' interface.
/// This class provides a base for deriving Ed25519 keys with the Kholaw scheme.
abstract class Bip32KholawEd25519KeyDerivatorBase
    implements IBip32KeyDerivator {
  /// Abstract method to serialize a 'Bip32KeyIndex'.
  List<int> serializeIndex(Bip32KeyIndex index);

  /// Abstract method to derive the left part of a private key.
  List<int> newPrivateKeyLeftPart(
      List<int> zlBytes, List<int> klBytes, EllipticCurveTypes curve);

  /// Abstract method to derive the right part of a private key.
  List<int> newPrivateKeyRightPart(List<int> zrBytes, List<int> krBytes);

  /// Abstract method to derive a new public key point based on the provided data.
  EDPoint newPublicKeyPoint(Bip32PublicKey pubKey, List<int> zlBytes);
  // Derive a child private key from the given 'privKey' and 'pubKey' using the specified 'index'.
  // The 'type' parameter defines the elliptic curve type.
  // Returns a tuple containing the child private key bytes and the updated chain code.
  @override
  Tuple<List<int>, List<int>> ckdPriv(Bip32PrivateKey privKey,
      Bip32PublicKey pubKey, Bip32KeyIndex index, EllipticCurveTypes type) {
    /// Serialize the 'index' to bytes.
    final List<int> indexBytes = serializeIndex(index);

    /// Get the chain code bytes from the 'privKey'.
    List<int> chainCodeBytes = privKey.chainCode.toBytes();

    /// Extract raw private key bytes from 'privKey'.
    final List<int> privKeyBytes = privKey.raw;

    /// Extract compressed public key bytes from 'pubKey' and remove the compression flag.
    final List<int> pubKeyBytes = pubKey.compressed.sublist(1);

    List<int> zBytes;
    if (index.isHardened) {
      /// If the index is hardened, compute 'zBytes' using HMAC-SHA512 with specific data.
      zBytes = QuickCrypto.hmacSha512Hash(chainCodeBytes,
          List<int>.from([0x00, ...privKeyBytes, ...indexBytes]));

      /// Update the chain code using HMAC-SHA512 with specific data.
      chainCodeBytes = QuickCrypto.hmacSha512HashHalves(chainCodeBytes,
          List<int>.from([0x01, ...privKeyBytes, ...indexBytes])).item2;
    } else {
      /// If not hardened, compute 'zBytes' using HMAC-SHA512 with different data.
      zBytes = QuickCrypto.hmacSha512Hash(chainCodeBytes,
          List<int>.from([0x02, ...pubKeyBytes, ...indexBytes]));

      /// Update the chain code using HMAC-SHA512 with different data.
      chainCodeBytes = QuickCrypto.hmacSha512HashHalves(chainCodeBytes,
          List<int>.from([0x03, ...pubKeyBytes, ...indexBytes])).item2;
    }

    /// Compute left and right part of private key
    const hmacHalfLen = QuickCrypto.hmacSha512DigestSize ~/ 2;
    final List<int> pLBytes = newPrivateKeyLeftPart(
        zBytes.sublist(0, hmacHalfLen),
        privKeyBytes.sublist(0, hmacHalfLen),
        type);
    final List<int> pRBytes = newPrivateKeyRightPart(
        zBytes.sublist(hmacHalfLen), privKeyBytes.sublist(hmacHalfLen));

    /// Return the child private key bytes and the updated chain code.
    return Tuple(List<int>.from([...pLBytes, ...pRBytes]), chainCodeBytes);
  }

  /// Derive a child public key from the given 'pubKey' using the specified 'index'.
  /// The 'type' parameter defines the elliptic curve type.
  /// Returns a tuple containing the child public key bytes and the updated chain code.
  @override
  Tuple<List<int>, List<int>> ckdPub(
      Bip32PublicKey pubKey, Bip32KeyIndex index, EllipticCurveTypes type) {
    /// Serialize the 'index' to bytes.
    final List<int> indexBytes = serializeIndex(index);

    /// Get the chain code bytes from the 'pubKey'.
    List<int> chainCodeBytes = pubKey.chainCode.toBytes();

    /// Extract compressed public key bytes from 'pubKey' and remove the compression flag.
    final List<int> pubKeyBytes = pubKey.compressed.sublist(1);

    /// Compute 'Z' and update the chain code.
    final List<int> zBytes = QuickCrypto.hmacSha512Hash(
        chainCodeBytes, List<int>.from([0x02, ...pubKeyBytes, ...indexBytes]));
    chainCodeBytes = QuickCrypto.hmacSha512HashHalves(chainCodeBytes,
        List<int>.from([0x03, ...pubKeyBytes, ...indexBytes])).item2;

    /// Compute the new public key point based on 'pubKey' and 'zBytes'.
    const hmacHalfLen = QuickCrypto.hmacSha512DigestSize ~/ 2;
    final EDPoint newPubKeyPoint =
        newPublicKeyPoint(pubKey, zBytes.sublist(0, hmacHalfLen));

    /// Check if the new public key point is the identity point (0, 1).
    if (newPubKeyPoint.x == BigInt.zero && newPubKeyPoint.y == BigInt.one) {
      throw const Bip32KeyError(
          'Computed public child key is not valid, very unlucky index');
    }

    /// Return the child public key bytes and the updated chain code.
    return Tuple(newPubKeyPoint.toBytes(), chainCodeBytes);
  }

  /// check if support public derivation
  @override
  bool isPublicDerivationSupported() {
    return true;
  }
}
