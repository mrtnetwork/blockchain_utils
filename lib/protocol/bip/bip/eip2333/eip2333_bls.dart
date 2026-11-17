import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/protocol/bip/bip/eip2333/base/eip2333_base.dart';
import 'package:blockchain_utils/protocol/bip/bip/eip2333/base/eip2333_derivator.dart';
import 'package:blockchain_utils/protocol/bip/bip/eip2333/eip2333_key_data.dart';
import 'package:blockchain_utils/protocol/bip/bip/eip2333/eip2333_keys.dart';
import 'package:blockchain_utils/protocol/bip/bip/eip2333/eip2333_key_derivator.dart';
import 'package:blockchain_utils/protocol/bip/bip/eip2333/eip2333_mst_key_generator.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// EIP-2333 hierarchical deterministic key for BLS12-381 (min-pubkey-size).
///
/// Mirrors `Bip32Slip10Ed25519`: secret-only derivation, same ctor family
/// (`fromSeed` / `fromPrivateKey` / `fromPublicKey`), `childKey` builds
/// the next depth with the parent fingerprint position replaced by the
/// new index (no chain code in EIP-2333).
class Eip2333Bls extends Eip2333Base<Eip2333Bls> {
  Eip2333Bls._({required super.privKey, required super.pubKey});

  Eip2333Bls.fromSeed(super.seedBytes) : super.fromSeed();

  Eip2333Bls.fromPrivateKey(super.privKey, [super.keyData])
    : super.fromPrivateKey();

  Eip2333Bls.fromPublicKey(super.pubKey, [super.keyData])
    : super.fromPublicKey();

  @override
  CryptoKeyType get type => CryptoKeyType.bls12G1;

  @override
  IEip2333ChildKeyDerivator get keyDerivator => const Eip2333KeyDerivator();

  @override
  IEip2333MstKeyGenerator get masterKeyGenerator =>
      const Eip2333MstKeyGenerator();

  @override
  Eip2333Bls childKey(Eip2333KeyIndex index) {
    if (isPublicOnly) {
      throw const BuError(
        DefaultErrorType.unsupported,
        'Public child derivation is not supported',
      );
    }
    final result = keyDerivator.deriveFromSecret(
      parent: privateKey,
      ctx: privateKey,
      index: index,
    );
    final keyData = Eip2333KeyData(depth: depth.increase(), index: index);
    final childPriv = Eip2333PrivateKey(result.key.privKey, keyData);
    return Eip2333Bls._(privKey: childPriv, pubKey: childPriv.publicKey);
  }
}
