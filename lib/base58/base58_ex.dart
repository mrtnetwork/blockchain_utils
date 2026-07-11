import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/serialization/identifier.dart';

/// An exception class representing an error related to Base58 checksum validation.
class Base58ChecksumError extends BlockchainUtilsException {
  /// Constructor for creating a Base58ChecksumError with an optional error message.
  const Base58ChecksumError({super.details}) : super("Invalid checksum.");
  factory Base58ChecksumError.deserialize({
    List<int>? bytes,
    CborObject? object,
  }) {
    final values = CborTagSerializable.decodeTaggedValue(
      identifier: BlockchainUtilsSerializationIdentifier.base58Error,
      cborBytes: bytes,
      cborObject: object,
    );
    return Base58ChecksumError(
      details: values.maybeRawMapAt<String, String?>(0),
    );
  }

  @override
  BlockchainUtilsSerializationIdentifier get serializationIdentifier =>
      BlockchainUtilsSerializationIdentifier.base58Error;

  @override
  List<CborObject?> get serializationItems => [
    CborTagSerializable.mapToCbor(details),
  ];
}
