import 'package:blockchain_utils/blockchain_utils.dart';

class PedersenUtils {
  static const int pedersenHashExpWindowSize = 8;
  static const int pedersenHashChunksPerGenerator = 63;
  static List<List<List<E>>> generatePedersenHashExpTable<
    T extends JubJubScalar<T>,
    E extends BaseJubJubPoint<T, E>
  >({required E Function(List<int> bytes) fromBytes, required E identity}) {
    final List<E> generators = generateHash<T, E>(fromBytes);
    final int window = pedersenHashExpWindowSize;
    final int numBits = JubJubFrConst.bits;
    final List<List<List<E>>> result = [];
    for (var g0 in generators) {
      E g = g0;
      final List<List<E>> tables = [];
      int numBitsProcessed = 0;

      while (numBitsProcessed <= numBits) {
        final List<E> table = [];
        E base = identity;

        for (int i = 0; i < (1 << window); i++) {
          table.add(base);
          base = base + g;
        }

        tables.add(table);
        numBitsProcessed += window;

        // double g for next window
        for (int i = 0; i < window; i++) {
          g = g.double();
        }
      }

      result.add(tables);
    }

    return result;
  }

  static List<E>
  generateHash<T extends JubJubScalar<T>, E extends BaseJubJubPoint<T, E>>(
    E Function(List<int> bytes) fromBytes, {
    String personalization = "Zcash_PH",
    int length = 6,
  }) {
    List<E> points = [];
    for (int i = 0; i < length; i++) {
      final r = findGroupHash<T, E>(
        message: i.toU32LeBytes(),
        personalization: personalization.codeUnits,
        fromBytes: fromBytes,
      );
      points.add(r);
    }
    return points;
  }

  static E
  findGroupHash<T extends JubJubScalar<T>, E extends BaseJubJubPoint<T, E>>({
    required List<int> message,
    required List<int> personalization,
    required E Function(List<int> bytes) fromBytes,
  }) {
    if (personalization.length != 8) {
      throw ArgumentException.invalidOperationArguments(
        "findGroupHash",
        reason: 'Invalid personalization bytes length.',
      );
    }
    final tag = List<int>.from(message);
    final i = tag.length;
    tag.add(0);

    while (true) {
      final gh = SaplingKeyUtils.groupHash<T, E>(
        tag: tag,
        personalization: personalization,
        fromBytes: fromBytes,
      );
      if (tag[i] == BinaryOps.mask8) {
        throw PedersenHashException.failed(
          "findGroupHash",
          reason: "tag counter overflow.",
        );
      }

      tag[i]++;

      if (gh != null) {
        return gh;
      }
    }
  }
}
