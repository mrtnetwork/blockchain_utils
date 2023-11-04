import 'package:blockchain_utils/bip/bip/bip32/base/bip32_base.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_ex.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_key_data.dart';
import 'package:blockchain_utils/bip/bip/bip32/khalow/bip32_kholaw_ed25519.dart';
import 'package:blockchain_utils/bip/bip/bip32/slip10/bip32_slip10_ed25519.dart';
import 'package:blockchain_utils/bip/bip/bip32/slip10/bip32_slip10_ed25519_blake2b.dart';
import 'package:blockchain_utils/bip/bip/bip32/slip10/bip32_slip10_nist256p1.dart';
import 'package:blockchain_utils/bip/bip/bip32/slip10/bip32_slip10_secp256k1.dart';
import 'package:blockchain_utils/bip/bip/bip44/base/bip44_base_ex.dart';
import 'package:blockchain_utils/bip/bip/conf/bip_coin_conf.dart';
import 'package:blockchain_utils/bip/cardano/bip32/cardano_icarus_bip32.dart';
import 'package:blockchain_utils/bip/ecc/curve/elliptic_curve_types.dart';

import 'bip44_keys.dart';

/// Enumeration of BIP-44 changes (external and internal).
enum Bip44Changes {
  /// External chain for receiving funds
  chainExt(0),

  /// Internal chain for change addresses
  chainInt(1);

  final int value;
  const Bip44Changes(this.value);
}

/// Enumeration of BIP-44 levels in hierarchical deterministic wallets.
enum Bip44Levels {
  /// Master level
  master(0),

  /// Purpose level
  purpose(1),

  /// Coin level
  coin(2),

  /// Account level
  account(3),

  /// Change level (external/internal)
  change(4),

  /// Address index level
  addressIndex(5);

  final int value;
  const Bip44Levels(this.value);

  /// Factory method to create a [Bip44Levels] enum value from an integer.
  factory Bip44Levels.fromInt(int value) {
    return values.firstWhere((e) => e.value == value);
  }
}

/// Abstract base class for BIP-44 hierarchical deterministic wallets.
abstract class Bip44Base {
  late final Bip32Base bip32;
  late final BipCoinConf coinConf;

  /// Constructor for creating a [Bip44Base] object from a seed and coin.
  Bip44Base.fromSeed(List<int> seedBytes, BipCoinConf coin) {
    Bip32Base bip;
    switch (coin.type) {
      case EllipticCurveTypes.secp256k1:
        bip = Bip32Slip10Secp256k1.fromSeed(seedBytes, coin.keyNetVer);
      case EllipticCurveTypes.ed25519:
        bip = Bip32Slip10Ed25519.fromSeed(seedBytes, coin.keyNetVer);
      case EllipticCurveTypes.ed25519Kholaw:
        if (coin.addrParams["is_icarus"] == true) {
          bip = CardanoIcarusBip32.fromSeed(seedBytes, coin.keyNetVer);
          break;
        }
        bip = Bip32KholawEd25519.fromSeed(seedBytes, coin.keyNetVer);
      case EllipticCurveTypes.ed25519Blake2b:
        bip = Bip32Slip10Ed25519Blake2b.fromSeed(seedBytes, coin.keyNetVer);
      case EllipticCurveTypes.nist256p1:
        bip = Bip32Slip10Nist256p1.fromSeed(seedBytes, coin.keyNetVer);
      default:
        throw ArgumentError("invaid type");
    }
    final validate = _validate(bip, coin);
    bip32 = validate.$1;
    coinConf = validate.$2;
  }

  /// Constructor for creating a [Bip44Base] object from a extended key and coin.
  Bip44Base.fromExtendedKey(String extendedKey, BipCoinConf coin) {
    Bip32Base bip;

    switch (coin.type) {
      case EllipticCurveTypes.secp256k1:
        bip = Bip32Slip10Secp256k1.fromExtendedKey(extendedKey, coin.keyNetVer);
      case EllipticCurveTypes.ed25519:
        bip = Bip32Slip10Ed25519.fromExtendedKey(extendedKey, coin.keyNetVer);
      case EllipticCurveTypes.ed25519Kholaw:
        if (coin.addrParams["is_icarus"] == true) {
          bip = CardanoIcarusBip32.fromExtendedKey(extendedKey, coin.keyNetVer);
          break;
        }
        bip = Bip32KholawEd25519.fromExtendedKey(extendedKey, coin.keyNetVer);
      case EllipticCurveTypes.ed25519Blake2b:
        bip = Bip32Slip10Ed25519Blake2b.fromExtendedKey(
            extendedKey, coin.keyNetVer);
      case EllipticCurveTypes.nist256p1:
        bip = Bip32Slip10Nist256p1.fromExtendedKey(extendedKey, coin.keyNetVer);
      default:
        throw ArgumentError("invaid type");
    }
    final validate = _validate(bip, coin);
    bip32 = validate.$1;
    coinConf = validate.$2;
  }

