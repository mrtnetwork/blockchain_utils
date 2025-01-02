import 'package:blockchain_utils/bip/bip/bip32/base/bip32_base.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_ex.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_key_data.dart';
import 'package:blockchain_utils/bip/bip/bip32/khalow/bip32_kholaw_ed25519.dart';
import 'package:blockchain_utils/bip/bip/bip32/slip10/bip32_slip10_ed25519.dart';
import 'package:blockchain_utils/bip/bip/bip32/slip10/bip32_slip10_ed25519_blake2b.dart';
import 'package:blockchain_utils/bip/bip/bip32/slip10/bip32_slip10_nist256p1.dart';
import 'package:blockchain_utils/bip/bip/bip32/slip10/bip32_slip10_secp256k1.dart';
import 'package:blockchain_utils/bip/bip/bip44/base/bip44_base_ex.dart';
import 'package:blockchain_utils/bip/bip/conf/config/bip_coin_conf.dart';
import 'package:blockchain_utils/bip/cardano/bip32/cardano_icarus_bip32.dart';
import 'package:blockchain_utils/bip/ecc/curve/elliptic_curve_types.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/utils/utils.dart';

import 'bip44_keys.dart';

/// Enumeration of BIP-44 changes (external and internal).
class Bip44Changes {
  // Named constants representing each change

  /// External chain for receiving funds
  static const chainExt = Bip44Changes._(0);

  /// Internal chain for change addresses
  static const chainInt = Bip44Changes._(1);

  // The value associated with each instance

  /// Constructor to associate a value with each instance
  final int value;
  const Bip44Changes._(this.value);
}

/// Enumeration of BIP-44 levels in hierarchical deterministic wallets.
class Bip44Levels {
  // Named constants representing each level

  /// Master level
  static const master = Bip44Levels._(0, "Master");

  /// Purpose level
  static const purpose = Bip44Levels._(1, "Purpose");

  /// Coin level
  static const coin = Bip44Levels._(2, "Coin");

  /// Account level
  static const account = Bip44Levels._(3, "Account");

  /// Change level (external/internal)
  static const change = Bip44Levels._(4, "Change");

  /// Address index level
  static const addressIndex = Bip44Levels._(5, "Address");

  // The value associated with each instance

  /// Constructor to associate a value with each instance
  final int value;
  final String name;
  const Bip44Levels._(this.value, this.name);

  /// Factory method to create a [Bip44Levels] instance from an integer.

  /// Create a [Bip44Levels] instance from an integer value.
  factory Bip44Levels.fromInt(int value) {
    return values.firstWhere((e) => e.value == value);
  }

  // List of all instances of Bip44Levels
  static const List<Bip44Levels> values = [
    master,
    purpose,
    coin,
    account,
    change,
    addressIndex,
  ];
  @override
  String toString() {
    return "Bip44Levels.$name";
  }
}

/// Abstract base class for BIP-44 hierarchical deterministic wallets.
abstract class Bip44Base {
  late final Bip32Base bip32;
  late final BipCoinConfig coinConf;

  /// Constructor for creating a [Bip44Base] object from a seed and coin.
  Bip44Base.fromSeed(List<int> seedBytes, BipCoinConfig coin) {
    Bip32Base bip;
    switch (coin.type) {
      case EllipticCurveTypes.secp256k1:
        bip = Bip32Slip10Secp256k1.fromSeed(seedBytes, coin.keyNetVer);
        break;
      case EllipticCurveTypes.ed25519:
        bip = Bip32Slip10Ed25519.fromSeed(seedBytes, coin.keyNetVer);
        break;
      case EllipticCurveTypes.ed25519Kholaw:
        if (coin.addrParams["is_icarus"] == true) {
          bip = CardanoIcarusBip32.fromSeed(seedBytes, coin.keyNetVer);
          break;
        }
        bip = Bip32KholawEd25519.fromSeed(seedBytes, coin.keyNetVer);
        break;
      case EllipticCurveTypes.ed25519Blake2b:
        bip = Bip32Slip10Ed25519Blake2b.fromSeed(seedBytes, coin.keyNetVer);
        break;
      case EllipticCurveTypes.nist256p1:
        bip = Bip32Slip10Nist256p1.fromSeed(seedBytes, coin.keyNetVer);
        break;
      default:
        throw ArgumentException("Bip44 does not supported ${coin.type}");
    }
    final validate = _validate(bip, coin);
    bip32 = validate.item1;
    coinConf = validate.item2;
  }

