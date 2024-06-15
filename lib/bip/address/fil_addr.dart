import 'package:blockchain_utils/base32/base32.dart';
import 'package:blockchain_utils/bip/address/addr_dec_utils.dart';
import 'package:blockchain_utils/bip/address/addr_key_validator.dart';
import 'package:blockchain_utils/bip/address/decoder.dart';
import 'package:blockchain_utils/bip/address/encoder.dart';
import 'package:blockchain_utils/bip/coin_conf/coins_conf.dart';
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
  ///
  /// This method computes the checksum for a given Filecoin address by combining
  /// the address type byte and the provided public key hash and then applying the
  /// Blake2b-32 hashing algorithm.
  ///
  /// Parameters:
  ///   - pubKeyHash: The public key hash of the address as a List<int>.
  ///   - addrType: The address type (e.g., secp256k1 or bls).
  ///
  /// Returns:
  ///   A List<int> representing the computed checksum.
  static List<int> computeChecksum(
      List<int> pubKeyHash, FillAddrTypes addrType) {
    List<int> addrTypeByte = List<int>.from([addrType.value]);
    return QuickCrypto.blake2b32Hash(
        List<int>.from([...addrTypeByte, ...pubKeyHash]));
  }

  /// Decodes a Filecoin address to its constituent parts.
  ///
  /// This method decodes a Filecoin address, validates its format, and extracts the
  /// address type, public key hash, and checksum. It checks the address type against
  /// the provided `addrType` and ensures the address's length and checksum are valid.
  ///
  /// Parameters:
  ///   - addr: The Filecoin address as a string.
  ///   - addrType: The expected address type (e.g., secp256k1 or bls).
  ///
  /// Returns:
  ///   A List<int> representing the decoded public key hash.
  ///
  /// Throws:
  ///   - ArgumentException if the address type doesn't match the expected type.
  ///   - ArgumentException if the address format, length, or checksum is invalid.
  static List<int> decodeAddr(String addr, FillAddrTypes addrType) {
    String addrNoPrefix = AddrDecUtils.validateAndRemovePrefix(
        addr, CoinsConf.filecoin.params.addrPrefix!);
    int addrTypeGot = addrNoPrefix[0].codeUnits.first - "0".codeUnits.first;
    if (addrType.value != addrTypeGot) {
      throw AddressConverterException(
          "Invalid address type (expected ${addrType.value}, got $addrTypeGot)");
    }
    List<int> addrDecBytes = Base32Decoder.decode(
        addrNoPrefix.substring(1), FilAddrConst.base32Alphabet);
    AddrDecUtils.validateBytesLength(addrDecBytes,
        QuickCrypto.blake2b160DigestSize + QuickCrypto.blake2b32DigestSize);

    final split = AddrDecUtils.splitPartsByChecksum(
        addrDecBytes, QuickCrypto.blake2b32DigestSize);
    AddrDecUtils.validateChecksum(split.item1, split.item2,
        (pubKeyBytes) => computeChecksum(pubKeyBytes, addrType));

    return split.item1;
  }

  /// Encodes a Filecoin address based on its constituent parts.
  ///
  /// This method takes the public key bytes and the address type and encodes them
  /// into a Filecoin address. It computes the public key hash, adds the appropriate
  /// address type byte, and appends the checksum. The resulting address is encoded
  /// in base32 using the specified alphabet.
  ///
  /// Parameters:
  ///   - pubKeyBytes: The public key bytes of the address as a List<int>.
  ///   - addrType: The address type (e.g., secp256k1 or bls).
  ///
  /// Returns:
  ///   A string representing the encoded Filecoin address.
  static String encodeKeyBytes(List<int> pubKeyBytes, FillAddrTypes addrType) {
    String addrTypeStr = String.fromCharCode(addrType.value + 48);
    List<int> pubKeyHashBytes = QuickCrypto.blake2b160Hash(pubKeyBytes);
    List<int> checksumBytes = computeChecksum(pubKeyHashBytes, addrType);
    final bytesWithChecksum = List<int>.from(pubKeyHashBytes + checksumBytes);

    String b32Enc = Base32Encoder.encodeNoPaddingBytes(
        bytesWithChecksum, FilAddrConst.base32Alphabet);
    return CoinsConf.filecoin.params.addrPrefix! + addrTypeStr + b32Enc;
  }
}

/// Implementation of the [BlockchainAddressDecoder] for Filecoin (FIL) addresses.
class FilSecp256k1AddrDecoder implements BlockchainAddressDecoder {
  /// Decodes a Filecoin address of the specified address type.
  ///
  /// This method decodes a Filecoin address by calling the internal utility method
  /// `_FilAddrUtils.decodeAddr`. It expects the address type to be provided as
  /// `FillAddrTypes.secp256k1`. The decoded address is returned as a List<int>.
  ///
  /// Parameters:
  ///   - addr: The Filecoin address to decode as a string.
  ///
  /// Returns:
  ///   A List<int> representing the decoded Filecoin address
  @override
  List<int> decodeAddr(String addr, [Map<String, dynamic> kwargs = const {}]) {
    return _FilAddrUtils.decodeAddr(addr, FillAddrTypes.secp256k1);
  }
}

/// Implementation of the [BlockchainAddressEncoder] for Filecoin (FIL) addresses.
class FilSecp256k1AddrEncoder implements BlockchainAddressEncoder {
  /// Encodes a Filecoin address for a public key using the secp256k1 address type.
  ///
  /// This method takes a public key represented as a List<int>, validates it as a
  /// secp256k1 public key, converts it to raw uncompressed bytes, and then encodes
  /// a Filecoin address of the secp256k1 address type. The resulting address is
  /// returned as a string.
  ///
  /// Parameters:
  ///   - pubKey: The public key to encode as a List<int>.
  ///
  /// Returns:
  ///   A string representing the encoded Filecoin address.
  @override
  String encodeKey(List<int> pubKey, [Map<String, dynamic> kwargs = const {}]) {
    final pubkey = AddrKeyValidator.validateAndGetSecp256k1Key(pubKey);
    final tobytes = pubkey.uncompressed;
    return _FilAddrUtils.encodeKeyBytes(tobytes, FillAddrTypes.secp256k1);
  }
}
