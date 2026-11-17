import 'package:blockchain_utils/encoding/base64/base64.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/chain/address/utils/addr_key_validator.dart';
import 'package:blockchain_utils/chain/address/types/decoder.dart';
import 'package:blockchain_utils/chain/address/types/encoder.dart';
import 'package:blockchain_utils/crypto/crypto/checksum/crc16/crc16.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/utils/binary/src/utils.dart';
import 'package:blockchain_utils/utils/binary/src/binary_operation.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Result of decoding a TON address: workchain, hash, and address flags.
class DecodeAddressResult {
  final int workchain;
  final BuBytes hash;
  DecodeAddressResult({
    required this.workchain,
    required List<int> hash,
    required List<FriendlyAddressFlags> flags,
    this.isUrlSafe = false,
    this.isPadded = true,
  }) : hash = hash.asImmutableBytes,
       flags = flags.immutable;
  final List<FriendlyAddressFlags> flags;
  final bool isUrlSafe;
  final bool isPadded;
  bool get isFriendly => flags.isNotEmpty;
  bool get isTestOnly => flags.contains(FriendlyAddressFlags.test);
  bool get isBounceable => flags.contains(FriendlyAddressFlags.bounceable);
}

enum FriendlyAddressFlags {
  bounceable("bounceable", 0x11),
  nonBounceable("nonBounceable", 0x51),
  test("test", 0x80);

  const FriendlyAddressFlags(this.name, this.flag);
  final String name;
  final int flag;
  static FriendlyAddressFlags fromFlag(int? flag) {
    return values.firstWhere(
      (e) => e.flag == flag,
      orElse:
          () =>
              throw CoreErrors.addressValidationFailed(
                reason: "Invalid TON address flags.",
                details: {"got": flag?.toString()},
              ),
    );
  }
}

/// TON address constants.
class _TonAddressConst {
  static const int friendlyAddressLength = 48;
  static const int addressHashLength = 32;
  static const int friendlyAddressBytesLength = 36;
}

/// Internal TON address helpers.
class TonAddressUtils {
  /// Whether [source] looks like a "friendly" (base64) TON address.
  static bool isFriendly(String source) {
    final RegExp regExp = RegExp(r'[A-Za-z0-9+/_-]+');
    if (source.length == _TonAddressConst.friendlyAddressLength &&
        regExp.hasMatch(source)) {
      return true;
    }
    return false;
  }

  /// Whether [source] looks like a raw ("workchain:hex") TON address.
  static bool isRaw(String source) {
    return tryRawAddress(source) != null;
  }

  /// Parses a raw address, or null if it isn't one.
  static DecodeAddressResult? tryRawAddress(String address) {
    try {
      final parts = address.split(':');
      if (parts.length != 2) return null;
      final int? workChain = int.tryParse(parts[0]);
      if (workChain == null) return null;
      final hash = BytesUtils.fromHexString(parts[1]);
      return DecodeAddressResult(hash: hash, workchain: workChain, flags: []);
    } catch (_) {
      return null;
    }
  }

  /// Decodes a "friendly" (base64 + CRC16) TON address.
  static DecodeAddressResult fromFriendlyAddress(String address) {
    final decode = B64Decoder.decodeWithInfo(
      address,
      urlSafe: true,
      validatePadding: false,
    );
    final data = decode.data;
    // Expect: 1 byte tag + 1 byte workchain + 32 bytes hash + 2 byte crc.
    if (data.length != _TonAddressConst.friendlyAddressBytesLength) {
      throw CoreErrors.addressValidationFailed(
        reason: "Invalid address bytes.",
        details: {"length": data.length.toString()},
      );
    }

    final addr = data.sublist(0, 34);
    final crc = data.sublist(34, 36);
    final calcedCrc = Crc16.quickIntDigest(addr);
    if (!BytesUtils.bytesEqual(crc, calcedCrc)) {
      throw CoreErrors.addressValidationFailed(
        reason: "Invalid address checksum.",
        details: {"expected": calcedCrc.toString(), "checksum": crc.toString()},
      );
    }
    final List<FriendlyAddressFlags> flags = [];
    int tag = addr[0];
    if ((tag & FriendlyAddressFlags.test.flag) != 0) {
      flags.add(FriendlyAddressFlags.test);
      tag ^= FriendlyAddressFlags.test.flag;
    }
    if (tag == FriendlyAddressFlags.bounceable.flag) {
      flags.add(FriendlyAddressFlags.bounceable);
    } else if (tag == FriendlyAddressFlags.nonBounceable.flag) {
      flags.add(FriendlyAddressFlags.nonBounceable);
    } else {
      throw CoreErrors.addressValidationFailed(
        reason: "Invalid friendly address flags.",
        details: {"tag": tag.toString()},
      );
    }
    int? workchain;
    if (addr[1] == BinaryOps.mask8) {
      workchain = -1;
    } else {
      workchain = addr[1];
    }
    final hashPart = addr.sublist(2, 34);
    return DecodeAddressResult(
      workchain: workchain,
      hash: hashPart,
      flags: flags,
      isUrlSafe: decode.isUrlSafe,
      isPadded: decode.isPadded,
    );
  }

