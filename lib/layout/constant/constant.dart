import 'dart:typed_data';
import 'package:blockchain_utils/layout/core/core.dart';
import 'package:blockchain_utils/layout/exception/exception.dart';
import 'package:blockchain_utils/utils/utils.dart';

class LayoutConst {
  /// [GreedyCount].
  static GreedyCount greedy({int elementSpan = 1, String? property}) =>
      GreedyCount(elementSpan, property);

  /// [OffsetLayout].
  static OffsetLayout offset(PaddingLayout<int> layout, int offset,
          {String? property}) =>
      OffsetLayout(layout, offset: offset, property: property);

  /// [IntegerLayout] (unsigned int layouts) spanning one byte.
  static IntegerLayout u8({String? property}) =>
      IntegerLayout(1, property: property);

  /// [IntegerLayout] (signed int layouts) spanning one byte.
  static IntegerLayout i8({String? property}) =>
      IntegerLayout(1, property: property, sign: true);

  /// [IntegerLayout] (little-endian unsigned int layouts) spanning two bytes.
  static IntegerLayout u16({String? property}) =>
      IntegerLayout(2, property: property);

  /// [IntegerLayout] (little-endian unsigned int layouts) spanning two bytes.
  static IntegerLayout i16({String? property}) =>
      IntegerLayout(2, property: property, sign: true);

  /// [IntegerLayout] (little-endian unsigned int layouts) spanning three bytes.
  static IntegerLayout u24({String? property}) =>
      IntegerLayout(3, property: property);

  /// [IntegerLayout] (little-endian unsigned int layouts) spanning three bytes.
  static IntegerLayout i24({String? property}) =>
      IntegerLayout(3, property: property, sign: true);

  /// [IntegerLayout] (little-endian unsigned int layouts) spanning four bytes.
  static IntegerLayout u32({String? property}) =>
      IntegerLayout(4, property: property);

  /// [IntegerLayout] (little-endian unsigned int layouts) spanning four bytes.
  static IntegerLayout i32({String? property}) =>
      IntegerLayout(4, property: property, sign: true);

  /// [IntegerLayout] (little-endian unsigned int layouts) spanning five bytes.
  static IntegerLayout u40({String? property}) =>
      IntegerLayout(5, property: property);

  /// [IntegerLayout] (little-endian unsigned int layouts) spanning five bytes.
  static IntegerLayout i40({String? property}) =>
      IntegerLayout(5, property: property, sign: true);

  /// [IntegerLayout] (little-endian unsigned int layouts) spanning six bytes.
  static IntegerLayout u48({String? property}) =>
      IntegerLayout(6, property: property);

  /// [IntegerLayout] (little-endian unsigned int layouts) spanning six bytes.
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
  static StructLayout struct(List<Layout> fields,
          {String? property, bool decodePrefixes = false}) =>
      StructLayout(fields, property: property, decodePrefixes: decodePrefixes);

  // /// [StructLayout] values.
  static LazyStructLayout lazyStruct(List<BaseLazyLayout> fields,
          {String? property, bool decodePrefixes = false}) =>
      LazyStructLayout(fields,
          property: property, decodePrefixes: decodePrefixes);

  /// [SequenceLayout] values.
  static SequenceLayout seq<T>(Layout elementLayout, Layout count,
          {String? property}) =>
      SequenceLayout<T>(
          elementLayout: elementLayout, count: count, property: property);

  /// [Union] values.
  static Union union(dynamic discr,
          {Layout? defaultLayout, String? property}) =>
      Union(discr, defaultLayout: defaultLayout, property: property);

  /// [UnionLayoutDiscriminatorLayout] values.
  static UnionLayoutDiscriminatorLayout unionLayoutDiscriminator(
          ExternalLayout layout,
          {String? property}) =>
      UnionLayoutDiscriminatorLayout(layout, property: property);

