/*
  The MIT License (MIT)
  
  Copyright (c) 2021 Emanuele Bellocchia

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
  of the Software, and to permit persons to whom the Software is furnished to do so,
  subject to the following conditions:

  The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS," WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
  INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
  PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
  FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
  ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
  
  Note: This code has been adapted from its original Python version to Dart.
*/

/*
  The 3-Clause BSD License
  
  Copyright (c) 2023 Mohsen Haydari (MRTNETWORK)
  All rights reserved.
  
  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are met:
  
  1. Redistributions of source code must retain the above copyright notice, this
     list of conditions, and the following disclaimer.
  2. Redistributions in binary form must reproduce the above copyright notice, this
     list of conditions, and the following disclaimer in the documentation and/or
     other materials provided with the distribution.
  3. Neither the name of the [organization] nor the names of its contributors may be
     used to endorse or promote products derived from this software without
     specific prior written permission.
  
  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
  IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
  INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
  BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
  OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
  OF THE POSSIBILITY OF SUCH DAMAGE.
*/

import 'package:blockchain_utils/base58/base58_base.dart';
import 'package:blockchain_utils/bip/address/addr_dec_utils.dart';
import 'package:blockchain_utils/bip/address/addr_key_validator.dart';
import 'package:blockchain_utils/bip/address/decoder.dart';
import 'package:blockchain_utils/bip/address/encoder.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_key_data.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_path.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/cbor/core/cbor.dart';
import 'package:blockchain_utils/cbor/types/bytes.dart';
import 'package:blockchain_utils/cbor/types/cbor_tag.dart';
import 'package:blockchain_utils/cbor/types/int.dart';
import 'package:blockchain_utils/cbor/types/list.dart';
import 'package:blockchain_utils/cbor/types/map.dart';
import 'package:blockchain_utils/crypto/crypto/crc32/crc32.dart';
import 'package:blockchain_utils/exception/exception.dart';
import 'package:blockchain_utils/tuple/tuple.dart';

/// Enum representing different address types used in the Ada Byron era.
///
/// The AdaByronAddrTypes enum defines two address types:
/// - `publicKey`: Represents the address type for public keys.
/// - `redemption`: Represents the address type for redemption addresses.
///
/// Each address type is associated with a unique integer value for identification.
///
/// Example Usage:
/// ```dart
/// final addressType = AdaByronAddrTypes.publicKey;
/// print('Address Type: $addressType'); // Output: Address Type: AdaByronAddrTypes.publicKey
/// ```
enum AdaByronAddrTypes {
  /// Represents the address type for public keys.
  publicKey(0),

  /// Represents the address type for redemption addresses.
  redemption(2);

  final int value;

  /// Constructor for AdaByronAddrTypes.
  const AdaByronAddrTypes(this.value);

  /// Factory method to create an AdaByronAddrTypes enum value from an integer value.
  factory AdaByronAddrTypes.fromValue(CborIntValue value) {
    return values.firstWhere((element) => element.value == value.value);
  }
}

/// Constants related to Ada Byron era addresses in Cardano.
///
/// The AdaByronAddrConst class contains various constants used for Ada Byron era addresses:
/// - `chacha20Poly1305AssocData`: An empty List<int> used as associated data for encryption.
/// - `chacha20Poly1305Nonce`: A predefined nonce used for encryption purposes.
/// - `payloadTag`: An integer representing the payload tag for Ada Byron era addresses.
///
/// These constants are essential for handling and processing Ada Byron era addresses.
class AdaByronAddrConst {
  /// An empty List<int> used as associated data for encryption.
  static final List<int> chacha20Poly1305AssocData = List.empty();

  /// A predefined nonce used for encryption purposes.
  static final List<int> chacha20Poly1305Nonce =
      List<int>.from('serokellfore'.codeUnits);

  /// An integer representing the payload tag for Ada Byron era addresses.
  static const int payloadTag = 24;
}

class _AdaByronAddrHdPath {
  static Bip32Path decrypt(List<int> hdPathEncBytes, List<int> hdPathKeyBytes) {
    final plainTextBytes = QuickCrypto.chaCha20Poly1305Decrypt(
      key: hdPathKeyBytes,
      nonce: AdaByronAddrConst.chacha20Poly1305Nonce,
      assocData: AdaByronAddrConst.chacha20Poly1305AssocData,
      cipherText: hdPathEncBytes,
    );
    final decode = CborObject.fromCbor(plainTextBytes);
    if (decode is! CborListValue) {
      throw ArgumentException("invalid bip32 path");
    }
    final paths = decode.value
        .map((e) => Bip32KeyIndex(e is String ? int.parse(e) : e as int))
        .toList();
    return Bip32Path(elems: paths, isAbsolute: true);
  }

