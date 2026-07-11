import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/serialization/identifier.dart';

class Zip32Error extends BlockchainUtilsException {
  const Zip32Error(super.message, {super.details});

  factory Zip32Error.deserialize({List<int>? bytes, CborObject? object}) {
    final values = CborTagSerializable.decodeTaggedValue(
      identifier: BlockchainUtilsSerializationIdentifier.zip32Error,
      cborBytes: bytes,
      cborObject: object,
    );
    return Zip32Error(
      values.rawValueAt(0),
      details: values.maybeRawMapAt<String, String?>(1),
    );
  }

  @override
  BlockchainUtilsSerializationIdentifier get serializationIdentifier =>
      BlockchainUtilsSerializationIdentifier.zip32Error;
}