  /// [RawBytesLayout] values.
  static RawBytesLayout blob(dynamic length, {String? property}) =>
      RawBytesLayout(length, property: property);

  static RawBytesLayout fixedBlob32({String? property}) =>
      RawBytesLayout(32, property: property);
  static RawBytesLayout fixedBlobN(int len, {String? property}) =>
      RawBytesLayout(len, property: property);

  static ConstantLayout constant(dynamic value, {String? property}) =>
      ConstantLayout(value, property: property);
  static String nameWithProperty(String name, Layout? lo) {
    if (lo?.property != null) {
      return '$name[${lo!.property!}]';
    }
    return name;
  }

  static COptionLayout cOptionalPublicKey(Layout layout,
      {String? property, Layout? discriminator}) {
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

  /// [BigIntLayout] (little-endian signed int layouts) interpreted as Numbers.
  static BigIntLayout i128({String? property}) =>
      BigIntLayout(16, sign: true, property: property);

  static BigIntLayout bigintLayout(int length,
          {String? property, bool sign = false}) =>
      BigIntLayout(length, sign: sign, property: property);

  static IntegerLayout intLayout(int length,
          {String? property, bool sign = false}) =>
      IntegerLayout(length, sign: sign, property: property);

  /// optional [BigIntLayout] (little-endian unsigned int layouts) interpreted as Numbers.
  static OptionalLayout optionU64({String? property}) {
    return OptionalLayout<BigInt>(u64(), property: property);
  }

  static OptionalLayout optionalU32Be(Layout layout,
      {String? property, bool keepSize = false}) {
    return optional(layout,
        keepSize: keepSize, discriminator: u32be(), property: property);
  }

  /// [OptionalLayout]
  static OptionalLayout optional(Layout layout,
      {String? property, bool keepSize = false, BaseIntiger? discriminator}) {
    return OptionalLayout(layout,
        property: property,
        discriminator: discriminator,
        keepLayoutSize: keepSize);
  }

  /// [bool] values
  static CustomLayout boolean({String? property, Layout<int>? layout}) {
    return CustomLayout<int, bool>(
        layout: layout ?? u8(),
        decoder: (data) {
          if (data != 0 && data != 1) {
            throw LayoutException("Invalid boolean integer value.",
                details: {"value": data, "property": property});
          }
          return data == 0 ? false : true;
        },
        encoder: (src) {
          return src ? 1 : 0;
        },
        property: property);
  }

  static CustomLayout boolean32Be({String? property}) {
    return boolean(property: property, layout: u32be());
  }

  /// [bool] 4 bytes values
  static CustomLayout boolean32({String? property}) {
    return boolean(property: property, layout: u32());
  }

  static PaddingLayout<T> padding<T>(BaseIntiger<T> layout, {String? propery}) {
    return PaddingLayout(layout, property: propery);
  }

  /// Rust vector values
  static CustomLayout rustVecU8({String? property}) {
    final length = padding(u32(property: "length"), propery: "length");
    final layout = struct([
      length,
      padding(u32(), propery: "length_padding"),
      blob(offset(length, -8), property: 'data'),
    ]);
    return CustomLayout(
      layout: layout,
      encoder: (data) => {"data": data},
      decoder: (data) => data["data"],
      property: property,
    );
  }

  /// vector bytes
  static CustomLayout vecU8(
      {String? property, IntegerLayout? lengthSizeLayout}) {
    lengthSizeLayout ??= (lengthSizeLayout?.clone(newProperty: "length") ??
        u32(property: "length"));
    final length = padding(lengthSizeLayout, propery: "length");
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

  static Layout<String> xdrString({String? property}) {
    return CustomLayout<List<int>, String>(
        layout: xdrVecBytes(),
        decoder: (bytes) => StringUtils.decode(bytes),
        encoder: (src) => StringUtils.encode(src),
        property: property);
  }

  static Layout<List<int>> xdrVecBytes({String? property}) {
    final length = padding(u32be(property: "length"), propery: "length");
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
        property: property);
  }

  static CustomLayout<Map<String, dynamic>, Map<String, dynamic>> enum32Be(
    List<Layout> variants, {
    String? property,
    bool useKeyAndValue = true,
  }) {
    return rustEnum(variants,
        discriminant: u32be(),
        property: property,
        useKeyAndValue: useKeyAndValue);
  }

  static CustomLayout<Map<String, dynamic>, Map<String, dynamic>> lazyEnumU32Be(
    List<LazyVariantModel> variants, {
    required String? property,
    bool useKeyAndValue = true,
  }) {
    return lazyEnum(variants,
        discriminant: u32be(),
        property: property,
        useKeyAndValue: useKeyAndValue);
  }

  static CustomLayout<Map<String, dynamic>, Map<String, dynamic>> lazyEnumS32Be(
    List<LazyVariantModel> variants, {
    required String? property,
    bool useKeyAndValue = true,
  }) {
    return lazyEnum(variants,
        discriminant: s32be(),
        property: property,
        useKeyAndValue: useKeyAndValue);
  }

  static CustomLayout<Map<String, dynamic>, Map<String, dynamic>> lazyEnum(
    List<LazyVariantModel> variants, {
    IntegerLayout? discriminant,
    String? property,
    bool useKeyAndValue = true,
  }) {
    final unionLayout = LazyUnion(discriminant ?? u8());
    variants
        .asMap()
        .forEach((index, variant) => unionLayout.addVariant(variant));
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
        property: property);
  }

