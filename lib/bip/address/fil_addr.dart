import 'package:blockchain_utils/base32/base32.dart';
import 'package:blockchain_utils/bip/address/addr_dec_utils.dart';
import 'package:blockchain_utils/bip/address/addr_key_validator.dart';
import 'package:blockchain_utils/bip/address/decoder.dart';
import 'package:blockchain_utils/bip/address/encoder.dart';
import 'package:blockchain_utils/bip/coin_conf/constant/coins_conf.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'exception/exception.dart';

/// Enum representing different address types for Filecoin (FIL) addresses.
class FillAddrTypes {
  /// Address type using the secp256k1 curve.
  static const FillAddrTypes secp256k1 = FillAddrTypes._(1);

  /// Address type using the bls curve.
  static const FillAddrTypes bls = FillAddrTypes._(3);

  /// The numerical value associated with each address type.
  final int value;

  /// Constructor to initialize each address type with its corresponding value.
  const FillAddrTypes._(this.value);
}

/// Constants related to Filecoin (FIL) addresses.
class FilAddrConst {
  /// The base32 alphabet used for encoding Filecoin addresses.
  static const String base32Alphabet = "abcdefghijklmnopqrstuvwxyz234567";
}

/// Utility class for handling Filecoin (FIL) addresses.
class _FilAddrUtils {
  /// Computes the checksum for a Filecoin address based on the address type.
  static List<int> computeChecksum(
    List<int> pubKeyHash,
    FillAddrTypes addrType,
  ) {
    final List<int> addrTypeByte = [addrType.value];
    return QuickCrypto.blake2b32Hash([...addrTypeByte, ...pubKeyHash]);
  }

  /// Decodes a Filecoin address to its constituent parts.
  static List<int> decodeAddr(String addr, FillAddrTypes addrType) {
    final String addrNoPrefix = AddrDecUtils.validateAndRemovePrefix(
      addr,
      AddrKeyValidator.getConfigArg(
        CoinsConf.filecoin.params.addrPrefix,
        "addrPrefix",
      ),
    );
    final int addrTypeGot =
        addrNoPrefix[0].codeUnits.first - "0".codeUnits.first;
    if (addrType.value != addrTypeGot) {
      throw AddressConverterException.addressValidationFailed(
        reason: "Invalid address type.",
      );
    }
    final List<int> addrDecBytes = Base32Decoder.decode(
      addrNoPrefix.substring(1),
      FilAddrConst.base32Alphabet,
    );
    AddrDecUtils.validateBytesLength(
      addrDecBytes,
      QuickCrypto.blake2b160DigestSize + QuickCrypto.blake2b32DigestSize,
    );

    final split = AddrDecUtils.splitPartsByChecksum(
      addrDecBytes,
      QuickCrypto.blake2b32DigestSize,
    );
    AddrDecUtils.validateChecksum(
      split.$1,
      split.$2,
      (pubKeyBytes) => computeChecksum(pubKeyBytes, addrType),
    );

    return split.$1;
  }

  /// Encodes a Filecoin address based on its constituent parts.
  static String encodeKeyBytes(List<int> pubKeyBytes, FillAddrTypes addrType) {
    final String addrTypeStr = String.fromCharCode(addrType.value + 48);
    final List<int> pubKeyHashBytes = QuickCrypto.blake2b160Hash(pubKeyBytes);
    final List<int> checksumBytes = computeChecksum(pubKeyHashBytes, addrType);
    final bytesWithChecksum = pubKeyHashBytes + checksumBytes;

    final String b32Enc = Base32Encoder.encodeNoPaddingBytes(
      bytesWithChecksum,
      FilAddrConst.base32Alphabet,
    );
    return AddrKeyValidator.getConfigArg(
          CoinsConf.filecoin.params.addrPrefix,
          "addrPrefix",
        ) +
        addrTypeStr +
        b32Enc;
  }
}

/// Implementation of the [BlockchainAddressDecoder] for Filecoin (FIL) addresses.
class FilSecp256k1AddrDecoder implements BlockchainAddressDecoder<List<int>> {
  /// Decodes a Filecoin address of the specified address type.
  @override
  List<int> decodeAddr(String addr) {
    return _FilAddrUtils.decodeAddr(addr, FillAddrTypes.secp256k1);
  }
}

/// Implementation of the [BlockchainAddressEncoder] for Filecoin (FIL) addresses.
class FilSecp256k1AddrEncoder implements BlockchainAddressEncoder {
  /// Encodes a Filecoin address for a public key using the secp256k1 address type.
  @override
  String encodeKey(List<int> pubKey) {
    final pubkey = AddrKeyValidator.validateAndGetSecp256k1Key(pubKey);
    final tobytes = pubkey.uncompressed;
    return _FilAddrUtils.encodeKeyBytes(tobytes, FillAddrTypes.secp256k1);
  }
}
