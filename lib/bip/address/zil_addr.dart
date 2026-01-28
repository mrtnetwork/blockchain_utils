import 'package:blockchain_utils/bech32/bech32_base.dart';
import 'package:blockchain_utils/bip/address/addr_key_validator.dart';
import 'package:blockchain_utils/bip/address/decoder.dart';
import 'package:blockchain_utils/bip/address/encoder.dart';
import 'package:blockchain_utils/bip/coin_conf/constant/coins_conf.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';

/// Constants related to Zilliqa (ZIL) blockchain addresses.
class ZilAddrConst {
  /// The length, in bytes, of a SHA-256 hash used in Zilliqa addresses.
  static const int sha256ByteLen = 20;
}

/// A Zilliqa (ZIL) blockchain address decoder that implements the [BlockchainAddressDecoder] interface.
class ZilAddrDecoder implements BlockchainAddressDecoder<List<int>> {
  /// Decodes a Zilliqa blockchain address from a human-readable representation.
  @override
  List<int> decodeAddr(String addr) {
    /// Decode the Zilliqa address using the specified Human Readable Part (HRP).
    final addrDecBytes = Bech32Decoder.decode(
      AddrKeyValidator.getConfigArg(
        CoinsConf.zilliqa.params.addrHrp,
        "addrHrp",
      ),
      addr,
    );
    return addrDecBytes;
  }
}

/// A Zilliqa blockchain address encoder that implements the [BlockchainAddressEncoder] interface.
class ZilAddrEncoder implements BlockchainAddressEncoder {
  /// Encodes a Zilliqa blockchain address from a given public key.
  @override
  String encodeKey(List<int> pubKey) {
    /// Validate the public key and obtain a secp256k1 key object.
    final pubKeyObj = AddrKeyValidator.validateAndGetSecp256k1Key(pubKey);

    /// Calculate the SHA-256 hash of the compressed public key.
    final keyHash = QuickCrypto.sha256Hash(pubKeyObj.compressed);

    /// Encode the Zilliqa blockchain address using Bech32 encoding.
    return Bech32Encoder.encode(
      AddrKeyValidator.getConfigArg(
        CoinsConf.zilliqa.params.addrHrp,
        "addrHrp",
      ),
      keyHash.sublist(keyHash.length - ZilAddrConst.sha256ByteLen),
    );
  }
}
