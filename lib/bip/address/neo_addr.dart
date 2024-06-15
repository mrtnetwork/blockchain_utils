import 'dart:typed_data';
import 'package:blockchain_utils/base58/base58_base.dart';
import 'package:blockchain_utils/bip/address/addr_dec_utils.dart';
import 'package:blockchain_utils/bip/address/addr_key_validator.dart';
import 'package:blockchain_utils/bip/address/decoder.dart';
import 'package:blockchain_utils/bip/address/encoder.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'exception/exception.dart';

/// A class that defines constants for Neo (NEO) addresses.
class NeoAddrConst {
  /// The prefix byte used in Neo addresses.
  static const prefixByte = [0x21];

  /// The suffix byte used in Neo addresses.
  static const suffixByte = [0xac];
}

/// Implementation of the [BlockchainAddressDecoder] for Neo (NEO) addresses.
class NeoAddrDecoder implements BlockchainAddressDecoder {
  /// Overrides the base class method to decode a Neo (NEO) address.
  ///
  /// This method decodes a Neo address from the provided input string using Base58 encoding.
  /// It expects an optional map of keyword arguments with 'ver' specifying the version bytes.
  /// The method validates the arguments, decodes the Base58 address, checks its version, length,
  /// and checksum, and returns the decoded Neo address as a List<int>.
  ///
  /// Parameters:
  ///   - addr: The Base58-encoded Neo address to be decoded.
  ///   - kwargs: Optional keyword arguments with 'ver' for the version bytes.
  ///
  /// Returns:
  ///   A List<int> containing the decoded Neo address bytes.
  @override
  List<int> decodeAddr(String addr, [Map<String, dynamic> kwargs = const {}]) {
    /// Validate the version argument.
    AddrKeyValidator.validateAddressArgs<List<int>>(kwargs, "ver");
    List<int> verBytes = kwargs["ver"];
    List<int> addrDecBytes = Base58Decoder.checkDecode(addr);

    /// Validate the length of the decoded address.
    AddrDecUtils.validateBytesLength(
        addrDecBytes, QuickCrypto.hash160DigestSize + verBytes.length);

    /// Retrieve the version byte from the decoded address and compare it with the expected version.
    List<int> verGot = IntUtils.toBytes(addrDecBytes[0],
        length: IntUtils.bitlengthInBytes(addrDecBytes[0]),
        byteOrder: Endian.little);
    if (!BytesUtils.bytesEqual(verGot, verBytes)) {
      throw AddressConverterException(
          "Invalid version (expected ${BytesUtils.toHexString(verBytes)}, "
          "got ${BytesUtils.toHexString(verGot)})");
    }

    return addrDecBytes.sublist(1);
  }
}

/// Implementation of the [BlockchainAddressEncoder] for Neo (NEO) addresses.
class NeoAddrEncoder implements BlockchainAddressEncoder {
  /// Overrides the base class method to encode a public key as a Neo (NEO) address using Base58 encoding.
  ///
  /// This method encodes a public key as a Neo address using Base58 encoding. It expects a version byte
  /// as a keyword argument. The method validates the version argument, constructs the Neo address payload,
  /// and encodes it as a Base58 address. The result is returned as a String representing the Neo address.
  ///
  /// Parameters:
  ///   - pubKey: The public key to be encoded as a Neo address in the form of a List<int>.
  ///   - kwargs: Optional keyword arguments with 'ver' for the version bytes.
  ///
  /// Returns:
  ///   A String representing the Base58-encoded Neo address derived from the provided public key.
  @override
  String encodeKey(List<int> pubKey, [Map<String, dynamic> kwargs = const {}]) {
    /// Validate the version argument.
    AddrKeyValidator.validateAddressArgs<List<int>>(kwargs, "ver");
    List<int> verBytes = kwargs["ver"];

    /// Validate and get the Nist256p1 public key.
    final pubKeyObj = AddrKeyValidator.validateAndGetNist256p1Key(pubKey);

    /// Construct the Neo address payload.
    List<int> payloadBytes = List<int>.from([
      ...NeoAddrConst.prefixByte,
      ...pubKeyObj.compressed,
      ...NeoAddrConst.suffixByte,
    ]);

    /// Encode the payload as a Base58 address.
    return Base58Encoder.checkEncode(
        List<int>.from([...verBytes, ...QuickCrypto.hash160(payloadBytes)]));
  }
}
