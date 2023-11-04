import 'package:blockchain_utils/base58/base58.dart';
import 'package:blockchain_utils/bip/address/decoder.dart';
import 'package:blockchain_utils/bip/address/encoder.dart';
import 'package:blockchain_utils/bip/address/p2pkh_addr.dart';
import 'package:blockchain_utils/bip/coin_conf/coins_conf.dart';

/// Implementation of the [BlockchainAddressDecoder] for ripple (XRP) blockchain addresses.
class XrpAddrDecoder implements BlockchainAddressDecoder {
  /// Decodes a Ripple (XRP) blockchain address into its byte representation.
  ///
  /// This method takes a Ripple address as a string and optional keyword arguments,
  /// including "net_ver" specifying the network version byte and "base58_alph" specifying
  /// the Base58 alphabet to use for decoding. It delegates the decoding process to the
  /// [P2PKHAddrDecoder] class, providing the necessary parameters. The resulting byte
  /// representation of the address is returned as a [List<int>].
  ///
  /// Parameters:
  /// - [addr]: The Ripple address as a string to decode.
  /// - [kwargs]: Optional keyword arguments, including "net_ver" and "base58_alph" settings.
  ///
  /// Returns:
  /// A [List<int>] representing the byte data of the decoded Ripple address.
  ///
  /// Example usage:
  /// ```dart
  /// final decoder = XrpAddrDecoder();
  /// final rippleAddress = "r9HcFbTdsuGAAQ14xaNk7zPQGqPt6fPqGT";
  /// final decodedBytes = decoder.decodeAddr(rippleAddress);
  /// ```
  @override
  List<int> decodeAddr(String addr, [Map<String, dynamic> kwargs = const {}]) {
    /// Delegate the decoding process to P2PKHAddrDecoder with specific parameters.
    return P2PKHAddrDecoder().decodeAddr(addr, {
      "net_ver": CoinsConf.ripple.getParam("p2pkh_net_ver"),
      "base58_alph": Base58Alphabets.ripple,
    });
  }
}

/// Implementation of the [BlockchainAddressEncoder] for ripple (XRP) blockchain addresses.
class XrpAddrEncoder implements BlockchainAddressEncoder {
  /// Encodes a Ripple (XRP) public key as a blockchain address.
  ///
  /// This method takes a public key represented as a [List<int>] and optional keyword arguments,
  /// including "net_ver" specifying the network version byte and "base58_alph" specifying
  /// the Base58 alphabet to use for encoding. It delegates the encoding process to the
  /// [P2PKHAddrEncoder] class, providing the necessary parameters. The resulting Ripple
  /// address is returned as a string.
  ///
  /// Parameters:
  /// - [pubKey]: The public key to encode as a Ripple address.
  /// - [kwargs]: Optional keyword arguments, including "net_ver" and "base58_alph" settings.
  ///
  /// Returns:
  /// A Ripple address string representing the encoded public key.
  ///
  /// Example usage:
  /// ```dart
  /// final encoder = XrpAddrEncoder();
  /// final publicKey = List<int>.from([/* public key bytes */]);
  /// final rippleAddress = encoder.encodeKey(publicKey);
  /// ```
  @override
  String encodeKey(List<int> pubKey, [Map<String, dynamic> kwargs = const {}]) {
    return P2PKHAddrEncoder().encodeKey(pubKey, {
      "net_ver": CoinsConf.ripple.getParam("p2pkh_net_ver"),
      "base58_alph": Base58Alphabets.ripple,
    });
  }
}
