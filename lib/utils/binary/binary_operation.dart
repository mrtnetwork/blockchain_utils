/// Writes a 64-bit unsigned integer value in little-endian byte order to a list.
List<int> writeUint64LE(int value, [List<int>? out, int offset = 0]) {
  out ??= List<int>.filled(8, 0);

  writeUint32LE(value & mask32, out, offset);
  writeUint32LE((value >> 32) & mask32, out, offset + 4);

  return out;
}

/// Writes a 32-bit unsigned integer value in little-endian byte order to a list.
void writeUint32LE(int value, List<int> out, [int offset = 0]) {
  out[offset + 0] = (value & mask8);
  out[offset + 1] = ((value >> 8) & mask8);
  out[offset + 2] = ((value >> 16) & mask8);
  out[offset + 3] = ((value >> 24) & mask8);
}

/// Writes a 16-bit unsigned integer value in little-endian byte order to a list.
void writeUint16LE(int value, List<int> out, [int offset = 0]) {
  out[offset + 0] = (value & mask8);
  out[offset + 1] = ((value >> 8) & mask8);
}

/// Reads a 32-bit unsigned integer value in little-endian byte order from a list.
int readUint32LE(List<int> array, [int offset = 0]) {
  return ((array[offset + 3] << 24) |
          (array[offset + 2] << 16) |
          (array[offset + 1] << 8) |
          array[offset]) &
      mask32;
}

/// Reads a 16-bit unsigned integer value in little-endian byte order from a list.
int readUint16LE(List<int> array, [int offset = 0]) {
  return ((array[offset + 1] << 8) | array[offset]) & mask32;
}

/// Writes a 32-bit unsigned integer value in big-endian byte order to a list.
void writeUint32BE(int value, List<int> out, [int offset = 0]) {
  out[offset + 0] = (value >> 24) & mask8;
  out[offset + 1] = (value >> 16) & mask8;
  out[offset + 2] = (value >> 8) & mask8;
  out[offset + 3] = value & mask8;
}

/// Writes a 16-bit unsigned integer value in big-endian byte order to a list.
void writeUint16BE(int value, List<int> out, [int offset = 0]) {
  out[offset] = (value >> 8) & mask8;
  out[offset + 1] = value & mask8;
}

/// Reads a 32-bit unsigned integer value in big-endian byte order from a list.
int readUint32BE(List<int> array, [int offset = 0]) {
  return ((array[offset] << 24) |
          (array[offset + 1] << 16) |
          (array[offset + 2] << 8) |
          array[offset + 3]) &
      mask32;
}

/// Reads a 16-bit unsigned integer value in big-endian byte order from a list.
int readUint16BE(List<int> data, [int offset = 0]) {
  if (offset < 0 || offset + 2 > data.length) {
    throw RangeError('Index out of bounds');
  }
  return ((data[offset] & mask8) << 8) | (data[offset + 1] & mask8);
}

/// Reads an 8-bit unsigned integer value from a list.
int readUint8(List<int> array, [int offset = 0]) {
  return array[offset] & mask8;
}

/// A constant representing a 32-bit mask with all bits set to 1.
const mask32 = 0xFFFFFFFF;

/// A constant representing a 16-bit mask with all bits set to 1.
const mask16 = 0xFFFF;

/// A constant representing a 13-bit mask with all relevant bits set to 1.
const mask13 = 0x1fff;

/// A constant representing an 8-bit mask with all bits set to 1.
const mask8 = 0xFF;

/// Adds two 32-bit integers and applies a mask to ensure the result fits within 32 bits.
int add32(int x, int y) => (x + y) & mask32;

/// Rotates a 32-bit integer left by a specified number of bits.
int rotl32(int val, int shift) {
  final modShift = shift & 31;
  return ((val << modShift) & mask32) | ((val & mask32) >> (32 - modShift));
}

/// Rotates a 32-bit integer right by a specified number of bits.
int rotr32(int val, int shift) {
  final modShift = shift & 31;
  return ((val >> modShift) & mask32) | ((val & mask32) << (32 - modShift));
}

/// Right-shifts a 32-bit integer by 16 bits and applies a mask to ensure the result fits within 16 bits.
int shr16(int x) {
  return (x >> 16) & mask16;
}

/// Sets all elements in a list to zero.
void zero(List<int> array) {
  for (int i = 0; i < array.length; i++) {
    array[i] = 0;
  }
}

final BigInt maxU64 = BigInt.parse("18446744073709551615");

final BigInt maskBig8 = BigInt.from(mask8);

final BigInt maskBig16 = BigInt.from(mask16);

final BigInt maskBig32 = BigInt.from(mask32);
final BigInt maskBig64 = BigInt.parse("FFFFFFFFFFFFFFFF", radix: 16);

final BigInt minInt64 = BigInt.parse("-9223372036854775808");
final BigInt maxInt64 = BigInt.parse("9223372036854775807");

const int maxInt32 = 2147483647;
const int minInt32 = -2147483648;

const int maxUint32 = 4294967295;

const int safeUint = 9007199254740991;
const int safeInt = -9007199254740991;
