import 'package:blockchain_utils/protocol/bip/bip/eip2333/eip2333_key_data.dart';
import 'package:blockchain_utils/protocol/bip/bip/eip2333/eip2333_keys.dart';
import 'package:blockchain_utils/protocol/hd_key/types.dart';

/// Derived child key DTO, mirrors `Bip32ChildKey`.
class Eip2333ChildKey implements IChildKey {
  final Eip2333PrivateKey key;
  Eip2333ChildKey({required this.key});
}

/// Derived master key DTO, mirrors `Bip32MasterKey`.
class Eip2333MasterKey implements IMasterKey {
  final Eip2333PrivateKey key;
  Eip2333MasterKey({required this.key});
}

/// Child derivator interface, mirrors `IBip32ChildKeyDerivator`.
///
/// Only secret derivation exists in EIP-2333 (no public derivation).
abstract class IEip2333ChildKeyDerivator
    implements
        IChildKeyDerivator<
          Eip2333ChildKey,
          Eip2333PrivateKey,
          Eip2333PrivateKey,
          Eip2333KeyIndex
        > {
  @override
  Eip2333ChildKey deriveFromSecret({
    required Eip2333PrivateKey parent,
    required Eip2333PrivateKey ctx,
    required Eip2333KeyIndex index,
  });

  @override
  Eip2333ChildKey deriveFromPublic({
    required Eip2333PrivateKey parent,
    required Eip2333KeyIndex index,
  });
}

/// Master generator interface, mirrors `IBip32MstKeyGenerator`.
abstract class IEip2333MstKeyGenerator
    implements IMasterKeyKeyGenerator<Eip2333MasterKey> {
  @override
  Eip2333MasterKey generateFromSeed(List<int> seedBytes);
}
