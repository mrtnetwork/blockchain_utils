import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/crypto/crypto/keys/bls12_381/minimal_pubkey_size/keys.dart';
import 'package:blockchain_utils/crypto/crypto/keys/bls12_381/minimal_signature_size/keys.dart';
import 'package:blockchain_utils/crypto/crypto/keys/ed25519/keys/ed25519.dart';
import 'package:blockchain_utils/crypto/crypto/keys/ed25519/keys/ed25519_blake2b.dart';
import 'package:blockchain_utils/crypto/crypto/keys/ed25519/keys/ed25519_khalow.dart';
import 'package:blockchain_utils/crypto/crypto/keys/ed25519/keys/ed25519_monero.dart';
import 'package:blockchain_utils/crypto/crypto/keys/bls12_381/aggregate_minimal_pubkey_size/keys.dart';
import 'package:blockchain_utils/crypto/crypto/keys/bls12_381/aggregate_minimal_signature_size/keys.dart';
import 'package:blockchain_utils/crypto/crypto/keys/ml_dsa/keys/keys.dart';
import 'package:blockchain_utils/crypto/crypto/keys/musig2/src/keys.dart';
import 'package:blockchain_utils/crypto/crypto/keys/dkls23/src/keys.dart';
import 'package:blockchain_utils/crypto/crypto/keys/frost/src/keys.dart';
import 'package:blockchain_utils/crypto/crypto/keys/secp256k1/secp256k1.dart';
import 'package:blockchain_utils/crypto/crypto/keys/reddsa/redjubjub/keys/binding.dart';
import 'package:blockchain_utils/crypto/crypto/keys/reddsa/redjubjub/keys/spend.dart';
import 'package:blockchain_utils/crypto/crypto/keys/reddsa/redpallas/keys/binding.dart';
import 'package:blockchain_utils/crypto/crypto/keys/reddsa/redpallas/keys/spend.dart';
import 'package:blockchain_utils/crypto/crypto/keys/secp256r1/secp256r1.dart';
import 'package:blockchain_utils/crypto/crypto/keys/sr25519/sr25519.dart';
import 'package:blockchain_utils/utils/binary/src/utils.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';

/// Common interface for every key type (public or private).
abstract class ICryptoKey with Equality {
  /// The elliptic curve / signature scheme this key belongs to.
  CryptoKeyType get type;
  const ICryptoKey();
}