  /// Constructor for creating a [Bip44Base] object from a extended key and coin.
  Bip44Base.fromExtendedKey(String extendedKey, BipCoinConfig coin) {
    Bip32Base bip;

    switch (coin.type) {
      case EllipticCurveTypes.secp256k1:
        bip = Bip32Slip10Secp256k1.fromExtendedKey(extendedKey, coin.keyNetVer);
        break;
      case EllipticCurveTypes.ed25519:
        bip = Bip32Slip10Ed25519.fromExtendedKey(extendedKey, coin.keyNetVer);
        break;
      case EllipticCurveTypes.ed25519Kholaw:
        if (coin.addrParams["is_icarus"] == true) {
          bip = CardanoIcarusBip32.fromExtendedKey(extendedKey, coin.keyNetVer);

          break;
        }
        bip = Bip32KholawEd25519.fromExtendedKey(extendedKey, coin.keyNetVer);
        break;
      case EllipticCurveTypes.ed25519Blake2b:
        bip = Bip32Slip10Ed25519Blake2b.fromExtendedKey(
            extendedKey, coin.keyNetVer);
        break;
      case EllipticCurveTypes.nist256p1:
        bip = Bip32Slip10Nist256p1.fromExtendedKey(extendedKey, coin.keyNetVer);
        break;
      default:
        throw const ArgumentException("invaid type");
    }
    final validate = _validate(bip, coin);
    bip32 = validate.item1;
    coinConf = validate.item2;
  }

  /// Constructor for creating a [Bip44Base] object from a private key and coin.
  Bip44Base.fromPrivateKey(List<int> privateKeyBytes, BipCoinConfig coin,
      {Bip32KeyData? keyData}) {
    Bip32Base bip;
    switch (coin.type) {
      case EllipticCurveTypes.secp256k1:
        bip = Bip32Slip10Secp256k1.fromPrivateKey(privateKeyBytes,
            keyData: keyData, keyNetVer: coin.keyNetVer);
        break;
      case EllipticCurveTypes.ed25519:
        bip = Bip32Slip10Ed25519.fromPrivateKey(privateKeyBytes,
            keyData: keyData, keyNetVer: coin.keyNetVer);
        break;
      case EllipticCurveTypes.ed25519Kholaw:
        if (coin.addrParams["is_icarus"] == true) {
          bip = CardanoIcarusBip32.fromPrivateKey(privateKeyBytes,
              keyData: keyData, keyNetVer: coin.keyNetVer);
          break;
        }
        bip = Bip32KholawEd25519.fromPrivateKey(privateKeyBytes,
            keyData: keyData, keyNetVer: coin.keyNetVer);
        break;
      case EllipticCurveTypes.ed25519Blake2b:
        bip = Bip32Slip10Ed25519Blake2b.fromPrivateKey(privateKeyBytes,
            keyData: keyData, keyNetVer: coin.keyNetVer);
        break;
      case EllipticCurveTypes.nist256p1:
        bip = Bip32Slip10Nist256p1.fromPrivateKey(privateKeyBytes,
            keyData: keyData, keyNetVer: coin.keyNetVer);
        break;
      default:
        throw const ArgumentException("invaid type");
    }
    final validate = _validate(bip, coin);
    bip32 = validate.item1;
    coinConf = validate.item2;
  }

