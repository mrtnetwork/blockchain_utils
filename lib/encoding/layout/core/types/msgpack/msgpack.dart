import 'dart:typed_data';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/encoding/layout/buffer/buffer.dart';
import 'package:blockchain_utils/encoding/layout/core/core/core.dart';
import 'package:blockchain_utils/encoding/layout/core/types/numeric.dart';
import 'package:blockchain_utils/utils/binary/src/binary_operation.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';
import 'package:blockchain_utils/utils/numbers/utils/bigint_utils.dart';
import 'package:blockchain_utils/utils/string/string.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Gate deciding whether a value should be emitted at all when encoding.
sealed class MsgPackEncodeOption<T> {
  bool encode(T source, String? property);
}

/// Default encode gate: always emits the value.
class MsgPackEncodeOptionDefault<T> implements MsgPackEncodeOption<T> {
  const MsgPackEncodeOptionDefault();
  @override
  bool encode(T source, String? property) => true;
}

/// MessagePack format tag bytes and shared length-header helpers.
class MsgPackConst {
  static const int int64Flag = 0xd3;
  static const int int32Flag = 0xd2;
  static const int int16Flag = 0xd1;
  static const int int8Flag = 0xd0;
  static const int positiveFixint = 0x7f;
  static const int negativeFixint = 0xe0;

  static const int uint8Flag = 0xcc;
  static const int uint16Flag = 0xcd;
  static const int uint32Flag = 0xce;
  static const int uint64Flag = 0xcf;

  /// Reads a MessagePack length header at [offset]: an inline fixed-form
  /// tag in `[fixLow, fixHigh]` masked by [fixMask] when present, otherwise
  /// the [flag8]/[flag16]/[flag32] sized forms. Returns `(length, headerSize)`.
  static (int, int) readLengthHeader(
    LayoutByteReader bytes,
    int offset, {
    int? fixLow,
    int? fixHigh,
    int? fixMask,
    int? flag8,
    required int flag16,
    required int flag32,
    required String what,
    String? property,
  }) {
    final fb = bytes.at(offset);
    if (fixLow != null && fb >= fixLow && fb <= fixHigh!) {
      return (fb & fixMask!, 1);
    }
    if (flag8 != null && fb == flag8) {
      return (bytes.getU8(offset + 1), 2);
    }
    if (fb == flag16) {
      return (bytes.getU16Be(offset + 1), 3);
    }
    if (fb == flag32) {
      return (bytes.getU32Be(offset + 1), 5);
    }
    throw BuError(
      DefaultErrorType.invalidArgument,
      'Expected MessagePack $what',
      details: {'property': property, 'byte': fb.toString()},
    );
  }

  /// Writes a MessagePack length header for [n] directly to [writer] at
  /// [offset]: an inline fixed-form tag ([fixPrefix] OR'd with [n]) when it
  /// fits [fixBits] bits, otherwise the smallest of [flag8]/[flag16]/[flag32]
  /// followed by a big-endian length. Returns the header size in bytes.
  static int writeLengthHeader(
    LayoutByteWriter writer,
    int offset,
    int n, {
    int? fixBits,
    int? fixPrefix,
    int? flag8,
    required int flag16,
    required int flag32,
  }) {
    if (fixBits != null && n <= (1 << fixBits) - 1) {
      writer.set(offset, fixPrefix! | n);
      return 1;
    }
    if (flag8 != null && n <= BinaryOps.mask8) {
      writer.set(offset, flag8);
      writer.set(offset + 1, n);
      return 2;
    }
    if (n <= BinaryOps.mask16) {
      writer.set(offset, flag16);
      writer.setU16Be(offset + 1, n);
      return 3;
    }
    writer.set(offset, flag32);
    writer.setU32Be(offset + 1, n);
    return 5;
  }
}

/// MessagePack `nil`.
class MsgPackNilLayout extends Layout<Null> {
  final MsgPackEncodeOption<Null> encodeOption;
  const MsgPackNilLayout({
    super.property,
    this.encodeOption = const MsgPackEncodeOptionDefault<Null>(),
  }) : super(1);

  @override
  LayoutDecodeResult<Null> decode(LayoutByteReader bytes, {int offset = 0}) {
    if (bytes.at(offset) != 0xc0) {
      throw BuError(
        DefaultErrorType.invalidArgument,
        'Expected MessagePack nil (0xc0)',
        details: {'property': property, 'byte': bytes.at(offset).toString()},
      );
    }
    return const LayoutDecodeResult(consumed: 1, value: null);
  }

  @override
  int encode(Null source, LayoutByteWriter writer, {int offset = 0}) {
    if (!encodeOption.encode(source, property)) return 0;
    writer.set(offset, 0xc0);
    return 1;
  }

  @override
  MsgPackNilLayout clone({String? newProperty}) =>
      MsgPackNilLayout(property: newProperty, encodeOption: encodeOption);
}

/// MessagePack `bool`.
class MsgPackBoolLayout extends Layout<bool> {
  final MsgPackEncodeOption<bool> encodeOption;
  const MsgPackBoolLayout({
    super.property,
    this.encodeOption = const MsgPackEncodeOptionDefault<bool>(),
  }) : super(-1);

  @override
  LayoutDecodeResult<bool> decode(LayoutByteReader bytes, {int offset = 0}) {
    final b = bytes.at(offset);
    if (b == 0xc2) return const LayoutDecodeResult(consumed: 1, value: false);
    if (b == 0xc3) return const LayoutDecodeResult(consumed: 1, value: true);
    throw BuError(
      DefaultErrorType.invalidArgument,
      'Expected MessagePack bool',
      details: {'property': property, 'byte': b.toString()},
    );
  }