  static List<int> encrypt(Bip32Path hdPath, List<int> hdPathKeyBytes) {
    final result = QuickCrypto.chaCha20Poly1305Encrypt(
      key: hdPathKeyBytes,
      nonce: AdaByronAddrConst.chacha20Poly1305Nonce,
      assocData: AdaByronAddrConst.chacha20Poly1305AssocData,
      plainText: CborListValue.dynamicLength(hdPath.toList()).encode(),
    );
    return result;
  }
}

class _AdaByronAddrAttrs {
  final List<int>? hdPathEncBytes;
  final int? networkMagic;

  _AdaByronAddrAttrs(
      {required this.hdPathEncBytes, required this.networkMagic});

  factory _AdaByronAddrAttrs.fromJson(CborMapValue cborValue) {
    const cborOne = CborIntValue(1);
    const cborTwo = CborIntValue(2);
    if (cborValue.value.length > 2 ||
        (cborValue.value.isNotEmpty &&
            !cborValue.value.containsKey(cborOne) &&
            !cborValue.value.containsKey(cborTwo))) {
      throw ArgumentException('Invalid address attributes');
    }
    final hdPath = cborValue.value.containsKey(cborOne)
        ? CborObject.fromCbor(
                (cborValue.value[cborOne]! as CborBytesValue).value)
            .value
        : null;
    final networkMagic = cborValue.value.containsKey(cborTwo)
        ? CborObject.fromCbor(
                (cborValue.value[cborOne]! as CborBytesValue).value)
            .value
        : null;
    return _AdaByronAddrAttrs(
      hdPathEncBytes: hdPath,
      networkMagic: networkMagic,
    );
  }

  Map<int, List<int>> toJson() {
    final attrs = <int, List<int>>{};
    if (hdPathEncBytes != null) {
      attrs[1] = CborBytesValue(hdPathEncBytes!).encode();
    }
    if (networkMagic != null) {
      attrs[2] = CborIntValue(networkMagic!).encode();
    }
    return attrs;
  }
}

class _AdaByronAddrSpendingData {
  AdaByronAddrTypes type;
  List<int> keyBytes;

  _AdaByronAddrSpendingData({required this.type, required this.keyBytes});
}

class _AdaByronAddrRoot {
  _AdaByronAddrRoot(
      {required this.type, required this.spendingData, required this.attrs});
  AdaByronAddrTypes type;
  _AdaByronAddrSpendingData spendingData;
  _AdaByronAddrAttrs attrs;

  List<int> hash() {
    return QuickCrypto.blake2b224Hash(QuickCrypto.sha3256Hash(serialize()));
  }

  List<int> serialize() {
    return CborListValue.fixedLength([
      CborIntValue(type.value),
      CborListValue.fixedLength(
          [spendingData.type.value, spendingData.keyBytes]),
      attrs.toJson(),
    ]).encode();
  }
}

class _AdaByronAddrPayload {
  List<int> rootHashBytes;
  _AdaByronAddrAttrs attrs;
  AdaByronAddrTypes type;

  _AdaByronAddrPayload(
      {required this.rootHashBytes, required this.attrs, required this.type});

  factory _AdaByronAddrPayload.deserialize(List<int> serPayloadBytes) {
    final addrPayload = CborObject.fromCbor(serPayloadBytes);
    if (addrPayload is! CborListValue || addrPayload.value.length != 3) {
      throw const MessageException("Invalid address payload");
    }
    if (addrPayload.value[0] is! CborBytesValue ||
        addrPayload.value[1] is! CborMapValue ||
        addrPayload.value[2] is! CborIntValue) {
      throw const MessageException("Invalid address payload");
    }
    final cborBytes = addrPayload.value[0] as CborBytesValue;
    // Check key hash length
    AddrDecUtils.validateBytesLength(
        cborBytes.value, QuickCrypto.blake2b224DigestSize);

    return _AdaByronAddrPayload(
      rootHashBytes: cborBytes.value,
      attrs: _AdaByronAddrAttrs.fromJson(addrPayload.value[1]),
      type: AdaByronAddrTypes.fromValue(addrPayload.value[2]),
    );
  }

  List<int> serialize() {
    return CborListValue.fixedLength([
      CborBytesValue(rootHashBytes),
      attrs.toJson(),
      CborIntValue(type.value)
    ]).encode();
  }
}

class _AdaByronAddr {
  _AdaByronAddrPayload payload;

  _AdaByronAddr({required this.payload});

  factory _AdaByronAddr.decode(String addr) {
    return _AdaByronAddr.deserialize(Base58Decoder.decode(addr));
  }

