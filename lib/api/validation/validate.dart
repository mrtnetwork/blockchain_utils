import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Shared argument checks for API validation wrappers.
/// Throws [BuError] on bad caller input.
abstract final class ApiValidate {
  /// Requires [data] to be exactly [expected] bytes, throws [BuError] otherwise.
  static void length(
    List<int> data,
    int expected, {
    required String operation,
    required String name,
  }) {
    if (data.length != expected) {
      throw CoreErrors.invalidOperationArguments(
        operation,
        name: name,
        reason: 'expected $expected bytes, got ${data.length}',
        details: {'expected': '$expected', 'actual': '${data.length}'},
      );
    }
  }

  /// Runs [run] for operation [op], rethrows [BuError]/[CryptoException], wraps the rest in [CryptoException].
  static T call<T>(String op, T Function() run) {
    try {
      return run();
    } on BuError {
      rethrow;
    } catch (e) {
      throw CoreErrors.cryptoFailed(op, reason: e.toString());
    }
  }

  /// Requires [data] length to be one of [allowed], throws [BuError] otherwise.
  static void oneOfLengths(
    List<int> data,
    List<int> allowed, {
    required String operation,
    required String name,
  }) {
    if (!allowed.contains(data.length)) {
      throw CoreErrors.invalidOperationArguments(
        operation,
        name: name,
        reason: 'length ${data.length} not in $allowed',
        details: {'actual': '${data.length}', 'allowed': '$allowed'},
      );
    }
  }

  /// Requires [digestLength] to be non-negative and within [min]/[max], throws [BuError] otherwise.
  static void digestLength(
    int digestLength, {
    int? max,
    int? min,
    required String operation,
    required String name,
  }) {
    if ((max != null && digestLength > max) ||
        (min != null && digestLength < min) ||
        digestLength.isNegative) {
      throw CoreErrors.invalidOperationArguments(
        operation,
        name: name,
        reason: 'Invalid digest length.',
      );
    }
    // if (!allowed.contains(data.length)) {

    // }
  }

  /// Requires [data] to be non-empty, throws [BuError] if empty.
  static void nonEmpty(
    List<int> data, {
    required String operation,
    required String name,
  }) {
    if (data.isEmpty) {
      throw CoreErrors.invalidOperationArguments(
        operation,
        name: name,
        reason: 'must not be empty',
      );
    }
  }

  /// Requires ML-DSA [level] to be 44, 65, or 87, throws [BuError] otherwise.
  static void levelMlDsa(int level, String operation) {
    if (level != 44 && level != 65 && level != 87) {
      throw CoreErrors.invalidOperationArguments(
        operation,
        name: 'level',
        reason: 'must be 44, 65, or 87, got $level',
      );
    }
  }
}
