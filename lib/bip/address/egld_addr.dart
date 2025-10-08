import 'package:blockchain_utils/bech32/bech32_base.dart';
import 'package:blockchain_utils/bip/address/addr_dec_utils.dart';
import 'package:blockchain_utils/bip/address/addr_key_validator.dart';
import 'package:blockchain_utils/bip/address/decoder.dart';
import 'package:blockchain_utils/bip/coin_conf/constant/coins_conf.dart';
import 'package:blockchain_utils/bip/ecc/keys/ed25519_keys.dart';
import 'encoder.dart';

/// Implementation of the [BlockchainAddressDecoder] for Egld (Elrond) address.
class EgldAddrDecoder implements BlockchainAddressDecoder {
  /// Overrides the method to decode an Egld (Elrond) address from the provided string [addr].
  ///
  /// [addr]: The string representation of the Egld address.
  /// [kwargs]: A map of optional keyword arguments.
  ///
  /// This method decodes the Egld address by validating and removing the prefix and verifying
  /// the Bech32 checksum.
  ///
  /// Returns a List containing the decoded Egld address.
  @override
  List<int> decodeAddr(String addr, [Map<String, dynamic> kwargs = const {}]) {
    /// Decode the Bech32 address with the specified Human-Readable Part (HRP)
    final addrDecBytes =
        Bech32Decoder.decode(CoinsConf.elrond.params.addrHrp!, addr);

    /// Validate the length of the decoded address
    AddrDecUtils.validateBytesLength(
      addrDecBytes,
      Ed25519KeysConst.pubKeyByteLen,
    );

    return List<int>.from(addrDecBytes);
  }
}

/// Implementation of the [BlockchainAddressEncoder] for Egld (Elrond) address.
class EgldAddrEncoder implements BlockchainAddressEncoder {
  /// Overrides the method to encode an Egld (Elrond) address based on the provided [pubKey].
  ///
  /// [pubKey]: The List representing the public key to be encoded.
  /// [kwargs]: A map of optional keyword arguments.
  ///
  /// This method encodes the Egld address by using the specified Human-Readable Part (HRP)
  /// and converting the raw compressed public key to bytes.
  ///
  /// Returns the string representation of the encoded Egld address.
  @override
  String encodeKey(List<int> pubKey, [Map<String, dynamic> kwargs = const {}]) {
    /// Validate and retrieve the Ed25519 public key
    final pubKeyObj = AddrKeyValidator.validateAndGetEd25519Key(pubKey);

    /// Encode the Egld address using the provided HRP and the raw compressed public key
    return Bech32Encoder.encode(
      CoinsConf.elrond.params.addrHrp!,
      pubKeyObj.compressed.sublist(1),
    );
  }
}
