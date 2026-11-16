import 'package:blockchain_utils/encoding/layout/core/types/numeric.dart';

/// Offset layout that delegates to a varint-encoded [VarintIntLayout].
class VarintOffsetLayout extends WrappedIntOffsetLayout<VarintIntLayout> {
  VarintOffsetLayout(super.layout, {super.property});

  @override
  VarintOffsetLayout clone({String? newProperty}) {
    return VarintOffsetLayout(layout, property: newProperty);
  }
}
