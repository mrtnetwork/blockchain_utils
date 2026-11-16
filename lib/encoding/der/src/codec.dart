import 'package:blockchain_utils/encoding/der/src/constants.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/encoding/der/src/reader.dart';
import 'package:blockchain_utils/encoding/der/src/types.dart';
import 'package:blockchain_utils/encoding/der/src/utils.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

void _expectTag(DerNode node, int tag, String what) {
  if (node.tag != tag) {
    throw CoreErrors.cryptoFailed(
      "DerCodec",
      reason:
          'Expected $what (tag 0x${tag.toRadixString(16)}), got tag 0x${node.tag.toRadixString(16)}',
    );
  }
}

class DerCodec {
  // secp256k1 EC keys
  // ============================================================

  /// Builds a SEC1 "ECPrivateKey" DER structure.
  static SecretBytes encodeSecp256k1PrivateKeySec1(
    List<int> privateKey, {
    List<int>? publicKeyPoint, // compressed (33B) or uncompressed (65B) point
    bool includeCurveOid = true,
  }) {
    final priv = privateKey.asImmutableBytes;
    if (priv.length != 32) {
      throw CoreErrors.cryptoFailed(
        "encodeSecp256k1PrivateKeySec1",
        reason: 'secp256k1 private key must be 32 bytes',
      );
    }
    final parts = <int>[
      ...DerUtils.derSmallInt(1),
      ...DerUtils.derOctetString(priv),
    ];
    if (includeCurveOid) {
      parts.addAll(DerUtils.derContext(0, DerUtils.derOid(Oids.secp256k1)));
    }
    if (publicKeyPoint != null) {
      parts.addAll(
        DerUtils.derContext(1, DerUtils.derBitString(publicKeyPoint.asBytes)),
      );
    }
    return SecretBytes.take(DerUtils.derSequence(parts));
  }

  static Secp256k1Sec1Key decodeSecp256k1PrivateKeySec1(List<int> der) {
    final root = DerReader(der).readNode();
    _expectTag(root, DerTag.sequence, 'ECPrivateKey SEQUENCE');
    final fields = root.children();
    if (fields.length < 2) {
      throw CoreErrors.cryptoFailed(
        "decodeSecp256k1PrivateKeySec1",
        reason: 'Malformed ECPrivateKey',
      );
    }

    _expectTag(fields[0], DerTag.integer, 'version');
    if (fields[0].value.isNotEmpty && fields[0].value.last != 1) {
      throw CoreErrors.cryptoFailed(
        "decodeSecp256k1PrivateKeySec1",
        reason: 'Unsupported ECPrivateKey version',
      );
    }

    _expectTag(fields[1], DerTag.octetString, 'privateKey');
    final privateKey = fields[1].value;

    String? curveOid;
    BuBytes? publicKeyPoint;
    for (var i = 2; i < fields.length; i++) {
      final f = fields[i];
      if (f.tag == DerTag.ctx0) {
        final inner = DerReader(f.value).readNode();
        _expectTag(inner, DerTag.oid, 'namedCurve');
        curveOid = DerUtils.decodeOid(inner.value);
      } else if (f.tag == DerTag.ctx1) {
        final inner = DerReader(f.value).readNode();
        _expectTag(inner, DerTag.bitString, 'publicKey');
        if (inner.value.isEmpty) {
          throw CoreErrors.cryptoFailed(
            "decodeSecp256k1PrivateKeySec1",
            reason: 'Malformed publicKey',
          );
        }
        publicKeyPoint = inner.value.sublist(1); // drop unused-bits count byte
      }
    }
    return Secp256k1Sec1Key.from(
      privateKey: SecretBytes.take(privateKey),
      publicKeyPoint: publicKeyPoint?.asImmutableBytes,
      curveOid: curveOid,
    );
  }

  /// Wraps a secp256k1 private key in a PKCS8 "PrivateKeyInfo".
  /// The curve OID lives in the AlgorithmIdentifier; the nested SEC1
  /// structure omits it (matching common OpenSSL / RFC 5915 output).
  static SecretBytes encodeSecp256k1PrivateKeyPkcs8(
    List<int> privateKey, {
    List<int>? publicKeyPoint,
  }) {
    final algId = DerUtils.derSequence([
      ...DerUtils.derOid(Oids.ecPublicKey),
      ...DerUtils.derOid(Oids.secp256k1),
    ]);
    final sec1 = encodeSecp256k1PrivateKeySec1(
      privateKey,
      publicKeyPoint: publicKeyPoint,
      includeCurveOid: false,
    );
    return SecretBytes.take(
      DerUtils.derSequence([
        ...DerUtils.derSmallInt(0),
        ...algId,
        ...DerUtils.derOctetString(sec1),
      ]),
    );
  }

