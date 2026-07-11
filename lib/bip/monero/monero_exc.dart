import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/serialization/identifier.dart';

/// An exception class representing an error related to Monero keys.
///
/// This exception class is used to represent errors and exceptions related to Monero keys.
class MoneroKeyError extends BlockchainUtilsException {
  const MoneroKeyError(super.message, {super.details});

  factory MoneroKeyError.deserialize({List<int>? bytes, CborObject? object}) {
    final values = CborTagSerializable.decodeTaggedValue(
      identifier: BlockchainUtilsSerializationIdentifier.moneroKeyError,
      cborBytes: bytes,
      cborObject: object,
    );
    return MoneroKeyError(
      values.rawValueAt(0),
      details: values.maybeRawMapAt<String, String?>(1),
    );
  }

  @override
  BlockchainUtilsSerializationIdentifier get serializationIdentifier =>
      BlockchainUtilsSerializationIdentifier.moneroKeyError;
}
