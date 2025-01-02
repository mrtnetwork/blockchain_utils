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
import 'package:blockchain_utils/bip/address/addr_key_validator.dart';
import 'package:blockchain_utils/bip/address/decoder.dart';
import 'package:blockchain_utils/bip/address/encoder.dart';
import 'package:blockchain_utils/crypto/crypto/crc16/crc16.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'exception/exception.dart';

class DecodeAddressResult {
  final int workchain;
  final List<int> hash;
  DecodeAddressResult(
      {required this.workchain,
      required this.hash,
      required List<FriendlyAddressFlags> flags})
      : flags = List<FriendlyAddressFlags>.unmodifiable(flags);
  final List<FriendlyAddressFlags> flags;
  bool get isFriendly => flags.isNotEmpty;
  bool get isTestOnly => flags.contains(FriendlyAddressFlags.test);
  bool get isBounceable => flags.contains(FriendlyAddressFlags.bounceable);
}

class FriendlyAddressFlags {
  final String name;
  final int flag;
  const FriendlyAddressFlags._(this.name, this.flag);
  static const FriendlyAddressFlags bounceable =
      FriendlyAddressFlags._("bounceable", 0x11);
  static const FriendlyAddressFlags nonBounceable =
      FriendlyAddressFlags._("nonBounceable", 0x51);
  static const FriendlyAddressFlags test =
      FriendlyAddressFlags._("nonBounceable", 0x80);
}

class _TonAddressConst {
  static const int friendlyAddressLength = 48;
  static const int addressHashLength = 32;
  static const int friendlyAddressBytesLength = 36;
}

class TonAddressUtils {
  static final RegExp _friendlyRegixAddress = RegExp(r'[A-Za-z0-9+/_-]+');
  static bool isFriendly(String source) {
    if (source.length == _TonAddressConst.friendlyAddressLength &&
        _friendlyRegixAddress.hasMatch(source)) {
      return true;
    }
    return false;
  }

