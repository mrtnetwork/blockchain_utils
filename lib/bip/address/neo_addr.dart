import 'package:blockchain_utils/base58/base58_base.dart';
import 'package:blockchain_utils/bip/address/addr_dec_utils.dart';
import 'package:blockchain_utils/bip/address/addr_key_validator.dart';
import 'package:blockchain_utils/bip/address/decoder.dart';
import 'package:blockchain_utils/bip/address/encoder.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';

import 'exception/exception.dart';

/// A class that defines constants for Neo (NEO) addresses.
class NeoAddrConst {
  /// The prefix byte used in Neo addresses.
  static const prefixByte = [0x21];

  /// The suffix byte used in Neo addresses.
  static const suffixByte = [0xac];
}

/// Implementation of the [BlockchainAddressDecoder] for Neo (NEO) addresses.
class NeoAddrDecoder implements BlockchainAddressDecoder<List<int>> {
  /// Overrides the base class method to decode a Neo (NEO) address.
  @override
  List<int> decodeAddr(String addr, {List<int>? versionBytes}) {
    final List<int> verBytes = AddrKeyValidator.getAddrArg(
      versionBytes,
      "versionBytes",
    );
    final List<int> addrDecBytes = Base58Decoder.checkDecode(addr);

    /// Validate the length of the decoded address.
    AddrDecUtils.validateBytesLength(
      addrDecBytes,
      QuickCrypto.hash160DigestSize + verBytes.length,
    );

    if (!BytesUtils.bytesEqual([addrDecBytes[0]], verBytes)) {
      throw AddressConverterException.addressValidationFailed(
        reason: "Invalid address checksum.",
      );
    }

    return addrDecBytes.sublist(1);
  }
}

/// Implementation of the [BlockchainAddressEncoder] for Neo (NEO) addresses.
class NeoAddrEncoder implements BlockchainAddressEncoder {
  /// Overrides the base class method to encode a public key as a Neo (NEO) address using Base58 encoding.
  @override
  String encodeKey(List<int> pubKey, {List<int>? versionBytes}) {
    final List<int> verBytes = AddrKeyValidator.getAddrArg(
      versionBytes,
      "versionBytes",
    );

    /// Validate and get the Nist256p1 public key.
    final pubKeyObj = AddrKeyValidator.validateAndGetNist256p1Key(pubKey);

    /// Construct the Neo address payload.
    final List<int> payloadBytes = [
      ...NeoAddrConst.prefixByte,
      ...pubKeyObj.compressed,
      ...NeoAddrConst.suffixByte,
    ];

    /// Encode the payload as a Base58 address.
    return Base58Encoder.checkEncode([
      ...verBytes,
      ...QuickCrypto.hash160(payloadBytes),
    ]);
  }
}
