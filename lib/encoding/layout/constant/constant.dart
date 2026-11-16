import 'dart:typed_data';

import 'package:blockchain_utils/encoding/layout/core/core.dart';
import 'package:blockchain_utils/encoding/layout/core/types/compact_string.dart';
import 'package:blockchain_utils/utils/binary/src/utils.dart';
import 'package:blockchain_utils/utils/json/extension/json.dart';
import 'package:blockchain_utils/utils/string/string.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Factory methods for every layout type: the primary entry point for
/// building layouts without calling each type's constructor directly.
class LayoutConst {
  /// [GreedyCount].
  static GreedyCount greedy({int elementSpan = 1, String? property}) =>
      GreedyCount(elementSpan, property);

  /// [OffsetLayout].
  static OffsetLayout offset(
    PaddingLayout<int> layout,
    int offset, {
    String? property,
  }) => OffsetLayout(layout, offset: offset, property: property);

  /// [IntegerLayout] (unsigned int layouts) spanning one byte.
  static IntegerLayout u8({String? property}) =>
      IntegerLayout(1, property: property);

  /// [IntegerLayout] (signed int layouts) spanning one byte.
  static IntegerLayout i8({String? property}) =>
      IntegerLayout(1, property: property, sign: true);

  /// [IntegerLayout] (little-endian unsigned int layouts) spanning two bytes.
  static IntegerLayout u16({String? property}) =>
      IntegerLayout(2, property: property);

  /// [IntegerLayout] (little-endian signed int layouts) spanning two bytes.
  static IntegerLayout i16({String? property}) =>
      IntegerLayout(2, property: property, sign: true);

  /// [IntegerLayout] (big-endian signed int layouts) spanning two bytes.
  static IntegerLayout i16Be({String? property}) =>
      IntegerLayout(2, property: property, sign: true, order: Endian.big);

  /// [IntegerLayout] (little-endian unsigned int layouts) spanning three bytes.
  static IntegerLayout u24({String? property}) =>
      IntegerLayout(3, property: property);

  /// [IntegerLayout] (little-endian signed int layouts) spanning three bytes.
  static IntegerLayout i24({String? property}) =>
      IntegerLayout(3, property: property, sign: true);

  /// [IntegerLayout] (little-endian unsigned int layouts) spanning four bytes.
  static IntegerLayout u32({String? property}) =>
      IntegerLayout(4, property: property);

  /// [IntegerLayout] (little-endian signed int layouts) spanning four bytes.
  static IntegerLayout i32({String? property}) =>
      IntegerLayout(4, property: property, sign: true);

  /// [IntegerLayout] (big-endian signed int layouts) spanning four bytes.
  static IntegerLayout i32Be({String? property}) =>
      IntegerLayout(4, property: property, sign: true, order: Endian.big);

  /// [IntegerLayout] (little-endian unsigned int layouts) spanning five bytes.
  static IntegerLayout u40({String? property}) =>
      IntegerLayout(5, property: property);

  /// [IntegerLayout] (little-endian signed int layouts) spanning five bytes.
  static IntegerLayout i40({String? property}) =>
      IntegerLayout(5, property: property, sign: true);

  /// [IntegerLayout] (little-endian unsigned int layouts) spanning six bytes.
  static IntegerLayout u48({String? property}) =>
      IntegerLayout(6, property: property);

  /// [IntegerLayout] (little-endian signed int layouts) spanning six bytes.
  static IntegerLayout i48({String? property}) =>
      IntegerLayout(6, property: property, sign: true);

  /// [BigIntLayout] (little-endian unsigned int layouts) interpreted as Numbers.
  static BigIntLayout nu64({String? property}) =>
      BigIntLayout(8, property: property);

  /// [IntegerLayout] (big-endian unsigned int layouts) spanning two bytes.
  static IntegerLayout u16be({String? property}) =>
      IntegerLayout(2, property: property, order: Endian.big);

  /// [IntegerLayout] (big-endian unsigned int layouts) spanning three bytes.
  static IntegerLayout u24be({String? property}) =>
      IntegerLayout(3, property: property, order: Endian.big);

  /// [IntegerLayout] (big-endian unsigned int layouts) spanning four bytes.
  static IntegerLayout u32be({String? property}) =>
      IntegerLayout(4, property: property, order: Endian.big);

  /// [IntegerLayout] (big-endian unsigned int layouts) spanning five bytes.
  static IntegerLayout u40be({String? property}) =>
      IntegerLayout(5, property: property, order: Endian.big);

