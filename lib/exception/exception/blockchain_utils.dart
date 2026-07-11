import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/networks/types/network.dart';

import 'exception.dart';
import 'package:blockchain_utils/serialization/identifier.dart';

/// An abstract class 'BlockchainUtilsException' that implements the Exception interface.
/// This class serves as a base for custom exceptions related to blockchain utility operations.
abstract class BlockchainUtilsException extends IException {
  /// Abstract field to hold the exception message.

  const BlockchainUtilsException(super.message, {super.details});

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

  @override
  BlockchainNetwork? get relatedNetwork => null;

  @override
  BlockchainUtilsSerializationIdentifier get serializationIdentifier;
}

/// A specific exception class 'ArgumentException' that extends 'BlockchainUtilsException'.
/// This exception is used to represent errors related to invalid arguments in blockchain utility operations.
class ArgumentException extends BlockchainUtilsException
    implements ArgumentError {
  /// Constructor to initialize the exception with a specific message.
  const ArgumentException._(super.message, {this.name, super.details});
  factory ArgumentException.deserialize({
    List<int>? bytes,
    CborObject? object,
  }) {
    final values = CborTagSerializable.decodeTaggedValue(
      identifier: BlockchainUtilsSerializationIdentifier.argumentException,
      cborBytes: bytes,
      cborObject: object,
    );
    return ArgumentException._(
      values.rawValueAt(0),
      details: values.maybeRawMapAt<String, String?>(1),
      name: values.rawValueAt(2),
    );
  }

  static ArgumentException invalidOperationArguments(
    String operation, {
    required String reason,
    String? name,
    Map<String, String>? details,
  }) => ArgumentException._(
    "Invalid $operation arguments.",
    details: {"reason": reason, ...details ?? {}},
    name: name,
  );

  @override
  get invalidValue => null;

  @override
  final String? name;

  @override
  final StackTrace? stackTrace = null;

  @override
  BlockchainUtilsSerializationIdentifier get serializationIdentifier =>
      BlockchainUtilsSerializationIdentifier.argumentException;

  @override
  List<CborObject?> get serializationItems => [
    ...super.serializationItems,
    name?.toCbor(),
    stackTrace?.toString().toCbor(),
  ];
}

class StateException extends BlockchainUtilsException implements StateError {
  /// Constructor to initialize the exception with a specific message.
  const StateException._(super.message, {super.details});

  factory StateException.deserialize({List<int>? bytes, CborObject? object}) {
    final values = CborTagSerializable.decodeTaggedValue(
      identifier: BlockchainUtilsSerializationIdentifier.stateException,
      cborBytes: bytes,
      cborObject: object,
    );
    return StateException._(
      values.rawValueAt(0),
      details: values.maybeRawMapAt<String, String?>(1),
    );
  }

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

  @override
  BlockchainUtilsSerializationIdentifier get serializationIdentifier =>
      BlockchainUtilsSerializationIdentifier.stateException;
}

class ItemNotFoundException extends ArgumentException {
  final Object? value;
  factory ItemNotFoundException.deserialize({
    List<int>? bytes,
    CborObject? object,
  }) {
    final values = CborTagSerializable.decodeTaggedValue(
      identifier: BlockchainUtilsSerializationIdentifier.itemNotFound,
      cborBytes: bytes,
      cborObject: object,
    );
    return ItemNotFoundException(
      message: values.rawValueAt(0),
      details: values.maybeRawMapAt<String, String?>(1),
    );
  }

  ItemNotFoundException({
    this.value,
    String? message,
    Map<String, String?>? details,
    String? name,
  }) : super._(
         message ?? "No matching ${name ?? 'item'} found for the given value.",
         details: details,
       );

  @override
  BlockchainUtilsSerializationIdentifier get serializationIdentifier =>
      BlockchainUtilsSerializationIdentifier.itemNotFound;
}

class CastFailedException<T> extends BlockchainUtilsException {
  final Object? value;
  CastFailedException({
    this.value,
    String? message,
    Map<String, String?>? details,
  }) : super(
         message ?? "Failed to cast value",
         details:
             details ??
             <String, String?>{
               "expected": T.toString(),
               "value": value?.runtimeType.toString(),
             }.notNullValue,
       );
  factory CastFailedException.deserialize({
    List<int>? bytes,
    CborObject? object,
  }) {
    final values = CborTagSerializable.decodeTaggedValue(
      identifier: BlockchainUtilsSerializationIdentifier.casting,
      cborBytes: bytes,
      cborObject: object,
    );
    return CastFailedException(
      message: values.rawValueAt(0),
      details: values.maybeRawMapAt<String, String?>(1),
    );
  }

  @override
  BlockchainUtilsSerializationIdentifier get serializationIdentifier =>
      BlockchainUtilsSerializationIdentifier.casting;
}
