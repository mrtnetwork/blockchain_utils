/// Class container for bit utility functions.
class BitUtils {
  /// Get if the specified bit is set.
  static bool intIsBitSet(int value, int bitNum) {
    return (value & (1 << bitNum)) != 0;
  }

  /// Get if the specified bits are set.
  static bool areBitsSet(int value, int bitMask) {
    return (value & bitMask) != 0;
  }

  /// Set the specified bit.
  static int setBit(int value, int bitNum) {
    return value | (1 << bitNum);
  }

  /// Set the specified bits.
  static int setBits(int value, int bitMask) {
    return value | bitMask;
  }

  /// Reset the specified bit.
  static int resetBit(int value, int bitNum) {
    return value & ~(1 << bitNum);
  }

  /// Reset the specified bits.
  static int resetBits(int value, int bitMask) {
    return value & ~bitMask;
  }
}