  /// Decodes a raw ("workchain:hex") TON address.
  static DecodeAddressResult fromRawAddress(String address) {
    try {
      final parts = address.split(':');
      final int workChain = int.parse(parts[0]);
      final hash = BytesUtils.fromHexString(parts[1]);
      return DecodeAddressResult(hash: hash, workchain: workChain, flags: []);
    } catch (e) {
      throw CoreErrors.addressValidationFailed(details: {"address": address});
    }
  }

  /// Encodes a workchain + hash as a "friendly" TON address.
  static String encodeAddress({
    required List<int> hash,
    required int workChain,
    bool bounceable = true,
    bool testOnly = false,
    bool urlSafe = false,
    bool noPadding = false,
  }) {
    hash = validateAddressHash(hash);
    int tag =
        bounceable
            ? FriendlyAddressFlags.bounceable.flag
            : FriendlyAddressFlags.nonBounceable.flag;
    if (testOnly) {
      tag |= FriendlyAddressFlags.test.flag;
    }
    final List<int> addr = List<int>.unmodifiable([
      tag,
      workChain & BinaryOps.mask8,
      ...hash,
    ]);
    final addrBytes = [...addr, ...Crc16.quickIntDigest(addr)];
    return B64Encoder.encode(addrBytes, urlSafe: urlSafe, noPadding: noPadding);
  }

  /// Decodes either a "friendly" or raw TON address.
  static DecodeAddressResult decodeAddress(String address) {
    if (isFriendly(address)) {
      return fromFriendlyAddress(address);
    } else if (tryRawAddress(address) case DecodeAddressResult result) {
      return result;
    } else {
      throw CoreErrors.addressValidationFailed(details: {"address": address});
    }
  }

  /// Validates the address hash is the expected length.
  static BuBytes validateAddressHash(List<int> bytes) {
    if (bytes.length != _TonAddressConst.addressHashLength) {
      throw CoreErrors.addressBytesValidationFailed(
        reason: "Invalid address bytes.",
        details: {
          "expected": _TonAddressConst.addressHashLength.toString(),
          "length": bytes.length.toString(),
        },
      );
    }
    return bytes.asImmutableBytes;
  }

  /// Encodes a workchain + hash as a raw ("workchain:hex") address.
  static String encodeRawAddress(int workchain, List<int> bytes) {
    final data = validateAddressHash(bytes);
    return BytesUtils.toHexString(data, prefix: '$workchain:');
  }
}

/// Decodes a TON address.
class TonAddrDecoder implements BlockchainAddressDecoder<BuBytes> {
  @override
  BuBytes decodeAddr(String addr, {int? workChain}) {
    final decode = TonAddressUtils.decodeAddress(addr);
    if (workChain != null && workChain != decode.workchain) {
      throw CoreErrors.addressValidationFailed(
        reason: "Invalid address workchain.",
        network: "Ton",
        details: {
          "expected": workChain.toString(),
          "workchain": decode.workchain.toString(),
        },
      );
    }
    return decode.hash;
  }

  /// Decodes [addr], returning the full result (not just the hash).
  DecodeAddressResult decodeWithResult(String addr, {int? workChain}) {
    final decode = TonAddressUtils.decodeAddress(addr);
    if (workChain != null && workChain != decode.workchain) {
      throw CoreErrors.addressValidationFailed(
        reason: "Invalid address workchain.",
        network: "Ton",
        details: {
          "expected": workChain.toString(),
          "workchain": decode.workchain.toString(),
        },
      );
    }
    return decode;
  }
}

/// Encodes a TON address.
class TonAddrEncoder implements BlockchainAddressEncoder {
  @override
  String encodeKey(
    List<int> hash, {
    int? workChain,
    bool bounceable = true,
    bool urlSafe = true,
    bool noPadding = false,
    bool testOnly = false,
  }) {
    workChain = AddrKeyValidator.getAddrArg<int>(workChain, "workChain");
    return TonAddressUtils.encodeAddress(
      hash: hash,
      workChain: workChain,
      bounceable: bounceable,
      urlSafe: urlSafe,
      noPadding: noPadding,
      testOnly: testOnly,
    );
  }
}
