import 'package:blockchain_utils/bip/address/addr_dec_utils.dart';
import 'package:blockchain_utils/bip/address/decoder.dart';
import 'package:blockchain_utils/bip/coin_conf/constant/coins_conf.dart';
import 'package:blockchain_utils/bip/ecc/keys/i_keys.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';
import 'package:blockchain_utils/utils/string/string.dart';

import 'addr_key_validator.dart';
import 'encoder.dart';
import 'exception/exception.dart';

/// Constants related to Ethereum addresses.
class EthAddrConst {
  /// The starting byte of an Ethereum address.
  static const int startByte = 24;

  /// The total length of an Ethereum address in hexadecimal characters.
  static const int addrLen = 40;

  /// The total length of an Ethereum address in bytes.
  static const int addrLenBytes = 20;
}

/// Utility class for Ethereum address-related operations.
class EthAddrUtils {
  /// Encodes an Ethereum address with checksum.
  static String _checksumEncode(String addr) {
    final String addrHexDigest = BytesUtils.toHexString(
      QuickCrypto.keccack256Hash(StringUtils.encode(addr.toLowerCase())),
    );
    final List<String> encAddr =
        addr.split("").asMap().entries.map((entry) {
          final int i = entry.key;
          final String c = entry.value;
          final int charValue = int.parse(addrHexDigest[i], radix: 16);
          return charValue >= 8 ? c.toUpperCase() : c.toLowerCase();
        }).toList();

    return encAddr.join();
  }

  static String toChecksumAddress(String addr) {
    final String wihtoutPrefix = StringUtils.strip0x(addr);
    if (!StringUtils.isHexBytes(wihtoutPrefix)) {
      throw AddressConverterException.addressValidationFailed(
        details: {"address": addr},
      );
    }
    AddrDecUtils.validateLength(wihtoutPrefix, EthAddrConst.addrLen);
    return AddrKeyValidator.getConfigArg(
          CoinsConf.ethereum.params.addrPrefix,
          "addrPrefix",
        ) +
        _checksumEncode(wihtoutPrefix);
  }

  static String addressBytesToChecksumAddress(List<int> bytes) {
    final String addr = BytesUtils.toHexString(bytes);
    return toChecksumAddress(addr);
  }
}

/// Implementation of the [BlockchainAddressDecoder] for Ethereum addresses.
class EthAddrDecoder implements BlockchainAddressDecoder<List<int>> {
  /// Decodes an Ethereum address from its string representation.
  @override
  List<int> decodeAddr(String addr, {bool skipChecksum = false}) {
    final String addrNoPrefix = AddrDecUtils.validateAndRemovePrefix(
      addr,
      AddrKeyValidator.getConfigArg(
        CoinsConf.ethereum.params.addrPrefix,
        "addrPrefix",
      ),
    );
    AddrDecUtils.validateLength(addrNoPrefix, EthAddrConst.addrLen);
    if (!skipChecksum &&
        addrNoPrefix != EthAddrUtils._checksumEncode(addrNoPrefix)) {
      throw AddressConverterException.addressKeyValidationFailed(
        reason: "Invalid checksum encoding",
      );
    }
    return BytesUtils.fromHexString(addrNoPrefix);
  }
}

/// Implementation of the [BlockchainAddressEncoder] for Ethereum addresses.
class EthAddrEncoder implements BlockchainAddressEncoder {
  /// Encodes a public key as an Ethereum address.
  @override
  String encodeKey(List<int> pubKey, {bool skipChecksum = false}) {
    final IPublicKey pubKeyObj = AddrKeyValidator.validateAndGetSecp256k1Key(
      pubKey,
    );
    final String kekkakHex = BytesUtils.toHexString(
      QuickCrypto.keccack256Hash(pubKeyObj.uncompressed.sublist(1)),
    );
    final String addr = kekkakHex.substring(EthAddrConst.startByte);
    if (skipChecksum) {
      return addr;
    }
    return AddrKeyValidator.getConfigArg(
          CoinsConf.ethereum.params.addrPrefix,
          "addrPrefix",
        ) +
        EthAddrUtils._checksumEncode(addr);
  }
}
