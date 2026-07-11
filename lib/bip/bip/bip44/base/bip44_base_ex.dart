import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/serialization/identifier.dart';

/// Custom exception for errors related to BIP-44 depth.
///
/// This class, `Bip44DepthError`, represents a custom exception for handling
/// errors related to the BIP-44 hierarchical deterministic wallet structure's
/// depth. It can be thrown to indicate issues with depth levels in BIP-44 paths.
class Bip44DepthError extends BlockchainUtilsException {
  const Bip44DepthError(super.message, {super.details});

  factory Bip44DepthError.deserialize({List<int>? bytes, CborObject? object}) {
    final values = CborTagSerializable.decodeTaggedValue(
      identifier: BlockchainUtilsSerializationIdentifier.bip44DepthError,
      cborBytes: bytes,
      cborObject: object,
    );
    return Bip44DepthError(
      values.rawValueAt(0),
      details: values.maybeRawMapAt<String, String?>(1),
    );
  }

  @override
  BlockchainUtilsSerializationIdentifier get serializationIdentifier =>
      BlockchainUtilsSerializationIdentifier.bip44DepthError;
}
