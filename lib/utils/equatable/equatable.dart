import 'package:blockchain_utils/blockchain_utils.dart';

abstract mixin class Equality {
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