  static Secp256k1Pkcs8Key decodeSecp256k1PrivateKeyPkcs8(List<int> der) {
    final root = DerReader(der).readNode();
    _expectTag(root, DerTag.sequence, 'PrivateKeyInfo SEQUENCE');
    final fields = root.children();
    if (fields.length < 3) {
      throw CoreErrors.cryptoFailed(
        "decodeSecp256k1PrivateKeyPkcs8",
        reason: 'Malformed PrivateKeyInfo',
      );
    }

    _expectTag(fields[0], DerTag.integer, 'version');

    final algId = fields[1];
    _expectTag(algId, DerTag.sequence, 'AlgorithmIdentifier');
    final algFields = algId.children();
    if (algFields.isEmpty) {
      throw CoreErrors.cryptoFailed(
        "decodeSecp256k1PrivateKeyPkcs8",
        reason: 'Malformed AlgorithmIdentifier',
      );
    }
    _expectTag(algFields[0], DerTag.oid, 'algorithm OID');
    final algOid = DerUtils.decodeOid(algFields[0].value);
    if (algOid != Oids.ecPublicKey) {
      throw CoreErrors.cryptoFailed(
        "decodeSecp256k1PrivateKeyPkcs8",
        reason: 'Not an EC key (algorithm OID $algOid)',
      );
    }
    if (algFields.length > 1 && algFields[1].tag == DerTag.oid) {
      final curveOid = DerUtils.decodeOid(algFields[1].value);
      if (curveOid != Oids.secp256k1) {
        throw CoreErrors.cryptoFailed(
          "decodeSecp256k1PrivateKeyPkcs8",
          reason: 'Not a secp256k1 key (curve OID $curveOid)',
        );
      }
    }

    _expectTag(fields[2], DerTag.octetString, 'privateKey');
    final sec1 = decodeSecp256k1PrivateKeySec1(fields[2].value);
    return Secp256k1Pkcs8Key.from(sec1.privateKey, sec1.publicKeyPoint);
  }

  /// Builds a SubjectPublicKeyInfo (SPKI) for a raw secp256k1 EC point
  /// (0x04||X||Y uncompressed, or 0x02/0x03||X compressed).
  static BuBytes encodeSecp256k1PublicKeySpki(List<int> point) {
    final algId = DerUtils.derSequence([
      ...DerUtils.derOid(Oids.ecPublicKey),
      ...DerUtils.derOid(Oids.secp256k1),
    ]);
    return BuBytes(
      DerUtils.derSequence([...algId, ...DerUtils.derBitString(point.asBytes)]),
    );
  }

  static BuBytes decodeSecp256k1PublicKeySpki(List<int> der) {
    final root = DerReader(der).readNode();
    _expectTag(root, DerTag.sequence, 'SubjectPublicKeyInfo SEQUENCE');
    final fields = root.children();
    if (fields.length < 2) {
      throw CoreErrors.cryptoFailed(
        "decodeSecp256k1PublicKeySpki",
        reason: 'Malformed SubjectPublicKeyInfo',
      );
    }
    final algId = fields[0];
    _expectTag(algId, DerTag.sequence, 'AlgorithmIdentifier');
    final algFields = algId.children();
    if (algFields.isEmpty) {
      throw CoreErrors.cryptoFailed(
        "decodeSecp256k1PublicKeySpki",
        reason: 'Malformed AlgorithmIdentifier',
      );
    }
    final algOid = DerUtils.decodeOid(algFields[0].value);
    if (algOid != Oids.ecPublicKey) {
      throw CoreErrors.cryptoFailed(
        "decodeSecp256k1PublicKeySpki",
        reason: 'Not an EC key (algorithm OID $algOid)',
      );
    }
    if (algFields.length > 1) {
      final curveOid = DerUtils.decodeOid(algFields[1].value);
      if (curveOid != Oids.secp256k1) {
        throw CoreErrors.cryptoFailed(
          "decodeSecp256k1PublicKeySpki",
          reason: 'Not a secp256k1 key (curve OID $curveOid)',
        );
      }
    }
    _expectTag(fields[1], DerTag.bitString, 'subjectPublicKey');
    if (fields[1].value.isEmpty) {
      throw CoreErrors.cryptoFailed(
        "decodeSecp256k1PublicKeySpki",
        reason: 'Malformed subjectPublicKey',
      );
    }
    return BuBytes(fields[1].value.sublist(1)); // drop unused-bits count byte
  }