  @override
  int encode(bool source, LayoutByteWriter writer, {int offset = 0}) {
    if (!encodeOption.encode(source, property)) {
      return 0;
    }
    writer.set(offset, source ? 0xc3 : 0xc2);
    return 1;
  }

  @override
  MsgPackBoolLayout clone({String? newProperty}) =>
      MsgPackBoolLayout(property: newProperty, encodeOption: encodeOption);
}

/// MessagePack integer, decoded/encoded across the fixint/uint8-64/int8-64 forms.
class MsgPackIntLayout extends Layout<int> {
  final MsgPackEncodeOption<int> encodeOption;
  final IntegerLayout? validator;
  const MsgPackIntLayout({
    super.property,
    this.validator,
    this.encodeOption = const MsgPackEncodeOptionDefault<int>(),
  }) : super(-1);

  LayoutDecodeResult<int> _decode(LayoutByteReader bytes, {int offset = 0}) {
    final fb = bytes.at(offset);
    if (fb <= MsgPackConst.positiveFixint) {
      return LayoutDecodeResult(consumed: 1, value: fb);
    }
    if (fb >= MsgPackConst.negativeFixint) {
      return LayoutDecodeResult(consumed: 1, value: fb - 256);
    }
    switch (fb) {
      case MsgPackConst.uint8Flag:
        return LayoutDecodeResult(consumed: 2, value: bytes.getU8(offset + 1));
      case MsgPackConst.uint16Flag:
        return LayoutDecodeResult(
          consumed: 3,
          value: bytes.getU16Be(offset + 1),
        );
      case MsgPackConst.uint32Flag:
        return LayoutDecodeResult(
          consumed: 5,
          value: bytes.getU32Be(offset + 1),
        );
      case MsgPackConst.uint64Flag:
        final v = bytes.getU64Be(offset + 1);
        if (v.isSafeInt()) {
          return LayoutDecodeResult(consumed: 9, value: v.toInt());
        }
        throw BuError(
          DefaultErrorType.invalidArgument,
          'Expected safe dart integer',
          details: {'property': property, 'byte': fb.toString()},
        );
      case MsgPackConst.int8Flag:
        final u = bytes.getU8(offset + 1);
        return LayoutDecodeResult(
          consumed: 2,
          value: u > MsgPackConst.positiveFixint ? u - 0x100 : u,
        );
      case MsgPackConst.int16Flag:
        final u = bytes.getU16Be(offset + 1);
        return LayoutDecodeResult(
          consumed: 3,
          value: u > 0x7fff ? u - 0x10000 : u,
        );
      case MsgPackConst.int32Flag:
        final u = bytes.getU32Be(offset + 1);
        return LayoutDecodeResult(
          consumed: 5,
          value: u > 0x7fffffff ? u - 0x100000000 : u,
        );
      case MsgPackConst.int64Flag:
        final v = bytes.getU64Be(offset + 1);
        final signed = v > BinaryOps.maxInt64 ? v - (BigInt.one << 64) : v;
        if (signed.isSafeInt()) {
          return LayoutDecodeResult(consumed: 9, value: signed.toInt());
        }
        throw BuError(
          DefaultErrorType.invalidArgument,
          'Expected safe dart integer',
          details: {'property': property, 'byte': fb.toString()},
        );
      default:
        throw BuError(
          DefaultErrorType.invalidArgument,
          'Expected MessagePack integer',
          details: {'property': property, 'byte': fb.toString()},
        );
    }
  }

  @override
  LayoutDecodeResult<int> decode(LayoutByteReader bytes, {int offset = 0}) {
    final decode = _decode(bytes, offset: offset);
    validator?.validate(decode.value);
    return decode;
  }

  @override
  int encode(int source, LayoutByteWriter writer, {int offset = 0}) {
    if (!encodeOption.encode(source, property)) return 0;
    validator?.validate(source);
    return _encodeInt(source, writer, offset);
  }

  /// Writes [v] in the smallest MessagePack integer form and returns its size.
  static int _encodeInt(int v, LayoutByteWriter writer, int offset) {
    if (v >= 0) {
      if (v <= MsgPackConst.positiveFixint) {
        writer.set(offset, v);
        return 1;
      }
      if (v <= BinaryOps.mask8) {
        writer.set(offset, MsgPackConst.uint8Flag);
        writer.set(offset + 1, v);
        return 2;
      }
      if (v <= BinaryOps.mask16) {
        writer.set(offset, MsgPackConst.uint16Flag);
        writer.setU16Be(offset + 1, v);
        return 3;
      }
      if (v <= BinaryOps.mask32) {
        writer.set(offset, MsgPackConst.uint32Flag);
        writer.setU32Be(offset + 1, v);
        return 5;
      }
      writer.set(offset, MsgPackConst.uint64Flag);
      writer.setU64Be(offset + 1, BigInt.from(v));
      return 9;
    }
    if (v >= -32) {
      writer.set(offset, v & BinaryOps.mask8);
      return 1;
    }
    if (v >= -128) {
      writer.set(offset, MsgPackConst.int8Flag);
      writer.set(offset + 1, v & BinaryOps.mask8);
      return 2;
    }
    if (v >= BinaryOps.minInt16) {
      writer.set(offset, MsgPackConst.int16Flag);
      writer.setI16Be(offset + 1, v);
      return 3;
    }
    if (v >= BinaryOps.minInt32) {
      writer.set(offset, MsgPackConst.int32Flag);
      writer.setI32Be(offset + 1, v);
      return 5;
    }
    writer.set(offset, MsgPackConst.int64Flag);
    writer.setI64Be(offset + 1, BigInt.from(v));
    return 9;
  }

