import 'package:blockchain_utils/blockchain_utils.dart';

abstract mixin class ZCryptoContext {
  CommitDomainNative getCommitDomain(String domain);
  PoseidonHash<PallasNativeFp> getPoseidonHash();
}

class DefaultZCryptoContext implements ZCryptoContext {
  late final _spec = P128Pow5T3NativeFp();
  late final sinsemillaS = HashDomainNative.generateSinsemillaS();
  final Map<String, CommitDomainNative> _cachedDomains = {};
  @override
  CommitDomainNative getCommitDomain(String domain) {
    return _cachedDomains[domain] ??= CommitDomainNative.create(
      domain,
      sinsemillaS: sinsemillaS,
    );
  }

  @override
  PoseidonHash<PallasNativeFp> getPoseidonHash() {
    return PoseidonHash(_spec);
  }
}
