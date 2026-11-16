import 'package:blockchain_utils/crypto/crypto/group/pasta/constants/pallas.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/crypto/crypto/group/pasta/fields/core.dart';
import 'package:blockchain_utils/crypto/crypto/group/pasta/fields/pallas_fp.dart';
import 'package:blockchain_utils/crypto/crypto/group/pasta/fields/vesta_fq.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/utils/numbers/fixed/src/u64/u64.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// The MDS matrix and its inverse, produced during Poseidon setup.
class MdsGenerateResult<F extends PastaFieldElement<F>> {
  final List<List<F>> mds;
  final List<List<F>> mdsInv;
  final List<List<F>> constants;
  MdsGenerateResult({
    required List<List<F>> mds,
    required List<List<F>> mdsInv,
    List<List<F>> constants = const [],
  }) : mds = mds.immutable,
       mdsInv = mdsInv.immutable,
       constants = constants.immutable;
}

/// Which prime field a Poseidon instance operates over.
enum FieldType {
  binary(0),
  primeOrder(1);

  final int tag;
  const FieldType(this.tag);
}

/// Which S-box a Poseidon instance uses.
enum SboxType {
  pow(0),
  inv(1);

  final int tag;
  const SboxType(this.tag);
}

/// The Grain LFSR used to derive Poseidon round constants.
class Grain<F extends PastaFieldElement<F>> {
  final int numBits;
  final F Function(List<int>) fromBytes;
  List<bool> _state;
  List<bool> get state => _state;
  int _nextBit;
  int get length => _state.length;
  int get nextBit => _nextBit;
  Grain._({
    required List<bool> state,
    required int nextBit,
    required this.numBits,
    required this.fromBytes,
  }) : _state = state,
       _nextBit = nextBit;

  /// Equivalent to the Rust constructor new(...)
  factory Grain({
    required SboxType sbox,
    required int t,
    required int rF,
    required int rP,
    required F Function(List<int> bytes) fromBytes,
    int length = 80,
  }) {
    List<bool> state = List<bool>.filled(length, true);
    void setBits(int offset, int len, int value) {
      for (int i = 0; i < len; i++) {
        int bit = (value >> i) & 1;
        state[offset + (len - 1 - i)] = bit == 1;
      }
    }

    final numBits = PallasFPConst.numBits;

    // Equivalent to Rust:
    // set_bits(0, 2, FieldType::PrimeOrder.tag() as u16);
    setBits(0, 2, FieldType.primeOrder.tag);

    // set_bits(2, 4, sbox.tag() as u16);
    setBits(2, 4, sbox.tag);

    // set_bits(6, 12, F::NUM_BITS as u16);
    setBits(6, 12, numBits);

    // set_bits(18, 12, t);
    setBits(18, 12, t);

    // set_bits(30, 10, r_f);
    setBits(30, 10, rF);

    // set_bits(40, 10, r_p);
    setBits(40, 10, rP);
    final grain = Grain<F>._(
      state: state,
      nextBit: length,
      numBits: numBits,
      fromBytes: fromBytes,
    );

    // discard first 160 bits (20 × 8 bits)
    for (int i = 0; i < 20; i++) {
      grain._loadNext8Bits();
      grain._nextBit = length; // identical to Rust: grain.next_bit = STATE;
    }

    return grain;
  }

  void _loadNext8Bits() {
    int newBits = 0;

    for (int i = 0; i < 8; i++) {
      final bit =
          (state[i + 62] ^
                  state[i + 51] ^
                  state[i + 38] ^
                  state[i + 23] ^
                  state[i + 13] ^
                  state[i])
              ? 1
              : 0;

      newBits |= (bit << i);
    }

    // rotate left by 8
    final rotated = [...state.sublist(8), ...state.sublist(0, 8)];
    _state = rotated;

    _nextBit -= 8;

    for (int i = 0; i < 8; i++) {
      _state[nextBit + i] = ((newBits >> i) & 1) != 0;
    }
  }

