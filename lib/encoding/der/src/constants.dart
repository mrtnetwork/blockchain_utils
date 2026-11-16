class DerTag {
  static const int integer = 0x02;
  static const int bitString = 0x03;
  static const int octetString = 0x04;
  static const int nullTag = 0x05;
  static const int oid = 0x06;
  static const int sequence = 0x30;
  static const int ctx0 = 0xA0; // context-specific constructed [0]
  static const int ctx1 = 0xA1; // context-specific constructed [1]
}

class Oids {
  static const String ecPublicKey = '1.2.840.10045.2.1'; // id-ecPublicKey
  static const String secp256k1 = '1.3.132.0.10'; // secp256k1 named curve
  static const String secp256r1 =
      '1.2.840.10045.3.1.7'; // secp256r1 / prime256v1 / NIST P-256
  static const String ed25519 = '1.3.101.112'; // id-Ed25519 (RFC 8410)

  // BLS12-381 has no IETF/IANA-registered OID. The pair below is the one
  // actually shipped by DFINITY/Internet Computer (enterprise arc 44668)
  // to DER-wrap BLS12-381 G2 public keys — e.g. the IC root key and
  // subnet keys embedded in `SubjectPublicKeyInfo`-shaped certificates.
  // Verified byte-for-byte against @dfinity/agent's `BLS12_381_G2_OID` /
  // `DER_PREFIX` constants (packages/core/src/agent/der.ts, certificate.ts).
  // There is no corresponding standard for BLS12-381 *private* keys from
  // DFINITY or anyone else — see [DerCodec.encodeBls12381PrivateKeyRaw].
  static const String icBls12381 =
      '1.3.6.1.4.1.44668.5.3.1.2.1'; // id-ic-bls12-381 (algorithm)
  static const String icBls12381G2 =
      '1.3.6.1.4.1.44668.5.3.2.1'; // curve/parameter OID (paired with the above)
}