  /// Builds a SEC1 "ECPrivateKey" DER structure.
  static SecretBytes encodeSecp256r1PrivateKeySec1(
    List<int> privateKey, {
    List<int>? publicKeyPoint, // compressed (33B) or uncompressed (65B) point
    bool includeCurveOid = true,
  }) {
    final priv = privateKey.asImmutableBytes;
    if (priv.length != 32) {
      throw CoreErrors.cryptoFailed(
        "encodeSecp256r1PrivateKeySec1",
        reason: 'secp256r1 private key must be 32 bytes',
      );
    }
    final parts = <int>[
      ...DerUtils.derSmallInt(1),
      ...DerUtils.derOctetString(priv),
    ];
    if (includeCurveOid) {
      parts.addAll(DerUtils.derContext(0, DerUtils.derOid(Oids.secp256r1)));
    }
    if (publicKeyPoint != null) {
      parts.addAll(
        DerUtils.derContext(1, DerUtils.derBitString(publicKeyPoint.asBytes)),
      );
    }
    return SecretBytes.take(DerUtils.derSequence(parts));
  }

  static Secp256r1Sec1Key decodeSecp256r1PrivateKeySec1(List<int> der) {
    final root = DerReader(der).readNode();
    _expectTag(root, DerTag.sequence, 'ECPrivateKey SEQUENCE');
    final fields = root.children();
    if (fields.length < 2) {
      throw CoreErrors.cryptoFailed(
        "decodeSecp256r1PrivateKeySec1",
        reason: 'Malformed ECPrivateKey',
      );
    }

    _expectTag(fields[0], DerTag.integer, 'version');
    if (fields[0].value.isNotEmpty && fields[0].value.last != 1) {
      throw CoreErrors.cryptoFailed(
        "decodeSecp256r1PrivateKeySec1",
        reason: 'Unsupported ECPrivateKey version',
      );
    }

    _expectTag(fields[1], DerTag.octetString, 'privateKey');
    final privateKey = fields[1].value;

    String? curveOid;
    BuBytes? publicKeyPoint;
    for (var i = 2; i < fields.length; i++) {
      final f = fields[i];
      if (f.tag == DerTag.ctx0) {
        final inner = DerReader(f.value).readNode();
        _expectTag(inner, DerTag.oid, 'namedCurve');
        curveOid = DerUtils.decodeOid(inner.value);
      } else if (f.tag == DerTag.ctx1) {
        final inner = DerReader(f.value).readNode();
        _expectTag(inner, DerTag.bitString, 'publicKey');
        if (inner.value.isEmpty) {
          throw CoreErrors.cryptoFailed(
            "decodeSecp256r1PrivateKeySec1",
            reason: 'Malformed publicKey',
          );
        }
        publicKeyPoint = inner.value.sublist(1); // drop unused-bits count byte
      }
    }
    return Secp256r1Sec1Key.from(
      privateKey: SecretBytes.take(privateKey),
      publicKeyPoint: publicKeyPoint?.asImmutableBytes,
      curveOid: curveOid,
    );
  }

  /// Wraps a secp256r1 private key in a PKCS8 "PrivateKeyInfo".
  /// The curve OID lives in the AlgorithmIdentifier; the nested SEC1
  /// structure omits it (matching common OpenSSL / RFC 5915 output).
  static SecretBytes encodeSecp256r1PrivateKeyPkcs8(
    List<int> privateKey, {
    List<int>? publicKeyPoint,
  }) {
    final algId = DerUtils.derSequence([
      ...DerUtils.derOid(Oids.ecPublicKey),
      ...DerUtils.derOid(Oids.secp256r1),
    ]);
    final sec1 = encodeSecp256r1PrivateKeySec1(
      privateKey,
      publicKeyPoint: publicKeyPoint,
      includeCurveOid: false,
    );
    return SecretBytes.take(
      DerUtils.derSequence([
        ...DerUtils.derSmallInt(0),
        ...algId,
        ...DerUtils.derOctetString(sec1),
      ]),
    );
  }