  /// [IntegerLayout] (big-endian unsigned int layouts) spanning six bytes.
  static IntegerLayout u48be({String? property}) =>
      IntegerLayout(6, property: property, order: Endian.big);

  /// [BigIntLayout] (big-endian unsigned int layouts) interpreted as Numbers.
  static BigIntLayout u64be({String? property}) =>
      BigIntLayout(8, property: property, order: Endian.big);

  /// [BigIntLayout] (big-endian signed int layouts) interpreted as Numbers.
  static BigIntLayout i64Be({String? property}) =>
      BigIntLayout(8, property: property, order: Endian.big, sign: true);

  /// [IntegerLayout] (signed int layouts) spanning one byte.
  static IntegerLayout s8({String? property}) =>
      IntegerLayout(1, property: property, sign: true);

  /// [IntegerLayout] (little-endian signed int layouts) spanning two bytes.
  static IntegerLayout s16({String? property}) =>
      IntegerLayout(2, property: property, sign: true);

  /// [IntegerLayout] (little-endian signed int layouts) spanning three bytes.
  static IntegerLayout s24({String? property}) =>
      IntegerLayout(3, property: property, sign: true);

  /// [IntegerLayout] (little-endian signed int layouts) spanning four bytes.
  static IntegerLayout s32({String? property}) =>
      IntegerLayout(4, property: property, sign: true);

  /// [IntegerLayout] (little-endian signed int layouts) spanning five bytes.
  static IntegerLayout s40({String? property}) =>
      IntegerLayout(5, property: property, sign: true);

  /// [IntegerLayout] (little-endian signed int layouts) spanning six bytes.
  static IntegerLayout s48({String? property}) =>
      IntegerLayout(6, property: property, sign: true);

  /// [BigIntLayout] (little-endian signed int layouts) interpreted as Numbers.
  static BigIntLayout ns64({String? property}) =>
      BigIntLayout(8, property: property, sign: true);

  /// [IntegerLayout] (big-endian signed int layouts) spanning two bytes.
  static IntegerLayout s16be({String? property}) =>
      IntegerLayout(2, property: property, sign: true, order: Endian.big);

  /// [IntegerLayout] (big-endian signed int layouts) spanning three bytes.
  static IntegerLayout s24be({String? property}) =>
      IntegerLayout(3, property: property, sign: true, order: Endian.big);

  /// [IntegerLayout] (big-endian signed int layouts) spanning four bytes.
  static IntegerLayout s32be({String? property}) =>
      IntegerLayout(4, property: property, sign: true, order: Endian.big);

  /// [IntegerLayout] (big-endian signed int layouts) spanning five bytes.
  static IntegerLayout s40be({String? property}) =>
      IntegerLayout(5, property: property, sign: true, order: Endian.big);

  /// [IntegerLayout] (big-endian signed int layouts) spanning six bytes.
  static IntegerLayout s48be({String? property}) =>
      IntegerLayout(6, property: property, sign: true, order: Endian.big);

  /// [BigIntLayout] (big-endian signed int layouts) interpreted as Numbers.
  static BigIntLayout s64be({String? property}) =>
      BigIntLayout(8, property: property, sign: true, order: Endian.big);

  /// [DoubleLayout] (little-endian 32-bit floating point) values.
  static DoubleLayout f32({String? property}) =>
      DoubleLayout.f32(property: property);

  /// [DoubleLayout] (big-endian 32-bit floating point) values.
  static DoubleLayout f32be({String? property}) =>
      DoubleLayout.f32(property: property, order: Endian.big);

  /// [DoubleLayout] (little-endian 64-bit floating point) values.
  static DoubleLayout f64({String? property}) =>
      DoubleLayout.f64(property: property);

  /// [DoubleLayout] (big-endian 64-bit floating point) values.
  static DoubleLayout f64be({String? property}) =>
      DoubleLayout.f64(property: property, order: Endian.big);

  /// [StructLayout] values.
  static StructLayout struct(
    List<Layout> fields, {
    String? property,
    bool decodePrefixes = false,
  }) =>
      StructLayout(fields, property: property, decodePrefixes: decodePrefixes);

  /// [LazyStructLayout] values.
  static LazyStructLayout<R> lazyStruct<R extends LayoutRepository>(
    List<LazyStructLayoutBuilder<Object?, R>> fields, {
    String? property,
    R? repository,
    bool decodePrefixes = false,
  }) => LazyStructLayout(
    fields,
    property: property,
    decodePrefixes: decodePrefixes,
    repository: repository,
  );

