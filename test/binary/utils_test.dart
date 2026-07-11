import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

void main() {
  test("leading zero", _testLeading3);
  test("leading zero", _testLeading);
  test("trailing zero", _testTrimTrailingZero3);
  test("trailing zero", _testTrimTrailingZero4);
}

void _testTrimTrailingZero4() {
  final bytes = List<int>.filled(512, 0);
  final n = List<int>.filled(12, 12);
  bytes.setAll(10, n);
  final leading = BytesUtils.trimLeadingZero(
    BytesUtils.trimTrailingZero(bytes),
  );
  expect(bytes.sublist(10, 22), leading);
}

void _testTrimTrailingZero3() {
  final bytes = List<int>.empty();
  final leading = BytesUtils.trimTrailingZero(bytes);
  expect([], leading);
}

void _testLeading() {
  final bytes = List<int>.filled(5, 0);
  bytes.setAll(3, [1, 1]);
  final leading = BytesUtils.trimLeadingZero(bytes);
  expect(bytes.sublist(3), leading);
}

void _testLeading3() {
  final bytes = <int>[];
  final leading = BytesUtils.trimLeadingZero(bytes);
  expect([], leading);
}