  @override
  MsgPackIntLayout clone({String? newProperty}) =>
      MsgPackIntLayout(property: newProperty, encodeOption: encodeOption);
}

/// MessagePack integer decoded/encoded as a [BigInt] (all forms, including
/// magnitudes beyond a Dart [int]).
class MsgPackBigIntLayout extends Layout<BigInt> {
  final MsgPackEncodeOption<BigInt> encodeOption;
  final BigIntLayout? validator;
  const MsgPackBigIntLayout({
    this.validator,
    super.property,
    this.encodeOption = const MsgPackEncodeOptionDefault<BigInt>(),
  }) : super(-1);

  LayoutDecodeResult<BigInt> _decode(LayoutByteReader bytes, {int offset = 0}) {
    final fb = bytes.at(offset);
    if (fb <= MsgPackConst.positiveFixint) {
      return LayoutDecodeResult(consumed: 1, value: BigInt.from(fb));
    }
    if (fb >= MsgPackConst.negativeFixint) {
      return LayoutDecodeResult(consumed: 1, value: BigInt.from(fb - 256));
    }

    switch (fb) {
      case MsgPackConst.uint8Flag:
        return LayoutDecodeResult(
          consumed: 2,
          value: BigInt.from(bytes.getU8(offset + 1)),
        );
      case MsgPackConst.uint16Flag:
        return LayoutDecodeResult(
          consumed: 3,
          value: BigInt.from(bytes.getU16Be(offset + 1)),
        );
      case MsgPackConst.uint32Flag:
        return LayoutDecodeResult(
          consumed: 5,
          value: BigInt.from(bytes.getU32Be(offset + 1)),
        );
      case MsgPackConst.uint64Flag:
        final v = bytes.getU64Be(offset + 1);
        return LayoutDecodeResult(consumed: 9, value: v);
      case MsgPackConst.int8Flag:
        final u = bytes.getU8(offset + 1);
        return LayoutDecodeResult(
          consumed: 2,
          value: BigInt.from(u > MsgPackConst.positiveFixint ? u - 0x100 : u),
        );
      case MsgPackConst.int16Flag:
        final u = bytes.getU16Be(offset + 1);
        return LayoutDecodeResult(
          consumed: 3,
          value: BigInt.from(u > 0x7fff ? u - 0x10000 : u),
        );
      case MsgPackConst.int32Flag:
        final u = bytes.getU32Be(offset + 1);
        return LayoutDecodeResult(
          consumed: 5,
          value: BigInt.from(u > 0x7fffffff ? u - 0x100000000 : u),
        );
      case MsgPackConst.int64Flag:
        final v = bytes.getU64Be(offset + 1);
        final signed = v > BinaryOps.maxInt64 ? v - (BigInt.one << 64) : v;
        return LayoutDecodeResult(consumed: 9, value: signed);
      default:
        throw BuError(
          DefaultErrorType.invalidArgument,
          'Expected MessagePack integer',
          details: {'property': property, 'byte': fb.toString()},
        );
    }
  }

  @override
  LayoutDecodeResult<BigInt> decode(LayoutByteReader bytes, {int offset = 0}) {
    final decode = _decode(bytes, offset: offset);
    validator?.validate(decode.value);
    return decode;
  }

  @override
  int encode(BigInt source, LayoutByteWriter writer, {int offset = 0}) {
    if (!encodeOption.encode(source, property)) return 0;
    validator?.validate(source);
    return _encodeBigInt(source, writer, offset);
  }

  /// Writes [v] in the smallest MessagePack integer form and returns its size.
  static int _encodeBigInt(BigInt v, LayoutByteWriter writer, int offset) {
    if (v >= BigInt.zero) {
      if (v <= BigInt.from(MsgPackConst.positiveFixint)) {
        writer.set(offset, v.toInt());
        return 1;
      }
      if (v <= BinaryOps.maskBig8) {
        writer.set(offset, MsgPackConst.uint8Flag);
        writer.set(offset + 1, v.toInt());
        return 2;
      }
      if (v <= BinaryOps.maskBig16) {
        writer.set(offset, MsgPackConst.uint16Flag);
        writer.setU16Be(offset + 1, v.toInt());
        return 3;
      }
      if (v <= BinaryOps.maskBig32) {
        writer.set(offset, MsgPackConst.uint32Flag);
        writer.setU32Be(offset + 1, v.toInt());
        return 5;
      }
      if (v <= BinaryOps.maxU64) {
        writer.set(offset, MsgPackConst.uint64Flag);
        writer.setU64Be(offset + 1, v);
        return 9;
      }
    } else {
      if (v >= BigInt.from(-32)) {
        writer.set(offset, v.toInt() & BinaryOps.mask8);
        return 1;
      }
      if (v >= BigInt.from(-128)) {
        writer.set(offset, MsgPackConst.int8Flag);
        writer.set(offset + 1, v.toInt() & BinaryOps.mask8);
        return 2;
      }
      if (v >= BinaryOps.minInt16Big) {
        writer.set(offset, MsgPackConst.int16Flag);
        writer.setI16Be(offset + 1, v.toInt());
        return 3;
      }
      if (v >= BinaryOps.minInt32Big) {
        writer.set(offset, MsgPackConst.int32Flag);
        writer.setI32Be(offset + 1, v.toInt());
        return 5;
      }
      if (v >= BinaryOps.minInt64) {
        writer.set(offset, MsgPackConst.int64Flag);
        writer.setI64Be(offset + 1, v);
        return 9;
      }
    }
    throw BuError(
      DefaultErrorType.invalidArgument,
      'BigInt out of MessagePack int range',
      details: {'value': v.toString()},
    );
  }

