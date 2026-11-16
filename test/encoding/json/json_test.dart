import 'dart:convert' show latin1;
import 'dart:convert' as dc;

import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

import '../../utils.dart';

// Reference constants used across several groups.
final BigInt int64Max = BigInt.parse('9223372036854775807'); // 2^63 - 1
final BigInt int64Min = BigInt.parse('-9223372036854775808'); // -2^63
final BigInt uint64Max = BigInt.parse('18446744073709551615'); // 2^64 - 1
final BigInt safeMax = BigInt.from(9007199254740991); // 2^53 - 1
final BigInt safeMin = BigInt.from(-9007199254740991);

// dart2js: int is a JS number (53 bits). VM: int is signed 64-bit.
final bool isWeb = identical(0, 0.0);

bool fitsDartInt(BigInt v) =>
    isWeb ? (v <= safeMax && v >= safeMin) : v.isValidInt;

String lone(int unit) => String.fromCharCode(unit);

// Marker object used only to force `toEncodable` to fire - native types
// like String/num/bool never reach toEncodable (same as dart:convert),
// so tests exercising the callback chain trigger from this instead.
class _Trigger {}

class _WithToJson {
  final Object? value;
  _WithToJson(this.value);
  Object? toJson() => value;
}

class _BadToJson {
  Object? toJson() => throw StateError('nope');
}

class _SelfToJson {
  Object? toJson() => this;
}