  /// [SequenceLayout] values.
  static SequenceLayout seq<T>(
    Layout elementLayout,
    Layout<int> count, {
    String? property,
  }) => SequenceLayout<T>(
    elementLayout: elementLayout,
    count: count,
    property: property,
  );

  /// [Union] values.
  static Union union(dynamic discr, {String? property}) =>
      Union(discr, property: property);

  /// [RawBytesLayout] values.
  static RawBytesLayout blob(dynamic length, {String? property}) =>
      RawBytesLayout(length, property: property);

  /// [RawBytesLayout] spanning a fixed 32 bytes.
  static RawBytesLayout fixedBlob32({String? property}) =>
      RawBytesLayout(32, property: property);

  /// [RawBytesLayout] spanning a fixed [len] bytes.
  static RawBytesLayout fixedBlobN(int len, {String? property}) =>
      RawBytesLayout(len, property: property);

  /// [ConstantLayout] holding a fixed [value].
  static ConstantLayout<T> constant<T extends Object>(
    T value, {
    String? property,
  }) => ConstantLayout(value, property: property);

  /// Formats a debug name for [lo], including its property if set.
  static String nameWithProperty(String name, Layout? lo) {
    if (lo?.property != null) {
      return '$name[${lo!.property!}]';
    }
    return name;
  }

  /// [COptionLayout] for a Rust `COption<PublicKey>`-shaped value.
  static COptionLayout cOptionalPublicKey(Layout layout, {String? property}) {
    return COptionLayout(layout, property: property);
  }

  /// [BigIntLayout] (little-endian unsigned int layouts) interpreted as Numbers.
  static BigIntLayout u64({String? property}) =>
      BigIntLayout(8, property: property);

  /// [BigIntLayout] (little-endian signed int layouts) interpreted as Numbers.
  static BigIntLayout i64({String? property}) =>
      BigIntLayout(8, sign: true, property: property);

  /// [BigIntLayout] (little-endian unsigned int layouts) interpreted as Numbers.
  static BigIntLayout u128({String? property}) =>
      BigIntLayout(16, property: property);

  /// [BigIntLayout] (little-endian unsigned int layouts) interpreted as Numbers.
  static BigIntLayout u256({String? property}) =>
      BigIntLayout(32, property: property);

  /// [BigIntLayout] (little-endian signed int layouts) interpreted as Numbers.
  static BigIntLayout i128({String? property}) =>
      BigIntLayout(16, sign: true, property: property);

  /// [BigIntLayout] (little-endian signed int layouts) spanning 32 bytes.
  static BigIntLayout i256({String? property}) =>
      BigIntLayout(32, sign: true, property: property);

  /// [BigIntLayout] of an arbitrary [length] in bytes.
  static BigIntLayout bigintLayout(
    int length, {
    String? property,
    bool sign = false,
  }) => BigIntLayout(length, sign: sign, property: property);

  /// [IntegerLayout] of an arbitrary [length] in bytes.
  static IntegerLayout intLayout(
    int length, {
    String? property,
    bool sign = false,
  }) => IntegerLayout(length, sign: sign, property: property);

  /// Optional [BigIntLayout] (little-endian unsigned int layouts) interpreted as Numbers.
  static OptionalLayout optionU64({String? property}) {
    return OptionalLayout<BigInt>(u64(), property: property);
  }

  /// [OptionalLayout] with a big-endian u32 discriminator.
  static OptionalLayout optionalU32Be(
    Layout layout, {
    String? property,
    bool keepSize = false,
  }) {
    return optional(
      layout,
      keepSize: keepSize,
      discriminator: u32be(),
      property: property,
    );
  }

  /// [OptionalLayout]
  static OptionalLayout<T> optional<T>(
    Layout<T> layout, {
    String? property,
    bool keepSize = false,
    BaseInteger? discriminator,
  }) {
    return OptionalLayout<T>(
      layout,
      property: property,
      discriminator: discriminator,
      keepLayoutSize: keepSize,
    );
  }

  /// [OptionalLayout] variant used with varint-based discriminators.
  static OptionalLayout<T> optionalVarint<T>(
    Layout<T> layout, {
    String? property,
    bool keepSize = false,
    BaseInteger? discriminator,
  }) {
    return OptionalLayout<T>(
      layout,
      property: property,
      discriminator: discriminator,
      keepLayoutSize: keepSize,
    );
  }