  bool _getNextBit() {
    if (nextBit == length) {
      _loadNext8Bits();
    }

    final ret = state[nextBit];
    _nextBit += 1;
    return ret;
  }

  F nextFieldElement() {
    while (true) {
      List<int> bytes = List<int>.filled(32, 0);
      final bits = _takeBits(numBits).toList();
      for (int i = 0; i < bits.length; i++) {
        int revIndex = numBits - 1 - i;
        int byteIndex = revIndex ~/ 8;
        int bitIndex = revIndex % 8;
        if (bits[i]) {
          bytes[byteIndex] |= (1 << bitIndex);
        }
      }
      try {
        return fromBytes(bytes);
      } catch (e) {
        continue;
      }
    }
  }

  F nextFieldElementWithoutRejection() {
    List<int> bytes = List<int>.filled(64, 0);
    final bits = _takeBits(numBits).toList();
    for (int i = 0; i < bits.length; i++) {
      int revIndex = numBits - 1 - i;
      int byteIndex = revIndex ~/ 8;
      int bitIndex = revIndex % 8;
      if (bits[i]) {
        bytes[byteIndex] |= (1 << bitIndex);
      }
    }
    return fromBytes(bytes);
  }

  Iterable<bool> _takeBits(int count) sync* {
    bool next() {
      while (!_getNextBit()) {
        _getNextBit();
      }
      return _getNextBit();
    }

    for (int i = 0; i < count; i++) {
      yield next();
    }
  }
}

class P128Pow5T3Fp extends PoseidonSpec<PallasFp> {
  P128Pow5T3Fp._(super.constants);
  factory P128Pow5T3Fp({MdsGenerateResult<PallasFp>? constants}) {
    if (constants != null && !PoseidonSpec.isValidConstants(constants)) {
      throw CoreErrors.invalidOperationArguments(
        "P128Pow5T3Fp",
        reason: "Invalid constants length.",
      );
    }
    constants ??= PoseidonUtils.generateConstants<PallasFp>(
      fromBytes: (bytes) {
        if (bytes.length == 32) {
          return PallasFp.fromBytes(bytes);
        }
        return PallasFp.fromBytes64(bytes);
      },
      zero: PallasFp.zero,
      one: PallasFp.one,
    );
    return P128Pow5T3Fp._(constants);
  }

  @override
  PallasFp fromBytes(List<int> bytes) {
    if (bytes.length == 32) {
      return PallasFp.fromBytes(bytes);
    }
    return PallasFp.fromBytes64(bytes);
  }

  @override
  PallasFp zero() {
    return PallasFp.zero;
  }

  @override
  PallasFp rateField() {
    return PallasFp.fromU128(BigInt.from(rate()) << 64);
  }

  @override
  PallasFp sbox(PallasFp field) {
    return field.pow([Uint64(5), Uint64.zero, Uint64.zero, Uint64.zero]);
  }
}

class P128Pow5T3Fq extends PoseidonSpec<VestaFq> {
  P128Pow5T3Fq._(super.constants);
  factory P128Pow5T3Fq({MdsGenerateResult<VestaFq>? constants}) {
    if (constants != null && !PoseidonSpec.isValidConstants(constants)) {
      throw CoreErrors.invalidOperationArguments(
        "P128Pow5T3Fq",
        reason: "Invalid constants length.",
      );
    }
    constants ??= PoseidonUtils.generateConstants<VestaFq>(
      fromBytes: (bytes) {
        if (bytes.length == 32) {
          return VestaFq.fromBytes(bytes);
        }
        return VestaFq.fromBytes64(bytes);
      },
      zero: VestaFq.zero,
      one: VestaFq.one,
    );
    return P128Pow5T3Fq._(constants);
  }

  @override
  VestaFq fromBytes(List<int> bytes) {
    if (bytes.length == 32) {
      return VestaFq.fromBytes(bytes);
    }
    return VestaFq.fromBytes64(bytes);
  }

  @override
  VestaFq zero() {
    return VestaFq.zero;
  }

