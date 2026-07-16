import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/fields/core.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/fields/native/fq.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/fields/native/fp.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/fields/pallas_fp.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/fields/vesta_fq.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/point/core.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/point/pallas.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/point/pallas_native.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/sinsemilla/constants/constants.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/wnaf/wnaf.dart';
import 'package:blockchain_utils/crypto/crypto/exception/exception.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/binary/bit_utils.dart';
import 'package:blockchain_utils/utils/string/string.dart';

/// Pads the given iterator
class SinsemillaPad implements Iterator<bool> {
  /// The iterator we are padding.
  final List<bool> inner;
  int _len = 0;

  /// The measured length of the inner iterator.
  int get len => _len;
  int? _paddingLeft;
  bool? _current;

  /// The amount of padding that remains to be emitted.
  int? get paddingLeft => _paddingLeft;

  SinsemillaPad(List<bool> inner) : inner = inner.immutable;

  @override
  bool get current => _current ?? false;
  int _index = -1;
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

class _IncompletePoint<
  SCALAR extends PastaFieldElement<SCALAR>,
  BASE extends PastaFieldElement<BASE>,
  P extends PastaPoint<SCALAR, BASE, P>
> {
  final P? point;

  const _IncompletePoint(this.point);

  _IncompletePoint<SCALAR, BASE, P> operator +(
    _IncompletePoint<SCALAR, BASE, P> rhs,
  ) {
    final p = point;
    if (p == null) {
      return const _IncompletePoint(null);
    }
    final q = rhs.point;
    if (q == null) {
      return const _IncompletePoint(null);
    }
    final valid = !(p.isIdentity() || q.isIdentity() || p == q || p == -q);
    final result = valid ? (p + q) : null;
    return _IncompletePoint(result);
  }

  _IncompletePoint<SCALAR, BASE, P> addAffine(P rhs) {
    final p = point;
    if (p == null) {
      return const _IncompletePoint(null);
    }
    final q = rhs;

    final valid = !(p.isIdentity() || q.isIdentity() || p == q || p == -q);
    final result = valid ? (p + q) : null;
    return _IncompletePoint(result);
  }
}

class HashDomainConst {
  /// SWU hash-to-curve personalization for Sinsemilla Q
  static const String qPersonalization = "z.cash:SinsemillaQ";

  /// SWU hash-to-curve personalization for Sinsemilla S
  static const String sPersonalization = "z.cash:SinsemillaS";

  /// Number of bits of each message piece
  static const int K = 10;
  static const int C = 253;
  static const int lOrchardMerkle = 255;
}

abstract final class BaseHashDomain<
  SCALAR extends PastaFieldElement<SCALAR>,
  BASE extends PastaFieldElement<BASE>,
  P extends PastaPoint<SCALAR, BASE, P>,
  AFFINE extends PastaAffinePoint<SCALAR, BASE, P>
> {
  final List<P> _sinsemillaS;
  List<P> get sinsemillaS => _sinsemillaS;
  final P q;
  BaseHashDomain({required this.q, required List<P> sinsemillaS})
    : _sinsemillaS = sinsemillaS;
  P pointAtIndex(int index);

  /// - [hashToPoint]: https://zips.z.cash/protocol/nu5.pdf#concretesinsemillahash
  _IncompletePoint<SCALAR, BASE, P> _hashToPoint(List<bool> msg) {
    final padded = SinsemillaPad(msg).toList();
    Iterable<List<T>> chunks<T>(List<T> list, int size) sync* {
      for (var i = 0; i < list.length; i += size) {
        yield list.sublist(i, (i + size).clamp(0, list.length));
      }
    }

    return chunks(padded, HashDomainConst.K).fold(_IncompletePoint(q), (
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

  /// [concretesinsemillacommit]: https://zips.z.cash/protocol/nu5.pdf#concretesinsemillacommit
  P? commit({required List<bool> msg, required SCALAR r}) {
    final point = context.hashToPoint(msg);
    if (point == null) return null;
    final result = point + this.r.mult(r);
    return result;
  }

  /// [concretesinsemillacommit]: https://zips.z.cash/protocol/nu5.pdf#concretesinsemillacommit
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
  static List<PallasPoint> generateSinsemillaS() {
    List<PallasPoint> points = [];
    for (int index = 0; index < 1024; index++) {
      final hash = PallasPoint.hashToCurve(
        domainPrefix: HashDomainConst.sPersonalization,
        message: index.toU32LeBytes(),
      );
      points.add(hash);
    }
    return points;
  }

  factory HashDomain.fromDomain(
    String domain, {
    List<int>? message,
    List<PallasPoint>? sinsemillaS,
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
  PallasPoint pointAtIndex(int index) {
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

  static List<PallasNativePoint> generateSinsemillaS() {
    List<PallasNativePoint> points = [];
    for (int index = 0; index < 1024; index++) {
      final hash = PallasNativePoint.hashToCurve(
        domainPrefix: HashDomainConst.sPersonalization,
        message: index.toU32LeBytes(),
      );
      points.add(hash);
    }
    return points;
  }

  static List<PallasNativePoint> generateSinsemillaSConstants() {
    return SinsemillaConst.sConstants
        .map(
          (e) => PallasNativePoint(
            x: PallasNativeFp.nP(BigInt.parse(e[0])),
            y: PallasNativeFp.nP(BigInt.parse(e[1])),
            z: PallasNativeFp.nP(BigInt.parse(e[2])),
          ),
        )
        .toList();
  }

  factory HashDomainNative.fromDomain(
    String domain, {
    List<PallasNativePoint>? sinsemillaS,
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
    sinsemillaS ??= generateSinsemillaSConstants();
    return HashDomainNative(q: point, sinsemillaS: sinsemillaS);
  }

  @override
  PallasNativePoint pointAtIndex(int index) {
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

  /// Constructs a new [CommitDomainNative] with a specific prefix string.
  /// [sinsemillaS] pre generated sinsemilaS
  factory CommitDomain.create(String domain, {List<PallasPoint>? sinsemillaS}) {
    return CommitDomain.withSeperateDomain(
      hashDomain: domain,
      blindDomain: domain,
      sinsemillaS: sinsemillaS,
    );
  }

  /// Constructs a new [CommitDomain] from different values for [hashDomain] and [blindDomain]
  /// [sinsemillaS] pre generated sinsemilaS
  factory CommitDomain.withSeperateDomain({
    required String hashDomain,
    required String blindDomain,
    List<PallasPoint>? sinsemillaS,
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

  /// Constructs a new [CommitDomainNative] with a specific prefix string.
  /// [sinsemillaS] pre generated sinsemilaS
  factory CommitDomainNative.create(
    String domain, {
    List<PallasNativePoint>? sinsemillaS,
  }) {
    return CommitDomainNative.withSeperateDomain(
      hashDomain: domain,
      blindDomain: domain,
      sinsemillaS: sinsemillaS,
    );
  }

  /// Constructs a new [CommitDomainNative] from different values for [hashDomain] and [blindDomain]
  /// [sinsemillaS] pre generated sinsemilaS
  factory CommitDomainNative.withSeperateDomain({
    required String hashDomain,
    required String blindDomain,
    List<PallasNativePoint>? sinsemillaS,
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
