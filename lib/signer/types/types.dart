import 'package:blockchain_utils/crypto/crypto/ec/ecdsa/signature.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/signer/bitcoin/bitcoin_key_signer.dart';
import 'package:blockchain_utils/signer/const/constants.dart';
import 'package:blockchain_utils/signer/utils/utils.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';
import 'package:blockchain_utils/utils/numbers/utils/bigint_utils.dart';

class BitcoinSchnorrSignature {
  final BigInt r;
  final BigInt s;
  const BitcoinSchnorrSignature._(this.r, this.s);
  factory BitcoinSchnorrSignature({required BigInt r, required BigInt s}) {
    if (r.isNegative ||
        r >= BitcoinSignerUtils.order ||
        s.isNegative ||
        s >= BitcoinSignerUtils.order) {
      throw ArgumentException.invalidOperationArguments(
        "BitcoinSchnorrSignature",
        reason: "Invalid Schnorr signature.",
      );
    }
    return BitcoinSchnorrSignature._(r, s);
  }
  factory BitcoinSchnorrSignature.fromBytes(List<int> signature) {
    if (signature.length == CryptoSignerConst.schnoorSginatureLength ||
        signature.length == CryptoSignerConst.schnoorSginatureLength + 1) {
      final r = BigintUtils.fromBytes(
        signature.sublist(0, BitcoinSignerUtils.baselen),
      );
      final s = BigintUtils.fromBytes(
        signature.sublist(
          BitcoinSignerUtils.baselen,
          BitcoinSignerUtils.baselen * 2,
        ),
      );
      return BitcoinSchnorrSignature(r: r, s: s);
    }
    throw ArgumentException.invalidOperationArguments(
      "BitcoinSchnorrSignature",
      reason: "Invalid Schnorr signature bytes length.",
    );
  }

  List<int> rBytes() {
    return r.toBeBytes(length: BitcoinSignerUtils.baselen);
  }

  List<int> sBytes() {
    return s.toBeBytes(length: BitcoinSignerUtils.baselen);
  }

  List<int> toBytes() {
    return [...rBytes(), ...sBytes()];
  }

  String toHex() {
    return BytesUtils.toHexString(toBytes());
  }
}

class Secp256k1EcdsaSignature {
  final BigInt r;
  final BigInt s;
  ECDSASignature toEcdsaSignature() {
    return ECDSASignature(r, s);
  }

  const Secp256k1EcdsaSignature._(this.r, this.s);
  factory Secp256k1EcdsaSignature({required BigInt r, required BigInt s}) {
    if (r < BigInt.one || r >= BitcoinSignerUtils.order) {
      throw ArgumentException.invalidOperationArguments(
        "Secp256k1EcdsaSignature",
        reason: "Invalid ECDSA signature.",
      );
    }
    if (s < BigInt.one || s >= BitcoinSignerUtils.order) {
      throw ArgumentException.invalidOperationArguments(
        "Secp256k1EcdsaSignature",
        reason: "Invalid ECDSA signature.",
      );
    }
    return Secp256k1EcdsaSignature._(r, s);
  }
  factory Secp256k1EcdsaSignature.fromDer(List<int> derSignature) {
    if (!CryptoSignatureUtils.isValidBitcoinDERSignature(derSignature)) {
      throw ArgumentException.invalidOperationArguments(
        "Secp256k1EcdsaSignature",
        name: "derSignature",
        reason: "Invalid ECDSA der signature.",
      );
    }
    final int lengthR = derSignature[3];
    final int lengthS = derSignature[5 + lengthR];
    final rBytes = CryptoSignatureUtils.derStripLeadingZeroIfNeeded(
      derSignature.sublist(4, 4 + lengthR),
    );

    final int sIndex = 4 + lengthR + 2;
    final sBytes = CryptoSignatureUtils.derStripLeadingZeroIfNeeded(
      derSignature.sublist(sIndex, sIndex + lengthS),
    );
    if (sBytes.length > BitcoinSignerUtils.baselen ||
        rBytes.length > BitcoinSignerUtils.baselen) {
      throw ArgumentException.invalidOperationArguments(
        "Secp256k1EcdsaSignature",
        name: "derSignature",
        reason: "Invalid ECDSA der signature.",
      );
    }
    return Secp256k1EcdsaSignature.fromBytes([
      ...BytesUtils.padBytesLeft(rBytes, BitcoinSignerUtils.baselen),
      ...BytesUtils.padBytesLeft(sBytes, BitcoinSignerUtils.baselen),
    ]);
  }

  factory Secp256k1EcdsaSignature.fromBytes(List<int> signature) {
    if (signature.length != BitcoinSignerUtils.baselen * 2) {
      throw ArgumentException.invalidOperationArguments(
        "Secp256k1EcdsaSignature",
        name: "derSignature",
        reason: "Invalid ECDSA der signature.",
      );
    }
    final r = BigintUtils.fromBytes(
      signature.sublist(0, BitcoinSignerUtils.baselen),
    );
    final s = BigintUtils.fromBytes(
      signature.sublist(
        BitcoinSignerUtils.baselen,
        BitcoinSignerUtils.baselen * 2,
      ),
    );
    return Secp256k1EcdsaSignature(r: r, s: s);
  }

  List<int> rBytes() {
    return r.toBeBytes(length: BitcoinSignerUtils.baselen);
  }

  List<int> sBytes() {
    return s.toBeBytes(length: BitcoinSignerUtils.baselen);
  }

  List<int> toBytes() {
    return [...rBytes(), ...sBytes()];
  }

  String toHex() {
    return BytesUtils.toHexString(toBytes());
  }
}
