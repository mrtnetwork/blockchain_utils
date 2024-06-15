import 'package:blockchain_utils/bech32/bech32_base.dart';
import 'package:blockchain_utils/bip/address/addr_dec_utils.dart';
import 'package:blockchain_utils/bip/address/eth_addr.dart';
import 'package:blockchain_utils/bip/address/decoder.dart';
import 'package:blockchain_utils/bip/address/encoder.dart';
import 'package:blockchain_utils/bip/coin_conf/coins_conf.dart';
import 'package:blockchain_utils/utils/utils.dart';

/// Implementation of the [BlockchainAddressDecoder] for INJ (Injective Protocol) addresses.
class InjAddrDecoder implements BlockchainAddressDecoder {
  /// Overrides the base class method to decode an INJ (Injective Protocol) address.
  ///
  /// This method decodes an INJ address from the provided input string. It expects an optional map of
  /// keyword arguments for custom INJ address parameters. The method performs the following steps:
  /// 1. Decodes the Bech32-encoded address using the INJ address human-readable part (hrp).
  /// 2. Validates the length of the decoded address.
  /// 3. Returns the decoded address as a List<int>.
  ///
  /// Parameters:
  ///   - addr: The INJ address to be decoded as a string.
  ///   - kwargs: Optional keyword arguments for custom INJ address parameters (not used in this implementation).
  ///
  /// Returns:
  ///   A List<int> containing the decoded INJ address.
  @override
  List<int> decodeAddr(String addr, [Map<String, dynamic> kwargs = const {}]) {
    /// Decode the Bech32-encoded address using the INJ address human-readable part (hrp).
    final addrDecBytes = Bech32Decoder.decode(
      CoinsConf.injective.params.addrHrp!,
      addr,
    );

    /// Validate the length of the decoded address.
    AddrDecUtils.validateBytesLength(
      addrDecBytes,
      EthAddrConst.addrLen ~/ 2,
    );
    return addrDecBytes;
  }
}

/// Implementation of the [BlockchainAddressEncoder] for INJ (Injective Protocol) addresses.
class InjAddrEncoder implements BlockchainAddressEncoder {
  /// Overrides the base class method to encode a public key as an INJ (Injective Protocol) address.
  ///
  /// This method encodes a public key as an INJ address. It expects the public key as a List<int>
  /// and returns the INJ address as a string. The encoding process involves:
  /// 1. Encoding the public key as an Ethereum (ETH) address using EthAddrEncoder.
  /// 2. Encoding the ETH address using the INJ address human-readable part (hrp).
  ///
  /// Parameters:
  ///   - pubKey: The public key to be encoded as an INJ address in the form of a List<int>.
  ///   - kwargs: Optional keyword arguments (not used in this implementation).
  ///
  /// Returns:
  ///   A string representing the INJ address corresponding to the provided public key.
  @override
  String encodeKey(List<int> pubKey, [Map<String, dynamic> kwargs = const {}]) {
    /// Encode the public key as an Ethereum (ETH) address.
    final ethAddr = EthAddrEncoder().encodeKey(pubKey);

    /// Encode the ETH address using the INJ address human-readable part (hrp).
    return Bech32Encoder.encode(
        CoinsConf.injective.params.addrHrp!, BytesUtils.fromHexString(ethAddr));
  }
}
