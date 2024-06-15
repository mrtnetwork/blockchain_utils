import 'utils.dart';

/// A utility class for tracking bytes dynamically.
class DynamicByteTracker {
  final List<int> _buffer = List.empty(growable: true);

  /// Get the last byte in the tracked bytes.
  int get last => _buffer.last;

  /// buffer bytes.
  List<int> toBytes() {
    return List<int>.from(_buffer);
  }

  void add(List<int> chunk) {
    _buffer.addAll(BytesUtils.toBytes(chunk));
  }
}
