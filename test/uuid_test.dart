import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

void main() {
  List<int> buffer1 = List<int>.from(
      [174, 91, 168, 91, 107, 15, 78, 26, 181, 132, 151, 91, 160, 7, 157, 152]);
  List<int> buffer2 = List<int>.from([
    42,
    118,
    243,
    204,
    168,
    139,
    49,
    8,
    163,
    241,
    253,
    29,
    91,
    63,
    219,
    178
  ]);
  List<int> buffer3 = List<int>.from(
      [115, 181, 16, 102, 139, 73, 65, 95, 181, 34, 94, 80, 60, 118, 197, 55]);
  List<int> buffer4 = List<int>.from([
    215,
    154,
    165,
    99,
    152,
    96,
    226,
    52,
    181,
    118,
    60,
    118,
    136,
    156,
    165,
    177
  ]);
  List<int> buffer5 = List<int>.from(
      [97, 148, 163, 150, 135, 56, 166, 2, 171, 26, 194, 71, 2, 140, 199, 132]);

  // Test cases for UUID operations
  test("testUUid", () {
    // Verify that UUIDs can be created from the buffers and match the expected values
    expect(UUID.fromBuffer(buffer1), "ae5ba85b-6b0f-4e1a-b584-975ba0079d98");
    expect(UUID.fromBuffer(buffer2), "2a76f3cc-a88b-3108-a3f1-fd1d5b3fdbb2");
    expect(UUID.fromBuffer(buffer3), "73b51066-8b49-415f-b522-5e503c76c537");
    expect(UUID.fromBuffer(buffer4), "d79aa563-9860-e234-b576-3c76889ca5b1");
    expect(UUID.fromBuffer(buffer5), "6194a396-8738-a602-ab1a-c247028cc784");

    // Generate a random UUIDv4, validate it, and convert it to a buffer and back to UUID
    final uuid = UUID.generateUUIDv4();
    expect(UUID.isValidUUIDv4(uuid), true);
    expect(UUID.fromBuffer(UUID.toBuffer(uuid)), uuid);
  });
}
