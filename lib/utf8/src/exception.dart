import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/serialization/identifier.dart';

class Utf8Exception extends BlockchainUtilsException {
  const Utf8Exception(super.message, {super.details});
  static const Utf8Exception invalidUf16String = Utf8Exception(
    "Invalid UTF-16 string.",
  );
  static const Utf8Exception invalidUf8String = Utf8Exception(
    "Invalid UTF-8 string.",
  );

  factory Utf8Exception.deserialize({List<int>? bytes, CborObject? object}) {
    final values = CborTagSerializable.decodeTaggedValue(
      identifier: BlockchainUtilsSerializationIdentifier.utf8Error,
      cborBytes: bytes,
      cborObject: object,
    );
    return Utf8Exception(
      values.rawValueAt(0),
      details: values.maybeRawMapAt<String, String?>(1),
    );
  }

  @override
  BlockchainUtilsSerializationIdentifier get serializationIdentifier =>
      BlockchainUtilsSerializationIdentifier.utf8Error;
}
