import 'package:blockchain_utils/crypto/crypto/cdsa/ecdsa/signature.dart';
import 'package:blockchain_utils/signer/bitcoin/bitcoin_signer.dart';
import 'package:blockchain_utils/signer/const/constants.dart';
import 'package:blockchain_utils/signer/exception/signing_exception.dart';
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
      throw CryptoSignException(
          "Invalid Schnorr signature: r and s must be in [0, n-1].");
    }
    return BitcoinSchnorrSignature._(r, s);
  }
  factory BitcoinSchnorrSignature.fromBytes(List<int> signature) {
    if (signature.length == CryptoSignerConst.schnoorSginatureLength ||
        signature.length == CryptoSignerConst.schnoorSginatureLength + 1) {
      final r = BigintUtils.fromBytes(
          signature.sublist(0, BitcoinSignerUtils.baselen));
      final s = BigintUtils.fromBytes(signature.sublist(
          BitcoinSignerUtils.baselen, BitcoinSignerUtils.baselen * 2));
      return BitcoinSchnorrSignature(r: r, s: s);
    }
    throw CryptoSignException("Invalid schnorr signature.");
  }

  List<int> rBytes() {
    return BigintUtils.toBytes(r, length: BitcoinSignerUtils.baselen);
  }

  List<int> sBytes() {
    return BigintUtils.toBytes(s, length: BitcoinSignerUtils.baselen);
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
      throw CryptoSignException(
          "Invalid ECDSA signature: r must be in [1, n-1].");
    }
    if (s < BigInt.one || s >= BitcoinSignerUtils.order) {
      throw CryptoSignException(
          "Invalid ECDSA signature: s must be in [1, n-1].");
    }
    return Secp256k1EcdsaSignature._(r, s);
  }
  factory Secp256k1EcdsaSignature.fromDer(List<int> derSignature) {
    if (!CryptoSignatureUtils.isValidBitcoinDERSignature(derSignature)) {
      throw CryptoSignException("Invalid ECDSA Der signature.");
    }
    final int lengthR = derSignature[3];
    final int lengthS = derSignature[5 + lengthR];
    final rBytes = CryptoSignatureUtils.derStripLeadingZeroIfNeeded(
        derSignature.sublist(4, 4 + lengthR));

    final int sIndex = 4 + lengthR + 2;
    final sBytes = CryptoSignatureUtils.derStripLeadingZeroIfNeeded(
        derSignature.sublist(sIndex, sIndex + lengthS));
    if (sBytes.length > BitcoinSignerUtils.baselen ||
        rBytes.length > BitcoinSignerUtils.baselen) {
      throw CryptoSignException(
          "Invalid ECDSA signature: must be ${BitcoinSignerUtils.baselen * 2} bytes.");
    }
    return Secp256k1EcdsaSignature.fromBytes([
      ...BytesUtils.padBytesLeft(rBytes, BitcoinSignerUtils.baselen),
      ...BytesUtils.padBytesLeft(sBytes, BitcoinSignerUtils.baselen)
    ]);
  }

  factory Secp256k1EcdsaSignature.fromBytes(List<int> signature) {
    if (signature.length != BitcoinSignerUtils.baselen * 2) {
      throw CryptoSignException(
          "Invalid ECDSA signature: must be ${BitcoinSignerUtils.baselen * 2} bytes.");
    }
    final r =
        BigintUtils.fromBytes(signature.sublist(0, BitcoinSignerUtils.baselen));
    final s = BigintUtils.fromBytes(signature.sublist(
        BitcoinSignerUtils.baselen, BitcoinSignerUtils.baselen * 2));
    return Secp256k1EcdsaSignature(r: r, s: s);
  }

  List<int> rBytes() {
    return BigintUtils.toBytes(r, length: BitcoinSignerUtils.baselen);
  }

  List<int> sBytes() {
    return BigintUtils.toBytes(s, length: BitcoinSignerUtils.baselen);
  }

  List<int> toBytes() {
    return [...rBytes(), ...sBytes()];
  }

  String toHex() {
    return BytesUtils.toHexString(toBytes());
  }
}
