import 'package:blockchain_utils/encoding/base58/base58.dart';
import 'package:blockchain_utils/protocol/bip/bip/bip32/bip32_const.dart';
import 'package:blockchain_utils/protocol/bip/bip/bip32/bip32_key_data.dart';
import 'package:blockchain_utils/protocol/bip/bip/bip32/bip32_key_net_ver.dart';
import 'package:blockchain_utils/crypto/crypto/keys/keys.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/utils/binary/src/utils.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';
import 'package:blockchain_utils/utils/numbers/utils/int_utils.dart';

/// The `Bip32KeySerConst` class contains constants related to the serialization
/// of Bip32 keys.
class Bip32KeySerConst {
  // Serialized public key length in bytes
  static const int serializedPubKeyByteLen = 78;
  // Serialized private key length in bytes
  static const List<int> serializedPrivKeyByteLen = [78, 110];
}

/// BIP32 key serializer class.
/// It serializes private/public keys.
class _Bip32KeySerializer {
  static BuBytes serializeBytes(
    List<int> keyBytes,
    Bip32KeyData keyData,
    List<int>? keyNetVerBytes,
  ) {
    return BuBytes.unsafe([
      ...keyNetVerBytes ?? [],
      ...keyData.depth.toBytes(),
      ...keyData.fingerPrint.toBytes(),
      ...keyData.index.toBytes(),
      ...keyData.chainCode.toBytes(),
      ...keyBytes,
    ]);
  }

  /// Serialize the specified key bytes.
  static String serialize(
    List<int> keyBytes,
    Bip32KeyData keyData,
    List<int> keyNetVerBytes,
  ) {
    return Base58Encoder.encodeWithChecksum(
      serializeBytes(keyBytes, keyData, keyNetVerBytes),
    );
  }
}

/// BIP32 private key serializer class.
/// It serializes private keys.
class Bip32PrivateKeySerializer {
  /// Serialize a private key.
  static String serialize(
    IPrivateKey privKey,
    Bip32KeyData keyData, [
    Bip32KeyNetVersions? keyNetVer,
  ]) {
    keyNetVer ??= Bip32Const.mainNetKeyNetVersions;
    return _Bip32KeySerializer.serialize(
      privKey.toBytes().useValue((p) => [0x00, ...p], zero: true),
      keyData,
      keyNetVer.private,
    );
  }

  static BuBytes serializeBytes({
    required IPrivateKey privKey,
    required Bip32KeyData keyData,
    Bip32KeyNetVersions? keyNetVer,
    bool withPrefix = true,
  }) {
    keyNetVer ??= Bip32Const.mainNetKeyNetVersions;
    return _Bip32KeySerializer.serializeBytes(
      privKey.toBytes().useValue((p) => [0x00, ...p], zero: true),
      keyData,
      withPrefix ? keyNetVer.private : null,
    );
  }
}

//. BIP32 public key serializer class.
/// It serializes public keys.
class Bip32PublicKeySerializer {
  static BuBytes serializePublicKey(
    IPublicKey pubKey, {
    CryptoKeyEncoding mode = CryptoKeyEncoding.base,
  }) {
    final toBytes = pubKey.toBytes(mode: mode);
    if (pubKey.type.isED25519()) {
      return BuBytes([0x00, ...toBytes]);
    }
    return toBytes;
  }

  /// Serialize a public key.
  static String serialize(
    IPublicKey pubKey,
    Bip32KeyData keyData, [
    Bip32KeyNetVersions? keyNetVer,
  ]) {
    keyNetVer ??= Bip32Const.mainNetKeyNetVersions;

    return _Bip32KeySerializer.serialize(
      serializePublicKey(pubKey),
      keyData,
      keyNetVer.public,
    );
  }

  static BuBytes serializeBytes({
    required IPublicKey pubKey,
    required Bip32KeyData keyData,
    required Bip32KeyNetVersions? keyNetVer,
    bool withPrefix = true,
  }) {
    keyNetVer ??= Bip32Const.mainNetKeyNetVersions;
    return _Bip32KeySerializer.serializeBytes(
      serializePublicKey(pubKey),
      keyData,
      withPrefix ? keyNetVer.public : null,
    );
  }
}

/// BIP32 deserialized key class.
/// It represents a key deserialized with the Bip32KeyDeserializer.
class Bip32DeserializedKey with SecretState {
  /// Key bytes
  final SecretBytes _keyBytes;

  /// Key data
  final Bip32KeyData keyData;

  /// True if the key is public, false otherwise
  final bool isPublic;

  Bip32DeserializedKey(List<int> keyBytes, this.keyData, this.isPublic)
    : _keyBytes = SecretBytes(keyBytes);

  BuBytes toBytes() => _keyBytes.toBytes();

  BuBytes keyBytes(CryptoKeyType curve) {
    if (isPublic && curve.isED25519()) {
      if (_keyBytes.length !=
          Ed25519KeysConst.pubKeyByteLen +
              Ed25519KeysConst.pubKeyPrefix.length) {
        throw BuError(
          DefaultErrorType.badPublicKey,
          "Invalid bip32 public key bytes.",
        );
      }
      return BuBytes(_keyBytes.sublist(Ed25519KeysConst.pubKeyPrefix.length));
    }
    return toBytes();
  }

  @override
  void dispose() {
    _keyBytes.zero();
  }
}

/// BIP32 key deserializer class.
/// It deserializes an extended key.
class Bip32KeyDeserializer {
  static BuBytes deserializePublicKey(List<int> pubKey, CryptoKeyType curve) {
    if (curve.isED25519()) {
      if (pubKey.length !=
          Ed25519KeysConst.pubKeyByteLen +
              Ed25519KeysConst.pubKeyPrefix.length) {
        throw BuError(
          DefaultErrorType.badPublicKey,
          "Invalid bip32 public key bytes.",
        );
      }
      return BuBytes(pubKey.sublist(Ed25519KeysConst.pubKeyPrefix.length));
    }
    return pubKey.asBytes;
  }

