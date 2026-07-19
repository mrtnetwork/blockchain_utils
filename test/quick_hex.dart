import 'package:blockchain_utils/utils/utils.dart';

const int iteration = int.fromEnvironment("ITER", defaultValue: 0);
const bool native = bool.fromEnvironment('dart.library.io');

extension ExtHEX on List<int> {
  String toHex() => BytesUtils.toHexString(this);
}

extension TAKE on List<Map<String, dynamic>> {
  List<Map<String, dynamic>> shuffleTake([int? total]) {
    return this;
  }
}
