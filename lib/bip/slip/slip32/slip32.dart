import 'dart:typed_data';

import 'package:blockchain_utils/bech32/bech32_base.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_key_data.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_path.dart';
import 'package:blockchain_utils/bip/ecc/keys/i_keys.dart';
import 'package:blockchain_utils/exception/exception.dart';

import 'slip32_key_net_ver.dart';

/// A class containing constants related to SLIP-32 key serialization.
class Slip32KeySerConst {
  /// Standard SLIP-32 key network versions.
  ///
  /// These network versions are used for standard extended public (xpub) and private (xprv) keys.
  static const Slip32KeyNetVersions stdKeyNetVersions =
      Slip32KeyNetVersions(pubNetVar: "xpub", privNetVar: "xprv");
}

/// A class for serializing SLIP-32 extended keys and associated data.
class Slip32KeySerializer {
  /// Serialize an extended key along with path, chain code, and network version.
  ///
  /// This method takes the extended key's byte representation [keyBytes], the key's
  /// derivation path or Bip32 path [pathOrBip32Path], the chain code or Bip32 chain code,
  /// and the network version string [keyNetVerStr]. It serializes these components and
  /// returns the serialized key as a Bech32-encoded string.
  static String serialize(
    List<int> keyBytes,
    String pathOrBip32Path,
    Bip32ChainCode chainCodeOrBip32ChainCode,
    String keyNetVerStr,
  ) {
    Bip32Path path = Bip32PathParser.parse(pathOrBip32Path);
    Bip32ChainCode chainCode = chainCodeOrBip32ChainCode;

    // Serialize key
    final serKey = List<int>.from([
      ...Bip32Depth(path.length()).toBytes(Endian.little),
      ..._serializePath(path),
      ...chainCode.toBytes(),
      ...keyBytes,
    ]);

    return Bech32Encoder.encode(keyNetVerStr, serKey);
  }

  /// Serialize a Bip32Path into a byte representation.
  ///
  /// This method serializes a Bip32Path [path] into a byte representation and returns it.
  static List<int> _serializePath(Bip32Path path) {
    List<int> pathBytes = List.empty();
    for (final pathElem in path.elems) {
      pathBytes =
          List<int>.from([...pathBytes, ...pathElem.toBytes(Endian.little)]);
    }
    return pathBytes;
  }
}

/// A class for serializing SLIP-32 private keys.
class Slip32PrivateKeySerializer {
  /// Serialize a private key with a given path, chain code, and network version.
  ///
  /// This method serializes a private key [privKey] into a SLIP-32 format along with
  /// the specified path or Bip32 path [pathOrBip32Path], chain code, and private key
  /// network version [keyNetVer]. It returns the serialized private key as a Bech32-encoded string.
  static String serialize(
    IPrivateKey privKey,
    String pathOrBip32Path,
    dynamic chainCodeOrBip32ChainCode,
    Slip32KeyNetVersions keyNetVer,
  ) {
    return Slip32KeySerializer.serialize(
      List<int>.from([0x00, ...privKey.raw]),
      pathOrBip32Path,
      chainCodeOrBip32ChainCode,
      keyNetVer.private,
    );
  }
}

/// A class for serializing SLIP-32 public keys.
class Slip32PublicKeySerializer {
  /// Serialize a public key with a given path, chain code, and network version.
  ///
  /// This method serializes a public key [pubKey] into a SLIP-32 format along with
  /// the specified path or Bip32 path [pathOrBip32Path], chain code, and public key
  /// network version [keyNetVer]. It returns the serialized public key as a Bech32-encoded string.
  static String serialize(
    IPublicKey pubKey,
    String pathOrBip32Path,
    dynamic chainCodeOrBip32ChainCode,
    Slip32KeyNetVersions keyNetVer,
  ) {
    return Slip32KeySerializer.serialize(
      pubKey.compressed,
      pathOrBip32Path,
      chainCodeOrBip32ChainCode,
      keyNetVer.public,
    );
  }
}

