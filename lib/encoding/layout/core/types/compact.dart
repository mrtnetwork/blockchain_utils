import 'package:blockchain_utils/encoding/layout/core/types/numeric.dart';

/// Offset layout that delegates to a compact-encoded [CompactIntLayout].
class CompactOffsetLayout extends WrappedIntOffsetLayout<CompactIntLayout> {
  CompactOffsetLayout(super.layout, {super.property});

  @override
  CompactOffsetLayout clone({String? newProperty}) {
    return CompactOffsetLayout(layout, property: newProperty);
  }
}
