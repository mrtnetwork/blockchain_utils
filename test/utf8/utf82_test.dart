// copied from dart:convert package testcases
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:blockchain_utils/utf8/src/encoder.dart';
import 'package:test/test.dart';
import 'utf81_test.dart';

void main() {
  test("UTF8-2", () {
    for (var test in unicodeTests) {
      List<int> bytes = test[0];
      String string = test[1];
      expect(bytes, UTF8Encoder.encode(string));
    }

    _testEncodeSlice();
  });
}

void _testEncodeSlice() {
  String ascii = "ABCDE";
  expect([0x41, 0x42, 0x43, 0x44, 0x45], UTF8Encoder.encode(ascii));
  expect([
    0x41,
    0x42,
    0x43,
    0x44,
    0x45,
  ], UTF8Encoder.encode(ascii.substring(0)));
  expect([
    0x41,
    0x42,
    0x43,
    0x44,
    0x45,
  ], UTF8Encoder.encode(ascii.substring(0, 5)));
  expect([0x42, 0x43, 0x44, 0x45], UTF8Encoder.encode(ascii.substring(1)));
  expect([0x41, 0x42, 0x43, 0x44], UTF8Encoder.encode(ascii.substring(0, 4)));
  expect([0x42, 0x43, 0x44], UTF8Encoder.encode(ascii.substring(1, 4)));

  var unicode = "\u0081\u0082\u1041\u{10101}";

  expect([
    0xc2,
    0x81,
    0xc2,
    0x82,
    0xe1,
    0x81,
    0x81,
    0xf0,
    0x90,
    0x84,
    0x81,
  ], UTF8Encoder.encode(unicode));
  expect([
    0xc2,
    0x82,
    0xe1,
    0x81,
    0x81,
    0xf0,
    0x90,
    0x84,
    0x81,
  ], UTF8Encoder.encode(unicode.substring(1)));
  expect([
    0xc2,
    0x82,
    0xe1,
    0x81,
    0x81,
  ], UTF8Encoder.encode(unicode.substring(1, 3)));
  // Split in the middle of a surrogate pair.
  expect([
    0xc2,
    0x82,
    0xe1,
    0x81,
    0x81,
    0xef,
    0xbf,
    0xbd,
  ], UTF8Encoder.encode(unicode.substring(1, 4)));
}
