import 'dart:typed_data';

import 'package:blockchain_utils/crypto/crypto/keys/bls12_381/minimal_pubkey_size/keys.dart';
import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/protocol/bip/bip/eip2333/eip2333_key_data.dart';
import 'package:blockchain_utils/protocol/hd_key/types.dart';
import 'package:blockchain_utils/utils/numbers/utils/bigint_utils.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Private key wrapper for EIP-2333, mirrors `Bip32PrivateKey`.
///
/// Backed by [Bls12G1PrivateKey] (min-pubkey-size: 48-byte G1 pubs, the
/// Ethereum validator encoding).
class Eip2333PrivateKey extends CryptoKeyBase<Eip2333KeyData> with SecretState {
  final Bls12G1PrivateKey privKey;

  Eip2333PrivateKey(this.privKey, super.keyData);

  CryptoKeyType get type => CryptoKeyType.bls12G1;

  Eip2333PublicKey get publicKey =>
      Eip2333PublicKey(privKey.publicKey, keyData);

  SecretBytes toBytes({SecretTransform? transform}) {
    return privKey.toBytes(transform: transform);
  }

  BigInt toBigInt() {
    return toBytes().useValue(
      (b) => BigintUtils.fromBytes(b, byteOrder: Endian.big),
      zero: true,
    );
  }

  static Eip2333PrivateKey fromBytes(
    List<int> keyBytes, [
    Eip2333KeyData? keyData,
  ]) {
    return Eip2333PrivateKey(
      Bls12G1PrivateKey.fromBytes(keyBytes),
      keyData ?? Eip2333KeyData(),
    );
  }

  static Eip2333PrivateKey fromBigInt(BigInt value, [Eip2333KeyData? keyData]) {
    final bytes = value.toBytes(length: 32, byteOrder: Endian.big);
    return Eip2333PrivateKey.fromBytes(bytes, keyData);
  }

  @override
  void dispose() {
    privKey.dispose();
  }
}

/// Public key wrapper for EIP-2333, mirrors `Bip32PublicKey`.
class Eip2333PublicKey extends CryptoKeyBase<Eip2333KeyData> {
  final Bls12G1PublicKey pubKey;

  Eip2333PublicKey(this.pubKey, super.keyData);

  CryptoKeyType get type => CryptoKeyType.bls12G1;

  BuBytes toBytes({CryptoKeyEncoding mode = CryptoKeyEncoding.base}) {
    return pubKey.toBytes(mode: mode);
  }

  static Eip2333PublicKey fromBytes(
    List<int> keyBytes, [
    Eip2333KeyData? keyData,
  ]) {
    return Eip2333PublicKey(
      Bls12G1PublicKey.fromBytes(keyBytes),
      keyData ?? Eip2333KeyData(),
    );
  }
}
