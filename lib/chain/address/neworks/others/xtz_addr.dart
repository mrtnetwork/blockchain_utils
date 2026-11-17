import 'package:blockchain_utils/encoding/base58/base58.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/chain/address/utils/addr_key_validator.dart';
import 'package:blockchain_utils/chain/address/types/decoder.dart';
import 'package:blockchain_utils/chain/address/types/encoder.dart';
import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/binary/src/utils.dart';
import 'package:blockchain_utils/chain/address/utils/addr_dec_utils.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Tezos base58 address prefixes (implicit, contract, smart rollup, zk rollup).
///
/// Hash payload is always 20 bytes (Blake2b-160) after the version prefix.
/// Most prefixes are 3 bytes; [epx1] (ZK rollup) is **4 bytes**.
///
/// Wire `public_key_hash` tags (implicit): tz1=0, tz2=1, tz3=2, tz4=3, tz5=4.
enum XtzAddrPrefixes {
  tz1(0, 0, [0x06, 0xa1, 0x9f]),
  tz2(1, 1, [0x06, 0xa1, 0xa1]),
  tz3(2, 2, [0x06, 0xa1, 0xa4]),
  tz4(3, 3, [0x06, 0xa1, 0xa6]),

  /// ML-DSA-44 (post-quantum) public key hash — base58 `tz5`.
  /// Prefix `\006\161\169`; wire PKH tag `0x04`.
  /// Feature-flagged (`tz5_account_enable`); cannot be a delegate / consensus key.
  tz5(4, 4, [0x06, 0xa1, 0xa9]),
  kt1(5, null, [0x02, 0x5a, 0x79]),
  sr1(6, null, [0x06, 0x7c, 0x75]),

  /// ZK rollup (Epoxy) address — base58 prefix `epx1`.
  /// Prefix bytes verified against `epx16D48wS8mtjMzS6vWCXzQi7SJcXuRA378z`.
  epx1(7, null, [0x01, 0x17, 0xe0, 0x7d]);

  final List<int> prefix;
  final int value;
  bool get isImplicit => pubKeyTag != null;
  final int? pubKeyTag;

  const XtzAddrPrefixes(this.value, this.pubKeyTag, this.prefix);

  int get prefixLen => prefix.length;

  static XtzAddrPrefixes fromPrefix(List<int>? value) {
    return values.firstWhere(
      (e) => BytesUtils.bytesEqual(e.prefix, value),
      orElse:
          () =>
              throw CoreErrors.addressBytesValidationFailed(
                reason: 'Invalid XTZ address type prefix.',
              ),
    );
  }

  static XtzAddrPrefixes fromAddrBytes(List<int> addrDecBytes) {
    if (addrDecBytes.length == QuickCrypto.blake2b160DigestSize + 1) {
      return XtzAddrPrefixes.values.firstWhere(
        (e) => e.pubKeyTag == addrDecBytes[0],
        orElse:
            () =>
                throw CoreErrors.addressBytesValidationFailed(
                  reason: 'Invalid XTZ address type prefix.',
                ),
      );
    }
    // Longest match first so epx1 (4) wins over any accidental 3-byte clash.
    final ordered = [...values]
      ..sort((a, b) => b.prefixLen.compareTo(a.prefixLen));
    for (final t in ordered) {
      if (addrDecBytes.length >= t.prefixLen &&
          BytesUtils.bytesEqual(
            t.prefix,
            addrDecBytes.sublist(0, t.prefixLen),
          )) {
        return t;
      }
    }
    throw CoreErrors.addressBytesValidationFailed(
      reason: 'Invalid XTZ address type prefix.',
    );
  }

  static XtzAddrPrefixes fromValue(int? value) {
    return values.firstWhere(
      (e) => e.value == value,
      orElse:
          () =>
              throw CoreErrors.addressValidationFailed(
                reason: "Invalid XTZ address type value.",
                details: {"got": value?.toString()},
              ),
    );
  }
}

/// Decoded Tezos address: 20-byte hash + its prefix type.
class XtzAddrDecodedAddress {
  final BuBytes bytes;
  final XtzAddrPrefixes type;

  XtzAddrDecodedAddress({required List<int> bytes, required this.type})
    : bytes =
          (bytes.length == QuickCrypto.blake2b160DigestSize
                  ? bytes
                  : throw CoreErrors.addressBytesValidationFailed(
                    reason: "Invalid tezos address bytes length.",
                    details: {
                      "expected": QuickCrypto.blake2b160DigestSize.toString(),
                      "got": bytes.length.toString(),
                    },
                  ))
              .asImmutableBytes;
}

/// Encoded Tezos address: base58 string, its prefix type, and hash bytes.
class XtzAddrEncodedAddress {
  final String address;
  final XtzAddrPrefixes type;
  final BuBytes hashBytes;
  XtzAddrEncodedAddress({
    required this.address,
    required this.type,
    required List<int> hashBytes,
  }) : hashBytes = hashBytes.asImmutableBytes;
}

