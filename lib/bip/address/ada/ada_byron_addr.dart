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
import 'package:blockchain_utils/bip/address/exception/exception.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_key_data.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_path.dart';
import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:blockchain_utils/crypto/crypto/crc32/crc32.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/utils/numbers/utils/int_utils.dart';

import 'network.dart';

/// Enum representing different address types used in the Ada Byron era.
///
/// The ADAByronAddrTypes enum defines two address types:
/// - `publicKey`: Represents the address type for public keys.
/// - `redemption`: Represents the address type for redemption addresses.
///
/// Each address type is associated with a unique integer value for identification.
class ADAByronAddrTypes {
  /// Represents the address type for public keys.
  static const ADAByronAddrTypes publicKey = ADAByronAddrTypes._(
    0,
    "publicKey",
  );

  /// Represents the address type for script addresses.
  static const ADAByronAddrTypes script = ADAByronAddrTypes._(1, "script");

  /// Represents the address type for redemption addresses.
  static const ADAByronAddrTypes redemption = ADAByronAddrTypes._(
    2,
    "redemption",
  );

  final int value;
  final String name;

  /// Constructor for ADAByronAddrTypes.
  const ADAByronAddrTypes._(this.value, this.name);

  /// Factory method to create an ADAByronAddrTypes enum value from an integer value.
  factory ADAByronAddrTypes.fromCbor(CborIntValue value) {
    return values.firstWhere((element) => element.value == value.value);
  }

  // Enum values as a list for iteration
  static const List<ADAByronAddrTypes> values = [publicKey, redemption];

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
class ADAByronAddrConst {
  /// A predefined nonce used for encryption purposes.
  static const List<int> chacha20Poly1305Nonce = [
    115,
    101,
    114,
    111,
    107,
    101,
    108,
    108,
    102,
    111,
    114,
    101,
  ];

  /// An integer representing the payload tag for Ada Byron era addresses.
  static const int payloadTag = 24;
}

class _AdaByronAddrHdPath {
  static Bip32Path decrypt(List<int> hdPathEncBytes, List<int> hdPathKeyBytes) {
    final plainTextBytes = QuickCrypto.chaCha20Poly1305Decrypt(
      key: hdPathKeyBytes,
      nonce: ADAByronAddrConst.chacha20Poly1305Nonce,
      assocData: [],
      cipherText: hdPathEncBytes,
    );
    final decode = CborObject.fromCbor(plainTextBytes);
    if (decode is! CborListValue) {
      throw AddressConverterException.addressBytesValidationFailed(
        reason: "Invalid bip32 path.",
      );
    }

    final paths =
        decode.value
            .map((e) => Bip32KeyIndex(IntUtils.parse(e.value)))
            .toList();
    return Bip32Path(elems: paths, isAbsolute: true);
  }

  static List<int> encrypt(Bip32Path hdPath, List<int> hdPathKeyBytes) {
    final result = QuickCrypto.chaCha20Poly1305Encrypt(
      key: hdPathKeyBytes,
      nonce: ADAByronAddrConst.chacha20Poly1305Nonce,
      assocData: [],
      plainText:
          CborListValue.inDefinite(
            hdPath.toList().map((e) => CborIntValue(e)).toList(),
          ).encode(),
    );
    return result;
  }
}

class ADAByronAddrAttrs {
  final List<int>? hdPathEncBytes;
  final int? networkMagic;

  const ADAByronAddrAttrs({
    required this.hdPathEncBytes,
    required this.networkMagic,
  });

