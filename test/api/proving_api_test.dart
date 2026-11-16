// ignore_for_file: depend_on_referenced_packages

import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

void main() {
  group('Dart proving stubs', () {
    const sapling = DartSaplingApi();
    const orchard = DartOrchardApi();
    const merkle = DartMerkleApi();
    const rng = DartRngApi();
    const empty = <int>[];

    test('every method throws BuError', () {
      expect(
        () => sapling.setSpendParams(empty),
        throwsA(isA<BuError>()),
      );
      expect(
        () => sapling.setOutputParams(empty),
        throwsA(isA<BuError>()),
      );
      expect(() => sapling.paramsFree(0), throwsA(isA<BuError>()));
      expect(
        () => sapling.prove(handle: 0, kind: 0, witness: empty),
        throwsA(isA<BuError>()),
      );
      expect(
        () => sapling.verify(handle: 0, kind: 0, proof: empty, inputs: empty),
        throwsA(isA<BuError>()),
      );
      expect(
        () => orchard.pkNew(version: 1),
        throwsA(isA<BuError>()),
      );
      expect(() => orchard.pkFree(0), throwsA(isA<BuError>()));

      expect(
        () => orchard.verifyProof(
          pk: 0,
          proof: empty,
          instances: empty,
          version: 1,
        ),
        throwsA(isA<BuError>()),
      );
      // NOTE: `OrchardApi.prfNf` was removed from the backend interface
      // (only `OrchardKeyUtils.prfNf` at protocol level remains), so the
      // old expectation is dropped instead of blocking suite compilation.
      expect(() => merkle.createContext(), throwsA(isA<BuError>()));
      expect(() => merkle.closeContext(1), throwsA(isA<BuError>()));
      expect(() => merkle.getContext(1), throwsA(isA<BuError>()));
      expect(
        () => merkle.insertChainState(1, blob: empty),
        throwsA(isA<BuError>()),
      );
      expect(
        () => merkle.updateState(1, kind: 0, leaves: empty),
        throwsA(isA<BuError>()),
      );
      expect(
        () => merkle.updateSubtree(1, kind: 0, start: 0, root32: empty),
        throwsA(isA<BuError>()),
      );
      expect(
        () => merkle.mergeState(1, kind: 0, blob: empty),
        throwsA(isA<BuError>()),
      );
      expect(() => merkle.checkpoint(1, 2), throwsA(isA<BuError>()));
      expect(
        () =>
            merkle.createWitness(1, kind: 0, checkpointId: 2, positions: empty),
        throwsA(isA<BuError>()),
      );
      expect(() => rng.seed(seed32: empty), throwsA(isA<BuError>()));
      expect(() => rng.isSeeded, throwsA(isA<BuError>()));
      expect(() => rng.fill(length: 1), throwsA(isA<BuError>()));
    });

    test('implements the aggregate interfaces', () {
      expect(sapling, isA<SaplingApi>());
      expect(orchard, isA<OrchardApi>());
      expect(merkle, isA<MerkleApi>());
      expect(rng, isA<RngApi>());
    });
  });

  group('Native wrappers', () {
    test('construct over connector types', () {
      expect(NativeSaplingApi, isA<Type>());
      expect(NativeOrchardApi, isA<Type>());
      expect(NativeMerkleApi, isA<Type>());
      expect(NativeRngApi, isA<Type>());
    });
  });
}