  @override
  MsgPackBigIntLayout clone({String? newProperty}) =>
      MsgPackBigIntLayout(property: newProperty, encodeOption: encodeOption);
}

/// MessagePack 32- or 64-bit float.
class MsgPackFloatLayout extends Layout<double> {
  final bool forceFloat64;
  final MsgPackEncodeOption<double> encodeOption;
  const MsgPackFloatLayout({
    super.property,
    this.encodeOption = const MsgPackEncodeOptionDefault<double>(),
    this.forceFloat64 = true,
  }) : super(-1);

  @override
  LayoutDecodeResult<double> decode(LayoutByteReader bytes, {int offset = 0}) {
    final fb = bytes.at(offset);
    if (fb == 0xca) {
      final bd = ByteData.sublistView(
        Uint8List.fromList(bytes.sublist(offset + 1, offset + 5)),
      );
      return LayoutDecodeResult(
        consumed: 5,
        value: bd.getFloat32(0, Endian.big),
      );
    }
    if (fb == 0xcb) {
      final bd = ByteData.sublistView(
        Uint8List.fromList(bytes.sublist(offset + 1, offset + 9)),
      );
      return LayoutDecodeResult(
        consumed: 9,
        value: bd.getFloat64(0, Endian.big),
      );
    }
    throw BuError(
      DefaultErrorType.invalidArgument,
      'Expected MessagePack float',
      details: {'property': property, 'byte': fb.toString()},
    );
  }

  @override
  int encode(double source, LayoutByteWriter writer, {int offset = 0}) {
    if (!encodeOption.encode(source, property)) return 0;
    if (!forceFloat64) {
      final f32 = ByteData(4)..setFloat32(0, source, Endian.big);
      final back = f32.getFloat32(0, Endian.big);
      if (back == source || source.isNaN) {
        writer.set(offset, 0xca);
        writer.setAll(offset + 1, f32.buffer.asUint8List());
        return 5;
      }
    }
    final f64 = ByteData(8)..setFloat64(0, source, Endian.big);
    writer.set(offset, 0xcb);
    writer.setAll(offset + 1, f64.buffer.asUint8List());
    return 9;
  }

  @override
  MsgPackFloatLayout clone({String? newProperty}) => MsgPackFloatLayout(
    forceFloat64: forceFloat64,
    property: newProperty,
    encodeOption: encodeOption,
  );
}

/// MessagePack UTF-8 string (fixstr/str8/str16/str32).
class MsgPackStringLayout extends Layout<String> {
  final MsgPackEncodeOption<String> encodeOption;
  const MsgPackStringLayout({
    super.property,
    this.encodeOption = const MsgPackEncodeOptionDefault<String>(),
  }) : super(-1);

  @override
  LayoutDecodeResult<String> decode(LayoutByteReader bytes, {int offset = 0}) {
    final (n, header) = MsgPackConst.readLengthHeader(
      bytes,
      offset,
      fixLow: 0xa0,
      fixHigh: 0xbf,
      fixMask: 0x1f,
      flag8: 0xd9,
      flag16: 0xda,
      flag32: 0xdb,
      what: 'string',
      property: property,
    );
    final data = bytes.sublist(offset + header, offset + header + n);
    final s = StringUtils.decode(data, allowInvalidOrMalformed: true);
    return LayoutDecodeResult(consumed: header + n, value: s);
  }

  @override
  int encode(String source, LayoutByteWriter writer, {int offset = 0}) {
    if (!encodeOption.encode(source, property)) return 0;
    final data = StringUtils.encode(source);
    final n = data.length;
    final header = MsgPackConst.writeLengthHeader(
      writer,
      offset,
      n,
      fixBits: 5,
      fixPrefix: 0xa0,
      flag8: 0xd9,
      flag16: 0xda,
      flag32: 0xdb,
    );
    writer.setAll(offset + header, data);
    return header + n;
  }

  @override
  MsgPackStringLayout clone({String? newProperty}) =>
      MsgPackStringLayout(property: newProperty, encodeOption: encodeOption);
}

/// MessagePack binary blob (bin8/bin16/bin32), optionally of a [fixedLength].
class MsgPackBinaryLayout extends Layout<List<int>> {
  final MsgPackEncodeOption<List<int>> encodeOption;
  final int? fixedLength;
  const MsgPackBinaryLayout({
    super.property,
    this.fixedLength,
    this.encodeOption = const MsgPackEncodeOptionDefault<List<int>>(),
  }) : super(-1);

  @override
  LayoutDecodeResult<List<int>> decode(
    LayoutByteReader bytes, {
    int offset = 0,
  }) {
    final (n, header) = MsgPackConst.readLengthHeader(
      bytes,
      offset,
      flag8: 0xc4,
      flag16: 0xc5,
      flag32: 0xc6,
      what: 'binary',
      property: property,
    );
    final data = bytes.sublist(offset + header, offset + header + n);
    if (fixedLength != null && data.length != fixedLength) {
      throw BuError(
        DefaultErrorType.invalidLength,
        'Invalid decode bytes length.',
        details: {
          'property': property,
          "expected": fixedLength?.toString(),
          "length": data.length.toString(),
        },
      );
    }
    return LayoutDecodeResult(consumed: header + n, value: data);
  }

