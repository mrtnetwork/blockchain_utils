import 'package:blockchain_utils/binary/utils.dart';

extension HEX on List<int> {
  String toHex() => BytesUtils.toHexString(this);
}
