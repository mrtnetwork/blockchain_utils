import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Frontier-model Merkle contexts (Sapling + Orchard + Ironwood wallet sync).
///
/// Leaves append in order; subtrees must be level-16 aligned at the tip;
/// checkpoints cap at 100 (oldest evicted); witnesses replay the leaf log;
/// positions inside absorbed history are unwitnessable.
///
abstract interface class MerkleApi {
  /// Sapling protocol tree.
  static const int sapling = 0;

  /// Orchard protocol tree.
  static const int orchard = 1;

  /// Ironwood pool (NU6.3 second slot, Orchard-typed frontier).
  static const int ironwood = 2;

  /// Create an empty wallet context. Returns 0 on internal error.
  int createContext();

  /// Drop a context.
  void closeContext(int id);

  /// Export a context blob (restorable via [insertChainState]).
  BuBytes getContext(int id);

  /// Restore a context from an exported blob (replaces state).
  void insertChainState(int id, {required List<int> blob});

  /// Append n = len/32 leaves to a protocol tree.
  void updateState(int id, {required int kind, required List<int> leaves});

  /// Absorb one level-16 subtree root at [start] (must equal current size).
  void updateSubtree(
    int id, {
    required int kind,
    required int start,
    required List<int> root32,
  });

  /// Merge checkpoints + contiguous subtrees from an exported merge blob.
  void mergeState(int id, {required int kind, required List<int> blob});

  /// Snapshot all trees under [checkpointId] (evicts oldest beyond cap).
  void checkpoint(int id, int checkpointId);

  /// Witness [positions] at [checkpointId].
  BuMerkleWitness createWitness(
    int id, {
    required int kind,
    required int checkpointId,
    required List<int> positions,
  });
}
