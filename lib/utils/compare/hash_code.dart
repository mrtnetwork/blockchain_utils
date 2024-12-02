import '../binary/binary_operation.dart';

class HashCodeGenerator {
  static int generateBytesHashCode(List<int> bytes,
      [List<Object> optional = const []]) {
    int hash = 12;
    for (final element in bytes) {
      hash ^= element; // XOR each element into the hash
      hash = (hash * 31) & mask32;
    }
    for (final element in optional) {
      hash = (hash ^ element.hashCode) & mask32;
    }
    return hash;
  }

  static int generateHashCode(List<Object> objects) {
    int hash = 12;
    for (final element in objects) {
      hash = (hash ^ element.hashCode) & mask32;
    }
    return hash;
  }
}