  @override
  int encode(List<int> source, LayoutByteWriter writer, {int offset = 0}) {
    if (!encodeOption.encode(source, property)) return 0;
    if (fixedLength != null && source.length != fixedLength) {
      throw BuError(
        DefaultErrorType.invalidLength,
        'Invalid source bytes length.',
        details: {
          'property': property,
          "expected": fixedLength?.toString(),
          "length": source.length.toString(),
        },
      );
    }
    final n = source.length;
    final header = MsgPackConst.writeLengthHeader(
      writer,
      offset,
      n,
      flag8: 0xc4,
      flag16: 0xc5,
      flag32: 0xc6,
    );
    writer.setAll(offset + header, source);
    return header + n;
  }

  @override
  MsgPackBinaryLayout clone({String? newProperty}) => MsgPackBinaryLayout(
    property: newProperty,
    encodeOption: encodeOption,
    fixedLength: fixedLength,
  );
}

/// MessagePack array (fixarray/array16/array32) of [elementLayout] elements.
class MsgPackArrayLayout<T> extends Layout<List<T>> {
  final Layout<T> elementLayout;
  final MsgPackEncodeOption<List<T>>? encodeOption;
  const MsgPackArrayLayout(
    this.elementLayout, {
    super.property,
    this.encodeOption,
  }) : super(-1);

  @override
  LayoutDecodeResult<List<T>> decode(LayoutByteReader bytes, {int offset = 0}) {
    final (count, header) = MsgPackConst.readLengthHeader(
      bytes,
      offset,
      fixLow: 0x90,
      fixHigh: 0x9f,
      fixMask: 0x0f,
      flag16: 0xdc,
      flag32: 0xdd,
      what: 'array',
      property: property,
    );

    final list = <T>[];
    int consumed = header;
    for (int k = 0; k < count; k++) {
      final r = elementLayout.decode(bytes, offset: offset + consumed);
      list.add(r.value);
      consumed += r.consumed;
    }
    return LayoutDecodeResult(consumed: consumed, value: list);
  }

  @override
  int encode(List<T> source, LayoutByteWriter writer, {int offset = 0}) {
    if (!(encodeOption?.encode(source, property) ?? true)) return 0;
    final n = source.length;
    final header = MsgPackConst.writeLengthHeader(
      writer,
      offset,
      n,
      fixBits: 4,
      fixPrefix: 0x90,
      flag16: 0xdc,
      flag32: 0xdd,
    );
    int span = header;
    for (final item in source) {
      span += elementLayout.encode(item, writer, offset: offset + span);
    }
    return span;
  }

  @override
  MsgPackArrayLayout<T> clone({String? newProperty}) => MsgPackArrayLayout<T>(
    elementLayout,
    property: newProperty,
    encodeOption: encodeOption,
  );
}

/// MessagePack map (fixmap/map16/map32) of [keyLayout]/[valueLayout] pairs.
class MsgPackMapLayout<K, V> extends Layout<Map<K, V>> {
  final Layout<K> keyLayout;
  final Layout<V> valueLayout;
  final MsgPackEncodeOption<Map<K, V>>? encodeOption;
  const MsgPackMapLayout({
    required this.keyLayout,
    required this.valueLayout,
    super.property,
    this.encodeOption,
  }) : super(-1);

  @override
  LayoutDecodeResult<Map<K, V>> decode(
    LayoutByteReader bytes, {
    int offset = 0,
  }) {
    final (count, header) = MsgPackConst.readLengthHeader(
      bytes,
      offset,
      fixLow: 0x80,
      fixHigh: 0x8f,
      fixMask: 0x0f,
      flag16: 0xde,
      flag32: 0xdf,
      what: 'map',
      property: property,
    );

    final map = <K, V>{};
    int consumed = header;
    for (int k = 0; k < count; k++) {
      final key = keyLayout.decode(bytes, offset: offset + consumed);
      consumed += key.consumed;
      final val = valueLayout.decode(bytes, offset: offset + consumed);
      consumed += val.consumed;
      map[key.value] = val.value;
    }
    return LayoutDecodeResult(consumed: consumed, value: map);
  }

  @override
  int encode(Map<K, V> source, LayoutByteWriter writer, {int offset = 0}) {
    if (!(encodeOption?.encode(source, property) ?? true)) return 0;
    final n = source.length;
    final header = MsgPackConst.writeLengthHeader(
      writer,
      offset,
      n,
      fixBits: 4,
      fixPrefix: 0x80,
      flag16: 0xde,
      flag32: 0xdf,
    );
    int span = header;
    for (final e in source.entries) {
      span += keyLayout.encode(e.key, writer, offset: offset + span);
      span += valueLayout.encode(e.value, writer, offset: offset + span);
    }
    return span;
  }

  @override
  MsgPackMapLayout clone({String? newProperty}) => MsgPackMapLayout(
    keyLayout: keyLayout,
    valueLayout: valueLayout,
    property: newProperty,
    encodeOption: encodeOption,
  );
}

/// A MessagePack extension value: an application-defined [type] tag plus [data].
class MsgPackExtValue {
  final int type;
  final List<int> data;
  const MsgPackExtValue(this.type, this.data);
}

/// MessagePack extension type (fixext 1/2/4/8/16, ext8/16/32).
class MsgPackExtLayout extends Layout<MsgPackExtValue> {
  final MsgPackEncodeOption<MsgPackExtValue> encodeOption;
  const MsgPackExtLayout({
    super.property,
    this.encodeOption = const MsgPackEncodeOptionDefault<MsgPackExtValue>(),
  }) : super(-1);