/// An abstract class representing a generic public key interface for different elliptic curve types.
abstract class IPublicKey<VERIFYPARAMS extends IVerifiyingParams>
    extends ICryptoKey
    implements IVerifiyingKey<VERIFYPARAMS> {
  const IPublicKey();

  /// Factory method for creating an IPublicKey instance from a byte array and an elliptic curve type.
  static IPublicKey fromBytes(List<int> keybytes, CryptoKeyType type) {
    switch (type) {
      case CryptoKeyType.nist256p1:
        return Secp256r1PublicKey.fromBytes(keybytes);
      case CryptoKeyType.nist256p1Hybrid:
        return SuiHybridSecp256r1PublicKey.fromBytes(keybytes);
      case CryptoKeyType.sr25519:
        return SR25519PublicKey.fromBytes(keybytes);
      case CryptoKeyType.ed25519:
        return ED25519PublicKey.fromBytes(keybytes);
      case CryptoKeyType.ed25519Kholaw:
        return ED25519KholawPublicKey.fromBytes(keybytes);
      case CryptoKeyType.ed25519Monero:
        return ED25519MoneroPublicKey.fromBytes(keybytes);
      case CryptoKeyType.ed25519Blake2b:
        return ED25519Blake2bPublicKey.fromBytes(keybytes);
      case CryptoKeyType.secp256k1:
        return Secp256k1PublicKey.fromBytes(keybytes);
      case CryptoKeyType.bls12G1:
        return Bls12G1PublicKey.fromBytes(keybytes);
      case CryptoKeyType.bls12G2:
        return Bls12G2PublicKey.fromBytes(keybytes);
      case CryptoKeyType.mldsa44:
        return MLDSA44PublicKey.fromBytes(keybytes);
      case CryptoKeyType.mldsa65:
        return MLDSA65PublicKey.fromBytes(keybytes);
      case CryptoKeyType.mldsa87:
        return MLDSA87PublicKey.fromBytes(keybytes);
      case CryptoKeyType.redPallasBinding:
        return RedPallasBindingPublicKey.fromBytes(keybytes);
      case CryptoKeyType.redPallasSpend:
        return RedPallasSpendPublicKey.fromBytes(keybytes);
      case CryptoKeyType.redJubJubBinding:
        return RedJubJubBindingPublicKey.fromBytes(keybytes);
      case CryptoKeyType.redJubJubSpend:
        return RedJubJubSpendPublicKey.fromBytes(keybytes);
      case CryptoKeyType.muSig2:
        return MuSig2AggregatePublicKey.fromBytes(keybytes);
      case CryptoKeyType.dkls23K1:
        return Dkls23Secp256k1PublicKey.fromBytes(keybytes);
      case CryptoKeyType.dkls23R1:
        return Dkls23Secp256r1PublicKey.fromBytes(keybytes);
      case CryptoKeyType.frostK1:
        return FrostSecp256k1PublicKey.fromBytes(keybytes);
      case CryptoKeyType.frostEd25519:
        return FrostEd25519PublicKey.fromBytes(keybytes);
      case CryptoKeyType.bls12G1Aggregate:
        return Bls12G1AggregatePublicKey.fromBytes(keybytes);
      case CryptoKeyType.bls12G2Aggregate:
        return Bls12G2AggregatePublicKey.fromBytes(keybytes);
    }
  }

  static IPublicKey fromHex(String keyHex, CryptoKeyType type) {
    return IPublicKey.fromBytes(BytesUtils.fromHexString(keyHex), type);
  }

  /// Static method to check the validity of a byte array as a public key for a specific elliptic curve type.
  static bool isValidBytes(List<int> keyBytes, CryptoKeyType type) {
    switch (type) {
      case CryptoKeyType.nist256p1:
        return Secp256r1PublicKey.isValidBytes(keyBytes);
      case CryptoKeyType.nist256p1Hybrid:
        return SuiHybridSecp256r1PublicKey.isValidBytes(keyBytes);
      case CryptoKeyType.sr25519:
        return SR25519PublicKey.isValidBytes(keyBytes);
      case CryptoKeyType.ed25519:
        return ED25519PublicKey.isValidBytes(keyBytes);
      case CryptoKeyType.ed25519Kholaw:
        return ED25519KholawPublicKey.isValidBytes(keyBytes);
      case CryptoKeyType.ed25519Monero:
        return ED25519MoneroPublicKey.isValidBytes(keyBytes);
      case CryptoKeyType.ed25519Blake2b:
        return ED25519Blake2bPublicKey.isValidBytes(keyBytes);
      case CryptoKeyType.secp256k1:
        return Secp256k1PublicKey.isValidBytes(keyBytes);

      case CryptoKeyType.bls12G1:
        return Bls12G1PublicKey.isValidBytes(keyBytes);
      case CryptoKeyType.bls12G2:
        return Bls12G2PublicKey.isValidBytes(keyBytes);
      case CryptoKeyType.mldsa44:
        return MLDSA44PublicKey.isValidBytes(keyBytes);
      case CryptoKeyType.mldsa65:
        return MLDSA65PublicKey.isValidBytes(keyBytes);
      case CryptoKeyType.mldsa87:
        return MLDSA87PublicKey.isValidBytes(keyBytes);
      case CryptoKeyType.redPallasBinding:
        return RedPallasBindingPublicKey.isValidBytes(keyBytes);
      case CryptoKeyType.redPallasSpend:
        return RedPallasSpendPublicKey.isValidBytes(keyBytes);
      case CryptoKeyType.redJubJubBinding:
        return RedJubJubBindingPublicKey.isValidBytes(keyBytes);
      case CryptoKeyType.redJubJubSpend:
        return RedJubJubSpendPublicKey.isValidBytes(keyBytes);
      case CryptoKeyType.muSig2:
        return MuSig2AggregatePublicKey.isValidBytes(keyBytes);
      case CryptoKeyType.dkls23K1:
        return Dkls23Secp256k1PublicKey.isValidBytes(keyBytes);
      case CryptoKeyType.dkls23R1:
        return Dkls23Secp256r1PublicKey.isValidBytes(keyBytes);
      case CryptoKeyType.frostK1:
        return FrostSecp256k1PublicKey.isValidBytes(keyBytes);
      case CryptoKeyType.frostEd25519:
        return FrostEd25519PublicKey.isValidBytes(keyBytes);
      case CryptoKeyType.bls12G1Aggregate:
        return Bls12G1AggregatePublicKey.isValidBytes(keyBytes);
      case CryptoKeyType.bls12G2Aggregate:
        return Bls12G2AggregatePublicKey.isValidBytes(keyBytes);
    }
  }

  /// Checks whether [keyBytes] is a valid public key of the given [type]
  /// when interpreted with the given [encoding].
  ///
  static bool isValidKeyEncoding(
    List<int> keyBytes,
    CryptoKeyType type,
    CryptoKeyEncoding encoding,
  ) {
    switch (type) {
      case CryptoKeyType.nist256p1:
        return Secp256r1PublicKey.isValidKeyEncoding(keyBytes, encoding);
      case CryptoKeyType.nist256p1Hybrid:
        return SuiHybridSecp256r1PublicKey.isValidKeyEncoding(
          keyBytes,
          encoding,
        );
      case CryptoKeyType.sr25519:
        return SR25519PublicKey.isValidKeyEncoding(keyBytes, encoding);
      case CryptoKeyType.ed25519:
        return ED25519PublicKey.isValidKeyEncoding(keyBytes, encoding);
      case CryptoKeyType.ed25519Kholaw:
        return ED25519KholawPublicKey.isValidKeyEncoding(keyBytes, encoding);
      case CryptoKeyType.ed25519Monero:
        return ED25519MoneroPublicKey.isValidKeyEncoding(keyBytes, encoding);
      case CryptoKeyType.ed25519Blake2b:
        return ED25519Blake2bPublicKey.isValidKeyEncoding(keyBytes, encoding);
      case CryptoKeyType.secp256k1:
        return Secp256k1PublicKey.isValidKeyEncoding(keyBytes, encoding);
      case CryptoKeyType.bls12G1:
        return Bls12G1PublicKey.isValidKeyEncoding(keyBytes, encoding);
      case CryptoKeyType.bls12G2:
        return Bls12G2PublicKey.isValidKeyEncoding(keyBytes, encoding);
      case CryptoKeyType.mldsa44:
        return MLDSA44PublicKey.isValidKeyEncoding(keyBytes, encoding);
      case CryptoKeyType.mldsa65:
        return MLDSA65PublicKey.isValidKeyEncoding(keyBytes, encoding);
      case CryptoKeyType.mldsa87:
        return MLDSA87PublicKey.isValidKeyEncoding(keyBytes, encoding);
      case CryptoKeyType.redPallasBinding:
        return RedPallasBindingPublicKey.isValidKeyEncoding(keyBytes, encoding);
      case CryptoKeyType.redPallasSpend:
        return RedPallasSpendPublicKey.isValidKeyEncoding(keyBytes, encoding);
      case CryptoKeyType.redJubJubBinding:
        return RedJubJubBindingPublicKey.isValidKeyEncoding(keyBytes, encoding);
      case CryptoKeyType.redJubJubSpend:
        return RedJubJubSpendPublicKey.isValidKeyEncoding(keyBytes, encoding);
      case CryptoKeyType.muSig2:
        return MuSig2AggregatePublicKey.isValidKeyEncoding(keyBytes, encoding);
      case CryptoKeyType.dkls23K1:
        return Dkls23Secp256k1PublicKey.isValidKeyEncoding(keyBytes, encoding);
      case CryptoKeyType.dkls23R1:
        return Dkls23Secp256r1PublicKey.isValidKeyEncoding(keyBytes, encoding);
      case CryptoKeyType.frostK1:
        return FrostSecp256k1PublicKey.isValidKeyEncoding(keyBytes, encoding);
      case CryptoKeyType.frostEd25519:
        return FrostEd25519PublicKey.isValidKeyEncoding(keyBytes, encoding);
      case CryptoKeyType.bls12G1Aggregate:
        return Bls12G1AggregatePublicKey.isValidKeyEncoding(keyBytes, encoding);
      case CryptoKeyType.bls12G2Aggregate:
        return Bls12G2AggregatePublicKey.isValidKeyEncoding(keyBytes, encoding);
    }
  }

  /// Get the elliptic curve type associated with the public key.
  @override
  CryptoKeyType get type;

  @override
  BuBytes toBytes({CryptoKeyEncoding mode = CryptoKeyEncoding.base});
}

