import 'package:blockchain_utils/chain/address/utils/addr_dec_utils.dart';
import 'package:blockchain_utils/chain/address/utils/addr_key_validator.dart';
import 'package:blockchain_utils/chain/address/types/decoder.dart';
import 'package:blockchain_utils/chain/address/types/encoder.dart';
import 'package:blockchain_utils/utils/binary/src/utils.dart';
import 'package:blockchain_utils/crypto/crypto/keys/ed25519/ed25519.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Decodes a Near Protocol address.
class NearAddrDecoder implements BlockchainAddressDecoder<BuBytes> {
  @override
  BuBytes decodeAddr(String addr) {
    final BuBytes pubKeyBytes = BytesUtils.fromHexString(addr);
    AddrDecUtils.validateBytesLength(
      pubKeyBytes,
      Ed25519KeysConst.pubKeyByteLen,
    );

    return pubKeyBytes;
  }
}

/// Encodes a Near Protocol address.
class NearAddrEncoder implements BlockchainAddressEncoder {
  @override
  String encodeKey(List<int> pubKey) {
    final pubKeyObj = AddrKeyValidator.validateAndGetEd25519KeyBytes(pubKey);
    // A Near address is just the hex-encoded public key (no '0x' prefix).
    return BytesUtils.toHexString(pubKeyObj);
  }
}
