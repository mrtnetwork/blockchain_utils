import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

import '../utils.dart';

void _expectRoundTrip(BuError error) {
  final decode = BuErrorCodec.decode(bytes: error.toCborBytes());
  expect(decode.type, error.type);
  expect(decode.message, error.message);
  expect(decode.details, error.details);
}

void serializationTest() {
  test("exception serialization.", () {
    _expectRoundTrip(
      CoreErrors.invalidOperationArguments(
        "salam",
        reason: "error",
        details: {"alu": "1"},
        name: "2",
      ),
    );
    _expectRoundTrip(CoreErrors.badState("salam", reason: "error"));
    _expectRoundTrip(
      const BuError(
        DefaultErrorType.notFound,
        "No matching item found for the given value. 12",
      ),
    );
    _expectRoundTrip(
      const BuError(
        DefaultErrorType.castFailed,
        "Failed to cast value",
        details: {"expected": "int", "value": "String"},
      ),
    );
    _expectRoundTrip(
      const BuError(
        DefaultErrorType.invalidChecksum,
        "Invalid checksum.",
        details: {"1": "1"},
      ),
    );
    _expectRoundTrip(
      const BuError(
        DefaultErrorType.badBase64,
        "Invalid Base64 string.",
        details: {"1": "1"},
      ),
    );
    _expectRoundTrip(
      const BuError(DefaultErrorType.badBech32, "error", details: {"1": "1"}),
    );
    _expectRoundTrip(
      CoreErrors.addressValidationFailed(reason: "error", details: {"1": "1"}),
    );
    _expectRoundTrip(
      const BuError(
        DefaultErrorType.invalidArgument,
        "error",
        details: {"1": "1"},
      ),
    );
    _expectRoundTrip(CoreErrors.cryptoFailed("op", reason: "error"));
    _expectRoundTrip(CoreErrors.signVerificationFailed);
    _expectRoundTrip(CoreErrors.integerDivisionByZero);
    _expectRoundTrip(CoreErrors.integerOverflow);
    _expectRoundTrip(CoreErrors.web3UnsupportedBackupContent);
    _expectRoundTrip(CoreErrors.web3WrongBackupPassword);
    _expectRoundTrip(CoreErrors.mnemonicInvalidChecksum);
    _expectRoundTrip(CoreErrors.jsonFailed("reason", value: 1));
    _expectRoundTrip(CoreErrors.jsonCycleError([1]));
    _expectRoundTrip(CoreErrors.saplingFailed("derive", reason: "bad"));
    _expectRoundTrip(
      CoreErrors.zcashInvalidKeyData("Sapling spending", reason: "bad"),
    );
    _expectRoundTrip(CoreErrors.incorrectTagValue(tag: [1, 2]));
    {
      final ids = DefaultErrorType.values.map((e) => e.id);
      expect(ids.toSet().length, DefaultErrorType.values.length);
      for (final id in ids) {
        expect(id > 258, equals(true));
      }
    }
  });
}

void main() {
  BlockchainUtilsTestApi.runTest(serializationTest, "Serialization");
}
