// copied from dart:convert package testcases
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

var _asciiStrings = [
  "pure ascii",
  "\x00 with control characters \n",
  "\x01 edge cases \x7f",
];

var _nonAsciiStrings = [
  "\x80 edge case first",
  "Edge case ASCII \u{80}",
  "Edge case byte \u{ff}",
  "Edge case super-BMP \u{10000}",
];

void main() {
  test("ascii", () {
    // Build longer versions of the example strings.
    for (int i = 0, n = _asciiStrings.length; i < n; i++) {
      var string = _asciiStrings[i];
      while (string.length < 1024) {
        string += string;
      }
      _asciiStrings.add(string);
    }
    for (int i = 0, n = _nonAsciiStrings.length; i < n; i++) {
      var string = _nonAsciiStrings[i];
      while (string.length < 1024) {
        string += string;
      }
      _nonAsciiStrings.add(string);
    }
    _testDirectConversions();
  });
}

void _testDirectConversions() {
  for (var asciiString in _asciiStrings) {
    List<int> bytes = ASCIIEncoder.encode(asciiString);
    expect(asciiString.codeUnits.toList(), bytes);
    String roundTripString = ASCIIDecoder.decode(bytes);
    expect(asciiString, roundTripString);
    roundTripString = ASCIIDecoder.decode(bytes);
    expect(asciiString, roundTripString);
  }

  for (var nonAsciiString in _nonAsciiStrings) {
    expect(() {
      final _ = ASCIIEncoder.encode(nonAsciiString);
    }, throwsException);
  }

  List<int> encode(String s, [int? i, int? r]) {
    return ASCIIEncoder.encode(s.substring(i ?? 0, r));
  }

  expect([0x42, 0x43, 0x44], encode("ABCDE", 1, 4));
  expect([0x42, 0x43, 0x44, 0x45], encode("ABCDE", 1));
  expect([0x42, 0x43, 0x44], encode("\xffBCD\xff", 1, 4));
  expect(() {
    return encode("\xffBCD\xff", 0, 4);
  }, throwsA(isA<ArgumentException>()));
  expect(() {
    encode("\xffBCD\xff", 1);
  }, throwsA(isA<ArgumentException>()));
  expect(() {
    encode("\xffBCD\xff", 1, 5);
  }, throwsA(isA<ArgumentException>()));

  String decode(List<int> s, [int? i, int? r]) {
    return ASCIIDecoder.decode(s.sublist(i ?? 0, r));
  }

  expect("BCD", decode([0x41, 0x42, 0x43, 0x44, 0x45], 1, 4));
  expect("BCDE", decode([0x41, 0x42, 0x43, 0x44, 0x45], 1));
  expect("BCD", decode([0xFF, 0x42, 0x43, 0x44, 0xFF], 1, 4));
  expect(() {
    decode([0xFF, 0x42, 0x43, 0x44, 0xFF], 0, 4);
  }, throwsA(isA<ArgumentException>()));
  expect(() {
    decode([0xFF, 0x42, 0x43, 0x44, 0xFF], 1);
  }, throwsA(isA<ArgumentException>()));

  // var allowInvalidCodec = new AsciiCodec(allowInvalid: true);
  var invalidBytes = [0, 1, 0xff, 0xdead, 0];
  String decoded = ASCIIDecoder.decode(invalidBytes, allowMalformed: true);
  expect("\x00\x01\uFFFD\uFFFD\x00", decoded);
  decoded = ASCIIDecoder.decode(invalidBytes, allowMalformed: true);
  expect("\x00\x01\uFFFD\uFFFD\x00", decoded);
  decoded = ASCIIDecoder.decode(invalidBytes, allowMalformed: true);
  expect("\x00\x01\uFFFD\uFFFD\x00", decoded);
}
