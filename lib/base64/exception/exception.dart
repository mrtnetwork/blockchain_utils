import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/serialization/identifier.dart';

class B64ConverterException extends BlockchainUtilsException {
  const B64ConverterException({super.details})
    : super("Invalid base64 string.");

  factory B64ConverterException.deserialize({
    List<int>? bytes,
    CborObject? object,
  }) {
    final values = CborTagSerializable.decodeTaggedValue(
      identifier: BlockchainUtilsSerializationIdentifier.base64Error,
      cborBytes: bytes,
      cborObject: object,
    );
    return B64ConverterException(
      details: values.maybeRawMapAt<String, String?>(0),
    );
  }

  @override
  BlockchainUtilsSerializationIdentifier get serializationIdentifier =>
      BlockchainUtilsSerializationIdentifier.base64Error;

  @override
  List<CborObject?> get serializationItems => [
    CborTagSerializable.mapToCbor(details),
  ];
}