  factory ADAByronAddrAttrs.fromCbor(CborMapValue cborValue) {
    const cborOne = CborIntValue(1);
    const cborTwo = CborIntValue(2);
    if (cborValue.value.length > 2 ||
        (cborValue.value.isNotEmpty &&
            !cborValue.value.containsKey(cborOne) &&
            !cborValue.value.containsKey(cborTwo))) {
      throw AddressConverterException.addressBytesValidationFailed(
        reason: "Invalid address attributes.",
      );
    }
    final hdPath =
        cborValue.value.containsKey(cborOne)
            ? CborBytesValue.decode(
              (cborValue.value[cborOne]! as CborBytesValue).value,
            ).value
            : null;
    final networkMagic =
        cborValue.value.containsKey(cborTwo)
            ? CborIntValue.decode(
              (cborValue.value[cborTwo]! as CborBytesValue).value,
            ).value
            : null;
    return ADAByronAddrAttrs(
      hdPathEncBytes: hdPath,
      networkMagic: networkMagic,
    );
  }

  CborMapValue<CborIntValue, CborBytesValue> toJson() {
    final attrs = <CborIntValue, CborBytesValue>{};
    if (hdPathEncBytes != null) {
      attrs[CborIntValue(1)] = CborBytesValue(
        CborBytesValue(hdPathEncBytes!).encode(),
      );
    }
    if (networkMagic != null &&
        networkMagic != ADANetwork.mainnet.protocolMagic) {
      attrs[CborIntValue(2)] = CborBytesValue(
        CborIntValue(networkMagic!).encode(),
      );
    }
    return CborMapValue.definite(attrs);
  }
}

class _AdaByronAddrSpendingData {
  final ADAByronAddrTypes type;
  final List<int> keyBytes;

  const _AdaByronAddrSpendingData({required this.type, required this.keyBytes});
}

class _AdaByronAddrRoot {
  const _AdaByronAddrRoot({
    required this.type,
    required this.spendingData,
    required this.attrs,
  });
  final ADAByronAddrTypes type;
  final _AdaByronAddrSpendingData spendingData;
  final ADAByronAddrAttrs attrs;

  List<int> hash() {
    return QuickCrypto.blake2b224Hash(QuickCrypto.sha3256Hash(serialize()));
  }

  List<int> serialize() {
    return CborListValue<CborObject>.definite([
      CborIntValue(type.value),
      CborListValue<CborObject>.definite([
        CborIntValue(spendingData.type.value),
        CborBytesValue(spendingData.keyBytes),
      ]),
      attrs.toJson(),
    ]).encode();
  }
}

class ADAByronAddrPayload {
  List<int> rootHashBytes;
  final ADAByronAddrAttrs attrs;
  final ADAByronAddrTypes type;

  ADAByronAddrPayload({
    required this.rootHashBytes,
    required this.attrs,
    required this.type,
  });

  factory ADAByronAddrPayload.deserialize(List<int> serPayloadBytes) {
    final addrPayload = CborObject.fromCbor(serPayloadBytes);
    if (addrPayload is! CborListValue || addrPayload.value.length != 3) {
      throw AddressConverterException.addressBytesValidationFailed(
        reason: "Invalid address payload.",
      );
    }
    if (addrPayload.value[0] is! CborBytesValue ||
        addrPayload.value[1] is! CborMapValue ||
        addrPayload.value[2] is! CborIntValue) {
      throw AddressConverterException.addressBytesValidationFailed(
        reason: "Invalid address payload",
      );
    }
    final cborBytes = addrPayload.value[0] as CborBytesValue;
    // Check key hash length
    AddrDecUtils.validateBytesLength(
      cborBytes.value,
      QuickCrypto.blake2b224DigestSize,
    );

    return ADAByronAddrPayload(
      rootHashBytes: cborBytes.value,
      attrs: ADAByronAddrAttrs.fromCbor(addrPayload.value[1].cast()),
      type: ADAByronAddrTypes.fromCbor(addrPayload.value[2].cast()),
    );
  }