/// Decodes a Tezos (XTZ) address.
class XtzAddrDecoder implements BlockchainAddressDecoder<BuBytes> {
  /// Decodes [addr], returning the full result (hash bytes + prefix type).
  XtzAddrDecodedAddress decode(String addr, {XtzAddrPrefixes? addressPrefix}) {
    final addrDecBytes = Base58Decoder.decodeWithChecksum(addr);
    final t = XtzAddrPrefixes.fromAddrBytes(addrDecBytes);
    final expectedLen = t.prefixLen + QuickCrypto.blake2b160DigestSize;
    AddrDecUtils.validateBytesLength(addrDecBytes, expectedLen);
    final hashBytes = AddrDecUtils.validateAndRemovePrefixBytes(
      addrDecBytes,
      t.prefix,
    );
    if (addressPrefix != null && t != addressPrefix) {
      throw CoreErrors.addressValidationFailed(
        reason: 'Address type mismatch.',
        details: {'type': t.name, 'expected': addressPrefix.name},
      );
    }
    return XtzAddrDecodedAddress(bytes: hashBytes, type: t);
  }

  @override
  BuBytes decodeAddr(String addr, {XtzAddrPrefixes? addressPrefix}) {
    return decode(addr, addressPrefix: addressPrefix).bytes;
  }
}

/// Encodes a Tezos (XTZ) address.
class XtzAddrEncoder implements BlockchainAddressEncoder {
  /// Encodes an already-hashed address (or re-encodes with a new prefix).
  XtzAddrEncodedAddress encode(
    List<int> hash, {
    XtzAddrPrefixes? addressPrefix,
  }) {
    if (hash.length != QuickCrypto.blake2b160DigestSize) {
      final type = XtzAddrPrefixes.fromAddrBytes(hash);
      if (addressPrefix != null && type != addressPrefix) {
        throw CoreErrors.addressValidationFailed(
          reason: 'Type mismatch.',
          details: {'type': type.name},
        );
      }
      hash = hash.sublist(hash.length - QuickCrypto.blake2b160DigestSize);
      addressPrefix = type;
    }
    addressPrefix = AddrKeyValidator.getAddrArg<XtzAddrPrefixes>(
      addressPrefix,
      'addressPrefix',
    );
    AddrDecUtils.validateBytesLength(hash, QuickCrypto.blake2b160DigestSize);
    return XtzAddrEncodedAddress(
      address: Base58Encoder.encodeWithChecksum([
        ...addressPrefix.prefix,
        ...hash,
      ]),
      type: addressPrefix,
      hashBytes: hash,
    );
  }

  /// Encode a 20-byte hash as a ZK rollup (`epx1…`) address.
  XtzAddrEncodedAddress encodeZkRollup(List<int> hash20) {
    return encode(hash20, addressPrefix: XtzAddrPrefixes.epx1);
  }

  /// Encode a 20-byte hash as a smart rollup (`sr1…`) address.
  XtzAddrEncodedAddress encodeSmartRollup(List<int> hash20) {
    return encode(hash20, addressPrefix: XtzAddrPrefixes.sr1);
  }

  @override
  String encodeKey(List<int> pubKey, {XtzAddrPrefixes? addressPrefix}) {
    addressPrefix = AddrKeyValidator.getAddrArg<XtzAddrPrefixes>(
      addressPrefix,
      'addressPrefix',
    );
    if (!addressPrefix.isImplicit) {
      throw CoreErrors.addressValidationFailed(
        reason:
            'Cannot derive ${addressPrefix.name} from a public key '
            '(only tz1–tz4).',
      );
    }
    final List<int> keyBytes;
    switch (addressPrefix) {
      case XtzAddrPrefixes.tz1:
        keyBytes = AddrKeyValidator.validateAndGetEd25519KeyBytes(pubKey);
      case XtzAddrPrefixes.tz2:
        keyBytes = AddrKeyValidator.validateAndGetSecp256k1Key(
          pubKey,
        ).toBytes(mode: CryptoKeyEncoding.base);
      case XtzAddrPrefixes.tz3:
        keyBytes = AddrKeyValidator.validateAndGetNist256p1Key(
          pubKey,
        ).toBytes(mode: CryptoKeyEncoding.base);
      case XtzAddrPrefixes.tz4:
        keyBytes = AddrKeyValidator.validateAndGetBlsG1PublicKey(
          pubKey,
        ).toBytes(mode: CryptoKeyEncoding.base);
      case XtzAddrPrefixes.tz5:
        keyBytes = AddrKeyValidator.validateAndGetMLDSA44PubKey(
          pubKey,
        ).toBytes(mode: CryptoKeyEncoding.base);
      case XtzAddrPrefixes.kt1:
      case XtzAddrPrefixes.sr1:
      case XtzAddrPrefixes.epx1:
        throw CoreErrors.addressValidationFailed(reason: 'Unreachable');
    }
    final blakeBytes = QuickCrypto.blake2b160Hash(keyBytes);
    return Base58Encoder.encodeWithChecksum([
      ...addressPrefix.prefix,
      ...blakeBytes,
    ]);
  }
}