  /// [bool] values
  static CustomLayout<int, bool> boolean({
    String? property,
    Layout<int>? layout,
    int falseFlag = 0,
    int trueFlag = 1,
  }) {
    return CustomLayout<int, bool>(
      layout: layout ?? u8(),
      decoder: (data) {
        if (data != falseFlag && data != trueFlag) {
          throw BuError(
            DefaultErrorType.invalidArgument,
            "Failed to decode data as boolean.",
            details: {"value": data.toString(), "property": property},
          );
        }
        return data == falseFlag ? false : true;
      },
      encoder: (src) {
        return src ? trueFlag : falseFlag;
      },
      property: property,
    );
  }

  /// [bool] backed by a big-endian u32.
  static CustomLayout boolean32Be({String? property}) {
    return boolean(property: property, layout: u32be());
  }

  /// Boolean value backed by a 4-byte integer.
  static CustomLayout boolean32({String? property}) {
    return boolean(property: property, layout: u32());
  }

  /// [PaddingLayout] wrapping [layout].
  static PaddingLayout<T> padding<T>(
    BaseInteger<T> layout, {
    String? property,
  }) {
    return PaddingLayout(layout, property: property);
  }

  /// Rust vector values
  static CustomLayout rustVecU8({String? property}) {
    final length = padding(u32(property: "length"), property: "length");
    final layout = struct([
      length,
      padding(u32(), property: "length_padding"),
      blob(offset(length, -8), property: 'data'),
    ]);
    return CustomLayout(
      layout: layout,
      encoder: (data) => {"data": data},
      decoder: (data) => data["data"],
      property: property,
    );
  }

  /// Resolves the effective length-prefix layout for [vec]/[vecU8]: a clone
  /// of [lengthSizeLayout] renamed to `"length"`, or a default u32.
  static IntegerLayout _lengthLayoutFor(IntegerLayout? lengthSizeLayout) {
    if (lengthSizeLayout != null) {
      return lengthSizeLayout.clone(newProperty: "length");
    }
    return u32(property: "length");
  }

  /// vector bytes
  static CustomLayout vecU8({
    String? property,
    IntegerLayout? lengthSizeLayout,
  }) {
    final resolvedLength = _lengthLayoutFor(lengthSizeLayout);
    final length = padding(resolvedLength, property: "length");
    final layout = struct([
      length,
      blob(offset(length, -length.span), property: 'data'),
    ]);
    return CustomLayout(
      layout: layout,
      encoder: (data) => {"data": data},
      decoder: (data) => data["data"],
      property: property,
    );
  }

  /// XDR-encoded UTF-8 string.
  static Layout<String> xdrString({String? property}) {
    return CustomLayout<List<int>, String>(
      layout: xdrVecBytes(),
      decoder: (bytes) => StringUtils.decode(bytes),
      encoder: (src) => StringUtils.encode(src),
      property: property,
    );
  }

  /// XDR-encoded byte blob (4-byte-padded).
  static Layout<List<int>> xdrVecBytes({String? property}) {
    final length = padding(u32be(property: "length"), property: "length");
    final layout = struct([
      length,
      XDRBytesLayout(offset(length, -length.span), property: 'data'),
    ]);
    return CustomLayout<Map<String, dynamic>, List<int>>(
      layout: layout,
      encoder: (data) {
        return {"data": data};
      },
      decoder: (data) => data["data"],
      property: property,
    );
  }

  /// Rust enum with a big-endian u32 discriminant.
  static CustomLayout<Map<String, dynamic>, Map<String, dynamic>> enum32Be(
    List<Layout> variants, {
    String? property,
    bool useKeyAndValue = true,
  }) {
    return rustEnum(
      variants,
      discriminant: u32be(),
      property: property,
      useKeyAndValue: useKeyAndValue,
    );
  }

  /// Lazy enum with a big-endian u32 discriminant.
  static CustomLayout<Map<String, dynamic>, Map<String, dynamic>> lazyEnumU32Be(
    List<LazyVariantModel> variants, {
    required String? property,
    bool useKeyAndValue = true,
  }) {
    return lazyEnum(
      variants,
      discriminant: u32be(),
      property: property,
      useKeyAndValue: useKeyAndValue,
    );
  }

  /// Lazy enum with a big-endian s32 discriminant.
  static CustomLayout<Map<String, dynamic>, Map<String, dynamic>> lazyEnumS32Be(
    List<LazyVariantModel> variants, {
    required String? property,
    bool useKeyAndValue = true,
  }) {
    return lazyEnum(
      variants,
      discriminant: s32be(),
      property: property,
      useKeyAndValue: useKeyAndValue,
    );
  }

