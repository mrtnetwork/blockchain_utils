import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/serialization/identifier.dart';

class AmountConverterException extends BlockchainUtilsException {
  const AmountConverterException(super.message, {super.details});

  factory AmountConverterException.deserialize({
    List<int>? bytes,
    CborObject? object,
  }) {
    final values = CborTagSerializable.decodeTaggedValue(
      identifier: BlockchainUtilsSerializationIdentifier.amountConverterError,
      cborBytes: bytes,
      cborObject: object,
    );
    return AmountConverterException(
      values.rawValueAt(0),
      details: values.maybeRawMapAt<String, String?>(1),
    );
  }

  @override
  BlockchainUtilsSerializationIdentifier get serializationIdentifier =>
      BlockchainUtilsSerializationIdentifier.amountConverterError;
}