  /// Constructor for creating a [Bip44Base] object from a public key and coin.
  Bip44Base.fromPublicKey(List<int> pubkeyBytes, BipCoinConfig coin,
      {Bip32KeyData? keyData}) {
    Bip32Base bip;
    switch (coin.type) {
      case EllipticCurveTypes.secp256k1:
        bip = Bip32Slip10Secp256k1.fromPublicKey(pubkeyBytes,
            keyData: keyData, keyNetVer: coin.keyNetVer);
        break;
      case EllipticCurveTypes.ed25519:
        bip = Bip32Slip10Ed25519.fromPublicKey(pubkeyBytes,
            keyData: keyData, keyNetVer: coin.keyNetVer);
        break;
      case EllipticCurveTypes.ed25519Blake2b:
        bip = Bip32Slip10Ed25519Blake2b.fromPublicKey(pubkeyBytes,
            keyData: keyData, keyNetVer: coin.keyNetVer);
        break;
      case EllipticCurveTypes.ed25519Kholaw:
        if (coin.addrParams["is_icarus"] == true) {
          bip = CardanoIcarusBip32.fromPublicKey(pubkeyBytes,
              keyData: keyData, keyNetVer: coin.keyNetVer);
          break;
        }
        bip = Bip32KholawEd25519.fromPublicKey(pubkeyBytes,
            keyData: keyData, keyNetVer: coin.keyNetVer);
        break;
      case EllipticCurveTypes.nist256p1:
        bip = Bip32Slip10Nist256p1.fromPublicKey(pubkeyBytes,
            keyData: keyData, keyNetVer: coin.keyNetVer);
        break;
      default:
        throw const ArgumentException("invaid type");
    }
    final validate = _validate(bip, coin);
    bip32 = validate.item1;
    coinConf = validate.item2;
  }

  /// Internal validation method for checking the depth of the BIP object.
  static Tuple<Bip32Base, BipCoinConfig> _validate(
      Bip32Base bip32Obj, BipCoinConfig coinConf) {
    final int depth = bip32Obj.depth.depth;

    if (bip32Obj.isPublicOnly) {
      if (depth < Bip44Levels.account.value ||
          depth > Bip44Levels.addressIndex.value) {
        throw Bip44DepthError(
            "Depth of the public-only Bip object ($depth) is below account level or beyond address index level");
      }
    } else {
      if (depth < 0 || depth > Bip44Levels.addressIndex.value) {
        throw Bip44DepthError(
            "Depth of the Bip object ($depth) is invalid or beyond address index level");
      }
    }

    return Tuple(bip32Obj, coinConf);
  }

  /// Constructor for creating a [Bip44Base] object from a bip32 [Bip32Base] and coin [BipCoinConfig].
  Bip44Base(this.bip32, this.coinConf) {
    _validate(bip32, coinConf);
  }

  /// [Bip44PublicKey] public key
  Bip44PublicKey get publicKey {
    return Bip44PublicKey(bip32.publicKey, coinConf);
  }

  /// [Bip44PrivateKey] privatekey
  Bip44PrivateKey get privateKey {
    if (bip32.isPublicOnly) {
      throw const Bip32KeyError("The Bip32 object is public-only");
    }
    return Bip44PrivateKey(bip32.privateKey, coinConf);
  }

  Bip32Base get bip32Object => bip32;

  /// check if is public only
  bool get isPublicOnly => bip32.isPublicOnly;

  /// [Bip44Levels] level
  Bip44Levels get level {
    return Bip44Levels.fromInt(bip32.depth.depth);
  }

  /// check level with current bip-44 level
  bool isLevel(Bip44Levels level) {
    return bip32.depth.depth == level.value;
  }

  /// derive default path
  Bip44Base get deriveDefaultPath;

  /// derive purpose
  Bip44Base get purpose;

  /// derive coin
  Bip44Base get coin;

  /// derive account with index
  Bip44Base account(int accIndex);

  /// derive change with change type [Bip44Changes] internal or external
  Bip44Base change(Bip44Changes changeType);

  /// derive address with index
  Bip44Base addressIndex(int addressIndex);

  /// spec name
  String get specName;
}
