import 'package:blockchain_utils/base58/base58.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_const.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_ex.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_key_data.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_key_net_ver.dart';
import 'package:blockchain_utils/bip/ecc/keys/i_keys.dart';
import 'package:blockchain_utils/utils/utils.dart';

/// The `Bip32KeySerConst` class contains constants related to the serialization
/// of Bip32 keys. These constants specify the length of serialized public and
/// private keys in bytes. It provides a convenient way to access these values
/// in your code.
class Bip32KeySerConst {
  // Serialized public key length in bytes
  static const int serializedPubKeyByteLen = 78;
  // Serialized private key length in bytes
  static const List<int> serializedPrivKeyByteLen = [78, 110];
}

/// BIP32 key serializer class.
/// It serializes private/public keys.
class _Bip32KeySerializer {
  /// Serialize the specified key bytes.
  static String serialize(
      List<int> keyBytes, Bip32KeyData keyData, List<int> keyNetVerBytes) {
    List<int> serKey = List<int>.from([
      ...keyNetVerBytes,
      ...keyData.depth.toBytes(),
      ...keyData.parentFingerPrint.toBytes(),
      ...keyData.index.toBytes(),
      ...keyData.chainCode.toBytes(),
      ...keyBytes
    ]);
    return Base58Encoder.checkEncode(serKey);
  }
}

/// BIP32 private key serializer class.
/// It serializes private keys.
class Bip32PrivateKeySerializer {
  /// Serialize a private key.
  static String serialize(IPrivateKey privKey, Bip32KeyData keyData,
      [Bip32KeyNetVersions? keyNetVer]) {
    keyNetVer ??= Bip32Const.mainNetKeyNetVersions;
    return _Bip32KeySerializer.serialize(
        List<int>.from([0x00, ...privKey.raw]), keyData, keyNetVer.private);
  }
}

//. BIP32 public key serializer class.
/// It serializes public keys.
class Bip32PublicKeySerializer {
  /// Serialize a public key.
  static String serialize(IPublicKey pubKey, Bip32KeyData keyData,
      [Bip32KeyNetVersions? keyNetVer]) {
    keyNetVer ??= Bip32Const.mainNetKeyNetVersions;
    return _Bip32KeySerializer.serialize(
        pubKey.compressed, keyData, keyNetVer.public);
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
      : _keyBytes = keyBytes;

  List<int> get keyBytes {
    return List<int>.from(_keyBytes);
  }
}

/// BIP32 key deserializer class.
/// It deserializes an extended key.
class Bip32KeyDeserializer {
  /// Deserialize a key.
  static Bip32DeserializedKey deserializeKey(String serKeyStr,
      {Bip32KeyNetVersions? keyNetVer}) {
    final serKeyBytes = Base58Decoder.checkDecode(serKeyStr);

    // Get if key is public/private depending on the net version
    final isPublic = _getIfPublic(
        serKeyBytes, keyNetVer ?? Bip32Const.mainNetKeyNetVersions);

    // Validate length
    if (isPublic &&
        serKeyBytes.length != Bip32KeySerConst.serializedPubKeyByteLen) {
      throw Bip32KeyError(
          'Invalid extended public key (wrong length: ${serKeyBytes.length})');
    }
    if (!isPublic &&
        !Bip32KeySerConst.serializedPrivKeyByteLen
            .contains(serKeyBytes.length)) {
      throw Bip32KeyError(
          'Invalid extended private key (wrong length: ${serKeyBytes.length})');
    }

    // Get parts back
    final keyParts = _getPartsFromBytes(serKeyBytes, isPublic);

    return Bip32DeserializedKey(keyParts.item1, keyParts.item2, isPublic);
  }

  /// Get if the key is public.
  static bool _getIfPublic(
      List<int> serKeyBytes, Bip32KeyNetVersions keyNetVer) {
    final keyNetVerGot = serKeyBytes.sublist(0, Bip32KeyNetVersions.length);

    if (BytesUtils.bytesEqual(keyNetVerGot, keyNetVer.public)) {
      return true;
    } else if (BytesUtils.bytesEqual(keyNetVerGot, keyNetVer.private)) {
      return false;
    } else {
      throw Bip32KeyError(
          'Invalid extended key (wrong net version: ${BytesUtils.toHexString(keyNetVerGot)})');
    }
  }

  /// Get back key parts from serialized key bytes.
  static Tuple<List<int>, Bip32KeyData> _getPartsFromBytes(
      List<int> serKeyBytes, bool isPublic) {
    final depthIdx = Bip32KeyNetVersions.length;
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
        parentFingerPrint: Bip32FingerPrint(fprintBytes));

    // If private key, the first byte shall be zero and shall be removed
    if (!isPublic) {
      if (keyBytes[0] != 0) {
        throw Bip32KeyError(
            'Invalid extended private key (wrong secret: ${keyBytes[0]})');
      }
      keyBytes = keyBytes.sublist(1);
    }

    return Tuple(keyBytes, keyData);
  }
}
