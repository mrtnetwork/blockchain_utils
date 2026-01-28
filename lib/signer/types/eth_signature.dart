import 'package:blockchain_utils/exception/exception/exception.dart';
import 'package:blockchain_utils/signer/const/constants.dart';
import 'package:blockchain_utils/signer/exception/signing_exception.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';
import 'package:blockchain_utils/utils/numbers/utils/bigint_utils.dart';

/// Utility class for Ethereum signature operations.
class ETHSignatureUtils {
  /// Gets the canonicalized version of the signature recovery id 'v' in Ethereum signatures.
  ///
  /// Parameters:
  /// - [v]: The recovery id value extracted from an Ethereum signature.
  ///
  /// Throws:
  /// - [ArgumentException] if the input recovery id is invalid or out of range.
  ///
  static int getSignatureV(int v) {
    if (v == 0 || v == 27) {
      return 27;
    }
    if (v == 1 || v == 28) {
      return 28;
    }
    if (v < 35) {
      throw ArgumentException.invalidOperationArguments(
        "ETHSignature",
        name: "v",
        reason: "Invalid signature recovery id.",
      );
    }
    return (v & 1) != 0 ? 27 : 28;
  }
}

/// Represents an Ethereum signature, consisting of the 'r', 's', and 'v' components.
class ETHSignature {
  /// Creates an Ethereum signature from the 'r', 's', and 'v' components.
  ///
  /// Throws a [CryptoSignException] if the provided 'v' is not 27 or 28.
  ETHSignature(this.r, this.s, this.v) {
    if (v != 28 && v != 27) {
      throw ArgumentException.invalidOperationArguments(
        "ETHSignature",
        name: "v",
        reason: "Invalid signature recovery id.",
      );
    }
  }

  /// Creates an Ethereum signature from a byte representation.
  ///
  /// Throws a [CryptoSignException] if the provided bytes are invalid.
  factory ETHSignature.fromBytes(List<int> signature) {
    if (signature.length != CryptoSignerConst.ecdsaSignatureLength &&
        signature.length !=
            CryptoSignerConst.ecdsaSignatureWithRecoveryIdLength) {
      throw ArgumentException.invalidOperationArguments(
        "ETHSignature",
        name: "signature",
        reason: "Invalid signature bytes length.",
      );
    }
    final rBytes = signature.sublist(
      0,
      CryptoSignerConst.generatorSecp256k1.curve.baselen,
    );
    final sBytes = signature.sublist(
      CryptoSignerConst.generatorSecp256k1.curve.baselen,
      CryptoSignerConst.generatorSecp256k1.curve.baselen * 2,
    );

    int v;
    if (signature.length == CryptoSignerConst.ecdsaSignatureLength) {
      v = (sBytes[0] & 0x80) != 0 ? 28 : 27;
      sBytes[0] &= 0x7f;
    } else {
      v = ETHSignatureUtils.getSignatureV(
        signature[CryptoSignerConst.ecdsaSignatureLength],
      );
    }
    final r = BigintUtils.fromBytes(rBytes);
    final s = BigintUtils.fromBytes(sBytes);
    return ETHSignature(r, s, v);
  }
  final BigInt s;
  final BigInt r;
  final int v;

  /// Gets the byte representation of the 'r' component of an Ethereum signature.
  ///
  /// The 'r' component represents the x-coordinate of the elliptic curve point
  /// generated during the signature process. The bytes are obtained by converting
  /// the 'r' component BigInt to a byte list with a specified length.
  ///
  /// Returns:
  /// - A List of integers representing the byte representation of 'r'.
  List<int> get rBytes =>
      BigintUtils.toBytes(r, length: CryptoSignerConst.digestLength);

  /// Gets the byte representation of the 's' component of an Ethereum signature.
  ///
  /// The 's' component represents the y-coordinate of the elliptic curve point
  /// generated during the signature process. The bytes are obtained by converting
  /// the 's' component BigInt to a byte list with a specified length.
  List<int> get sBytes =>
      BigintUtils.toBytes(s, length: CryptoSignerConst.digestLength);

  /// Gets the byte representation of the 'r', 's', and 'v' components.
  ///
  /// Optionally adjusts 'v' according to EIP-155.
  List<int> toBytes([bool eip155 = true]) {
    return [...rBytes, ...sBytes, !eip155 ? v - 27 : v];
  }

  List<int> ecdsaBytes() {
    return [...rBytes, ...sBytes];
  }

  /// Gets the hexadecimal representation of the 'r', 's', and 'v' components.
  ///
  /// Optionally adjusts 'v' according to EIP-155.
  String toHex([bool eip155 = true]) {
    return BytesUtils.toHexString(toBytes(eip155));
  }
}
