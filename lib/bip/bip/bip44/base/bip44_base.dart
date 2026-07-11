import 'package:blockchain_utils/bip/bip/bip32/base/bip32_base.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_ex.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_key_data.dart';
import 'package:blockchain_utils/bip/bip/bip32/khalow/bip32_kholaw_ed25519.dart';
import 'package:blockchain_utils/bip/bip/bip32/slip10/bip32_slip10_ed25519.dart';
import 'package:blockchain_utils/bip/bip/bip32/slip10/bip32_slip10_ed25519_blake2b.dart';
import 'package:blockchain_utils/bip/bip/bip32/slip10/bip32_slip10_nist256p1.dart';
import 'package:blockchain_utils/bip/bip/bip32/slip10/bip32_slip10_nist256p1_hybrid.dart';
import 'package:blockchain_utils/bip/bip/bip32/slip10/bip32_slip10_secp256k1.dart';
import 'package:blockchain_utils/bip/bip/bip44/base/bip44_base_ex.dart';
import 'package:blockchain_utils/bip/bip/conf/config/bip_coin_conf.dart';
import 'package:blockchain_utils/bip/bip/conf/core/coin_conf.dart';
import 'package:blockchain_utils/bip/cardano/bip32/cardano_icarus_bip32.dart';
import 'package:blockchain_utils/bip/ecc/curve/elliptic_curve_types.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'bip44_keys.dart';

/// Enumeration of BIP-44 changes (external and internal).
enum Bip44Changes {
  /// External chain for receiving funds
  chainExt(0, "External"),

  /// Internal chain for change addresses
  chainInt(1, "Internal");

  /// Constructor to associate a value with each instance
  final int value;
  final String name;
  const Bip44Changes(this.value, this.name);
  static Bip44Changes fromValue(int? value) {
    return values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw ItemNotFoundException(name: "Bip44Changes"),
    );
  }
}

/// Enumeration of BIP-44 levels in hierarchical deterministic wallets.
enum Bip44Levels {
  // Named constants representing each level

  /// Master level
  master(0, "Master"),

  /// Purpose level
  purpose(1, "Purpose"),

  /// Coin level
  coin(2, "Coin"),

  /// Account level
  account(3, "Account"),

  /// Change level (external/internal)
  change(4, "Change"),

  /// Address index level
  addressIndex(5, "Address");

  /// Constructor to associate a value with each instance
  final int value;
  final String name;
  const Bip44Levels(this.value, this.name);

  /// Factory method to create a [Bip44Levels] instance from an integer.

  /// Create a [Bip44Levels] instance from an integer value.
  factory Bip44Levels.fromInt(int value) {
    return values.firstWhere(
      (e) => e.value == value,
      orElse:
          () =>
              throw ArgumentException.invalidOperationArguments(
                "Bip44Levels",
                reason: "Invalid BIP-44 depth.",
              ),
    );
  }

  @override
  String toString() {
    return "Bip44Levels.$name";
  }
}

/// Abstract base class for BIP-44 hierarchical deterministic wallets.
abstract class Bip44Base<BIP44 extends Bip44Base<BIP44>> {
  late final Bip32Base<dynamic> bip32;
  late final BaseBipCoinConfig coinConf;

