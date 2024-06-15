import 'package:blockchain_utils/utils/utils.dart';
import 'package:blockchain_utils/exception/exception.dart';
import 'package:blockchain_utils/signer/eth/evm_signer.dart';

/// Utility class for Ethereum signature operations.
class ETHSignatureUtils {
  /// Gets the canonicalized version of the signature recovery id 'v' in Ethereum signatures.
  ///
  /// Ethereum signatures include a recovery id 'v' that can be 0 or 1 for
  /// Ethereum mainnet or 27 or 28 for testnets. This method ensures that the
  /// recovery id is canonicalized to 27 or 28, throwing an exception for invalid values.
  ///
  /// Parameters:
  /// - [v]: The recovery id value extracted from an Ethereum signature.
  ///
  /// Returns:
  /// - The canonicalized recovery id (27 or 28).
  ///
  /// Throws:
  /// - [MessageException] if the input recovery id is invalid or out of range.
  ///
  static int getSignatureV(int v) {
    if (v == 0 || v == 27) {
      return 27;
    }
    if (v == 1 || v == 28) {
      return 28;
    }
    if (v < 35) {
      throw MessageException("Invalid signature recovery id",
          details: {"input": v});
    }
    return (v & 1) != 0 ? 27 : 28;
  }
}

/// Represents an Ethereum signature, consisting of the 'r', 's', and 'v' components.
///
/// An Ethereum signature is often used to authenticate transactions or messages
/// in the Ethereum blockchain. This class provides methods for creating and
/// manipulating Ethereum signatures, including conversion to and from bytes and hex.
class ETHSignature {
  /// Creates an Ethereum signature from the 'r', 's', and 'v' components.
  ///
  /// Throws a [MessageException] if the provided 'v' is not 27 or 28.
  ETHSignature(this.r, this.s, this.v) {
    if (v != 28 && v != 27) {
      throw MessageException("Invalid signature recovery id",
          details: {"input": v});
    }
  }

  /// Creates an Ethereum signature from a byte representation.
  ///
  /// Throws a [MessageException] if the provided bytes are invalid.
  factory ETHSignature.fromBytes(List<int> bytes) {
    if (bytes.length != ETHSignerConst.ethSignatureLength &&
        bytes.length !=
            ETHSignerConst.ethSignatureLength +
                ETHSignerConst.ethSignatureRecoveryIdLength) {
      throw MessageException("Invalid signature bytes",
          details: {"input": BytesUtils.tryToHexString(bytes)});
    }
    final rBytes = bytes.sublist(0, ETHSignerConst.secp256.curve.baselen);
    final sBytes = bytes.sublist(ETHSignerConst.secp256.curve.baselen,
        ETHSignerConst.secp256.curve.baselen * 2);

    int v;
    if (bytes.length == ETHSignerConst.ethSignatureLength) {
      v = (sBytes[0] & 0x80) != 0 ? 28 : 27;
      sBytes[0] &= 0x7f;
    } else {
      v = ETHSignatureUtils.getSignatureV(
          bytes[ETHSignerConst.ethSignatureLength]);
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
      BigintUtils.toBytes(r, length: ETHSignerConst.digestLength);

  /// Gets the byte representation of the 's' component of an Ethereum signature.
  ///
  /// The 's' component represents the y-coordinate of the elliptic curve point
  /// generated during the signature process. The bytes are obtained by converting
  /// the 's' component BigInt to a byte list with a specified length.
  List<int> get sBytes =>
      BigintUtils.toBytes(s, length: ETHSignerConst.digestLength);

  /// Gets the byte representation of the 'r', 's', and 'v' components.
  ///
  /// Optionally adjusts 'v' according to EIP-155.
  List<int> toBytes([bool eip155 = true]) {
    return [...rBytes, ...sBytes, !eip155 ? v - 27 : v];
  }

  /// Gets the hexadecimal representation of the 'r', 's', and 'v' components.
  ///
  /// Optionally adjusts 'v' according to EIP-155.
  String toHex([bool eip155 = true]) {
    return BytesUtils.toHexString(toBytes(eip155));
  }
}
