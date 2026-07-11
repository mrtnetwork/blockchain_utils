import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/serialization/identifier.dart';

/// An exception class representing an error related to Substrate keys.
class SubstrateKeyError extends BlockchainUtilsException {
  const SubstrateKeyError(super.message, {super.details});
  factory SubstrateKeyError.deserialize({
    List<int>? bytes,
    CborObject? object,
  }) {
    final values = CborTagSerializable.decodeTaggedValue(
      identifier: BlockchainUtilsSerializationIdentifier.substrateKeyError,
      cborBytes: bytes,
      cborObject: object,
    );
    return SubstrateKeyError(
      values.rawValueAt(0),
      details: values.maybeRawMapAt<String, String?>(1),
    );
  }

  @override
  BlockchainUtilsSerializationIdentifier get serializationIdentifier =>
      BlockchainUtilsSerializationIdentifier.substrateKeyError;
}

/// An exception class representing an error related to Substrate paths.
class SubstratePathError extends BlockchainUtilsException {
  const SubstratePathError(super.message, {super.details});
  factory SubstratePathError.deserialize({
    List<int>? bytes,
    CborObject? object,
  }) {
    final values = CborTagSerializable.decodeTaggedValue(
      identifier: BlockchainUtilsSerializationIdentifier.substratePathError,
      cborBytes: bytes,
      cborObject: object,
    );
    return SubstratePathError(
      values.rawValueAt(0),
      details: values.maybeRawMapAt<String, String?>(1),
    );
  }

  @override
  BlockchainUtilsSerializationIdentifier get serializationIdentifier =>
      BlockchainUtilsSerializationIdentifier.substratePathError;
}
