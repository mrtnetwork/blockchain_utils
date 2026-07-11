import 'package:blockchain_utils/serialization/identifier.dart';
import 'package:test/test.dart';

void main() {
  test("serialization identifier", () {
    expect(
      BlockchainUtilsSerializationIdentifier.values
          .map((e) => e.id)
          .toSet()
          .length,
      BlockchainUtilsSerializationIdentifier.values.length,
    );
    expect(
      BlockchainUtilsSerializationIdentifier.values.every(
        (e) => e.id >= 11000 && e.id < 12000,
      ),
      true,
    );
  });
}
