import 'package:blockchain_utils/utils/compare/compare.dart';
import 'package:blockchain_utils/utils/compare/hash_code.dart';

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

  List<dynamic> get variables;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Equality) {
      return false;
    }
    if (other.runtimeType != runtimeType) return false;
    return CompareUtils.iterableIsEqual(variables, other.variables);
  }

  @override
  int get hashCode {
    return HashCodeGenerator.generateHashCode(variables);
  }
}

abstract mixin class PartialEquality implements Equality {
  @override
  List<dynamic> get variables => [];
  List<dynamic> get parts;
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! PartialEquality) {
      return false;
    }
    if (other.runtimeType != runtimeType) return false;
    return CompareUtils.iterableIsEqual(parts, other.parts);
  }

  @override
  int get hashCode {
    return HashCodeGenerator.generateHashCode(parts);
  }
}

abstract mixin class ConstantEquality<T extends ConstantEquality<T>> {
  /// Public, non-secret fields that can be compared normally.
  List<Object?> get publicFields => [];

  /// Secret fields that MUST be compared in constant time.
  ///
  /// Subclasses MUST override this. If a class has no secrets,
  /// return an empty list.
  List<List<int>> get secretFields => [];

  bool constantEquality(T other) {
    assert(secretFields.isNotEmpty);
    return CompareUtils.iterableConstantTime(secretFields, other.secretFields);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! T) return false;
    if (!CompareUtils.iterableIsEqual(publicFields, other.publicFields)) {
      return false;
    }
    return constantEquality(other);
  }

  @override
  int get hashCode {
    // Only hash public, non-secret data.
    if (publicFields.isEmpty) return 0;
    return HashCodeGenerator.generateHashCode(publicFields);
  }
}
