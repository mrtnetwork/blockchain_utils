import 'package:blockchain_utils/crypto/crypto/cdsa/point/edwards.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/point/ec_projective_point.dart';

import 'curve.dart';

/// This class provides a collection of predefined elliptic curves for various cryptographic applications.
class Curves {
  /// Define a curve for Ed25519 elliptic cryptography
  static final curveEd25519 = CurveED(
      p: BigInt.parse(
          "57896044618658097711785492504343953926634992332820282019728792003956564819949"),
      a: BigInt.from(-1),
      d: BigInt.parse(
          "37095705934669439343138083508754565189542113879843219016388785533085940283555"),
      h: BigInt.from(8),
      order: BigInt.parse(
          "7237005577332262213973186563042994240857116359379907606001950938285454250989"));

  /// Define the generator point for Ed25519
  static final generatorED25519 = EDPoint(
      curve: curveEd25519,
      x: BigInt.parse(
          "15112221349535400772501151409588531511454012693041857206046113283949847762202"),
      y: BigInt.parse(
          "46316835694926478169428394003475163141307993866256225615783033603165251855960"),
      z: BigInt.one,
      t: BigInt.parse(
          "46827403850823179245072216630277197565144205554125654976674165829533817101731"),
      order: BigInt.parse(
          "7237005577332262213973186563042994240857116359379907606001950938285454250989"),
      generator: true);

  /// Define a curve for Secp256k1 elliptic cryptography
  static final curveSecp256k1 = CurveFp(
    p: BigInt.parse(
        "115792089237316195423570985008687907853269984665640564039457584007908834671663"),
    a: BigInt.zero,
    b: BigInt.from(7),
    h: BigInt.one,
  );

  /// Define the generator point for Secp256k1
  static final generatorSecp256k1 = ProjectiveECCPoint(
      curve: curveSecp256k1,
      x: BigInt.parse(
          "79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798",
          radix: 16),
      y: BigInt.parse(
        "483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8",
        radix: 16,
      ),
      z: BigInt.one,
      order: BigInt.parse(
          "115792089237316195423570985008687907852837564279074904382605163141518161494337"),
      generator: true);

  /// Define a curve for the 192-bit prime field
  static final curve192 = CurveFp(
    p: BigInt.parse(
        "6277101735386680763835789423207666416083908700390324961279"),
    a: BigInt.from(-3),
    b: BigInt.parse(
        "2455155546008943817740293915197451784769108058161191238065"),
    h: BigInt.one,
  );

  /// Define the generator point for the 192-bit prime field
  static final generator192 = ProjectiveECCPoint(
      curve: curve192,
      x: BigInt.parse(
          "602046282375688656758213480587526111916698976636884684818"),
      y: BigInt.parse(
          "174050332293622031404857552280219410364023488927386650641"),
      z: BigInt.one,
      order: BigInt.parse(
          "6277101735386680763835789423176059013767194773182842284081"),
      generator: true);

  /// Define a curve for the 224-bit prime field
  static final curve224 = CurveFp(
    p: BigInt.parse(
        "26959946667150639794667015087019630673557916260026308143510066298881"),
    a: BigInt.from(-3),
    b: BigInt.parse("B4050A850C04B3ABF54132565044B0B7D7BFD8BA270B39432355FFB4",
        radix: 16),
    h: BigInt.one,
  );

  /// Define the generator point for the 224-bit prime field
  static final generator224 = ProjectiveECCPoint(
      curve: curve224,
      x: BigInt.parse(
          "B70E0CBD6BB4BF7F321390B94A03C1D356C21122343280D6115C1D21",
          radix: 16),
      y: BigInt.parse(
          "BD376388B5F723FB4C22DFE6CD4375A05A07476444D5819985007E34",
          radix: 16),
      z: BigInt.one,
      generator: true,
      order: BigInt.parse(
          "26959946667150639794667015087019625940457807714424391721682722368061"));

  /// Define a curve for Ed448 elliptic cryptography
  static final curveEd448 = CurveED(
      p: BigInt.parse(
          "726838724295606890549323807888004534353641360687318060281490199180612328166730772686396383698676545930088884461843637361053498018365439"),
      a: BigInt.one,
      d: BigInt.parse(
          "726838724295606890549323807888004534353641360687318060281490199180612328166730772686396383698676545930088884461843637361053498018326358"),
      h: BigInt.from(4),
      order: BigInt.parse(
          "181709681073901722637330951972001133588410340171829515070372549795146003961539585716195755291692375963310293709091662304773755859649779"));

  /// Define the generator point for Ed448
  static final generatorEd448 = EDPoint(
    curve: curveEd448,
    generator: true,
    order: BigInt.parse(
        "181709681073901722637330951972001133588410340171829515070372549795146003961539585716195755291692375963310293709091662304773755859649779"),
    x: BigInt.parse(
        "224580040295924300187604334099896036246789641632564134246125461686950415467406032909029192869357953282578032075146446173674602635247710"),
    y: BigInt.parse(
        "298819210078481492676017930443930673437544040154080242095928241372331506189835876003536878655418784733982303233503462500531545062832660"),
    z: BigInt.one,
    t: BigInt.parse(
        "566053928361835949852834778149687438525473724399248069152339054586912418998433999863114841018499380965114687248170942704967194566956531"),
  );

  /// Define a curve for the 256-bit prime field
  static final CurveFp curve256 = CurveFp(
    p: BigInt.parse(
        "115792089210356248762697446949407573530086143415290314195533631308867097853951"),
    a: BigInt.from(-3),
    b: BigInt.parse(
        "5AC635D8AA3A93E7B3EBBD55769886BC651D06B0CC53B0F63BCE3C3E27D2604B",
        radix: 16),
    h: BigInt.one,
  );

  /// Define the generator point for the 256-bit prime field
  static final ProjectiveECCPoint generator256 = ProjectiveECCPoint(
      curve: curve256,
      x: BigInt.parse(
          "6B17D1F2E12C4247F8BCE6E563A440F277037D812DEB33A0F4A13945D898C296",
          radix: 16),
      y: BigInt.parse(
          "4FE342E2FE1A7F9B8EE7EB4A7C0F9E162BCE33576B315ECECBB6406837BF51F5",
          radix: 16),
      z: BigInt.one,
      generator: true,
      order: BigInt.parse(
          "115792089210356248762697446949407573529996955224135760342422259061068512044369"));
}
