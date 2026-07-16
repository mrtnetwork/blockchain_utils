import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:blockchain_utils/exception/exception/blockchain_utils.dart';
import 'package:blockchain_utils/serialization/identifier.dart';

class IntegerError extends BlockchainUtilsException {
  const IntegerError(super.message);

  factory IntegerError.deserialize({List<int>? bytes, CborObject? object}) {
    final values = CborTagSerializable.decodeTaggedValue(
      identifier: BlockchainUtilsSerializationIdentifier.integerError,
      cborBytes: bytes,
      cborObject: object,
    );
    return IntegerError(values.rawValueAt(0));
  }

  static const divisionByZero = IntegerError("division by zero");

  static const overflow = IntegerError(
    "integer overflow: value cannot be represented in the target integer type",
  );

  static const toIntConvertionError = IntegerError(
    "integer value exceeds the safe range of Dart int; use toBigInt() instead",
  );
  @override
  BlockchainUtilsSerializationIdentifier get serializationIdentifier =>
      BlockchainUtilsSerializationIdentifier.integerError;
}
