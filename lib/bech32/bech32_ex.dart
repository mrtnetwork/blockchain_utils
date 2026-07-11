import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/serialization/identifier.dart';

/// An exception class representing errors related to Bech32 checksum validation.
class Bech32Error extends BlockchainUtilsException {
  /// The error message associated with this checksum error.
  const Bech32Error(super.message, {super.details});

  factory Bech32Error.deserialize({List<int>? bytes, CborObject? object}) {
    final values = CborTagSerializable.decodeTaggedValue(
      identifier: BlockchainUtilsSerializationIdentifier.bech32Error,
      cborBytes: bytes,
      cborObject: object,
    );
    return Bech32Error(
      values.rawValueAt(0),
      details: values.maybeRawMapAt<String, String?>(1),
    );
  }

  @override
  BlockchainUtilsSerializationIdentifier get serializationIdentifier =>
      BlockchainUtilsSerializationIdentifier.bech32Error;
}