  /// Lazy enum (variant layouts resolved via [LazyUnion]).
  static CustomLayout<Map<String, dynamic>, Map<String, dynamic>> lazyEnum(
    List<LazyVariantModel> variants, {
    IntegerLayout? discriminant,
    String? property,
    bool useKeyAndValue = true,
  }) {
    final unionLayout = LazyUnion(
      discr: discriminant ?? u8(),
      variants: variants,
    );

    return CustomLayout<Map<String, dynamic>, Map<String, dynamic>>(
      layout: unionLayout,
      decoder: (value) {
        if (useKeyAndValue) {
          return {"key": value.keys.first, "value": value.values.first};
        }
        return value;
      },
      encoder: (src) {
        return src;
      },
      property: property,
    );
  }

  /// enum values
  static CustomLayout<Map<String, dynamic>, Map<String, dynamic>> rustEnum(
    List<Layout> variants, {
    Layout? discriminant,
    String? property,
    bool useKeyAndValue = true,
  }) {
    final unionLayout = Union((discriminant != null) ? discriminant : u8());
    variants.asMap().forEach(
      (index, variant) => unionLayout.addVariant(
        variant: index,
        layout: variant,
        property: variant.property,
      ),
    );
    return CustomLayout<Map<String, dynamic>, Map<String, dynamic>>(
      layout: unionLayout,
      decoder: (value) {
        if (useKeyAndValue) {
          return {"key": value.keys.first, "value": value.values.first};
        }
        return value;
      },
      encoder: (src) {
        return src;
      },
      property: property,
    );
  }

  /// Rust String values.
  static CustomLayout rustString({String? property}) {
    return CustomLayout(
      layout: rustVecU8(),
      decoder: (bytes) => StringUtils.decode(bytes as List<int>),
      encoder: (src) => StringUtils.encode(src as String),
      property: property,
    );
  }

  /// String values
  static CustomLayout string({String? property}) {
    return CustomLayout(
      layout: vecU8(),
      decoder: (bytes) => StringUtils.decode(bytes as List<int>),
      encoder: (src) => StringUtils.encode(src as String),
      property: property,
    );
  }

  /// Compact-length-prefixed UTF-8 string.
  static Layout<String> compactString({String? property}) {
    return CompactString(property: property);
  }

  /// XDR-encoded vector of [elementLayout] elements.
  static CustomLayout xdrVec(Layout elementLayout, {String? property}) {
    final length = padding(u32be(property: "length"), property: "length");
    final layout = struct([
      length,
      seq(elementLayout, offset(length, -length.span), property: 'values'),
    ]);
    return CustomLayout<Map<String, dynamic>, dynamic>(
      layout: layout,
      encoder: (data) => {"values": data},
      decoder: (data) => data["values"],
      property: property,
    );
  }

  /// vectors
  static CustomLayout vec(
    Layout elementLayout, {
    String? property,
    IntegerLayout? lengthSizeLayout,
  }) {
    final resolvedLength = _lengthLayoutFor(lengthSizeLayout);
    final length = padding(resolvedLength, property: "length");
    final layout = struct([
      length,
      seq(elementLayout, offset(length, -length.span), property: 'values'),
    ]);
    return CustomLayout<Map<String, dynamic>, dynamic>(
      layout: layout,
      encoder: (data) => {"values": data},
      decoder: (data) => data["values"],
      property: property,
    );
  }

  /// [OffsetLayout] pointing 8 bytes before a Rust vector's data.
  static OffsetLayout rustVecOffset({String? property}) {
    return offset(padding(u32()), -8, property: property);
  }

  /// factory for Rust vectors
  static CustomLayout rustVec(Layout elementLayout, {String? property}) {
    final length = padding(u32(property: "length"), property: "length");

    final paddingLayout = padding(u32(), property: "padding_length");
    final layout = struct([
      length,
      paddingLayout,
      seq(elementLayout, offset(length, -8), property: 'values'),
    ]);
    return CustomLayout<Map<String, dynamic>, dynamic>(
      layout: layout,
      encoder: (data) => {"values": data},
      decoder: (data) => data["values"],
      property: property,
    );
  }

