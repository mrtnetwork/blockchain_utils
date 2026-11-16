import 'package:blockchain_utils/protocol/bip/bip/eip2333/base/eip2333_derivator.dart';
import 'package:blockchain_utils/protocol/bip/bip/eip2333/eip2333_key_derivator.dart';
import 'package:blockchain_utils/protocol/bip/bip/eip2333/eip2333_keys.dart';

/// Master generator, mirrors `Bip32Slip10Ed25519MstKeyGenerator`.
class Eip2333MstKeyGenerator implements IEip2333MstKeyGenerator {
  const Eip2333MstKeyGenerator();
  @override
  Eip2333MasterKey generateFromSeed(List<int> seedBytes) {
    final sk = Eip2333KeyDerivator.deriveMasterSk(seedBytes);
    return Eip2333MasterKey(key: Eip2333PrivateKey.fromBigInt(sk));
  }
}
