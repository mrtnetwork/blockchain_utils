import 'package:blockchain_utils/encoding/base32/base32.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/chain/address/utils/addr_dec_utils.dart';
import 'package:blockchain_utils/chain/address/types/decoder.dart';
import 'package:blockchain_utils/chain/address/types/encoder.dart';
import 'package:blockchain_utils/crypto/crypto/keys/ed25519/ed25519.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Algorand address constants.
class AlgoAddrConst {
  /// Checksum length in bytes.
  static const int checksumByteLen = 4;
}

/// Internal Algorand address helpers.
class _AlgoAddrUtils {
  /// Computes the address checksum.
  static BuBytes computeChecksum(List<int> pubKeyBytes) {
    final digest = QuickCrypto.sha512256Hash(pubKeyBytes);
    final startIndex = digest.length - AlgoAddrConst.checksumByteLen;

    return digest.sublist(startIndex);
  }
}

/// Decodes an Algorand address.
class AlgoAddrDecoder implements BlockchainAddressDecoder<BuBytes> {
  /// Returns the decoded public key bytes.
  @override
  BuBytes decodeAddr(String addr) {
    final addrDecBytes = Base32Decoder.decode(addr);
    const expectedLength =
        Ed25519KeysConst.pubKeyByteLen + AlgoAddrConst.checksumByteLen;
    AddrDecUtils.validateBytesLength(addrDecBytes, expectedLength);
    final parts = AddrDecUtils.splitPartsByChecksum(
      addrDecBytes,
      AlgoAddrConst.checksumByteLen,
    );
    final pubKeyBytes = parts.$1;
    final checksumBytes = parts.$2;
    AddrDecUtils.validateChecksum(
      pubKeyBytes,
      checksumBytes,
      _AlgoAddrUtils.computeChecksum,
    );
    return BuBytes(pubKeyBytes);
  }
}

/// Encodes an Algorand address.
class AlgoAddrEncoder implements BlockchainAddressEncoder {
  /// Returns the encoded address string.
  @override
  String encodeKey(List<int> pubKey) {
    if (pubKey.length ==
        Ed25519KeysConst.pubKeyByteLen + Ed25519KeysConst.pubKeyPrefix.length) {
      pubKey = pubKey.sublist(Ed25519KeysConst.pubKeyPrefix.length);
    }
    if (pubKey.length != Ed25519KeysConst.pubKeyByteLen) {
      throw CoreErrors.missingOrInvalidAddressArguments(
        reason: "Invalid encoded address bytes length.",
      );
    }
    final checksumBytes = _AlgoAddrUtils.computeChecksum(pubKey);
    final encodedAddress = Base32Encoder.encodeNoPaddingBytes([
      ...pubKey,
      ...checksumBytes,
    ]);
    return encodedAddress;
  }
}
