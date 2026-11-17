import 'package:blockchain_utils/encoding/base58/src/base58_base.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/encoding/bech32/src/bech32_base.dart';
import 'package:blockchain_utils/chain/address/neworks/ada/src/ada_shelley_addr.dart';
import 'package:blockchain_utils/chain/address/utils/addr_dec_utils.dart';
import 'package:blockchain_utils/chain/address/utils/addr_key_validator.dart';
import 'package:blockchain_utils/chain/address/types/decoder.dart';
import 'package:blockchain_utils/chain/address/types/encoder.dart';
import 'package:blockchain_utils/protocol/bip/bip/bip32/bip32_key_data.dart';
import 'package:blockchain_utils/protocol/bip/bip/bip32/bip32_path.dart';
import 'package:blockchain_utils/encoding/cbor/cbor.dart';
import 'package:blockchain_utils/crypto/crypto/checksum/crc32/crc32.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/utils/numbers/utils/int_utils.dart';

import 'package:blockchain_utils/chain/address/neworks/ada/src/network.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Ada Byron era address types: public key, script, or redemption.
class ADAByronAddrTypes {
  static const ADAByronAddrTypes publicKey = ADAByronAddrTypes._(
    0,
    "publicKey",
  );
  static const ADAByronAddrTypes script = ADAByronAddrTypes._(1, "script");
  static const ADAByronAddrTypes redemption = ADAByronAddrTypes._(
    2,
    "redemption",
  );

  final int value;
  final String name;

  const ADAByronAddrTypes._(this.value, this.name);

  /// Get the address type from its CBOR-encoded value.
  factory ADAByronAddrTypes.fromCbor(CborIntValue value) {
    return values.firstWhere(
      (element) => element.value == value.value,
      orElse:
          () =>
              throw CoreErrors.addressValidationFailed(
                reason: "Invalid ADA Byron address type.",
                details: {"got": value.value.toString()},
              ),
    );
  }

  /// All defined address types, for lookup by value.
  static const List<ADAByronAddrTypes> values = [publicKey, script, redemption];

  /// Get the address type matching an integer value.
  static ADAByronAddrTypes fromValue(int value) {
    return values.firstWhere(
      (element) => element.value == value,
      orElse:
          () =>
              throw CoreErrors.addressValidationFailed(
                reason: "Invalid ADA Byron address type.",
                details: {"got": value.toString()},
              ),
    );
  }

  @override
  String toString() {
    return "ADAByronAddrTypes.$name";
  }
}

/// Ada Byron address constants.
class ADAByronAddrConst {
  /// Fixed nonce for the ChaCha20-Poly1305 HD path encryption.
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

  /// CBOR tag for the address payload.
  static const int payloadTag = 24;
}

/// Encrypts/decrypts the HD derivation path embedded in Byron addresses.
class _AdaByronAddrHdPath {
  /// Decrypts an HD path using [hdPathKeyBytes].
  static Bip32Path decrypt(List<int> hdPathEncBytes, List<int> hdPathKeyBytes) {
    final plainTextBytes = QuickCrypto.chaCha20Poly1305Decrypt(
      key: hdPathKeyBytes,
      nonce: ADAByronAddrConst.chacha20Poly1305Nonce,
      assocData: [],
      cipherText: hdPathEncBytes,
    );
    final decode = CborObject.fromCbor(plainTextBytes);
    if (decode is! CborListValue) {
      throw CoreErrors.addressBytesValidationFailed(
        reason: "Invalid bip32 path.",
      );
    }

    final paths =
        decode.value
            .map((e) => Bip32KeyIndex(IntUtils.parse(e.value)))
            .toList();
    return Bip32Path(elems: paths, isAbsolute: true);
  }

  /// Encrypts an HD path using [hdPathKeyBytes].
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

/// Ada Byron address attributes: optional encrypted HD path and network magic.
class ADAByronAddrAttrs {
  final List<int>? hdPathEncBytes;
  final int? networkMagic;

  const ADAByronAddrAttrs({
    required this.hdPathEncBytes,
    required this.networkMagic,
  });

