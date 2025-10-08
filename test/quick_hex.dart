import 'package:blockchain_utils/utils/utils.dart';

extension HEX on List<int> {
  String toHex() => BytesUtils.toHexString(this);
}
