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
import 'package:blockchain_utils/bech32/bech32_base.dart';
import 'package:blockchain_utils/bip/address/ada/ada_shelley_addr.dart';
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

import 'network.dart';

/// Enum representing different address types used in the Ada Byron era.
///
/// The ADAByronAddrTypes enum defines two address types:
/// - `publicKey`: Represents the address type for public keys.
/// - `redemption`: Represents the address type for redemption addresses.
///
/// Each address type is associated with a unique integer value for identification.
///
/// Example Usage:
/// ```dart
/// final addressType = ADAByronAddrTypes.publicKey;
/// print('Address Type: $addressType'); // Output: Address Type: ADAByronAddrTypes.publicKey
/// ```
class ADAByronAddrTypes {
  /// Represents the address type for public keys.
  static const ADAByronAddrTypes publicKey =
      ADAByronAddrTypes._(0, "publicKey");

  /// Represents the address type for script addresses.
  static const ADAByronAddrTypes script = ADAByronAddrTypes._(1, "script");

  /// Represents the address type for redemption addresses.
  static const ADAByronAddrTypes redemption =
      ADAByronAddrTypes._(2, "redemption");

  final int value;
  final String name;

  /// Constructor for ADAByronAddrTypes.
  const ADAByronAddrTypes._(this.value, this.name);

  /// Factory method to create an ADAByronAddrTypes enum value from an integer value.
  factory ADAByronAddrTypes.fromCbor(CborIntValue value) {
    return values.firstWhere((element) => element.value == value.value);
  }

  // Enum values as a list for iteration
  static const List<ADAByronAddrTypes> values = [
    publicKey,
    redemption,
  ];

  /// Factory method to create an ADAByronAddrTypes enum value from an integer value.
  static ADAByronAddrTypes fromValue(int value) {
    return values.firstWhere((element) => element.value == value);
  }

  @override
  String toString() {
    return "ADAByronAddrTypes.$name";
  }
}

/// Constants related to Ada Byron era addresses in Cardano.
///
/// The ADAByronAddrConst class contains various constants used for Ada Byron era addresses:
/// - `chacha20Poly1305AssocData`: An empty List<int> used as associated data for encryption.
/// - `chacha20Poly1305Nonce`: A predefined nonce used for encryption purposes.
/// - `payloadTag`: An integer representing the payload tag for Ada Byron era addresses.
///
/// These constants are essential for handling and processing Ada Byron era addresses.
class ADAByronAddrConst {
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
      nonce: ADAByronAddrConst.chacha20Poly1305Nonce,
      assocData: ADAByronAddrConst.chacha20Poly1305AssocData,
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
      nonce: ADAByronAddrConst.chacha20Poly1305Nonce,
      assocData: ADAByronAddrConst.chacha20Poly1305AssocData,
      plainText: CborListValue.dynamicLength(hdPath.toList()).encode(),
    );
    return result;
  }
}

class ADAByronAddrAttrs {
  final List<int>? hdPathEncBytes;
  final int? networkMagic;

  ADAByronAddrAttrs({required this.hdPathEncBytes, required this.networkMagic});

  factory ADAByronAddrAttrs.fromCbor(CborMapValue cborValue) {
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
                (cborValue.value[cborTwo]! as CborBytesValue).value)
            .value
        : null;
    return ADAByronAddrAttrs(
        hdPathEncBytes: hdPath, networkMagic: networkMagic);
  }

  Map<int, List<int>> toJson() {
    final attrs = <int, List<int>>{};
    if (hdPathEncBytes != null) {
      attrs[1] = CborBytesValue(hdPathEncBytes!).encode();
    }
    if (networkMagic != null &&
        networkMagic != ADANetwork.mainnet.protocolMagic) {
      attrs[2] = CborIntValue(networkMagic!).encode();
    }
    return attrs;
  }
}

class _AdaByronAddrSpendingData {
  final ADAByronAddrTypes type;
  final List<int> keyBytes;

  _AdaByronAddrSpendingData({required this.type, required this.keyBytes});
}

class _AdaByronAddrRoot {
  _AdaByronAddrRoot(
      {required this.type, required this.spendingData, required this.attrs});
  final ADAByronAddrTypes type;
  final _AdaByronAddrSpendingData spendingData;
  final ADAByronAddrAttrs attrs;

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

class ADAByronAddrPayload {
  List<int> rootHashBytes;
  final ADAByronAddrAttrs attrs;
  final ADAByronAddrTypes type;

