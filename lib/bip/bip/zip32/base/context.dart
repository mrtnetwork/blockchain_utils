import 'package:blockchain_utils/blockchain_utils.dart';

/// Provides cryptographic primitives and precomputed tables required for
/// ZCash operations (e.g., Poseidon hash, Sinsemilla commitments, and
/// domain-separated commitments).
///
/// ⚠️ Expensive to instantiate: creating a `DefaultZCryptoContext` allocates
/// internal tables and constants, so it should be created **once** and
/// passed to any code that requires it, rather than recreated repeatedly.
abstract mixin class ZCryptoContext {
  // CommitDomainNative getCommitDomain(String domain);
  // PoseidonHash<PallasNativeFp> getPoseidonHash();

  /// $PRF^\mathsf{nfOrchard}(nk, \rho) := Poseidon(nk, \rho)$
  ///
  /// Defined in [Zcash Protocol Spec § 5.4.2: Pseudo Random Functions][concreteprfs].
  ///
  /// [concreteprfs]: https://zips.z.cash/protocol/nu5.pdf#concreteprfs
  /// prf_nf

  PallasNativeFp pseudoRando({
    required PallasNativeFp nk,
    required PallasNativeFp rho,
  });

  PallasNativeFp? sinsemillaShortCommit({
    required VestaNativeFq r,
    required List<bool> bits,
    String domain = "z.cash:Orchard-CommitIvk",
  });
  PallasNativePoint? sinsemillaCommit({
    required VestaNativeFq r,
    required List<bool> bits,
    String domain = "z.cash:Orchard-CommitIvk",
  });
}

class DefaultZCryptoContext implements ZCryptoContext {
  late final _spec = P128Pow5T3NativeFp();
  late final sinsemillaS = HashDomainNative.generateSinsemillaSConstants();
  final Map<String, CommitDomainNative> _cachedDomains = {};

  CommitDomainNative getCommitDomain(String domain) {
    return _cachedDomains[domain] ??= CommitDomainNative.create(domain);
  }

  @override
  PallasNativeFp? sinsemillaShortCommit({
    required VestaNativeFq r,
    required List<bool> bits,
    String domain = "z.cash:Orchard-CommitIvk",
  }) {
    final donmain = getCommitDomain(domain);
    return donmain.shortCommit(msg: bits, r: r);
  }

  @override
  PallasNativePoint? sinsemillaCommit({
    required VestaNativeFq r,
    required List<bool> bits,
    String domain = "z.cash:Orchard-CommitIvk",
  }) {
    final donmain = getCommitDomain(domain);
    return donmain.commit(msg: bits, r: r);
  }

  PoseidonHash<PallasNativeFp> getPoseidonHash() {
    return PoseidonHash(_spec);
  }

  @override
  PallasNativeFp pseudoRando({
    required PallasNativeFp nk,
    required PallasNativeFp rho,
  }) {
    return getPoseidonHash().hash([nk, rho]);
  }
}