  static Secp256r1Pkcs8Key decodeSecp256r1PrivateKeyPkcs8(List<int> der) {
    final root = DerReader(der).readNode();
    _expectTag(root, DerTag.sequence, 'PrivateKeyInfo SEQUENCE');
    final fields = root.children();
    if (fields.length < 3) {
      throw CoreErrors.cryptoFailed(
        "decodeSecp256r1PrivateKeyPkcs8",
        reason: 'Malformed PrivateKeyInfo',
      );
    }

    _expectTag(fields[0], DerTag.integer, 'version');

    final algId = fields[1];
    _expectTag(algId, DerTag.sequence, 'AlgorithmIdentifier');
    final algFields = algId.children();
    if (algFields.isEmpty) {
      throw CoreErrors.cryptoFailed(
        "decodeSecp256r1PrivateKeyPkcs8",
        reason: 'Malformed AlgorithmIdentifier',
      );
    }
    _expectTag(algFields[0], DerTag.oid, 'algorithm OID');
    final algOid = DerUtils.decodeOid(algFields[0].value);
    if (algOid != Oids.ecPublicKey) {
      throw CoreErrors.cryptoFailed(
        "decodeSecp256r1PrivateKeyPkcs8",
        reason: 'Not an EC key (algorithm OID $algOid)',
      );
    }
    if (algFields.length > 1 && algFields[1].tag == DerTag.oid) {
      final curveOid = DerUtils.decodeOid(algFields[1].value);
      if (curveOid != Oids.secp256r1) {
        throw CoreErrors.cryptoFailed(
          "decodeSecp256r1PrivateKeyPkcs8",
          reason: 'Not a secp256r1 key (curve OID $curveOid)',
        );
      }
    }

    _expectTag(fields[2], DerTag.octetString, 'privateKey');
    final sec1 = decodeSecp256r1PrivateKeySec1(fields[2].value);
    return Secp256r1Pkcs8Key.from(
      privateKey: sec1.privateKey,
      publicKeyPoint: sec1.publicKeyPoint,
    );
  }

  /// Builds a SubjectPublicKeyInfo (SPKI) for a raw secp256r1 EC point
  /// (0x04||X||Y uncompressed, or 0x02/0x03||X compressed).
  static BuBytes encodeSecp256r1PublicKeySpki(List<int> point) {
    final algId = DerUtils.derSequence([
      ...DerUtils.derOid(Oids.ecPublicKey),
      ...DerUtils.derOid(Oids.secp256r1),
    ]);
    return BuBytes(
      DerUtils.derSequence([...algId, ...DerUtils.derBitString(point.asBytes)]),
    );
  }

  static BuBytes decodeSecp256r1PublicKeySpki(List<int> der) {
    final root = DerReader(der).readNode();
    _expectTag(root, DerTag.sequence, 'SubjectPublicKeyInfo SEQUENCE');
    final fields = root.children();
    if (fields.length < 2) {
      throw CoreErrors.cryptoFailed(
        "decodeSecp256r1PublicKeySpki",
        reason: 'Malformed SubjectPublicKeyInfo',
      );
    }
    final algId = fields[0];
    _expectTag(algId, DerTag.sequence, 'AlgorithmIdentifier');
    final algFields = algId.children();
    if (algFields.isEmpty) {
      throw CoreErrors.cryptoFailed(
        "decodeSecp256r1PublicKeySpki",
        reason: 'Malformed AlgorithmIdentifier',
      );
    }
    final algOid = DerUtils.decodeOid(algFields[0].value);
    if (algOid != Oids.ecPublicKey) {
      throw CoreErrors.cryptoFailed(
        "decodeSecp256r1PublicKeySpki",
        reason: 'Not an EC key (algorithm OID $algOid)',
      );
    }
    if (algFields.length > 1) {
      final curveOid = DerUtils.decodeOid(algFields[1].value);
      if (curveOid != Oids.secp256r1) {
        throw CoreErrors.cryptoFailed(
          "decodeSecp256r1PublicKeySpki",
          reason: 'Not a secp256r1 key (curve OID $curveOid)',
        );
      }
    }
    _expectTag(fields[1], DerTag.bitString, 'subjectPublicKey');
    if (fields[1].value.isEmpty) {
      throw CoreErrors.cryptoFailed(
        "decodeSecp256r1PublicKeySpki",
        reason: 'Malformed subjectPublicKey',
      );
    }
    return BuBytes(fields[1].value.sublist(1)); // drop unused-bits count byte
  }

