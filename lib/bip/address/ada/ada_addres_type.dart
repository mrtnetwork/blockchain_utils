import 'package:blockchain_utils/exception/exception.dart';

class ADAAddressType {
  final int header;
  final String name;
  const ADAAddressType._(this.header, this.name);

  static const ADAAddressType base = ADAAddressType._(0x00, "Base");
  static const ADAAddressType reward = ADAAddressType._(0x0E, "Reward");
  static const ADAAddressType enterprise = ADAAddressType._(0x06, "Enterprise");
  static const ADAAddressType pointer = ADAAddressType._(0x04, "Pointer");
  static const ADAAddressType byron = ADAAddressType._(0x8, "Byron");
  static ADAAddressType decodeAddressType(int header) {
    switch ((header & 0xF0) >> 4) {
      case 0x00:
      case 0x01:
      case 0x02:
      case 0x03:
        return ADAAddressType.base;
      case 0xe:
      case 0xf:
        return ADAAddressType.reward;
      case 0x06:
      case 0x07:
        return ADAAddressType.enterprise;
      case 0x04:
      case 0x05:
        return ADAAddressType.pointer;
      case 0x8:
        return ADAAddressType.byron;
    }
    throw MessageException("Invalid address header bytes.",
        details: {"value": header});
  }

  @override
  String toString() {
    return "ADAAddressType.$name";
  }
}