  /// Constructor for creating a [Bip44Base] object from a private key and coin.
  Bip44Base.fromPrivateKey(List<int> privateKeyBytes, BipCoinConf coin,
      {Bip32KeyData? keyData}) {
    Bip32Base bip;
    switch (coin.type) {
      case EllipticCurveTypes.secp256k1:
        bip = Bip32Slip10Secp256k1.fromPrivateKey(privateKeyBytes,
            keyData: keyData, keyNetVer: coin.keyNetVer);
      case EllipticCurveTypes.ed25519:
        bip = Bip32Slip10Ed25519.fromPrivateKey(privateKeyBytes,
            keyData: keyData, keyNetVer: coin.keyNetVer);
      case EllipticCurveTypes.ed25519Kholaw:
        if (coin.addrParams["is_icarus"] == true) {
          bip = CardanoIcarusBip32.fromPrivateKey(privateKeyBytes,
              keyData: keyData, keyNetVer: coin.keyNetVer);
          break;
        }
        bip = Bip32KholawEd25519.fromPrivateKey(privateKeyBytes,
            keyData: keyData, keyNetVer: coin.keyNetVer);
      case EllipticCurveTypes.ed25519Blake2b:
        bip = Bip32Slip10Ed25519Blake2b.fromPrivateKey(privateKeyBytes,
            keyData: keyData, keyNetVer: coin.keyNetVer);
      case EllipticCurveTypes.nist256p1:
        bip = Bip32Slip10Nist256p1.fromPrivateKey(privateKeyBytes,
            keyData: keyData, keyNetVer: coin.keyNetVer);
      default:
        throw ArgumentError("invaid type");
    }
    final validate = _validate(bip, coin);
    bip32 = validate.$1;
    coinConf = validate.$2;
  }

  /// Constructor for creating a [Bip44Base] object from a public key and coin.
  Bip44Base.fromPublicKey(List<int> pubkeyBytes, BipCoinConf coin,
      {Bip32KeyData? keyData}) {
    Bip32Base bip;
    switch (coin.type) {
      case EllipticCurveTypes.secp256k1:
        bip = Bip32Slip10Secp256k1.fromPublicKey(pubkeyBytes,
            keyData: keyData, keyNetVer: coin.keyNetVer);
      case EllipticCurveTypes.ed25519:
        bip = Bip32Slip10Ed25519.fromPublicKey(pubkeyBytes,
            keyData: keyData, keyNetVer: coin.keyNetVer);
      case EllipticCurveTypes.ed25519Blake2b:
        bip = Bip32Slip10Ed25519Blake2b.fromPublicKey(pubkeyBytes,
            keyData: keyData, keyNetVer: coin.keyNetVer);
      case EllipticCurveTypes.ed25519Kholaw:
        if (coin.addrParams["is_icarus"] == true) {
          bip = CardanoIcarusBip32.fromPublicKey(pubkeyBytes,
              keyData: keyData, keyNetVer: coin.keyNetVer);
          break;
        }
        bip = Bip32KholawEd25519.fromPublicKey(pubkeyBytes,
            keyData: keyData, keyNetVer: coin.keyNetVer);
      case EllipticCurveTypes.nist256p1:
        bip = Bip32Slip10Nist256p1.fromPublicKey(pubkeyBytes,
            keyData: keyData, keyNetVer: coin.keyNetVer);
      default:
        throw ArgumentError("invaid type");
    }
    final validate = _validate(bip, coin);
    bip32 = validate.$1;
    coinConf = validate.$2;
  }

  /// Internal validation method for checking the depth of the BIP object.
  static (Bip32Base, BipCoinConf) _validate(
      Bip32Base bip32Obj, BipCoinConf coinConf) {
    int depth = bip32Obj.depth.depth;

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

    return (bip32Obj, coinConf);
  }

  /// Constructor for creating a [Bip44Base] object from a bip32 [Bip32Base] and coin [BipCoinConf].
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
