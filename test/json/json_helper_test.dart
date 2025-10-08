import 'package:blockchain_utils/utils/json/exception/exception.dart';
import 'package:blockchain_utils/utils/json/extension/json.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:test/test.dart';

import 'test_vector.dart';

void main() {
  group("JsonHelper", () {
    test("bigint", () {
      expect(testVector.valueAsBigInt("bigint"), BigInt.one);
      expect(testVector.valueAsBigInt<BigInt?>("notexists"), null);
      expect(testVector.valueAsBigInt("bStringHex", allowHex: true),
          BigInt.from(123123123));
      expect(testVector.valueAsBigInt("bString"), BigInt.one);
      expect(() => testVector.valueAsBigInt("wBigInt"),
          throwsA(isA<JSONHelperException>()));
      expect(() => testVector.valueAsBigInt("bStringHex", allowHex: false),
          throwsA(isA<JSONHelperException>()));
    });

    test("double", () {
      expect(testVector.valueAsDouble("double"), 1.0);
      expect(testVector.valueAsDouble<double?>("notexists"), null);
      expect(testVector.valueAsDouble("doubleString"), 1.0);
      expect(testVector.valueAsDouble("doubleInt"), 1.0);
    });

    test("int", () {
      expect(testVector.valueAsInt("int"), 1);
      expect(testVector.valueAsInt<int?>("notexists"), null);
      expect(testVector.valueAsInt("intString"), 1);
      expect(testVector.valueAsInt("double", allowDouble: true), 1);
      expect(testVector.valueAsInt("doubleString", allowDouble: true), 1);
      expect(testVector.valueAsInt("bString"), 1);
      expect(() => testVector.valueAsInt("wBigInt"),
          throwsA(isA<JSONHelperException>()));
      expect(() => testVector.valueAsInt("bStringHex", allowHex: false),
          throwsA(isA<JSONHelperException>()));
    });

    test("bytes", () {
      expect(testVector.valueAsBytes("bytes"), [0, 1]);
      expect(testVector.valueAsBytes("bytesAsHex"), [0]);
      expect(
          testVector.valueAsBytes("bytesAsString",
              encoding: StringEncoding.utf8),
          StringUtils.encode("mrtnetwork"));
      expect(() => testVector.valueAsBytes("bytesAsHex", allowHex: false),
          throwsA(isA<JSONHelperException>()));

      expect(() => testVector.valueAsBytes("wBytes"),
          throwsA(isA<JSONHelperException>()));
      expect(
          testVector.valueAsBytes("byteAsBase58",
              encoding: StringEncoding.base58),
          StringUtils.encode("2cFupjhnEsSn59qHXstmK2ffpLv2",
              type: StringEncoding.base58));
      expect(
          testVector.valueAsBytes("bytesAsBase64",
              encoding: StringEncoding.base64),
          StringUtils.encode("Mnh0LC54VShsSmdRQ08xVzU=",
              type: StringEncoding.base64));
      expect(
          () => testVector.valueAsBytes("bytesAsBase64",
              encoding: StringEncoding.base58),
          throwsA(isA<JSONHelperException>()));
      expect(() => testVector.valueAsBytes("bytesAsBase64", encoding: null),
          throwsA(isA<JSONHelperException>()));
    });

    test("map", () {
      expect(testVector.valueAsMap<Map<String, dynamic>>("map"),
          {"one": 1, "two": 2});
      expect(testVector.valueAsMap<Map<dynamic, dynamic>>("map"),
          {"one": 1, "two": 2});
      expect(testVector.valueAsMap<Map<dynamic, dynamic>?>("notexists"), null);
      expect(testVector.valueAsMap<Map<int, dynamic>>("mapInt"), {1: 1, 2: 2});
      expect(testVector.valueAsMap<Map>("map"), {"one": 1, "two": 2});
      expect(testVector.valueAsMap<Map>("map").valueAsInt("one"), 1);
      expect(
          testVector.valueAsMap<Map<int, dynamic>>("mapInt").valueAsInt(1), 1);
      expect(() => testVector.valueAsMap<Map<int, dynamic>>("map"),
          throwsA(isA<JSONHelperException>()));

      ///
      expect(testVector.valueEnsureAsMap<String, dynamic>("map"),
          {"one": 1, "two": 2});
      expect(testVector.valueEnsureAsMap<dynamic, dynamic>("map"),
          {"one": 1, "two": 2});
      expect(testVector.valueEnsureAsMap<int, int>("mapInt"), {1: 1, 2: 2});
      expect(() => testVector.valueEnsureAsMap<int, int>("map"),
          throwsA(isA<JSONHelperException>()));
      expect(() => testVector.valueEnsureAsMap<int, int>("notexists"),
          throwsA(isA<JSONHelperException>()));
    });

    test("list", () {
      expect(testVector.valueAsList<List<String>>("list"), ["a", "b"]);
      expect(testVector.valueAsList<List<String>?>("notexists"), null);
      expect(testVector.valueAsList<List<Object>>("listDynamic"), ["a", 1]);
      expect(() => testVector.valueAsList<List<int>>("listDynamic2"),
          throwsA(isA<JSONHelperException>()));

      expect(testVector.valueEnsureAsList<String>("listDynamic2"), ["a", "a"]);
    });
    test("set", () {
      expect(testVector.valueAsSet<Set<String>>("setDynamic"), {"a", "b"});
      expect(testVector.valueAsSet<Set<String>?>("notexists"), null);
      expect(() => testVector.valueAsSet<Set<String>>("notexists"),
          throwsA(isA<JSONHelperException>()));
      expect(testVector.valueAsSet<Set<int>>("set"), {0, 1});
    });
    test(
      "value as",
      () {
        expect(
            testVector.valueTo<String, List<String>>(
                key: "list", parse: (v) => v[1]),
            "b");
        expect(
            testVector.valueTo<BigInt, BigInt>(key: "bString", parse: (v) => v),
            BigInt.one);
        expect(
            testVector.valueTo<BigInt, String>(
                key: "bString", parse: (v) => BigInt.parse(v)),
            BigInt.one);
        expect(
            testVector.valueTo<BigInt, Object>(
                key: "bString", parse: (v) => BigInt.parse(v.toString())),
            BigInt.one);
        expect(
            testVector.valueTo<List<int>, List<int>>(
                key: "byteAsBase58",
                parse: (v) => v,
                encoding: StringEncoding.base58,
                asBytes: true),
            StringUtils.encode("2cFupjhnEsSn59qHXstmK2ffpLv2",
                type: StringEncoding.base58));

        expect(
            testVector.valueTo<String, Map<String, String>>(
                key: "mapDynamic", parse: (v) => v.valueAs("a")),
            "v");
      },
    );
  });
}