  static Bip32DeserializedKey deserializeKeyBytes({
    required List<int> serKeyBytes,
    required bool isPublic,
    required bool withPrefix, // true: bytes start with the 4-byte version
  }) {
    // Bytes to skip before the depth byte
    final verLen =
        withPrefix ? 0 : Bip32KeyNetVersionsConst.keyNetVersionByteLen;
    final skipLen =
        withPrefix ? Bip32KeyNetVersionsConst.keyNetVersionByteLen : 0;

    // Expected lengths: 78 (pub), 78 or 110 (priv) with version; 74/74/106 without
    final pubLen = Bip32KeySerConst.serializedPubKeyByteLen - verLen;
    final validPrivLen = Bip32KeySerConst.serializedPrivKeyByteLen.any(
      (l) => l - verLen == serKeyBytes.length,
    );

    // [version(4)] + depth(1) + fingerprint(4) + index(4) + chain code(32)
    final keyDataOffset = skipLen + 41;
    if (serKeyBytes.length <= keyDataOffset) {
      throw BuError(
        DefaultErrorType.invalidLength,
        'Invalid extended key length.',
      );
    }
    final keyPrefixByte = serKeyBytes[keyDataOffset];

    if (isPublic) {
      if (serKeyBytes.length != pubLen) {
        throw BuError(
          DefaultErrorType.badPublicKey,
          'Invalid extended public key.',
        );
      }
    } else {
      if (!validPrivLen) {
        throw BuError(
          DefaultErrorType.badPrivateKey,
          'Invalid extended private key.',
        );
      }
      if (keyPrefixByte != 0x00) {
        throw BuError(
          DefaultErrorType.badPrivateKey,
          'Invalid extended private key prefix.',
        );
      }
    }

    return deserializeBytes(serKeyBytes, isPublic, offset: skipLen);
  }

  /// Deserialize a key.
  static Bip32DeserializedKey deserializeKey(
    String serKeyStr, {
    required Bip32KeyNetVersions keyNetVer,
  }) {
    final serKeyBytes = Base58Decoder.decodeWithChecksum(serKeyStr);
    final isPubKey = _getIfPublic(serKeyBytes, keyNetVer);
    return deserializeKeyBytes(
      serKeyBytes: serKeyBytes,
      isPublic: isPubKey,
      withPrefix: true,
    );
  }

  static Bip32DeserializedKey deserializeStrKey(
    String serKeyStr, {
    required bool isPublic,
  }) {
    final serKeyBytes = Base58Decoder.decodeWithChecksum(serKeyStr);
    return deserializeKeyBytes(
      serKeyBytes: serKeyBytes,
      isPublic: isPublic,
      withPrefix: true,
    );
  }

  /// Get if the key is public.
  static bool _getIfPublic(
    List<int> serKeyBytes,
    Bip32KeyNetVersions keyNetVer,
  ) {
    final hasValidLength = [
      ...Bip32KeySerConst.serializedPrivKeyByteLen,
      Bip32KeySerConst.serializedPubKeyByteLen,
    ].contains(serKeyBytes.length);
    if (hasValidLength) {
      final keyNetVerGot = serKeyBytes.sublist(
        0,
        Bip32KeyNetVersionsConst.keyNetVersionByteLen,
      );
      if (BytesUtils.bytesEqual(keyNetVerGot, keyNetVer.public)) {
        return true;
      } else if (BytesUtils.bytesEqual(keyNetVerGot, keyNetVer.private)) {
        return false;
      } else {
        throw const BuError(
          DefaultErrorType.invalidArgument,
          'Incorrect extended key net version.',
        );
      }
    }
    throw BuError(
      DefaultErrorType.invalidLength,
      'Invalid extended key length.',
    );
  }

  /// Get back key parts from serialized key bytes.
  static Bip32DeserializedKey deserializeBytes(
    List<int> serKeyBytes,
    bool isPublic, {
    int offset = Bip32KeyNetVersionsConst.keyNetVersionByteLen,
  }) {
    final depthIdx = offset;
    final fprintIdx = depthIdx + Bip32KeyDataConst.depthByteLen;
    final keyIndexIdx = fprintIdx + Bip32KeyDataConst.fingerprintByteLen;
    final chainCodeIdx = keyIndexIdx + Bip32KeyDataConst.keyIndexByteLen;
    final keyIdx = chainCodeIdx + Bip32KeyDataConst.chaincodeByteLen;

    // Get parts
    final depth = serKeyBytes[depthIdx];
    final fprintBytes = serKeyBytes.sublist(fprintIdx, keyIndexIdx);
    final keyIndexBytes = serKeyBytes.sublist(keyIndexIdx, chainCodeIdx);
    final chainCodeBytes = serKeyBytes.sublist(chainCodeIdx, keyIdx);
    var keyBytes = serKeyBytes.sublist(keyIdx);

    final keyData = Bip32KeyData(
      depth: Bip32Depth(depth),
      index: Bip32KeyIndex(IntUtils.fromBytes(keyIndexBytes)),
      chainCode: Bip32ChainCode(chainCodeBytes),
      fingerPrint: Bip32FingerPrint(fprintBytes),
    );

    // If private key, the first byte shall be zero and shall be removed
    if (!isPublic) {
      if (keyBytes[0] != 0) {
        throw BuError(
          DefaultErrorType.badPrivateKey,
          'Incorrect extended private key.',
        );
      }
      keyBytes = keyBytes.sublist(1);
    }

    return Bip32DeserializedKey(keyBytes, keyData, isPublic);
  }
}
