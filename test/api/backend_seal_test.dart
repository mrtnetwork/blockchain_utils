import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

void main() {
  group('backend seal', () {
    test('seal blocks backend swaps', () {
      blockchainUtils.setDartApi();
      expect(blockchainUtils.isSealed, isFalse);
      blockchainUtils.seal();
      expect(blockchainUtils.isSealed, isTrue);
      expect(() => blockchainUtils.setDartApi(), throwsA(isA<BuError>()));
      expect(
        () => blockchainUtils.setApi(blockchainUtils.api),
        throwsA(isA<BuError>()),
      );
      expect(() => blockchainUtils.setRustApi(), throwsA(isA<BuError>()));
    });
  });
}
