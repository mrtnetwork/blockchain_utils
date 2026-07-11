import 'package:blockchain_utils/bip/address/exception/exception.dart';

enum ADAAddressType {
  base(0x00, "Base"),
  reward(0x0E, "Reward"),
  enterprise(0x06, "Enterprise"),
  pointer(0x04, "Pointer"),
  byron(0x8, "Byron");

  final int header;
  final String name;
  const ADAAddressType(this.header, this.name);
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
    throw AddressConverterException.addressKeyValidationFailed(
      reason: "Invalid address prefix.",
      details: {"value": header.toString()},
    );
  }

  static ADAAddressType fromHeader(int? header) {
    return values.firstWhere(
      (element) => element.header == header,
      orElse:
          () =>
              throw const AddressConverterException(
                "Invalid header value encountered.",
              ),
    );
  }

  @override
  String toString() {
    return "ADAAddressType.$name";
  }

  bool get isShelly => this != byron;
}
