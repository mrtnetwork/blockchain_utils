import 'package:blockchain_utils/blockchain_utils.dart';

/// Provides cryptographic primitives and precomputed tables required for
/// ZCash operations (e.g., Poseidon hash, Sinsemilla commitments, and
/// domain-separated commitments).
///
/// ⚠️ Expensive to instantiate: creating a `DefaultZCryptoContext` allocates
/// internal tables and constants, so it should be created **once** and
/// passed to any code that requires it, rather than recreated repeatedly.
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
