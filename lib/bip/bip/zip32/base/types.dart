import 'package:blockchain_utils/bip/bip/bip32/base/derivator.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_key_data.dart';
import 'package:blockchain_utils/bip/bip/bip44/base/bip44_base.dart';
import 'package:blockchain_utils/bip/bip/hd_key/types.dart';
import 'package:blockchain_utils/bip/bip/zip32/base/context.dart';
import 'package:blockchain_utils/bip/bip/zip32/zip32/types.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';

/// ZIP32 (Zcash Implementation of BIP32) abstractions for hierarchical
/// deterministic key management.
///
/// Derivator interface for ZIP32 child keys.
abstract class IZip32ChildKeyDerivator<
  PARENTKEY extends CryptoKeyBase?,
  DERIVATIONCONTXT extends CryptoKeyBase?
>
    implements
        IChildKeyDerivator<
          Bip32ChildKey,
          PARENTKEY,
          DERIVATIONCONTXT,
          Bip32KeyIndex
        > {}

/// Interface for ZIP32 master key generation.
///
/// Implementations generate a new master key from a seed.
abstract class IZip32MasterKeyGenerator
    extends IMasterKeyKeyGenerator<Bip32MasterKey> {}

abstract class IZip32CryptoKey<KEYDATA extends BaseCryptoKeyData>
    extends CryptoKeyBase<KEYDATA> {
  IZip32CryptoKey(super.keyData);
}

/// Represents an extended spending key in ZIP32.
///
/// Extended spend keys can be used to derive child spend keys and are
/// serialized in a form compatible with Zcash/BIP32.
///
/// [KEYDATA] is the internal storage for the key.
abstract class Zip32ExtendedSpendKey<KEYDATA extends BaseCryptoKeyData>
    extends IZip32CryptoKey<KEYDATA>
    with Equality {
  Zip32ExtendedSpendKey(super.keyData);

  List<int> spendKeyBytes();
}

/// Represents an extended full-view key in ZIP32.
///
/// Full-view keys allow for deriving incoming viewing keys (IVK) without
/// access to the private spend key.
///
/// [IVK] is the type of incoming viewing key associated with this full-view key.
abstract class Zip32ExtendedFullViewKey<
  IVK extends IncomingViewingKey,
  KEYDATA extends BaseCryptoKeyData
>
    extends IZip32CryptoKey<KEYDATA>
    with Equality {
  Zip32ExtendedFullViewKey(super.keyData);

  /// Returns the incoming viewing key (IVK) for this extended full-view key.
  ///
  /// [context] is required for cryptographic operations.
  /// [scope] allows selecting between internal/external derivation chains.
  IVK incomingViewingKey(
    ZCryptoContext context, {
    Bip44Changes scope = Bip44Changes.chainInt,
  });
}

/// Base class for ZIP32 hierarchical deterministic (HD) key managers.
///
/// Provides methods to derive child keys and manage the key hierarchy.
///
/// Type parameters:
/// - [SK]: Spend key type.
/// - [PK]: Full-view key type.
/// - [KEYINDEX]: Index type for key derivation.
/// - [KEYDRIVATOR]: Child key derivator implementation.
/// - [MASTERKEYGENERATOR]: Master key generator implementation.
/// - [KEY]: The HDKeyManager type for chaining derivations.
abstract class Zip32Base<
  SK extends Zip32ExtendedSpendKey,
  PK extends Zip32ExtendedFullViewKey,
  KEYINDEX extends HdKeyIndex,
  KEYDRIVATOR extends IChildKeyDerivator,
  MASTERKEYGENERATOR extends IMasterKeyKeyGenerator,
  KEY extends HDKeyManager<SK, PK, KEYINDEX, KEY>
>
    implements HDKeyManager<SK, PK, KEYINDEX, KEY> {
  const Zip32Base();
  Bip32Depth get depth;
  Bip32ChainCode get chainCode;
  Bip32FingerPrint get fingerPrint;

  /// Gets the key derivator for this key.
  KEYDRIVATOR get keyDerivator;

  /// Gets the master key generator for this key.
  MASTERKEYGENERATOR get masterKeyGenerator;

  /// Derives a child key at the given [index].
  KEY childKey(KEYINDEX index, ZCryptoContext context);

  /// Derives a key along a BIP32 path (e.g., "m/32'/0'/0'").
  KEY derivePath(String path, ZCryptoContext context);
}
