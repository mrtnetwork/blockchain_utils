import 'package:blockchain_utils/layout/byte/byte_handler.dart';
import 'package:blockchain_utils/layout/core/core/core.dart';

/// Represents a layout with no data.
class NoneLayout extends Layout {
  const NoneLayout({String? property}) : super(0, property: property);

  /// Constructs a [NoneLayout] layout.
  ///
  /// - [property] (optional): The property identifier.
  @override
  Layout clone({String? newProperty}) {
    return NoneLayout(property: newProperty);
  }

  @override
  decode(LayoutByteReader bytes, {int offset = 0}) {
    return const LayoutDecodeResult(consumed: 0, value: null);
  }

  @override
  int encode(source, LayoutByteWriter writer, {int offset = 0}) {
    return 0;
  }
}
