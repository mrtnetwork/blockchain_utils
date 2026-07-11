class BinaryOps {
  /// Writes a 64-bit unsigned integer value in little-endian byte order to a list.
  static List<int> writeUint64LE(int value, [List<int>? out, int offset = 0]) {
    out ??= List<int>.filled(8, 0);

    writeUint32LE(value & mask32, out, offset);
    writeUint32LE((value >> 32) & mask32, out, offset + 4);

    return out;
  }

  /// Writes a 32-bit unsigned integer value in little-endian byte order to a list.
  static void writeUint32LE(int value, List<int> out, [int offset = 0]) {
    out[offset + 0] = (value & mask8);
    out[offset + 1] = ((value >> 8) & mask8);
    out[offset + 2] = ((value >> 16) & mask8);
    out[offset + 3] = ((value >> 24) & mask8);
  }

  /// Writes a 16-bit unsigned integer value in little-endian byte order to a list.
  static void writeUint16LE(int value, List<int> out, [int offset = 0]) {
    out[offset + 0] = (value & mask8);
    out[offset + 1] = ((value >> 8) & mask8);
  }

  /// Reads a 32-bit unsigned integer value in little-endian byte order from a list.
  static int readUint32LE(List<int> array, [int offset = 0]) {
    return ((array[offset + 3] << 24) |
            (array[offset + 2] << 16) |
            (array[offset + 1] << 8) |
            array[offset]) &
        mask32;
  }

  // /// Reads a 16-bit unsigned integer value in little-endian byte order from a list.
  static int readUint16LE(List<int> array, [int offset = 0]) {
    return ((array[offset + 1] << 8) | array[offset]) & mask32;
  }

  /// Writes a 32-bit unsigned integer value in big-endian byte order to a list.
  static void writeUint32BE(int value, List<int> out, [int offset = 0]) {
    out[offset + 0] = (value >> 24) & mask8;
    out[offset + 1] = (value >> 16) & mask8;
    out[offset + 2] = (value >> 8) & mask8;
    out[offset + 3] = value & mask8;
  }

  // /// Writes a 16-bit unsigned integer value in big-endian byte order to a list.
  static void writeUint16BE(int value, List<int> out, [int offset = 0]) {
    out[offset] = (value >> 8) & mask8;
    out[offset + 1] = value & mask8;
  }

  /// Reads a 32-bit unsigned integer value in big-endian byte order from a list.
  static int readUint32BE(List<int> array, [int offset = 0]) {
    return ((array[offset] << 24) |
            (array[offset + 1] << 16) |
            (array[offset + 2] << 8) |
            array[offset + 3]) &
        mask32;
  }

  /// A constant representing a 32-bit mask with all bits set to 1.
  static const mask32 = 0xFFFFFFFF;

  /// A constant representing a 32-bit mask with all bits set to 1.
  static const mask24 = 0xFFFFFF;

  /// A constant representing a 16-bit mask with all bits set to 1.
  static const mask16 = 0xFFFF;

  /// A constant representing a 13-bit mask with all relevant bits set to 1.
  static const mask13 = 0x1fff;

  /// A constant representing an 8-bit mask with all bits set to 1.
  static const mask8 = 0xFF;

  /// Adds two 32-bit integers and applies a mask to ensure the result fits within 32 bits.
  static int add32(int x, int y) => (x + y) & mask32;

  /// Rotates a 32-bit integer left by a specified number of bits.
  static int rotl32(int val, int shift) {
    final modShift = shift & 31;
    return ((val << modShift) & mask32) | ((val & mask32) >> (32 - modShift));
  }

  /// Rotates a 32-bit integer right by a specified number of bits.
  static int rotr32(int val, int shift) {
    final modShift = shift & 31;
    return ((val >> modShift) & mask32) | ((val & mask32) << (32 - modShift));
  }

  /// Right-shifts a 32-bit integer by 16 bits and applies a mask to ensure the result fits within 16 bits.
  static int shr16(int x) {
    return (x >> 16) & mask16;
  }

  /// Sets all elements in a list to zero.
  static void zero(List<int> array) {
    for (int i = 0; i < array.length; i++) {
      array[i] = 0;
    }
  }

  static final BigInt maxU64 = BigInt.parse("18446744073709551615");
  static final BigInt maxU128 = BigInt.parse(
    "340282366920938463463374607431768211455",
  );
  static final BigInt maxU256 = BigInt.parse(
    "115792089237316195423570985008687907853269984665640564039457584007913129639935",
  );

  static final BigInt maskBig8 = BigInt.from(mask8);

  static final BigInt maskBig16 = BigInt.from(mask16);

  static final BigInt maskBig32 = BigInt.from(mask32);
  static final BigInt maskBig64 = BigInt.parse("FFFFFFFFFFFFFFFF", radix: 16);

  static final BigInt minInt64 = BigInt.parse("-9223372036854775808");
  static final BigInt maxInt64 = BigInt.parse("9223372036854775807");
  static final BigInt minI128 = BigInt.parse(
    "-170141183460469231731687303715884105728",
  );

  static final BigInt maxI128 = BigInt.parse(
    "170141183460469231731687303715884105727",
  );
  static const int maxInt32 = 2147483647;
  static const int minInt32 = -2147483648;

  static const int maxUint32 = 4294967295;

  static const int safeUint = 9007199254740991;
  static const int safeInt = -9007199254740991;
}
