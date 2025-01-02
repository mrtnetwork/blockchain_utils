import 'package:blockchain_utils/exception/exceptions.dart';

/// The `Bip32KeyError` class represents an exception that can be thrown in case
/// of a key-related error during Bip32 key operations. It allows you to provide
/// an optional error message to describe the specific issue. When caught, you
/// can access the error message using the `toString()` method or the `message`
/// property, if provided.
class Bip32KeyError extends BlockchainUtilsException {
  const Bip32KeyError(super.message, {super.details});
}

/// The `Bip32PathError` class represents an exception that can be thrown in case
/// of a path-related error during Bip32 operations. It is designed to handle
/// errors associated with hierarchical deterministic paths. You can include
/// an optional error message to describe the specific issue. To access the error
/// message, use the `toString()` method or the `message` property, if provided.
class Bip32PathError extends BlockchainUtilsException {
  const Bip32PathError(super.message, {super.details});
}
