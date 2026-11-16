import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

import '../../utils.dart';

bool listEquals(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

void layoutNumericTest() {
  group('IntegerLayout', () {
    test('u8 roundtrip boundaries', () {
      final layout = LayoutConst.u8(property: 'v');
      expect(layout.span, 1);
      expect(listEquals(layout.serialize(0), [0]), isTrue);
      expect(listEquals(layout.serialize(255), [255]), isTrue);
      expect(layout.deserialize([255]).value, 255);
      expect(layout.deserialize([255]).consumed, 1);
      expect(layout.serializeHex(255), 'ff');
    });

    test('u8 rejects out of range and negatives', () {
      final layout = LayoutConst.u8(property: 'v');
      expect(() => layout.serialize(256), throwsA(isA<BuError>()));
      expect(() => layout.serialize(-1), throwsA(isA<BuError>()));
    });

    test('i8 handles negatives', () {
      final layout = LayoutConst.i8(property: 'v');
      expect(listEquals(layout.serialize(-1), [255]), isTrue);
      expect(listEquals(layout.serialize(-128), [128]), isTrue);
      expect(layout.deserialize([255]).value, -1);
      expect(() => layout.serialize(128), throwsA(isA<BuError>()));
    });

    test('u16 little-endian byte order', () {
      final layout = LayoutConst.u16(property: 'v');
      expect(listEquals(layout.serialize(0x1234), [0x34, 0x12]), isTrue);
      expect(layout.deserialize([0x34, 0x12]).value, 0x1234);
      expect(() => layout.serialize(0x10000), throwsA(isA<BuError>()));
    });

    test('u16be big-endian byte order', () {
      final layout = LayoutConst.u16be(property: 'v');
      expect(listEquals(layout.serialize(0x1234), [0x12, 0x34]), isTrue);
      expect(layout.deserialize([0x12, 0x34]).value, 0x1234);
    });

    test('u32 roundtrip max', () {
      final layout = LayoutConst.u32(property: 'v');
      expect(layout.deserialize([0xFF, 0xFF, 0xFF, 0xFF]).value, 0xFFFFFFFF);
      expect(
        listEquals(layout.serialize(0xFFFFFFFF), [0xFF, 0xFF, 0xFF, 0xFF]),
        isTrue,
      );
      expect(() => layout.serialize(-1), throwsA(isA<BuError>()));
    });

    test('i32 negative roundtrip', () {
      final layout = LayoutConst.i32(property: 'v');
      expect(layout.deserialize(layout.serialize(-123456)).value, -123456);
    });

    test('u24 middle width', () {
      final layout = LayoutConst.u24(property: 'v');
      expect(layout.span, 3);
      expect(layout.deserialize(layout.serialize(0xABCDEF)).value, 0xABCDEF);
      expect(
        () => layout.serialize(0x1000000),
        throwsA(isA<BuError>()),
      );
    });

    test('span wider than 7 bytes is rejected', () {
      expect(() => IntegerLayout(8), throwsA(isA<BuError>()));
      expect(() => LayoutConst.intLayout(9), throwsA(isA<BuError>()));
    });

    test('signed 7-byte layout roundtrip', () {
      final layout = LayoutConst.intLayout(7, sign: true, property: 'v');
      expect(layout.deserialize(layout.serialize(-1)).value, -1);
      expect(
        layout.deserialize(layout.serialize(0x123456789ABC)).value,
        0x123456789ABC,
      );
    });

    test('clone keeps width and signedness', () {
      final layout = LayoutConst.i16(property: 'a');
      final cloned = layout.clone(newProperty: 'b');
      expect(cloned.property, 'b');
      expect(cloned.span, 2);
      expect(cloned.sign, isTrue);
      expect(layout.deserialize(cloned.serialize(-5)).value, -5);
    });
  });

  group('BigIntLayout', () {
    test('u64 max roundtrip', () {
      final layout = LayoutConst.u64(property: 'v');
      final max = BigInt.parse('18446744073709551615');
      expect(layout.deserialize(layout.serialize(max)).value, max);
      expect(layout.deserialize(List<int>.filled(8, 0xFF)).value, max);
    });

    test('u64 rejects negative and overflow', () {
      final layout = LayoutConst.u64(property: 'v');
      expect(
        () => layout.serialize(BigInt.from(-1)),
        throwsA(isA<BuError>()),
      );
      expect(
        () => layout.serialize(BigInt.one << 64),
        throwsA(isA<BuError>()),
      );
    });

    test('i64 negative roundtrip', () {
      final layout = LayoutConst.i64(property: 'v');
      final min = -(BigInt.one << 63);
      expect(layout.deserialize(layout.serialize(min)).value, min);
      expect(
        layout.deserialize(layout.serialize(BigInt.from(-42))).value,
        BigInt.from(-42),
      );
    });

    test('u64be byte order', () {
      final layout = LayoutConst.u64be(property: 'v');
      final bytes = layout.serialize(BigInt.one);
      expect(bytes.last, 1);
      expect(bytes.first, 0);
      expect(bytes.length, 8);
      expect(layout.deserialize(bytes).value, BigInt.one);
    });

    test('u128/u256 widths', () {
      final u128 = LayoutConst.u128(property: 'v');
      final big = (BigInt.one << 127) + BigInt.from(12345);
      expect(u128.deserialize(u128.serialize(big)).value, big);
      final u256 = LayoutConst.u256(property: 'v');
      final bigger = (BigInt.one << 255) - BigInt.one;
      expect(u256.deserialize(u256.serialize(bigger)).value, bigger);
      expect(
        () => u128.serialize(BigInt.one << 128),
        throwsA(isA<BuError>()),
      );
    });

    test('i128 negative', () {
      final layout = LayoutConst.i128(property: 'v');
      final v = -(BigInt.one << 100);
      expect(layout.deserialize(layout.serialize(v)).value, v);
    });
  });

  group('DoubleLayout', () {
    test('f64 pi roundtrip', () {
      final layout = LayoutConst.f64(property: 'v');
      expect(layout.span, 8);
      final bytes = layout.serialize(3.141592653589793);
      expect(bytes.length, 8);
      expect(layout.deserialize(bytes).value, 3.141592653589793);
    });

    test('f32 roundtrip within float precision', () {
      final layout = LayoutConst.f32(property: 'v');
      expect(layout.span, 4);
      final bytes = layout.serialize(0.5);
      expect(bytes.length, 4);
      expect(layout.deserialize(bytes).value, 0.5);
    });

    test('f64be byte order differs from le', () {
      final le = LayoutConst.f64(property: 'v');
      final be = LayoutConst.f64be(property: 'v');
      final a = le.serialize(1.5);
      final b = be.serialize(1.5);
      expect(listEquals(List<int>.from(a.reversed), b), isTrue);
      expect(be.deserialize(b).value, 1.5);
    });
  });

  group('Compact integers', () {
    test('compactIntU32 SCALE vectors', () {
      final layout = LayoutConst.compactIntU32(property: 'v');
      expect(listEquals(layout.serialize(0), [0x00]), isTrue);
      expect(listEquals(layout.serialize(63), [0xFC]), isTrue);
      expect(listEquals(layout.serialize(64), [0x01, 0x01]), isTrue);
      expect(listEquals(layout.serialize(16383), [0xFD, 0xFF]), isTrue);
      expect(
        listEquals(layout.serialize(16384), [0x02, 0x00, 0x01, 0x00]),
        isTrue,
      );
      for (final v in [0, 1, 63, 64, 1000, 16383, 16384, 1073741823]) {
        final decoded = layout.deserialize(layout.serialize(v));
        expect(decoded.value, v);
      }
    });

    test('compact int validates width on encode and decode', () {
      final layout = LayoutConst.compactIntU32(property: 'v');
      expect(
        () => layout.serialize(0x100000000),
        throwsA(isA<BuError>()),
      );
      expect(
        () => layout.deserialize(
          LayoutConst.compactIntU48(property: 'x').serialize(0x100000000),
        ),
        throwsA(isA<BuError>()),
      );
    });

    test('compactBigintU64 large values', () {
      final layout = LayoutConst.compactBigintU64(property: 'v');
      final big = BigInt.parse('18446744073709551615');
      expect(layout.deserialize(layout.serialize(big)).value, big);
      expect(
        layout.deserialize(layout.serialize(BigInt.zero)).value,
        BigInt.zero,
      );
      expect(
        () => layout.serialize(BigInt.one << 64),
        throwsA(isA<BuError>()),
      );
    });

    test('compactBigintU128 and compactIntU48', () {
      final u128 = LayoutConst.compactBigintU128(property: 'v');
      final big = (BigInt.one << 120) + BigInt.from(7);
      expect(u128.deserialize(u128.serialize(big)).value, big);
      final u48 = LayoutConst.compactIntU48(property: 'v');
      expect(
        u48.deserialize(u48.serialize(0xFFFFFFFFFFFF)).value,
        0xFFFFFFFFFFFF,
      );
    });
  });

  group('Varint integers', () {
    test('varintU32Le bitcoin vectors', () {
      final layout = LayoutConst.varintU32Le(property: 'v');
      expect(listEquals(layout.serialize(252), [252]), isTrue);
      expect(listEquals(layout.serialize(253), [0xFD, 0xFD, 0x00]), isTrue);
      expect(listEquals(layout.serialize(0xFFFF), [0xFD, 0xFF, 0xFF]), isTrue);
      expect(
        listEquals(layout.serialize(0x10000), [0xFE, 0x00, 0x00, 0x01, 0x00]),
        isTrue,
      );
      for (final v in [0, 1, 252, 253, 0xFFFF, 0x10000, 0xFFFFFFFF]) {
        expect(layout.deserialize(layout.serialize(v)).value, v);
      }
    });

    test('varint rejects overflow and negatives', () {
      final layout = LayoutConst.varintU32Le(property: 'v');
      expect(
        () => layout.serialize(0x100000000),
        throwsA(isA<BuError>()),
      );
      expect(() => layout.serialize(-1), throwsA(isA<BuError>()));
    });

    test('varintU32Be roundtrip', () {
      final layout = LayoutConst.varintU32Be(property: 'v');
      expect(layout.deserialize(layout.serialize(100000)).value, 100000);
    });
  });

  group('NatLayout and ZarithIntLayout', () {
    test('nat roundtrip incl. multi-byte', () {
      const layout = NatLayout(property: 'v');
      for (final v in [
        BigInt.zero,
        BigInt.one,
        BigInt.from(127),
        BigInt.from(128),
        BigInt.from(300),
        BigInt.from(624485),
        BigInt.one << 100,
      ]) {
        expect(
          layout.deserialize(layout.serialize(v)).value,
          v,
          reason: 'nat $v',
        );
      }
      expect(
        listEquals(layout.serialize(BigInt.from(300)), [0xAC, 0x02]),
        isTrue,
      );
    });

    test('nat rejects negatives', () {
      const layout = NatLayout(property: 'v');
      expect(
        () => layout.serialize(BigInt.from(-1)),
        throwsA(isA<BuError>()),
      );
    });

    test('zarith vectors', () {
      const layout = ZarithIntLayout(property: 'v');
      expect(listEquals(layout.serialize(BigInt.zero), [0x00]), isTrue);
      expect(listEquals(layout.serialize(BigInt.one), [0x01]), isTrue);
      expect(listEquals(layout.serialize(BigInt.from(63)), [0x3F]), isTrue);
      expect(
        listEquals(layout.serialize(BigInt.from(64)), [0x80, 0x01]),
        isTrue,
      );
      expect(listEquals(layout.serialize(BigInt.from(-1)), [0x41]), isTrue);
      expect(
        listEquals(layout.serialize(BigInt.from(-64)), [0xC0, 0x01]),
        isTrue,
      );
      for (final v in [
        BigInt.zero,
        BigInt.one,
        BigInt.from(-1),
        BigInt.from(64),
        BigInt.from(-64),
        BigInt.from(1000),
        BigInt.from(-1000),
        BigInt.one << 70,
        -(BigInt.one << 70),
      ]) {
        expect(
          layout.deserialize(layout.serialize(v)).value,
          v,
          reason: 'zarith $v',
        );
      }
    });
  });

  group('GreedyCount and OffsetLayout', () {
    test('greedy counts remaining elements', () {
      final layout = LayoutConst.greedy(elementSpan: 2, property: 'c');
      final reader = LayoutByteReader([1, 2, 3, 4, 5, 6]);
      final decoded = layout.decode(reader);
      expect(decoded.value, 3);
      expect(decoded.consumed, 0);
      expect(layout.encode(3, LayoutByteWriter(-1)), 0);
    });

    test('greedy rejects negative element span', () {
      expect(() => GreedyCount(-1), throwsA(isA<BuError>()));
    });

    test('offset layout delegates with shift', () {
      final inner = LayoutConst.padding(
        LayoutConst.u32(property: 'n'),
        property: 'n',
      );
      final layout = LayoutConst.offset(inner, -4, property: 'o');
      final writer = LayoutByteWriter(8);
      // Simulates vecU8-style back-references: length lives 4 bytes back.
      writer.setAll(0, [10, 0, 0, 0, 1, 2, 3, 4]);
      final reader = LayoutByteReader(writer.toBytes());
      expect(layout.decode(reader, offset: 4).value, 10);
    });
  });
}

void layoutStructTupleSeqTest() {
  group('StructLayout', () {
    test('fixed struct roundtrip and span', () {
      final layout = LayoutConst.struct([
        LayoutConst.u8(property: 'a'),
        LayoutConst.u16(property: 'b'),
        LayoutConst.u32(property: 'c'),
      ], property: 's');
      expect(layout.span, 7);
      final bytes = layout.serialize({'a': 1, 'b': 0x0203, 'c': 0x04050607});
      expect(bytes.length, 7);
      final decoded = layout.deserialize(bytes).value;
      expect(decoded, {'a': 1, 'b': 0x0203, 'c': 0x04050607});
    });

    test('missing field throws LayoutException', () {
      final layout = LayoutConst.struct([
        LayoutConst.u8(property: 'a'),
      ], property: 's');
      expect(() => layout.serialize({}), throwsA(isA<BuError>()));
    });

    test('unnamed field is rejected', () {
      expect(
        () => LayoutConst.struct([LayoutConst.u8()]),
        throwsA(isA<BuError>()),
      );
    });

    test('variable struct has negative span', () {
      final layout = LayoutConst.struct([
        LayoutConst.u8(property: 'a'),
        LayoutConst.compactBytes(property: 'b'),
      ], property: 's');
      expect(layout.span, -1);
      final decoded =
          layout
              .deserialize(
                layout.serialize({
                  'a': 9,
                  'b': [1, 2, 3],
                }),
              )
              .value;
      expect(decoded['a'], 9);
      expect(decoded['b'], [1, 2, 3]);
    });

    test('empty struct roundtrip', () {
      final layout = LayoutConst.noArgs(property: 's');
      expect(layout.span, 0);
      final bytes = layout.serialize({});
      expect(bytes.length, 0);
      expect(layout.deserialize(bytes).value, isEmpty);
    });

    test('clone renames property', () {
      final layout = LayoutConst.struct([
        LayoutConst.u8(property: 'a'),
      ], property: 's');
      final cloned = layout.clone(newProperty: 's2');
      expect(cloned.property, 's2');
      expect(cloned.fields.length, 1);
    });
  });

  group('ObjSeqLayout', () {
    test('object sequence roundtrip', () {
      final layout = ObjSeqLayout<List<int>>(
        [LayoutConst.u8(), LayoutConst.u8()],
        build: (v) => [v[0] as int, v[1] as int],
        unbuild: (v) => v,
        property: 'o',
      );
      final bytes = layout.serialize([3, 4]);
      expect(listEquals(bytes, [3, 4]), isTrue);
      expect(layout.deserialize(bytes).value, [3, 4]);
    });
  });

  group('TupleLayout', () {
    test('heterogeneous roundtrip', () {
      final layout = LayoutConst.tuple([
        LayoutConst.u8(),
        LayoutConst.u16(),
        LayoutConst.compactString(),
      ], property: 't');
      final bytes = layout.serialize([7, 0x1234, 'hi']);
      final decoded = layout.deserialize(bytes).value;
      expect(decoded, [7, 0x1234, 'hi']);
    });

    test('length mismatch throws', () {
      final layout = LayoutConst.tuple([
        LayoutConst.u8(),
        LayoutConst.u8(),
      ], property: 't');
      expect(() => layout.serialize([1]), throwsA(isA<BuError>()));
      expect(
        () => layout.serialize([1, 2, 3]),
        throwsA(isA<BuError>()),
      );
    });

    test('getSpan fixed and variable', () {
      expect(
        LayoutConst.tuple([LayoutConst.u8(), LayoutConst.u16()]).getSpan(),
        3,
      );
      expect(
        LayoutConst.tuple([
          LayoutConst.u8(),
          LayoutConst.compactBytes(),
        ]).getSpan(),
        -1,
      );
    });
  });

  group('SequenceLayout', () {
    test('fixed count roundtrip', () {
      final layout = LayoutConst.seq(
        LayoutConst.u8(),
        const ConstantLayout<int>(3),
        property: 'v',
      );
      final bytes = layout.serialize([1, 2, 3]);
      expect(listEquals(bytes, [1, 2, 3]), isTrue);
      expect(layout.deserialize(bytes).value, [1, 2, 3]);
      expect(layout.getSpan(), 3);
    });

    test('counted by prefix offset (vecU8 style)', () {
      final layout = LayoutConst.vecU8(property: 'v');
      for (final data in [
        <int>[],
        [1],
        [1, 2, 3, 4, 5],
      ]) {
        final decoded = layout.deserialize(layout.serialize(data)).value;
        expect(decoded, data);
      }
    });

    test('greedy consumes remainder', () {
      final layout = LayoutConst.greedyArray(LayoutConst.u16(), property: 'v');
      final bytes = layout.serialize([0x1234, 0x5678]);
      expect(bytes.length, 4);
      expect(layout.deserialize(bytes).value, [0x1234, 0x5678]);
    });

    test('dynamic vector consumes remainder', () {
      final layout = LayoutConst.dynamicVector(LayoutConst.u8(), property: 'v');
      final decoded = layout.deserialize([9, 8, 7]).value;
      expect(decoded, [9, 8, 7]);
      expect(layout.deserialize(layout.serialize([1, 2])).value, [1, 2]);
    });

    test('invalid count layout is rejected', () {
      expect(
        () => SequenceLayout(
          elementLayout: LayoutConst.u8(),
          count: LayoutConst.u8(),
        ),
        throwsA(isA<BuError>()),
      );
    });

    test('zero-progress element throws instead of hanging', () {
      final layout = SequenceLayout(
        elementLayout: const NoneLayout(),
        property: 'v',
      );
      expect(
        () => layout.deserialize([1, 2, 3]),
        throwsA(isA<BuError>()),
      );
      final remainder = RemainderListLayout<int?>(NoneLayout<int>());
      expect(() => remainder.deserialize([1]), throwsA(isA<BuError>()));
    });
  });

  group('RemainderListLayout', () {
    test('roundtrip incl. empty', () {
      final layout = RemainderListLayout<int>(IntegerLayout(1));
      expect(layout.deserialize(layout.serialize([4, 5, 6])).value, [4, 5, 6]);
      expect(layout.deserialize([]).value, isEmpty);
    });
  });
}

void layoutBytesTest() {
  group('RawBytesLayout', () {
    test('fixed blob roundtrip', () {
      final layout = LayoutConst.blob(4, property: 'b');
      final bytes = layout.serialize([1, 2, 3, 4]);
      expect(listEquals(bytes, [1, 2, 3, 4]), isTrue);
      final decoded = layout.deserialize(bytes);
      expect(decoded.value, [1, 2, 3, 4]);
      expect(decoded.consumed, 4);
    });

    test('length mismatch throws LayoutException', () {
      final layout = LayoutConst.blob(4, property: 'b');
      expect(() => layout.serialize([1, 2]), throwsA(isA<BuError>()));
    });

    test('negative and invalid lengths rejected', () {
      expect(() => LayoutConst.blob(-1), throwsA(isA<BuError>()));
      expect(() => RawBytesLayout('nope'), throwsA(isA<BuError>()));
    });

    test('fixedBlob32 span', () {
      expect(LayoutConst.fixedBlob32(property: 'b').span, 32);
      expect(LayoutConst.fixedBlobN(10, property: 'b').span, 10);
    });

    test('external length prefix roundtrip', () {
      final layout = LayoutConst.vecU8(property: 'v');
      final decoded = layout.deserialize(layout.serialize([9, 9, 9]));
      expect(decoded.value, [9, 9, 9]);
    });
  });

  group('RawTailLayout', () {
    test('captures tail', () {
      const layout = RawTailLayout(property: 't');
      final decoded = layout.deserialize([1, 2, 3, 4]);
      expect(decoded.value, [1, 2, 3, 4]);
      expect(decoded.consumed, 4);
      expect(listEquals(layout.serialize([7, 8]), [7, 8]), isTrue);
    });
  });

  group('DynamicBytesLayout', () {
    test('u32be length-prefixed roundtrip', () {
      const layout = DynamicBytesLayout(property: 'd');
      final bytes = layout.serialize([1, 2, 3]);
      expect(listEquals(bytes, [0, 0, 0, 3, 1, 2, 3]), isTrue);
      final decoded = layout.deserialize(bytes);
      expect(decoded.value, [1, 2, 3]);
      expect(decoded.consumed, 7);
    });
  });

  group('DynamicSizeLayout', () {
    test('inner must consume exactly the declared payload', () {
      final layout = DynamicSizeLayout(
        LayoutConst.u8(property: 'a'),
        property: 'd',
      );
      final bytes = layout.serialize(0xAB);
      expect(listEquals(bytes, [0, 0, 0, 1, 0xAB]), isTrue);
      expect(layout.deserialize(bytes).value, 0xAB);
      // Declared 2 payload bytes but only 1 meaningful byte: trailing
      // garbage must fail instead of being silently accepted.
      expect(
        () => layout.deserialize([0, 0, 0, 2, 0xAB, 0x00]),
        throwsA(isA<BuError>()),
      );
    });

    test('clone keeps custom discriminator', () {
      const disc = IntegerLayout.u32Be();
      final layout = DynamicSizeLayout(
        LayoutConst.u8(property: 'a'),
        discriminator: disc,
        property: 'd',
      );
      final cloned = layout.clone(newProperty: 'd2');
      expect(cloned.property, 'd2');
      expect(cloned.discriminator.span, 4);
    });
  });

  group('CompactBytes and CompactString', () {
    test('compactBytes roundtrip', () {
      final layout = LayoutConst.bytes(property: 'b');
      for (final data in [
        <int>[],
        [1, 2, 3],
        List<int>.filled(100, 7),
      ]) {
        expect(layout.deserialize(layout.serialize(data)).value, data);
      }
    });

    test('compactString unicode roundtrip', () {
      final layout = LayoutConst.compactString(property: 's');
      const text = 'hello wörld 🌍';
      expect(layout.deserialize(layout.serialize(text)).value, text);
      expect(layout.deserialize(layout.serialize('')).value, isEmpty);
    });

    test('compactVec roundtrip', () {
      final layout = LayoutConst.compactVec(LayoutConst.u16(), property: 'v');
      final data = [1, 300, 0xFFFF];
      expect(layout.deserialize(layout.serialize(data)).value, data);
      expect(layout.deserialize(layout.serialize(<int>[])).value, isEmpty);
    });

    test('compactMap roundtrip', () {
      final layout = LayoutConst.compactMap(
        LayoutConst.u8(),
        LayoutConst.u16(),
        property: 'm',
      );
      final data = {1: 100, 2: 200};
      expect(layout.deserialize(layout.serialize(data)).value, data);
    });

    test('bitSequence byte-aligned roundtrip', () {
      final layout = LayoutConst.bitSequenceLayout(property: 'b');
      final data = [0xAA, 0xBB];
      final bytes = layout.serialize(data);
      // Wire length is a bit count: 2 bytes -> 16.
      expect(bytes.first, 0x40);
      expect(layout.deserialize(bytes).value, data);
    });
  });

  group('XDRBytesLayout', () {
    test('pads payload to 4 bytes', () {
      final layout = XDRBytesLayout(3, property: 'x');
      final bytes = layout.serialize([1, 2, 3]);
      expect(listEquals(bytes, [1, 2, 3, 0]), isTrue);
      final decoded = layout.deserialize(bytes);
      expect(decoded.value, [1, 2, 3]);
      expect(decoded.consumed, 4);
    });

    test('already-aligned payload has no padding', () {
      final layout = XDRBytesLayout(4, property: 'x');
      final bytes = layout.serialize([1, 2, 3, 4]);
      expect(bytes.length, 4);
      expect(layout.deserialize(bytes).value, [1, 2, 3, 4]);
    });

    test('invalid lengths rejected with owning operation name', () {
      expect(() => XDRBytesLayout(-1), throwsA(isA<BuError>()));
      try {
        XDRBytesLayout(-1);
        fail('expected ArgumentException');
      } catch (e) {
        expect(e.toString(), contains('XDRBytesLayout'));
      }
    });

    test('xdrVecBytes pads via struct helper', () {
      final layout = LayoutConst.xdrVecBytes(property: 'x');
      final bytes = layout.serialize([1, 2, 3]);
      expect(bytes.length, 4 + 4);
      expect(layout.deserialize(bytes).value, [1, 2, 3]);
    });

    test('xdrString unicode roundtrip', () {
      final layout = LayoutConst.xdrString(property: 'x');
      const text = 'héllo';
      expect(layout.deserialize(layout.serialize(text)).value, text);
    });

    test('xdrVec of u32 roundtrip', () {
      final layout = LayoutConst.xdrVec(LayoutConst.u32be(), property: 'x');
      final data = [1, 2, 0xFFFFFFFF];
      expect(layout.deserialize(layout.serialize(data)).value, data);
    });
  });
}

void layoutOptionUnionTest() {
  group('OptionalLayout', () {
    test('some/none roundtrip', () {
      final layout = LayoutConst.optional(
        LayoutConst.u8(property: 'v'),
        property: 'o',
      );
      expect(listEquals(layout.serialize(null), [0]), isTrue);
      expect(listEquals(layout.serialize(7), [1, 7]), isTrue);
      expect(layout.deserialize([0]).value, isNull);
      final some = layout.deserialize([1, 7]);
      expect(some.value, 7);
      expect(some.consumed, 2);
    });

    test('invalid flag throws', () {
      final layout = LayoutConst.optional(
        LayoutConst.u8(property: 'v'),
        property: 'o',
      );
      expect(() => layout.deserialize([9]), throwsA(isA<BuError>()));
    });

    test('keepLayoutSize pads none to fixed size', () {
      final layout = LayoutConst.optional(
        LayoutConst.u32(property: 'v'),
        property: 'o',
        keepSize: true,
      );
      expect(layout.getSpan(), 5);
      final none = layout.deserialize([0, 9, 9, 9, 9]);
      expect(none.value, isNull);
      expect(none.consumed, 5);
      final some = layout.deserialize(layout.serialize(0x12345678));
      expect(some.value, 0x12345678);
      expect(some.consumed, 5);
      final noneBytes = layout.serialize(null);
      expect(noneBytes.length, 5);
      expect(layout.deserialize(noneBytes).value, isNull);
    });

    test('keepLayoutSize needs fixed inner span', () {
      expect(
        () => LayoutConst.optional(
          LayoutConst.compactBytes(property: 'v'),
          property: 'o',
          keepSize: true,
        ),
        throwsA(isA<BuError>()),
      );
    });

    test('optionalU32Be and optionalVarint', () {
      final be = LayoutConst.optionalU32Be(
        LayoutConst.u8(property: 'v'),
        property: 'o',
      );
      expect(be.deserialize(be.serialize(3)).value, 3);
      expect(be.deserialize(be.serialize(null)).value, isNull);
      final vv = LayoutConst.optionalVarint(
        LayoutConst.u16(property: 'v'),
        property: 'o',
      );
      expect(vv.deserialize(vv.serialize(300)).value, 300);
      expect(vv.deserialize(vv.serialize(null)).value, isNull);
    });

    test('custom flags', () {
      final layout = OptionalLayout(
        LayoutConst.u8(property: 'v'),
        noneFlag: 0xAA,
        someFlag: 0xBB,
        property: 'o',
      );
      expect(listEquals(layout.serialize(null), [0xAA]), isTrue);
      expect(layout.deserialize([0xBB, 5]).value, 5);
    });
  });

  group('COptionLayout', () {
    test('some/none roundtrip', () {
      final layout = COptionLayout(
        LayoutConst.u16(property: 'v'),
        property: 'c',
      );
      expect(listEquals(layout.serialize(null), [0]), isTrue);
      expect(listEquals(layout.serialize(0x1234), [1, 0x34, 0x12]), isTrue);
      expect(layout.deserialize([0]).value, isNull);
      expect(layout.deserialize([1, 0x34, 0x12]).value, 0x1234);
    });

    test('invalid discriminator throws', () {
      final layout = COptionLayout(
        LayoutConst.u16(property: 'v'),
        property: 'c',
      );
      expect(() => layout.deserialize([7]), throwsA(isA<BuError>()));
    });

    test('getSpan accounts discriminator', () {
      expect(COptionLayout(LayoutConst.u16(property: 'v')).getSpan(), 3);
      expect(
        COptionLayout(LayoutConst.compactBytes(property: 'v')).getSpan(),
        -1,
      );
    });
  });

  group('ConstantLayout and NoneLayout', () {
    test('constant takes no bytes', () {
      const layout = ConstantLayout<int>(42, property: 'c');
      expect(layout.span, 0);
      final decoded = layout.deserialize([9, 9]);
      expect(decoded.value, 42);
      expect(decoded.consumed, 0);
      expect(layout.encode(42, LayoutByteWriter(0)), 0);
    });

    test('none always null', () {
      final layout = LayoutConst.none<int>(property: 'n');
      expect(layout.getSpan(), 0);
      expect(layout.deserialize([1, 2]).value, isNull);
      expect(layout.encode(null, LayoutByteWriter(0)), 0);
    });
  });

  group('Union', () {
    Layout<Map<String, dynamic>> buildUnion() {
      final union = LayoutConst.union(LayoutConst.u8(), property: 'u');
      union.addVariant(variant: 0, layout: LayoutConst.u8(property: 'a'));
      union.addVariant(variant: 1, layout: LayoutConst.u16(property: 'b'));
      return union;
    }

    test('variant roundtrips', () {
      final union = buildUnion();
      expect(listEquals(union.serialize({'a': 5}), [0, 5]), isTrue);
      expect(
        listEquals(union.serialize({'b': 0x1234}), [1, 0x34, 0x12]),
        isTrue,
      );
      expect(union.deserialize([0, 5]).value, {'a': 5});
      expect(union.deserialize([1, 0x34, 0x12]).value, {'b': 0x1234});
    });

    test('unknown tag throws LayoutException', () {
      final union = buildUnion();
      expect(() => union.deserialize([7]), throwsA(isA<BuError>()));
    });

    test('unregistered variant name throws', () {
      final union = buildUnion();
      expect(
        () => union.serialize({'zzz': 1}),
        throwsA(isA<BuError>()),
      );
    });

    test('signed discriminator rejected', () {
      expect(
        () => LayoutConst.union(LayoutConst.i8()),
        throwsA(isA<BuError>()),
      );
      expect(
        () => LayoutConst.union(LayoutConst.compactString()),
        throwsA(isA<BuError>()),
      );
    });

    test('addVariant falls back to layout property', () {
      final union = LayoutConst.union(LayoutConst.u8(), property: 'u');
      union.addVariant(variant: 3, layout: LayoutConst.u8(property: 'auto'));
      expect(listEquals(union.serialize({'auto': 9}), [3, 9]), isTrue);
      expect(union.deserialize([3, 9]).value, {'auto': 9});
    });
  });

  group('TaggedUnionLayout', () {
    test('tag dispatch roundtrip', () {
      final layout = TaggedUnionLayout<List<int>>(
        tagLayout: LayoutConst.u8(),
        cases: [
          UnionCase(0, LayoutConst.blob(2)),
          UnionCase(1, LayoutConst.blob(3)),
        ],
        tagFor: (v) => v.length == 2 ? 0 : 1,
        property: 't',
      );
      expect(listEquals(layout.serialize([1, 2]), [0, 1, 2]), isTrue);
      expect(layout.deserialize([1, 9, 8, 7]).value, [9, 8, 7]);
    });

    test('unknown tag throws on both paths', () {
      final layout = TaggedUnionLayout<List<int>>(
        tagLayout: LayoutConst.u8(),
        cases: [UnionCase(0, LayoutConst.blob(2))],
        tagFor: (v) => v.length,
        property: 't',
      );
      expect(
        () => layout.deserialize([5, 1, 2]),
        throwsA(isA<BuError>()),
      );
      expect(
        () => layout.serialize([1, 2, 3]),
        throwsA(isA<BuError>()),
      );
    });
  });

  group('LazyUnion', () {
    LazyUnion buildLazy() {
      return LazyUnion(
        discr: LayoutConst.u8(),
        variants: [
          LazyVariantModel(
            layout: ({property}) => LayoutConst.u8(property: property),
            property: 'a',
            index: 0,
          ),
          LazyVariantModel(
            layout: ({property}) => LayoutConst.u16(property: property),
            property: 'b',
            index: 1,
          ),
        ],
        property: 'u',
      );
    }

    test('variant roundtrips', () {
      final union = buildLazy();
      expect(listEquals(union.serialize({'a': 5}), [0, 5]), isTrue);
      expect(
        listEquals(union.serialize({'b': 0x1234}), [1, 0x34, 0x12]),
        isTrue,
      );
      expect(union.deserialize([0, 5]).value, {'a': 5});
      expect(union.deserialize([1, 0x34, 0x12]).value, {'b': 0x1234});
    });

    test('default variant handles unknown tags', () {
      final union = LazyUnion(
        discr: LayoutConst.u8(),
        variants: [
          LazyVariantModel(
            layout: ({property}) => LayoutConst.u8(property: property),
            property: 'a',
            index: 0,
          ),
          LazyVariantModel(
            layout: ({property}) => LayoutConst.u8(property: property),
            property: 'fallback',
            index: null,
          ),
        ],
        property: 'u',
      );
      expect(union.deserialize([9, 0xAB]).value, {'fallback': 0xAB});
      expect(union.deserialize([0, 1]).value, {'a': 1});
    });

    test('duplicate index rejected and unknown encode throws', () {
      expect(
        () => LazyUnion(
          discr: LayoutConst.u8(),
          variants: [
            LazyVariantModel(
              layout: ({property}) => LayoutConst.u8(property: property),
              property: 'a',
              index: 0,
            ),
            LazyVariantModel(
              layout: ({property}) => LayoutConst.u8(property: property),
              property: 'b',
              index: 0,
            ),
          ],
        ),
        throwsA(isA<BuError>()),
      );
      expect(
        () => buildLazy().serialize({'zzz': 1}),
        throwsA(isA<BuError>()),
      );
    });

    test('missing index resolver throws', () {
      final model = LazyVariantModel(
        layout: ({property}) => LayoutConst.u8(property: property),
        property: 'a',
        index: null,
      );
      expect(() => model.getIndex({}), throwsA(isA<BuError>()));
    });
  });

  group('LazyStructLayout', () {
    test('later field reads earlier length', () {
      final layout = LayoutConst.lazyStruct([
        LazyStructLayoutBuilder<int, LayoutRepository>(
          layout: (property, params) => LayoutConst.u8(property: property),
          property: 'len',
        ),
        LazyStructLayoutBuilder<List<int>, LayoutRepository>(
          layout: (property, params) {
            final len = (params.sourceOrResult['len'] as int?) ?? 0;
            return LayoutConst.blob(len, property: property);
          },
          property: 'data',
        ),
      ], property: 's');
      final bytes = layout.serialize({
        'len': 3,
        'data': [7, 8, 9],
      });
      expect(listEquals(bytes, [3, 7, 8, 9]), isTrue);
      expect(layout.deserialize(bytes).value, {
        'len': 3,
        'data': [7, 8, 9],
      });
    });

    test('unnamed builder rejected with owning operation', () {
      try {
        LayoutConst.lazyStruct([
          LazyStructLayoutBuilder<int, LayoutRepository>(
            layout: (property, params) => LayoutConst.u8(property: property),
            property: null,
          ),
        ]);
        fail('expected ArgumentException');
      } catch (e) {
        expect(e, isA<BuError>());
        expect(e.toString(), contains('LazyStructLayout'));
      }
    });

    test('null layout builder throws LayoutException', () {
      final layout = LayoutConst.lazyStruct([
        LazyStructLayoutBuilder<int, LayoutRepository>(
          layout: (property, params) => null,
          property: 'missing',
        ),
      ], property: 's');
      expect(() => layout.deserialize([1]), throwsA(isA<BuError>()));
    });

    test('finalize hooks run', () {
      var decodedHook = 0;
      var encodedHook = 0;
      final layout = LayoutConst.lazyStruct([
        LazyStructLayoutBuilder<int, LayoutRepository>(
          layout: (property, params) => LayoutConst.u8(property: property),
          property: 'v',
          finalizeDecode: (result, struct, repo) {
            decodedHook++;
            return result * 2;
          },
          finalizeEncode: (source, struct, repo) {
            encodedHook++;
          },
        ),
      ], property: 's');
      expect(layout.deserialize([21]).value, {'v': 42});
      expect(decodedHook, 1);
      layout.serialize({'v': 1});
      expect(encodedHook, 1);
    });
  });
}

void layoutFactoriesTest() {
  group('LayoutConst vectors and strings', () {
    test('vec with u16 elements', () {
      final layout = LayoutConst.vec(LayoutConst.u16(), property: 'v');
      final data = [1, 0x1234, 0xFFFF];
      expect(layout.deserialize(layout.serialize(data)).value, data);
      expect(layout.deserialize(layout.serialize(<int>[])).value, isEmpty);
    });

    test('rustVec 8-byte header', () {
      final layout = LayoutConst.rustVec(LayoutConst.u8(), property: 'v');
      final bytes = layout.serialize([1, 2]);
      expect(bytes.length, 4 + 4 + 2);
      expect(layout.deserialize(bytes).value, [1, 2]);
    });

    test('rustVecU8 header', () {
      final layout = LayoutConst.rustVecU8(property: 'v');
      final bytes = layout.serialize([5, 6, 7]);
      expect(bytes.length, 8 + 3);
      expect(layout.deserialize(bytes).value, [5, 6, 7]);
    });

    test('string and rustString unicode', () {
      for (final layout in [
        LayoutConst.string(property: 's'),
        LayoutConst.rustString(property: 's'),
      ]) {
        const text = 'héllo wörld';
        expect(layout.deserialize(layout.serialize(text)).value, text);
      }
    });

    test('byteArray fixed with hex mode', () {
      final raw = LayoutConst.byteArray(3, property: 'b');
      expect(raw.deserialize(raw.serialize([1, 2, 3])).value, [1, 2, 3]);
      final hex = LayoutConst.byteArray(3, resultAsHex: true, property: 'b');
      expect(hex.deserialize(hex.serialize('010203')).value, '010203');
    });

    test('array of u32', () {
      final layout = LayoutConst.array(LayoutConst.u32(), 2, property: 'a');
      final data = [1, 2];
      expect(layout.deserialize(layout.serialize(data)).value, data);
    });

    test('map string->int', () {
      final layout = LayoutConst.map(
        LayoutConst.compactString(),
        LayoutConst.compactIntU32(),
        property: 'm',
      );
      final data = {'a': 1, 'bb': 300};
      expect(layout.deserialize(layout.serialize(data)).value, data);
    });

    test('bcsMap roundtrip', () {
      final layout = LayoutConst.bcsMap(
        LayoutConst.u8(),
        LayoutConst.u16(),
        property: 'm',
      );
      final data = {1: 100, 2: 0xFFFF};
      expect(layout.deserialize(layout.serialize(data)).value, data);
    });

    test('bcs string/bytes/vector', () {
      final s = LayoutConst.bcsString(property: 's');
      expect(s.deserialize(s.serialize('héllo')).value, 'héllo');
      final b = LayoutConst.bcsBytes(property: 'b');
      expect(
        b.deserialize(b.serialize(List<int>.filled(300, 9))).value,
        List<int>.filled(300, 9),
      );
      final v = LayoutConst.bcsVector(LayoutConst.u32(), property: 'v');
      expect(v.deserialize(v.serialize([1, 2, 3])).value, [1, 2, 3]);
    });

    test('varintVector roundtrip', () {
      final layout = LayoutConst.varintVector(LayoutConst.u8(), property: 'v');
      final data = List<int>.generate(300, (i) => i % 256);
      expect(layout.deserialize(layout.serialize(data)).value, data);
    });
  });

  group('LayoutConst enums and unions', () {
    test('rustEnum two variants', () {
      final layout = LayoutConst.rustEnum([
        LayoutConst.u8(property: 'a'),
        LayoutConst.u16(property: 'b'),
      ], property: 'e');
      expect(listEquals(layout.serialize({'a': 5}), [0, 5]), isTrue);
      expect(unionDecode(layout, [1, 0x34, 0x12]), {
        'key': 'b',
        'value': 0x1234,
      });
    });

    test('enum32Be big-endian discriminant', () {
      final layout = LayoutConst.enum32Be([
        LayoutConst.u8(property: 'a'),
        LayoutConst.u8(property: 'b'),
      ], property: 'e');
      final bytes = layout.serialize({'b': 9});
      expect(bytes.sublist(0, 4), [0, 0, 0, 1]);
      expect(layout.deserialize(bytes).value, {'key': 'b', 'value': 9});
    });

    test('lazyEnum dispatches on builder', () {
      final layout = LayoutConst.lazyEnum([
        LazyVariantModel(
          layout: ({property}) => LayoutConst.u8(property: property),
          property: 'a',
          index: 0,
        ),
        LazyVariantModel(
          layout: ({property}) => LayoutConst.u16(property: property),
          property: 'b',
          index: 1,
        ),
      ], property: 'e');
      expect(listEquals(layout.serialize({'a': 1}), [0, 1]), isTrue);
      expect(layout.deserialize([1, 0x34, 0x12]).value, {
        'key': 'b',
        'value': 0x1234,
      });
    });

    test('bcsLazyEnum and varintLazyEnum', () {
      List<LazyVariantModel> variants() => [
        LazyVariantModel(
          layout: ({property}) => LayoutConst.u8(property: property),
          property: 'a',
          index: 0,
        ),
        LazyVariantModel(
          layout: ({property}) => LayoutConst.u8(property: property),
          property: 'b',
          index: 1,
        ),
      ];
      final bcs = LayoutConst.bcsLazyEnum(variants(), property: 'e');
      expect(bcs.deserialize(bcs.serialize({'a': 7})).value, {
        'key': 'a',
        'value': 7,
      });
      final vv = LayoutConst.varintLazyEnum(variants(), property: 'e');
      expect(vv.deserialize(vv.serialize({'b': 8})).value, {
        'key': 'b',
        'value': 8,
      });
    });
  });

  group('LayoutConst misc', () {
    test('boolean strict values', () {
      final layout = LayoutConst.boolean(property: 'b');
      expect(listEquals(layout.serialize(true), [1]), isTrue);
      expect(listEquals(layout.serialize(false), [0]), isTrue);
      expect(layout.deserialize([1]).value, isTrue);
      expect(() => layout.deserialize([7]), throwsA(isA<BuError>()));
      expect(LayoutConst.boolean32(property: 'b').span, 4);
      expect(LayoutConst.boolean32Be(property: 'b').span, 4);
    });

    test('none/wrap/constant/tuple/noArgs', () {
      expect(
        LayoutConst.none<int>(property: 'n').deserialize([]).value,
        isNull,
      );
      final wrapped = LayoutConst.wrap(
        LayoutConst.u8(property: 'v'),
        property: 'w',
      );
      expect(wrapped.deserialize(wrapped.serialize(9)).value, 9);
      expect(LayoutConst.constant(7, property: 'c').deserialize([]).value, 7);
      expect(LayoutConst.noArgs(property: 'n').span, 0);
    });

    test('leb helpers', () {
      for (final layout in [
        LayoutConst.lebU32(property: 'v'),
        LayoutConst.lebU48(property: 'v'),
      ]) {
        expect(layout.deserialize(layout.serialize(624485)).value, 624485);
      }
      final u64 = LayoutConst.lebU64(property: 'v');
      final big = BigInt.parse('18446744073709551615');
      expect(u64.deserialize(u64.serialize(big)).value, big);
      final i128 = LayoutConst.lebI128(property: 'v');
      expect(
        i128.deserialize(i128.serialize(BigInt.from(-123456))).value,
        BigInt.from(-123456),
      );
    });

    test('lebBigInteger rejects bad validator', () {
      expect(
        () => LEBBigIntegerLayout(BigIntLayout(-1)),
        throwsA(isA<BuError>()),
      );
    });

    test('nameWithProperty', () {
      expect(
        LayoutConst.nameWithProperty('u8', LayoutConst.u8(property: 'a')),
        'u8[a]',
      );
      expect(LayoutConst.nameWithProperty('u8', LayoutConst.u8()), 'u8');
    });

    test('cOptionalPublicKey none/some', () {
      final layout = LayoutConst.cOptionalPublicKey(
        LayoutConst.u8(property: 'k'),
        property: 'c',
      );
      expect(layout.deserialize(layout.serialize(null)).value, isNull);
      expect(layout.deserialize(layout.serialize(9)).value, 9);
    });

    test('padding and seq helpers', () {
      final padded = LayoutConst.padding(
        LayoutConst.u16(property: 'p'),
        property: 'p',
      );
      expect(padded.span, 2);
      final seq = LayoutConst.seq(
        LayoutConst.u8(),
        LayoutConst.compactOffset(),
        property: 's',
      );
      expect(seq.deserialize(seq.serialize([1, 2])).value, [1, 2]);
    });

    test('bigint/int layout helpers', () {
      expect(LayoutConst.bigintLayout(8, property: 'v').span, 8);
      expect(LayoutConst.intLayout(3, property: 'v').span, 3);
      expect(LayoutConst.compactOffset(property: 'c').span, -1);
      expect(
        LayoutConst.varintOffset(LayoutConst.varintU32Be(), property: 'v').span,
        -1,
      );
      expect(LayoutConst.bcsOffset(property: 'b').span, -1);
    });
  });
}

Map<String, dynamic> unionDecode(Layout layout, List<int> bytes) {
  return layout.deserialize(bytes).value;
}

void layoutBufferSerializationTest() {
  group('LayoutByteReader/Writer', () {
    test('big-endian scalar reads', () {
      final reader = LayoutByteReader([0x12, 0x34, 0x00, 0x00, 0x00, 0x05]);
      expect(reader.getU8(0), 0x12);
      expect(reader.getU16Be(0), 0x1234);
      expect(reader.getU32Be(2), 5);
      expect(reader.length, 6);
      expect(reader.isEnd(6), isTrue);
      expect(reader.isEnd(5), isFalse);
      expect(reader.last, 5);
      expect(reader.at(0), 0x12);
    });

    test('u64be read', () {
      final reader = LayoutByteReader([0, 0, 0, 0, 0, 0, 0, 1]);
      expect(reader.getU64Be(0), BigInt.one);
    });

    test('scale/varint helpers', () {
      final reader = LayoutByteReader([0xFC, 0xFD, 0xFD, 0x00]);
      expect(reader.decodeScaleAsInteger(0).value, 63);
      expect(reader.getScaleLength(0), 1);
      expect(reader.decodeVarintAsInteger(1).value, 253);
      expect(reader.getVarintLength(0), 1);
      expect(reader.getVarintLength(1), 3);
      expect(LayoutByteReader([0xFE]).getVarintLength(0), 5);
      expect(LayoutByteReader([0xFF]).getVarintLength(0), 9);
    });

    test('oversized scale/varint reject int conversion', () {
      final bigScale = LayoutConst.compactBigintU64(
        property: 'v',
      ).serialize(BigInt.one << 62);
      final reader = LayoutByteReader(bigScale);
      expect(
        () => reader.decodeScaleAsInteger(0),
        throwsA(isA<BuError>()),
      );
      final bigVarint = LayoutSerializationUtils.encodeVarintBigInt(
        BigInt.one << 60,
      );
      final reader2 = LayoutByteReader(bigVarint);
      expect(
        () => reader2.decodeVarintAsInteger(0),
        throwsA(isA<BuError>()),
      );
    });

    test('writer grows and tracks', () {
      final writer = LayoutByteWriter(-1);
      expect(writer.growable, isTrue);
      writer.set(0, 0xAB);
      writer.setU16Be(1, 0x1234);
      writer.setU32Be(3, 0xDEADBEEF);
      writer.setU64Be(7, BigInt.one);
      writer.setI16Be(15, -2);
      writer.setI32Be(17, -3);
      writer.setI64Be(21, BigInt.from(-4));
      expect(writer.length, 29);
      expect(writer.at(0), 0xAB);
      expect(writer.last, 0xFC);
      expect(writer.toBytes().length, 29);
      expect(writer.sublist(0, 1).length, 1);
      expect(writer.reader.length, 29);
    });

    test('fixed writer zeroes and sublist', () {
      final layout = LayoutConst.u32(property: 'v');
      final bytes = layout.serialize(1);
      expect(bytes.length, 4);
      expect(LayoutConst.u8(property: 'v').serializeHex(0xAB), 'ab');
    });
  });

  group('Layout core', () {
    test('deserialize honors offset', () {
      final layout = LayoutConst.u16(property: 'v');
      final decoded = layout.deserialize([0xFF, 0x34, 0x12], offset: 1);
      expect(decoded.value, 0x1234);
      expect(decoded.consumed, 2);
    });

    test('truncated input throws LayoutException', () {
      final layout = LayoutConst.struct([
        LayoutConst.u32(property: 'a'),
        LayoutConst.u16(property: 'b'),
      ], property: 's');
      expect(() => layout.deserialize([1, 2]), throwsA(isA<BuError>()));
      expect(
        () => LayoutConst.u32(property: 'a').deserialize([1]),
        throwsA(isA<BuError>()),
      );
    });

    test('serializeHex prefix', () {
      expect(
        LayoutConst.u8(property: 'v').serializeHex(255, prefix: '0x'),
        '0xff',
      );
    });

    test('LayoutException is a BlockchainUtilsException', () {
      const e = BuError(DefaultErrorType.badLayout, 'nope');
      expect(e, isA<BuError>());
      expect(e.message, 'nope');
    });

    test('MapEntryLayout roundtrip', () {
      final layout = MapEntryLayout(
        keyLayout: LayoutConst.u8(),
        valueLayout: LayoutConst.u16(),
      );
      final entry =
          layout.deserialize(layout.serialize(const MapEntry(1, 0x1234))).value;
      expect(entry.key, 1);
      expect(entry.value, 0x1234);
      expect(layout.getSpan(), 3);
    });

    test('CustomLayout and ConvLayout', () {
      final custom = CustomLayout<String, int>(
        layout: LayoutConst.compactString(),
        decoder: (s) => s.length,
        encoder: (n) => List.filled(n, 'x').join(),
        property: 'c',
      );
      expect(custom.deserialize(custom.serialize(3)).value, 3);
      expect(custom.getSpan(), -1);
      final conv = ConvLayout<String, int>(
        LayoutConst.u8(),
        toWire: (s) => s.length,
        fromWire: (n) => List.filled(n, 'y').join(),
        property: 'c',
      );
      expect(conv.deserialize(conv.serialize('ab')).value, 'yy');
    });

    test('EmptyLayout clone honors new property', () {
      const layout = EmptyLayout<int>(7, property: 'a');
      final cloned = layout.clone(newProperty: 'b');
      expect(cloned.property, 'b');
      expect(cloned.decode(LayoutByteReader([])).value, 7);
      expect(layout.encode(7, LayoutByteWriter(0)), 0);
    });

    test('LazyLayout recursion', () {
      late Layout<List<int>> list;
      list = LazyLayout<List<int>>(
        () => LayoutConst.compactVec(LayoutConst.u8(), property: 'inner'),
      );
      expect(list.deserialize(list.serialize([1, 2])).value, [1, 2]);
    });

    test('LayoutSerializable mixin roundtrip', () {
      const obj = _TestPoint(3, 4);
      final bytes = obj.toSerializeBytes();
      final json = LayoutSerializable.deserialize(
        bytes: bytes,
        layout: _TestPoint.layout(),
      );
      expect(json, {'x': 3, 'y': 4});
    });

    test('VariantLayoutSerializable guards invalid input', () {
      expect(
        () => VariantLayoutSerializable.toVariantDecodeResult({'nope': 1}),
        throwsA(isA<BuError>()),
      );
      expect(
        () => VariantLayoutSerializable.deserialize(
          bytes: [0xFF],
          layout: LayoutConst.struct([
            LayoutConst.u8(property: 'key'),
          ], property: 'v'),
        ),
        throwsA(isA<BuError>()),
      );
      const v = _TestVariant(9);
      final bytes = v.toSerializeVariantBytes();
      expect(bytes.isNotEmpty, isTrue);
      expect(v.toSerializeBytes().isNotEmpty, isTrue);
    });
  });
}

class _TestPoint with LayoutSerializable {
  final int x;
  final int y;
  const _TestPoint(this.x, this.y);
  static Layout<Map<String, dynamic>> layout({String? property}) =>
      LayoutConst.struct([
        LayoutConst.u8(property: 'x'),
        LayoutConst.u8(property: 'y'),
      ], property: property);
  @override
  Layout<Map<String, dynamic>> toLayout({String? property}) =>
      layout(property: property);
  @override
  Map<String, dynamic> toSerializeJson() => {'x': x, 'y': y};
}

class _TestVariant with VariantLayoutSerializable {
  final int v;
  const _TestVariant(this.v);
  @override
  String get variantName => 't';
  @override
  Layout<Map<String, dynamic>> toLayout({String? property}) =>
      LayoutConst.struct([LayoutConst.u8(property: 'v')], property: property);
  @override
  Map<String, dynamic> toSerializeJson() => {'v': v};
  @override
  Map<String, dynamic> toSerializeVariantJson() => {'t': v};
  @override
  Layout<Map<String, dynamic>> toVariantLayout({String? property}) =>
      LayoutConst.struct([LayoutConst.u8(property: 't')], property: property);
}

void layoutTest() {
  layoutNumericTest();
  layoutStructTupleSeqTest();
  layoutBytesTest();
  layoutOptionUnionTest();
  layoutFactoriesTest();
  layoutBufferSerializationTest();
}

void main() {
  BlockchainUtilsTestApi.runTest(layoutTest, "Layout");
}
