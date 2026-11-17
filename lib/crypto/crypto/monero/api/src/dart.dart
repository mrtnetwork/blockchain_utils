import 'package:blockchain_utils/crypto/crypto/monero/api/src/api.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Pure-Dart Monero implementations do not exist: Bulletproofs+ lives in
/// the `monero_dart` package / Rust backend. Every method throws
/// [BuError] -- use the native (Rust) implementation
/// ([NativeMoneroApi]) via `setRustApi`.
Never _unsupported(String op) =>
    throw BuError(
      DefaultErrorType.unsupported,
      'Monero.$op is not implemented in pure Dart; use the Rust (native) API.',
    );

/// [MoneroApi] stub: all operations throw [UnsupportedError].
class DartMoneroApi implements MoneroApi {
  const DartMoneroApi();

  @override
  bool bpPlusVerify(List<MoneroBpPlusProof> proofs) =>
      _unsupported('bpPlusVerify');

  @override
  MoneroBpPlusProof bpPlusProveAmounts({
    required List<BigInt> amounts,
    required List<List<int>> gamma,
    required List<int> seed,
  }) => _unsupported('bpPlusProveAmounts');

  @override
  MoneroBpPlusProof bpPlusProveScalars({
    required List<List<int>> sv,
    required List<List<int>> gamma,
    required List<int> seed,
  }) => _unsupported('bpPlusProveScalars');

  /// Native-only batch scan; the pure-Dart scan lives in `monero_dart`
  /// (`MoneroTransactionHelper.getLockedOutputs`).
  @override
  List<BuMoneroUnlockMatch> unlockBatch({
    required List<BuMoneroScanAccount> accounts,
    required List<BuMoneroScanOutput> outputs,
  }) => _unsupported('unlockBatch');

  @override
  bool get supported => false;
}
