import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/fields/core.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/fields/native/fq.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/fields/native/fp.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/fields/pallas_fp.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/fields/vesta_fq.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/point/core.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/point/pallas.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/point/pallas_native.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/wnaf/wnaf.dart';
import 'package:blockchain_utils/crypto/crypto/exception/exception.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/binary/bit_utils.dart';
import 'package:blockchain_utils/utils/string/string.dart';

/// Pads the given iterator (which MUST have length $\leq K * C$) with zero-bits to a
/// multiple of $K$ bits.
class Pad implements Iterator<bool> {
  /// The iterator we are padding.
  final List<bool> inner;
  int _len = 0;

  /// The measured length of the inner iterator.
  int get len => _len;
  int? _paddingLeft;
  bool? _current;

  /// The amount of padding that remains to be emitted.
  int? get paddingLeft => _paddingLeft;

  Pad(List<bool> inner) : inner = inner.immutable;

  @override
  bool get current => _current ?? false;
  int _index = -1;
  // @override
  bool get _currentInner => inner[_index];

  bool _moveNextInner() {
    if (_index + 1 >= inner.length) return false;
    _index++;
    return true;
  }

  @override
  bool moveNext() {
    while (true) {
      if (paddingLeft != null) {
        // Emit padding
        if (paddingLeft == 0) {
          // No more padding
          _current = null;
          return false;
        } else {
          _paddingLeft = paddingLeft! - 1;
          _current = false;
          return true;
        }
      } else {
        // Try to advance the inner iterator
        if (_moveNextInner()) {
          _len += 1;
          assert(len <= HashDomainConst.K * HashDomainConst.C);
          _current = _currentInner;
          return true;
        } else {
          // Inner iterator ended. Compute padding.
          final rem = len % HashDomainConst.K;
          if (rem > 0) {
            _paddingLeft = HashDomainConst.K - rem;
          } else {
            _paddingLeft = 0;
          }
          // Loop again — now paddingLeft != null so the next iteration emits padding
        }
      }
    }
  }

  List<bool> toList() {
    List<bool> items = [];
    while (moveNext()) {
      items.add(current);
    }
    return items;
  }
}

class IncompletePoint<
  SCALAR extends PastaFieldElement<SCALAR>,
  BASE extends PastaFieldElement<BASE>,
  P extends PastaPoint<SCALAR, BASE, P>
> {
  final P? point;

  const IncompletePoint(this.point);

  IncompletePoint<SCALAR, BASE, P> operator +(
    IncompletePoint<SCALAR, BASE, P> rhs,
  ) {
    final p = point;
    if (p == null) {
      return const IncompletePoint(null);
    }
    final q = rhs.point;
    if (q == null) {
      return const IncompletePoint(null);
    }
    final valid = !(p.isIdentity() || q.isIdentity() || p == q || p == -q);
    final result = valid ? (p + q) : null;
    return IncompletePoint(result);
  }

  IncompletePoint<SCALAR, BASE, P> addAffine(
    PastaAffinePoint<SCALAR, BASE, P> rhs,
  ) {
    final p = point;
    if (p == null) {
      return const IncompletePoint(null);
    }
    final q = rhs.toCurve();

    final valid = !(p.isIdentity() || q.isIdentity() || p == q || p == -q);
    final result = valid ? (p + rhs) : null;
    return IncompletePoint(result);
  }
}

class HashDomainConst {
  static const String qPersonalization = "z.cash:SinsemillaQ";
  static const String sPersonalization = "z.cash:SinsemillaS";
  static const int K = 10;
  static const int C = 253;
  static const int lOrchardMerkle = 255;
}

/// insemillaHash is an algebraic hash function with collision resistance (for fixed input length) derived from assumed
/// hardness of the Discrete Logarithm Problem.
abstract final class BaseHashDomain<
  SCALAR extends PastaFieldElement<SCALAR>,
  BASE extends PastaFieldElement<BASE>,
  P extends PastaPoint<SCALAR, BASE, P>,
  AFFINE extends PastaAffinePoint<SCALAR, BASE, P>
> {
  final List<AFFINE> _sinsemillaS;
  List<AFFINE> get sinsemillaS => _sinsemillaS;
  final P q;
  BaseHashDomain({required this.q, required List<AFFINE> sinsemillaS})
    : _sinsemillaS = sinsemillaS;
  PastaAffinePoint<SCALAR, BASE, P> pointAtIndex(int index);

  /// - [hashToPoint]: https://zips.z.cash/protocol/nu5.pdf#concretesinsemillahash
  IncompletePoint<SCALAR, BASE, P> _hashToPoint(List<bool> msg) {
    final padded = Pad(msg).toList();
    Iterable<List<T>> chunks<T>(List<T> list, int size) sync* {
      for (var i = 0; i < list.length; i += size) {
        yield list.sublist(i, (i + size).clamp(0, list.length));
      }
    }

    return chunks(padded, HashDomainConst.K).fold(IncompletePoint(q), (
      acc,
      chunk,
    ) {
      final index = BitUtils.bitsToInt(chunk);
      return acc.addAffine(pointAtIndex(index)) + acc;
    });
  }

  P? hashToPoint(List<bool> msg) {
    return _hashToPoint(msg).point;
  }

  BASE? hash(List<bool> msg) {
    final point = hashToPoint(msg);
    return point?.toAffine().x;
  }
}

abstract class BaseCommitDomain<
  SCALAR extends PastaFieldElement<SCALAR>,
  BASE extends PastaFieldElement<BASE>,
  P extends PastaPoint<SCALAR, BASE, P>,
  AFFINE extends PastaAffinePoint<SCALAR, BASE, P>
