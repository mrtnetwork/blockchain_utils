import 'package:blockchain_utils/encoding/base32/base32.dart';
import 'package:blockchain_utils/chain/address/utils/addr_dec_utils.dart';
import 'package:blockchain_utils/chain/address/utils/addr_key_validator.dart';
import 'package:blockchain_utils/chain/address/types/decoder.dart';
import 'package:blockchain_utils/protocol/bip/coin_conf/constant/coins_conf.dart';
import 'package:blockchain_utils/crypto/crypto/keys/ed25519/ed25519.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/chain/address/types/encoder.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// A class that defines constants for Nano (NANO) addresses.
class NanoAddrConst {
  /// The custom Base32 alphabet used for Nano addresses.
  static const String base32Alphabet = "13456789abcdefghijkmnopqrstuwxyz";

  /// The list of padding bytes in decimal format used for Nano address payloads.
  static const List<int> payloadPadDec = [0, 0, 0];

  /// The string representation of padding bytes used for Nano address payloads in Base32 encoding
  static const String payloadPadEnc = "1111";
}

/// A utility class for Nano (NANO) address-related operations.
class _NanoAddrUtils {
  /// Computes the checksum for a Nano address based on the provided public key bytes.
  static BuBytes computeChecksum(List<int> pubKeyBytes) {
    return BuBytes(QuickCrypto.blake2b40Hash(pubKeyBytes).reversed.toList());
  }
}

/// Decodes a Nano address.
class NanoAddrDecoder implements BlockchainAddressDecoder<BuBytes> {
  @override
  BuBytes decodeAddr(String addr) {
    final addrNoPrefix = AddrDecUtils.validateAndRemovePrefix(
      addr,
      AddrKeyValidator.getConfigArg(
        CoinsConf.nano.params.addrPrefix,
        "addrPrefix",
      ),
    );

    // Prepend padding chars so the bit length aligns to a Base32 boundary.
    final addrDecBytes = Base32Decoder.decode(
      NanoAddrConst.payloadPadEnc + addrNoPrefix,
      NanoAddrConst.base32Alphabet,
    );

    AddrDecUtils.validateBytesLength(
      addrDecBytes,
      Ed25519KeysConst.pubKeyByteLen +
          QuickCrypto.blake2b40DigestSize +
          NanoAddrConst.payloadPadDec.length,
    );

    final decode = AddrDecUtils.splitPartsByChecksum(
      addrDecBytes.sublist(NanoAddrConst.payloadPadDec.length),
      QuickCrypto.blake2b40DigestSize,
    );

    final pubKeyBytes = decode.$1;
    final checksumBytes = decode.$2;

    AddrDecUtils.validateChecksum(
      pubKeyBytes,
      checksumBytes,
      _NanoAddrUtils.computeChecksum,
    );

    return BuBytes(pubKeyBytes);
  }
}

/// Encodes a Nano address.
class NanoAddrEncoder implements BlockchainAddressEncoder {
  @override
  String encodeKey(List<int> pubKey) {
    final pubKeyBytes = AddrKeyValidator.validateAndGetEd25519Blake2bKeyBytes(
      pubKey,
    );
    final checksumBytes = _NanoAddrUtils.computeChecksum(pubKeyBytes);

    final payloadBytes = [
      ...NanoAddrConst.payloadPadDec,
      ...pubKeyBytes,
      ...checksumBytes,
    ];

    final b32Enc = Base32Encoder.encodeNoPaddingBytes(
      payloadBytes,
      NanoAddrConst.base32Alphabet,
    );
    return AddrKeyValidator.getConfigArg(
          CoinsConf.nano.params.addrPrefix,
          "addrPrefix",
        ) +
        b32Enc.substring(NanoAddrConst.payloadPadEnc.length);
  }
}
