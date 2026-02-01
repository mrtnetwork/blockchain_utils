import 'package:blockchain_utils/base58/base58.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_const.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_ex.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_key_data.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_key_net_ver.dart';
import 'package:blockchain_utils/bip/ecc/keys/i_keys.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';
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
  static List<int> serializeBytes(
    List<int> keyBytes,
    Bip32KeyData keyData,
    List<int>? keyNetVerBytes,
  ) {
    return [
      ...keyNetVerBytes ?? [],
      ...keyData.depth.toBytes(),
      ...keyData.fingerPrint.toBytes(),
      ...keyData.index.toBytes(),
      ...keyData.chainCode.toBytes(),
      ...keyBytes,
    ];
  }

  /// Serialize the specified key bytes.
  static String serialize(
    List<int> keyBytes,
    Bip32KeyData keyData,
    List<int> keyNetVerBytes,
  ) {
    return Base58Encoder.checkEncode(
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
      [0x00, ...privKey.raw],
      keyData,
      keyNetVer.private,
    );
  }

  static List<int> serializeBytes({
    required IPrivateKey privKey,
    required Bip32KeyData keyData,
    Bip32KeyNetVersions? keyNetVer,
    bool withPrefix = true,
  }) {
    keyNetVer ??= Bip32Const.mainNetKeyNetVersions;
    return _Bip32KeySerializer.serializeBytes(
      [0x00, ...privKey.raw],
      keyData,
      withPrefix ? keyNetVer.private : null,
    );
  }
}

//. BIP32 public key serializer class.
/// It serializes public keys.
class Bip32PublicKeySerializer {
  /// Serialize a public key.
  static String serialize(
    IPublicKey pubKey,
    Bip32KeyData keyData, [
    Bip32KeyNetVersions? keyNetVer,
  ]) {
    keyNetVer ??= Bip32Const.mainNetKeyNetVersions;
    return _Bip32KeySerializer.serialize(
      pubKey.compressed,
      keyData,
      keyNetVer.public,
    );
  }

  static List<int> serializeBytes({
    required IPublicKey pubKey,
    required Bip32KeyData keyData,
    required Bip32KeyNetVersions? keyNetVer,
    bool withPrefix = true,
  }) {
    keyNetVer ??= Bip32Const.mainNetKeyNetVersions;
    return _Bip32KeySerializer.serializeBytes(
      pubKey.compressed,
      keyData,
      withPrefix ? keyNetVer.private : null,
    );
  }
}

/// BIP32 deserialized key class.
/// It represents a key deserialized with the Bip32KeyDeserializer.
class Bip32DeserializedKey {
  /// Key bytes
  final List<int> _keyBytes;

  /// Key data
  final Bip32KeyData keyData;

  /// True if the key is public, false otherwise
  final bool isPublic;

  Bip32DeserializedKey(List<int> keyBytes, this.keyData, this.isPublic)
    : _keyBytes = keyBytes.asImmutableBytes;

  List<int> get keyBytes {
    return _keyBytes.clone();
  }
}

/// BIP32 key deserializer class.
/// It deserializes an extended key.
class Bip32KeyDeserializer {
  static Bip32DeserializedKey deserializeKeyBytes(
    List<int> serKeyBytes, {
    Bip32KeyNetVersions? keyNetVer,
  }) {
    // Get if key is public/private depending on the net version
    final isPublic = _getIfPublic(
      serKeyBytes,
      keyNetVer ?? Bip32Const.mainNetKeyNetVersions,
    );

    // Validate length
    if (isPublic &&
        serKeyBytes.length != Bip32KeySerConst.serializedPubKeyByteLen) {
      throw Bip32KeyError('Invalid extended public key.');
    }
    if (!isPublic &&
        !Bip32KeySerConst.serializedPrivKeyByteLen.contains(
          serKeyBytes.length,
        )) {
      throw Bip32KeyError('Invalid extended private key.');
    }

    // Get parts back
    final keyParts = _getPartsFromBytes(serKeyBytes, isPublic);

    return Bip32DeserializedKey(keyParts.$1, keyParts.$2, isPublic);
  }

  static Bip32DeserializedKey deserializeKeyBytesWithoutPrefix(
    List<int> serKeyBytes, {
    bool isPublic = false,
  }) {
    // Validate length
    if (isPublic &&
        serKeyBytes.length !=
            (Bip32KeySerConst.serializedPubKeyByteLen -
                Bip32KeyNetVersionsConst.keyNetVersionByteLen)) {
      throw Bip32KeyError('Invalid extended public key.');
    }
    if (!isPublic &&
        !Bip32KeySerConst.serializedPrivKeyByteLen.contains(
          serKeyBytes.length + Bip32KeyNetVersionsConst.keyNetVersionByteLen,
        )) {
      throw Bip32KeyError('Invalid extended private key.');
    }

    // Get parts back
    final keyParts = _getPartsFromBytes(serKeyBytes, isPublic, offset: 0);

    return Bip32DeserializedKey(keyParts.$1, keyParts.$2, isPublic);
  }

  /// Deserialize a key.
  static Bip32DeserializedKey deserializeKey(
    String serKeyStr, {
    Bip32KeyNetVersions? keyNetVer,
  }) {
    final serKeyBytes = Base58Decoder.checkDecode(serKeyStr);
    return deserializeKeyBytes(serKeyBytes, keyNetVer: keyNetVer);
  }

  /// Get if the key is public.
  static bool _getIfPublic(
    List<int> serKeyBytes,
    Bip32KeyNetVersions keyNetVer,
  ) {
    final keyNetVerGot = serKeyBytes.sublist(0, Bip32KeyNetVersions.length);

    if (BytesUtils.bytesEqual(keyNetVerGot, keyNetVer.public)) {
      return true;
    } else if (BytesUtils.bytesEqual(keyNetVerGot, keyNetVer.private)) {
      return false;
    } else {
      throw Bip32KeyError(
        'Incorrect extended key net version.',
        details: {"netversion": BytesUtils.toHexString(keyNetVerGot)},
      );
    }
  }

  /// Get back key parts from serialized key bytes.
  static (List<int>, Bip32KeyData) _getPartsFromBytes(
    List<int> serKeyBytes,
    bool isPublic, {
    int offset = Bip32KeyNetVersionsConst.keyNetVersionByteLen,
  }) {
    final depthIdx = offset;
    final fprintIdx = depthIdx + Bip32Depth.fixedLength();
    final keyIndexIdx = fprintIdx + Bip32FingerPrint.fixedLength();
    final chainCodeIdx = keyIndexIdx + Bip32KeyIndex.fixedLength();
    final keyIdx = chainCodeIdx + Bip32ChainCode.fixedLength();

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
        throw Bip32KeyError('Incorrect extended private key.');
      }
      keyBytes = keyBytes.sublist(1);
    }

    return (keyBytes, keyData);
  }
}
