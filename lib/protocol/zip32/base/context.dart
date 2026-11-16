import 'package:blockchain_utils/api/api/api.dart';
import 'package:blockchain_utils/crypto/crypto/hash/api/src/api.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Provides cryptographic primitives and precomputed tables required for
/// ZCash operations (e.g., Poseidon hash, Sinsemilla commitments, and
/// domain-separated commitments).
///
/// ⚠️ Expensive to instantiate: creating a `DefaultZCryptoContext` allocates
/// internal tables and constants, so it should be created **once** and
/// passed to any code that requires it, rather than recreated repeatedly.
abstract mixin class ZCryptoContext {
  /// $PRF^\mathsf{nfOrchard}(nk, \rho) := Poseidon(nk, \rho)$
  ///
  /// Defined in [Zcash Protocol Spec § 5.4.2: Pseudo Random Functions][concreteprfs].
  ///
  /// [concreteprfs]: https://zips.z.cash/protocol/nu5.pdf#concreteprfs
  /// prf_nf
  ///
  /// All inputs/outputs are 32-byte little-endian field encodings.
  BuBytes pseudoRando({required List<int> nk, required List<int> rho});

  BuBytes? sinsemillaShortCommit({
    required List<int> r,
    required List<bool> bits,
    String domain = "z.cash:Orchard-CommitIvk",
  });
  BuBytes? sinsemillaCommit({
    required List<int> r,
    required List<bool> bits,
    String domain = "z.cash:Orchard-CommitIvk",
  });
}

class DefaultZCryptoContext implements ZCryptoContext {
  HashApi get _api => blockchainUtils.api.hash;
  @override
  BuBytes pseudoRando({required List<int> nk, required List<int> rho}) {
    return _api.pseudoRando(nk: nk, rho: rho);
  }

  @override
  BuBytes? sinsemillaShortCommit({
    required List<int> r,
    required List<bool> bits,
    String domain = 'z.cash:Orchard-CommitIvk',
  }) {
    return _api.sinsemillaShortCommit(r: r, bits: bits, domain: domain);
  }

  @override
  BuBytes? sinsemillaCommit({
    required List<int> r,
    required List<bool> bits,
    String domain = 'z.cash:Orchard-CommitIvk',
  }) {
    return _api.sinsemillaCommit(r: r, bits: bits, domain: domain);
  }
}