  /// map values
  static CustomLayout map(
    Layout keyLayout,
    Layout valueLayout, {
    String? property,
  }) {
    final length = padding(u32(property: "length"), property: "length");
    final layout = struct([
      length,
      seq(
        MapEntryLayout(
          keyLayout: keyLayout,
          valueLayout: valueLayout,
          property: "",
        ),
        offset(length, -length.span),
        property: 'values',
      ),
    ]);
    return CustomLayout<Map<String, dynamic>, Map<dynamic, dynamic>>(
      layout: layout,
      decoder: (data) {
        final List<MapEntry<dynamic, dynamic>> values =
            (data['values'] as List).cast();
        return Map.fromEntries(values);
      },
      encoder: (values) => {'values': values.entries.toList()},
      property: property,
    );
  }

  /// Compact-length-prefixed map.
  static CustomLayout compactMap<K, V>(
    Layout keyLayout,
    Layout valueLayout, {
    String? property,
  }) {
    final layout = struct([
      seq(
        MapEntryLayout(
          keyLayout: keyLayout,
          valueLayout: valueLayout,
          property: "",
        ),
        compactOffset(),
        property: 'values',
      ),
    ]);
    return CustomLayout<Map<String, dynamic>, Map<K, V>>(
      layout: layout,
      decoder: (data) {
        final List<MapEntry<K, V>> values =
            (data['values'] as List)
                .cast<MapEntry>()
                .map(
                  (e) => MapEntry<K, V>(
                    JsonParser.valueAs<K>(e.key),
                    JsonParser.valueAs<V>(e.value),
                  ),
                )
                .toList();
        return Map.fromEntries(values);
      },
      encoder: (values) => {'values': values.entries.toList()},
      property: property,
    );
  }

  /// Fixed-[length] array of [elementLayout] elements.
  static CustomLayout array(
    Layout elementLayout,
    int length, {
    String? property,
  }) {
    final layout = struct([
      seq(elementLayout, ConstantLayout<int>(length), property: 'values'),
    ]);
    return CustomLayout<Map<String, dynamic>, dynamic>(
      layout: layout,
      decoder: (data) => data['values'],
      encoder: (values) => {'values': values},
      property: property,
    );
  }

  /// Fixed-[length] byte array, optionally decoded as a hex string.
  static CustomLayout byteArray(
    int length, {
    bool resultAsHex = false,
    String? property,
  }) {
    final layout = struct([
      seq(u8(), ConstantLayout<int>(length), property: 'values'),
    ]);
    return CustomLayout<Map<String, dynamic>, dynamic>(
      layout: layout,
      decoder: (data) {
        final bytes = (data['values'] as List).cast<int>();
        if (resultAsHex) return BytesUtils.toHexString(bytes);
        return bytes;
      },
      encoder: (values) {
        if (values is String) {
          return {'values': BytesUtils.fromHexString(values)};
        }
        return {'values': values};
      },
      property: property,
    );
  }

  /// Array of [elementLayout] elements that consumes the rest of the buffer.
  static CustomLayout greedyArray(Layout elementLayout, {String? property}) {
    final layout = struct([
      seq(
        elementLayout,
        greedy(elementSpan: elementLayout.span),
        property: 'values',
      ),
    ]);
    return CustomLayout<Map<String, dynamic>, dynamic>(
      layout: layout,
      decoder: (data) => data['values'],
      encoder: (values) => {'values': values},
      property: property,
    );
  }

  /// tuple values
  static TupleLayout tuple(List<Layout> layouts, {String? property}) {
    return TupleLayout(layouts, property: property);
  }

  /// no data values
  static NoneLayout<T> none<T>({String? property}) {
    return NoneLayout<T>(property: property);
  }

  /// wrap layouts for property handling
  static Layout wrap(Layout layout, {String? property}) {
    return CustomLayout(
      layout: layout,
      decoder: (value) => value,
      encoder: (src) => src,
      property: property,
    );
  }

  /// Compact-length-prefixed [BigInt], validated against [layout]'s width.
  static CompactBigIntLayout compactBigint(
    BigIntLayout layout, {
    String? property,
  }) {
    return CompactBigIntLayout(layout, property: property);
  }

  /// Compact-length-prefixed unsigned 64-bit [BigInt].
  static CompactBigIntLayout compactBigintU64({String? property}) {
    return CompactBigIntLayout(u64(), property: property);
  }

  /// Compact-length-prefixed unsigned 128-bit [BigInt].
  static CompactBigIntLayout compactBigintU128({String? property}) {
    return CompactBigIntLayout(u128(), property: property);
  }

  /// Compact-length-prefixed integer, validated against [layout]'s width.
  static CompactIntLayout compactInt(IntegerLayout layout, {String? property}) {
    return CompactIntLayout(layout, property: property);
  }