/// A class representing a deserialized SLIP-32 key, including private and public keys.
class Slip32DeserializedKey {
  /// Raw key bytes
  final List<int> _keyBytes;

  /// Derivation path
  final Bip32Path path;

  /// Chain code
  final Bip32ChainCode chainCode;

  ///  Indicates if the key is public
  final bool isPublic;

  /// Constructor for creating a deserialized SLIP-32 key.
  ///
  /// The constructor takes the raw key bytes [_keyBytes], the derivation path [path],
  /// the chain code [chainCode], and a flag [isPublic] to indicate if the key is public.
  const Slip32DeserializedKey(
    this._keyBytes,
    this.path,
    this.chainCode,
    this.isPublic,
  );

  /// Get a copy of the key bytes.
  List<int> get keyBytes {
    return List<int>.from(_keyBytes);
  }
}

/// A class for deserializing SLIP-32 extended keys and associated data.
class Slip32KeyDeserializer {
  /// Deserialize a serialized SLIP-32 key.
  ///
  /// This method takes a Bech32-encoded string [serKeyStr] representing a serialized SLIP-32 key
  /// and the network versions [keyNetVer]. It deserializes the key, extracts its components, and
  /// returns a `Slip32DeserializedKey` object containing the key bytes, derivation path, chain code,
  /// and an indicator if the key is public.
  static Slip32DeserializedKey deserializeKey(
    String serKeyStr,
    Slip32KeyNetVersions keyNetVer,
  ) {
    bool isPublic = _getIfPublic(serKeyStr, keyNetVer);
    List<int> serKeyBytes = Bech32Decoder.decode(
        isPublic ? keyNetVer.public : keyNetVer.private, serKeyStr);

    // Get parts back
    List<dynamic> keyParts = _getPartsFromBytes(serKeyBytes, isPublic);
    List<int> keyBytes = keyParts[0];
    Bip32Path path = keyParts[1];
    Bip32ChainCode chainCode = keyParts[2];

    return Slip32DeserializedKey(keyBytes, path, chainCode, isPublic);
  }

  /// Determine if the serialized key is public or private based on network versions.
  static bool _getIfPublic(String serKeyStr, Slip32KeyNetVersions keyNetVer) {
    if (serKeyStr.substring(0, keyNetVer.public.length) == keyNetVer.public) {
      return true;
    } else if (serKeyStr.substring(0, keyNetVer.private.length) ==
        keyNetVer.private) {
      return false;
    } else {
      throw const ArgumentException("Invalid extended key (wrong net version)");
    }
  }

  /// Extract key parts from serialized key bytes.
  static List<dynamic> _getPartsFromBytes(
      List<int> serKeyBytes, bool isPublic) {
    int depthIdx = 0;
    int pathIdx = depthIdx + Bip32Depth.fixedLength();

    // Get back depth and path
    int depth = serKeyBytes[depthIdx];
    Bip32Path path = Bip32Path();
    for (int i = 0; i < depth; i++) {
      List<int> keyIndexBytes = serKeyBytes.sublist(
          pathIdx + (i * Bip32KeyIndex.fixedLength()),
          pathIdx + ((i + 1) * Bip32KeyIndex.fixedLength()));
      path = path.addElem(Bip32KeyIndex.fromBytes(keyIndexBytes));
    }

    // Get back chain code and key
    int chainCodeIdx = pathIdx + (depth * Bip32KeyIndex.fixedLength());
    int keyIdx = chainCodeIdx + Bip32ChainCode.fixedLength();

    List<int> chainCodeBytes = serKeyBytes.sublist(chainCodeIdx, keyIdx);
    List<int> keyBytes = serKeyBytes.sublist(keyIdx);

    // If private key, the first byte shall be zero and shall be removed
    if (!isPublic) {
      if (keyBytes[0] != 0) {
        throw ArgumentException(
            "Invalid extended private key (wrong secret: ${keyBytes[0]})");
      }
      keyBytes = keyBytes.sublist(1);
    }

    return [keyBytes, path, Bip32ChainCode(chainCodeBytes)];
  }
}