  @override
  VestaFq rateField() {
    return VestaFq.fromU128(BigInt.from(rate()) << 64);
  }

  @override
  VestaFq sbox(VestaFq field) {
    return field.pow([Uint64(5), Uint64.zero, Uint64.zero, Uint64.zero]);
  }
}

/// Helpers for deriving Poseidon round constants and MDS matrices.
class PoseidonUtils {
  static const int rate = 2;
  static const int width = 3;
  static void permute<F extends PastaFieldElement<F>>(
    List<F> state,
    PoseidonSpec<F> spec,
  ) {
    final constants = spec.constants;
    final mds = constants.mds;
    final roundConstants = constants.constants;
    final int t = state.length;
    final int rF = spec.fullRounds() ~/ 2;
    final int rP = spec.partialRounds();
    final F zero = spec.zero();
    // Matrix multiplication
    void applyMds(List<F> s) {
      final newState = List<F>.filled(t, zero);
      for (int i = 0; i < t; i++) {
        for (int j = 0; j < t; j++) {
          newState[i] = newState[i] + (mds[i][j] * s[j]);
        }
      }
      for (int i = 0; i < t; i++) {
        s[i] = newState[i];
      }
    }

    // Full round: apply S-box to all state words
    void fullRound(List<F> s, List<F> rcs) {
      for (int i = 0; i < t; i++) {
        s[i] = spec.sbox(s[i] + rcs[i]);
      }
      applyMds(s);
    }

    // Partial round: S-box only on first state word
    void partialRound(List<F> s, List<F> rcs) {
      for (int i = 0; i < t; i++) {
        s[i] = s[i] + rcs[i];
      }
      s[0] = spec.sbox(s[0]);
      applyMds(s);
    }

    // Sequence of rounds: rF full rounds, rP partial rounds, rF full rounds
    final rounds = <void Function(List<F>, List<F>)>[];
    rounds.addAll(List.filled(rF, fullRound));
    rounds.addAll(List.filled(rP, partialRound));
    rounds.addAll(List.filled(rF, fullRound));

    // Apply rounds in order with corresponding round constants
    for (int i = 0; i < rounds.length; i++) {
      rounds[i](state, roundConstants[i]);
    }
  }

  static Squeezing<F> poseidonSponge<F extends PastaFieldElement<F>>(
    List<F> state,
    Absorbing<F>? input,
    PoseidonSpec<F> spec,
  ) {
    final rate = spec.rate();
    if (input != null) {
      for (int i = 0; i < state.length && i < input._fields.length; i++) {
        final value = input._fields[i];
        if (value == null) {
          throw CoreErrors.invalidOperationArguments(
            "poseidonSponge",
            reason:
                "Invalid State: this operation is not permitted in the current mode",
          );
        }
        state[i] = state[i] + value;
      }
    }
    // Apply Poseidon permutation
    permute(state, spec);
    // Prepare output (take first RATE words from state)
    final output = List<F?>.filled(rate, null);
    for (int i = 0; i < rate && i < state.length; i++) {
      output[i] = state[i];
    }
    return Squeezing<F>(output);
  }