  String encode() {
    return Base58Encoder.encode(serialize());
  }

  factory _AdaByronAddr.deserialize(List<int> serAddrBytes) {
    final addrBytes = CborObject.fromCbor(serAddrBytes);
    if (addrBytes is! CborListValue || addrBytes.value.length != 2) {
      throw const MessageException("Invalid address encoding");
    }
    if (addrBytes.value[0] is! CborTagValue ||
        addrBytes.value[1] is! CborIntValue) {
      throw const MessageException("Invalid address encoding");
    }
    final decodeCbor = addrBytes.value[0] as CborTagValue;
    if (decodeCbor.tags.isEmpty ||
        decodeCbor.tags.first != AdaByronAddrConst.payloadTag ||
        decodeCbor.value is! CborBytesValue) {
      throw const MessageException("Invalid CBOR tag");
    }

    final crcTag = (addrBytes.value[1] as CborIntValue).value;
    final List<int> payloadBytes = decodeCbor.value.value;
    final crc32Got = Crc32.quickIntDigest(payloadBytes);
    if (crc32Got != crcTag) {
      throw MessageException("Invalid CRC (expected: $crcTag, got: $crc32Got)");
    }

    return _AdaByronAddr(
        payload: _AdaByronAddrPayload.deserialize(payloadBytes));
  }

  List<int> serialize() {
    final payloadBytes = payload.serialize();
    return CborListValue.fixedLength([
      CborTagValue(payloadBytes, [AdaByronAddrConst.payloadTag]),
      CborIntValue(Crc32.quickIntDigest(payloadBytes)),
    ]).encode();
  }
}

class _AdaByronAddrUtils {
  static String encodeKey(List<int> pubKeyBytes, List<int> chainCodeBytes,
      AdaByronAddrTypes addrType,
      {List<int>? hdPathEncBytes}) {
    final addrAttrs =
        _AdaByronAddrAttrs(hdPathEncBytes: hdPathEncBytes, networkMagic: null);

    // Get address root
    final addrRoot = _AdaByronAddrRoot(
      type: addrType,
      spendingData: _AdaByronAddrSpendingData(
          type: addrType,
          keyBytes:
              List<int>.from([...pubKeyBytes.sublist(1), ...chainCodeBytes])),
      attrs: addrAttrs,
    );
    final addrHash = addrRoot.hash();
    // Get address payload
    final addrPayload = _AdaByronAddrPayload(
        rootHashBytes: addrHash, attrs: addrAttrs, type: addrType);
    final encode = _AdaByronAddr(payload: addrPayload).encode();
    // Add CRC32 and encode to base58
    return encode;
  }
}

/// Implementation of the [BlockchainAddressDecoder] for Ada Byron address.
class AdaByronAddrDecoder implements BlockchainAddressDecoder {
  /// Decrypts an encrypted Hierarchical Deterministic (HD) path using the provided key.
  ///
  /// The [hdPathEncBytes] parameter represents the encrypted HD path to decrypt.
  /// The [hdPathKeyBytes] parameter is the key used for decryption.
  ///
  /// Returns a [Bip32Path] representing the decrypted HD path.
  static Bip32Path decryptHdPath(
      List<int> hdPathEncBytes, List<int> hdPathKeyBytes) {
    return _AdaByronAddrHdPath.decrypt(hdPathEncBytes, hdPathKeyBytes);
  }

  /// Splits the decoded bytes into address root hash and encrypted HD path.
  ///
  /// The [decBytes] parameter represents the decoded bytes containing both address root hash
  /// and encrypted HD path.
  ///
  /// Returns a tuple containing two [List<int>] elements: address root hash and encrypted HD path.
  static Tuple<List<int>, List<int>> splitDecodedBytes(List<int> decBytes) {
    final addressRootHash =
        List<int>.from(decBytes.sublist(0, QuickCrypto.blake2b224DigestSize));
    final encryptedHdPath =
        List<int>.from(decBytes.sublist(QuickCrypto.blake2b224DigestSize));
    return Tuple(addressRootHash, encryptedHdPath);
  }

  /// Decodes an Ada Byron address and returns its components.
  ///
  /// The [addr] parameter is the Ada Byron address to decode.
  /// The optional [kwargs] parameter is a map of additional arguments, where "addr_type" can be set to
  /// specify the address type (default is `AdaByronAddrTypes.publicKey`).
  ///
  /// Returns a [List<int>] representing the decoded address components, including root hash and HD path if available.
  ///
  /// Throws an [ArgumentException] if the provided address type is invalid or if the
  /// address type in the decoded address does not match the expected type.
  @override
  List<int> decodeAddr(String addr, [Map<String, dynamic> kwargs = const {}]) {
    final addrType = kwargs["addr_type"] ?? AdaByronAddrTypes.publicKey;
    if (addrType is! AdaByronAddrTypes) {
      throw ArgumentException(
          'Address type is not an enumerative of AdaByronAddrTypes');
    }

    final decAddr = _AdaByronAddr.decode(addr);
    if (decAddr.payload.type != addrType) {
      throw ArgumentException('Invalid address type');
    }
    return List<int>.from([
      ...decAddr.payload.rootHashBytes,
      if (decAddr.payload.attrs.hdPathEncBytes != null)
        ...decAddr.payload.attrs.hdPathEncBytes!,
    ]);
  }
}