  /// enum values
  static CustomLayout<Map<String, dynamic>, Map<String, dynamic>> rustEnum(
    List<Layout> variants, {
    Layout? discriminant,
    String? property,
    bool useKeyAndValue = true,
  }) {
    final unionLayout = Union((discriminant != null) ? discriminant : u8());
    variants.asMap().forEach((index, variant) => unionLayout.addVariant(
        variant: index, layout: variant, property: variant.property));
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
        property: property);
  }

  /// Rust String values.
  static rustString({String? property}) {
    return CustomLayout(
        layout: rustVecU8(),
        decoder: (bytes) => StringUtils.decode(bytes as List<int>),
        encoder: (src) => StringUtils.encode(src as String),
        property: property);
  }

  /// String values
  static CustomLayout string({String? property}) {
    return CustomLayout(
        layout: vecU8(),
        decoder: (bytes) => StringUtils.decode(bytes as List<int>),
        encoder: (src) => StringUtils.encode(src as String),
        property: property);
  }

  static Layout<String> compactString({String? property}) {
    return CustomLayout<List<int>, String>(
        layout: bytes(),
        decoder: (bytes) => StringUtils.decode(bytes),
        encoder: (src) => StringUtils.encode(src),
        property: property);
  }

  static CustomLayout xdrVec(Layout elementLayout, {String? property}) {
    final length = padding(u32be(property: "length"), propery: "length");
    final layout = struct([
      length,
      seq(elementLayout, offset(length, -length.span), property: 'values'),
    ]);
    return CustomLayout<Map<String, dynamic>, dynamic>(
        layout: layout,
        encoder: (data) => {"values": data},
        decoder: (data) => data["values"],
        property: property);
  }

  /// vectors
  static CustomLayout vec(Layout elementLayout,
      {String? property, IntegerLayout? lengthSizeLayout}) {
    lengthSizeLayout ??= (lengthSizeLayout?.clone(newProperty: "length") ??
        u32(property: "length"));
    final length = padding(lengthSizeLayout, propery: "length");
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

  static OffsetLayout rustVecOffset({String? property}) {
    return offset(padding(u32()), -8, property: property);
  }

  /// factory for Rust vectors
  static CustomLayout rustVec(Layout elementLayout, {String? property}) {
    final length = padding(u32(property: "length"), propery: "length");

    final paddingLayout = padding(u32(), propery: "padding_length");
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
  static CustomLayout map(Layout keyLayout, Layout valueLayout,
      {String? property}) {
    final length = padding(u32(property: "length"), propery: "length");
    final layout = struct([
      length,
      seq(
        MapEntryLayout(
            keyLayout: keyLayout, valueLayout: valueLayout, property: ""),
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

  static CustomLayout compactMap<K, V>(Layout keyLayout, Layout valueLayout,
      {String? property}) {
    final layout = struct([
      seq(
          MapEntryLayout(
              keyLayout: keyLayout, valueLayout: valueLayout, property: ""),
          compactOffset(),
          property: 'values')
    ]);
    return CustomLayout<Map<String, dynamic>, Map<K, V>>(
      layout: layout,
      decoder: (data) {
        final List<MapEntry<K, V>> values = (data['values'] as List).cast();
        return Map.fromEntries(values);
      },
      encoder: (values) => {'values': values.entries.toList()},
      property: property,
    );
  }

  static CustomLayout array(Layout elementLayout, int length,
      {String? property}) {
    final layout = struct([
      seq(elementLayout, ConstantLayout(length), property: 'values'),
    ]);
    return CustomLayout<Map<String, dynamic>, dynamic>(
      layout: layout,
      decoder: (data) => data['values'],
      encoder: (values) => {'values': values},
      property: property,
    );
  }

  static CustomLayout greedyArray(Layout elementLayout, {String? property}) {
    final layout = struct([
      seq(elementLayout, greedy(elementSpan: elementLayout.span),
          property: 'values'),
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

  static TupleCompactLayout compactTuple(List<Layout> layouts,
      {String? property}) {
    return TupleCompactLayout(layouts, property: property);
  }

  /// no data values
  static NoneLayout none({String? property}) {
    return NoneLayout(property: property);
  }

  /// wrap layouts for property handling
  static Layout wrap(Layout layout, {String? property}) {
    return CustomLayout(
        layout: layout,
        decoder: (value) => value,
        encoder: (src) => src,
        property: property);
  }

  ///

  static CompactBigIntLayout compactBigint(BigIntLayout layout,
      {String? property}) {
    return CompactBigIntLayout(layout, property: property);
  }

  static CompactBigIntLayout compactBigintU64({String? property}) {
    return CompactBigIntLayout(u64(), property: property);
  }

  static CompactBigIntLayout compactBigintU128({String? property}) {
    return CompactBigIntLayout(u128(), property: property);
  }

  static CompactIntLayout compactInt(IntegerLayout layout, {String? property}) {
    return CompactIntLayout(layout, property: property);
  }

  static CompactIntLayout compactIntU48({String? property}) {
    return CompactIntLayout(u48(), property: property);
  }

  static CompactIntLayout compactIntU32({String? property}) {
    return CompactIntLayout(u32(), property: property);
  }

  static CustomLayout<Map<String, dynamic>, List<T>> compactVec<T>(
      Layout<T> elementLayout,
      {String? property}) {
    final layout =
        struct([seq(elementLayout, compactOffset(), property: 'values')]);
    return CustomLayout<Map<String, dynamic>, List<T>>(
      layout: layout,
      encoder: (data) => {"values": data},
      decoder: (data) => (data["values"] as List).cast<T>(),
      property: property,
    );
  }

  static CustomLayout compactArray(Layout elementLayout, {String? property}) {
    return compactVec(elementLayout, property: property);
  }

  static CompactBytes bytes({String? property}) {
    return CompactBytes(property: property);
  }

  static CompactOffsetLayout compactOffset({String? property}) =>
      CompactOffsetLayout(property: property);

  static StructLayout noArgs({String? property}) {
    return struct([], property: property);
  }

  static BitSequenceLayout bitSequenceLayout({String? property}) {
    return BitSequenceLayout(property: property);
  }

  static CompactLayout compact(Layout layout, {String? property}) =>
      CompactLayout(layout, property: property);
}
