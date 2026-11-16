import 'package:blockchain_utils/encoding/base58/base58.dart';
import 'package:blockchain_utils/chain/address/utils/addr_dec_utils.dart';
import 'package:blockchain_utils/chain/address/utils/addr_key_validator.dart';
import 'package:blockchain_utils/chain/address/types/decoder.dart';
import 'package:blockchain_utils/chain/address/types/encoder.dart';
import 'package:blockchain_utils/crypto/crypto/keys/ed25519/ed25519.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Decodes a Solana (SOL) address.
class SolAddrDecoder implements BlockchainAddressDecoder<BuBytes> {
  @override
  BuBytes decodeAddr(String addr) {
    final addrDecBytes = Base58Decoder.decode(addr);
    AddrDecUtils.validateBytesLength(
      addrDecBytes,
      Ed25519KeysConst.pubKeyByteLen,
    );
    return addrDecBytes;
  }
}

/// Encodes a Solana (SOL) address.
class SolAddrEncoder implements BlockchainAddressEncoder {
  @override
  String encodeKey(List<int> pubKey) {
    final pub = AddrKeyValidator.validateAndGetEd25519KeyBytes(pubKey);
    return Base58Encoder.encode(pub);
  }
}