  /// PKCS8 PrivateKeyInfo for Ed25519. The "privateKey" OCTET STRING
  /// contains the DER of a further OCTET STRING wrapping the raw 32-byte
  /// seed (RFC 8410's "CurvePrivateKey").
  static SecretBytes encodeEd25519PrivateKeyPkcs8(List<int> seed) {
    if (seed.length != 32) {
      throw CoreErrors.cryptoFailed(
        "encodeEd25519PrivateKeyPkcs8",
        reason: 'Ed25519 private key (seed) must be 32 bytes',
      );
    }
    final algId = DerUtils.derSequence([...DerUtils.derOid(Oids.ed25519)]);
    final curvePrivateKey = DerUtils.derOctetString(seed);
    return SecretBytes.take(
      DerUtils.derSequence([
        ...DerUtils.derSmallInt(0),
        ...algId,
        ...DerUtils.derOctetString(curvePrivateKey),
      ]),
    );
  }

  static SecretBytes decodeEd25519PrivateKeyPkcs8(List<int> der) {
    final root = DerReader(der).readNode();
    _expectTag(root, DerTag.sequence, 'PrivateKeyInfo SEQUENCE');
    final fields = root.children();
    if (fields.length < 3) {
      throw CoreErrors.cryptoFailed(
        "decodeEd25519PrivateKeyPkcs8",
        reason: 'Malformed PrivateKeyInfo',
      );
    }

    _expectTag(fields[0], DerTag.integer, 'version');

    final algId = fields[1];
    _expectTag(algId, DerTag.sequence, 'AlgorithmIdentifier');
    final algChildren = algId.children();
    if (algChildren.isEmpty) {
      throw CoreErrors.cryptoFailed(
        "decodeEd25519PrivateKeyPkcs8",
        reason: 'Malformed AlgorithmIdentifier',
      );
    }
    final algOid = DerUtils.decodeOid(algChildren[0].value);
    if (algOid != Oids.ed25519) {
      throw CoreErrors.cryptoFailed(
        "decodeEd25519PrivateKeyPkcs8",
        reason: 'Not an Ed25519 key (algorithm OID $algOid)',
      );
    }

    _expectTag(fields[2], DerTag.octetString, 'privateKey');
    final innerNode = DerReader(fields[2].value).readNode();
    _expectTag(innerNode, DerTag.octetString, 'CurvePrivateKey');
    if (innerNode.value.length != 32) {
      throw CoreErrors.cryptoFailed(
        "decodeEd25519PrivateKeyPkcs8",
        reason: 'Ed25519 seed must be 32 bytes',
      );
    }
    return SecretBytes.take(innerNode.value);
  }

  /// SubjectPublicKeyInfo for Ed25519 — BIT STRING holds the raw 32-byte
  /// public key with zero unused bits.
  static BuBytes encodeEd25519PublicKeySpki(List<int> publicKey) {
    final pub = publicKey.asImmutableBytes;
    if (pub.length != 32) {
      throw CoreErrors.cryptoFailed(
        "encodeEd25519PublicKeySpki",
        reason: 'Ed25519 public key must be 32 bytes',
      );
    }
    final algId = DerUtils.derSequence([...DerUtils.derOid(Oids.ed25519)]);
    return BuBytes(
      DerUtils.derSequence([...algId, ...DerUtils.derBitString(pub)]),
    );
  }

