import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/serialization/identifier.dart';

/// The `Bip32KeyError` class represents an exception that can be thrown in case
/// of a key-related error during Bip32 key operations. It allows you to provide
/// an optional error message to describe the specific issue. When caught, you
/// can access the error message using the `toString()` method or the `message`
/// property, if provided.
class Bip32KeyError extends BlockchainUtilsException {
  const Bip32KeyError(super.message, {super.details});
  static Bip32KeyError get notHardenedIndexNotSupported => Bip32KeyError(
    'Private child derivation with not-hardened index is not supported',
  );
  static Bip32KeyError get publicDerivationNotSupported =>
      Bip32KeyError('Public child derivation is not supported');
  static Bip32KeyError get publicHardenedIndexNotSupported => Bip32KeyError(
    'Public child derivation with hardened index is not supported',
  );

  factory Bip32KeyError.deserialize({List<int>? bytes, CborObject? object}) {
    final values = CborTagSerializable.decodeTaggedValue(
      identifier: BlockchainUtilsSerializationIdentifier.bip32KeyError,
      cborBytes: bytes,
      cborObject: object,
    );
    return Bip32KeyError(
      values.rawValueAt(0),
      details: values.maybeRawMapAt<String, String?>(1),
    );
  }

  @override
  BlockchainUtilsSerializationIdentifier get serializationIdentifier =>
      BlockchainUtilsSerializationIdentifier.bip32KeyError;
}

/// The `Bip32PathError` class represents an exception that can be thrown in case
/// of a path-related error during Bip32 operations. It is designed to handle
/// errors associated with hierarchical deterministic paths. You can include
/// an optional error message to describe the specific issue. To access the error
/// message, use the `toString()` method or the `message` property, if provided.
class Bip32PathError extends BlockchainUtilsException {
  const Bip32PathError(super.message, {super.details});

  factory Bip32PathError.deserialize({List<int>? bytes, CborObject? object}) {
    final values = CborTagSerializable.decodeTaggedValue(
      identifier: BlockchainUtilsSerializationIdentifier.bip32PathError,
      cborBytes: bytes,
      cborObject: object,
    );
    return Bip32PathError(
      values.rawValueAt(0),
      details: values.maybeRawMapAt<String, String?>(1),
    );
  }

  @override
  BlockchainUtilsSerializationIdentifier get serializationIdentifier =>
      BlockchainUtilsSerializationIdentifier.bip32PathError;
}
