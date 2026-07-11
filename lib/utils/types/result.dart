import 'dart:async';

import 'package:blockchain_utils/exception/exceptions.dart';

/// A Rust-like Result type
sealed class Result<T extends Object?, E extends Object?> {
  const Result();

  bool get isOk;
  bool get isErr;

  T unwrap();
  E unwrapErr();

  T unwrapOr(T defaultValue);
  T? ok();
  E? err();

  Result<U, E> map<U>(U Function(T value) f);
  Result<T, F> mapErr<F>(F Function(E error) f);

  FutureOr<Result<U, E>> mapAsync<U>(FutureOr<U> Function(T value) f);
  FutureOr<Result<T, F>> mapErrAsync<F>(FutureOr<F> Function(E error) f);
  Result<U, E> andThen<U>(Result<U, E> Function(T value) f);
  FutureOr<Result<U, E>> andThenAsync<U>(
    FutureOr<Result<U, E>> Function(T value) f,
  );

  R fold<R extends Object?>({
    R Function(T value)? onOk,
    R Function(E error)? onErr,
  });
  R foldOne<R extends Object?>(R Function(T? value, E? error) f);
}

class Ok<T extends Object?, E extends Object?> extends Result<T, E> {
  final T value;

  const Ok(this.value);

  @override
  bool get isOk => true;

  @override
  bool get isErr => false;

  @override
  T unwrap() => value;

  @override
  E unwrapErr() {
    throw StateException.badState("unwrap", reason: "Called unwrapErr() on Ok");
  }

  @override
  T unwrapOr(T defaultValue) => value;

  @override
  T? ok() => value;

  @override
  E? err() => null;

  @override
  Result<U, E> map<U>(U Function(T value) f) {
    return Ok<U, E>(f(value));
  }

  @override
  Result<T, F> mapErr<F>(F Function(E error) f) {
    return Ok<T, F>(value);
  }

  @override
  Result<U, E> andThen<U>(Result<U, E> Function(T value) f) {
    return f(value);
  }

  @override
  String toString() => 'Ok($value)';

  @override
  R fold<R extends Object?>({
    R Function(T value)? onOk,
    R Function(E error)? onErr,
  }) {
    if (onOk == null) {
      if (null is R) return null as R;
      throw ArgumentException.invalidOperationArguments(
        "fold",
        reason: "onOk handler is required when R is non-nullable",
      );
    }
    return onOk(value);
  }

  @override
  R foldOne<R extends Object?>(R Function(T? value, E? error) f) {
    return f(value, null);
  }

  @override
  FutureOr<Result<U, E>> andThenAsync<U>(
    FutureOr<Result<U, E>> Function(T value) f,
  ) async {
    return await f(value);
  }

  @override
  FutureOr<Result<U, E>> mapAsync<U>(FutureOr<U> Function(T value) f) async {
    final reslt = await f(value);
    return Ok(reslt);
  }

  @override
  FutureOr<Result<T, F>> mapErrAsync<F>(FutureOr<F> Function(E error) f) {
    return Ok<T, F>(value);
  }
}

class Err<T extends Object?, E extends Object?> extends Result<T, E> {
  final E error;

  const Err(this.error);

  @override
  bool get isOk => false;

  @override
  bool get isErr => true;

  @override
  T unwrap() {
    throw StateException.badState(
      "unwrap",
      reason: "Called unwrap() on Err: $error",
    );
  }

  @override
  E unwrapErr() => error;

  @override
  T unwrapOr(T defaultValue) => defaultValue;

  @override
  T? ok() => null;

  @override
  E? err() => error;

  @override
  Result<U, E> map<U>(U Function(T value) f) {
    return Err<U, E>(error);
  }

  @override
  Result<T, F> mapErr<F>(F Function(E error) f) {
    return Err<T, F>(f(error));
  }

  @override
  Result<U, E> andThen<U>(Result<U, E> Function(T value) f) {
    return Err<U, E>(error);
  }

  @override
  String toString() => 'Err($error)';

  @override
  R fold<R extends Object?>({
    R Function(T value)? onOk,
    R Function(E error)? onErr,
  }) {
    if (onErr == null) {
      if (null is R) return null as R;
      throw ArgumentException.invalidOperationArguments(
        "fold",
        reason: "onErr handler is required when R is non-nullable",
      );
    }
    return onErr(error);
  }

  @override
  R foldOne<R extends Object?>(R Function(T? value, E? error) f) {
    return f(null, error);
  }

  @override
  FutureOr<Result<U, E>> andThenAsync<U>(
    FutureOr<Result<U, E>> Function(T value) f,
  ) {
    return Err<U, E>(error);
  }

  @override
  FutureOr<Result<U, E>> mapAsync<U>(FutureOr<U> Function(T value) f) {
    return Err<U, E>(error);
  }

  @override
  FutureOr<Result<T, F>> mapErrAsync<F>(FutureOr<F> Function(E error) f) async {
    final result = await f(error);
    return Err(result);
  }
}
