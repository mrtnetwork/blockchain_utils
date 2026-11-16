import 'package:blockchain_utils/chain/address/utils/addr_dec_utils.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/chain/address/types/decoder.dart';
import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/protocol/bip/coin_conf/constant/coins_conf.dart';
import 'package:blockchain_utils/crypto/crypto/keys/core/i_keys.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/utils/binary/src/utils.dart';
import 'package:blockchain_utils/utils/string/string.dart';

import 'package:blockchain_utils/chain/address/types/encoder.dart';
import 'package:blockchain_utils/chain/address/utils/addr_key_validator.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Constants related to Ethereum addresses.
class EthAddrConst {
  /// Hex-character offset where the 20-byte address starts within a
  /// 32-byte keccak256 hash (i.e. skip the first 12 bytes = 24 hex chars).
  static const int startByte = 24;

  /// The total length of an Ethereum address in hexadecimal characters.
  static const int addrLen = 40;

  /// The total length of an Ethereum address in bytes.
  static const int addrLenBytes = 20;
}

/// Utility class for Ethereum address-related operations.
class EthAddrUtils {
  /// Applies EIP-55 mixed-case checksum encoding to a hex address.
  static String _checksumEncode(String addr) {
    final String addrHexDigest = BytesUtils.toHexString(
      QuickCrypto.keccak256Hash(StringUtils.encode(addr.toLowerCase())),
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

  /// Converts any-case hex [addr] to its checksummed form.
  static String toChecksumAddress(String addr) {
    final String withoutPrefix = StringUtils.strip0x(addr);
    if (!StringUtils.isHexBytes(withoutPrefix)) {
      throw CoreErrors.addressValidationFailed(
        details: {"address": addr},
      );
    }
    AddrDecUtils.validateLength(withoutPrefix, EthAddrConst.addrLen);
    return AddrKeyValidator.getConfigArg(
          CoinsConf.ethereum.params.addrPrefix,
          "addrPrefix",
        ) +
        _checksumEncode(withoutPrefix);
  }

  /// Converts raw address bytes to a checksummed hex address.
  static String addressBytesToChecksumAddress(List<int> bytes) {
    final String addr = BytesUtils.toHexString(bytes);
    return toChecksumAddress(addr);
  }
}

/// Decodes an Ethereum address.
class EthAddrDecoder implements BlockchainAddressDecoder<BuBytes> {
  @override
  BuBytes decodeAddr(String addr, {bool skipChecksum = false}) {
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
      throw CoreErrors.addressKeyValidationFailed(
        reason: "Invalid checksum encoding",
      );
    }
    return BytesUtils.fromHexString(addrNoPrefix);
  }
}

/// Encodes an Ethereum address.
class EthAddrEncoder implements BlockchainAddressEncoder {
  @override
  String encodeKey(List<int> pubKey, {bool skipChecksum = false}) {
    final IPublicKey pubKeyObj = AddrKeyValidator.validateAndGetSecp256k1Key(
      pubKey,
    );
    final String hashKey = BytesUtils.toHexString(
      QuickCrypto.keccak256Hash(
        pubKeyObj.toBytes(mode: CryptoKeyEncoding.uncompressed).sublist(1),
      ),
    );
    final String addr = hashKey.substring(EthAddrConst.startByte);
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