  static BuBytes decodeEd25519PublicKeySpki(List<int> der) {
    final root = DerReader(der).readNode();
    _expectTag(root, DerTag.sequence, 'SubjectPublicKeyInfo SEQUENCE');
    final fields = root.children();
    if (fields.length < 2) {
      throw CoreErrors.cryptoFailed(
        "decodeEd25519PublicKeySpki",
        reason: 'Malformed SubjectPublicKeyInfo',
      );
    }
    final algId = fields[0];
    _expectTag(algId, DerTag.sequence, 'AlgorithmIdentifier');
    final algChildren = algId.children();
    if (algChildren.isEmpty) {
      throw CoreErrors.cryptoFailed(
        "decodeEd25519PublicKeySpki",
        reason: 'Malformed AlgorithmIdentifier',
      );
    }
    final algOid = DerUtils.decodeOid(algChildren[0].value);
    if (algOid != Oids.ed25519) {
      throw CoreErrors.cryptoFailed(
        "decodeEd25519PublicKeySpki",
        reason: 'Not an Ed25519 key (algorithm OID $algOid)',
      );
    }
    _expectTag(fields[1], DerTag.bitString, 'subjectPublicKey');
    if (fields[1].value.isEmpty) {
      throw CoreErrors.cryptoFailed(
        "decodeEd25519PublicKeySpki",
        reason: 'Malformed subjectPublicKey',
      );
    }
    final value = fields[1].value.sublist(1);
    if (value.length != 32) {
      throw CoreErrors.cryptoFailed(
        "decodeEd25519PublicKeySpki",
        reason: 'Ed25519 public key must be 32 bytes',
      );
    }
    return BuBytes(value);
  }

  // BLS12-381 (Internet Computer G2 public keys)
  // ============================================================
  //
  // BLS12-381 has no IETF/IANA-registered DER format at all — OpenSSL has
  // no support for it, and every real-world consumer (Ethereum consensus,
  // drand, Filecoin, Chia) exchanges keys as raw fixed-length bytes, not
  // ASN.1. The one exception is DFINITY/Internet Computer, which DER-wraps
  // BLS12-381 G2 *public* keys (their root key, subnet keys, etc.) using
  // the AlgorithmIdentifier OIDs below — verified byte-for-byte against
  // @dfinity/agent's `BLS12_381_G2_OID` / `DER_PREFIX` constants.
  //
  // There is no equivalent standard anywhere for BLS12-381 *private* keys
  // (not from DFINITY, not from anyone) — they're always raw scalars.
  // [encodeBls12381PrivateKeyRaw]/[decodeBls12381PrivateKeyRaw] reflect
  // that; the optional Pkcs8 wrapper further below is *our own*
  // construction (reusing the real IC algorithm OID for the container),
  // not something you'll find produced by IC tooling or anything else.

  /// SubjectPublicKeyInfo for a BLS12-381 G2 public key, matching the
  /// exact DER shape DFINITY/Internet Computer uses for root/subnet keys:
  /// `SEQUENCE { SEQUENCE { OID id-ic-bls12-381, OID curve }, BIT STRING(point) }`.
  /// [point] is normally the 96-byte compressed G2 point, but any length
  /// is accepted since the wrapper itself doesn't fix one.
  static BuBytes encodeBls12381PublicKeySpki(List<int> point) {
    final algId = DerUtils.derSequence([
      ...DerUtils.derOid(Oids.icBls12381),
      ...DerUtils.derOid(Oids.icBls12381G2),
    ]);
    return BuBytes(
      DerUtils.derSequence([...algId, ...DerUtils.derBitString(point.asBytes)]),
    );
  }

  static BuBytes decodeBls12381PublicKeySpki(List<int> der) {
    final root = DerReader(der).readNode();
    _expectTag(root, DerTag.sequence, 'SubjectPublicKeyInfo SEQUENCE');
    final fields = root.children();
    if (fields.length < 2) {
      throw CoreErrors.cryptoFailed(
        "decodeBls12381PublicKeySpki",
        reason: 'Malformed SubjectPublicKeyInfo',
      );
    }

    final algId = fields[0];
    _expectTag(algId, DerTag.sequence, 'AlgorithmIdentifier');
    final algFields = algId.children();
    if (algFields.isEmpty) {
      throw CoreErrors.cryptoFailed(
        "decodeBls12381PublicKeySpki",
        reason: 'Malformed AlgorithmIdentifier',
      );
    }
    _expectTag(algFields[0], DerTag.oid, 'algorithm OID');
    final algOid = DerUtils.decodeOid(algFields[0].value);
    if (algOid != Oids.icBls12381) {
      throw CoreErrors.cryptoFailed(
        "decodeBls12381PublicKeySpki",
        reason: 'Not an IC BLS12-381 key (algorithm OID $algOid)',
      );
    }
    if (algFields.length > 1 && algFields[1].tag == DerTag.oid) {
      final curveOid = DerUtils.decodeOid(algFields[1].value);
      if (curveOid != Oids.icBls12381G2) {
        throw CoreErrors.cryptoFailed(
          "decodeBls12381PublicKeySpki",
          reason: 'Not an IC BLS12-381 G2 key (curve OID $curveOid)',
        );
      }
    }

    _expectTag(fields[1], DerTag.bitString, 'subjectPublicKey');
    if (fields[1].value.isEmpty) {
      throw CoreErrors.cryptoFailed(
        "decodeBls12381PublicKeySpki",
        reason: 'Malformed subjectPublicKey',
      );
    }
    return BuBytes(fields[1].value.sublist(1)); // drop unused-bits count byte
  }