  static bool isRaw(String source) {
    final parts = source.split(':');
    try {
      int.parse(parts[0]);
      final hashBytes = BytesUtils.fromHexString(parts[1]);
      if (hashBytes.length == _TonAddressConst.addressHashLength) {
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static DecodeAddressResult fromFriendlyAddress(String address) {
    final data = StringUtils.encode(address, type: StringEncoding.base64);
    // 1 byte tag + 1 byte workchain + 32 bytes hash + 2 byte crc
    if (data.length != _TonAddressConst.friendlyAddressBytesLength) {
      throw AddressConverterException(
          "Unknown address type. byte length is not equal to ${_TonAddressConst.friendlyAddressBytesLength}",
          details: {"length": data.length});
    }

    // Prepare data
    final addr = data.sublist(0, 34);
    final crc = data.sublist(34, 36);
    final calcedCrc = Crc16.quickIntDigest(addr);
    if (!BytesUtils.bytesEqual(crc, calcedCrc)) {
      throw AddressConverterException("Invalid checksum",
          details: {"excepted": calcedCrc, "checksum": crc});
    }
    final List<FriendlyAddressFlags> flags = [];
    // Parse tag
    int tag = addr[0];
    // bool isTestOnly = false;
    // bool isBounceable = false;
    if ((tag & FriendlyAddressFlags.test.flag) != 0) {
      flags.add(FriendlyAddressFlags.test);
      tag ^= FriendlyAddressFlags.test.flag;
    }
    if (tag != FriendlyAddressFlags.bounceable.flag &&
        tag != FriendlyAddressFlags.nonBounceable.flag) {
      throw AddressConverterException("Unknown address tag",
          details: {"tag": tag});
    }
    if (tag == FriendlyAddressFlags.bounceable.flag) {
      flags.add(FriendlyAddressFlags.bounceable);
    } else {
      flags.add(FriendlyAddressFlags.nonBounceable);
    }
    int? workchain;
    if (addr[1] == mask8) {
      workchain = -1;
    } else {
      workchain = addr[1];
    }
    final hashPart = addr.sublist(2, 34);
    return DecodeAddressResult(
        workchain: workchain, hash: hashPart, flags: flags);
  }

  static DecodeAddressResult fromRawAddress(String address) {
    try {
      final parts = address.split(':');
      final int workChain = int.parse(parts[0]);
      final hash = BytesUtils.fromHexString(parts[1]);
      return DecodeAddressResult(hash: hash, workchain: workChain, flags: []);
    } catch (e) {
      throw AddressConverterException("Invalid raw address",
          details: {"address": address});
    }
  }

  static String encodeAddress(
      {required List<int> hash,
      required int workChain,
      bool bounceable = true,
      bool testOnly = false,
      bool urlSafe = false}) {
    int tag = bounceable
        ? FriendlyAddressFlags.bounceable.flag
        : FriendlyAddressFlags.nonBounceable.flag;
    if (testOnly) {
      tag |= FriendlyAddressFlags.test.flag;
    }
    final List<int> addr =
        List<int>.unmodifiable([tag, workChain & mask8, ...hash]);
    final addrBytes = [...addr, ...Crc16.quickIntDigest(addr)];

    final encode = StringUtils.decode(addrBytes, type: StringEncoding.base64);
    if (urlSafe) {
      return encode.replaceAll('+', '-').replaceAll('/', '_');
    }
    return encode;
  }

  static DecodeAddressResult decodeAddress(String address) {
    if (isFriendly(address)) {
      return fromFriendlyAddress(address);
    } else if (isRaw(address)) {
      return fromRawAddress(address);
    } else {
      throw AddressConverterException('Unknown address type.',
          details: {"address": address});
    }
  }

  static List<int> validateAddressHash(List<int> bytes) {
    if (bytes.length != _TonAddressConst.addressHashLength) {
      throw AddressConverterException("Invalid address hash length.", details: {
        "excepted": _TonAddressConst.addressHashLength,
        "length": bytes.length
      });
    }
    return BytesUtils.toBytes(bytes, unmodifiable: true);
  }
}

class TonAddrDecoder implements BlockchainAddressDecoder {
  @override
  List<int> decodeAddr(String addr, [Map<String, dynamic> kwargs = const {}]) {
    final int? workChain =
        AddrKeyValidator.nullOrValidateAddressArgs(kwargs, "workchain");
    final decode = TonAddressUtils.decodeAddress(addr);
    if (workChain != null && workChain != decode.workchain) {
      throw AddressConverterException("Invalid address workchain.",
          details: {"excepted": workChain, "workchain": decode.workchain});
    }
    return decode.hash;
  }

  DecodeAddressResult decodeWithResult(String addr,
      [Map<String, dynamic> kwargs = const {}]) {
    final int? workChain =
        AddrKeyValidator.nullOrValidateAddressArgs(kwargs, "workchain");
    final decode = TonAddressUtils.decodeAddress(addr);
    if (workChain != null && workChain != decode.workchain) {
      throw AddressConverterException("Invalid address workchain.",
          details: {"excepted": workChain, "workchain": decode.workchain});
    }
    return decode;
  }
}

class TonAddrEncoder implements BlockchainAddressEncoder {
  @override
  String encodeKey(List<int> hash, [Map<String, dynamic> kwargs = const {}]) {
    final int workChain =
        AddrKeyValidator.validateAddressArgs(kwargs, "workchain");
    final bool bounceable = AddrKeyValidator.nullOrValidateAddressArgs<bool>(
            kwargs, "bounceable") ??
        true;
    final bool urlSafe =
        AddrKeyValidator.nullOrValidateAddressArgs<bool>(kwargs, "url_safe") ??
            true;

    return TonAddressUtils.encodeAddress(
        hash: hash,
        workChain: workChain,
        bounceable: bounceable,
        urlSafe: urlSafe);
  }
}
