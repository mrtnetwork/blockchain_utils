import 'package:blockchain_utils/utils/equatable/equatable.dart';

abstract class ComparableRange<T> with Iterable<T>, Equality {
  final T start;
  final T end;
  const ComparableRange(this.start, this.end);
}

class ComparableIntRange extends ComparableRange<int> {
  ComparableIntRange(super.start, super.end);
  @override
  bool contains(Object? element) {
    return switch (element) {
      final int p => p >= start && p <= end,
      _ => false,
    };
  }

  late final List<int> _items = [for (int i = start; i < end; i++) i];

  @override
  Iterator<int> get iterator => _items.iterator;

  @override
  List<dynamic> get variables => [start, end];

  @override
  String toString() {
    return "ComparableIntRange($start,$end)";
  }
}

class ComparableBigIntRange extends ComparableRange<BigInt> {
  ComparableBigIntRange(super.start, super.end);
  @override
  bool contains(Object? element) {
    return switch (element) {
      final BigInt p => p >= start && p <= end,
      _ => false,
    };
  }

  late final List<BigInt> _items = [
    for (BigInt i = start; i < end; i += BigInt.one) i,
  ];

  @override
  Iterator<BigInt> get iterator => _items.iterator;

  @override
  List<dynamic> get variables => [start, end];

  @override
  String toString() {
    return "ComparableBigIntRange($start,$end)";
  }
}