  /// Not ASN.1 — a validated pass-through for a raw BLS12-381 private key
  /// scalar (32 bytes). This is the format every real BLS12-381 consumer
  /// actually uses; there is no DER/PKCS8 standard to conform to here.
  static BuBytes encodeBls12381PrivateKeyRaw(List<int> privateKey) {
    final priv = privateKey.asImmutableBytes;
    if (priv.length != 32) {
      throw CoreErrors.cryptoFailed(
        "encodeBls12381PrivateKeyRaw",
        reason: 'BLS12-381 private key must be 32 bytes',
      );
    }
    return priv;
  }

  static SecretBytes decodeBls12381PrivateKeyRaw(
    List<int> raw, {
    bool wipeSource = false,
  }) {
    if (raw.length != 32) {
      throw CoreErrors.cryptoFailed(
        "decodeBls12381PrivateKeyRaw",
        reason: 'BLS12-381 private key must be 32 bytes',
      );
    }
    return SecretBytes(raw, wipeSource: wipeSource);
  }

  /// OPTIONAL, NON-STANDARD: wraps a raw BLS12-381 private key scalar in a
  /// PKCS8-shaped `PrivateKeyInfo`, reusing the real IC algorithm OID pair
  /// so it at least round-trips against [decodeBls12381PrivateKeyPkcs8] and
  /// carries a meaningful algorithm identifier. No implementation of ours
  /// or anyone else's (including DFINITY) produces or expects this for
  /// *private* keys — use [encodeBls12381PrivateKeyRaw] unless you
  /// specifically need an ASN.1 container for internal storage/interop.
  static SecretBytes encodeBls12381PrivateKeyPkcs8(List<int> privateKey) {
    if (privateKey.length != 32) {
      throw CoreErrors.cryptoFailed(
        "encodeBls12381PrivateKeyPkcs8",
        reason: 'BLS12-381 private key must be 32 bytes',
      );
    }
    final algId = DerUtils.derSequence([
      ...DerUtils.derOid(Oids.icBls12381),
      ...DerUtils.derOid(Oids.icBls12381G2),
    ]);
    return SecretBytes.take(
      DerUtils.derSequence([
        ...DerUtils.derSmallInt(0),
        ...algId,
        ...DerUtils.derOctetString(privateKey),
      ]),
    );
  }

  static SecretBytes decodeBls12381PrivateKeyPkcs8(List<int> der) {
    final root = DerReader(der).readNode();
    _expectTag(root, DerTag.sequence, 'PrivateKeyInfo SEQUENCE');
    final fields = root.children();
    if (fields.length < 3) {
      throw CoreErrors.cryptoFailed(
        "decodeBls12381PrivateKeyPkcs8",
        reason: 'Malformed PrivateKeyInfo',
      );
    }

    _expectTag(fields[0], DerTag.integer, 'version');

    final algId = fields[1];
    _expectTag(algId, DerTag.sequence, 'AlgorithmIdentifier');
    final algFields = algId.children();
    if (algFields.isEmpty) {
      throw CoreErrors.cryptoFailed(
        "decodeBls12381PrivateKeyPkcs8",
        reason: 'Malformed AlgorithmIdentifier',
      );
    }
    _expectTag(algFields[0], DerTag.oid, 'algorithm OID');
    final algOid = DerUtils.decodeOid(algFields[0].value);
    if (algOid != Oids.icBls12381) {
      throw CoreErrors.cryptoFailed(
        "decodeBls12381PrivateKeyPkcs8",
        reason: 'Not an IC BLS12-381 key (algorithm OID $algOid)',
      );
    }

    _expectTag(fields[2], DerTag.octetString, 'privateKey');
    return decodeBls12381PrivateKeyRaw(fields[2].value, wipeSource: true);
  }

