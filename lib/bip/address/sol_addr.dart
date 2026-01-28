import 'package:blockchain_utils/base58/base58.dart';
import 'package:blockchain_utils/bip/address/addr_dec_utils.dart';
import 'package:blockchain_utils/bip/address/addr_key_validator.dart';
import 'package:blockchain_utils/bip/address/decoder.dart';
import 'package:blockchain_utils/bip/address/encoder.dart';
import 'package:blockchain_utils/bip/ecc/keys/ed25519_keys.dart';

/// Implementation of the [BlockchainAddressDecoder] for Solana (SOL) addresses.
class SolAddrDecoder implements BlockchainAddressDecoder<List<int>> {
  /// Overrides the base class method to decode a Solana SOL address.
  @override
  List<int> decodeAddr(String addr) {
    /// Decode the Solana SOL address from Base58.
    final addrDecBytes = Base58Decoder.decode(addr);

    /// Validate the byte length of the decoded address.
    AddrDecUtils.validateBytesLength(
      addrDecBytes,
      Ed25519KeysConst.pubKeyByteLen,
    );

    /// Return the decoded address as a `List<int>`.
    return addrDecBytes;
  }
}

/// Implementation of the [BlockchainAddressEncoder] for Solana (SOL) addresses.
class SolAddrEncoder implements BlockchainAddressEncoder {
  /// Overrides the base class method to encode a public key as a Solana SOL address.
  @override
  String encodeKey(List<int> pubKey) {
    /// Validate and process the public key as an Ed25519 key.
    final pub = AddrKeyValidator.validateAndGetEd25519Key(pubKey);

    /// Encode the processed public key as a Solana SOL address using Base58.
    final encodedKey = Base58Encoder.encode(pub.compressed.sublist(1));

    /// Return the encoded Solana SOL address as a String.
    return encodedKey;
  }
}
