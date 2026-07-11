import 'dart:typed_data';
import 'package:blockchain_utils/crypto/crypto/zcrypto/jubjub/jubjub.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/pedersen_hash/src/constants.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/pedersen_hash/src/exception.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/utils/numbers/utils/bigint_utils.dart';

sealed class Personalization {
  List<bool> getBits();
}

class PersonalizationNoteCommitment implements Personalization {
  const PersonalizationNoteCommitment();
  @override
  List<bool> getBits() {
    return [true, true, true, true, true, true];
  }
}

class PersonalizationMerkleTree implements Personalization {
  final int size;
  const PersonalizationMerkleTree(this.size);

  @override
  List<bool> getBits() {
    return List.generate(6, (i) => ((size >> i) & 1) == 1);
  }
}

abstract class BasePedersenHash<
  T extends JubJubScalar<T>,
  E extends BaseJubJubPoint<T, E>
> {
  final List<List<List<E>>> _generators;
  BasePedersenHash._(List<List<List<E>>> generators)
    : _generators =
          generators
              .map((e) => e.map((e) => e.toImutableList).toImutableList)
              .toImutableList;
  E _hash({
    required Personalization personalization,
    required List<bool> inputBits,
    required T one,
    required T zero,
    required E identity,
  }) {
    final Iterator<bool> bits =
        [...personalization.getBits(), ...inputBits].iterator;
    E result = identity;
    List<List<List<E>>> generators = _generators;
    int generatorIndex = 0;

    while (true) {
      T acc = zero;
      T cur = one;
      int chunksRemaining = PedersenUtils.pedersenHashChunksPerGenerator;
      bool encounteredBits = false;

      while (bits.moveNext()) {
        encounteredBits = true;

        bool a = bits.current;
        bool b = bits.moveNext() ? bits.current : false;
        bool c = bits.moveNext() ? bits.current : false;
        T tmp = cur;
        if (a) {
          tmp += cur;
        }
        cur = (cur + cur);
        if (b) {
          tmp += cur;
        }
        if (c) {
          tmp = -tmp;
        }
        acc += tmp;
        chunksRemaining--;
        if (chunksRemaining == 0) break;
        cur = cur.double().double().double();
      }

      if (!encounteredBits) break;

      if (generatorIndex >= generators.length) {
        throw PedersenHashException.failed(
          "hash",
          reason: "Invalid generator length.",
        );
      }

      List<List<E>> table = generators[generatorIndex++];
      int window = PedersenUtils.pedersenHashExpWindowSize;
      BigInt windowMask = (BigInt.one << window) - BigInt.one;
      final accBytes = acc.toBytes();
      final numLimbs = accBytes.length ~/ 8;
      List<BigInt> limbs = List.filled(numLimbs + 1, BigInt.zero);
      for (int i = 0; i < numLimbs; i++) {
        List<int> chunk = accBytes.sublist(i * 8, i * 8 + 8);
        limbs[i] = BigintUtils.fromBytes(chunk, byteOrder: Endian.little);
      }
      E tmp = identity;
      int pos = 0;
      int tableIndex = 0;

      while (pos < JubJubFrConst.bits) {
        int u64Idx = pos ~/ 64;
        int bitIdx = pos % 64;
        int i;
        if ((bitIdx + window) < 64) {
          i = ((limbs[u64Idx] >> bitIdx) & windowMask).toIntOrThrow;
        } else {
          i =
              (((limbs[u64Idx] >> bitIdx).toU64 |
                          (limbs[u64Idx + 1] << (64 - bitIdx)).toU64) &
                      windowMask)
                  .toIntOrThrow;
        }
        tmp += table[tableIndex][i];

        pos += window;
        tableIndex++;
      }
      result += tmp;
    }
    return result;
  }
}

class PedersenHash extends BasePedersenHash<JubJubFr, JubJubPoint> {
  PedersenHash._(super.generators) : super._();
  factory PedersenHash({List<List<List<JubJubPoint>>>? generators}) {
    generators ??=
        PedersenUtils.generatePedersenHashExpTable<JubJubFr, JubJubPoint>(
          fromBytes: JubJubPoint.fromBytes,
          identity: JubJubPoint.identity(),
        );
    return PedersenHash._(generators);
  }
  JubJubPoint hash({
    required Personalization personalization,
    required List<bool> inputBits,
  }) {
    return _hash(
      personalization: personalization,
      inputBits: inputBits,
      identity: JubJubPoint.identity(),
      one: JubJubFr.one(),
      zero: JubJubFr.zero(),
    );
  }
}

class PedersenHashNative
    extends BasePedersenHash<JubJubNativeFr, JubJubNativePoint> {
  PedersenHashNative._(super.generators) : super._();
  factory PedersenHashNative({
    List<List<List<JubJubNativePoint>>>? generators,
  }) {
    generators ??= PedersenUtils.generatePedersenHashExpTable<
      JubJubNativeFr,
      JubJubNativePoint
    >(
      fromBytes: JubJubNativePoint.fromBytes,
      identity: JubJubNativePoint.identity(),
    );
    return PedersenHashNative._(generators);
  }
  JubJubNativePoint hash({
    required Personalization personalization,
    required List<bool> inputBits,
  }) {
    return _hash(
      personalization: personalization,
      inputBits: inputBits,
      identity: JubJubNativePoint.identity(),
      one: JubJubNativeFr.one(),
      zero: JubJubNativeFr.zero(),
    );
  }
}
