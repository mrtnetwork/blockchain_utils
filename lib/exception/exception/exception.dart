import 'package:blockchain_utils/helper/helper.dart';

/// An abstract class 'BlockchainUtilsException' that implements the Exception interface.
/// This class serves as a base for custom exceptions related to blockchain utility operations.
abstract class BlockchainUtilsException implements Exception {
  /// Abstract field to hold the exception message.
  final String message;

  final Map<String, dynamic>? details;

  const BlockchainUtilsException(this.message, {this.details});

  @override
  String toString() {
    final infos = Map<String, dynamic>.fromEntries(
        details?.entries.where((element) => element.value != null) ?? []);
    if (infos.isEmpty) return message;
    final String msg =
        "$message ${infos.entries.map((e) => "${e.key}: ${e.value}").join(", ")}";
    return msg;
  }
}

/// A specific exception class 'ArgumentException' that extends 'BlockchainUtilsException'.
/// This exception is used to represent errors related to invalid arguments in blockchain utility operations.
class ArgumentException extends BlockchainUtilsException {
  /// Constructor to initialize the exception with a specific message.
  const ArgumentException(super.message, {super.details});
}

/// Another specific exception class 'MessageException' that extends 'BlockchainUtilsException'.
/// This exception is used to represent errors related to messages in blockchain utility operations.
class MessageException extends BlockchainUtilsException {
  /// Constructor to initialize the exception with a specific message.
  const MessageException(super.message, {super.details});
}

class GenericException extends BlockchainUtilsException {
  /// Constructor to initialize the exception with a specific message.
  const GenericException(super.message, {super.details});
}

class ItemNotFoundException extends BlockchainUtilsException {
  final Object? value;

  /// Constructor to initialize the exception with a specific message.
  ItemNotFoundException(
      {this.value, String? message, Map<String, dynamic>? details})
      : super(message ?? "No matching item found for the given value.",
            details: {"value": value});
}

class CastFailedException<T> extends BlockchainUtilsException {
  final Object? value;
  CastFailedException(
      {this.value, String? message, Map<String, dynamic>? details})
      : super(message ?? "Failed to cast value",
            details: details ??
                {"expected": T.toString(), "value": value?.runtimeType}
                    .notNullValue);
}