  @override
  LayoutDecodeResult<MsgPackExtValue> decode(
    LayoutByteReader bytes, {
    int offset = 0,
  }) {
    final fb = bytes.at(offset);
    int dataLen;
    int header;

    if (fb == 0xd4) {
      dataLen = 1;
      header = 1;
    } else if (fb == 0xd5) {
      dataLen = 2;
      header = 1;
    } else if (fb == 0xd6) {
      dataLen = 4;
      header = 1;
    } else if (fb == 0xd7) {
      dataLen = 8;
      header = 1;
    } else if (fb == 0xd8) {
      dataLen = 16;
      header = 1;
    } else if (fb == 0xc7) {
      dataLen = bytes.getU8(offset + 1);
      header = 2;
    } else if (fb == 0xc8) {
      dataLen = bytes.getU16Be(offset + 1);
      header = 3;
    } else if (fb == 0xc9) {
      dataLen = bytes.getU32Be(offset + 1);
      header = 5;
    } else {
      throw BuError(
        DefaultErrorType.invalidArgument,
        'Expected MessagePack ext',
        details: {'property': property, 'byte': fb.toString()},
      );
    }

    final typeByte = bytes.at(offset + header);
    final type =
        typeByte > MsgPackConst.positiveFixint ? typeByte - 0x100 : typeByte;
    final data = bytes.sublist(
      offset + header + 1,
      offset + header + 1 + dataLen,
    );
    return LayoutDecodeResult(
      consumed: header + 1 + dataLen,
      value: MsgPackExtValue(type, List<int>.from(data)),
    );
  }

  @override
  int encode(
    MsgPackExtValue source,
    LayoutByteWriter writer, {
    int offset = 0,
  }) {
    if (!encodeOption.encode(source, property)) return 0;
    final n = source.data.length;
    final t = source.type & BinaryOps.mask8;
    int header;
    const fixedExtTags = {1: 0xd4, 2: 0xd5, 4: 0xd6, 8: 0xd7, 16: 0xd8};
    if (fixedExtTags.containsKey(n)) {
      writer.set(offset, fixedExtTags[n]!);
      header = 1;
    } else if (n <= BinaryOps.mask8) {
      writer.set(offset, 0xc7);
      writer.set(offset + 1, n);
      header = 2;
    } else if (n <= BinaryOps.mask16) {
      writer.set(offset, 0xc8);
      writer.setU16Be(offset + 1, n);
      header = 3;
    } else {
      writer.set(offset, 0xc9);
      writer.setU32Be(offset + 1, n);
      header = 5;
    }
    writer.set(offset + header, t);
    writer.setAll(offset + header + 1, source.data);
    return header + 1 + n;
  }

  @override
  MsgPackExtLayout clone({String? newProperty}) =>
      MsgPackExtLayout(property: newProperty, encodeOption: encodeOption);
}

/// MessagePack timestamp extension (ext type -1; 32/64/96-bit forms).
class MsgPackTimestampLayout extends Layout<DateTime> {
  final MsgPackEncodeOption<DateTime> encodeOption;
  const MsgPackTimestampLayout({
    super.property,
    this.encodeOption = const MsgPackEncodeOptionDefault<DateTime>(),
  }) : super(-1);

  @override
  LayoutDecodeResult<DateTime> decode(
    LayoutByteReader bytes, {
    int offset = 0,
  }) {
    final ext = const MsgPackExtLayout().decode(bytes, offset: offset);
    if (ext.value.type != -1) {
      throw BuError(
        DefaultErrorType.invalidArgument,
        'Expected MessagePack timestamp (ext type -1)',
        details: {'property': property, 'type': ext.value.type.toString()},
      );
    }
    final data = ext.value.data;
    DateTime dt;
    switch (data.length) {
      case 4:
        final sec =
            (data[0] << 24) | (data[1] << 16) | (data[2] << 8) | data[3];
        dt = DateTime.fromMillisecondsSinceEpoch(sec * 1000, isUtc: true);
        break;
      case 8:
        final u64 = BigintUtils.fromBytes(data);
        final nsec = (u64 >> 34).toInt();
        final sec = (u64 & BigInt.from(0x3ffffffff)).toInt();
        dt = DateTime.fromMillisecondsSinceEpoch(
          sec * 1000 + nsec ~/ 1000000,
          isUtc: true,
        );
        break;
      case 12:
        final nsec =
            (data[0] << 24) | (data[1] << 16) | (data[2] << 8) | data[3];
        final sec = BigintUtils.fromBytes(data.sublist(4));
        final signed =
            sec > BinaryOps.maxInt64 ? sec - (BigInt.one << 64) : sec;
        dt = DateTime.fromMillisecondsSinceEpoch(
          signed.toInt() * 1000 + nsec ~/ 1000000,
          isUtc: true,
        );
        break;
      default:
        throw BuError(
          DefaultErrorType.invalidLength,
          'Invalid timestamp payload length',
          details: {'length': data.length.toString()},
        );
    }
    return LayoutDecodeResult(consumed: ext.consumed, value: dt);
  }

  @override
  int encode(DateTime source, LayoutByteWriter writer, {int offset = 0}) {
    if (!encodeOption.encode(source, property)) {
      return 0;
    }
    final utc = source.toUtc();
    final ms = utc.millisecondsSinceEpoch;
    int secNum = ms ~/ 1000;
    int msRem = ms % 1000;
    if (msRem < 0) {
      msRem += 1000;
      secNum -= 1;
    }
    final sec = BigInt.from(secNum);
    final nsec = msRem * 1000000;

    List<int> data;
    if (sec >= BigInt.zero && sec <= BinaryOps.maskBig32 && nsec == 0) {
      data = sec.toU32BeBytes();
    } else if (sec >= BigInt.zero && sec < (BigInt.one << 34)) {
      final packed = (BigInt.from(nsec) << 34) | sec;
      data = packed.toU64BeBytes();
    } else {
      data = [...nsec.toU32BeBytes(), ...sec.toI64BeBytes()];
    }
    return const MsgPackExtLayout().encode(
      MsgPackExtValue(-1, data),
      writer,
      offset: offset,
    );
  }