  /// Compact-length-prefixed unsigned 48-bit integer.
  static CompactIntLayout compactIntU48({String? property}) {
    return CompactIntLayout(u48(), property: property);
  }

  /// Compact-length-prefixed unsigned 32-bit integer.
  static CompactIntLayout compactIntU32({String? property}) {
    return CompactIntLayout(u32(), property: property);
  }

  /// Wraps [elementLayout] as a repeated, single-field struct decoded/encoded
  /// through the `values` property — shared by [compactVec], [varintVector],
  /// [bcsVector] and [dynamicVector], which only differ in the [count] layout.
  static CustomLayout<Map<String, dynamic>, List<T>> _countedVector<T>(
    Layout<T> elementLayout,
    Layout<int>? count, {
    String? property,
  }) {
    final valuesField =
        count == null
            ? SequenceLayout(elementLayout: elementLayout, property: 'values')
            : seq(elementLayout, count, property: 'values');
    final layout = struct([valuesField]);
    return CustomLayout<Map<String, dynamic>, List<T>>(
      layout: layout,
      encoder: (data) => {"values": data},
      decoder: (data) => (data["values"] as List).cast<T>(),
      property: property,
    );
  }

  /// Compact-length-prefixed vector of [elementLayout] elements.
  static CustomLayout<Map<String, dynamic>, List<T>> compactVec<T>(
    Layout<T> elementLayout, {
    String? property,
  }) => _countedVector(elementLayout, compactOffset(), property: property);

  /// Compact-length-prefixed byte blob, optionally decoded as a hex string.
  static Layout compactBytes({bool resultAsHex = false, String? property}) {
    final layout = struct([seq(u8(), compactOffset(), property: 'values')]);
    return CustomLayout<Map<String, dynamic>, dynamic>(
      layout: layout,
      encoder: (data) {
        if (data is String) return {"values": BytesUtils.fromHexString(data)};
        return {"values": data};
      },
      decoder: (data) {
        final bytes = (data["values"] as List).cast<int>();
        if (resultAsHex) return BytesUtils.toHexString(bytes);
        return bytes;
      },
      property: property,
    );
  }

  /// Alias of [compactVec].
  static CustomLayout compactArray(Layout elementLayout, {String? property}) {
    return compactVec(elementLayout, property: property);
  }

  /// Compact-length-prefixed raw byte blob.
  static CompactBytes bytes({String? property}) {
    return CompactBytes(property: property);
  }

  /// [CompactOffsetLayout] backed by a compact unsigned 32-bit length.
  static CompactOffsetLayout compactOffset({String? property}) =>
      CompactOffsetLayout(compactIntU32(), property: property);

  /// Empty [StructLayout] (no fields).
  static StructLayout noArgs({String? property}) {
    return struct([], property: property);
  }

  /// Compact-length-prefixed bit sequence.
  static BitSequenceLayout bitSequenceLayout({String? property}) {
    return BitSequenceLayout(property: property);
  }

  /// LEB128-encoded integer, validated against [validator]'s width.
  static Layout<int> lebInteger(IntegerLayout validator, {String? property}) {
    return LEBIntegerLayout(validator, property: property);
  }

  /// LEB128-encoded unsigned 32-bit integer.
  static Layout<int> lebU32({String? property}) {
    return LEBIntegerLayout(u32(), property: property);
  }

  /// LEB128-encoded unsigned 48-bit integer.
  static Layout<int> lebU48({String? property}) {
    return LEBIntegerLayout(u48(), property: property);
  }

  /// LEB128-encoded [BigInt], validated against [validator]'s width.
  static Layout<BigInt> lebBigInteger(
    BigIntLayout validator, {
    String? property,
  }) {
    return LEBBigIntegerLayout(validator, property: property);
  }

  /// LEB128-encoded unsigned 64-bit [BigInt].
  static Layout<BigInt> lebU64({String? property}) {
    return LEBBigIntegerLayout(u64(), property: property);
  }

  /// LEB128-encoded signed 128-bit [BigInt].
  static Layout<BigInt> lebI128({String? property}) {
    return LEBBigIntegerLayout(i128(), property: property);
  }

  /// LEB128-encoded signed 256-bit [BigInt].
  static Layout<BigInt> lebI256({String? property}) {
    return LEBBigIntegerLayout(i256(), property: property);
  }

  /// Serializes and deserializes raw bytes with a length prefix encoded as LEB128.
  ///
  /// The structure is: [...LEB, data bytes...]
  /// [property] is an optional key to map the serialized data.
  static CustomLayout<Map<String, dynamic>, List<int>> bcsBytes({
    String? property,
  }) {
    return bcsVector(LayoutConst.u8(), property: property);
  }

