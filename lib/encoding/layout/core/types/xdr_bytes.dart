import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/encoding/layout/buffer/buffer.dart';
import 'package:blockchain_utils/encoding/layout/core/core.dart';

/// XDR byte blob: [layout] payload padded to a 4-byte boundary.
class XDRBytesLayout extends Layout<List<int>> {
  XDRBytesLayout._(this.layout, {super.property}) : super(_paddedSpan(layout));

  final RawBytesLayout layout;

  static int _paddedSpan(RawBytesLayout layout) {
    final s = layout.span;
    if (s.isNegative) return s;
    return s + _reminder(s);
  }

  factory XDRBytesLayout(dynamic length, {String? property}) {
    if (length is int) {
      if (length.isNegative) {
        throw CoreErrors.invalidOperationArguments(
          "XDRBytesLayout",
          name: "length",
          reason: "The length must be a positive integer.",
        );
      }
    } else if (length is! ExternalLayout) {
      throw CoreErrors.invalidOperationArguments(
        "XDRBytesLayout",
        name: "length",
        reason: "The length must be a positive integer or an external layout.",
      );
    }
    return XDRBytesLayout._(RawBytesLayout(length), property: property);
  }

  /// Number of padding bytes needed to round [dividend] up to a multiple of 4.
  static int _reminder(int dividend) {
    final int remainder = dividend % 4;
    return remainder == 0 ? 0 : 4 - remainder;
  }

  @override
  int getSpan() {
    int span = layout.getSpan();
    if (span.isNegative) return span;
    span += _reminder(span);
    return span;
  }

  @override
  LayoutDecodeResult<List<int>> decode(
    LayoutByteReader bytes, {
    int offset = 0,
  }) {
    final result = layout.decode(bytes, offset: offset);
    final span = result.consumed + _reminder(result.consumed);
    return LayoutDecodeResult(consumed: span, value: result.value);
  }

  @override
  int encode(List<int> source, LayoutByteWriter writer, {int offset = 0}) {
    final span = layout.encode(source, writer, offset: offset);
    final pad = _reminder(span);
    if (pad > 0) {
      writer.setAll(offset + span, List<int>.filled(pad, 0));
    }
    return span + pad;
  }

  @override
  XDRBytesLayout clone({String? newProperty}) {
    return XDRBytesLayout._(layout, property: newProperty);
  }
}
