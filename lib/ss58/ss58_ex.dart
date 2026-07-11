import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/serialization/identifier.dart';

/// An exception class for errors related to SS58 address checksum validation.
///
/// The [message] field can contain additional information about the error.
class SS58ChecksumError extends BlockchainUtilsException {
  const SS58ChecksumError(super.message, {super.details});
  static const SS58ChecksumError invalidChecksum = SS58ChecksumError(
    "Invalid SS58 checksum.",
  );
  factory SS58ChecksumError.deserialize({
    List<int>? bytes,
    CborObject? object,
  }) {
    final values = CborTagSerializable.decodeTaggedValue(
      identifier: BlockchainUtilsSerializationIdentifier.ss58Error,
      cborBytes: bytes,
      cborObject: object,
    );
    return SS58ChecksumError(
      values.rawValueAt(0),
      details: values.maybeRawMapAt<String, String?>(1),
    );
  }

  @override
  BlockchainUtilsSerializationIdentifier get serializationIdentifier =>
      BlockchainUtilsSerializationIdentifier.ss58Error;
}
