import 'package:blockchain_utils/api/validation/validate.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/crypto/crypto/monero/api/src/api.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// [MoneroApi] backed by a native (FFI/platform) implementation.
class NativeMoneroApi implements MoneroApi {
  final BuMoneroApi api;
  const NativeMoneroApi(this.api);

  static final BigInt _u64max = BigInt.parse('18446744073709551615');

  static List<int> _amountLe(BigInt v, String op) {
    if (v < BigInt.zero || v > _u64max) {
      throw CoreErrors.invalidOperationArguments(
        op,
        name: 'amounts',
        reason: 'amount out of u64 range: $v',
      );
    }
    final out = List<int>.filled(8, 0);
    var x = v;
    for (var i = 0; i < 8; i++) {
      out[i] = (x & BigInt.from(0xff)).toInt();
      x >>= 8;
    }
    return out;
  }

  static void _checkKeys(List<List<int>> xs, int n, String op, String name) {
    if (xs.length != n) {
      throw CoreErrors.invalidOperationArguments(
        op,
        name: name,
        reason: 'expected $n entries, got ${xs.length}',
      );
    }
    for (final x in xs) {
      ApiValidate.length(x, 32, operation: op, name: name);
    }
  }

  @override
  bool bpPlusVerify(List<MoneroBpPlusProof> proofs) {
    const op = 'Monero.bpPlusVerify';
    if (proofs.isEmpty || proofs.length > 256) {
      throw CoreErrors.invalidOperationArguments(
        op,
        name: 'proofs',
        reason: 'need 1..256 proofs, got ${proofs.length}',
      );
    }
    final packed = MoneroBpPlusProof.pack(proofs);
    return ApiValidate.call(
      op,
      () => api.bpPlusVerify(packed).unwrapOrThrowCryptoError(),
    );
  }

  @override
  MoneroBpPlusProof bpPlusProveAmounts({
    required List<BigInt> amounts,
    required List<List<int>> gamma,
    required List<int> seed,
  }) {
    const op = 'Monero.bpPlusProveAmounts';
    if (amounts.isEmpty || amounts.length > 16) {
      throw CoreErrors.invalidOperationArguments(
        op,
        name: 'amounts',
        reason: 'need 1..16 amounts, got ${amounts.length}',
      );
    }
    _checkKeys(gamma, amounts.length, op, 'gamma');
    ApiValidate.length(seed, 32, operation: op, name: 'seed');
    final blob = ApiValidate.call(
      op,
      () => api
          .bpPlusProveAmounts(
            amountsLe: amounts.map((e) => _amountLe(e, op)).toList(),
            gamma: gamma.map((e) => e.asBytes).toList(),
            seed: seed.asBytes,
          )
          .unwrapOrThrowCryptoError(),
    );
    return MoneroBpPlusProof.fromBlob(blob);
  }

  @override
  MoneroBpPlusProof bpPlusProveScalars({
    required List<List<int>> sv,
    required List<List<int>> gamma,
    required List<int> seed,
  }) {
    const op = 'Monero.bpPlusProveScalars';
    if (sv.isEmpty || sv.length > 16) {
      throw CoreErrors.invalidOperationArguments(
        op,
        name: 'sv',
        reason: 'need 1..16 scalars, got ${sv.length}',
      );
    }
    _checkKeys(sv, sv.length, op, 'sv');
    _checkKeys(gamma, sv.length, op, 'gamma');
    ApiValidate.length(seed, 32, operation: op, name: 'seed');
    final blob = ApiValidate.call(
      op,
      () => api
          .bpPlusProveScalars(
            sv: sv.map((e) => e.asBytes).toList(),
            gamma: gamma.map((e) => e.asBytes).toList(),
            seed: seed.asBytes,
          )
          .unwrapOrThrowCryptoError(),
    );
    return MoneroBpPlusProof.fromBlob(blob);
  }

  @override
  List<BuMoneroUnlockMatch> unlockBatch({
    required List<BuMoneroScanAccount> accounts,
    required List<BuMoneroScanOutput> outputs,
  }) {
    const op = 'Monero.unlockBatch';
    if (accounts.isEmpty) {
      throw CoreErrors.invalidOperationArguments(
        op,
        name: 'accounts',
        reason: 'need at least one scan account',
      );
    }
    if (outputs.isEmpty) {
      throw CoreErrors.invalidOperationArguments(
        op,
        name: 'outputs',
        reason: 'need at least one scan output',
      );
    }
    for (var i = 0; i < accounts.length; i++) {
      ApiValidate.length(accounts[i].viewSecret, 32,
          operation: op, name: 'accounts[$i].viewSecret');
      for (var j = 0; j < accounts[i].spendPubs.length; j++) {
        ApiValidate.length(accounts[i].spendPubs[j], 32,
            operation: op, name: 'accounts[$i].spendPubs[$j]');
      }
    }
    for (var i = 0; i < outputs.length; i++) {
      final o = outputs[i];
      ApiValidate.length(o.outKey, 32, operation: op, name: 'outputs[$i].outKey');
      ApiValidate.length(o.txPub, 32, operation: op, name: 'outputs[$i].txPub');
      final additional = o.additionalPub;
      if (additional != null) {
        ApiValidate.length(additional, 32,
            operation: op, name: 'outputs[$i].additionalPub');
      }
      final viewTag = o.viewTag;
      if (viewTag != null && (viewTag < 0 || viewTag > 255)) {
        throw CoreErrors.invalidOperationArguments(
          op,
          name: 'outputs[$i].viewTag',
          reason: 'must be a byte 0..255, got $viewTag',
        );
      }
      final outIndex = o.outIndex;
      if (outIndex != null && outIndex < 0) {
        throw CoreErrors.invalidOperationArguments(
          op,
          name: 'outputs[$i].outIndex',
          reason: 'must be non-negative, got $outIndex',
        );
      }
    }
    return ApiValidate.call(
      op,
      () => api
          .unlockBatch(accounts: accounts, outputs: outputs)
          .unwrapOrThrowCryptoError(),
    );
  }

  @override
  bool get supported => true;
}