  @override
  MsgPackTimestampLayout clone({String? newProperty}) =>
      MsgPackTimestampLayout(property: newProperty);
}

/// Shared map decode/encode for [MsgPackFixedKeyDynamicLazyValueMapLayout]
/// and [MsgPackFixedKeyFixedLazyValueMapLayout] — both differ only in how
/// they resolve the value builder for a given key (see [valueBuilderFor]).
abstract class _MsgPackLazyKeyedMapLayout<K, V, R extends LayoutRepository>
    extends Layout<Map<K, V>> {
  final Layout<K> keyLayout;
  final MsgPackEncodeOption<Map<K, V>>? encodeOption;
  final R? repository;
  final bool sortKeys;

  const _MsgPackLazyKeyedMapLayout({
    required this.keyLayout,
    this.repository,
    this.encodeOption,
    this.sortKeys = false,
    super.property,
  }) : super(-1);

  /// Resolves the lazy value-layout builder for [key].
  LazyMsgPackMapLayoutBuilder<K, V, R>? valueBuilderFor(K key);

  @override
  LayoutDecodeResult<Map<K, V>> decode(
    LayoutByteReader bytes, {
    int offset = 0,
  }) {
    final (count, header) = MsgPackConst.readLengthHeader(
      bytes,
      offset,
      fixLow: 0x80,
      fixHigh: 0x8f,
      fixMask: 0x0f,
      flag16: 0xde,
      flag32: 0xdf,
      what: 'map',
      property: property,
    );

    final map = <K, V>{};
    int consumed = header;
    int remainingBytes = bytes.length - offset;
    for (int k = 0; k < count; k++) {
      final key = keyLayout.decode(bytes, offset: offset + consumed);
      consumed += key.consumed;
      remainingBytes -= key.consumed;
      final layout = valueBuilderFor(key.value)?.layout(
        action: LayoutAction.decode,
        sourceOrResult: map,
        remainBytes: remainingBytes,
        repository: repository,
      );
      if (layout == null) {
        throw BuError(
          DefaultErrorType.invalidArgument,
          'Missing map value layout.',
          details: {'property': property, 'key': key.value.toString()},
        );
      }
      final val = layout.decode(bytes, offset: offset + consumed);
      consumed += val.consumed;
      remainingBytes -= val.consumed;
      map[key.value] = val.value;
    }
    return LayoutDecodeResult(consumed: consumed, value: map);
  }

  @override
  int encode(Map<K, V> source, LayoutByteWriter writer, {int offset = 0}) {
    if (!(encodeOption?.encode(source, property) ?? true)) return 0;
    final w = LayoutByteWriter(-1);
    int span = 0;
    int n = 0;
    final keys = source.keys.toList();
    if (sortKeys) {
      keys.sort();
    }
    for (final e in keys) {
      final value = source[e];
      final layout = valueBuilderFor(e)?.layout(
        action: LayoutAction.encode,
        sourceOrResult: source,
        remainBytes: 0,
        repository: repository,
        value: value,
      );
      if (layout == null) continue;
      span += keyLayout.encode(e, w, offset: span);
      span += layout.encode(value as V, w, offset: span);
      n++;
    }
    final header = MsgPackConst.writeLengthHeader(
      writer,
      offset,
      n,
      fixBits: 4,
      fixPrefix: 0x80,
      flag16: 0xde,
      flag32: 0xdf,
    );
    writer.setAll(offset + header, w.toBytes());
    return span + header;
  }
}

/// MessagePack map with a fixed key layout, whose value layout is chosen
/// per-decoded-key from [valueLayouts].
class MsgPackFixedKeyDynamicLazyValueMapLayout<K, V, R extends LayoutRepository>
    extends _MsgPackLazyKeyedMapLayout<K, V, R> {
  final List<MapEntry<K, LazyMsgPackMapLayoutBuilder<K, V, R>>> valueLayouts;

  const MsgPackFixedKeyDynamicLazyValueMapLayout({
    required super.keyLayout,
    required this.valueLayouts,
    super.repository,
    super.encodeOption,
    super.sortKeys,
    super.property,
  });

  @override
  LazyMsgPackMapLayoutBuilder<K, V, R>? valueBuilderFor(K key) {
    return valueLayouts
        .firstWhereNullable((i) => Equality.deepEqual(i.key, key))
        ?.value;
  }

  @override
  MsgPackFixedKeyDynamicLazyValueMapLayout<K, V, R> clone({
    String? newProperty,
  }) => MsgPackFixedKeyDynamicLazyValueMapLayout(
    keyLayout: keyLayout,
    valueLayouts: valueLayouts,
    property: newProperty,
    repository: repository,
    encodeOption: encodeOption,
    sortKeys: sortKeys,
  );
}

/// MessagePack map with a fixed key layout and a single shared value layout.
class MsgPackFixedKeyFixedLazyValueMapLayout<K, V, R extends LayoutRepository>
    extends _MsgPackLazyKeyedMapLayout<K, V, R> {
  final LazyMsgPackMapLayoutBuilder<K, V, R> valueLayout;

  const MsgPackFixedKeyFixedLazyValueMapLayout({
    required super.keyLayout,
    required this.valueLayout,
    super.encodeOption,
    super.sortKeys,
    super.repository,
    super.property,
  });

  @override
  LazyMsgPackMapLayoutBuilder<K, V, R>? valueBuilderFor(K key) => valueLayout;

  @override
  MsgPackFixedKeyFixedLazyValueMapLayout<K, V, R> clone({
    String? newProperty,
  }) => MsgPackFixedKeyFixedLazyValueMapLayout(
    keyLayout: keyLayout,
    valueLayout: valueLayout,
    property: newProperty,
    repository: repository,
    sortKeys: sortKeys,
    encodeOption: encodeOption,
  );
}

