// import 'package:blockchain_utils/layout/byte/byte_handler.dart';
// import 'package:blockchain_utils/layout/core/core/core.dart';
// import 'package:blockchain_utils/layout/exception/exception.dart';
// import 'package:blockchain_utils/utils/utils.dart';

// /// A class representing a C-style string layout within a buffer.
// class CStringLayout extends Layout<String> {
//   /// Constructs a [CStringLayout] with the given [property].
//   const CStringLayout({String? property}) : super(-1, property: property);

//   @override
//   int getSpan(LayoutByteReader? bytes, {int offset = 0}) {
//     int idx = offset;
//     while (idx < bytes!.length && bytes.at(idx) != 0) {
//       idx += 1;
//     }
//     return 1 + idx - offset;
//   }

//   @override
//   LayoutDecodeResult<String> decode(LayoutByteReader bytes, {int offset = 0}) {
//     int span = getSpan(bytes, offset: offset);
//     final totalLength = span - 1;
//     final result =
//         String.fromCharCodes(bytes.sublist(offset, offset + totalLength));
//     return LayoutDecodeResult(consumed: totalLength, value: result);
//   }

//   @override
//   int encode(String source, LayoutByteWriter writer, {int offset = 0}) {
//     List<int> srcBytes = StringUtils.encode(source);
//     int span = srcBytes.length;
//     if (!writer.growable && (offset + span) > writer.length) {
//       throw LayoutException("Encoding overruns bytes",
//           details: {"property": property});
//     }

//     writer.setRange(offset, offset + span, srcBytes);
//     writer.set(offset + span, 0);
//     return span + 1;
//   }

//   @override
//   CStringLayout clone({String? newProperty}) {
//     return CStringLayout(property: newProperty);
//   }
// }