  // ECDSA signatures (ECDSA-Sig-Value, RFC 3279 §2.2.3 / SEC1 §C.3)
  // ============================================================
  //
  // `ECDSA-Sig-Value ::= SEQUENCE { r INTEGER, s INTEGER }` — just two
  // integers, no algorithm identifier (unlike the key structures above).
  // Built on [toDer], which stays generic since the same
  // SEQUENCE-of-INTEGER shape covers other schemes too (e.g. DSA).

  /// DER-encodes an ECDSA signature's `r`/`s` as `ECDSA-Sig-Value`.
  static BuBytes encodeEcdsaSignatureDer(List<int> r, List<int> s) {
    return toDer([r, s]);
  }

  /// Decodes an `ECDSA-Sig-Value`, returning `r`/`s` as fixed 32-byte
  /// unsigned big-endian scalars (any DER sign-byte padding stripped, any
  /// short encoding zero-padded back out) — the shape [IECDSASignature]
  /// expects.
  static (BuBytes r, BuBytes s) decodeEcdsaSignatureDer(List<int> der) {
    final root = DerReader(der).readNode();
    _expectTag(root, DerTag.sequence, 'ECDSA-Sig-Value SEQUENCE');
    final fields = root.children();
    if (fields.length < 2) {
      throw CoreErrors.cryptoFailed(
        "decodeEcdsaSignatureDer",
        reason: 'Malformed ECDSA-Sig-Value',
      );
    }
    _expectTag(fields[0], DerTag.integer, 'r');
    _expectTag(fields[1], DerTag.integer, 's');
    return (
      _decodeUnsignedScalar32(fields[0].value, 'r'),
      _decodeUnsignedScalar32(fields[1].value, 's'),
    );
  }

  static BuBytes _decodeUnsignedScalar32(List<int> value, String name) {
    var v = value;
    if (v.length == 33 && v[0] == 0x00) {
      v = v.sublist(1); // DER's two's-complement sign-guard byte
    }
    if (v.length > 32) {
      throw CoreErrors.cryptoFailed(
        "decodeEcdsaSignatureDer",
        reason: '$name is too large for a 32-byte scalar',
      );
    }
    if (v.length == 32) return BuBytes(v);
    return BuBytes([...List.filled(32 - v.length, 0), ...v]);
  }

  /// DER-encodes a SEQUENCE of INTEGERs from raw unsigned big-endian byte
  /// arrays (e.g. `[signature.r, signature.s]`).
  ///
  /// Unlike `BigInt.toBeBytes()`, a fixed-length byte array (e.g. 32 bytes)
  /// may carry leading zero bytes that aren't part of the integer's minimal
  /// representation — those are stripped before DER-encoding each value.
  static BuBytes toDer(List<List<int>> values) {
    final List<BuBytes> encodedIntegers =
        values.map((bytes) => _encodeInteger(bytes)).toList();
    final content = encodedIntegers.expand((e) => e);
    final BuBytes lengthBytes = _encodeLength(content.length);
    return BuBytes([0x30, ...lengthBytes, ...encodedIntegers.expand((e) => e)]);
  }

  static BuBytes _encodeLength(int length) {
    if (length < 128) {
      return BuBytes([length]);
    } else {
      final encodeLen = length.toBeBytes();
      return BuBytes([0x80 | encodeLen.length, ...encodeLen]);
    }
  }

  /// Encodes a raw unsigned big-endian byte array as a DER INTEGER.
  ///
  /// - Strips leading zero bytes down to the minimal representation (a
  ///   32-byte `r`/`s` with a small value would otherwise carry leading
  ///   zero padding that isn't part of the integer).
  /// - Re-adds a single `0x00` prefix if the resulting high bit is set, so
  ///   the value doesn't read as negative (DER integers are two's
  ///   complement).
  /// - An all-zero input still encodes as the integer zero (`0x02 0x01 0x00`).
  static BuBytes _encodeInteger(List<int> bytes) {
    if (bytes.isEmpty) {
      throw CoreErrors.cryptoFailed(
        "toDer",
        reason: 'Cannot DER-encode an empty INTEGER.',
      );
    }
    int start = 0;
    while (start < bytes.length - 1 && bytes[start] == 0) {
      start++;
    }
    final List<int> s = bytes.sublist(start);

    final int num = s[0];
    if (num <= 0x7F) {
      return BuBytes([0x02, ..._encodeLength(s.length), ...s]);
    } else {
      return BuBytes([0x02, ..._encodeLength(s.length + 1), 0x00, ...s]);
    }
  }
}
