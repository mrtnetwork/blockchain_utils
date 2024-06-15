import 'package:blockchain_utils/utils/utils.dart';

class Crc16 {
  static const int _poly = 0x1021;

  static List<int> quickIntDigest(List<int> data) {
    int reg = 0;
    List<int> message = List<int>.filled(data.length + 2, 0);
    message.setAll(0, data);

    for (int byte in message) {
      int mask = 0x80;
      while (mask > 0) {
        reg <<= 1;
        if (byte & mask != 0) {
          reg += 1;
        }
        mask >>= 1;
        if (reg > mask16) {
          reg &= mask16;
          reg ^= _poly;
        }
      }
    }
    return List<int>.from([reg >> 8, reg & mask8]);
  }
}
