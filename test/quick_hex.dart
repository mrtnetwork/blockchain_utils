import 'package:blockchain_utils/utils/utils.dart';

extension ExtHEX on List<int> {
  String toHex() => BytesUtils.toHexString(this);
}