  static MdsGenerateResult<F> generateMds<F extends PastaFieldElement<F>>(
    Grain<F> grain,
    int t,
    int select,
    F one,
    F zero,
  ) {
    List<F> xs = [];
    List<F> ys = [];
    List<List<F>> mds = [];
    int counter = select;
    while (true) {
      // Generate two lists of unique field elements
      while (true) {
        List<F> vals = List.generate(
          2 * t,
          (_) => grain.nextFieldElementWithoutRejection(),
        );

        // Check uniqueness
        List<F> unique = List.from(vals);
        unique.sort((a, b) => a.compareTo(b));
        unique = unique.toSet().toList();

        if (vals.length == unique.length) {
          xs = vals.sublist(0, t);
          ys = vals.sublist(t);
          break;
        }
      }

      // Skip if select counter not yet zero
      if (counter != 0) {
        counter -= 1;
        continue;
      }

      // Generate MDS matrix: a_ij = 1 / (x_i + y_j)
      mds = List.generate(
        t,
        (i) => List.generate(t, (j) {
          final sum = xs[i] + ys[j];
          final s = sum.invert();
          if (s == null) {
            throw BuError(
              DefaultErrorType.invalidArgument,
              "Division by zero.",
            );
          }
          return s;
        }),
      );

      break;
    }

    // Compute inverse MDS
    List<List<F>> mdsInv = List.generate(
      t,
      (_) => List.generate(t, (_) => zero),
    );

    F lagrange(List<F> arr, int j, F x) {
      final xj = arr[j];
      F acc = one;
      for (int m = 0; m < arr.length; m++) {
        if (m == j) continue;
        final denom = xj - arr[m];
        final denomInv = denom.invert();
        if (denomInv == null) {
          throw BuError(DefaultErrorType.invalidArgument, "Division by zero.");
        }
        acc = acc * (x - arr[m]) * denomInv;
      }
      return acc;
    }

    // Negate ys for positive Cauchy formulation
    final negYs = ys.map((y) => -y).toList();

    for (int i = 0; i < t; i++) {
      for (int j = 0; j < t; j++) {
        mdsInv[i][j] =
            (xs[j] - negYs[i]) *
            lagrange(xs, j, negYs[i]) *
            lagrange(negYs, i, xs[j]);
      }
    }
    return MdsGenerateResult(mds: mds, mdsInv: mdsInv);
  }

  static MdsGenerateResult<F>
  generateConstants<F extends PastaFieldElement<F>>({
    required F Function(List<int> bytes) fromBytes,
    required F zero,
    required F one,
    int rate = 2,
    int width = 3,
    int fullRounds = 8,
    int partialRounds = 56,
    int secureMds = 0,
  }) {
    final sbox = SboxType.pow;
    final Grain<F> grain = Grain<F>(
      sbox: sbox,
      t: width,
      fromBytes: fromBytes,
      rF: fullRounds,
      rP: partialRounds,
    );
    final iter = fullRounds + partialRounds;
    final roundConstants = List<List<F>>.generate(iter, (_) {
      return List<F>.generate(width, (i) => grain.nextFieldElement());
    });
    final mds = generateMds<F>(grain, width, secureMds, one, zero);
    return MdsGenerateResult(
      mds: mds.mds,
      mdsInv: mds.mdsInv,
      constants: roundConstants,
    );
  }
}

abstract class SpongeMode<F extends Object> {
  final List<F?> _fields;
  List<F?> get fields => _fields.clone();
  const SpongeMode(List<F?> fields) : _fields = fields;
  F? squeeze() => null;
  F absorb(F value) =>
      throw BuError(DefaultErrorType.invalidState, "Sponge is full.");
}

class Squeezing<F extends Object> extends SpongeMode<F> {
  const Squeezing(super.field);
  @override
  F? squeeze() {
    for (int i = 0; i < _fields.length; i++) {
      final e = _fields[i];
      if (e != null) {
        _fields[i] = null;
        return e;
      }
    }
    return null;
  }
}

class Absorbing<F extends Object> extends SpongeMode<F> {
  const Absorbing(super.field);
  factory Absorbing.initWith(F value, int rate) {
    final state = Absorbing<F>(List.filled(rate, null));
    state.absorb(value);
    return state;
  }
  @override
  F absorb(F value) {
    for (int i = 0; i < _fields.length; i++) {
      if (_fields[i] == null) {
        _fields[i] = value;
        return value;
      }
    }
    throw BuError(DefaultErrorType.invalidState, "Sponge is full.");
  }

  List<F?> exposeInner() => _fields;
}

abstract
/// A Poseidon parameter set: round counts, constants, and MDS matrix.
class PoseidonSpec<F extends PastaFieldElement<F>> {
  final MdsGenerateResult<F> constants;
  const PoseidonSpec(this.constants);

