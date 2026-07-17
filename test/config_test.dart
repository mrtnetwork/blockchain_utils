@TestOn("!vm")
library;

import 'package:blockchain_utils/numbers/src/word_math/word_math.dart';
import 'package:test/test.dart';

void main() {
  test("Check native math", () {
    expect(useNativeWordMath, false);
  });
}
