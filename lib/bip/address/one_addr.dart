import 'package:blockchain_utils/bech32/bech32_base.dart';
import 'package:blockchain_utils/bip/address/eth_addr.dart';
import 'package:blockchain_utils/bip/address/decoder.dart';
import 'package:blockchain_utils/bip/address/encoder.dart';
import 'package:blockchain_utils/bip/coin_conf/constant/coins_conf.dart';
import 'package:blockchain_utils/utils/utils.dart';

/// Implementation of the [BlockchainAddressDecoder] for Harmony (ONE) addresses.
class OneAddrDecoder implements BlockchainAddressDecoder {
  /// Overrides the base class method to decode a Harmony ONE address.
  ///
  /// This method decodes a Harmony ONE address from the provided input string using Bech32 encoding.
  /// It expects an optional map of keyword arguments for custom behavior, but specifically, it skips
  /// the checksum encoding validation. The address Human-Readable Part (HRP) is retrieved from the
  /// Harmony ONE configuration. The method first decodes the Bech32 address, and then decodes it again
  /// as an Ethereum address with a custom prefix. The result is returned as a `List<int>` containing
  /// the decoded Ethereum address bytes.
  ///
  /// Parameters:
  ///   - addr: The Harmony ONE address to be decoded.
  ///   - kwargs: Optional keyword arguments (with 'skip_chksum_enc' for skipping checksum encoding).
  ///
  /// Returns:
  ///   A `List<int>` containing the decoded Ethereum address bytes derived from the Harmony ONE address.
  @override
  List<int> decodeAddr(String addr, [Map<String, dynamic> kwargs = const {}]) {
    final List<int> addrDecBytes =
        Bech32Decoder.decode(CoinsConf.harmonyOne.params.addrHrp!, addr);

    /// Decode the address again as an Ethereum address with a custom prefix.
    return EthAddrDecoder().decodeAddr(
        CoinsConf.ethereum.params.addrPrefix! +
            BytesUtils.toHexString(addrDecBytes),
        {"skip_chksum_enc": true});
  }
}

/// Implementation of the [BlockchainAddressEncoder] for Harmony (ONE) addresses.
class OneAddrEncoder implements BlockchainAddressEncoder {
  /// Overrides the base class method to encode a public key as a Harmony ONE address using Bech32 encoding.
  ///
  /// This method encodes a public key as a Harmony ONE address using Bech32 encoding. It expects an Ethereum address
  /// as input, encodes it as an Ethereum address without a '0x' prefix, and then encodes it as a Harmony ONE address
  /// using the ONE configuration's Human-Readable Part (HRP). The result is returned as a String representing the
  /// Bech32-encoded Harmony ONE address.
  ///
  /// Parameters:
  ///   - pubKey: The Ethereum address in the form of a `List<int>`.
  ///   - kwargs: Optional keyword arguments.
  ///
  /// Returns:
  ///   A String representing the Bech32-encoded Harmony ONE address derived from the provided Ethereum address.
  @override
  String encodeKey(List<int> pubKey, [Map<String, dynamic> kwargs = const {}]) {
    /// Encode the Ethereum address without the '0x' prefix.
    final String ethAddr =
        StringUtils.strip0x(EthAddrEncoder().encodeKey(pubKey));

    /// Encode the Ethereum address as a Harmony ONE address using Bech32 encoding.
    return Bech32Encoder.encode(
      CoinsConf.harmonyOne.params.addrHrp!,
      BytesUtils.fromHexString(ethAddr),
    );
  }
}
