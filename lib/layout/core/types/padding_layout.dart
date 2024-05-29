import 'package:blockchain_utils/layout/byte/byte_handler.dart';
import 'package:blockchain_utils/layout/core/core/core.dart';
import 'numeric.dart';

class PaddingLayout<T> extends Layout<T> {
  final BaseIntiger<T> layout;
  PaddingLayout(this.layout, {String? property})
      : super(layout.span, property: property);

  @override
  int getSpan(LayoutByteReader? bytes, {int offset = 0}) {
    return layout.getSpan(bytes, offset: offset);
  }

  @override
  PaddingLayout clone({String? newProperty}) {
    return PaddingLayout(layout, property: newProperty);
  }

  @override
  LayoutDecodeResult<T> decode(LayoutByteReader bytes, {int offset = 0}) {
    return layout.decode(bytes, offset: offset);
  }

  @override
  int encode(T source, LayoutByteWriter writer, {int offset = 0}) {
    return layout.encode(source, writer, offset: offset);
  }
}
