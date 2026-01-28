import 'package:blockchain_utils/bip/address/addr_dec_utils.dart';
import 'package:blockchain_utils/bip/address/addr_key_validator.dart';
import 'package:blockchain_utils/bip/address/decoder.dart';
import 'package:blockchain_utils/bip/address/encoder.dart';
import 'package:blockchain_utils/bip/ecc/keys/ed25519_keys.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';
import 'package:blockchain_utils/utils/string/string.dart';

/// Implementation of the [BlockchainAddressDecoder] for Near Protocol addresses.
class NearAddrDecoder implements BlockchainAddressDecoder<List<int>> {
  /// Overrides the base class method to decode a Near Protocol address.
  @override
  List<int> decodeAddr(String addr) {
    /// Convert the hexadecimal input to bytes.
    final List<int> pubKeyBytes = BytesUtils.fromHexString(addr);

    /// Validate the length of the public key bytes.
    AddrDecUtils.validateBytesLength(
      pubKeyBytes,
      Ed25519KeysConst.pubKeyByteLen,
    );

    return pubKeyBytes;
  }
}

/// Implementation of the [BlockchainAddressEncoder] for Near Protocol addresses.
class NearAddrEncoder implements BlockchainAddressEncoder {
  /// Overrides the base class method to encode a public key as a Near Protocol address.
  @override
  String encodeKey(List<int> pubKey) {
    /// Validate and get the Ed25519 public key.
    final pubKeyObj = AddrKeyValidator.validateAndGetEd25519Key(pubKey);

    /// Encode the public key as a hexadecimal representation and remove the '0x' prefix.
    return StringUtils.strip0x(
      BytesUtils.toHexString(pubKeyObj.compressed),
    ).substring(2);
  }
}