  /// Constructor for creating a [Bip44Base] object from a seed and coin.
  Bip44Base.fromSeed(List<int> seedBytes, BaseBipCoinConfig coin) {
    Bip32Base bip;
    switch (coin.type) {
      case EllipticCurveTypes.secp256k1:
        bip = Bip32Slip10Secp256k1.fromSeed(seedBytes, coin.keyNetVer);
        break;
      case EllipticCurveTypes.ed25519:
        bip = Bip32Slip10Ed25519.fromSeed(seedBytes, coin.keyNetVer);
        break;
      case EllipticCurveTypes.ed25519Kholaw:
        if (coin.defaultHdKeyDerivator == DefaultHdKeyDerivator.icarus) {
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
      case EllipticCurveTypes.nist256p1Hybrid:
        bip = Bip32Slip10Nist256p1Hybrid.fromSeed(seedBytes, coin.keyNetVer);
        break;
      default:
        throw ArgumentException.invalidOperationArguments(
          "Bip44",
          name: "coin",
          reason: "Unsupported coin key algorithm",
          details: {"algorithm": coin.type.name},
        );
    }
    final validate = _validate(bip, coin);
    bip32 = validate.$1;
    coinConf = validate.$2;
  }

  /// Constructor for creating a [Bip44Base] object from a extended key and coin.
  Bip44Base.fromExtendedKey(String extendedKey, BaseBipCoinConfig coin) {
    Bip32Base bip;

    switch (coin.type) {
      case EllipticCurveTypes.secp256k1:
        bip = Bip32Slip10Secp256k1.fromExtendedKey(extendedKey, coin.keyNetVer);
        break;
      case EllipticCurveTypes.ed25519:
        bip = Bip32Slip10Ed25519.fromExtendedKey(extendedKey, coin.keyNetVer);
        break;
      case EllipticCurveTypes.ed25519Kholaw:
        if (coin.defaultHdKeyDerivator == DefaultHdKeyDerivator.icarus) {
          bip = CardanoIcarusBip32.fromExtendedKey(extendedKey, coin.keyNetVer);

          break;
        }
        bip = Bip32KholawEd25519.fromExtendedKey(extendedKey, coin.keyNetVer);
        break;
      case EllipticCurveTypes.ed25519Blake2b:
        bip = Bip32Slip10Ed25519Blake2b.fromExtendedKey(
          extendedKey,
          coin.keyNetVer,
        );
        break;
      case EllipticCurveTypes.nist256p1:
        bip = Bip32Slip10Nist256p1.fromExtendedKey(extendedKey, coin.keyNetVer);
        break;
      case EllipticCurveTypes.nist256p1Hybrid:
        bip = Bip32Slip10Nist256p1Hybrid.fromExtendedKey(
          extendedKey,
          coin.keyNetVer,
        );
        break;
      default:
        throw ArgumentException.invalidOperationArguments(
          "Bip44",
          name: "coin",
          reason: "Unsupported coin key algorithm",
          details: {"algorithm": coin.type.name},
        );
    }
    final validate = _validate(bip, coin);
    bip32 = validate.$1;
    coinConf = validate.$2;
  }

  /// Constructor for creating a [Bip44Base] object from a private key and coin.
  Bip44Base.fromPrivateKey(
    List<int> privateKeyBytes,
    BaseBipCoinConfig coin, {
    Bip32KeyData? keyData,
  }) {
    Bip32Base bip;
    switch (coin.type) {
      case EllipticCurveTypes.secp256k1:
        bip = Bip32Slip10Secp256k1.fromPrivateKey(
          privateKeyBytes,
          keyData: keyData,
          keyNetVer: coin.keyNetVer,
        );
        break;
      case EllipticCurveTypes.ed25519:
        bip = Bip32Slip10Ed25519.fromPrivateKey(
          privateKeyBytes,
          keyData: keyData,
          keyNetVer: coin.keyNetVer,
        );
        break;
      case EllipticCurveTypes.ed25519Kholaw:
        if (coin.defaultHdKeyDerivator == DefaultHdKeyDerivator.icarus) {
          bip = CardanoIcarusBip32.fromPrivateKey(
            privateKeyBytes,
            keyData: keyData,
            keyNetVer: coin.keyNetVer,
          );
          break;
        }
        bip = Bip32KholawEd25519.fromPrivateKey(
          privateKeyBytes,
          keyData: keyData,
          keyNetVer: coin.keyNetVer,
        );
        break;
      case EllipticCurveTypes.ed25519Blake2b:
        bip = Bip32Slip10Ed25519Blake2b.fromPrivateKey(
          privateKeyBytes,
          keyData: keyData,
          keyNetVer: coin.keyNetVer,
        );
        break;
      case EllipticCurveTypes.nist256p1:
        bip = Bip32Slip10Nist256p1.fromPrivateKey(
          privateKeyBytes,
          keyData: keyData,
          keyNetVer: coin.keyNetVer,
        );
        break;
      default:
        throw ArgumentException.invalidOperationArguments(
          "Bip44",
          name: "coin",
          reason: "Unsupported coin key algorithm",
          details: {"algorithm": coin.type.name},
        );
    }
    final validate = _validate(bip, coin);
    bip32 = validate.$1;
    coinConf = validate.$2;
  }

  /// Constructor for creating a [Bip44Base] object from a public key and coin.
  Bip44Base.fromPublicKey(
    List<int> pubkeyBytes,
    BaseBipCoinConfig coin, {
    Bip32KeyData? keyData,
  }) {
    Bip32Base bip;
    switch (coin.type) {
      case EllipticCurveTypes.secp256k1:
        bip = Bip32Slip10Secp256k1.fromPublicKey(
          pubkeyBytes,
          keyData: keyData,
          keyNetVer: coin.keyNetVer,
        );
        break;
      case EllipticCurveTypes.ed25519:
        bip = Bip32Slip10Ed25519.fromPublicKey(
          pubkeyBytes,
          keyData: keyData,
          keyNetVer: coin.keyNetVer,
        );
        break;
      case EllipticCurveTypes.ed25519Blake2b:
        bip = Bip32Slip10Ed25519Blake2b.fromPublicKey(
          pubkeyBytes,
          keyData: keyData,
          keyNetVer: coin.keyNetVer,
        );
        break;
      case EllipticCurveTypes.ed25519Kholaw:
        if (coin.defaultHdKeyDerivator == DefaultHdKeyDerivator.icarus) {
          bip = CardanoIcarusBip32.fromPublicKey(
            pubkeyBytes,
            keyData: keyData,
            keyNetVer: coin.keyNetVer,
          );
          break;
        }
        bip = Bip32KholawEd25519.fromPublicKey(
          pubkeyBytes,
          keyData: keyData,
          keyNetVer: coin.keyNetVer,
        );
        break;
      case EllipticCurveTypes.nist256p1:
        bip = Bip32Slip10Nist256p1.fromPublicKey(
          pubkeyBytes,
          keyData: keyData,
          keyNetVer: coin.keyNetVer,
        );
        break;
      default:
        throw ArgumentException.invalidOperationArguments(
          "Bip44",
          name: "coin",
          reason: "Unsupported coin key algorithm",
          details: {"algorithm": coin.type.name},
        );
    }
    final validate = _validate(bip, coin);
    bip32 = validate.$1;
    coinConf = validate.$2;
  }

  /// Internal validation method for checking the depth of the BIP object.
  static (Bip32Base<dynamic>, BaseBipCoinConfig) _validate(
    Bip32Base<dynamic> bip32Obj,
    BaseBipCoinConfig coinConf,
  ) {
    final int depth = bip32Obj.depth.depth;

    if (bip32Obj.isPublicOnly) {
      if (depth < Bip44Levels.account.value ||
          depth > Bip44Levels.addressIndex.value) {
        throw Bip44DepthError(
          "Depth of the public-only Bip object ($depth) is below account level or beyond address index level",
        );
      }
    } else {
      if (depth < 0 || depth > Bip44Levels.addressIndex.value) {
        throw Bip44DepthError(
          "Depth of the Bip object ($depth) is invalid or beyond address index level",
        );
      }
    }

    return (bip32Obj, coinConf);
  }

  /// Constructor for creating a [Bip44Base] object from a bip32 [Bip32Base] and coin [BaseBipCoinConfig].
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

  Bip32Base<dynamic> get bip32Object => bip32;

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
  BIP44 get deriveDefaultPath;

  /// derive purpose
  BIP44 get purpose;

  /// derive coin
  BIP44 get coin;

  /// derive account with index
  BIP44 account(int accIndex);

  /// derive change with change type [Bip44Changes] internal or external
  BIP44 change(Bip44Changes changeType);

  /// derive address with index
  BIP44 addressIndex(int addressIndex);

  /// spec name
  String get specName;
}