/// Implementation of the [BlockchainAddressEncoder] for Ada Byron Icarus address.
class AdaByronIcarusAddrEncoder implements BlockchainAddressEncoder {
  /// Encodes an Ada Byron address with the provided public key and chain code.
  ///
  /// The [pubKey] parameter is the public key to be encoded.
  /// The optional [kwargs] parameter is a map of additional arguments, where "chain_code" can be set to specify the chain code.
  ///
  /// Returns a string representing the encoded Ada Byron address.
  ///
  /// Throws an [ArgumentException] if the provided chain code is invalid.
  @override
  String encodeKey(List<int> pubKey, [Map<String, dynamic> kwargs = const {}]) {
    List<int> chainCodeBytes;
    final chainCode = kwargs["chain_code"];
    if (chainCode is Bip32ChainCode) {
      chainCodeBytes = chainCode.toBytes();
    } else if (chainCode is List<int>) {
      chainCodeBytes = chainCode;
    } else {
      throw ArgumentException("invalid chaincode ");
    }
    final pubkeyBytes =
        AddrKeyValidator.validateAndGetEd25519Key(pubKey).compressed;

    return _AdaByronAddrUtils.encodeKey(
        pubkeyBytes, chainCodeBytes, AdaByronAddrTypes.publicKey);
  }
}

/// Implementation of the [BlockchainAddressEncoder] for Ada Byron Legacy address.
class AdaByronLegacyAddrEncoder implements BlockchainAddressEncoder {
  /// Encodes an Ada Byron Legacy address with the provided public key, chain code, and optional HD path information.
  ///
  /// The [pubKey] parameter is the public key to be encoded.
  /// The optional [kwargs] parameter is a map of additional arguments, including:
  /// - "hd_path": A string or [Bip32Path] specifying the hierarchical deterministic (HD) path.
  /// - "chain_code": A bytes or [Bip32ChainCode] representing the chain code.
  /// - "hd_path_key": An optional bytes for the HD path key (must be 32 bytes).
  ///
  /// Returns a string representing the encoded Ada Byron Legacy address.
  ///
  /// Throws an [ArgumentException] if the provided HD path, chain code, or HD path key is invalid.
  @override
  String encodeKey(List<int> pubKey, [Map<String, dynamic> kwargs = const {}]) {
    Bip32Path hdPath;
    if (kwargs["hd_path"] is String) {
      hdPath = Bip32PathParser.parse(kwargs["hd_path"]);
    } else {
      if (kwargs["hd_path"] is! Bip32Path) {
        throw ArgumentException("hd path must be string or Bip32Path");
      }
      hdPath = kwargs["hd_path"];
    }

    List<int> chainCodeBytes;

    if (kwargs["chain_code"] is List<int>) {
      chainCodeBytes = kwargs["chain_code"];
    } else {
      if (kwargs["chain_code"] is! Bip32ChainCode) {
        throw ArgumentException("chain code must be bytes or Bip32ChainCode");
      }
      chainCodeBytes = (kwargs["chain_code"] as Bip32ChainCode).toBytes();
    }
    List<int>? hdPathKeyBytes;
    if (kwargs["hd_path_key"] != null) {
      if (kwargs["hd_path_key"] is! List<int>) {
        throw ArgumentException("hd path key must be bytes");
      }
      hdPathKeyBytes = kwargs["hd_path_key"];
      if (hdPathKeyBytes!.length != QuickCrypto.chacha20Polu1305Keysize) {
        throw ArgumentException(
            "HD path key shall be ${QuickCrypto.chacha20Polu1305Keysize}-byte long");
      }
    }
    final pubKeyBytes =
        AddrKeyValidator.validateAndGetEd25519Key(pubKey).compressed;
    return _AdaByronAddrUtils.encodeKey(
        pubKeyBytes, chainCodeBytes, AdaByronAddrTypes.publicKey,
        hdPathEncBytes: hdPathKeyBytes == null
            ? null
            : _AdaByronAddrHdPath.encrypt(hdPath, hdPathKeyBytes));
  }
}
