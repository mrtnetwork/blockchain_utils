import 'package:blockchain_utils/encoding/layout/core/types/compact_bytes.dart';
import 'package:blockchain_utils/utils/string/string.dart';

/// Compact-length-prefixed UTF-8 string.
class CompactString extends CompactLengthPrefixedLayout<String> {
  CompactString({super.property});

  @override
  String fromBytes(List<int> bytes) => StringUtils.decode(bytes);

  @override
  List<int> toBytes(String source) => StringUtils.encode(source);

  @override
  CompactString clone({String? newProperty}) {
    return CompactString(property: newProperty);
  }
}
