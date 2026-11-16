import 'package:blockchain_utils/api/merkle/api.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// [MerkleApi] backed by a native (FFI/platform) implementation.
class NativeMerkleApi implements MerkleApi {
  /// Underlying connector backend (Rust frontier-model Merkle core).
  final BuMerkleApi api;

  /// Creates a native Merkle backend over [api].
  const NativeMerkleApi(this.api);

  static BuBytes _as(List<int> x) => BuBytes.from(x);

  /// Creates an empty wallet context and returns its id; throws [CryptoException] on native failure, including backend refusal (id 0).
  @override
  int createContext() {
    final id = api.createContext().unwrapOrThrowCryptoError();
    if (id == 0) {
      throw CoreErrors.cryptoFailed(
        'createContext',
        reason: 'backend refused context creation',
      );
    }
    return id;
  }

  /// Drops context [id]; throws [CryptoException] on native failure.
  @override
  void closeContext(int id) {
    api.closeContext(id).unwrapOrThrowCryptoError();
  }

  /// Exports context [id] as a restorable blob; throws [CryptoException] on native failure.
  @override
  BuBytes getContext(int id) {
    return api.getContext(id).unwrapOrThrowCryptoError().asBytes;
  }

  /// Restores context [id] from exported [blob]; throws [CryptoException] on native failure.
  @override
  void insertChainState(int id, {required List<int> blob}) {
    api
        .insertChainState(id, blob: blob)
        .unwrapOrThrowCryptoError();
  }

  /// Appends `leaves` (len/32) to tree [kind] in context [id]; throws [CryptoException] on native failure.
  @override
  void updateState(int id, {required int kind, required List<int> leaves}) {
    api
        .updateState(id, kind: kind, leaves: leaves)
        .unwrapOrThrowCryptoError();
  }

  /// Absorbs level-16 subtree [root32] at [start] for [kind] in context [id]; throws [CryptoException] on native failure.
  @override
  void updateSubtree(
    int id, {
    required int kind,
    required int start,
    required List<int> root32,
  }) {
    api
        .updateSubtree(id, kind: kind, start: start, root32: _as(root32))
        .unwrapOrThrowCryptoError();
  }

  /// Merges exported [blob] into tree [kind] in context [id]; throws [CryptoException] on native failure.
  @override
  void mergeState(int id, {required int kind, required List<int> blob}) {
    api
        .mergeState(id, kind: kind, blob: blob)
        .unwrapOrThrowCryptoError();
  }

  /// Snapshots context [id] under [checkpointId]; throws [CryptoException] on native failure.
  @override
  void checkpoint(int id, int checkpointId) {
    api.checkpoint(id, checkpointId).unwrapOrThrowCryptoError();
  }

  /// Witnesses [positions] at [checkpointId] for [kind] in context [id] and returns the witness; throws [CryptoException] on native failure.
  @override
  BuMerkleWitness createWitness(
    int id, {
    required int kind,
    required int checkpointId,
    required List<int> positions,
  }) {
    return api
        .createWitness(
          id,
          kind: kind,
          checkpointId: checkpointId,
          positions: positions,
        )
        .unwrapOrThrowCryptoError();
  }
}
