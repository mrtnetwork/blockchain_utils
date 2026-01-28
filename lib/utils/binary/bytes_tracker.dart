import 'package:blockchain_utils/helper/helper.dart';

/// A utility class for tracking bytes dynamically.
class DynamicByteTracker {
  final List<int> _buffer = List.empty(growable: true);

  /// Get the last byte in the tracked bytes.
  int get last => _buffer.last;

  /// buffer bytes.
  List<int> toBytes() {
    return _buffer.clone();
  }

  void add(List<int> chunk) {
    _buffer.addAll(chunk.asBytes);
  }
}