/// An abstract class representing a generic private key interface for different elliptic curve types.
abstract class IPrivateKey<
  SIGNATURE extends ISignature,
  SIGNPARAMS extends ISigningParams,
  // VK extends IVerifiyingKey,
  PK extends IPublicKey
>
    extends ICryptoKey
    with SecretState
    implements ISigningKey<SIGNATURE, SIGNPARAMS, PK> {
  /// Get the elliptic curve type associated with the private key.
  @override
  CryptoKeyType get type;

  /// Factory method for creating an IPrivateKey instance from a byte array and an elliptic curve type.
  static IPrivateKey fromBytes(List<int> keyBytes, CryptoKeyType type) {
    switch (type) {
      case CryptoKeyType.nist256p1:
        return Secp256r1PrivateKey.fromBytes(keyBytes);
      case CryptoKeyType.nist256p1Hybrid:
        return SuiHybridSecp256r1PrivateKey.fromBytes(keyBytes);
      case CryptoKeyType.ed25519:
        return ED25519PrivateKey.fromBytes(keyBytes);
      case CryptoKeyType.ed25519Kholaw:
        return ED25519KholawPrivateKey.fromBytes(keyBytes);
      case CryptoKeyType.ed25519Blake2b:
        return ED25519Blake2bPrivateKey.fromBytes(keyBytes);
      case CryptoKeyType.ed25519Monero:
        return ED25519MoneroPrivateKey.fromBytes(keyBytes);
      case CryptoKeyType.sr25519:
        return SR25519PrivateKey.fromBytes(keyBytes);
      case CryptoKeyType.secp256k1:
        return Secp256k1PrivateKey.fromBytes(keyBytes);
      case CryptoKeyType.bls12G1:
        return Bls12G1PrivateKey.fromBytes(keyBytes);
      case CryptoKeyType.bls12G2:
        return Bls12G2PrivateKey.fromBytes(keyBytes);
      case CryptoKeyType.mldsa44:
        return MLDSA44PrivateKey.fromBytes(keyBytes);
      case CryptoKeyType.mldsa65:
        return MLDSA65PrivateKey.fromBytes(keyBytes);
      case CryptoKeyType.mldsa87:
        return MLDSA87PrivateKey.fromBytes(keyBytes);
      case CryptoKeyType.bls12G1Aggregate:
        return Bls12G1AggregatePrivateKey.fromBytes(keyBytes);
      case CryptoKeyType.bls12G2Aggregate:
        return Bls12G2AggregatePrivateKey.fromBytes(keyBytes);
      case CryptoKeyType.redPallasBinding:
        return RedPallasBindingPrivateKey.fromBytes(keyBytes);
      case CryptoKeyType.redPallasSpend:
        return RedPallasSpendPrivateKey.fromBytes(keyBytes);
      case CryptoKeyType.redJubJubBinding:
        return RedJubJubBindingPrivateKey.fromBytes(keyBytes);
      case CryptoKeyType.redJubJubSpend:
        return RedJubJubSpendPrivateKey.fromBytes(keyBytes);
      case CryptoKeyType.muSig2:
        return Musig2PrivateKey.fromBytes(keyBytes);
      case CryptoKeyType.dkls23K1:
        return Dkls23Secp256k1PrivateKey.fromBytes(keyBytes);
      case CryptoKeyType.dkls23R1:
        return Dkls23Secp256r1PrivateKey.fromBytes(keyBytes);
      case CryptoKeyType.frostK1:
        return FrostSecp256k1PrivateKey.fromBytes(keyBytes);
      case CryptoKeyType.frostEd25519:
        return FrostEd25519PrivateKey.fromBytes(keyBytes);
    }
  }

  static IPrivateKey fromHex(String keyHex, CryptoKeyType type) {
    final toBytes = BytesUtils.fromHexString(keyHex);
    try {
      return IPrivateKey.fromBytes(toBytes, type);
    } finally {
      toBytes.forceZero();
    }
  }

  /// Get the associated public key.
  PK get publicKey;

  /// Static method to check the validity of key bytes for a specific elliptic curve type.
  static bool isValidBytes(List<int> keyBytes, CryptoKeyType type) {
    switch (type) {
      case CryptoKeyType.nist256p1:
        return Secp256r1PrivateKey.isValidBytes(keyBytes);
      case CryptoKeyType.nist256p1Hybrid:
        return SuiHybridSecp256r1PrivateKey.isValidBytes(keyBytes);
      case CryptoKeyType.ed25519:
        return ED25519PrivateKey.isValidBytes(keyBytes);
      case CryptoKeyType.ed25519Kholaw:
        return ED25519KholawPrivateKey.isValidBytes(keyBytes);
      case CryptoKeyType.ed25519Blake2b:
        return ED25519Blake2bPrivateKey.isValidBytes(keyBytes);
      case CryptoKeyType.ed25519Monero:
        return ED25519MoneroPrivateKey.isValidBytes(keyBytes);
      case CryptoKeyType.sr25519:
        return SR25519PrivateKey.isValidBytes(keyBytes);
      case CryptoKeyType.secp256k1:
        return Secp256k1PrivateKey.isValidBytes(keyBytes);
      case CryptoKeyType.bls12G1:
        return Bls12G1PrivateKey.isValidBytes(keyBytes);
      case CryptoKeyType.bls12G2:
        return Bls12G2PrivateKey.isValidBytes(keyBytes);
      case CryptoKeyType.mldsa44:
        return MLDSA44PrivateKey.isValidBytes(keyBytes);
      case CryptoKeyType.mldsa65:
        return MLDSA65PrivateKey.isValidBytes(keyBytes);
      case CryptoKeyType.mldsa87:
        return MLDSA87PrivateKey.isValidBytes(keyBytes);
      case CryptoKeyType.bls12G1Aggregate:
        return Bls12G1AggregatePrivateKey.isValidBytes(keyBytes);
      case CryptoKeyType.bls12G2Aggregate:
        return Bls12G2AggregatePrivateKey.isValidBytes(keyBytes);
      case CryptoKeyType.redPallasBinding:
        return RedPallasBindingPrivateKey.isValidBytes(keyBytes);
      case CryptoKeyType.redPallasSpend:
        return RedPallasSpendPrivateKey.isValidBytes(keyBytes);
      case CryptoKeyType.redJubJubBinding:
        return RedJubJubBindingPrivateKey.isValidBytes(keyBytes);
      case CryptoKeyType.redJubJubSpend:
        return RedJubJubSpendPrivateKey.isValidBytes(keyBytes);
      case CryptoKeyType.muSig2:
        return Musig2PrivateKey.isValidBytes(keyBytes);
      case CryptoKeyType.dkls23K1:
        return Dkls23Secp256k1PrivateKey.isValidBytes(keyBytes);
      case CryptoKeyType.dkls23R1:
        return Dkls23Secp256r1PrivateKey.isValidBytes(keyBytes);
      case CryptoKeyType.frostK1:
        return FrostSecp256k1PrivateKey.isValidBytes(keyBytes);
      case CryptoKeyType.frostEd25519:
        return FrostEd25519PrivateKey.isValidBytes(keyBytes);
    }
  }

  @override
  SecretBytes toBytes({SecretTransform? transform});
}