  /// Decodes attributes from their CBOR map form.
  factory ADAByronAddrAttrs.fromCbor(CborMapValue cborValue) {
    const cborOne = CborIntValue(1);
    const cborTwo = CborIntValue(2);
    if (cborValue.value.length > 2 ||
        (cborValue.value.isNotEmpty &&
            !cborValue.value.containsKey(cborOne) &&
            !cborValue.value.containsKey(cborTwo))) {
      throw CoreErrors.addressBytesValidationFailed(
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

  /// Encodes attributes to their CBOR map form.
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

/// Type + key bytes describing how a Byron address can be spent.
class _AdaByronAddrSpendingData {
  final ADAByronAddrTypes type;
  final List<int> keyBytes;

  const _AdaByronAddrSpendingData({required this.type, required this.keyBytes});
}

/// The hashed root data (type, spending data, attrs) of a Byron address.
class _AdaByronAddrRoot {
  const _AdaByronAddrRoot({
    required this.type,
    required this.spendingData,
    required this.attrs,
  });
  final ADAByronAddrTypes type;
  final _AdaByronAddrSpendingData spendingData;
  final ADAByronAddrAttrs attrs;

  /// SHA3-256 then Blake2b-224 hash of the serialized root, per spec.
  List<int> hash() {
    return QuickCrypto.blake2b224Hash(QuickCrypto.sha3256Hash(serialize()));
  }

  /// CBOR-encodes [type, [spendingData.type, spendingData.keyBytes], attrs].
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

/// The CBOR payload embedded in a Byron address: root hash, attrs, type.
class ADAByronAddrPayload {
  List<int> rootHashBytes;
  final ADAByronAddrAttrs attrs;
  final ADAByronAddrTypes type;

  ADAByronAddrPayload({
    required this.rootHashBytes,
    required this.attrs,
    required this.type,
  });

  /// Decodes a payload from its raw CBOR bytes.
  factory ADAByronAddrPayload.deserialize(List<int> serPayloadBytes) {
    final addrPayload = CborObject.fromCbor(serPayloadBytes);
    if (addrPayload is! CborListValue || addrPayload.value.length != 3) {
      throw CoreErrors.addressBytesValidationFailed(
        reason: "Invalid address payload.",
      );
    }
    if (addrPayload.value[0] is! CborBytesValue ||
        addrPayload.value[1] is! CborMapValue ||
        addrPayload.value[2] is! CborIntValue) {
      throw CoreErrors.addressBytesValidationFailed(
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

  /// Encodes this payload to raw CBOR bytes.
  List<int> serialize() {
    return CborListValue<CborObject>.definite([
      CborBytesValue(rootHashBytes),
      attrs.toJson(),
      CborIntValue(type.value),
    ]).encode();
  }
}

/// A full Ada Byron address: CBOR payload + CRC32 checksum.
class ADAByronAddr {
  final ADAByronAddrPayload payload;

  ADAByronAddr({required this.payload});

  /// Decodes a Base58-encoded Byron address.
  factory ADAByronAddr.decode(String addr) {
    return ADAByronAddr.deserialize(Base58Decoder.decode(addr));
  }

  /// Encodes this address as Base58.
  String encode() {
    return Base58Encoder.encode(toCbor().encode());
  }

  /// Encodes this address as Bech32, using the HRP for its network.
  String toBech32() {
    final network = ADANetwork.fromProtocolMagic(payload.attrs.networkMagic);
    final hrp = AdaShelleyAddrUtils.getAddressHrp(network);
    return Bech32Encoder.encode(hrp, toCbor().encode());
  }

  /// Decodes an address from its raw bytes, verifying the CRC32 checksum.
  factory ADAByronAddr.deserialize(List<int> serAddrBytes) {
    final addrBytes = CborListValue.decode(serAddrBytes);
    if (addrBytes.value.length != 2) {
      throw CoreErrors.addressBytesValidationFailed();
    }
    if (!addrBytes.isTypeAt<CborTagValue>(0) ||
        !addrBytes.isTypeAt<CborIntValue>(1)) {
      throw CoreErrors.addressBytesValidationFailed();
    }
    final decodeCbor = addrBytes.objectAt<CborTagValue>(0);
    if (decodeCbor.tags.isEmpty ||
        decodeCbor.tags.first != ADAByronAddrConst.payloadTag ||
        decodeCbor.value is! CborBytesValue) {
      throw CoreErrors.addressBytesValidationFailed();
    }

    final crcTag = addrBytes.objectAt<CborIntValue>(1).value;
    final List<int> payloadBytes = decodeCbor.asValue<CborBytesValue>().value;
    final crc32Got = Crc32().quickIntDigest(payloadBytes);
    if (crc32Got != crcTag) {
      throw CoreErrors.addressBytesValidationFailed();
    }

    return ADAByronAddr(payload: ADAByronAddrPayload.deserialize(payloadBytes));
  }

  /// Builds the [payload, crc32] CBOR structure for this address.
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

/// Internal Byron address encoding helpers.
class _AdaByronAddrUtils {
  /// Builds a Byron address from a public key, chain code, and address type.
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
        keyBytes: [...pubKeyBytes, ...chainCodeBytes],
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

/// Decodes an Ada Byron address.
class AdaByronAddrDecoder implements BlockchainAddressDecoder<BuBytes> {
  /// Decrypts an encrypted HD path using [hdPathKeyBytes].
  static Bip32Path decryptHdPath(
    List<int> hdPathEncBytes,
    List<int> hdPathKeyBytes,
  ) {
    return _AdaByronAddrHdPath.decrypt(hdPathEncBytes, hdPathKeyBytes);
  }

  /// Splits decoded bytes into (address root hash, encrypted HD path).
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
      throw CoreErrors.addressValidationFailed(reason: "Invalid address type");
    }
    if (network != null) {
      if (decAddr.payload.attrs.networkMagic != network.protocolMagic) {
        if (decAddr.payload.attrs.networkMagic == null &&
            network == ADANetwork.mainnet) {
          return decAddr.payload;
        }
        throw CoreErrors.addressValidationFailed(
          reason: "Invalid address network.",
        );
      }
    }
    return decAddr.payload;
  }

  ADAByronAddr decodeWithInfo(String addr) {
    return ADAByronAddr.decode(addr);
  }

  /// Decodes an address, returning its root hash (+ HD path if present).
  /// Throws if [addrType] or [network] don't match the decoded address.
  @override
  BuBytes decodeAddr(
    String addr, {
    ADAByronAddrTypes? addrType,
    ADANetwork? network,
  }) {
    final decAddr = _decodeAddr(
      addr,
      addrType: addrType ?? ADAByronAddrTypes.publicKey,
      network: network,
    );
    return BuBytes([
      ...decAddr.rootHashBytes,
      if (decAddr.attrs.hdPathEncBytes != null)
        ...decAddr.attrs.hdPathEncBytes!,
    ]);
  }
}

/// Encodes an Ada Byron Icarus address.
class AdaByronIcarusAddrEncoder implements BlockchainAddressEncoder {
  /// Builds the address object from a public key and chain code.
  ADAByronAddr encodeKeyWithInfo(
    List<int> pubKey, {
    ADANetwork network = ADANetwork.mainnet,
    List<int>? chainCode,
  }) {
    final List<int> chainCodeBytes = AddrKeyValidator.getAddrArg(
      chainCode,
      "chainCode",
    );
    final pubkeyBytes = AddrKeyValidator.validateAndGetEd25519KeyBytes(pubKey);
    return _AdaByronAddrUtils.encodeKey(
      pubkeyBytes,
      chainCodeBytes,
      ADAByronAddrTypes.publicKey,
      networkMagic: network.protocolMagic,
    );
  }

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

/// Encodes an Ada Byron Legacy address (includes an encrypted HD path).
class AdaByronLegacyAddrEncoder implements BlockchainAddressEncoder {
  /// Builds the address object from a public key, chain code, HD path and
  /// path-encryption key.
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
      throw CoreErrors.missingOrInvalidAddressArguments(
        reason:
            "HD path key shall be ${QuickCrypto.chacha20Polu1305Keysize}-byte long",
      );
    }
    final pubKeyBytes = AddrKeyValidator.validateAndGetEd25519KeyBytes(pubKey);
    return _AdaByronAddrUtils.encodeKey(
      pubKeyBytes,
      chainCodeBytes,
      ADAByronAddrTypes.publicKey,
      hdPathEncBytes: _AdaByronAddrHdPath.encrypt(hdPath, hdPathKeyBytes),
      networkMagic: network.protocolMagic,
    );
  }

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