/// A MessagePack layout for schema-less / unknown dynamic type decoding and encoding.
class MsgPackAnyLayout extends Layout<dynamic> {
  const MsgPackAnyLayout({super.property}) : super(-1);

  @override
  LayoutDecodeResult<dynamic> decode(LayoutByteReader bytes, {int offset = 0}) {
    final fb = bytes.at(offset);

    // Nil (0xc0)
    if (fb == 0xc0) {
      return const MsgPackNilLayout().decode(bytes, offset: offset);
    }

    // Bool (0xc2, 0xc3)
    if (fb == 0xc2 || fb == 0xc3) {
      return const MsgPackBoolLayout().decode(bytes, offset: offset);
    }

    // Integers (Fixint, uint8..64, int8..64)
    if (fb <= MsgPackConst.positiveFixint ||
        fb >= MsgPackConst.negativeFixint ||
        (fb >= MsgPackConst.uint8Flag && fb <= MsgPackConst.uint64Flag) ||
        (fb >= MsgPackConst.int8Flag && fb <= MsgPackConst.int64Flag)) {
      if (fb == MsgPackConst.uint64Flag || fb == MsgPackConst.int64Flag) {
        return const MsgPackBigIntLayout().decode(bytes, offset: offset);
      }
      return const MsgPackIntLayout().decode(bytes, offset: offset);
    }

    // Float (0xca, 0xcb)
    if (fb == 0xca || fb == 0xcb) {
      return const MsgPackFloatLayout().decode(bytes, offset: offset);
    }

    // String (Fixstr, str8, str16, str32)
    if ((fb >= 0xa0 && fb <= 0xbf) || fb == 0xd9 || fb == 0xda || fb == 0xdb) {
      return const MsgPackStringLayout().decode(bytes, offset: offset);
    }

    // Binary (bin8, bin16, bin32)
    if (fb == 0xc4 || fb == 0xc5 || fb == 0xc6) {
      return const MsgPackBinaryLayout().decode(bytes, offset: offset);
    }

    // Array (Fixarray, array16, array32)
    if ((fb >= 0x90 && fb <= 0x9f) || fb == 0xdc || fb == 0xdd) {
      return const MsgPackArrayLayout<dynamic>(
        MsgPackAnyLayout(),
      ).decode(bytes, offset: offset);
    }

    // Map (Fixmap, map16, map32)
    if ((fb >= 0x80 && fb <= 0x8f) || fb == 0xde || fb == 0xdf) {
      return const MsgPackMapLayout<dynamic, dynamic>(
        keyLayout: MsgPackAnyLayout(),
        valueLayout: MsgPackAnyLayout(),
      ).decode(bytes, offset: offset);
    }

    // Extension Types (fixext 1..16, ext 8..32)
    if ((fb >= 0xd4 && fb <= 0xd8) || fb == 0xc7 || fb == 0xc8 || fb == 0xc9) {
      // Check if Timestamp (ext type -1)
      final ext = const MsgPackExtLayout().decode(bytes, offset: offset);
      if (ext.value.type == -1) {
        return const MsgPackTimestampLayout().decode(bytes, offset: offset);
      }
      return ext;
    }

    throw BuError(
      DefaultErrorType.invalidArgument,
      'Unknown MessagePack header format byte: 0x${fb.toRadixString(16)}',
      details: {'property': property, 'byte': fb.toString()},
    );
  }

  @override
  int encode(dynamic source, LayoutByteWriter writer, {int offset = 0}) {
    if (source == null) {
      return const MsgPackNilLayout().encode(null, writer, offset: offset);
    }
    if (source is bool) {
      return const MsgPackBoolLayout().encode(source, writer, offset: offset);
    }
    if (source is int) {
      return const MsgPackIntLayout().encode(source, writer, offset: offset);
    }
    if (source is BigInt) {
      return const MsgPackBigIntLayout().encode(source, writer, offset: offset);
    }
    if (source is double) {
      return const MsgPackFloatLayout().encode(source, writer, offset: offset);
    }
    if (source is String) {
      return const MsgPackStringLayout().encode(source, writer, offset: offset);
    }
    if (source is DateTime) {
      return const MsgPackTimestampLayout().encode(
        source,
        writer,
        offset: offset,
      );
    }
    if (source is MsgPackExtValue) {
      return const MsgPackExtLayout().encode(source, writer, offset: offset);
    }
    if (source is List<int>) {
      return const MsgPackBinaryLayout().encode(source, writer, offset: offset);
    }
    if (source is List) {
      return const MsgPackArrayLayout<dynamic>(
        MsgPackAnyLayout(),
      ).encode(source, writer, offset: offset);
    }
    if (source is Map) {
      return const MsgPackMapLayout<dynamic, dynamic>(
        keyLayout: MsgPackAnyLayout(),
        valueLayout: MsgPackAnyLayout(),
      ).encode(source, writer, offset: offset);
    }

    throw BuError(
      DefaultErrorType.unsupported,
      'Unsupported value type for MessagePack encoding: ${source.runtimeType}',
      details: {'property': property, 'value': source.toString()},
    );
  }

  @override
  MsgPackAnyLayout clone({String? newProperty}) =>
      MsgPackAnyLayout(property: newProperty);
}
