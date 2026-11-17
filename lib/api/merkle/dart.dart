import 'package:blockchain_utils/api/merkle/api.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// [MerkleApi] pure-Dart backend.
///
/// Every method throws [BuError]: frontier tracking at wallet
/// scale needs the native backend. Use [NativeMerkleApi] via
/// `blockchainUtils.setRustApi()` instead.
class DartMerkleApi implements MerkleApi {
  /// Creates a pure-Dart Merkle backend; every method throws [BuError].
  const DartMerkleApi();

  static BuError _un(String op) => BuError(
    DefaultErrorType.unsupported,
    'DartMerkleApi.$op: pure-Dart backend has no Merkle frontier; '
    'use NativeMerkleApi via blockchainUtils.setRustApi().',
  );

  /// Creates an empty wallet context and returns its id; pure-Dart stub always throws [BuError].
  @override
  int createContext() {
    throw _un('createContext');
  }

  /// Drops context [id]; pure-Dart stub always throws [BuError].
  @override
  void closeContext(int id) {
    throw _un('closeContext');
  }

  /// Exports context [id] as a restorable blob; pure-Dart stub always throws [BuError].
  @override
  BuBytes getContext(int id) {
    throw _un('getContext');
  }

  /// Restores context [id] from exported [blob]; pure-Dart stub always throws [BuError].
  @override
  void insertChainState(int id, {required List<int> blob}) {
    throw _un('insertChainState');
  }

  /// Appends `leaves` (len/32) to tree [kind] in context [id]; pure-Dart stub always throws [BuError].
  @override
  void updateState(int id, {required int kind, required List<int> leaves}) {
    throw _un('updateState');
  }

  /// Absorbs level-16 subtree [root32] at [start] for [kind] in context [id]; pure-Dart stub always throws [BuError].
  @override
  void updateSubtree(
    int id, {
    required int kind,
    required int start,
    required List<int> root32,
  }) {
    throw _un('updateSubtree');
  }

  /// Merges exported [blob] into tree [kind] in context [id]; pure-Dart stub always throws [BuError].
  @override
  void mergeState(int id, {required int kind, required List<int> blob}) {
    throw _un('mergeState');
  }

  /// Snapshots context [id] under [checkpointId]; pure-Dart stub always throws [BuError].
  @override
  void checkpoint(int id, int checkpointId) {
    throw _un('checkpoint');
  }

  /// Witnesses [positions] at [checkpointId] for [kind] in context [id]; pure-Dart stub always throws [BuError].
  @override
  BuMerkleWitness createWitness(
    int id, {
    required int kind,
    required int checkpointId,
    required List<int> positions,
  }) {
    throw _un('createWitness');
  }
}