  /// Serializes and deserializes UTF-8 encoded strings.
  static Layout<String> bcsString({String? property}) {
    return CustomLayout<List<int>, String>(
      layout: bcsBytes(),
      decoder: (bytes) {
        return StringUtils.decode(bytes);
      },
      encoder: (src) {
        return StringUtils.encode(src);
      },
      property: property,
    );
  }

  /// Serializes and deserializes a vector (list) of elements using the provided [elementLayout].
  static CustomLayout<Map<String, dynamic>, List<T>> bcsVector<T>(
    Layout<T> elementLayout, {
    String? property,
  }) => _countedVector(elementLayout, bcsOffset(), property: property);

  /// BCS-encoded map.
  static CustomLayout bcsMap<K, V>(
    Layout<K> keyLayout,
    Layout<V> valueLayout, {
    String? property,
  }) {
    final layout = struct([
      seq(
        MapEntryLayout(
          keyLayout: keyLayout,
          valueLayout: valueLayout,
          property: "",
        ),
        bcsOffset(),
        property: 'values',
      ),
    ]);
    return CustomLayout<Map<String, dynamic>, Map<K, V>>(
      layout: layout,
      decoder: (data) {
        final List<MapEntry<K, V>> values =
            (data['values'] as List)
                .cast<MapEntry>()
                .map(
                  (e) => MapEntry<K, V>(
                    JsonParser.valueAs<K>(e.key),
                    JsonParser.valueAs<V>(e.value),
                  ),
                )
                .toList();
        return Map.fromEntries(values);
      },
      encoder: (values) => {'values': values.entries.toList()},
      property: property,
    );
  }

  /// Varint-encoded unsigned 32-bit integer, big-endian.
  static VarintIntLayout varintU32Be({String? property}) {
    return VarintIntLayout(u32be(), property: property);
  }

  /// Varint-encoded unsigned 32-bit integer, little-endian.
  static VarintIntLayout varintU32Le({String? property}) {
    return VarintIntLayout(u32(), property: property);
  }

  /// Creates an offset layout using LEB128 encoding (used for compact integer representation).
  static LEB128U32OffsetLayout bcsOffset({String? property}) =>
      LEB128U32OffsetLayout(property: property);

  /// [VarintOffsetLayout] wrapping a varint-encoded [layout].
  static VarintOffsetLayout varintOffset(
    VarintIntLayout layout, {
    String? property,
  }) => VarintOffsetLayout(layout, property: property);

  /// Handles lazy serialization and deserialization of enums (variant types).
  static CustomLayout<Map<String, dynamic>, Map<String, dynamic>> bcsLazyEnum(
    List<LazyVariantModel> variants, {
    String? property,
  }) {
    final unionLayout = LazyUnion.offset(
      discr: bcsOffset(),
      variants: variants,
    );
    return CustomLayout<Map<String, dynamic>, Map<String, dynamic>>(
      layout: unionLayout,
      decoder: (value) {
        return {"key": value.keys.first, "value": value.values.first};
      },
      encoder: (src) {
        return src;
      },
      property: property,
    );
  }

  /// Lazy enum keyed by a varint-encoded discriminator.
  static CustomLayout<Map<String, dynamic>, Map<String, dynamic>>
  varintLazyEnum(
    List<LazyVariantModel> variants, {
    VarintIntLayout? discr,
    String? property,
  }) {
    final unionLayout = LazyUnion.offset(
      discr: varintOffset(discr ?? varintU32Be()),
      variants: variants,
    );
    return CustomLayout<Map<String, dynamic>, Map<String, dynamic>>(
      layout: unionLayout,
      decoder: (value) {
        return {"key": value.keys.first, "value": value.values.first};
      },
      encoder: (src) {
        return src;
      },
      property: property,
    );
  }

  /// Vector of [elementLayout] elements, length-prefixed by a varint.
  static CustomLayout<Map<String, dynamic>, List<T>> varintVector<T>(
    Layout<T> elementLayout, {
    String? property,
  }) => _countedVector(
    elementLayout,
    varintOffset(varintU32Be()),
    property: property,
  );

  /// Vector of [elementLayout] elements with no length prefix, decoded until
  /// the buffer is exhausted.
  static CustomLayout<Map<String, dynamic>, List<T>> dynamicVector<T>(
    Layout<T> elementLayout, {
    String? property,
  }) => _countedVector(elementLayout, null, property: property);
}