> {
  abstract final BaseHashDomain<SCALAR, BASE, P, AFFINE> context;
  abstract final WnafBase<SCALAR, P> r;
  P? commit({required List<bool> msg, required SCALAR r}) {
    final point = context.hashToPoint(msg);
    if (point == null) return null;
    final result = point + this.r.mult(r);
    return result;
  }

  BASE? shortCommit({required List<bool> msg, required SCALAR r}) {
    final commit = this.commit(msg: msg, r: r);
    if (commit == null) return null;
    final affine = commit.toAffine();
    return affine.x;
  }
}

final class HashDomain
    extends BaseHashDomain<VestaFq, PallasFp, PallasPoint, PallasAffinePoint> {
  HashDomain({required super.q, required super.sinsemillaS});
  static List<PallasAffinePoint> generateSinsemillaS() {
    List<PallasAffinePoint> points = [];
    for (int index = 0; index < 1024; index++) {
      final hash =
          PallasPoint.hashToCurve(
            domainPrefix: HashDomainConst.sPersonalization,
            message: index.toU32LeBytes(),
          ).toAffine();
      points.add(hash);
    }
    return points;
  }

  factory HashDomain.fromDomain(
    String domain, {
    List<int>? message,
    List<PallasAffinePoint>? sinsemillaS,
    bool withSeperator = false,
  }) {
    if (withSeperator) {
      domain += "-M";
    }
    message ??= StringUtils.encode(domain);
    final point = PallasPoint.hashToCurve(
      domainPrefix: HashDomainConst.qPersonalization,
      message: message,
    );
    sinsemillaS ??= generateSinsemillaS();
    return HashDomain(q: point, sinsemillaS: sinsemillaS);
  }

  @override
  PastaAffinePoint<VestaFq, PallasFp, PallasPoint> pointAtIndex(int index) {
    final r = _sinsemillaS.elementAtOrNull(index);
    if (r == null) {
      throw CryptoException.failed(
        "pointAtIndex",
        reason: "Missing sinsemillaS point at index $index",
      );
    }
    return r;
  }
}

final class HashDomainNative
    extends
        BaseHashDomain<
          VestaNativeFq,
          PallasNativeFp,
          PallasNativePoint,
          PallasAffineNativePoint
        > {
  HashDomainNative({required super.q, required super.sinsemillaS});

  static List<PallasAffineNativePoint> generateSinsemillaS() {
    List<PallasAffineNativePoint> points = [];
    for (int index = 0; index < 1024; index++) {
      final hash =
          PallasNativePoint.hashToCurve(
            domainPrefix: HashDomainConst.sPersonalization,
            message: index.toU32LeBytes(),
          ).toAffine();
      points.add(hash);
    }
    return points;
  }

  factory HashDomainNative.fromDomain(
    String domain, {
    List<PallasAffineNativePoint>? sinsemillaS,
    bool withSeperator = false,
  }) {
    if (withSeperator) {
      domain += "-M";
    }
    final message = StringUtils.encode(domain);
    final point = PallasNativePoint.hashToCurve(
      domainPrefix: HashDomainConst.qPersonalization,
      message: message,
    );
    sinsemillaS ??= generateSinsemillaS();
    return HashDomainNative(q: point, sinsemillaS: sinsemillaS);
  }

  @override
  PastaAffinePoint<VestaNativeFq, PallasNativeFp, PallasNativePoint>
  pointAtIndex(int index) {
    final r = _sinsemillaS.elementAtOrNull(index);
    if (r == null) {
      throw CryptoException.failed(
        "pointAtIndex",
        reason: "Missing sinsemillaS point at index $index",
      );
    }
    return r;
  }
}

class CommitDomain
    extends
        BaseCommitDomain<VestaFq, PallasFp, PallasPoint, PallasAffinePoint> {
  @override
  final HashDomain context;
  @override
  final WnafBase<VestaFq, PallasPoint> r;
  CommitDomain({required this.context, required this.r});
  factory CommitDomain.create(String domain) {
    return CommitDomain.withSeperateDomain(
      hashDomain: domain,
      blindDomain: domain,
    );
  }
  factory CommitDomain.withSeperateDomain({
    required String hashDomain,
    required String blindDomain,
    List<PallasAffinePoint>? sinsemillaS,
  }) {
    final mPrefix = "$hashDomain-M";
    final rPrefix = "$blindDomain-r";
    final pointR = PallasPoint.hashToCurve(domainPrefix: rPrefix, message: []);
    return CommitDomain(
      context: HashDomain.fromDomain(mPrefix, sinsemillaS: sinsemillaS),
      r: WnafBase(pointR),
    );
  }
}

class CommitDomainNative
    extends
        BaseCommitDomain<
          VestaNativeFq,
          PallasNativeFp,
          PallasNativePoint,
          PallasAffineNativePoint
        > {
  @override
  final HashDomainNative context;

  @override
  final WnafBase<VestaNativeFq, PallasNativePoint> r;
  CommitDomainNative({required this.context, required this.r});
  factory CommitDomainNative.create(
    String domain, {
    List<PallasAffineNativePoint>? sinsemillaS,
  }) {
    return CommitDomainNative.withSeperateDomain(
      hashDomain: domain,
      blindDomain: domain,
      sinsemillaS: sinsemillaS,
    );
  }
  factory CommitDomainNative.withSeperateDomain({
    required String hashDomain,
    required String blindDomain,
    List<PallasAffineNativePoint>? sinsemillaS,
  }) {
    final mPrefix = "$hashDomain-M";
    final rPrefix = "$blindDomain-r";
    final pointR = PallasNativePoint.hashToCurve(
      domainPrefix: rPrefix,
      message: [],
    );
    return CommitDomainNative(
      context: HashDomainNative.fromDomain(mPrefix, sinsemillaS: sinsemillaS),
      r: WnafBase(pointR),
    );
  }
}
