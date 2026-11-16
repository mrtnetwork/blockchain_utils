import 'package:blockchain_utils/chain/address/utils/addr_key_validator.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/chain/address/types/decoder.dart';
import 'package:blockchain_utils/chain/address/types/encoder.dart';
import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/encoding/bech32/bech32.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Constants related to P2WPKH (Pay-to-Witness-Public-Key-Hash) addresses.
class P2WPKHAddrConst {
  /// The witness version for P2WPKH addresses.
  /// In the context of Bitcoin and SegWit-based transactions, P2WPKH addresses
  /// typically have a witness version of 0.
  static const int witnessVer = 0;
}

/// Decodes a Segwit (P2WPKH) address.
class P2WPKHAddrDecoder implements BlockchainAddressDecoder<BuBytes> {
  @override
  BuBytes decodeAddr(String addr, {String? hrp}) {
    hrp = AddrKeyValidator.getAddrArg<String>(hrp, "hrp");

    final decoded = SegwitBech32Decoder.decode(hrp, addr);
    final witVerGot = decoded.$1;
    final addrDecBytes = decoded.$2;

    if (witVerGot != P2WPKHAddrConst.witnessVer) {
      throw CoreErrors.addressValidationFailed(
        reason: "Invalid address witness version",
      );
    }

    return addrDecBytes;
  }
}

/// Encodes a Segwit (P2WPKH) address.
class P2WPKHAddrEncoder implements BlockchainAddressEncoder {
  @override
  String encodeKey(List<int> pubKey, {String? hrp}) {
    hrp = AddrKeyValidator.getAddrArg<String>(hrp, "hrp");

    final pubKeyObj = AddrKeyValidator.validateAndGetSecp256k1Key(pubKey);
    const witnessVer = P2WPKHAddrConst.witnessVer;
    final pubKeyBytes = pubKeyObj.toBytes(mode: CryptoKeyEncoding.base);

    return SegwitBech32Encoder.encode(
      hrp,
      witnessVer,
      QuickCrypto.hash160(pubKeyBytes),
    );
  }
}
