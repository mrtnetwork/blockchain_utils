import 'package:blockchain_utils/blockchain_utils.dart';

abstract mixin class Equality {
  static bool deepEqual(Object? a, Object? b) {
    if (a == null || b == null) return false;
    if (a == b) return true;
    if (identical(a, b)) return true;
    if (a is List && b is List) {
      return CompareUtils.iterableIsEqual(a, b);
    }
    if (a is Map && b is Map) {
      return CompareUtils.mapIsEqual(a, b);
    }
    return false;
  }

  List<dynamic> get variabels;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Equality) {
      return false;
    }
    if (other.runtimeType != runtimeType) return false;
    return CompareUtils.iterableIsEqual(variabels, other.variabels);
  }

  @override
  int get hashCode {
    return HashCodeGenerator.generateHashCode(variabels);
  }
}
