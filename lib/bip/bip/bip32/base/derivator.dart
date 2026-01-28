import 'package:blockchain_utils/bip/bip/bip32/bip32_key_data.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_keys.dart';
import 'package:blockchain_utils/bip/bip/hd_key/types.dart';
import 'package:blockchain_utils/bip/ecc/curve/elliptic_curve_types.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';

/// Derived child key data
class Bip32ChildKey implements IChildKey {
  /// secret key
  final List<int> key;

  /// chain code
  final Bip32ChainCode chainCode;
  Bip32ChildKey({required List<int> key, required this.chainCode})
    : key = key.asImmutableBytes;
}

/// An abstract class that defines methods for BIP-32 key derivation.
abstract class IBip32ChildKeyDerivator
    implements
        IChildKeyDerivator<
          Bip32ChildKey,
          Bip32PrivateKey,
          Bip32PublicKey,
          Bip32KeyIndex
        > {
  /// Derives a child private key from the given private and public keys.
  @override
  Bip32ChildKey deriveFromSecret({
    required Bip32PrivateKey parent,
    required Bip32PublicKey ctx,
    required Bip32KeyIndex index,
    EllipticCurveTypes? type,
  });

  /// Derives a child public key from the given public key.
  @override
  Bip32ChildKey deriveFromPublic({
    required Bip32PublicKey parent,
    required Bip32KeyIndex index,
    EllipticCurveTypes? type,
  });
}

/// derived master key
class Bip32MasterKey implements IMasterKey {
  /// master key
  final List<int> key;

  /// chain code
  final Bip32ChainCode chainCode;
  Bip32MasterKey({required List<int> key, required this.chainCode})
    : key = key.asImmutableBytes;
}

/// An abstract class that defines a method for generating master keys from a seed.
///
/// This class outlines a method for generating BIP-32 master keys from seed bytes.
abstract class IBip32MstKeyGenerator
    implements IMasterKeyKeyGenerator<Bip32MasterKey> {
  /// Generates master keys from the given [seedBytes].
  @override
  Bip32MasterKey generateFromSeed(List<int> seedBytes);
}