void jsonTest() {
  group('basics', () {
    test('null round trip', () {
      expect(JsonCodec.jsonDecode(JsonCodec.jsonEncode(null)), isNull);
    });

    test('bool round trip', () {
      expect(JsonCodec.jsonDecode(JsonCodec.jsonEncode(true)), isTrue);
      expect(JsonCodec.jsonDecode(JsonCodec.jsonEncode(false)), isFalse);
    });

    test('int round trip', () {
      expect(JsonCodec.jsonDecode(JsonCodec.jsonEncode(0)), equals(0));
      expect(JsonCodec.jsonDecode(JsonCodec.jsonEncode(-42)), equals(-42));
      expect(
        JsonCodec.jsonDecode(JsonCodec.jsonEncode(1234567890)),
        equals(1234567890),
      );
    });

    test('double round trip', () {
      expect(JsonCodec.jsonDecode(JsonCodec.jsonEncode(3.14)), equals(3.14));
      expect(
        JsonCodec.jsonDecode(JsonCodec.jsonEncode(-0.001)),
        equals(-0.001),
      );
      expect(
        JsonCodec.jsonDecode(JsonCodec.jsonEncode(1.5e10)),
        equals(1.5e10),
      );
    });

    test('NaN/Infinity rejected on encode', () {
      expect(
        () => JsonCodec.jsonEncode(double.nan),
        throwsA(isA<BuError>()),
      );
      expect(
        () => JsonCodec.jsonEncode(double.infinity),
        throwsA(isA<BuError>()),
      );
    });

    test('plain string round trip', () {
      expect(
        JsonCodec.jsonDecode(JsonCodec.jsonEncode('hello world')),
        equals('hello world'),
      );
    });

    test('string escaping round trip', () {
      const s = 'quote:" backslash:\\ nl:\n tab:\t cr:\r bs:\b ff:\f ctrl:\x01';
      expect(JsonCodec.jsonDecode(JsonCodec.jsonEncode(s)), equals(s));
    });

    test('unicode / emoji (surrogate pair) round trip', () {
      const s = 'caf\u00e9 \u{1F600}'; // café 😀
      expect(JsonCodec.jsonDecode(JsonCodec.jsonEncode(s)), equals(s));
    });

    test('decode explicit \\uXXXX surrogate pair escape', () {
      final decoded = JsonCodec.jsonDecode(
        r'"\uD83D\uDE00"',
      ); // 😀 as a UTF-16 pair
      expect(decoded, equals('\u{1F600}'));
    });

    test('list round trip incl. nested', () {
      final value = [
        1,
        'two',
        3.0,
        true,
        null,
        [4, 5, 6],
      ];
      expect(JsonCodec.jsonDecode(JsonCodec.jsonEncode(value)), equals(value));
    });

    test('map round trip incl. nested', () {
      final value = {
        'a': 1,
        'b': {'c': 2, 'd': null},
        'e': [1, 2, 3],
      };
      expect(JsonCodec.jsonDecode(JsonCodec.jsonEncode(value)), equals(value));
    });

    test('empty object / array', () {
      expect(JsonCodec.jsonDecode(JsonCodec.jsonEncode({})), equals({}));
      expect(JsonCodec.jsonDecode(JsonCodec.jsonEncode([])), equals([]));
    });

    test('non-String map key rejected', () {
      expect(
        () => JsonCodec.jsonEncode({1: 'x'}),
        throwsA(isA<BuError>()),
      );
    });

    test('unsupported object without toEncodable throws', () {
      expect(
        () => JsonCodec.jsonEncode(Object()),
        throwsA(isA<BuError>()),
      );
    });

    test('cyclic list detected', () {
      final list = <dynamic>[1, 2];
      list.add(list);
      expect(
        () => JsonCodec.jsonEncode(list),
        throwsA(isA<BuError>()),
      );
    });

    test('cyclic map detected', () {
      final map = <String, dynamic>{'a': 1};
      map['self'] = map;
      expect(
        () => JsonCodec.jsonEncode(map),
        throwsA(isA<BuError>()),
      );
    });
  });

  group('null options == vanilla dart:convert behavior', () {
    test(
      'encode: BigInt without options (and without toEncodable) throws, like dart:convert',
      () {
        // dart:convert's own JsonCodec.jsonEncode doesn't know BigInt either - it's
        // an unsupported type there too without a toEncodable.
        expect(
          () => JsonCodec.jsonEncode(BigInt.from(5)),
          throwsA(isA<BuError>()),
        );
        expect(
          () => dc.jsonEncode(BigInt.from(5)),
          throwsA(isA<dc.JsonUnsupportedObjectError>()),
        );
      },
    );

    test(
      'encode: JsonBinary without options (and without toEncodable) throws',
      () {
        expect(
          () => JsonCodec.jsonEncode(JsonBinary([1, 2, 3])),
          throwsA(isA<BuError>()),
        );
      },
    );

    test(
      'decode: an oversized integer literal becomes a double, not BigInt/String',
      () {
        final huge = BigInt.parse('123456789012345678901234567890');
        final decoded = JsonCodec.jsonDecode('$huge');
        expect(decoded, isA<double>());
        expect(decoded, equals(huge.toDouble()));
      },
    );

    test(
      'decode: malformed UTF-8 string throws FormatException, not List<int>',
      () {
        final bytes = [...'{"data":"'.codeUnits, 0xFF, 0xFE, ...'"}'.codeUnits];
        expect(() => JsonCodec.jsonDecode(bytes), throwsArgumentException);
      },
    );

    test('passing options opts back into the custom behavior', () {
      expect(
        JsonCodec.jsonEncode(
          BigInt.from(5),
          options: const JsonEncodeOptions(),
        ),
        equals('"5"'),
      );
      final bytes = [...'{"data":"'.codeUnits, 0xFF, 0xFE, ...'"}'.codeUnits];
      final decoded =
          JsonCodec.jsonDecode(bytes, options: const JsonDecodeOptions())
              as Map;
      expect(decoded['data'], isA<List<int>>());
    });
  });

  group('parity with dart:convert (ordinary values)', () {
    // Representative "normal" JSON values - nothing BigInt/JsonBinary
    // related, since those are deliberate, documented divergences from
    // dart:convert, not bugs. This group is about proving that for
    // everything dart:convert already handles, we produce identical
    // output/bytes - and since options now defaults to null the same way
    // dart:convert has no such parameter at all, none of these need to
    // pass options explicitly.
    final values = <Object?>[
      null,
      true,
      false,
      0,
      -1,
      42,
      -42,
      1234567890,
      0.0,
      -0.0,
      1.0,
      100.0,
      0.1,
      -0.001,
      1.5e10,
      5e-7,
      1e21,
      '',
      'hello world',
      'quote:" backslash:\\ slash:/ nl:\n tab:\t ctrl:\x01',
      'caf\u00e9 \u{1F600}', // café 😀 - non-ASCII + astral code point
      [],
      {},
      [1, 'two', 3.0, true, null],
      {
        'z': 1, // intentionally non-alphabetical to check key order
        'a': 2,
        'nested': {
          'list': [1, 2, 3],
          'deep': {'x': null},
        },
      },
    ];

    test(
      'JsonCodec.jsonEncode(v) == dart:convert JsonCodec.jsonEncode(v) for every value',
      () {
        for (final v in values) {
          expect(
            JsonCodec.jsonEncode(v),
            equals(dc.jsonEncode(v)),
            reason: 'value: $v',
          );
        }
      },
    );

    test('JsonCodec.jsonDecode(dc.jsonEncode(v)) == v for every value', () {
      for (final v in values) {
        expect(
          JsonCodec.jsonDecode(dc.jsonEncode(v)),
          equals(v),
          reason: 'value: $v',
        );
      }
    });

    test(
      'JsonCodec.jsonDecode(s) == dart:convert JsonCodec.jsonDecode(s) for representative JSON text',
      () {
        const sources = [
          'null',
          'true',
          'false',
          '0',
          '-17',
          '3.14',
          '-0.001',
          '1e21',
          '""',
          '"hello"',
          '"line1\\nline2\\ttabbed"',
          '"unicode: \\u00e9 \\uD83D\\uDE00"',
          '[]',
          '{}',
          '[1,2,3]',
          '{"a":1,"b":[true,false,null],"c":{"d":"e"}}',
          '  {  "a"  :  1  }  ', // whitespace tolerance
        ];
        for (final s in sources) {
          expect(
            JsonCodec.jsonDecode(s),
            equals(dc.jsonDecode(s)),
            reason: 'source: $s',
          );
        }
      },
    );

    test('key insertion order is preserved, matching dart:convert', () {
      final m = {'z': 1, 'a': 2, 'm': 3};
      expect(JsonCodec.jsonEncode(m), equals(dc.jsonEncode(m)));
      expect(JsonCodec.jsonEncode(m), equals('{"z":1,"a":2,"m":3}'));
    });

    test('a realistic nested API-response-shaped fixture matches exactly', () {
      final fixture = {
        'status': 'ok',
        'count': 3,
        'ratio': 0.755,
        'items': [
          {'id': 1, 'name': 'first', 'tags': <String>[]},
          {'id': 2, 'name': 'sec\u00f6nd', 'active': true},
          {
            'id': 3,
            'name': null,
            'meta': {'nested': true},
          },
        ],
        'error': null,
      };
      final ours = JsonCodec.jsonEncode(fixture);
      final theirs = dc.jsonEncode(fixture);
      expect(ours, equals(theirs));
      expect(JsonCodec.jsonDecode(ours), equals(dc.jsonDecode(theirs)));
    });

    test(
      'JsonCodec.jsonEncodeBytes(v) == utf8 bytes of dart:convert JsonCodec.jsonEncode(v)',
      () {
        for (final v in values) {
          expect(
            JsonCodec.jsonEncodeBytes(v),
            equals(dc.utf8.encode(dc.jsonEncode(v))),
            reason: 'value: $v',
          );
        }
      },
    );

    test(
      'JsonCodec.jsonDecodeBytes on dc-produced UTF-8 bytes matches dc.jsonDecode',
      () {
        for (final v in values) {
          final wireBytes = dc.utf8.encode(dc.jsonEncode(v));
          expect(
            JsonCodec.jsonDecodeBytes(wireBytes),
            equals(dc.jsonDecode(dc.utf8.decode(wireBytes))),
            reason: 'value: $v',
          );
        }
      },
    );

    test(
      'bytes round trip agrees with the String round trip for every value',
      () {
        for (final v in values) {
          expect(
            JsonCodec.jsonDecodeBytes(JsonCodec.jsonEncodeBytes(v)),
            equals(JsonCodec.jsonDecode(JsonCodec.jsonEncode(v))),
            reason: 'value: $v',
          );
        }
      },
    );
  });

  group('BigInt encode', () {
    const asString = JsonEncodeOptions(); // bigIntEncoding defaults to .string

    test('BigIntEncoding.string always quotes, any magnitude', () {
      expect(
        JsonCodec.jsonEncode(BigInt.zero, options: asString),
        equals('"0"'),
      );
      expect(
        JsonCodec.jsonEncode(BigInt.from(42), options: asString),
        equals('"42"'),
      );
      expect(
        JsonCodec.jsonEncode(BigInt.from(-42), options: asString),
        equals('"-42"'),
      );
      expect(
        JsonCodec.jsonEncode(int64Max, options: asString),
        equals('"$int64Max"'),
      );
      expect(
        JsonCodec.jsonEncode(BigInt.one << 200, options: asString),
        equals('"${BigInt.one << 200}"'),
      );
    });

    const intOrString = JsonEncodeOptions(
      bigIntEncoding: BigIntEncoding.intOrString,
    );

    test('small safe value -> raw number', () {
      print(
        "data ${JsonCodec.jsonEncode(BigInt.from(42), options: intOrString)}",
      );
      expect(
        JsonCodec.jsonEncode(BigInt.from(42), options: intOrString),
        equals('42'),
      );
    });

    test('exactly at 53-bit safe bound -> raw number', () {
      expect(
        JsonCodec.jsonEncode(safeMax, options: intOrString),
        equals('$safeMax'),
      );
      expect(
        JsonCodec.jsonEncode(safeMin, options: intOrString),
        equals('$safeMin'),
      );
    });

    test('raw number iff the BigInt fits a Dart int on this platform', () {
      for (final v in [
        BigInt.zero,
        BigInt.from(-1),
        safeMax,
        safeMin,
        safeMax + BigInt.one,
        safeMin - BigInt.one,
        BigInt.one << 62,
        int64Max,
        int64Min,
        int64Max + BigInt.one,
        uint64Max,
        BigInt.one << 256,
        -(BigInt.one << 256),
      ]) {
        final expected = fitsDartInt(v) ? dc.jsonEncode(v.toInt()) : '"$v"';
        expect(
          JsonCodec.jsonEncode(v, options: intOrString),
          equals(expected),
          reason: '$v',
        );
        expect(
          String.fromCharCodes(
            JsonCodec.jsonEncodeBytes(v, options: intOrString),
          ),
          equals(expected),
          reason: 'bytes path $v',
        );
      }
    });

    test(
      'VM: full signed 64-bit range is a raw number, 2^63 and up is quoted',
      () {
        expect(
          JsonCodec.jsonEncode(int64Max, options: intOrString),
          equals('$int64Max'),
        );
        expect(
          JsonCodec.jsonEncode(int64Min, options: intOrString),
          equals('$int64Min'),
        );
        expect(
          JsonCodec.jsonEncode(int64Max + BigInt.one, options: intOrString),
          equals('"${int64Max + BigInt.one}"'),
        );
        expect(
          JsonCodec.jsonEncode(uint64Max, options: intOrString),
          equals('"$uint64Max"'),
        );
      },
      skip: isWeb ? 'int is a 53-bit JS number on web' : false,
    );

    test('huge values are always quoted', () {
      final huge = BigInt.one << 256;
      expect(
        JsonCodec.jsonEncode(huge, options: intOrString),
        equals('"$huge"'),
      );
    });

    test('intOrString output equals what a Dart int would encode to', () {
      for (final v in [0, 1, -1, 42, 9007199254740991, -9007199254740991]) {
        expect(
          JsonCodec.jsonEncode(BigInt.from(v), options: intOrString),
          equals(dc.jsonEncode(v)),
        );
      }
    });

    test('BigInt inside nested structure', () {
      final encoded = JsonCodec.jsonEncode({
        'small': BigInt.from(7),
        'huge': BigInt.one << 100,
      }, options: asString);
      expect(encoded, equals('{"small":"7","huge":"${BigInt.one << 100}"}'));
    });
  });

  group('integer decode (same as dart:convert)', () {
    const opts = JsonDecodeOptions();

    test('integer literals match dart:convert, with and without options', () {
      for (final lit in [
        '0',
        '42',
        '-42',
        '$safeMax',
        '$safeMin',
        '${BigInt.one << 62}',
        '$int64Max',
        '$int64Min',
        '$uint64Max',
        '123456789012345678901234567890',
        '-${BigInt.one << 300}',
      ]) {
        final expected = dc.jsonDecode(lit);
        expect(JsonCodec.jsonDecode(lit), equals(expected), reason: lit);
        expect(
          JsonCodec.jsonDecode(lit, options: opts),
          equals(expected),
          reason: lit,
        );
        expect(
          JsonCodec.jsonDecode(lit).runtimeType,
          equals(expected.runtimeType),
          reason: lit,
        );
      }
    });

    test('-0 decodes exactly like dart:convert', () {
      final expected = dc.jsonDecode('-0') as num;
      final actual = JsonCodec.jsonDecode('-0') as num;
      expect(actual, equals(expected));
      expect(actual.isNegative, equals(expected.isNegative));
      expect(actual.runtimeType, equals(expected.runtimeType));
      final inList = JsonCodec.jsonDecode('[-0, 0, -0.0]') as List;
      final expectedList = dc.jsonDecode('[-0, 0, -0.0]') as List;
      for (var i = 0; i < inList.length; i++) {
        expect(
          (inList[i] as num).isNegative,
          equals((expectedList[i] as num).isNegative),
        );
        expect(inList[i].runtimeType, equals(expectedList[i].runtimeType));
      }
    });

    test('oversized literal is never a String or BigInt', () {
      final decoded = JsonCodec.jsonDecode('$uint64Max', options: opts);
      expect(decoded, isA<num>());
    });

    test('invalid number grammar rejected like dart:convert', () {
      for (final bad in ['01', '1.', '-', '.5', '1e', '1e+', '-01']) {
        expect(() => dc.jsonDecode(bad), throwsFormatException, reason: bad);
        expect(() => JsonCodec.jsonDecode(bad), throwsA(anything), reason: bad);
      }
    });

    test('encode(intOrString) then decode round trip', () {
      const encOpts = JsonEncodeOptions(
        bigIntEncoding: BigIntEncoding.intOrString,
      );
      // safe value -> number -> int
      final safe = JsonCodec.jsonEncode(BigInt.from(42), options: encOpts);
      expect(JsonCodec.jsonDecode(safe), equals(42));
      // unsafe value -> string -> String
      final big = BigInt.one << 70; // never fits a Dart int
      final json = JsonCodec.jsonEncode(big, options: encOpts);
      expect(json, equals('"$big"'));
      expect(BigInt.parse(JsonCodec.jsonDecode(json) as String), equals(big));
    });

    test('encode(string) then decode round trip for huge values', () {
      final v = BigInt.one << 300;
      final json = JsonCodec.jsonEncode(v, options: const JsonEncodeOptions());
      final decoded = JsonCodec.jsonDecode(json);
      expect(decoded, isA<String>());
      expect(BigInt.parse(decoded as String), equals(v));
    });
  });

  group('toEncodable', () {
    test(
      'bypasses built-in BigInt handling entirely, regardless of options',
      () {
        expect(
          JsonCodec.jsonEncode(
            BigInt.from(5),
            options: const JsonEncodeOptions(),
          ),
          equals('"5"'),
        );

        final encoded = JsonCodec.jsonEncode(
          BigInt.from(5),
          toEncodable: (o) => o is BigInt ? o.toInt() : o,
        );
        expect(encoded, equals('5'));

        // toEncodable wins even when options is also given.
        final encodedWithOptions = JsonCodec.jsonEncode(
          BigInt.from(5),
          toEncodable: (o) => o is BigInt ? o.toInt() : o,
          options: const JsonEncodeOptions(),
        );
        expect(encodedWithOptions, equals('5'));
      },
    );

    test('receives JsonBinary untouched (feature skipped)', () {
      final encoded = JsonCodec.jsonEncode(
        JsonBinary([1, 2, 3]),
        toEncodable: (o) => o is JsonBinary ? o.bytes : o,
      );
      expect(encoded, equals('[1,2,3]'));
    });

    test('chains recursively on its own return value', () {
      final encoded = JsonCodec.jsonEncode(
        _Trigger(),
        toEncodable: (o) {
          if (o is _Trigger) return BigInt.from(9);
          if (o is BigInt) return 'was-bigint:$o';
          return o;
        },
      );
      expect(encoded, equals('"was-bigint:9"'));
    });

    test('without toEncodable, unknown object throws', () {
      expect(
        () => JsonCodec.jsonEncode(Object()),
        throwsA(isA<BuError>()),
      );
    });
  });

  group('reviver', () {
    test(
      'sees String keys for object props, int for array indices, null at top',
      () {
        final seen = <MapEntry<Object?, Object?>>[];
        JsonCodec.jsonDecode(
          '{"a":1,"list":[10,20]}',
          reviver: (k, v) {
            seen.add(MapEntry(k, v));
            return v;
          },
        );
        final byKey = <Object?, Object?>{
          for (final e in seen)
            if (e.key != null) e.key: e.value,
        };
        expect(byKey['a'], equals(1));
        expect(byKey['list'], equals([10, 20]));
        expect(seen.any((e) => e.key == 0 && e.value == 10), isTrue);
        expect(seen.any((e) => e.key == 1 && e.value == 20), isTrue);
        expect(seen.any((e) => e.key == null), isTrue);
      },
    );

    test('can transform values (e.g. tag doubling)', () {
      final decoded = JsonCodec.jsonDecode(
        '{"n":21}',
        reviver: (k, v) => (k == 'n' && v is int) ? v * 2 : v,
      );
      expect(decoded, equals({'n': 42}));
    });

    test('applied to every array element', () {
      final decoded = JsonCodec.jsonDecode(
        '[1,2,3]',
        reviver: (k, v) => v is int ? v + 1 : v,
      );
      expect(decoded, equals([2, 3, 4]));
    });
  });

  group('indent / pretty-printing', () {
    test('null indent (default) is compact, same as before', () {
      expect(
        JsonCodec.jsonEncode({
          'a': 1,
          'b': [1, 2],
        }),
        equals('{"a":1,"b":[1,2]}'),
      );
    });

    test('simple object with 2-space indent', () {
      final encoded = JsonCodec.jsonEncode({'a': 1, 'b': 2}, indent: '  ');
      expect(encoded, equals('{\n  "a": 1,\n  "b": 2\n}'));
    });

    test('simple array with 2-space indent', () {
      final encoded = JsonCodec.jsonEncode([1, 2, 3], indent: '  ');
      expect(encoded, equals('[\n  1,\n  2,\n  3\n]'));
    });

    test('nested structure indents each level', () {
      final value = {
        'a': 1,
        'b': {'c': 2},
        'd': [1, 2],
      };
      final encoded = JsonCodec.jsonEncode(value, indent: '  ');
      expect(
        encoded,
        equals(
          '{\n'
          '  "a": 1,\n'
          '  "b": {\n'
          '    "c": 2\n'
          '  },\n'
          '  "d": [\n'
          '    1,\n'
          '    2\n'
          '  ]\n'
          '}',
        ),
      );
    });

    test('empty object/array stay on one line even with indent', () {
      expect(JsonCodec.jsonEncode({}, indent: '  '), equals('{}'));
      expect(JsonCodec.jsonEncode([], indent: '  '), equals('[]'));
      expect(
        JsonCodec.jsonEncode({'a': []}, indent: '  '),
        equals('{\n  "a": []\n}'),
      );
    });

    test('a tab indent works too', () {
      final encoded = JsonCodec.jsonEncode({'a': 1}, indent: '\t');
      expect(encoded, equals('{\n\t"a": 1\n}'));
    });

    test('indented output still round trips through JsonCodec.jsonDecode', () {
      final value = {
        'a': 1,
        'b': [1, 2, 3],
        'c': {'d': null, 'e': true},
      };
      final encoded = JsonCodec.jsonEncode(value, indent: '  ');
      expect(JsonCodec.jsonDecode(encoded), equals(value));
    });

    test(
      'JsonCodec.jsonEncodeBytes with indent matches JsonCodec.jsonEncode with indent, UTF-8 encoded',
      () {
        final value = {
          'a': 1,
          'b': [1, 2],
        };
        final encoded = JsonCodec.jsonEncode(value, indent: '  ');
        final encodedBytes = JsonCodec.jsonEncodeBytes(value, indent: '  ');
        expect(encodedBytes, equals(encoded.codeUnits));
      },
    );

    test(
      'JsonCodec.jsonEncodeBytes with indent decodes correctly via JsonCodec.jsonDecodeBytes',
      () {
        final value = {
          'a': [1, 2],
          'b': {'c': 3},
        };
        final bytes = JsonCodec.jsonEncodeBytes(value, indent: '  ');
        expect(JsonCodec.jsonDecodeBytes(bytes), equals(value));
      },
    );
  });

  group('direct binary encode/decode', () {
    test(
      'JsonCodec.jsonEncodeBytes matches JsonCodec.jsonEncode byte-for-byte for plain values',
      () {
        final value = {
          'a': 1,
          'b': [true, false, null],
          'c': 'hello',
        };
        expect(
          JsonCodec.jsonEncodeBytes(value),
          equals(JsonCodec.jsonEncode(value).codeUnits),
        );
      },
    );

    test(
      'JsonCodec.jsonEncodeBytes UTF-8 encodes real string content properly',
      () {
        const s = 'caf\u00e9 \u{1F600}'; // café 😀
        final bytes = JsonCodec.jsonEncodeBytes({'s': s});
        // Should be valid UTF-8 - decoding it as a normal Dart string via
        // JsonCodec.jsonDecode must recover the original text.
        final decoded = JsonCodec.jsonDecode(bytes) as Map;
        expect(decoded['s'], equals(s));
      },
    );

    test(
      'JsonCodec.jsonDecodeBytes agrees with JsonCodec.jsonDecode(bytes)',
      () {
        final bytes = JsonCodec.jsonEncodeBytes({
          'n': 42,
          'list': [1, 2, 3],
        });
        expect(
          JsonCodec.jsonDecodeBytes(bytes),
          equals(JsonCodec.jsonDecode(bytes)),
        );
      },
    );

    test('JsonBinary round trips losslessly with NO extra encoding step', () {
      // Unlike the JsonCodec.jsonEncode + latin1.encode dance, JsonCodec.jsonEncodeBytes writes
      // JsonBinary bytes straight through - no encoding pitfall to avoid.
      final original = [0x00, 0xFF, 0xFE, 0x80, 0x41, 0x22, 0x5C];
      final bytes = JsonCodec.jsonEncodeBytes({
        'data': JsonBinary(original),
      }, options: const JsonEncodeOptions());
      final decoded =
          JsonCodec.jsonDecodeBytes(bytes, options: const JsonDecodeOptions())
              as Map;
      expect(decoded['data'], isA<List<int>>());
      expect(decoded['data'], equals(original));
    });

    test('BigInt intOrString round trips through the bytes path', () {
      const encOpts = JsonEncodeOptions(
        bigIntEncoding: BigIntEncoding.intOrString,
      );
      const decOpts = JsonDecodeOptions();
      final v = BigInt.one << 70; // never fits a Dart int -> string
      final bytes = JsonCodec.jsonEncodeBytes(v, options: encOpts);
      final decoded = JsonCodec.jsonDecodeBytes(bytes, options: decOpts);
      expect(decoded, isA<String>());
      expect(BigInt.parse(decoded), equals(v));
    });

    test('toEncodable / reviver both work on the bytes path too', () {
      final bytes = JsonCodec.jsonEncodeBytes(
        BigInt.from(5),
        toEncodable: (o) => o is BigInt ? o.toInt() : o,
      );
      expect(bytes, equals('5'.codeUnits));

      final decoded = JsonCodec.jsonDecodeBytes(
        '{"n":21}'.codeUnits,
        reviver: (k, v) => (k == 'n' && v is int) ? v * 2 : v,
      );
      expect(decoded, equals({'n': 42}));
    });

    test('cyclic structures rejected on the bytes path too', () {
      final list = <dynamic>[1, 2];
      list.add(list);
      expect(
        () => JsonCodec.jsonEncodeBytes(list),
        throwsA(isA<BuError>()),
      );
    });
  });

  group('binary-safe strings', () {
    // {"data":"<rawFieldBytes>"} built by hand so we can embed bytes that
    // aren't valid UTF-8 (a real Dart String literal couldn't hold those).
    List<int> jsonBytesWithBadStringField(List<int> rawFieldBytes) {
      return [...'{"data":"'.codeUnits, ...rawFieldBytes, ...'"}'.codeUnits];
    }

    test(
      'options: JsonDecodeOptions() (default within the class): malformed UTF-8 string -> List<int>',
      () {
        final bad = [0xFF, 0xFE, 0x41, 0x00];
        final decoded =
            JsonCodec.jsonDecode(
                  jsonBytesWithBadStringField(bad),
                  options: const JsonDecodeOptions(),
                )
                as Map;
        expect(decoded['data'], isA<List<int>>());
        expect(decoded['data'], equals(bad));
      },
    );

    test(
      'options: null (the JsonCodec.jsonDecode default) -> throws FormatException instead',
      () {
        final bad = [0xFF, 0xFE];
        expect(
          () => JsonCodec.jsonDecode(jsonBytesWithBadStringField(bad)),
          throwsArgumentException,
        );
      },
    );

    test('badStringAsBinary:false -> throws FormatException instead', () {
      final bad = [0xFF, 0xFE];
      expect(
        () => JsonCodec.jsonDecode(
          jsonBytesWithBadStringField(bad),
          options: const JsonDecodeOptions(badStringAsBinary: false),
        ),
        throwsArgumentException,
      );
    });

    test('valid UTF-8 bytes still decode as a normal String', () {
      final good = 'hello'.codeUnits; // plain ASCII, valid UTF-8
      final decoded =
          JsonCodec.jsonDecode(jsonBytesWithBadStringField(good)) as Map;
      expect(decoded['data'], isA<String>());
      expect(decoded['data'], equals('hello'));
    });

    test(
      'malformed string as an object KEY still decodes (best-effort key)',
      () {
        final bad = [0xFF, 0xFE];
        final bytes = [...'{"'.codeUnits, ...bad, ...'":1}'.codeUnits];
        final decoded =
            JsonCodec.jsonDecode(bytes, options: const JsonDecodeOptions())
                as Map;
        expect(decoded.length, equals(1));
      },
    );

    test('JsonBinary encode -> wire bytes -> decode round trip', () {
      // JsonBinary writes each byte as a raw UTF-16 code unit in the
      // output Dart String. To recover the *actual wire bytes* (what a
      // real API would send), encode that Dart String with latin1, NOT
      // utf8 - utf8.encode would re-expand bytes >= 0x80 into multi-byte
      // sequences and silently break the round trip.
      final original = [
        0x00,
        0xFF,
        0xFE,
        0x80,
        0x41,
      ]; // invalid UTF-8 on purpose
      final jsonString = JsonCodec.jsonEncode({
        'data': JsonBinary(original),
      }, options: const JsonEncodeOptions());
      final wireBytes = latin1.encode(jsonString);
      final decoded =
          JsonCodec.jsonDecode(wireBytes, options: const JsonDecodeOptions())
              as Map;
      expect(decoded['data'], isA<List<int>>());
      expect(decoded['data'], equals(original));
    });

    test(
      'JsonBinary of bytes that happen to be valid UTF-8 decodes as String (known ambiguity)',
      () {
        final asciiBytes = 'hi'.codeUnits; // valid UTF-8 by coincidence
        final jsonString = JsonCodec.jsonEncode({
          'data': JsonBinary(asciiBytes),
        }, options: const JsonEncodeOptions());
        final wireBytes = latin1.encode(jsonString);
        final decoded = JsonCodec.jsonDecode(wireBytes) as Map;
        // JSON has no separate binary type - bytes that are coincidentally
        // valid UTF-8 come back as a String, not List<int>. Expected.
        expect(decoded['data'], equals('hi'));
      },
    );
  });

  group('lone surrogates (parity with dart:convert)', () {
    final samples = <String>[
      lone(0xD800), // lone high
      lone(0xDC00), // lone low
      lone(0xDBFF),
      lone(0xDFFF),
      'a${lone(0xD800)}b',
      'a${lone(0xDC00)}b',
      '${lone(0xDC00)}${lone(0xD800)}', // reversed pair: both lone
      '${lone(0xD800)}${lone(0xD800)}${lone(0xDC00)}', // lone + valid pair
      '\u{1F600}', // valid pair stays as-is
      'x\u{1F600}${lone(0xD83D)}',
      'ok \n \u0001 ${lone(0xD800)} "q"',
    ];

    test('encode String path escapes lone surrogates like dart:convert', () {
      for (final v in samples) {
        expect(JsonCodec.jsonEncode(v), equals(dc.jsonEncode(v)), reason: v);
        expect(
          JsonCodec.jsonEncode([v]),
          equals(dc.jsonEncode([v])),
          reason: v,
        );
        expect(
          JsonCodec.jsonEncode({v: v}),
          equals(dc.jsonEncode({v: v})),
          reason: 'key $v',
        );
      }
    });

    test('encode bytes path matches dart:convert (valid UTF-8 output)', () {
      for (final v in samples) {
        final bytes = JsonCodec.jsonEncodeBytes({v: v});
        expect(dc.utf8.decode(bytes), equals(dc.jsonEncode({v: v})), reason: v);
      }
    });

    test('lone high surrogate is written as a lowercase \\ud800 escape', () {
      expect(JsonCodec.jsonEncode(lone(0xD800)), equals(r'"\ud800"'));
      expect(
        String.fromCharCodes(JsonCodec.jsonEncodeBytes(lone(0xD800))),
        equals(r'"\ud800"'),
      );
    });

    test('decode \\uD800 escape gives a String, like dart:convert', () {
      for (final src in [
        r'"\uD800"',
        r'"\ud800"',
        r'"\uDC00"',
        r'"\uD800\u0041"', // high followed by a non-low escape
        r'"a\uDC00b"',
        r'"\uDC00\uD800"',
        r'"\uD800\uD800\uDC00"',
        r'"\uD83D\uDE00"', // valid pair
        r'{"k\uD800":"v\uDC00"}',
        r'["\uD800", 1]',
      ]) {
        final expected = dc.jsonDecode(src);
        // options: null (strict), badStringAsBinary on and off, bytes source.
        for (final opts in [
          null,
          const JsonDecodeOptions(),
          const JsonDecodeOptions(badStringAsBinary: false),
        ]) {
          expect(
            JsonCodec.jsonDecode(src, options: opts),
            equals(expected),
            reason: '$src opts=$opts',
          );
          expect(
            JsonCodec.jsonDecode(src.codeUnits, options: opts),
            equals(expected),
            reason: 'bytes $src opts=$opts',
          );
        }
      }
      expect(
        JsonCodec.jsonDecode(r'"\uD800"', options: const JsonDecodeOptions()),
        isA<String>(),
      );
    });

    test('encode -> decode round trip keeps lone surrogates', () {
      for (final v in samples) {
        expect(JsonCodec.jsonDecode(JsonCodec.jsonEncode(v)), equals(v));
        expect(JsonCodec.jsonDecode(JsonCodec.jsonEncodeBytes(v)), equals(v));
        expect(dc.jsonDecode(JsonCodec.jsonEncode(v)), equals(v));
      }
    });

    test('genuinely malformed UTF-8 still follows badStringAsBinary', () {
      final bytes = [...'"'.codeUnits, 0xFF, 0xFE, ...'"'.codeUnits];
      expect(() => JsonCodec.jsonDecode(bytes), throwsArgumentException);
      expect(
        JsonCodec.jsonDecode(bytes, options: const JsonDecodeOptions()),
        isA<List<int>>(),
      );
      // lone-surrogate escape next to bad bytes: not a valid String either
      final mixed = [...r'"\uD800'.codeUnits, 0xFF, ...'"'.codeUnits];
      expect(() => JsonCodec.jsonDecode(mixed), throwsArgumentException);
    });
  });

  group('default toJson (parity with dart:convert)', () {
    test('object with toJson is encoded through it', () {
      final v = _WithToJson({
        'a': 1,
        'b': [true, null],
      });
      expect(JsonCodec.jsonEncode(v), equals(dc.jsonEncode(v)));
      expect(
        dc.utf8.decode(JsonCodec.jsonEncodeBytes([v])),
        equals(dc.jsonEncode([v])),
      );
    });

    test('toJson result is encoded recursively', () {
      final v = {'x': _WithToJson(_WithToJson(7))};
      expect(JsonCodec.jsonEncode(v), equals('{"x":7}'));
    });

    test('toJson that throws -> JsonUnsupportedObjectError', () {
      expect(
        () => JsonCodec.jsonEncode(_BadToJson()),
        throwsA(isA<BuError>()),
      );
      expect(
        () => dc.jsonEncode(_BadToJson()),
        throwsA(isA<dc.JsonUnsupportedObjectError>()),
      );
    });

    test('toJson returning itself is a cycle, not a stack overflow', () {
      expect(
        () => JsonCodec.jsonEncode(_SelfToJson()),
        throwsA(isA<BuError>()),
      );
      expect(
        () => JsonCodec.jsonEncodeBytes(_SelfToJson()),
        throwsA(isA<BuError>()),
      );
    });
  });

  group('misc parsing', () {
    test('whitespace tolerated around structure', () {
      expect(
        JsonCodec.jsonDecode('  {  "a"  :  1  ,  "b"  :  [ 1 , 2 ]  }  '),
        equals({
          'a': 1,
          'b': [1, 2],
        }),
      );
    });

    test('trailing garbage rejected', () {
      expect(() => JsonCodec.jsonDecode('123 456'), throwsArgumentException);
    });

    test('unterminated string rejected', () {
      expect(() => JsonCodec.jsonDecode('"abc'), throwsArgumentException);
    });

    test('exponent / negative exponent numbers', () {
      expect(JsonCodec.jsonDecode('1e3'), equals(1000.0));
      expect(JsonCodec.jsonDecode('1.5e-2'), equals(0.015));
    });

    test('String source and List<int> source agree for plain ASCII JSON', () {
      const s = '{"x":1,"y":[true,false,null]}';
      expect(
        JsonCodec.jsonDecode(s),
        equals(JsonCodec.jsonDecode(s.codeUnits)),
      );
    });
  });
}

void main() {
  BlockchainUtilsTestApi.runTest(jsonTest, "Json");
}
