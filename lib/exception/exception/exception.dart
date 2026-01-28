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
      details?.entries.where((element) => element.value != null) ?? [],
    );
    if (infos.isEmpty) return message;
    final String msg =
        "$message ${infos.entries.map((e) => "${e.key}: ${e.value}").join(", ")}";
    return msg;
  }
}

/// A specific exception class 'ArgumentException' that extends 'BlockchainUtilsException'.
/// This exception is used to represent errors related to invalid arguments in blockchain utility operations.
class ArgumentException extends BlockchainUtilsException
    implements ArgumentError {
  /// Constructor to initialize the exception with a specific message.
  const ArgumentException._(
    super.message, {
    this.name,
    this.stackTrace,
    super.details,
  });

  static ArgumentException invalidOperationArguments(
    String operation, {
    String? name,
    required String reason,
    int? expecteLen,
    Map<String, dynamic>? details,
  }) => ArgumentException._(
    "Invalid $name arguments.",
    details: {"operation": operation, "reason": reason},
    name: name,
  );

  @override
  get invalidValue => null;

  @override
  final String? name;

  @override
  final StackTrace? stackTrace;
}

class StateException extends BlockchainUtilsException implements StateError {
  /// Constructor to initialize the exception with a specific message.
  const StateException._(super.message, {super.details});

  static StateException badState(
    String operation, {
    String? name,
    required String reason,
    int? expecteLen,
    Map<String, dynamic>? details,
  }) => StateException._(
    "$operation not allowed in current state.",
    details: {"expected": operation, "reason": reason},
  );

  @override
  final StackTrace? stackTrace = null;
}

class ItemNotFoundException extends ArgumentException {
  final Object? value;

  /// Constructor to initialize the exception with a specific message.
  ItemNotFoundException({
    this.value,
    String? message,
    Map<String, dynamic>? details,
    String? name,
  }) : super._(
         message ?? "No matching ${name ?? 'item'} found for the given value.",
         details: {"value": value},
       );
}

class CastFailedException<T> extends BlockchainUtilsException {
  final Object? value;
  CastFailedException({
    this.value,
    String? message,
    Map<String, dynamic>? details,
  }) : super(
         message ?? "Failed to cast value",
         details:
             details ??
             {
               "expected": T.toString(),
               "value": value?.runtimeType,
             }.notNullValue,
       );
}