  static bool isValidConstants(
    MdsGenerateResult constants, {
    int constantLength = 64,
    int width = 3,
  }) {
    final mdsValid =
        constants.mds.length == width &&
        constants.mds.every((e) => e.length == 3);
    final mdsInvValid =
        constants.mdsInv.length == width &&
        constants.mdsInv.every((e) => e.length == 3);
    final constantsValid = constants.constants.length == constantLength;
    return mdsInvValid && mdsValid && constantsValid;
  }

  F fromBytes(List<int> bytes);
  F zero();
  int fullRounds() {
    return 8;
  }

  int partialRounds() {
    return 56;
  }

  F sbox(F field);

  int rate() {
    return 2;
  }

  int width() {
    return 3;
  }

  F rateField();
}

/// Sponge construction driving a Poseidon permutation.
class Sponge<F extends PastaFieldElement<F>> {
  List<F> _state;
  SpongeMode<F> _mode;
  final PoseidonSpec<F> spec;
  int get rate => spec.rate();
  Sponge._({
    required this.spec,
    required SpongeMode<F> mode,
    required List<F> state,
  }) : _mode = mode,
       _state = state;
  factory Sponge({
    required F initialCapacityElement,
    required PoseidonSpec<F> state,
  }) {
    final rate = state.rate();
    final F zero = state.zero();
    final constants = state.constants;
    final mode = Absorbing<F>(List.filled(rate, null));
    final st = List.filled(constants.mds.length, zero);
    st[rate] = initialCapacityElement;
    return Sponge._(mode: mode, state: st, spec: state);
  }

  /// Absorb an element into the sponge
  void absorb(F value) {
    final mode = _mode;
    if (mode is! Absorbing<F>) {
      throw const BuError(
        DefaultErrorType.invalidState,
        "Invalid State: this operation is not permitted in the current mode",
      );
    }
    try {
      mode.absorb(value);
      return;
    } on BuError catch (_) {}
    PoseidonUtils.poseidonSponge(_state, mode, spec);
    _mode = Absorbing.initWith(value, rate);
  }

  /// Finish absorbing and transition to squeezing
  void finishAbsorbing() {
    final mode = _mode;
    if (mode is! Absorbing<F>) return;
    _mode = PoseidonUtils.poseidonSponge(_state, mode, spec);
  }

  /// Squeeze an element from the sponge
  F squeeze() {
    final mode = _mode;
    while (true) {
      final r = mode.squeeze();
      if (r != null) return r;
      _mode = PoseidonUtils.poseidonSponge(_state, null, spec);
    }
  }
}

/// Domain separation for a [PoseidonHash].
class PoseidonHashDomain<F extends PastaFieldElement<F>> {
  final PoseidonSpec<F> spec;
  const PoseidonHashDomain(this.spec);
  F initialCapacityElement() {
    return spec.rateField();
  }

  List<F> padding(int inputLen) {
    final rate = spec.rate();
    if (inputLen != rate) {
      throw CoreErrors.invalidOperationArguments(
        "padding",
        reason: "Input length must match domain length",
      );
    }
    final zero = spec.zero();
    final k = ((rate + rate - 1) ~/ rate);
    final padLen = k * rate - rate;
    return List<F>.filled(padLen, zero);
  }
}

/// The Poseidon algebraic hash function.
class PoseidonHash<F extends PastaFieldElement<F>> {
  final Sponge<F> sponge;
  final PoseidonHashDomain<F> domain;
  PoseidonHash._(this.sponge, this.domain);
  factory PoseidonHash(PoseidonSpec<F> spec) {
    final domain = PoseidonHashDomain<F>(spec);
    final sponge = Sponge(
      initialCapacityElement: domain.initialCapacityElement(),
      state: spec,
    );
    return PoseidonHash._(sponge, domain);
  }

  /// Hash a fixed-length input
  F hash(List<F> message) {
    final paddedInput = [...message, ...domain.padding(message.length)];

    // Absorb
    for (final value in paddedInput) {
      sponge.absorb(value);
    }

    // Finish absorbing and squeeze
    sponge.finishAbsorbing();
    return sponge.squeeze();
  }
}
