// copied from dart:convert package testcases
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:blockchain_utils/utf8/src/deocder.dart';
import 'package:test/test.dart';

String _decode(List<int> bytes) {
  return UTF8Decoder.decode(bytes);
}

String _malformed(List<int> bytes) {
  return UTF8Decoder.decode(bytes, allowMalformed: true);
}

void main() {
  test("UTF8-4", () {
    expect("a", _decode([0xEF, 0xBB, 0xBF, 0x61]));
    expect("a", _decode([0xEF, 0xBB, 0xBF, 0x61]));
    expect("a", _decode([0xEF, 0xBB, 0xBF, 0x61]));
    expect("a", _decode([0xEF, 0xBB, 0xBF, 0x61]));
    expect("a", _malformed([0xEF, 0xBB, 0xBF, 0x61]));
    expect("a", _malformed([0xEF, 0xBB, 0xBF, 0x61]));
    expect("a", _malformed([0xEF, 0xBB, 0xBF, 0x61]));
    expect("a", _malformed([0xEF, 0xBB, 0xBF, 0x61]));
    expect("", _decode([0xEF, 0xBB, 0xBF]));
    expect("", _decode([0xEF, 0xBB, 0xBF]));
    expect("", _decode([0xEF, 0xBB, 0xBF]));
    expect("", _decode([0xEF, 0xBB, 0xBF]));
    expect("", _malformed([0xEF, 0xBB, 0xBF]));
    expect("", _malformed([0xEF, 0xBB, 0xBF]));
    expect("", _malformed([0xEF, 0xBB, 0xBF]));
    expect("", _malformed([0xEF, 0xBB, 0xBF]));
    expect("a\u{FEFF}", _decode([0x61, 0xEF, 0xBB, 0xBF]));
    expect("a\u{FEFF}", _decode([0x61, 0xEF, 0xBB, 0xBF]));
    expect("a\u{FEFF}", _decode([0x61, 0xEF, 0xBB, 0xBF]));
    expect("a\u{FEFF}", _decode([0x61, 0xEF, 0xBB, 0xBF]));
    expect("a\u{FEFF}", _malformed([0x61, 0xEF, 0xBB, 0xBF]));
    expect("a\u{FEFF}", _malformed([0x61, 0xEF, 0xBB, 0xBF]));
    expect("a\u{FEFF}", _malformed([0x61, 0xEF, 0xBB, 0xBF]));
    expect("a\u{FEFF}", _malformed([0x61, 0xEF, 0xBB, 0xBF]));
  });
}
