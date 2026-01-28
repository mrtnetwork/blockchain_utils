sealed class Either<L, R> {
  const Either();

  bool get isLeft => false;
  bool get isRight => false;

  L? left();
  R? right();

  T fold<T>({
    required T Function(L left) onLeft,
    required T Function(R right) onRight,
  });

  Either<L2, R2> map<L2, R2>({
    L2 Function(L left)? mapLeft,
    R2 Function(R right)? mapRight,
  });
}

final class Left<L, R> extends Either<L, R> {
  final L value;
  const Left(this.value);
  @override
  bool get isLeft => true;
  @override
  T fold<T>({
    required T Function(L left) onLeft,
    required T Function(R right) onRight,
  }) {
    return onLeft(value);
  }

  @override
  Either<L2, R2> map<L2, R2>({
    L2 Function(L left)? mapLeft,
    R2 Function(R right)? mapRight,
  }) {
    return Left<L2, R2>(mapLeft != null ? mapLeft(value) : value as L2);
  }

  @override
  L? left() {
    return value;
  }

  @override
  R? right() {
    return null;
  }
}

final class Right<L, R> extends Either<L, R> {
  final R value;
  const Right(this.value);
  @override
  bool get isRight => true;
  @override
  T fold<T>({
    required T Function(L left) onLeft,
    required T Function(R right) onRight,
  }) {
    return onRight(value);
  }

  @override
  Either<L2, R2> map<L2, R2>({
    R2 Function(R right)? mapRight,
    L2 Function(L left)? mapLeft,
  }) {
    return Right<L2, R2>(mapRight != null ? mapRight(value) : value as R2);
  }

  @override
  L? left() {
    return null;
  }

  @override
  R? right() {
    return value;
  }
}
