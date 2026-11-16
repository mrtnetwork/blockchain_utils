import 'package:blockchain_utils/encoding/base58/src/base58_base.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/chain/address/utils/addr_dec_utils.dart';
import 'package:blockchain_utils/chain/address/utils/addr_key_validator.dart';
import 'package:blockchain_utils/chain/address/types/decoder.dart';
import 'package:blockchain_utils/chain/address/types/encoder.dart';
import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/utils/binary/src/utils.dart';

/// A class that defines constants for Neo (NEO) addresses.
class NeoAddrConst {
  /// The prefix byte used in Neo addresses.
  static const prefixByte = [0x21];

  /// The suffix byte used in Neo addresses.
  static const suffixByte = [0xac];
}

/// Decodes a Neo (NEO) address.
class NeoAddrDecoder implements BlockchainAddressDecoder<List<int>> {
  @override
  List<int> decodeAddr(String addr, {List<int>? versionBytes}) {
    final List<int> verBytes = AddrKeyValidator.getAddrArg(
      versionBytes,
      "versionBytes",
    );
    final List<int> addrDecBytes = Base58Decoder.decodeWithChecksum(addr);

    AddrDecUtils.validateBytesLength(
      addrDecBytes,
      QuickCrypto.hash160DigestSize + verBytes.length,
    );

    if (!BytesUtils.bytesEqual([addrDecBytes[0]], verBytes)) {
      throw CoreErrors.addressValidationFailed(
        reason: "Invalid address version byte.",
      );
    }

    return addrDecBytes.sublist(1);
  }
}

/// Encodes a Neo (NEO) address.
class NeoAddrEncoder implements BlockchainAddressEncoder {
  @override
  String encodeKey(List<int> pubKey, {List<int>? versionBytes}) {
    final List<int> verBytes = AddrKeyValidator.getAddrArg(
      versionBytes,
      "versionBytes",
    );

    final pubKeyObj = AddrKeyValidator.validateAndGetNist256p1Key(pubKey);
    final List<int> payloadBytes = [
      ...NeoAddrConst.prefixByte,
      ...pubKeyObj.toBytes(mode: CryptoKeyEncoding.base),
      ...NeoAddrConst.suffixByte,
    ];

    return Base58Encoder.encodeWithChecksum([
      ...verBytes,
      ...QuickCrypto.hash160(payloadBytes),
    ]);
  }
}
