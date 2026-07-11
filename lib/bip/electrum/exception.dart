import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/serialization/identifier.dart';

class ElectrumException extends BlockchainUtilsException {
  const ElectrumException(super.message);

  factory ElectrumException.deserialize({
    List<int>? bytes,
    CborObject? object,
  }) {
    final values = CborTagSerializable.decodeTaggedValue(
      identifier: BlockchainUtilsSerializationIdentifier.electrumError,
      cborBytes: bytes,
      cborObject: object,
    );
    return ElectrumException(values.rawValueAt(0));
  }

  @override
  BlockchainUtilsSerializationIdentifier get serializationIdentifier =>
      BlockchainUtilsSerializationIdentifier.electrumError;
}
