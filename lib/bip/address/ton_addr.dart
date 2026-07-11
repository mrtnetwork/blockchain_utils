// MIT License

// Copyright (c) 2022-2023 Whales Corp. (all contributions until 2023-04-27)
// Copyright (c) 2023+ The TON Authors (all contributions from 2023-04-27)
// Copyright (c) 2024+ MRT Network (Dart Package).

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
import 'package:blockchain_utils/base64/base64.dart';
import 'package:blockchain_utils/bip/address/addr_key_validator.dart';
import 'package:blockchain_utils/bip/address/decoder.dart';
import 'package:blockchain_utils/bip/address/encoder.dart';
import 'package:blockchain_utils/crypto/crypto/crc16/crc16.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/helper/helper.dart';

import 'exception/exception.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';
import 'package:blockchain_utils/utils/binary/binary_operation.dart';

class DecodeAddressResult {
  final int workchain;
  final List<int> hash;
  DecodeAddressResult({
    required this.workchain,
    required this.hash,
    required List<FriendlyAddressFlags> flags,
    this.isUrlSafe = false,
    this.isPaded = true,
  }) : flags = flags.immutable;
  final List<FriendlyAddressFlags> flags;
  final bool isUrlSafe;
  final bool isPaded;
  bool get isFriendly => flags.isNotEmpty;
  bool get isTestOnly => flags.contains(FriendlyAddressFlags.test);
  bool get isBounceable => flags.contains(FriendlyAddressFlags.bounceable);
}

enum FriendlyAddressFlags {
  bounceable("bounceable", 0x11),
  nonBounceable("nonBounceable", 0x51),
  test("nonBounceable", 0x80);

  const FriendlyAddressFlags(this.name, this.flag);
  final String name;
  final int flag;
  static FriendlyAddressFlags fromFlag(int? flag) {
    return values.firstWhere(
      (e) => e.flag == flag,
      orElse: () => throw ItemNotFoundException(name: "FriendlyAddressFlags"),
    );
  }
}

class _TonAddressConst {
  static const int friendlyAddressLength = 48;
  static const int addressHashLength = 32;
  static const int friendlyAddressBytesLength = 36;
}

class TonAddressUtils {
  static bool isFriendly(String source) {
    final RegExp regExp = RegExp(r'[A-Za-z0-9+/_-]+');
    if (source.length == _TonAddressConst.friendlyAddressLength &&
        regExp.hasMatch(source)) {
      return true;
    }
    return false;
  }

  static bool isRaw(String source) {
    return tryRawAddress(source) != null;
  }

  static DecodeAddressResult? tryRawAddress(String address) {
    try {
      final parts = address.split(':');
      final int? workChain = int.tryParse(parts[0]);
      if (workChain == null) return null;
      final hash = BytesUtils.fromHexString(parts[1]);
      return DecodeAddressResult(hash: hash, workchain: workChain, flags: []);
    } catch (_) {
      return null;
    }
  }

  static DecodeAddressResult fromFriendlyAddress(String address) {
    final decode = B64Decoder.decodeWithInfo(
      address,
      urlSafe: true,
      validatePadding: false,
    );
    final data = decode.data;
    // 1 byte tag + 1 byte workchain + 32 bytes hash + 2 byte crc
    if (data.length != _TonAddressConst.friendlyAddressBytesLength) {
      throw AddressConverterException.addressValidationFailed(
        reason: "Invalid address bytes.",
        details: {"length": data.length.toString()},
      );
    }

    // Prepare data
    final addr = data.sublist(0, 34);
    final crc = data.sublist(34, 36);
    final calcedCrc = Crc16.quickIntDigest(addr);
    if (!BytesUtils.bytesEqual(crc, calcedCrc)) {
      throw AddressConverterException.addressValidationFailed(
        reason: "Invalid address checksum.",
        details: {"expected": calcedCrc.toString(), "checksum": crc.toString()},
      );
    }
    final List<FriendlyAddressFlags> flags = [];
    // Parse tag
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
      throw AddressConverterException.addressValidationFailed(
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
      isPaded: decode.isPaded,
    );
  }

  static DecodeAddressResult fromRawAddress(String address) {
    try {
      final parts = address.split(':');
      final int workChain = int.parse(parts[0]);
      final hash = BytesUtils.fromHexString(parts[1]);
      return DecodeAddressResult(hash: hash, workchain: workChain, flags: []);
    } catch (e) {
      throw AddressConverterException.addressValidationFailed(
        details: {"address": address},
      );
    }
  }

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

  static DecodeAddressResult decodeAddress(String address) {
    if (isFriendly(address)) {
      return fromFriendlyAddress(address);
    } else if (tryRawAddress(address) case DecodeAddressResult result) {
      return result;
    } else {
      throw AddressConverterException.addressValidationFailed(
        details: {"address": address},
      );
    }
  }

  static List<int> validateAddressHash(List<int> bytes) {
    if (bytes.length != _TonAddressConst.addressHashLength) {
      throw AddressConverterException.addressBytesValidationFailed(
        reason: "Invalid address bytes.",
        details: {
          "expected": _TonAddressConst.addressHashLength.toString(),
          "length": bytes.length.toString(),
        },
      );
    }
    return bytes.asImmutableBytes;
  }

  static String encodeRawAddress(int workchain, List<int> bytes) {
    final data = validateAddressHash(bytes);
    return BytesUtils.toHexString(data, prefix: '$workchain:');
  }
}

class TonAddrDecoder implements BlockchainAddressDecoder<List<int>> {
  @override
  List<int> decodeAddr(String addr, {int? workChain}) {
    final decode = TonAddressUtils.decodeAddress(addr);
    if (workChain != null && workChain != decode.workchain) {
      throw AddressConverterException.addressValidationFailed(
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

  DecodeAddressResult decodeWithResult(String addr, {int? workChain}) {
    final decode = TonAddressUtils.decodeAddress(addr);
    if (workChain != null && workChain != decode.workchain) {
      throw AddressConverterException.addressValidationFailed(
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
