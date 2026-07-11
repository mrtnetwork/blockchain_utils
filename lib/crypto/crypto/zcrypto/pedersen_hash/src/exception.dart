import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:blockchain_utils/exception/exception/blockchain_utils.dart';
import 'package:blockchain_utils/serialization/identifier.dart';

class PedersenHashException extends BlockchainUtilsException {
  const PedersenHashException(super.message, {super.details});
  static PedersenHashException failed(
    String operation, {
    Map<String, String>? details,
    String? reason,
  }) {
    return PedersenHashException(
      "Pedersen operation failed during $operation.",
      details: {...details ?? {}, "reason": reason},
    );
  }

  factory PedersenHashException.deserialize({
    List<int>? bytes,
    CborObject? object,
  }) {
    final values = CborTagSerializable.decodeTaggedValue(
      identifier: BlockchainUtilsSerializationIdentifier.pedersenHashError,
      cborBytes: bytes,
      cborObject: object,
    );
    return PedersenHashException(
      values.rawValueAt(0),
      details: values.maybeRawMapAt<String, String?>(1),
    );
  }

  @override
  BlockchainUtilsSerializationIdentifier get serializationIdentifier =>
      BlockchainUtilsSerializationIdentifier.pedersenHashError;
}