  ADAByronAddrPayload(
      {required this.rootHashBytes, required this.attrs, required this.type});

  factory ADAByronAddrPayload.deserialize(List<int> serPayloadBytes) {
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

    return ADAByronAddrPayload(
      rootHashBytes: cborBytes.value,
      attrs: ADAByronAddrAttrs.fromCbor(addrPayload.value[1]),
      type: ADAByronAddrTypes.fromCbor(addrPayload.value[2]),
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

class ADAByronAddr {
  final ADAByronAddrPayload payload;

  ADAByronAddr({required this.payload});

  factory ADAByronAddr.decode(String addr) {
    return ADAByronAddr.deserialize(Base58Decoder.decode(addr));
  }

  String encode() {
    return Base58Encoder.encode(toCbor().encode());
  }

  String toBech32() {
    final network = ADANetwork.fromProtocolMagic(payload.attrs.networkMagic);
    final hrp = AdaShelleyAddrConst.networkTagToAddrHrp[network]!;
    return Bech32Encoder.encode(hrp, toCbor().encode());
  }

  factory ADAByronAddr.deserialize(List<int> serAddrBytes) {
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
        decodeCbor.tags.first != ADAByronAddrConst.payloadTag ||
        decodeCbor.value is! CborBytesValue) {
      throw const MessageException("Invalid CBOR tag");
    }

    final crcTag = (addrBytes.value[1] as CborIntValue).value;
    final List<int> payloadBytes = decodeCbor.value.value;
    final crc32Got = Crc32.quickIntDigest(payloadBytes);
    if (crc32Got != crcTag) {
      throw MessageException("Invalid CRC (expected: $crcTag, got: $crc32Got)");
    }

    return ADAByronAddr(payload: ADAByronAddrPayload.deserialize(payloadBytes));
  }

  CborObject toCbor() {
    final payloadBytes = payload.serialize();
    return CborListValue.fixedLength([
      CborTagValue(payloadBytes, [ADAByronAddrConst.payloadTag]),
      CborIntValue(Crc32.quickIntDigest(payloadBytes)),
    ]);
  }
}

class _AdaByronAddrUtils {
  static ADAByronAddr encodeKey(List<int> pubKeyBytes, List<int> chainCodeBytes,
      ADAByronAddrTypes addrType,
      {List<int>? hdPathEncBytes, int? networkMagic}) {
    final addrAttrs = ADAByronAddrAttrs(
        hdPathEncBytes: hdPathEncBytes, networkMagic: networkMagic);

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
    final addrPayload = ADAByronAddrPayload(
        rootHashBytes: addrHash, attrs: addrAttrs, type: addrType);
    return ADAByronAddr(payload: addrPayload);
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

  ADAByronAddrPayload _decodeAddr(String addr,
      [Map<String, dynamic> kwargs = const {}]) {
    final addrType = kwargs["addr_type"];
    if (addrType != null && addrType is! ADAByronAddrTypes) {
      throw ArgumentException(
          'Address type is not an enumerative of ADAByronAddrTypes');
    }

    /// Determine the network tag, defaulting to mainnet if not specified.
    final netTag = kwargs["net_tag"];

    /// Check if the provided network tag is a valid enum value.
    if (netTag != null && netTag is! ADANetwork) {
      throw ArgumentException(
          'Address type is not an enumerative of ADANetwork');
    }

    final decAddr = ADAByronAddr.decode(addr);
    if (addrType != null && decAddr.payload.type != addrType) {
      throw ArgumentException('Invalid address type');
    }
    if (netTag != null) {
      netTag as ADANetwork;
      if (decAddr.payload.attrs.networkMagic != netTag.protocolMagic) {
        if (decAddr.payload.attrs.networkMagic == null &&
            netTag == ADANetwork.mainnet) {
          return decAddr.payload;
        }
        throw MessageException("Invalid address network.");
      }
    }
    return decAddr.payload;
  }

  ADAByronAddr decodeWithInfo(String addr,
      [Map<String, dynamic> kwargs = const {}]) {
    return ADAByronAddr.decode(addr);
  }

  /// Decodes an Ada Byron address and returns its components.
  ///
  /// The [addr] parameter is the Ada Byron address to decode.
  /// The optional [kwargs] parameter is a map of additional arguments, where "addr_type" can be set to
  /// specify the address type (default is `ADAByronAddrTypes.publicKey`).
  ///
  /// Returns a [List<int>] representing the decoded address components, including root hash and HD path if available.
  ///
  /// Throws an [ArgumentException] if the provided address type is invalid or if the
  /// address type in the decoded address does not match the expected type.
  @override
  List<int> decodeAddr(String addr, [Map<String, dynamic> kwargs = const {}]) {
    final args = Map<String, dynamic>.from(kwargs);
    args["addr_type"] = args["addr_type"] ?? ADAByronAddrTypes.publicKey;
    final decAddr = _decodeAddr(addr, args);
    return List<int>.from([
      ...decAddr.rootHashBytes,
      if (decAddr.attrs.hdPathEncBytes != null)
        ...decAddr.attrs.hdPathEncBytes!,
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
  /// Returns a ADAByronAddr representing the encoded Ada Byron address.
  ///
  /// Throws an [ArgumentException] if the provided chain code is invalid.

  ADAByronAddr encodeKeyWithInfo(List<int> pubKey,
      [Map<String, dynamic> kwargs = const {}]) {
    /// Determine the network tag, defaulting to mainnet if not specified.
    final netTag = kwargs["net_tag"] ?? ADANetwork.mainnet;

    /// Check if the provided network tag is a valid enum value.
    if (netTag is! ADANetwork) {
      throw ArgumentException(
          'Address type is not an enumerative of ADANetwork');
    }
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
        pubkeyBytes, chainCodeBytes, ADAByronAddrTypes.publicKey,
        networkMagic: netTag.protocolMagic);
  }

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
    return encodeKeyWithInfo(pubKey, kwargs).encode();
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
  /// Returns a ADAByronAddr representing the encoded Ada Byron Legacy address.
  ///
  /// Throws an [ArgumentException] if the provided HD path, chain code, or HD path key is invalid.
  ADAByronAddr encodeKeyWithInfo(List<int> pubKey,
      [Map<String, dynamic> kwargs = const {}]) {
    /// Determine the network tag, defaulting to mainnet if not specified.
    final netTag = kwargs["net_tag"] ?? ADANetwork.mainnet;

    /// Check if the provided network tag is a valid enum value.
    if (netTag is! ADANetwork) {
      throw ArgumentException(
          'Address type is not an enumerative of ADANetwork');
    }

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
    List<int> hdPathKeyBytes;
    if (kwargs["hd_path_key"] is! List<int>) {
      throw ArgumentException("hd path key must be bytes");
    }
    hdPathKeyBytes = kwargs["hd_path_key"];
    if (hdPathKeyBytes.length != QuickCrypto.chacha20Polu1305Keysize) {
      throw ArgumentException(
          "HD path key shall be ${QuickCrypto.chacha20Polu1305Keysize}-byte long");
    }
    final pubKeyBytes =
        AddrKeyValidator.validateAndGetEd25519Key(pubKey).compressed;
    return _AdaByronAddrUtils.encodeKey(
        pubKeyBytes, chainCodeBytes, ADAByronAddrTypes.publicKey,
        hdPathEncBytes: _AdaByronAddrHdPath.encrypt(hdPath, hdPathKeyBytes),
        networkMagic: netTag.protocolMagic);
  }

  /// Encodes an Ada Byron Legacy address with the provided public key, chain code, and optional HD path information.
  ///
  /// The [pubKey] parameter is the public key to be encoded.
  /// The optional [kwargs] parameter is a map of additional arguments, including:
  /// - "hd_path": A string or [Bip32Path] specifying the hierarchical deterministic (HD) path.
  /// - "chain_code": A bytes or [Bip32ChainCode] representing the chain code.
  /// - "hd_path_key": An for the HD path key (must be 32 bytes).
  ///
  /// Returns a string representing the encoded Ada Byron Legacy address.
  ///
  /// Throws an [ArgumentException] if the provided HD path, chain code, or HD path key is invalid.
  @override
  String encodeKey(List<int> pubKey, [Map<String, dynamic> kwargs = const {}]) {
    return encodeKeyWithInfo(pubKey, kwargs).encode();
  }
}
