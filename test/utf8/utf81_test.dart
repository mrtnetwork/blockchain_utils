// copied from dart:convert package testcases
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:blockchain_utils/utf8/src/encoder.dart';
import 'package:test/test.dart';

void main() {
  test("UTF8-1", () {
    for (var test in unicodeTests) {
      List<int> bytes = test[0];
      String string = test[1];
      expect(bytes, UTF8Encoder.encode(string));
      expect(bytes, UTF8Encoder.encode(string));
      expect(bytes, UTF8Encoder.encode(string));
      expect(bytes, UTF8Encoder.encode(string));
      expect(bytes, UTF8Encoder.encode(string));
      expect(bytes, UTF8Encoder.encode(string));
      expect(bytes, UTF8Encoder.encode(string));
    }
  });
}

// Google favorite: "Îñţérñåţîöñåļîžåţîờñ".
const interBytes = [
  0xc3,
  0x8e,
  0xc3,
  0xb1,
  0xc5,
  0xa3,
  0xc3,
  0xa9,
  0x72,
  0xc3,
  0xb1,
  0xc3,
  0xa5,
  0xc5,
  0xa3,
  0xc3,
  0xae,
  0xc3,
  0xb6,
  0xc3,
  0xb1,
  0xc3,
  0xa5,
  0xc4,
  0xbc,
  0xc3,
  0xae,
  0xc5,
  0xbe,
  0xc3,
  0xa5,
  0xc5,
  0xa3,
  0xc3,
  0xae,
  0xe1,
  0xbb,
  0x9d,
  0xc3,
  0xb1,
];
const interString = "Îñţérñåţîöñåļîžåţîờñ";

// Blueberry porridge in Danish: "blåbærgrød".
const blueberryBytes = [
  0x62,
  0x6c,
  0xc3,
  0xa5,
  0x62,
  0xc3,
  0xa6,
  0x72,
  0x67,
  0x72,
  0xc3,
  0xb8,
  0x64,
];
const blueberryString = "blåbærgrød";

// "சிவா அணாமாைல", that is "Siva Annamalai" in Tamil.
const sivaBytes1 = [
  0xe0,
  0xae,
  0x9a,
  0xe0,
  0xae,
  0xbf,
  0xe0,
  0xae,
  0xb5,
  0xe0,
  0xae,
  0xbe,
  0x20,
  0xe0,
  0xae,
  0x85,
  0xe0,
  0xae,
  0xa3,
  0xe0,
  0xae,
  0xbe,
  0xe0,
  0xae,
  0xae,
  0xe0,
  0xae,
  0xbe,
  0xe0,
  0xaf,
  0x88,
  0xe0,
  0xae,
  0xb2,
];
const sivaString1 = "சிவா அணாமாைல";

// "िसवा अणामालै", that is "Siva Annamalai" in Devanagari.
const sivaBytes2 = [
  0xe0,
  0xa4,
  0xbf,
  0xe0,
  0xa4,
  0xb8,
  0xe0,
  0xa4,
  0xb5,
  0xe0,
  0xa4,
  0xbe,
  0x20,
  0xe0,
  0xa4,
  0x85,
  0xe0,
  0xa4,
  0xa3,
  0xe0,
  0xa4,
  0xbe,
  0xe0,
  0xa4,
  0xae,
  0xe0,
  0xa4,
  0xbe,
  0xe0,
  0xa4,
  0xb2,
  0xe0,
  0xa5,
  0x88,
];
const sivaString2 = "िसवा अणामालै";

// DESERET CAPITAL LETTER BEE
const beeBytes = [0xf0, 0x90, 0x90, 0x92];
const beeString = "𐐒";

const digitBytes = [0x35];
const digitString = "5";

const asciiBytes = [
  0x61,
  0x62,
  0x63,
  0x64,
  0x65,
  0x66,
  0x67,
  0x68,
  0x69,
  0x6a,
  0x6b,
  0x6c,
  0x6d,
  0x6e,
  0x6f,
  0x70,
  0x71,
  0x72,
  0x73,
  0x74,
  0x75,
  0x76,
  0x77,
  0x78,
  0x79,
  0x7a,
];
const asciiString = "abcdefghijklmnopqrstuvwxyz";

const biggestAsciiBytes = [0x7f];
const biggestAsciiString = "\x7F";

const smallest2Utf8UnitBytes = [0xc2, 0x80];
const smallest2Utf8UnitString = "\u{80}";

const biggest2Utf8UnitBytes = [0xdf, 0xbf];
const biggest2Utf8UnitString = "\u{7FF}";

const smallest3Utf8UnitBytes = [0xe0, 0xa0, 0x80];
const smallest3Utf8UnitString = "\u{800}";

const biggest3Utf8UnitBytes = [0xef, 0xbf, 0xbf];
const biggest3Utf8UnitString = "\u{FFFF}";

const smallest4Utf8UnitBytes = [0xf0, 0x90, 0x80, 0x80];
const smallest4Utf8UnitString = "\u{10000}";

const biggest4Utf8UnitBytes = [0xf4, 0x8f, 0xbf, 0xbf];
const biggest4Utf8UnitString = "\u{10FFFF}";

const testPairs = [
  [<int>[], ""],
  [interBytes, interString],
  [blueberryBytes, blueberryString],
  [sivaBytes1, sivaString1],
  [sivaBytes2, sivaString2],
  [beeBytes, beeString],
  [digitBytes, digitString],
  [asciiBytes, asciiString],
  [biggestAsciiBytes, biggestAsciiString],
  [smallest2Utf8UnitBytes, smallest2Utf8UnitString],
  [biggest2Utf8UnitBytes, biggest2Utf8UnitString],
  [smallest3Utf8UnitBytes, smallest3Utf8UnitString],
  [biggest3Utf8UnitBytes, biggest3Utf8UnitString],
  [smallest4Utf8UnitBytes, smallest4Utf8UnitString],
  [biggest4Utf8UnitBytes, biggest4Utf8UnitString],
];

List<List> expandTestPairs() {
  assert(2 == beeString.length);
  var tests = <List>[];
  tests.addAll(testPairs);
  tests.addAll(
    testPairs.map((test) {
      var bytes = test[0] as List<int>;
      var string = test[1] as String;
      var longBytes = <int>[];
      var longString = "";
      for (int i = 0; i < 100; i++) {
        longBytes.addAll(bytes);
        longString += string;
      }
      return [longBytes, longString];
    }),
  );
  return tests;
}

final List unicodeTests = expandTestPairs();