  List<int> serialize() {
    return CborListValue<CborObject>.definite([
      CborBytesValue(rootHashBytes),
      attrs.toJson(),
      CborIntValue(type.value),
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
    final hrp = AdaShelleyAddrUtils.getAddressHrp(network);
    return Bech32Encoder.encode(hrp, toCbor().encode());
  }

  factory ADAByronAddr.deserialize(List<int> serAddrBytes) {
    final addrBytes = CborListValue.decode(serAddrBytes);
    if (addrBytes.value.length != 2) {
      throw AddressConverterException.addressBytesValidationFailed();
    }
    if (!addrBytes.isTypeAt<CborTagValue>(0) ||
        !addrBytes.isTypeAt<CborIntValue>(1)) {
      throw AddressConverterException.addressBytesValidationFailed();
    }
    final decodeCbor = addrBytes.objectAt<CborTagValue>(0);
    if (decodeCbor.tags.isEmpty ||
        decodeCbor.tags.first != ADAByronAddrConst.payloadTag ||
        decodeCbor.value is! CborBytesValue) {
      throw AddressConverterException.addressBytesValidationFailed();
    }

    final crcTag = addrBytes.objectAt<CborIntValue>(1).value;
    final List<int> payloadBytes = decodeCbor.asValue<CborBytesValue>().value;
    final crc32Got = Crc32().quickIntDigest(payloadBytes);
    if (crc32Got != crcTag) {
      throw AddressConverterException.addressBytesValidationFailed();
    }

    return ADAByronAddr(payload: ADAByronAddrPayload.deserialize(payloadBytes));
  }

  CborObject toCbor() {
    final payloadBytes = payload.serialize();
    return CborListValue<CborObject>.definite([
      CborTagValue(CborBytesValue(payloadBytes), [
        ADAByronAddrConst.payloadTag,
      ]),
      CborIntValue(Crc32().quickIntDigest(payloadBytes)),
    ]);
  }
}

class _AdaByronAddrUtils {
  static ADAByronAddr encodeKey(
    List<int> pubKeyBytes,
    List<int> chainCodeBytes,
    ADAByronAddrTypes addrType, {
    List<int>? hdPathEncBytes,
    int? networkMagic,
  }) {
    final addrAttrs = ADAByronAddrAttrs(
      hdPathEncBytes: hdPathEncBytes,
      networkMagic: networkMagic,
    );

    // Get address root
    final addrRoot = _AdaByronAddrRoot(
      type: addrType,
      spendingData: _AdaByronAddrSpendingData(
        type: addrType,
        keyBytes: [...pubKeyBytes.sublist(1), ...chainCodeBytes],
      ),
      attrs: addrAttrs,
    );
    final addrHash = addrRoot.hash();
    // Get address payload
    final addrPayload = ADAByronAddrPayload(
      rootHashBytes: addrHash,
      attrs: addrAttrs,
      type: addrType,
    );
    return ADAByronAddr(payload: addrPayload);
  }
}

/// Implementation of the [BlockchainAddressDecoder] for Ada Byron address.
class AdaByronAddrDecoder implements BlockchainAddressDecoder<List<int>> {
  /// Decrypts an encrypted Hierarchical Deterministic (HD) path using the provided key.
  ///
  /// The [hdPathEncBytes] parameter represents the encrypted HD path to decrypt.
  /// The [hdPathKeyBytes] parameter is the key used for decryption.
  ///
  /// Returns a [Bip32Path] representing the decrypted HD path.
  static Bip32Path decryptHdPath(
    List<int> hdPathEncBytes,
    List<int> hdPathKeyBytes,
  ) {
    return _AdaByronAddrHdPath.decrypt(hdPathEncBytes, hdPathKeyBytes);
  }

  /// Splits the decoded bytes into address root hash and encrypted HD path.
  ///
  /// The [decBytes] parameter represents the decoded bytes containing both address root hash
  /// and encrypted HD path.
  ///
  /// Returns a tuple containing two [List<int>] elements: address root hash and encrypted HD path.
  static (List<int>, List<int>) splitDecodedBytes(List<int> decBytes) {
    final addressRootHash = decBytes.sublist(
      0,
      QuickCrypto.blake2b224DigestSize,
    );
    final encryptedHdPath = decBytes.sublist(QuickCrypto.blake2b224DigestSize);
    return (addressRootHash, encryptedHdPath);
  }

  ADAByronAddrPayload _decodeAddr(
    String addr, {
    ADAByronAddrTypes? addrType,
    ADANetwork? network,
  }) {
    final decAddr = ADAByronAddr.decode(addr);
    if (addrType != null && decAddr.payload.type != addrType) {
      throw AddressConverterException.addressValidationFailed(
        reason: "Invalid address type",
      );
    }
    if (network != null) {
      if (decAddr.payload.attrs.networkMagic != network.protocolMagic) {
        if (decAddr.payload.attrs.networkMagic == null &&
            network == ADANetwork.mainnet) {
          return decAddr.payload;
        }
        throw AddressConverterException.addressValidationFailed(
          reason: "Invalid address network.",
        );
      }
    }
    return decAddr.payload;
  }

  ADAByronAddr decodeWithInfo(String addr) {
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
  List<int> decodeAddr(
    String addr, {
    ADAByronAddrTypes? addrType,
    ADANetwork? network,
  }) {
    final decAddr = _decodeAddr(
      addr,
      addrType: addrType ?? ADAByronAddrTypes.publicKey,
      network: network,
    );
    return [
      ...decAddr.rootHashBytes,
      if (decAddr.attrs.hdPathEncBytes != null)
        ...decAddr.attrs.hdPathEncBytes!,
    ];
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
  /// Throws an [AddressConverterException] if the provided chain code is invalid.

  ADAByronAddr encodeKeyWithInfo(
    List<int> pubKey, {
    ADANetwork network = ADANetwork.mainnet,
    List<int>? chainCode,
  }) {
    final List<int> chainCodeBytes = AddrKeyValidator.getAddrArg(
      chainCode,
      "chainCode",
    );
    final pubkeyBytes =
        AddrKeyValidator.validateAndGetEd25519Key(pubKey).compressed;
    return _AdaByronAddrUtils.encodeKey(
      pubkeyBytes,
      chainCodeBytes,
      ADAByronAddrTypes.publicKey,
      networkMagic: network.protocolMagic,
    );
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
  String encodeKey(
    List<int> pubKey, {
    ADANetwork network = ADANetwork.mainnet,
    List<int>? chainCode,
  }) {
    return encodeKeyWithInfo(
      pubKey,
      network: network,
      chainCode: chainCode,
    ).encode();
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
  ADAByronAddr encodeKeyWithInfo(
    List<int> pubKey, {
    ADANetwork network = ADANetwork.mainnet,
    String? path,
    List<int>? chainCode,
    List<int>? hdPathKey,
  }) {
    final hdPath = Bip32PathParser.parse(
      AddrKeyValidator.getAddrArg(path, "path"),
    );
    final chainCodeBytes = AddrKeyValidator.getAddrArg(chainCode, "chainCode");
    final hdPathKeyBytes = AddrKeyValidator.getAddrArg(hdPathKey, "hdPathKey");
    if (hdPathKeyBytes.length != QuickCrypto.chacha20Polu1305Keysize) {
      throw AddressConverterException.missingOrInvalidAddressArguments(
        reason:
            "HD path key shall be ${QuickCrypto.chacha20Polu1305Keysize}-byte long",
      );
    }
    final pubKeyBytes =
        AddrKeyValidator.validateAndGetEd25519Key(pubKey).compressed;
    return _AdaByronAddrUtils.encodeKey(
      pubKeyBytes,
      chainCodeBytes,
      ADAByronAddrTypes.publicKey,
      hdPathEncBytes: _AdaByronAddrHdPath.encrypt(hdPath, hdPathKeyBytes),
      networkMagic: network.protocolMagic,
    );
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
  /// Throws an [AddressConverterException] if the provided HD path, chain code, or HD path key is invalid.
  @override
  String encodeKey(
    List<int> pubKey, {
    ADANetwork network = ADANetwork.mainnet,
    String? path,
    List<int>? chainCode,
    List<int>? hdPathKey,
  }) {
    return encodeKeyWithInfo(
      pubKey,
      network: network,
      chainCode: chainCode,
      hdPathKey: hdPathKey,
      path: path,
    ).encode();
  }
}
