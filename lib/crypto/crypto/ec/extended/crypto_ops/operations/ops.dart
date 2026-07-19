import 'package:blockchain_utils/crypto/crypto/ec/extended/native/edwards.dart';

import 'package:blockchain_utils/crypto/crypto/ec/utils/ed25519.dart';
import 'package:blockchain_utils/crypto/crypto/exception/exception.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/numbers/src/i32.dart';
import 'package:blockchain_utils/numbers/src/i64.dart';
import 'package:blockchain_utils/numbers/src/u64/u64.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';

import '../const/const.dart';
import '../models/models.dart';

class CryptoOps {
  static final _b2097151 = Int64(2097151);
  static final Int64 _bitMaskFor25 = Int64.one << 25;
  static final Int64 _bitMaskFor24 = Int64.one << 24;
  static final Int64 _bitMaskFor20 = Int64.one << 20;
  static Int32 _mulInt(int a, Int32 b) {
    return Int32.unsafe(a) * b;
  }

  static Int64 _mulInt64(Int32 a, Int32 b) {
    return a.toInt64() * b.toInt64();
  }

  static Int64 _mulInt64Int(Int64 a, int b) {
    return a * Int64.unsafe(Uint64.unsafe(0, b));
  }

  // static Int64 _andU64(Int64 a, Uint64 b) {
  //   return a & b.toInt64();
  // }
  static Int64 _andU64(Int64 a, Uint64 b) {
    return Int64.unsafe(a.rawBits & b);
  }

  static Uint64 _load4(List<int> data, int offset) {
    int r = data[offset];
    r |= data[offset + 1] << 8;
    r |= data[offset + 2] << 16;
    r |= data[offset + 3] << 24;
    return Uint64.unsafe(0, r);
  }

  static Uint64 _load3(List<int> data, int offset) {
    int r = data[offset];
    r |= data[offset + 1] << 8;
    r |= data[offset + 2] << 16;
    return Uint64.unsafe(0, r);
  }

  static int scIsNonZero(List<int> s) {
    s.asMin32("scIsNonZero");
    for (int i = 0; i < 32; i++) {
      final byte = s[i];
      if (byte != 0) {
        return 1;
      }
    }
    return 0;
  }

  static Int64 signum(Int64 a) {
    if (a > Int64.zero) {
      return Int64.one;
    }
    if (a < Int64.zero) {
      return Int64(-1);
    }
    return Int64.zero;
  }

  static int scCheck(List<int> s) {
    final Int64 s0 = _load4(s, 0).toInt64();
    final Int64 s1 = _load4(s, 4).toInt64();
    final Int64 s2 = _load4(s, 8).toInt64();
    final Int64 s3 = _load4(s, 12).toInt64();
    final Int64 s4 = _load4(s, 16).toInt64();
    final Int64 s5 = _load4(s, 20).toInt64();
    final Int64 s6 = _load4(s, 24).toInt64();
    final Int64 s7 = _load4(s, 28).toInt64();

    final Int64 r =
        signum(1559614444.toInt64 - s0) +
        (signum(1477600026.toInt64 - s1) << 1) +
        (signum(2734136534.toInt64 - s2) << 2) +
        (signum(350157278.toInt64 - s3) << 3) +
        (signum(-s4) << 4) +
        (signum(-s5) << 5) +
        (signum(-s6) << 6) +
        (signum(268435456.toInt64 - s7) << 7);

    return -(0 > r.toInt() ? 1 : 0);
  }

  static void scReduce32Copy(List<int> scopy, List<int> s) {
    s.asMin32("scReduce32Copy");
    scopy.asMin32("scReduce32Copy");
    final r = s.clone();
    scReduce32(r);
    for (int i = 0; i < 32; i++) {
      scopy[i] = r[i];
    }
  }

  static void fe0(FieldElement h) {
    h.fillZero();
  }

  static void fe1(FieldElement h) {
    h.fillOne();
  }

  static void feAdd(FieldElement h, FieldElement f, FieldElement g) {
    final Int32 f0 = f.h[0];
    final Int32 f1 = f.h[1];
    final Int32 f2 = f.h[2];
    final Int32 f3 = f.h[3];
    final Int32 f4 = f.h[4];
    final Int32 f5 = f.h[5];
    final Int32 f6 = f.h[6];
    final Int32 f7 = f.h[7];
    final Int32 f8 = f.h[8];
    final Int32 f9 = f.h[9];
    final Int32 g0 = g.h[0];
    final Int32 g1 = g.h[1];
    final Int32 g2 = g.h[2];
    final Int32 g3 = g.h[3];
    final Int32 g4 = g.h[4];
    final Int32 g5 = g.h[5];
    final Int32 g6 = g.h[6];
    final Int32 g7 = g.h[7];
    final Int32 g8 = g.h[8];
    final Int32 g9 = g.h[9];
    final Int32 h0 = f0 + g0;
    final Int32 h1 = f1 + g1;
    final Int32 h2 = f2 + g2;
    final Int32 h3 = f3 + g3;
    final Int32 h4 = f4 + g4;
    final Int32 h5 = f5 + g5;
    final Int32 h6 = f6 + g6;
    final Int32 h7 = f7 + g7;
    final Int32 h8 = f8 + g8;
    final Int32 h9 = f9 + g9;
    h.h[0] = h0;
    h.h[1] = h1;
    h.h[2] = h2;
    h.h[3] = h3;
    h.h[4] = h4;
    h.h[5] = h5;
    h.h[6] = h6;
    h.h[7] = h7;
    h.h[8] = h8;
    h.h[9] = h9;
  }

  static Int32 _xor32(Int32 a, Int32 b) {
    return (a ^ b);
  }

  static void feCmov(FieldElement f, FieldElement g, int b) {
    assert(b == 0 || b == 1, "b should be either 0 or 1.");
    final Int32 f0 = f.h[0];
    final Int32 f1 = f.h[1];
    final Int32 f2 = f.h[2];
    final Int32 f3 = f.h[3];
    final Int32 f4 = f.h[4];
    final Int32 f5 = f.h[5];
    final Int32 f6 = f.h[6];
    final Int32 f7 = f.h[7];
    final Int32 f8 = f.h[8];
    final Int32 f9 = f.h[9];
    final Int32 g0 = g.h[0];
    final Int32 g1 = g.h[1];
    final Int32 g2 = g.h[2];
    final Int32 g3 = g.h[3];
    final Int32 g4 = g.h[4];
    final Int32 g5 = g.h[5];
    final Int32 g6 = g.h[6];
    final Int32 g7 = g.h[7];
    final Int32 g8 = g.h[8];
    final Int32 g9 = g.h[9];
    Int32 x0 = f0 ^ g0;
    Int32 x1 = f1 ^ g1;
    Int32 x2 = f2 ^ g2;
    Int32 x3 = f3 ^ g3;
    Int32 x4 = f4 ^ g4;
    Int32 x5 = f5 ^ g5;
    Int32 x6 = f6 ^ g6;
    Int32 x7 = f7 ^ g7;
    Int32 x8 = f8 ^ g8;
    Int32 x9 = f9 ^ g9;
    Int32 b32 = Int32(-b);
    // b = -b;
    x0 &= b32;
    x1 &= b32;
    x2 &= b32;
    x3 &= b32;
    x4 &= b32;
    x5 &= b32;
    x6 &= b32;
    x7 &= b32;
    x8 &= b32;
    x9 &= b32;
    f.h[0] = _xor32(f0, x0);
    f.h[1] = _xor32(f1, x1);
    f.h[2] = _xor32(f2, x2);
    f.h[3] = _xor32(f3, x3);
    f.h[4] = _xor32(f4, x4);
    f.h[5] = _xor32(f5, x5);
    f.h[6] = _xor32(f6, x6);
    f.h[7] = _xor32(f7, x7);
    f.h[8] = _xor32(f8, x8);
    f.h[9] = _xor32(f9, x9);
  }

  static void feCopy(FieldElement h, FieldElement f) {
    final Int32 f0 = f.h[0];
    final Int32 f1 = f.h[1];
    final Int32 f2 = f.h[2];
    final Int32 f3 = f.h[3];
    final Int32 f4 = f.h[4];
    final Int32 f5 = f.h[5];
    final Int32 f6 = f.h[6];
    final Int32 f7 = f.h[7];
    final Int32 f8 = f.h[8];
    final Int32 f9 = f.h[9];
    h.h[0] = f0;
    h.h[1] = f1;
    h.h[2] = f2;
    h.h[3] = f3;
    h.h[4] = f4;
    h.h[5] = f5;
    h.h[6] = f6;
    h.h[7] = f7;
    h.h[8] = f8;
    h.h[9] = f9;
  }

  static void feSq(FieldElement h, FieldElement f) {
    final Int32 f0 = f.h[0];
    final Int32 f1 = f.h[1];
    final Int32 f2 = f.h[2];
    final Int32 f3 = f.h[3];
    final Int32 f4 = f.h[4];
    final Int32 f5 = f.h[5];
    final Int32 f6 = f.h[6];
    final Int32 f7 = f.h[7];
    final Int32 f8 = f.h[8];
    final Int32 f9 = f.h[9];
    final Int32 f0_2 = _mulInt(2, f0);
    final Int32 f1_2 = _mulInt(2, f1);
    final Int32 f2_2 = _mulInt(2, f2);
    final Int32 f3_2 = _mulInt(2, f3);
    final Int32 f4_2 = _mulInt(2, f4);
    final Int32 f5_2 = _mulInt(2, f5);
    final Int32 f6_2 = _mulInt(2, f6);
    final Int32 f7_2 = _mulInt(2, f7);
    final Int32 f5_38 = _mulInt(38, f5); /* 1.959375*2^30 */
    final Int32 f6_19 = _mulInt(19, f6); /* 1.959375*2^30 */
    final Int32 f7_38 = _mulInt(38, f7); /* 1.959375*2^30 */
    final Int32 f8_19 = _mulInt(19, f8); /* 1.959375*2^30 */
    final Int32 f9_38 = _mulInt(38, f9); /* 1.959375*2^30 */

    final Int64 f0f0 = _mulInt64(f0, f0);
    final Int64 f0f1_2 = _mulInt64(f0_2, f1);
    final Int64 f0f2_2 = _mulInt64(f0_2, f2);
    final Int64 f0f3_2 = _mulInt64(f0_2, f3);
    final Int64 f0f4_2 = _mulInt64(f0_2, f4);
    final Int64 f0f5_2 = _mulInt64(f0_2, f5);
    final Int64 f0f6_2 = _mulInt64(f0_2, f6);
    final Int64 f0f7_2 = _mulInt64(f0_2, f7);
    final Int64 f0f8_2 = _mulInt64(f0_2, f8);
    final Int64 f0f9_2 = _mulInt64(f0_2, f9);
    final Int64 f1f1_2 = _mulInt64(f1_2, f1);
    final Int64 f1f2_2 = _mulInt64(f1_2, f2);
    final Int64 f1f3_4 = _mulInt64(f1_2, f3_2);
    final Int64 f1f4_2 = _mulInt64(f1_2, f4);
    final Int64 f1f5_4 = _mulInt64(f1_2, f5_2);
    final Int64 f1f6_2 = _mulInt64(f1_2, f6);
    final Int64 f1f7_4 = _mulInt64(f1_2, f7_2);
    final Int64 f1f8_2 = _mulInt64(f1_2, f8);
    final Int64 f1f9_76 = _mulInt64(f1_2, f9_38);
    final Int64 f2f2 = _mulInt64(f2, f2);
    final Int64 f2f3_2 = _mulInt64(f2_2, f3);
    final Int64 f2f4_2 = _mulInt64(f2_2, f4);
    final Int64 f2f5_2 = _mulInt64(f2_2, f5);
    final Int64 f2f6_2 = _mulInt64(f2_2, f6);
    final Int64 f2f7_2 = _mulInt64(f2_2, f7);
    final Int64 f2f8_38 = _mulInt64(f2_2, f8_19);
    final Int64 f2f9_38 = _mulInt64(f2, f9_38);
    final Int64 f3f3_2 = _mulInt64(f3_2, f3);
    final Int64 f3f4_2 = _mulInt64(f3_2, f4);
    final Int64 f3f5_4 = _mulInt64(f3_2, f5_2);
    final Int64 f3f6_2 = _mulInt64(f3_2, f6);
    final Int64 f3f7_76 = _mulInt64(f3_2, f7_38);
    final Int64 f3f8_38 = _mulInt64(f3_2, f8_19);
    final Int64 f3f9_76 = _mulInt64(f3_2, f9_38);
    final Int64 f4f4 = _mulInt64(f4, f4);
    final Int64 f4f5_2 = _mulInt64(f4_2, f5);
    final Int64 f4f6_38 = _mulInt64(f4_2, f6_19);
    final Int64 f4f7_38 = _mulInt64(f4, f7_38);
    final Int64 f4f8_38 = _mulInt64(f4_2, f8_19);
    final Int64 f4f9_38 = _mulInt64(f4, f9_38);
    final Int64 f5f5_38 = _mulInt64(f5, f5_38);
    final Int64 f5f6_38 = _mulInt64(f5_2, f6_19);
    final Int64 f5f7_76 = _mulInt64(f5_2, f7_38);
    final Int64 f5f8_38 = _mulInt64(f5_2, f8_19);
    final Int64 f5f9_76 = _mulInt64(f5_2, f9_38);
    final Int64 f6f6_19 = _mulInt64(f6, f6_19);
    final Int64 f6f7_38 = _mulInt64(f6, f7_38);
    final Int64 f6f8_38 = _mulInt64(f6_2, f8_19);
    final Int64 f6f9_38 = _mulInt64(f6, f9_38);
    final Int64 f7f7_38 = _mulInt64(f7, f7_38);
    final Int64 f7f8_38 = _mulInt64(f7_2, f8_19);
    final Int64 f7f9_76 = _mulInt64(f7_2, f9_38);
    final Int64 f8f8_19 = _mulInt64(f8, f8_19);
    final Int64 f8f9_38 = _mulInt64(f8, f9_38);
    final Int64 f9f9_38 = _mulInt64(f9, f9_38);
    Int64 h0 = f0f0 + f1f9_76 + f2f8_38 + f3f7_76 + f4f6_38 + f5f5_38;
    Int64 h1 = f0f1_2 + f2f9_38 + f3f8_38 + f4f7_38 + f5f6_38;
    Int64 h2 = f0f2_2 + f1f1_2 + f3f9_76 + f4f8_38 + f5f7_76 + f6f6_19;
    Int64 h3 = f0f3_2 + f1f2_2 + f4f9_38 + f5f8_38 + f6f7_38;
    Int64 h4 = f0f4_2 + f1f3_4 + f2f2 + f5f9_76 + f6f8_38 + f7f7_38;
    Int64 h5 = f0f5_2 + f1f4_2 + f2f3_2 + f6f9_38 + f7f8_38;
    Int64 h6 = f0f6_2 + f1f5_4 + f2f4_2 + f3f3_2 + f7f9_76 + f8f8_19;
    Int64 h7 = f0f7_2 + f1f6_2 + f2f5_2 + f3f4_2 + f8f9_38;
    Int64 h8 = f0f8_2 + f1f7_4 + f2f6_2 + f3f5_4 + f4f4 + f9f9_38;
    Int64 h9 = f0f9_2 + f1f8_2 + f2f7_2 + f3f6_2 + f4f5_2;
    Int64 carry0;
    Int64 carry1;
    Int64 carry2;
    Int64 carry3;
    Int64 carry4;
    Int64 carry5;
    Int64 carry6;
    Int64 carry7;
    Int64 carry8;
    Int64 carry9;

    carry0 = (h0 + _bitMaskFor25) >> 26;
    h1 += carry0;
    h0 -= carry0 << 26;
    carry4 = (h4 + _bitMaskFor25) >> 26;
    h5 += carry4;
    h4 -= carry4 << 26;

    carry1 = (h1 + _bitMaskFor24) >> 25;
    h2 += carry1;
    h1 -= carry1 << 25;
    carry5 = (h5 + _bitMaskFor24) >> 25;
    h6 += carry5;
    h5 -= carry5 << 25;

    carry2 = (h2 + _bitMaskFor25) >> 26;
    h3 += carry2;
    h2 -= carry2 << 26;
    carry6 = (h6 + _bitMaskFor25) >> 26;
    h7 += carry6;
    h6 -= carry6 << 26;

    carry3 = (h3 + _bitMaskFor24) >> 25;
    h4 += carry3;
    h3 -= carry3 << 25;
    carry7 = (h7 + _bitMaskFor24) >> 25;
    h8 += carry7;
    h7 -= carry7 << 25;

    carry4 = (h4 + _bitMaskFor25) >> 26;
    h5 += carry4;
    h4 -= carry4 << 26;
    carry8 = (h8 + _bitMaskFor25) >> 26;
    h9 += carry8;
    h8 -= carry8 << 26;

    carry9 = (h9 + _bitMaskFor24) >> 25;
    h0 += carry9 * Int64(19);
    h9 -= carry9 << 25;

    carry0 = (h0 + _bitMaskFor25) >> 26;
    h1 += carry0;
    h0 -= carry0 << 26;

    h.h[0] = h0.toI32;
    h.h[1] = h1.toI32;
    h.h[2] = h2.toI32;
    h.h[3] = h3.toI32;
    h.h[4] = h4.toI32;
    h.h[5] = h5.toI32;
    h.h[6] = h6.toI32;
    h.h[7] = h7.toI32;
    h.h[8] = h8.toI32;
    h.h[9] = h9.toI32;
  }

  static void feSq2(FieldElement h, FieldElement f) {
    final f0 = f.h[0];
    final f1 = f.h[1];
    final f2 = f.h[2];
    final f3 = f.h[3];
    final f4 = f.h[4];
    final f5 = f.h[5];
    final f6 = f.h[6];
    final f7 = f.h[7];
    final f8 = f.h[8];
    final f9 = f.h[9];
    final f0_2 = _mulInt(2, f0);
    final f1_2 = _mulInt(2, f1);
    final f2_2 = _mulInt(2, f2);
    final f3_2 = _mulInt(2, f3);
    final f4_2 = _mulInt(2, f4);
    final f5_2 = _mulInt(2, f5);
    final f6_2 = _mulInt(2, f6);
    final f7_2 = _mulInt(2, f7);
    final f5_38 = _mulInt(38, f5); /* 1.959375*2^30 */
    final f6_19 = _mulInt(19, f6); /* 1.959375*2^30 */
    final f7_38 = _mulInt(38, f7); /* 1.959375*2^30 */
    final f8_19 = _mulInt(19, f8); /* 1.959375*2^30 */
    final f9_38 = _mulInt(38, f9); /* 1.959375*2^30 */
    final Int64 f0f0 = _mulInt64(f0, f0);

    final Int64 f0f1_2 = _mulInt64(f0_2, f1);
    final Int64 f0f2_2 = _mulInt64(f0_2, f2);
    final Int64 f0f3_2 = _mulInt64(f0_2, f3);
    final Int64 f0f4_2 = _mulInt64(f0_2, f4);
    final Int64 f0f5_2 = _mulInt64(f0_2, f5);
    final Int64 f0f6_2 = _mulInt64(f0_2, f6);
    final Int64 f0f7_2 = _mulInt64(f0_2, f7);
    final Int64 f0f8_2 = _mulInt64(f0_2, f8);
    final Int64 f0f9_2 = _mulInt64(f0_2, f9);
    final Int64 f1f1_2 = _mulInt64(f1_2, f1);
    final Int64 f1f2_2 = _mulInt64(f1_2, f2);
    final Int64 f1f3_4 = _mulInt64(f1_2, f3_2);
    final Int64 f1f4_2 = _mulInt64(f1_2, f4);
    final Int64 f1f5_4 = _mulInt64(f1_2, f5_2);
    final Int64 f1f6_2 = _mulInt64(f1_2, f6);
    final Int64 f1f7_4 = _mulInt64(f1_2, f7_2);
    final Int64 f1f8_2 = _mulInt64(f1_2, f8);
    final Int64 f1f9_76 = _mulInt64(f1_2, f9_38);
    final Int64 f2f2 = _mulInt64(f2, f2);
    final Int64 f2f3_2 = _mulInt64(f2_2, f3);
    final Int64 f2f4_2 = _mulInt64(f2_2, f4);
    final Int64 f2f5_2 = _mulInt64(f2_2, f5);
    final Int64 f2f6_2 = _mulInt64(f2_2, f6);
    final Int64 f2f7_2 = _mulInt64(f2_2, f7);
    final Int64 f2f8_38 = _mulInt64(f2_2, f8_19);
    final Int64 f2f9_38 = _mulInt64(f2, f9_38);
    final Int64 f3f3_2 = _mulInt64(f3_2, f3);
    final Int64 f3f4_2 = _mulInt64(f3_2, f4);
    final Int64 f3f5_4 = _mulInt64(f3_2, f5_2);
    final Int64 f3f6_2 = _mulInt64(f3_2, f6);
    final Int64 f3f7_76 = _mulInt64(f3_2, f7_38);
    final Int64 f3f8_38 = _mulInt64(f3_2, f8_19);
    final Int64 f3f9_76 = _mulInt64(f3_2, f9_38);
    final Int64 f4f4 = _mulInt64(f4, f4);
    final Int64 f4f5_2 = _mulInt64(f4_2, f5);
    final Int64 f4f6_38 = _mulInt64(f4_2, f6_19);
    final Int64 f4f7_38 = _mulInt64(f4, f7_38);
    final Int64 f4f8_38 = _mulInt64(f4_2, f8_19);
    final Int64 f4f9_38 = _mulInt64(f4, f9_38);
    final Int64 f5f5_38 = _mulInt64(f5, f5_38);
    final Int64 f5f6_38 = _mulInt64(f5_2, f6_19);
    final Int64 f5f7_76 = _mulInt64(f5_2, f7_38);
    final Int64 f5f8_38 = _mulInt64(f5_2, f8_19);
    final Int64 f5f9_76 = _mulInt64(f5_2, f9_38);
    final Int64 f6f6_19 = _mulInt64(f6, f6_19);
    final Int64 f6f7_38 = _mulInt64(f6, f7_38);
    final Int64 f6f8_38 = _mulInt64(f6_2, f8_19);
    final Int64 f6f9_38 = _mulInt64(f6, f9_38);
    final Int64 f7f7_38 = _mulInt64(f7, f7_38);
    final Int64 f7f8_38 = _mulInt64(f7_2, f8_19);
    final Int64 f7f9_76 = _mulInt64(f7_2, f9_38);
    final Int64 f8f8_19 = _mulInt64(f8, f8_19);
    final Int64 f8f9_38 = _mulInt64(f8, f9_38);
    final Int64 f9f9_38 = _mulInt64(f9, f9_38);
    Int64 h0 = f0f0 + f1f9_76 + f2f8_38 + f3f7_76 + f4f6_38 + f5f5_38;
    Int64 h1 = f0f1_2 + f2f9_38 + f3f8_38 + f4f7_38 + f5f6_38;
    Int64 h2 = f0f2_2 + f1f1_2 + f3f9_76 + f4f8_38 + f5f7_76 + f6f6_19;
    Int64 h3 = f0f3_2 + f1f2_2 + f4f9_38 + f5f8_38 + f6f7_38;
    Int64 h4 = f0f4_2 + f1f3_4 + f2f2 + f5f9_76 + f6f8_38 + f7f7_38;
    Int64 h5 = f0f5_2 + f1f4_2 + f2f3_2 + f6f9_38 + f7f8_38;
    Int64 h6 = f0f6_2 + f1f5_4 + f2f4_2 + f3f3_2 + f7f9_76 + f8f8_19;
    Int64 h7 = f0f7_2 + f1f6_2 + f2f5_2 + f3f4_2 + f8f9_38;
    Int64 h8 = f0f8_2 + f1f7_4 + f2f6_2 + f3f5_4 + f4f4 + f9f9_38;
    Int64 h9 = f0f9_2 + f1f8_2 + f2f7_2 + f3f6_2 + f4f5_2;
    Int64 carry0;
    Int64 carry1;
    Int64 carry2;
    Int64 carry3;
    Int64 carry4;
    Int64 carry5;
    Int64 carry6;
    Int64 carry7;
    Int64 carry8;
    Int64 carry9;

    h0 += h0;
    h1 += h1;
    h2 += h2;
    h3 += h3;
    h4 += h4;
    h5 += h5;
    h6 += h6;
    h7 += h7;
    h8 += h8;
    h9 += h9;

    carry0 = (h0 + _bitMaskFor25) >> 26;
    h1 += carry0;
    h0 -= carry0 << 26;
    carry4 = (h4 + _bitMaskFor25) >> 26;
    h5 += carry4;
    h4 -= carry4 << 26;

    carry1 = (h1 + _bitMaskFor24) >> 25;
    h2 += carry1;
    h1 -= carry1 << 25;
    carry5 = (h5 + _bitMaskFor24) >> 25;
    h6 += carry5;
    h5 -= carry5 << 25;

    carry2 = (h2 + _bitMaskFor25) >> 26;
    h3 += carry2;
    h2 -= carry2 << 26;
    carry6 = (h6 + _bitMaskFor25) >> 26;
    h7 += carry6;
    h6 -= carry6 << 26;

    carry3 = (h3 + _bitMaskFor24) >> 25;
    h4 += carry3;
    h3 -= carry3 << 25;
    carry7 = (h7 + _bitMaskFor24) >> 25;
    h8 += carry7;
    h7 -= carry7 << 25;

    carry4 = (h4 + _bitMaskFor25) >> 26;
    h5 += carry4;
    h4 -= carry4 << 26;
    carry8 = (h8 + _bitMaskFor25) >> 26;
    h9 += carry8;
    h8 -= carry8 << 26;

    carry9 = (h9 + _bitMaskFor24) >> 25;
    h0 += carry9 * Int64(19);
    h9 -= carry9 << 25;

    carry0 = (h0 + _bitMaskFor25) >> 26;
    h1 += carry0;
    h0 -= carry0 << 26;

    h.h[0] = h0.toI32;
    h.h[1] = h1.toI32;
    h.h[2] = h2.toI32;
    h.h[3] = h3.toI32;
    h.h[4] = h4.toI32;
    h.h[5] = h5.toI32;
    h.h[6] = h6.toI32;
    h.h[7] = h7.toI32;
    h.h[8] = h8.toI32;
    h.h[9] = h9.toI32;
  }

  static void feSub(FieldElement h, FieldElement f, FieldElement g) {
    final Int32 f0 = f.h[0];
    final Int32 f1 = f.h[1];
    final Int32 f2 = f.h[2];
    final Int32 f3 = f.h[3];
    final Int32 f4 = f.h[4];
    final Int32 f5 = f.h[5];
    final Int32 f6 = f.h[6];
    final Int32 f7 = f.h[7];
    final Int32 f8 = f.h[8];
    final Int32 f9 = f.h[9];
    final Int32 g0 = g.h[0];
    final Int32 g1 = g.h[1];
    final Int32 g2 = g.h[2];
    final Int32 g3 = g.h[3];
    final Int32 g4 = g.h[4];
    final Int32 g5 = g.h[5];
    final Int32 g6 = g.h[6];
    final Int32 g7 = g.h[7];
    final Int32 g8 = g.h[8];
    final Int32 g9 = g.h[9];
    final Int32 h0 = f0 - g0;
    final Int32 h1 = f1 - g1;
    final Int32 h2 = f2 - g2;
    final Int32 h3 = f3 - g3;
    final Int32 h4 = f4 - g4;
    final Int32 h5 = f5 - g5;
    final Int32 h6 = f6 - g6;
    final Int32 h7 = f7 - g7;
    final Int32 h8 = f8 - g8;
    final Int32 h9 = f9 - g9;
    h.h[0] = h0;
    h.h[1] = h1;
    h.h[2] = h2;
    h.h[3] = h3;
    h.h[4] = h4;
    h.h[5] = h5;
    h.h[6] = h6;
    h.h[7] = h7;
    h.h[8] = h8;
    h.h[9] = h9;
  }

  static void feTobytes(List<int> s, FieldElement h) {
    s.asMin32("feTobytes");
    Int32 h0 = h.h[0];
    Int32 h1 = h.h[1];
    Int32 h2 = h.h[2];
    Int32 h3 = h.h[3];
    Int32 h4 = h.h[4];
    Int32 h5 = h.h[5];
    Int32 h6 = h.h[6];
    Int32 h7 = h.h[7];
    Int32 h8 = h.h[8];
    Int32 h9 = h.h[9];
    Int32 q;
    Int32 carry0;
    Int32 carry1;
    Int32 carry2;
    Int32 carry3;
    Int32 carry4;
    Int32 carry5;
    Int32 carry6;
    Int32 carry7;
    Int32 carry8;
    Int32 carry9;

    q = (Int32(19) * h9 + (Int32.one << 24)) >> 25;
    q = (h0 + q) >> 26;
    q = (h1 + q) >> 25;
    q = (h2 + q) >> 26;
    q = (h3 + q) >> 25;
    q = (h4 + q) >> 26;
    q = (h5 + q) >> 25;
    q = (h6 + q) >> 26;
    q = (h7 + q) >> 25;
    q = (h8 + q) >> 26;
    q = (h9 + q) >> 25;
    /* Goal: Output h-(2^255-19)q, which is between 0 and 2^255-20. */
    h0 += Int32.unsafe(19) * q;
    /* Goal: Output h-2^255 q, which is between 0 and 2^255-20. */

    carry0 = (h0 >> 26);
    h1 += carry0;
    h0 -= carry0 << 26;
    carry1 = h1 >> 25;
    h2 += carry1;
    h1 -= carry1 << 25;
    carry2 = h2 >> 26;
    h3 += carry2;
    h2 -= carry2 << 26;
    carry3 = h3 >> 25;
    h4 += carry3;
    h3 -= carry3 << 25;
    carry4 = h4 >> 26;
    h5 += carry4;
    h4 -= carry4 << 26;
    carry5 = h5 >> 25;
    h6 += carry5;
    h5 -= carry5 << 25;
    carry6 = h6 >> 26;
    h7 += carry6;
    h6 -= carry6 << 26;
    carry7 = h7 >> 25;
    h8 += carry7;
    h7 -= carry7 << 25;
    carry8 = h8 >> 26;
    h9 += carry8;
    h8 -= carry8 << 26;
    carry9 = h9 >> 25;
    h9 -= carry9 << 25;
    /* h10 = carry9 */

    /*
  Goal: Output h0+...+2^255 h10-2^255 q, which is between 0 and 2^255-20.
  Have h0+...+2^230 h9 between 0 and 2^255-1;
  evidently 2^255 h10-2^255 q = 0.
  Goal: Output h0+...+2^230 h9.
  */
    final List<Int32> sBig = List<Int32>.filled(32, Int32.zero);
    sBig[0] = h0 >> 0;
    sBig[1] = h0 >> 8;
    sBig[2] = h0 >> 16;
    sBig[3] = (h0 >> 24) | (h1 << 2);
    sBig[4] = h1 >> 6;
    sBig[5] = h1 >> 14;
    sBig[6] = (h1 >> 22) | (h2 << 3);
    sBig[7] = h2 >> 5;
    sBig[8] = h2 >> 13;
    sBig[9] = (h2 >> 21) | (h3 << 5);
    sBig[10] = h3 >> 3;
    sBig[11] = h3 >> 11;
    sBig[12] = (h3 >> 19) | (h4 << 6);
    sBig[13] = h4 >> 2;
    sBig[14] = h4 >> 10;
    sBig[15] = h4 >> 18;
    sBig[16] = h5 >> 0;
    sBig[17] = h5 >> 8;
    sBig[18] = h5 >> 16;
    sBig[19] = (h5 >> 24) | (h6 << 1);
    sBig[20] = h6 >> 7;
    sBig[21] = h6 >> 15;
    sBig[22] = (h6 >> 23) | (h7 << 3);
    sBig[23] = h7 >> 5;
    sBig[24] = h7 >> 13;
    sBig[25] = (h7 >> 21) | (h8 << 4);
    sBig[26] = h8 >> 4;
    sBig[27] = h8 >> 12;
    sBig[28] = (h8 >> 20) | (h9 << 6);
    sBig[29] = h9 >> 2;
    sBig[30] = h9 >> 10;
    sBig[31] = h9 >> 18;
    for (int i = 0; i < s.length; i++) {
      s[i] = sBig[i].toUint8();
    }
  }

  static void feMul(FieldElement h, FieldElement f, FieldElement g) {
    final Int32 f0 = f.h[0];
    final Int32 f1 = f.h[1];
    final Int32 f2 = f.h[2];
    final Int32 f3 = f.h[3];
    final Int32 f4 = f.h[4];
    final Int32 f5 = f.h[5];
    final Int32 f6 = f.h[6];
    final Int32 f7 = f.h[7];
    final Int32 f8 = f.h[8];
    final Int32 f9 = f.h[9];
    final Int32 g0 = g.h[0];
    final Int32 g1 = g.h[1];
    final Int32 g2 = g.h[2];
    final Int32 g3 = g.h[3];
    final Int32 g4 = g.h[4];
    final Int32 g5 = g.h[5];
    final Int32 g6 = g.h[6];
    final Int32 g7 = g.h[7];
    final Int32 g8 = g.h[8];
    final Int32 g9 = g.h[9];
    final Int32 g1_19 = _mulInt(19, g1); /* 1.959375*2^29 */
    final Int32 g2_19 = _mulInt(19, g2); /* 1.959375*2^30; still ok */
    final Int32 g3_19 = _mulInt(19, g3);
    final Int32 g4_19 = _mulInt(19, g4);
    final Int32 g5_19 = _mulInt(19, g5);
    final Int32 g6_19 = _mulInt(19, g6);
    final Int32 g7_19 = _mulInt(19, g7);
    final Int32 g8_19 = _mulInt(19, g8);
    final Int32 g9_19 = _mulInt(19, g9);
    final Int32 f1_2 = _mulInt(2, f1);
    final Int32 f3_2 = _mulInt(2, f3);
    final Int32 f5_2 = _mulInt(2, f5);
    final Int32 f7_2 = _mulInt(2, f7);
    final Int32 f9_2 = _mulInt(2, f9);

    final Int64 f0g0 = _mulInt64(f0, g0);
    final Int64 f0g1 = _mulInt64(f0, g1);
    final Int64 f0g2 = _mulInt64(f0, g2);
    final Int64 f0g3 = _mulInt64(f0, g3);
    final Int64 f0g4 = _mulInt64(f0, g4);
    final Int64 f0g5 = _mulInt64(f0, g5);
    final Int64 f0g6 = _mulInt64(f0, g6);
    final Int64 f0g7 = _mulInt64(f0, g7);
    final Int64 f0g8 = _mulInt64(f0, g8);
    final Int64 f0g9 = _mulInt64(f0, g9);
    final Int64 f1g0 = _mulInt64(f1, g0);
    final Int64 f1g1_2 = _mulInt64(f1_2, g1);
    final Int64 f1g2 = _mulInt64(f1, g2);
    final Int64 f1g3_2 = _mulInt64(f1_2, g3);
    final Int64 f1g4 = _mulInt64(f1, g4);
    final Int64 f1g5_2 = _mulInt64(f1_2, g5);
    final Int64 f1g6 = _mulInt64(f1, g6);
    final Int64 f1g7_2 = _mulInt64(f1_2, g7);
    final Int64 f1g8 = _mulInt64(f1, g8);
    final Int64 f1g9_38 = _mulInt64(f1_2, g9_19);
    final Int64 f2g0 = _mulInt64(f2, g0);
    final Int64 f2g1 = _mulInt64(f2, g1);
    final Int64 f2g2 = _mulInt64(f2, g2);
    final Int64 f2g3 = _mulInt64(f2, g3);
    final Int64 f2g4 = _mulInt64(f2, g4);
    final Int64 f2g5 = _mulInt64(f2, g5);
    final Int64 f2g6 = _mulInt64(f2, g6);
    final Int64 f2g7 = _mulInt64(f2, g7);
    final Int64 f2g8_19 = _mulInt64(f2, g8_19);
    final Int64 f2g9_19 = _mulInt64(f2, g9_19);
    final Int64 f3g0 = _mulInt64(f3, g0);
    final Int64 f3g1_2 = _mulInt64(f3_2, g1);
    final Int64 f3g2 = _mulInt64(f3, g2);
    final Int64 f3g3_2 = _mulInt64(f3_2, g3);
    final Int64 f3g4 = _mulInt64(f3, g4);
    final Int64 f3g5_2 = _mulInt64(f3_2, g5);
    final Int64 f3g6 = _mulInt64(f3, g6);
    final Int64 f3g7_38 = _mulInt64(f3_2, g7_19);
    final Int64 f3g8_19 = _mulInt64(f3, g8_19);
    final Int64 f3g9_38 = _mulInt64(f3_2, g9_19);
    final Int64 f4g0 = _mulInt64(f4, g0);
    final Int64 f4g1 = _mulInt64(f4, g1);
    final Int64 f4g2 = _mulInt64(f4, g2);
    final Int64 f4g3 = _mulInt64(f4, g3);
    final Int64 f4g4 = _mulInt64(f4, g4);
    final Int64 f4g5 = _mulInt64(f4, g5);
    final Int64 f4g6_19 = _mulInt64(f4, g6_19);
    final Int64 f4g7_19 = _mulInt64(f4, g7_19);
    final Int64 f4g8_19 = _mulInt64(f4, g8_19);
    final Int64 f4g9_19 = _mulInt64(f4, g9_19);
    final Int64 f5g0 = _mulInt64(f5, g0);
    final Int64 f5g1_2 = _mulInt64(f5_2, g1);
    final Int64 f5g2 = _mulInt64(f5, g2);
    final Int64 f5g3_2 = _mulInt64(f5_2, g3);
    final Int64 f5g4 = _mulInt64(f5, g4);
    final Int64 f5g5_38 = _mulInt64(f5_2, g5_19);
    final Int64 f5g6_19 = _mulInt64(f5, g6_19);
    final Int64 f5g7_38 = _mulInt64(f5_2, g7_19);
    final Int64 f5g8_19 = _mulInt64(f5, g8_19);
    final Int64 f5g9_38 = _mulInt64(f5_2, g9_19);
    final Int64 f6g0 = _mulInt64(f6, g0);
    final Int64 f6g1 = _mulInt64(f6, g1);
    final Int64 f6g2 = _mulInt64(f6, g2);
    final Int64 f6g3 = _mulInt64(f6, g3);
    final Int64 f6g4_19 = _mulInt64(f6, g4_19);
    final Int64 f6g5_19 = _mulInt64(f6, g5_19);
    final Int64 f6g6_19 = _mulInt64(f6, g6_19);
    final Int64 f6g7_19 = _mulInt64(f6, g7_19);
    final Int64 f6g8_19 = _mulInt64(f6, g8_19);
    final Int64 f6g9_19 = _mulInt64(f6, g9_19);
    final Int64 f7g0 = _mulInt64(f7, g0);
    final Int64 f7g1_2 = _mulInt64(f7_2, g1);
    final Int64 f7g2 = _mulInt64(f7, g2);
    final Int64 f7g3_38 = _mulInt64(f7_2, g3_19);
    final Int64 f7g4_19 = _mulInt64(f7, g4_19);
    final Int64 f7g5_38 = _mulInt64(f7_2, g5_19);
    final Int64 f7g6_19 = _mulInt64(f7, g6_19);
    final Int64 f7g7_38 = _mulInt64(f7_2, g7_19);
    final Int64 f7g8_19 = _mulInt64(f7, g8_19);
    final Int64 f7g9_38 = _mulInt64(f7_2, g9_19);
    final Int64 f8g0 = _mulInt64(f8, g0);
    final Int64 f8g1 = _mulInt64(f8, g1);
    final Int64 f8g2_19 = _mulInt64(f8, g2_19);
    final Int64 f8g3_19 = _mulInt64(f8, g3_19);
    final Int64 f8g4_19 = _mulInt64(f8, g4_19);
    final Int64 f8g5_19 = _mulInt64(f8, g5_19);
    final Int64 f8g6_19 = _mulInt64(f8, g6_19);
    final Int64 f8g7_19 = _mulInt64(f8, g7_19);
    final Int64 f8g8_19 = _mulInt64(f8, g8_19);
    final Int64 f8g9_19 = _mulInt64(f8, g9_19);
    final Int64 f9g0 = _mulInt64(f9, g0);
    final Int64 f9g1_38 = _mulInt64(f9_2, g1_19);
    final Int64 f9g2_19 = _mulInt64(f9, g2_19);
    final Int64 f9g3_38 = _mulInt64(f9_2, g3_19);
    final Int64 f9g4_19 = _mulInt64(f9, g4_19);
    final Int64 f9g5_38 = _mulInt64(f9_2, g5_19);
    final Int64 f9g6_19 = _mulInt64(f9, g6_19);
    final Int64 f9g7_38 = _mulInt64(f9_2, g7_19);
    final Int64 f9g8_19 = _mulInt64(f9, g8_19);
    final Int64 f9g9_38 = _mulInt64(f9_2, g9_19);
    Int64 h0 =
        f0g0 +
        f1g9_38 +
        f2g8_19 +
        f3g7_38 +
        f4g6_19 +
        f5g5_38 +
        f6g4_19 +
        f7g3_38 +
        f8g2_19 +
        f9g1_38;
    Int64 h1 =
        f0g1 +
        f1g0 +
        f2g9_19 +
        f3g8_19 +
        f4g7_19 +
        f5g6_19 +
        f6g5_19 +
        f7g4_19 +
        f8g3_19 +
        f9g2_19;
    Int64 h2 =
        f0g2 +
        f1g1_2 +
        f2g0 +
        f3g9_38 +
        f4g8_19 +
        f5g7_38 +
        f6g6_19 +
        f7g5_38 +
        f8g4_19 +
        f9g3_38;
    Int64 h3 =
        f0g3 +
        f1g2 +
        f2g1 +
        f3g0 +
        f4g9_19 +
        f5g8_19 +
        f6g7_19 +
        f7g6_19 +
        f8g5_19 +
        f9g4_19;
    Int64 h4 =
        f0g4 +
        f1g3_2 +
        f2g2 +
        f3g1_2 +
        f4g0 +
        f5g9_38 +
        f6g8_19 +
        f7g7_38 +
        f8g6_19 +
        f9g5_38;
    Int64 h5 =
        f0g5 + f1g4 + f2g3 + f3g2 + f4g1 + f5g0 + f6g9_19 + f7g8_19 + f8g7_19 + f9g6_19;
    Int64 h6 =
        f0g6 +
        f1g5_2 +
        f2g4 +
        f3g3_2 +
        f4g2 +
        f5g1_2 +
        f6g0 +
        f7g9_38 +
        f8g8_19 +
        f9g7_38;
    Int64 h7 = f0g7 + f1g6 + f2g5 + f3g4 + f4g3 + f5g2 + f6g1 + f7g0 + f8g9_19 + f9g8_19;
    Int64 h8 =
        f0g8 + f1g7_2 + f2g6 + f3g5_2 + f4g4 + f5g3_2 + f6g2 + f7g1_2 + f8g0 + f9g9_38;
    Int64 h9 = f0g9 + f1g8 + f2g7 + f3g6 + f4g5 + f5g4 + f6g3 + f7g2 + f8g1 + f9g0;
    Int64 carry0;
    Int64 carry1;
    Int64 carry2;
    Int64 carry3;
    Int64 carry4;
    Int64 carry5;
    Int64 carry6;
    Int64 carry7;
    Int64 carry8;
    Int64 carry9;

    /*
  |h0| <= (1.65*1.65*2^52*(1+19+19+19+19)+1.65*1.65*2^50*(38+38+38+38+38))
    i.e. |h0| <= 1.4*2^60; narrower ranges for h2, h4, h6, h8
  |h1| <= (1.65*1.65*2^51*(1+1+19+19+19+19+19+19+19+19))
    i.e. |h1| <= 1.7*2^59; narrower ranges for h3, h5, h7, h9
  */

    carry0 = (h0 + _bitMaskFor25) >> 26;
    h1 += carry0;
    h0 -= carry0 << 26;
    carry4 = (h4 + _bitMaskFor25) >> 26;
    h5 += carry4;
    h4 -= carry4 << 26;
    /* |h0| <= 2^25 */
    /* |h4| <= 2^25 */
    /* |h1| <= 1.71*2^59 */
    /* |h5| <= 1.71*2^59 */

    carry1 = (h1 + _bitMaskFor24) >> 25;
    h2 += carry1;
    h1 -= carry1 << 25;
    carry5 = (h5 + _bitMaskFor24) >> 25;
    h6 += carry5;
    h5 -= carry5 << 25;
    /* |h1| <= 2^24; from now on fits into int32 */
    /* |h5| <= 2^24; from now on fits into int32 */
    /* |h2| <= 1.41*2^60 */
    /* |h6| <= 1.41*2^60 */

    carry2 = (h2 + _bitMaskFor25) >> 26;
    h3 += carry2;
    h2 -= carry2 << 26;
    carry6 = (h6 + _bitMaskFor25) >> 26;
    h7 += carry6;
    h6 -= carry6 << 26;
    /* |h2| <= 2^25; from now on fits into int32 unchanged */
    /* |h6| <= 2^25; from now on fits into int32 unchanged */
    /* |h3| <= 1.71*2^59 */
    /* |h7| <= 1.71*2^59 */

    carry3 = (h3 + _bitMaskFor24) >> 25;
    h4 += carry3;
    h3 -= carry3 << 25;
    carry7 = (h7 + _bitMaskFor24) >> 25;
    h8 += carry7;
    h7 -= carry7 << 25;
    /* |h3| <= 2^24; from now on fits into int32 unchanged */
    /* |h7| <= 2^24; from now on fits into int32 unchanged */
    /* |h4| <= 1.72*2^34 */
    /* |h8| <= 1.41*2^60 */

    carry4 = (h4 + _bitMaskFor25) >> 26;
    h5 += carry4;
    h4 -= carry4 << 26;
    carry8 = (h8 + _bitMaskFor25) >> 26;
    h9 += carry8;
    h8 -= carry8 << 26;
    /* |h4| <= 2^25; from now on fits into int32 unchanged */
    /* |h8| <= 2^25; from now on fits into int32 unchanged */
    /* |h5| <= 1.01*2^24 */
    /* |h9| <= 1.71*2^59 */

    carry9 = (h9 + _bitMaskFor24) >> 25;
    h0 += carry9 * Int64(19);
    h9 -= carry9 << 25;
    /* |h9| <= 2^24; from now on fits into int32 unchanged */
    /* |h0| <= 1.1*2^39 */

    carry0 = (h0 + _bitMaskFor25) >> 26;
    h1 += carry0;
    h0 -= carry0 << 26;
    /* |h0| <= 2^25; from now on fits into int32 unchanged */
    /* |h1| <= 1.01*2^24 */

    h.h[0] = h0.toI32;
    h.h[1] = h1.toI32;
    h.h[2] = h2.toI32;
    h.h[3] = h3.toI32;
    h.h[4] = h4.toI32;
    h.h[5] = h5.toI32;
    h.h[6] = h6.toI32;
    h.h[7] = h7.toI32;
    h.h[8] = h8.toI32;
    h.h[9] = h9.toI32;
  }

  static void feDivpowm1(FieldElement r, FieldElement u, FieldElement v) {
    final FieldElement v3 = FieldElement(),
        uv7 = FieldElement(),
        t0 = FieldElement(),
        t1 = FieldElement(),
        t2 = FieldElement();
    int i;

    feSq(v3, v);
    feMul(v3, v3, v); /* v3 = v^3 */
    feSq(uv7, v3);
    feMul(uv7, uv7, v);
    feMul(uv7, uv7, u); /* uv7 = uv^7 */

    /*fe_pow22523(uv7, uv7);*/

    /* From fe_pow22523.c */

    feSq(t0, uv7);
    feSq(t1, t0);
    feSq(t1, t1);
    feMul(t1, uv7, t1);
    feMul(t0, t0, t1);
    feSq(t0, t0);
    feMul(t0, t1, t0);
    feSq(t1, t0);
    for (i = 0; i < 4; ++i) {
      feSq(t1, t1);
    }
    feMul(t0, t1, t0);
    feSq(t1, t0);
    for (i = 0; i < 9; ++i) {
      feSq(t1, t1);
    }
    feMul(t1, t1, t0);
    feSq(t2, t1);
    for (i = 0; i < 19; ++i) {
      feSq(t2, t2);
    }
    feMul(t1, t2, t1);
    for (i = 0; i < 10; ++i) {
      feSq(t1, t1);
    }
    feMul(t0, t1, t0);
    feSq(t1, t0);
    for (i = 0; i < 49; ++i) {
      feSq(t1, t1);
    }
    feMul(t1, t1, t0);
    feSq(t2, t1);
    for (i = 0; i < 99; ++i) {
      feSq(t2, t2);
    }
    feMul(t1, t2, t1);
    for (i = 0; i < 50; ++i) {
      feSq(t1, t1);
    }
    feMul(t0, t1, t0);
    feSq(t0, t0);
    feSq(t0, t0);
    feMul(t0, t0, uv7);

    /* End fe_pow22523.c */
    /* t0 = (uv^7)^((q-5)/8) */
    feMul(t0, t0, v3);
    feMul(r, t0, u); /* u^(m+1)v^(-(m+1)) */
  }

  static int feIsnonzero(FieldElement f) {
    final List<int> s = List<int>.filled(32, 0);
    feTobytes(s, f);
    for (final byte in s) {
      if (byte != 0) {
        return 1; // Found a non-zero byte
      }
    }
    return 0;
  }

  static void feInvert(FieldElement out, FieldElement z) {
    final FieldElement t0 = FieldElement();
    final FieldElement t1 = FieldElement();
    final FieldElement t2 = FieldElement();
    final FieldElement t3 = FieldElement();
    int i;

    feSq(t0, z);
    feSq(t1, t0);
    feSq(t1, t1);
    feMul(t1, z, t1);
    feMul(t0, t0, t1);
    feSq(t2, t0);
    feMul(t1, t1, t2);
    feSq(t2, t1);
    for (i = 0; i < 4; ++i) {
      feSq(t2, t2);
    }
    feMul(t1, t2, t1);
    feSq(t2, t1);
    for (i = 0; i < 9; ++i) {
      feSq(t2, t2);
    }
    feMul(t2, t2, t1);
    feSq(t3, t2);
    for (i = 0; i < 19; ++i) {
      feSq(t3, t3);
    }
    feMul(t2, t3, t2);
    feSq(t2, t2);
    for (i = 0; i < 9; ++i) {
      feSq(t2, t2);
    }
    feMul(t1, t2, t1);
    feSq(t2, t1);
    for (i = 0; i < 49; ++i) {
      feSq(t2, t2);
    }
    feMul(t2, t2, t1);
    feSq(t3, t2);
    for (i = 0; i < 99; ++i) {
      feSq(t3, t3);
    }
    feMul(t2, t3, t2);
    feSq(t2, t2);
    for (i = 0; i < 49; ++i) {
      feSq(t2, t2);
    }
    feMul(t1, t2, t1);
    feSq(t1, t1);
    for (i = 0; i < 4; ++i) {
      feSq(t1, t1);
    }
    feMul(out, t1, t0);

    return;
  }

  static List<int> geTobytes_(GroupElementP2 h) {
    final s = List<int>.filled(32, 0);
    geToBytes(s, h);
    return s;
  }

  static void geToBytes(List<int> s, GroupElementP2 h) {
    final FieldElement recip = FieldElement();
    final FieldElement x = FieldElement();
    final FieldElement y = FieldElement();
    feInvert(recip, h.z);
    feMul(x, h.x, recip);
    feMul(y, h.y, recip);
    feTobytes(s, y);
    s[31] ^= (feIsnegative(x) << 7) & 0xFF;
  }

  static void geSub(GroupElementP1P1 r, GroupElementP3 p, GroupElementCached q) {
    final FieldElement t0 = FieldElement();
    feAdd(r.x, p.y, p.x);
    feSub(r.y, p.y, p.x);
    feMul(r.z, r.x, q.yMinusX);
    feMul(r.y, r.y, q.yPlusX);
    feMul(r.t, q.t2d, p.t);
    feMul(r.x, p.z, q.z);
    feAdd(t0, r.x, r.x);
    feSub(r.x, r.z, r.y);
    feAdd(r.y, r.z, r.y);
    feSub(r.z, t0, r.t);
    feAdd(r.t, t0, r.t);
  }

  static void scMul(List<int> s, List<int> a, List<int> b) {
    s.asMin32("scMul");
    a.asMin32("scMul");
    b.asMin32("scMul");
    final Int64 a0 = _andU64(_b2097151, _load3(a, 0));
    final Int64 a1 = _andU64(_b2097151, (_load4(a, 2) >> 5));
    final Int64 a2 = _andU64(_b2097151, (_load3(a, 5) >> 2));
    final Int64 a3 = _andU64(_b2097151, (_load4(a, 7) >> 7));
    final Int64 a4 = _andU64(_b2097151, (_load4(a, 10) >> 4));
    final Int64 a5 = _andU64(_b2097151, (_load3(a, 13) >> 1));
    final Int64 a6 = _andU64(_b2097151, (_load4(a, 15) >> 6));
    final Int64 a7 = _andU64(_b2097151, (_load3(a, 18) >> 3));
    final Int64 a8 = _andU64(_b2097151, _load3(a, 21));
    final Int64 a9 = _andU64(_b2097151, (_load4(a, 23) >> 5));
    final Int64 a10 = _andU64(_b2097151, (_load3(a, 26) >> 2));
    final Int64 a11 = (_load4(a, 28) >> 7).toInt64();
    final Int64 b0 = _andU64(_b2097151, _load3(b, 0));
    final Int64 b1 = _andU64(_b2097151, (_load4(b, 2) >> 5));
    final Int64 b2 = _andU64(_b2097151, (_load3(b, 5) >> 2));
    final Int64 b3 = _andU64(_b2097151, (_load4(b, 7) >> 7));
    final Int64 b4 = _andU64(_b2097151, (_load4(b, 10) >> 4));
    final Int64 b5 = _andU64(_b2097151, (_load3(b, 13) >> 1));
    final Int64 b6 = _andU64(_b2097151, (_load4(b, 15) >> 6));
    final Int64 b7 = _andU64(_b2097151, (_load3(b, 18) >> 3));
    final Int64 b8 = _andU64(_b2097151, _load3(b, 21));
    final Int64 b9 = _andU64(_b2097151, (_load4(b, 23) >> 5));
    final Int64 b10 = _andU64(_b2097151, (_load3(b, 26) >> 2));
    final Int64 b11 = (_load4(b, 28) >> 7).toInt64();
    Int64 s0;
    Int64 s1;
    Int64 s2;
    Int64 s3;
    Int64 s4;
    Int64 s5;
    Int64 s6;
    Int64 s7;
    Int64 s8;
    Int64 s9;
    Int64 s10;
    Int64 s11;
    Int64 s12;
    Int64 s13;
    Int64 s14;
    Int64 s15;
    Int64 s16;
    Int64 s17;
    Int64 s18;
    Int64 s19;
    Int64 s20;
    Int64 s21;
    Int64 s22;
    Int64 s23;
    Int64 carry0;
    Int64 carry1;
    Int64 carry2;
    Int64 carry3;
    Int64 carry4;
    Int64 carry5;
    Int64 carry6;
    Int64 carry7;
    Int64 carry8;
    Int64 carry9;
    Int64 carry10;
    Int64 carry11;
    Int64 carry12;
    Int64 carry13;
    Int64 carry14;
    Int64 carry15;
    Int64 carry16;
    Int64 carry17;
    Int64 carry18;
    Int64 carry19;
    Int64 carry20;
    Int64 carry21;
    Int64 carry22;

    s0 = a0 * b0;
    s1 = (a0 * b1 + a1 * b0);
    s2 = (a0 * b2 + a1 * b1 + a2 * b0);
    s3 = (a0 * b3 + a1 * b2 + a2 * b1 + a3 * b0);
    s4 = (a0 * b4 + a1 * b3 + a2 * b2 + a3 * b1 + a4 * b0);
    s5 = (a0 * b5 + a1 * b4 + a2 * b3 + a3 * b2 + a4 * b1 + a5 * b0);
    s6 = (a0 * b6 + a1 * b5 + a2 * b4 + a3 * b3 + a4 * b2 + a5 * b1 + a6 * b0);
    s7 = (a0 * b7 + a1 * b6 + a2 * b5 + a3 * b4 + a4 * b3 + a5 * b2 + a6 * b1 + a7 * b0);
    s8 =
        (a0 * b8 +
            a1 * b7 +
            a2 * b6 +
            a3 * b5 +
            a4 * b4 +
            a5 * b3 +
            a6 * b2 +
            a7 * b1 +
            a8 * b0);
    s9 =
        (a0 * b9 +
            a1 * b8 +
            a2 * b7 +
            a3 * b6 +
            a4 * b5 +
            a5 * b4 +
            a6 * b3 +
            a7 * b2 +
            a8 * b1 +
            a9 * b0);
    s10 =
        (a0 * b10 +
            a1 * b9 +
            a2 * b8 +
            a3 * b7 +
            a4 * b6 +
            a5 * b5 +
            a6 * b4 +
            a7 * b3 +
            a8 * b2 +
            a9 * b1 +
            a10 * b0);
    s11 =
        (a0 * b11 +
            a1 * b10 +
            a2 * b9 +
            a3 * b8 +
            a4 * b7 +
            a5 * b6 +
            a6 * b5 +
            a7 * b4 +
            a8 * b3 +
            a9 * b2 +
            a10 * b1 +
            a11 * b0);
    s12 =
        (a1 * b11 +
            a2 * b10 +
            a3 * b9 +
            a4 * b8 +
            a5 * b7 +
            a6 * b6 +
            a7 * b5 +
            a8 * b4 +
            a9 * b3 +
            a10 * b2 +
            a11 * b1);
    s13 =
        (a2 * b11 +
            a3 * b10 +
            a4 * b9 +
            a5 * b8 +
            a6 * b7 +
            a7 * b6 +
            a8 * b5 +
            a9 * b4 +
            a10 * b3 +
            a11 * b2);
    s14 =
        (a3 * b11 +
            a4 * b10 +
            a5 * b9 +
            a6 * b8 +
            a7 * b7 +
            a8 * b6 +
            a9 * b5 +
            a10 * b4 +
            a11 * b3);
    s15 =
        (a4 * b11 +
            a5 * b10 +
            a6 * b9 +
            a7 * b8 +
            a8 * b7 +
            a9 * b6 +
            a10 * b5 +
            a11 * b4);
    s16 = (a5 * b11 + a6 * b10 + a7 * b9 + a8 * b8 + a9 * b7 + a10 * b6 + a11 * b5);
    s17 = (a6 * b11 + a7 * b10 + a8 * b9 + a9 * b8 + a10 * b7 + a11 * b6);
    s18 = (a7 * b11 + a8 * b10 + a9 * b9 + a10 * b8 + a11 * b7);
    s19 = (a8 * b11 + a9 * b10 + a10 * b9 + a11 * b8);
    s20 = (a9 * b11 + a10 * b10 + a11 * b9);
    s21 = (a10 * b11 + a11 * b10);
    s22 = a11 * b11;
    s23 = Int64.zero;

    carry0 = (s0 + _bitMaskFor20) >> 21;
    s1 += carry0;
    s0 -= carry0 << 21;
    carry2 = (s2 + _bitMaskFor20) >> 21;
    s3 += carry2;
    s2 -= carry2 << 21;
    carry4 = (s4 + _bitMaskFor20) >> 21;
    s5 += carry4;
    s4 -= carry4 << 21;
    carry6 = (s6 + _bitMaskFor20) >> 21;
    s7 += carry6;
    s6 -= carry6 << 21;
    carry8 = (s8 + _bitMaskFor20) >> 21;
    s9 += carry8;
    s8 -= carry8 << 21;
    carry10 = (s10 + _bitMaskFor20) >> 21;
    s11 += carry10;
    s10 -= carry10 << 21;
    carry12 = (s12 + _bitMaskFor20) >> 21;
    s13 += carry12;
    s12 -= carry12 << 21;
    carry14 = (s14 + _bitMaskFor20) >> 21;
    s15 += carry14;
    s14 -= carry14 << 21;
    carry16 = (s16 + _bitMaskFor20) >> 21;
    s17 += carry16;
    s16 -= carry16 << 21;
    carry18 = (s18 + _bitMaskFor20) >> 21;
    s19 += carry18;
    s18 -= carry18 << 21;
    carry20 = (s20 + _bitMaskFor20) >> 21;
    s21 += carry20;
    s20 -= carry20 << 21;
    carry22 = (s22 + _bitMaskFor20) >> 21;
    s23 += carry22;
    s22 -= carry22 << 21;

    carry1 = (s1 + _bitMaskFor20) >> 21;
    s2 += carry1;
    s1 -= carry1 << 21;
    carry3 = (s3 + _bitMaskFor20) >> 21;
    s4 += carry3;
    s3 -= carry3 << 21;
    carry5 = (s5 + _bitMaskFor20) >> 21;
    s6 += carry5;
    s5 -= carry5 << 21;
    carry7 = (s7 + _bitMaskFor20) >> 21;
    s8 += carry7;
    s7 -= carry7 << 21;
    carry9 = (s9 + _bitMaskFor20) >> 21;
    s10 += carry9;
    s9 -= carry9 << 21;
    carry11 = (s11 + _bitMaskFor20) >> 21;
    s12 += carry11;
    s11 -= carry11 << 21;
    carry13 = (s13 + _bitMaskFor20) >> 21;
    s14 += carry13;
    s13 -= carry13 << 21;
    carry15 = (s15 + _bitMaskFor20) >> 21;
    s16 += carry15;
    s15 -= carry15 << 21;
    carry17 = (s17 + _bitMaskFor20) >> 21;
    s18 += carry17;
    s17 -= carry17 << 21;
    carry19 = (s19 + _bitMaskFor20) >> 21;
    s20 += carry19;
    s19 -= carry19 << 21;
    carry21 = (s21 + _bitMaskFor20) >> 21;
    s22 += carry21;
    s21 -= carry21 << 21;

    s11 += _mulInt64Int(s23, 666643);
    s12 += _mulInt64Int(s23, 470296);
    s13 += _mulInt64Int(s23, 654183);
    s14 -= _mulInt64Int(s23, 997805);
    s15 += _mulInt64Int(s23, 136657);
    s16 -= _mulInt64Int(s23, 683901);

    s10 += _mulInt64Int(s22, 666643);
    s11 += _mulInt64Int(s22, 470296);
    s12 += _mulInt64Int(s22, 654183);
    s13 -= _mulInt64Int(s22, 997805);
    s14 += _mulInt64Int(s22, 136657);
    s15 -= _mulInt64Int(s22, 683901);

    s9 += _mulInt64Int(s21, 666643);
    s10 += _mulInt64Int(s21, 470296);
    s11 += _mulInt64Int(s21, 654183);
    s12 -= _mulInt64Int(s21, 997805);
    s13 += _mulInt64Int(s21, 136657);
    s14 -= _mulInt64Int(s21, 683901);

    s8 += _mulInt64Int(s20, 666643);
    s9 += _mulInt64Int(s20, 470296);
    s10 += _mulInt64Int(s20, 654183);
    s11 -= _mulInt64Int(s20, 997805);
    s12 += _mulInt64Int(s20, 136657);
    s13 -= _mulInt64Int(s20, 683901);

    s7 += _mulInt64Int(s19, 666643);
    s8 += _mulInt64Int(s19, 470296);
    s9 += _mulInt64Int(s19, 654183);
    s10 -= _mulInt64Int(s19, 997805);
    s11 += _mulInt64Int(s19, 136657);
    s12 -= _mulInt64Int(s19, 683901);

    s6 += _mulInt64Int(s18, 666643);
    s7 += _mulInt64Int(s18, 470296);
    s8 += _mulInt64Int(s18, 654183);
    s9 -= _mulInt64Int(s18, 997805);
    s10 += _mulInt64Int(s18, 136657);
    s11 -= _mulInt64Int(s18, 683901);

    carry6 = (s6 + _bitMaskFor20) >> 21;
    s7 += carry6;
    s6 -= carry6 << 21;
    carry8 = (s8 + _bitMaskFor20) >> 21;
    s9 += carry8;
    s8 -= carry8 << 21;
    carry10 = (s10 + _bitMaskFor20) >> 21;
    s11 += carry10;
    s10 -= carry10 << 21;
    carry12 = (s12 + _bitMaskFor20) >> 21;
    s13 += carry12;
    s12 -= carry12 << 21;
    carry14 = (s14 + _bitMaskFor20) >> 21;
    s15 += carry14;
    s14 -= carry14 << 21;
    carry16 = (s16 + _bitMaskFor20) >> 21;
    s17 += carry16;
    s16 -= carry16 << 21;

    carry7 = (s7 + _bitMaskFor20) >> 21;
    s8 += carry7;
    s7 -= carry7 << 21;
    carry9 = (s9 + _bitMaskFor20) >> 21;
    s10 += carry9;
    s9 -= carry9 << 21;
    carry11 = (s11 + _bitMaskFor20) >> 21;
    s12 += carry11;
    s11 -= carry11 << 21;
    carry13 = (s13 + _bitMaskFor20) >> 21;
    s14 += carry13;
    s13 -= carry13 << 21;
    carry15 = (s15 + _bitMaskFor20) >> 21;
    s16 += carry15;
    s15 -= carry15 << 21;

    s5 += _mulInt64Int(s17, 666643);
    s6 += _mulInt64Int(s17, 470296);
    s7 += _mulInt64Int(s17, 654183);
    s8 -= _mulInt64Int(s17, 997805);
    s9 += _mulInt64Int(s17, 136657);
    s10 -= _mulInt64Int(s17, 683901);

    s4 += _mulInt64Int(s16, 666643);
    s5 += _mulInt64Int(s16, 470296);
    s6 += _mulInt64Int(s16, 654183);
    s7 -= _mulInt64Int(s16, 997805);
    s8 += _mulInt64Int(s16, 136657);
    s9 -= _mulInt64Int(s16, 683901);

    s3 += _mulInt64Int(s15, 666643);
    s4 += _mulInt64Int(s15, 470296);
    s5 += _mulInt64Int(s15, 654183);
    s6 -= _mulInt64Int(s15, 997805);
    s7 += _mulInt64Int(s15, 136657);
    s8 -= _mulInt64Int(s15, 683901);

    s2 += _mulInt64Int(s14, 666643);
    s3 += _mulInt64Int(s14, 470296);
    s4 += _mulInt64Int(s14, 654183);
    s5 -= _mulInt64Int(s14, 997805);
    s6 += _mulInt64Int(s14, 136657);
    s7 -= _mulInt64Int(s14, 683901);

    s1 += _mulInt64Int(s13, 666643);
    s2 += _mulInt64Int(s13, 470296);
    s3 += _mulInt64Int(s13, 654183);
    s4 -= _mulInt64Int(s13, 997805);
    s5 += _mulInt64Int(s13, 136657);
    s6 -= _mulInt64Int(s13, 683901);

    s0 += _mulInt64Int(s12, 666643);
    s1 += _mulInt64Int(s12, 470296);
    s2 += _mulInt64Int(s12, 654183);
    s3 -= _mulInt64Int(s12, 997805);
    s4 += _mulInt64Int(s12, 136657);
    s5 -= _mulInt64Int(s12, 683901);
    s12 = Int64.zero;

    carry0 = (s0 + _bitMaskFor20) >> 21;
    s1 += carry0;
    s0 -= carry0 << 21;
    carry2 = (s2 + _bitMaskFor20) >> 21;
    s3 += carry2;
    s2 -= carry2 << 21;
    carry4 = (s4 + _bitMaskFor20) >> 21;
    s5 += carry4;
    s4 -= carry4 << 21;
    carry6 = (s6 + _bitMaskFor20) >> 21;
    s7 += carry6;
    s6 -= carry6 << 21;
    carry8 = (s8 + _bitMaskFor20) >> 21;
    s9 += carry8;
    s8 -= carry8 << 21;
    carry10 = (s10 + _bitMaskFor20) >> 21;
    s11 += carry10;
    s10 -= carry10 << 21;

    carry1 = (s1 + _bitMaskFor20) >> 21;
    s2 += carry1;
    s1 -= carry1 << 21;
    carry3 = (s3 + _bitMaskFor20) >> 21;
    s4 += carry3;
    s3 -= carry3 << 21;
    carry5 = (s5 + _bitMaskFor20) >> 21;
    s6 += carry5;
    s5 -= carry5 << 21;
    carry7 = (s7 + _bitMaskFor20) >> 21;
    s8 += carry7;
    s7 -= carry7 << 21;
    carry9 = (s9 + _bitMaskFor20) >> 21;
    s10 += carry9;
    s9 -= carry9 << 21;
    carry11 = (s11 + _bitMaskFor20) >> 21;
    s12 += carry11;
    s11 -= carry11 << 21;

    s0 += _mulInt64Int(s12, 666643);
    s1 += _mulInt64Int(s12, 470296);
    s2 += _mulInt64Int(s12, 654183);
    s3 -= _mulInt64Int(s12, 997805);
    s4 += _mulInt64Int(s12, 136657);
    s5 -= _mulInt64Int(s12, 683901);
    s12 = Int64.zero;

    carry0 = s0 >> 21;
    s1 += carry0;
    s0 -= carry0 << 21;
    carry1 = s1 >> 21;
    s2 += carry1;
    s1 -= carry1 << 21;
    carry2 = s2 >> 21;
    s3 += carry2;
    s2 -= carry2 << 21;
    carry3 = s3 >> 21;
    s4 += carry3;
    s3 -= carry3 << 21;
    carry4 = s4 >> 21;
    s5 += carry4;
    s4 -= carry4 << 21;
    carry5 = s5 >> 21;
    s6 += carry5;
    s5 -= carry5 << 21;
    carry6 = s6 >> 21;
    s7 += carry6;
    s6 -= carry6 << 21;
    carry7 = s7 >> 21;
    s8 += carry7;
    s7 -= carry7 << 21;
    carry8 = s8 >> 21;
    s9 += carry8;
    s8 -= carry8 << 21;
    carry9 = s9 >> 21;
    s10 += carry9;
    s9 -= carry9 << 21;
    carry10 = s10 >> 21;
    s11 += carry10;
    s10 -= carry10 << 21;
    carry11 = s11 >> 21;
    s12 += carry11;
    s11 -= carry11 << 21;

    s0 += _mulInt64Int(s12, 666643);
    s1 += _mulInt64Int(s12, 470296);
    s2 += _mulInt64Int(s12, 654183);
    s3 -= _mulInt64Int(s12, 997805);
    s4 += _mulInt64Int(s12, 136657);
    s5 -= _mulInt64Int(s12, 683901);

    carry0 = s0 >> 21;
    s1 += carry0;
    s0 -= carry0 << 21;
    carry1 = s1 >> 21;
    s2 += carry1;
    s1 -= carry1 << 21;
    carry2 = s2 >> 21;
    s3 += carry2;
    s2 -= carry2 << 21;
    carry3 = s3 >> 21;
    s4 += carry3;
    s3 -= carry3 << 21;
    carry4 = s4 >> 21;
    s5 += carry4;
    s4 -= carry4 << 21;
    carry5 = s5 >> 21;
    s6 += carry5;
    s5 -= carry5 << 21;
    carry6 = s6 >> 21;
    s7 += carry6;
    s6 -= carry6 << 21;
    carry7 = s7 >> 21;
    s8 += carry7;
    s7 -= carry7 << 21;
    carry8 = s8 >> 21;
    s9 += carry8;
    s8 -= carry8 << 21;
    carry9 = s9 >> 21;
    s10 += carry9;
    s9 -= carry9 << 21;
    carry10 = s10 >> 21;
    s11 += carry10;
    s10 -= carry10 << 21;
    final List<Int64> sBig = List<Int64>.filled(32, Int64.zero);
    sBig[0] = s0 >> 0;
    sBig[1] = s0 >> 8;
    sBig[2] = (s0 >> 16) | (s1 << 5);
    sBig[3] = s1 >> 3;
    sBig[4] = s1 >> 11;
    sBig[5] = (s1 >> 19) | (s2 << 2);
    sBig[6] = s2 >> 6;
    sBig[7] = (s2 >> 14) | (s3 << 7);
    sBig[8] = s3 >> 1;
    sBig[9] = s3 >> 9;
    sBig[10] = (s3 >> 17) | (s4 << 4);
    sBig[11] = s4 >> 4;
    sBig[12] = s4 >> 12;
    sBig[13] = (s4 >> 20) | (s5 << 1);
    sBig[14] = s5 >> 7;
    sBig[15] = (s5 >> 15) | (s6 << 6);
    sBig[16] = s6 >> 2;
    sBig[17] = s6 >> 10;
    sBig[18] = (s6 >> 18) | (s7 << 3);
    sBig[19] = s7 >> 5;
    sBig[20] = s7 >> 13;
    sBig[21] = s8 >> 0;
    sBig[22] = s8 >> 8;
    sBig[23] = (s8 >> 16) | (s9 << 5);
    sBig[24] = s9 >> 3;
    sBig[25] = s9 >> 11;
    sBig[26] = (s9 >> 19) | (s10 << 2);
    sBig[27] = s10 >> 6;
    sBig[28] = (s10 >> 14) | (s11 << 7);
    sBig[29] = s11 >> 1;
    sBig[30] = s11 >> 9;
    sBig[31] = s11 >> 17;
    for (int i = 0; i < sBig.length; i++) {
      s[i] = sBig[i].toUint8();
    }
  }

  static void geP3ToCached(GroupElementCached r, GroupElementP3 p) {
    feAdd(r.yPlusX, p.y, p.x);
    feSub(r.yMinusX, p.y, p.x);
    feCopy(r.z, p.z);
    feMul(r.t2d, p.t, CryptoOpsConst.d2);
  }

  static void scMulAdd(List<int> s, List<int> a, List<int> b, List<int> c) {
    s.asMin32("scMulAdd");
    a.asMin32("scMulAdd");
    b.asMin32("scMulAdd");
    c.asMin32("scMulAdd");
    final Int64 a0 = _andU64(_b2097151, _load3(a, 0));
    final Int64 a1 = _andU64(_b2097151, (_load4(a, 2) >> 5));
    final Int64 a2 = _andU64(_b2097151, (_load3(a, 5) >> 2));
    final Int64 a3 = _andU64(_b2097151, (_load4(a, 7) >> 7));
    final Int64 a4 = _andU64(_b2097151, (_load4(a, 10) >> 4));
    final Int64 a5 = _andU64(_b2097151, (_load3(a, 13) >> 1));
    final Int64 a6 = _andU64(_b2097151, (_load4(a, 15) >> 6));
    final Int64 a7 = _andU64(_b2097151, (_load3(a, 18) >> 3));
    final Int64 a8 = _andU64(_b2097151, _load3(a, 21));
    final Int64 a9 = _andU64(_b2097151, (_load4(a, 23) >> 5));
    final Int64 a10 = _andU64(_b2097151, (_load3(a, 26) >> 2));
    final Int64 a11 = (_load4(a, 28) >> 7).toInt64();
    final Int64 b0 = _andU64(_b2097151, _load3(b, 0));
    final Int64 b1 = _andU64(_b2097151, (_load4(b, 2) >> 5));
    final Int64 b2 = _andU64(_b2097151, (_load3(b, 5) >> 2));
    final Int64 b3 = _andU64(_b2097151, (_load4(b, 7) >> 7));
    final Int64 b4 = _andU64(_b2097151, (_load4(b, 10) >> 4));
    final Int64 b5 = _andU64(_b2097151, (_load3(b, 13) >> 1));
    final Int64 b6 = _andU64(_b2097151, (_load4(b, 15) >> 6));
    final Int64 b7 = _andU64(_b2097151, (_load3(b, 18) >> 3));
    final Int64 b8 = _andU64(_b2097151, _load3(b, 21));
    final Int64 b9 = _andU64(_b2097151, (_load4(b, 23) >> 5));
    final Int64 b10 = _andU64(_b2097151, (_load3(b, 26) >> 2));
    final Int64 b11 = (_load4(b, 28) >> 7).toInt64();
    final Int64 c0 = _andU64(_b2097151, _load3(c, 0));
    final Int64 c1 = _andU64(_b2097151, (_load4(c, 2) >> 5));
    final Int64 c2 = _andU64(_b2097151, (_load3(c, 5) >> 2));
    final Int64 c3 = _andU64(_b2097151, (_load4(c, 7) >> 7));
    final Int64 c4 = _andU64(_b2097151, (_load4(c, 10) >> 4));
    final Int64 c5 = _andU64(_b2097151, (_load3(c, 13) >> 1));
    final Int64 c6 = _andU64(_b2097151, (_load4(c, 15) >> 6));
    final Int64 c7 = _andU64(_b2097151, (_load3(c, 18) >> 3));
    final Int64 c8 = _andU64(_b2097151, _load3(c, 21));
    final Int64 c9 = _andU64(_b2097151, (_load4(c, 23) >> 5));
    final Int64 c10 = _andU64(_b2097151, (_load3(c, 26) >> 2));
    final Int64 c11 = (_load4(c, 28) >> 7).toInt64();
    Int64 s0;
    Int64 s1;
    Int64 s2;
    Int64 s3;
    Int64 s4;
    Int64 s5;
    Int64 s6;
    Int64 s7;
    Int64 s8;
    Int64 s9;
    Int64 s10;
    Int64 s11;
    Int64 s12;
    Int64 s13;
    Int64 s14;
    Int64 s15;
    Int64 s16;
    Int64 s17;
    Int64 s18;
    Int64 s19;
    Int64 s20;
    Int64 s21;
    Int64 s22;
    Int64 s23;
    Int64 carry0;
    Int64 carry1;
    Int64 carry2;
    Int64 carry3;
    Int64 carry4;
    Int64 carry5;
    Int64 carry6;
    Int64 carry7;
    Int64 carry8;
    Int64 carry9;
    Int64 carry10;
    Int64 carry11;
    Int64 carry12;
    Int64 carry13;
    Int64 carry14;
    Int64 carry15;
    Int64 carry16;
    Int64 carry17;
    Int64 carry18;
    Int64 carry19;
    Int64 carry20;
    Int64 carry21;
    Int64 carry22;

    s0 = c0 + a0 * b0;
    s1 = c1 + (a0 * b1 + a1 * b0);
    s2 = c2 + (a0 * b2 + a1 * b1 + a2 * b0);
    s3 = c3 + (a0 * b3 + a1 * b2 + a2 * b1 + a3 * b0);
    s4 = c4 + (a0 * b4 + a1 * b3 + a2 * b2 + a3 * b1 + a4 * b0);
    s5 = c5 + (a0 * b5 + a1 * b4 + a2 * b3 + a3 * b2 + a4 * b1 + a5 * b0);
    s6 = c6 + (a0 * b6 + a1 * b5 + a2 * b4 + a3 * b3 + a4 * b2 + a5 * b1 + a6 * b0);
    s7 =
        c7 +
        (a0 * b7 + a1 * b6 + a2 * b5 + a3 * b4 + a4 * b3 + a5 * b2 + a6 * b1 + a7 * b0);
    s8 =
        c8 +
        (a0 * b8 +
            a1 * b7 +
            a2 * b6 +
            a3 * b5 +
            a4 * b4 +
            a5 * b3 +
            a6 * b2 +
            a7 * b1 +
            a8 * b0);
    s9 =
        c9 +
        (a0 * b9 +
            a1 * b8 +
            a2 * b7 +
            a3 * b6 +
            a4 * b5 +
            a5 * b4 +
            a6 * b3 +
            a7 * b2 +
            a8 * b1 +
            a9 * b0);
    s10 =
        c10 +
        (a0 * b10 +
            a1 * b9 +
            a2 * b8 +
            a3 * b7 +
            a4 * b6 +
            a5 * b5 +
            a6 * b4 +
            a7 * b3 +
            a8 * b2 +
            a9 * b1 +
            a10 * b0);
    s11 =
        c11 +
        (a0 * b11 +
            a1 * b10 +
            a2 * b9 +
            a3 * b8 +
            a4 * b7 +
            a5 * b6 +
            a6 * b5 +
            a7 * b4 +
            a8 * b3 +
            a9 * b2 +
            a10 * b1 +
            a11 * b0);
    s12 =
        (a1 * b11 +
            a2 * b10 +
            a3 * b9 +
            a4 * b8 +
            a5 * b7 +
            a6 * b6 +
            a7 * b5 +
            a8 * b4 +
            a9 * b3 +
            a10 * b2 +
            a11 * b1);
    s13 =
        (a2 * b11 +
            a3 * b10 +
            a4 * b9 +
            a5 * b8 +
            a6 * b7 +
            a7 * b6 +
            a8 * b5 +
            a9 * b4 +
            a10 * b3 +
            a11 * b2);
    s14 =
        (a3 * b11 +
            a4 * b10 +
            a5 * b9 +
            a6 * b8 +
            a7 * b7 +
            a8 * b6 +
            a9 * b5 +
            a10 * b4 +
            a11 * b3);
    s15 =
        (a4 * b11 +
            a5 * b10 +
            a6 * b9 +
            a7 * b8 +
            a8 * b7 +
            a9 * b6 +
            a10 * b5 +
            a11 * b4);
    s16 = (a5 * b11 + a6 * b10 + a7 * b9 + a8 * b8 + a9 * b7 + a10 * b6 + a11 * b5);
    s17 = (a6 * b11 + a7 * b10 + a8 * b9 + a9 * b8 + a10 * b7 + a11 * b6);
    s18 = (a7 * b11 + a8 * b10 + a9 * b9 + a10 * b8 + a11 * b7);
    s19 = (a8 * b11 + a9 * b10 + a10 * b9 + a11 * b8);
    s20 = (a9 * b11 + a10 * b10 + a11 * b9);
    s21 = (a10 * b11 + a11 * b10);
    s22 = a11 * b11;
    s23 = Int64.zero;

    carry0 = (s0 + _bitMaskFor20) >> 21;
    s1 += carry0;
    s0 -= carry0 << 21;
    carry2 = (s2 + _bitMaskFor20) >> 21;
    s3 += carry2;
    s2 -= carry2 << 21;
    carry4 = (s4 + _bitMaskFor20) >> 21;
    s5 += carry4;
    s4 -= carry4 << 21;
    carry6 = (s6 + _bitMaskFor20) >> 21;
    s7 += carry6;
    s6 -= carry6 << 21;
    carry8 = (s8 + _bitMaskFor20) >> 21;
    s9 += carry8;
    s8 -= carry8 << 21;
    carry10 = (s10 + _bitMaskFor20) >> 21;
    s11 += carry10;
    s10 -= carry10 << 21;
    carry12 = (s12 + _bitMaskFor20) >> 21;
    s13 += carry12;
    s12 -= carry12 << 21;
    carry14 = (s14 + _bitMaskFor20) >> 21;
    s15 += carry14;
    s14 -= carry14 << 21;
    carry16 = (s16 + _bitMaskFor20) >> 21;
    s17 += carry16;
    s16 -= carry16 << 21;
    carry18 = (s18 + _bitMaskFor20) >> 21;
    s19 += carry18;
    s18 -= carry18 << 21;
    carry20 = (s20 + _bitMaskFor20) >> 21;
    s21 += carry20;
    s20 -= carry20 << 21;
    carry22 = (s22 + _bitMaskFor20) >> 21;
    s23 += carry22;
    s22 -= carry22 << 21;

    carry1 = (s1 + _bitMaskFor20) >> 21;
    s2 += carry1;
    s1 -= carry1 << 21;
    carry3 = (s3 + _bitMaskFor20) >> 21;
    s4 += carry3;
    s3 -= carry3 << 21;
    carry5 = (s5 + _bitMaskFor20) >> 21;
    s6 += carry5;
    s5 -= carry5 << 21;
    carry7 = (s7 + _bitMaskFor20) >> 21;
    s8 += carry7;
    s7 -= carry7 << 21;
    carry9 = (s9 + _bitMaskFor20) >> 21;
    s10 += carry9;
    s9 -= carry9 << 21;
    carry11 = (s11 + _bitMaskFor20) >> 21;
    s12 += carry11;
    s11 -= carry11 << 21;
    carry13 = (s13 + _bitMaskFor20) >> 21;
    s14 += carry13;
    s13 -= carry13 << 21;
    carry15 = (s15 + _bitMaskFor20) >> 21;
    s16 += carry15;
    s15 -= carry15 << 21;
    carry17 = (s17 + _bitMaskFor20) >> 21;
    s18 += carry17;
    s17 -= carry17 << 21;
    carry19 = (s19 + _bitMaskFor20) >> 21;
    s20 += carry19;
    s19 -= carry19 << 21;
    carry21 = (s21 + _bitMaskFor20) >> 21;
    s22 += carry21;
    s21 -= carry21 << 21;

    s11 += _mulInt64Int(s23, 666643);
    s12 += _mulInt64Int(s23, 470296);
    s13 += _mulInt64Int(s23, 654183);
    s14 -= _mulInt64Int(s23, 997805);
    s15 += _mulInt64Int(s23, 136657);
    s16 -= _mulInt64Int(s23, 683901);

    s10 += _mulInt64Int(s22, 666643);
    s11 += _mulInt64Int(s22, 470296);
    s12 += _mulInt64Int(s22, 654183);
    s13 -= _mulInt64Int(s22, 997805);
    s14 += _mulInt64Int(s22, 136657);
    s15 -= _mulInt64Int(s22, 683901);

    s9 += _mulInt64Int(s21, 666643);
    s10 += _mulInt64Int(s21, 470296);
    s11 += _mulInt64Int(s21, 654183);
    s12 -= _mulInt64Int(s21, 997805);
    s13 += _mulInt64Int(s21, 136657);
    s14 -= _mulInt64Int(s21, 683901);

    s8 += _mulInt64Int(s20, 666643);
    s9 += _mulInt64Int(s20, 470296);
    s10 += _mulInt64Int(s20, 654183);
    s11 -= _mulInt64Int(s20, 997805);
    s12 += _mulInt64Int(s20, 136657);
    s13 -= _mulInt64Int(s20, 683901);

    s7 += _mulInt64Int(s19, 666643);
    s8 += _mulInt64Int(s19, 470296);
    s9 += _mulInt64Int(s19, 654183);
    s10 -= _mulInt64Int(s19, 997805);
    s11 += _mulInt64Int(s19, 136657);
    s12 -= _mulInt64Int(s19, 683901);

    s6 += _mulInt64Int(s18, 666643);
    s7 += _mulInt64Int(s18, 470296);
    s8 += _mulInt64Int(s18, 654183);
    s9 -= _mulInt64Int(s18, 997805);
    s10 += _mulInt64Int(s18, 136657);
    s11 -= _mulInt64Int(s18, 683901);

    carry6 = (s6 + _bitMaskFor20) >> 21;
    s7 += carry6;
    s6 -= carry6 << 21;
    carry8 = (s8 + _bitMaskFor20) >> 21;
    s9 += carry8;
    s8 -= carry8 << 21;
    carry10 = (s10 + _bitMaskFor20) >> 21;
    s11 += carry10;
    s10 -= carry10 << 21;
    carry12 = (s12 + _bitMaskFor20) >> 21;
    s13 += carry12;
    s12 -= carry12 << 21;
    carry14 = (s14 + _bitMaskFor20) >> 21;
    s15 += carry14;
    s14 -= carry14 << 21;
    carry16 = (s16 + _bitMaskFor20) >> 21;
    s17 += carry16;
    s16 -= carry16 << 21;

    carry7 = (s7 + _bitMaskFor20) >> 21;
    s8 += carry7;
    s7 -= carry7 << 21;
    carry9 = (s9 + _bitMaskFor20) >> 21;
    s10 += carry9;
    s9 -= carry9 << 21;
    carry11 = (s11 + _bitMaskFor20) >> 21;
    s12 += carry11;
    s11 -= carry11 << 21;
    carry13 = (s13 + _bitMaskFor20) >> 21;
    s14 += carry13;
    s13 -= carry13 << 21;
    carry15 = (s15 + _bitMaskFor20) >> 21;
    s16 += carry15;
    s15 -= carry15 << 21;

    s5 += _mulInt64Int(s17, 666643);
    s6 += _mulInt64Int(s17, 470296);
    s7 += _mulInt64Int(s17, 654183);
    s8 -= _mulInt64Int(s17, 997805);
    s9 += _mulInt64Int(s17, 136657);
    s10 -= _mulInt64Int(s17, 683901);

    s4 += _mulInt64Int(s16, 666643);
    s5 += _mulInt64Int(s16, 470296);
    s6 += _mulInt64Int(s16, 654183);
    s7 -= _mulInt64Int(s16, 997805);
    s8 += _mulInt64Int(s16, 136657);
    s9 -= _mulInt64Int(s16, 683901);

    s3 += _mulInt64Int(s15, 666643);
    s4 += _mulInt64Int(s15, 470296);
    s5 += _mulInt64Int(s15, 654183);
    s6 -= _mulInt64Int(s15, 997805);
    s7 += _mulInt64Int(s15, 136657);
    s8 -= _mulInt64Int(s15, 683901);

    s2 += _mulInt64Int(s14, 666643);
    s3 += _mulInt64Int(s14, 470296);
    s4 += _mulInt64Int(s14, 654183);
    s5 -= _mulInt64Int(s14, 997805);
    s6 += _mulInt64Int(s14, 136657);
    s7 -= _mulInt64Int(s14, 683901);

    s1 += _mulInt64Int(s13, 666643);
    s2 += _mulInt64Int(s13, 470296);
    s3 += _mulInt64Int(s13, 654183);
    s4 -= _mulInt64Int(s13, 997805);
    s5 += _mulInt64Int(s13, 136657);
    s6 -= _mulInt64Int(s13, 683901);

    s0 += _mulInt64Int(s12, 666643);
    s1 += _mulInt64Int(s12, 470296);
    s2 += _mulInt64Int(s12, 654183);
    s3 -= _mulInt64Int(s12, 997805);
    s4 += _mulInt64Int(s12, 136657);
    s5 -= _mulInt64Int(s12, 683901);
    s12 = Int64.zero;

    carry0 = (s0 + _bitMaskFor20) >> 21;
    s1 += carry0;
    s0 -= carry0 << 21;
    carry2 = (s2 + _bitMaskFor20) >> 21;
    s3 += carry2;
    s2 -= carry2 << 21;
    carry4 = (s4 + _bitMaskFor20) >> 21;
    s5 += carry4;
    s4 -= carry4 << 21;
    carry6 = (s6 + _bitMaskFor20) >> 21;
    s7 += carry6;
    s6 -= carry6 << 21;
    carry8 = (s8 + _bitMaskFor20) >> 21;
    s9 += carry8;
    s8 -= carry8 << 21;
    carry10 = (s10 + _bitMaskFor20) >> 21;
    s11 += carry10;
    s10 -= carry10 << 21;

    carry1 = (s1 + _bitMaskFor20) >> 21;
    s2 += carry1;
    s1 -= carry1 << 21;
    carry3 = (s3 + _bitMaskFor20) >> 21;
    s4 += carry3;
    s3 -= carry3 << 21;
    carry5 = (s5 + _bitMaskFor20) >> 21;
    s6 += carry5;
    s5 -= carry5 << 21;
    carry7 = (s7 + _bitMaskFor20) >> 21;
    s8 += carry7;
    s7 -= carry7 << 21;
    carry9 = (s9 + _bitMaskFor20) >> 21;
    s10 += carry9;
    s9 -= carry9 << 21;
    carry11 = (s11 + _bitMaskFor20) >> 21;
    s12 += carry11;
    s11 -= carry11 << 21;

    s0 += _mulInt64Int(s12, 666643);
    s1 += _mulInt64Int(s12, 470296);
    s2 += _mulInt64Int(s12, 654183);
    s3 -= _mulInt64Int(s12, 997805);
    s4 += _mulInt64Int(s12, 136657);
    s5 -= _mulInt64Int(s12, 683901);
    s12 = Int64.zero;

    carry0 = s0 >> 21;
    s1 += carry0;
    s0 -= carry0 << 21;
    carry1 = s1 >> 21;
    s2 += carry1;
    s1 -= carry1 << 21;
    carry2 = s2 >> 21;
    s3 += carry2;
    s2 -= carry2 << 21;
    carry3 = s3 >> 21;
    s4 += carry3;
    s3 -= carry3 << 21;
    carry4 = s4 >> 21;
    s5 += carry4;
    s4 -= carry4 << 21;
    carry5 = s5 >> 21;
    s6 += carry5;
    s5 -= carry5 << 21;
    carry6 = s6 >> 21;
    s7 += carry6;
    s6 -= carry6 << 21;
    carry7 = s7 >> 21;
    s8 += carry7;
    s7 -= carry7 << 21;
    carry8 = s8 >> 21;
    s9 += carry8;
    s8 -= carry8 << 21;
    carry9 = s9 >> 21;
    s10 += carry9;
    s9 -= carry9 << 21;
    carry10 = s10 >> 21;
    s11 += carry10;
    s10 -= carry10 << 21;
    carry11 = s11 >> 21;
    s12 += carry11;
    s11 -= carry11 << 21;

    s0 += _mulInt64Int(s12, 666643);
    s1 += _mulInt64Int(s12, 470296);
    s2 += _mulInt64Int(s12, 654183);
    s3 -= _mulInt64Int(s12, 997805);
    s4 += _mulInt64Int(s12, 136657);
    s5 -= _mulInt64Int(s12, 683901);

    carry0 = s0 >> 21;
    s1 += carry0;
    s0 -= carry0 << 21;
    carry1 = s1 >> 21;
    s2 += carry1;
    s1 -= carry1 << 21;
    carry2 = s2 >> 21;
    s3 += carry2;
    s2 -= carry2 << 21;
    carry3 = s3 >> 21;
    s4 += carry3;
    s3 -= carry3 << 21;
    carry4 = s4 >> 21;
    s5 += carry4;
    s4 -= carry4 << 21;
    carry5 = s5 >> 21;
    s6 += carry5;
    s5 -= carry5 << 21;
    carry6 = s6 >> 21;
    s7 += carry6;
    s6 -= carry6 << 21;
    carry7 = s7 >> 21;
    s8 += carry7;
    s7 -= carry7 << 21;
    carry8 = s8 >> 21;
    s9 += carry8;
    s8 -= carry8 << 21;
    carry9 = s9 >> 21;
    s10 += carry9;
    s9 -= carry9 << 21;
    carry10 = s10 >> 21;
    s11 += carry10;
    s10 -= carry10 << 21;
    final List<Int64> sBig = List<Int64>.filled(32, Int64.zero);
    sBig[0] = s0 >> 0;
    sBig[1] = s0 >> 8;
    sBig[2] = (s0 >> 16) | (s1 << 5);
    sBig[3] = s1 >> 3;
    sBig[4] = s1 >> 11;
    sBig[5] = (s1 >> 19) | (s2 << 2);
    sBig[6] = s2 >> 6;
    sBig[7] = (s2 >> 14) | (s3 << 7);
    sBig[8] = s3 >> 1;
    sBig[9] = s3 >> 9;
    sBig[10] = (s3 >> 17) | (s4 << 4);
    sBig[11] = s4 >> 4;
    sBig[12] = s4 >> 12;
    sBig[13] = (s4 >> 20) | (s5 << 1);
    sBig[14] = s5 >> 7;
    sBig[15] = (s5 >> 15) | (s6 << 6);
    sBig[16] = s6 >> 2;
    sBig[17] = s6 >> 10;
    sBig[18] = (s6 >> 18) | (s7 << 3);
    sBig[19] = s7 >> 5;
    sBig[20] = s7 >> 13;
    sBig[21] = s8 >> 0;
    sBig[22] = s8 >> 8;
    sBig[23] = (s8 >> 16) | (s9 << 5);
    sBig[24] = s9 >> 3;
    sBig[25] = s9 >> 11;
    sBig[26] = (s9 >> 19) | (s10 << 2);
    sBig[27] = s10 >> 6;
    sBig[28] = (s10 >> 14) | (s11 << 7);
    sBig[29] = s11 >> 1;
    sBig[30] = s11 >> 9;
    sBig[31] = s11 >> 17;
    for (int i = 0; i < sBig.length; i++) {
      s[i] = sBig[i].toUint8();
    }
  }

  static void geDsmPrecomp(List<GroupElementCached> r, GroupElementP3 s) {
    final GroupElementP1P1 t = GroupElementP1P1();
    final GroupElementP3 s2 = GroupElementP3();
    final GroupElementP3 u = GroupElementP3();
    geP3ToCached(r[0], s);

    geP3Dbl(t, s);
    geP1P1ToP3(s2, t);
    geAdd(t, s2, r[0]);

    geP1P1ToP3(u, t);

    geP3ToCached(r[1], u);
    geAdd(t, s2, r[1]);
    geP1P1ToP3(u, t);
    geP3ToCached(r[2], u);
    geAdd(t, s2, r[2]);
    geP1P1ToP3(u, t);
    geP3ToCached(r[3], u);
    geAdd(t, s2, r[3]);
    geP1P1ToP3(u, t);
    geP3ToCached(r[4], u);
    geAdd(t, s2, r[4]);
    geP1P1ToP3(u, t);
    geP3ToCached(r[5], u);
    geAdd(t, s2, r[5]);
    geP1P1ToP3(u, t);
    geP3ToCached(r[6], u);
    geAdd(t, s2, r[6]);
    geP1P1ToP3(u, t);
    geP3ToCached(r[7], u);
  }

  static void slide(List<int> r, List<int> a) {
    int i, b, k;

    // First loop: Initialize r[i] based on a[i >> 3] and bitwise operations.
    for (i = 0; i < 256; ++i) {
      r[i] = 1 & (a[i >> 3] >> (i & 7));
    }

    // Second loop: Update r based on the specified conditions.
    for (i = 0; i < 256; ++i) {
      if (r[i] != 0) {
        for (b = 1; b <= 6 && i + b < 256; ++b) {
          if (r[i + b] != 0) {
            if (r[i] + (r[i + b] << b) <= 15) {
              r[i] += r[i + b] << b;
              r[i + b] = 0;
            } else if (r[i] - (r[i + b] << b) >= -15) {
              r[i] -= r[i + b] << b;
              for (k = i + b; k < 256; ++k) {
                if (r[k] == 0) {
                  r[k] = 1;
                  break;
                }
                r[k] = 0;
              }
            } else {
              break;
            }
          }
        }
      }
    }
  }

  static void geMsub(GroupElementP1P1 r, GroupElementP3 p, GroupElementPrecomp q) {
    final FieldElement t0 = FieldElement();
    feAdd(r.x, p.y, p.x);
    feSub(r.y, p.y, p.x);
    feMul(r.z, r.x, q.yminusx);
    feMul(r.y, r.y, q.yplusx);
    feMul(r.t, q.xy2d, p.t);
    feAdd(t0, p.z, p.z);
    feSub(r.x, r.z, r.y);
    feAdd(r.y, r.z, r.y);
    feSub(r.z, t0, r.t);
    feAdd(r.t, t0, r.t);
  }

  static void geDoubleScalarMultBaseVartimeP3(
    GroupElementP3 r3,
    List<int> a,
    GroupElementP3 gA,
    List<int> b,
  ) {
    b.asMin32("geDoubleScalarMultBaseVartimeP3");
    final List<int> aslide = List<int>.filled(256, 0);
    final List<int> bslide = List<int>.filled(256, 0);
    final List<GroupElementCached> aI = GroupElementCached.dsmp;
    final GroupElementP1P1 t = GroupElementP1P1();
    final GroupElementP3 u = GroupElementP3();
    final GroupElementP2 r = GroupElementP2();
    int i;

    slide(aslide, a);
    slide(bslide, b);
    geDsmPrecomp(aI, gA);

    geP2Zero(r);

    for (i = 255; i >= 0; --i) {
      if (aslide[i] != 0 || bslide[i] != 0) {
        break;
      }
    }

    for (; i >= 0; --i) {
      geP2Dbl(t, r);

      if (aslide[i] > 0) {
        geP1P1ToP3(u, t);
        geAdd(t, u, aI[aslide[i] ~/ 2]);
      } else if (aslide[i] < 0) {
        geP1P1ToP3(u, t);
        geSub(t, u, aI[(-aslide[i]) ~/ 2]);
      }

      if (bslide[i] > 0) {
        geP1P1ToP3(u, t);
        geMadd(t, u, CryptoOpsConst.geBi[bslide[i] ~/ 2]);
      } else if (bslide[i] < 0) {
        geP1P1ToP3(u, t);
        geMsub(t, u, CryptoOpsConst.geBi[(-bslide[i]) ~/ 2]);
      }

      if (i == 0) {
        geP1P1ToP3(r3, t);
      } else {
        geP1P1ToP2(r, t);
      }
    }
  }

  static Map<int, String> geDoubleScalarMultBaseVartime(
    GroupElementP2 r,
    List<int> a,
    GroupElementP3 gA,
    List<int> b,
  ) {
    b.asMin32("geDoubleScalarMultBaseVartime");
    final List<int> aslide = List<int>.filled(256, 0);
    final List<int> bslide = List<int>.filled(256, 0);
    final List<GroupElementCached> aI = GroupElementCached.dsmp;
    final GroupElementP1P1 t = GroupElementP1P1();
    final GroupElementP3 u = GroupElementP3();
    int i;
    final Map<int, String> res = {};

    slide(aslide, a);
    slide(bslide, b);

    geDsmPrecomp(aI, gA);
    geP2Zero(r);

    for (i = 255; i >= 0; --i) {
      if (aslide[i] != 0 || bslide[i] != 0) {
        break;
      }
    }
    for (; i >= 0; --i) {
      geP2Dbl(t, r);

      if (aslide[i] > 0) {
        geP1P1ToP3(u, t);
        geAdd(t, u, aI[aslide[i] ~/ 2]);
      } else if (aslide[i] < 0) {
        geP1P1ToP3(u, t);
        geSub(t, u, aI[(-aslide[i]) ~/ 2]);
      }

      if (bslide[i] > 0) {
        geP1P1ToP3(u, t);
        geMadd(t, u, CryptoOpsConst.geBi[bslide[i] ~/ 2]);
      } else if (bslide[i] < 0) {
        geP1P1ToP3(u, t);
        geMsub(t, u, CryptoOpsConst.geBi[(-bslide[i]) ~/ 2]);
      }
      final re = GroupElementP3();
      geP1P1ToP3(re, t.clone());
      res.addAll({i: BytesUtils.toHexString(geP3Tobytes_(re))});
      geP1P1ToP2(r, t);
    }
    return res;
  }

  static void geFromfeFrombytesVartime(GroupElementP2 r, List<int> s) {
    s.asMin32("geFromfeFrombytesVartime");
    final FieldElement u = FieldElement(),
        v = FieldElement(),
        w = FieldElement(),
        x = FieldElement(),
        y = FieldElement(),
        z = FieldElement();

    /* From fe_frombytes.c */

    Int64 h0 = _load4(s, 0).toInt64();
    Int64 h1 = (_load3(s, 4) << 6).toInt64();
    Int64 h2 = (_load3(s, 7) << 5).toInt64();
    Int64 h3 = (_load3(s, 10) << 3).toInt64();
    Int64 h4 = (_load3(s, 13) << 2).toInt64();
    Int64 h5 = _load4(s, 16).toInt64();
    Int64 h6 = (_load3(s, 20) << 7).toInt64();
    Int64 h7 = (_load3(s, 23) << 5).toInt64();
    Int64 h8 = (_load3(s, 26) << 4).toInt64();
    Int64 h9 = (_load3(s, 29) << 2).toInt64();
    Int64 carry0;
    Int64 carry1;
    Int64 carry2;
    Int64 carry3;
    Int64 carry4;
    Int64 carry5;
    Int64 carry6;
    Int64 carry7;
    Int64 carry8;
    Int64 carry9;

    carry9 = (h9 + _bitMaskFor24) >> 25;
    h0 += carry9 * Int64(19);
    h9 -= carry9 << 25;
    carry1 = (h1 + _bitMaskFor24) >> 25;
    h2 += carry1;
    h1 -= carry1 << 25;
    carry3 = (h3 + _bitMaskFor24) >> 25;
    h4 += carry3;
    h3 -= carry3 << 25;
    carry5 = (h5 + _bitMaskFor24) >> 25;
    h6 += carry5;
    h5 -= carry5 << 25;
    carry7 = (h7 + _bitMaskFor24) >> 25;
    h8 += carry7;
    h7 -= carry7 << 25;

    carry0 = (h0 + _bitMaskFor25) >> 26;
    h1 += carry0;
    h0 -= carry0 << 26;
    carry2 = (h2 + _bitMaskFor25) >> 26;
    h3 += carry2;
    h2 -= carry2 << 26;
    carry4 = (h4 + _bitMaskFor25) >> 26;
    h5 += carry4;
    h4 -= carry4 << 26;
    carry6 = (h6 + _bitMaskFor25) >> 26;
    h7 += carry6;
    h6 -= carry6 << 26;
    carry8 = (h8 + _bitMaskFor25) >> 26;
    h9 += carry8;
    h8 -= carry8 << 26;

    u.h[0] = h0.toI32;
    u.h[1] = h1.toI32;
    u.h[2] = h2.toI32;
    u.h[3] = h3.toI32;
    u.h[4] = h4.toI32;
    u.h[5] = h5.toI32;
    u.h[6] = h6.toI32;
    u.h[7] = h7.toI32;
    u.h[8] = h8.toI32;
    u.h[9] = h9.toI32;

    /* End fe_frombytes.c */

    feSq2(v, u); /* 2 * u^2 */
    fe1(w);
    feAdd(w, v, w); /* w = 2 * u^2 + 1 */
    feSq(x, w); /* w^2 */
    feMul(y, CryptoOpsConst.ma2, v); /* -2 * A^2 * u^2 */
    feAdd(x, x, y); /* x = w^2 - 2 * A^2 * u^2 */
    feDivpowm1(r.x, w, x); /* (w / x)^(m + 1) */
    feSq(y, r.x);
    feMul(x, y, x);
    feSub(y, w, x);
    feCopy(z, CryptoOpsConst.ma);
    if (feIsnonzero(y) != 0) {
      feAdd(y, w, x);
      if (feIsnonzero(y) != 0) {
        return _negative(x: x, r: r, y: y, w: w, z: z);
      } else {
        feMul(r.x, r.x, CryptoOpsConst.fffb1);
      }
    } else {
      feMul(r.x, r.x, CryptoOpsConst.fffb2);
    }
    feMul(r.x, r.x, u); /* u * sqrt(2 * A * (A + 2) * w / x) */
    feMul(z, z, v); /* -2 * A * u^2 */
    _setSign(r: r, sign: 0, z: z, w: w);
  }

  static void _negative({
    required FieldElement x,
    required GroupElementP2 r,
    required FieldElement y,
    required FieldElement w,
    required FieldElement z,
  }) {
    feMul(x, x, CryptoOpsConst.feSqrtm1);
    feSub(y, w, x);
    if (feIsnonzero(y) != 0) {
      // assert((feAdd(y, w, x), feIsnonzero(y)==0));
      feMul(r.x, r.x, CryptoOpsConst.fffb3);
    } else {
      feMul(r.x, r.x, CryptoOpsConst.fffb4);
    }
    _setSign(r: r, sign: 1, z: z, w: w);
  }

  static void geP1P1ToP3(GroupElementP3 r, GroupElementP1P1 p) {
    feMul(r.x, p.x, p.t);
    feMul(r.y, p.y, p.z);
    feMul(r.z, p.z, p.t);
    feMul(r.t, p.x, p.y);
  }

  static List<int> geP3Tobytes_(GroupElementP3 h) {
    final List<int> s = List<int>.filled(32, 0);
    final FieldElement recip = FieldElement();
    final FieldElement x = FieldElement();
    final FieldElement y = FieldElement();

    feInvert(recip, h.z);
    feMul(x, h.x, recip);
    feMul(y, h.y, recip);
    feTobytes(s, y);
    s[31] ^= feIsnegative(x) << 7;
    return s;
  }

  static void scReduce(List<int> r, List<int> s) {
    Int64 s0 = _andU64(_b2097151, _load3(s, 0));
    Int64 s1 = _andU64(_b2097151, (_load4(s, 2) >> 5));
    Int64 s2 = _andU64(_b2097151, (_load3(s, 5) >> 2));
    Int64 s3 = _andU64(_b2097151, (_load4(s, 7) >> 7));
    Int64 s4 = _andU64(_b2097151, (_load4(s, 10) >> 4));
    Int64 s5 = _andU64(_b2097151, (_load3(s, 13) >> 1));
    Int64 s6 = _andU64(_b2097151, (_load4(s, 15) >> 6));
    Int64 s7 = _andU64(_b2097151, (_load3(s, 18) >> 3));
    Int64 s8 = _andU64(_b2097151, _load3(s, 21));
    Int64 s9 = _andU64(_b2097151, (_load4(s, 23) >> 5));
    Int64 s10 = _andU64(_b2097151, (_load3(s, 26) >> 2));
    Int64 s11 = _andU64(_b2097151, (_load4(s, 28) >> 7));
    Int64 s12 = _andU64(_b2097151, (_load4(s, 31) >> 4));
    Int64 s13 = _andU64(_b2097151, (_load3(s, 34) >> 1));
    Int64 s14 = _andU64(_b2097151, (_load4(s, 36) >> 6));
    Int64 s15 = _andU64(_b2097151, (_load3(s, 39) >> 3));
    Int64 s16 = _andU64(_b2097151, _load3(s, 42));
    Int64 s17 = _andU64(_b2097151, (_load4(s, 44) >> 5));
    Int64 s18 = _andU64(_b2097151, (_load3(s, 47) >> 2));
    Int64 s19 = _andU64(_b2097151, (_load4(s, 49) >> 7));
    Int64 s20 = _andU64(_b2097151, (_load4(s, 52) >> 4));
    Int64 s21 = _andU64(_b2097151, (_load3(s, 55) >> 1));
    Int64 s22 = _andU64(_b2097151, (_load4(s, 57) >> 6));
    Int64 s23 = (_load4(s, 60) >> 3).toInt64();
    Int64 carry0;
    Int64 carry1;
    Int64 carry2;
    Int64 carry3;
    Int64 carry4;
    Int64 carry5;
    Int64 carry6;
    Int64 carry7;
    Int64 carry8;
    Int64 carry9;
    Int64 carry10;
    Int64 carry11;
    Int64 carry12;
    Int64 carry13;
    Int64 carry14;
    Int64 carry15;
    Int64 carry16;

    s11 += _mulInt64Int(s23, 666643);
    s12 += _mulInt64Int(s23, 470296);
    s13 += _mulInt64Int(s23, 654183);
    s14 -= _mulInt64Int(s23, 997805);
    s15 += _mulInt64Int(s23, 136657);
    s16 -= _mulInt64Int(s23, 683901);

    s10 += _mulInt64Int(s22, 666643);
    s11 += _mulInt64Int(s22, 470296);
    s12 += _mulInt64Int(s22, 654183);
    s13 -= _mulInt64Int(s22, 997805);
    s14 += _mulInt64Int(s22, 136657);
    s15 -= _mulInt64Int(s22, 683901);

    s9 += _mulInt64Int(s21, 666643);
    s10 += _mulInt64Int(s21, 470296);
    s11 += _mulInt64Int(s21, 654183);
    s12 -= _mulInt64Int(s21, 997805);
    s13 += _mulInt64Int(s21, 136657);
    s14 -= _mulInt64Int(s21, 683901);

    s8 += _mulInt64Int(s20, 666643);
    s9 += _mulInt64Int(s20, 470296);
    s10 += _mulInt64Int(s20, 654183);
    s11 -= _mulInt64Int(s20, 997805);
    s12 += _mulInt64Int(s20, 136657);
    s13 -= _mulInt64Int(s20, 683901);

    s7 += _mulInt64Int(s19, 666643);
    s8 += _mulInt64Int(s19, 470296);
    s9 += _mulInt64Int(s19, 654183);
    s10 -= _mulInt64Int(s19, 997805);
    s11 += _mulInt64Int(s19, 136657);
    s12 -= _mulInt64Int(s19, 683901);

    s6 += _mulInt64Int(s18, 666643);
    s7 += _mulInt64Int(s18, 470296);
    s8 += _mulInt64Int(s18, 654183);
    s9 -= _mulInt64Int(s18, 997805);
    s10 += _mulInt64Int(s18, 136657);
    s11 -= _mulInt64Int(s18, 683901);

    carry6 = (s6 + (Int64.one << 20)) >> 21;
    s7 += carry6;
    s6 -= carry6 << 21;
    carry8 = (s8 + (Int64.one << 20)) >> 21;
    s9 += carry8;
    s8 -= carry8 << 21;
    carry10 = (s10 + (Int64.one << 20)) >> 21;
    s11 += carry10;
    s10 -= carry10 << 21;
    carry12 = (s12 + (Int64.one << 20)) >> 21;
    s13 += carry12;
    s12 -= carry12 << 21;
    carry14 = (s14 + (Int64.one << 20)) >> 21;
    s15 += carry14;
    s14 -= carry14 << 21;
    carry16 = (s16 + (Int64.one << 20)) >> 21;
    s17 += carry16;
    s16 -= carry16 << 21;

    carry7 = (s7 + (Int64.one << 20)) >> 21;
    s8 += carry7;
    s7 -= carry7 << 21;
    carry9 = (s9 + (Int64.one << 20)) >> 21;
    s10 += carry9;
    s9 -= carry9 << 21;
    carry11 = (s11 + (Int64.one << 20)) >> 21;
    s12 += carry11;
    s11 -= carry11 << 21;
    carry13 = (s13 + (Int64.one << 20)) >> 21;
    s14 += carry13;
    s13 -= carry13 << 21;
    carry15 = (s15 + (Int64.one << 20)) >> 21;
    s16 += carry15;
    s15 -= carry15 << 21;

    s5 += _mulInt64Int(s17, 666643);
    s6 += _mulInt64Int(s17, 470296);
    s7 += _mulInt64Int(s17, 654183);
    s8 -= _mulInt64Int(s17, 997805);
    s9 += _mulInt64Int(s17, 136657);
    s10 -= _mulInt64Int(s17, 683901);

    s4 += _mulInt64Int(s16, 666643);
    s5 += _mulInt64Int(s16, 470296);
    s6 += _mulInt64Int(s16, 654183);
    s7 -= _mulInt64Int(s16, 997805);
    s8 += _mulInt64Int(s16, 136657);
    s9 -= _mulInt64Int(s16, 683901);

    s3 += _mulInt64Int(s15, 666643);
    s4 += _mulInt64Int(s15, 470296);
    s5 += _mulInt64Int(s15, 654183);
    s6 -= _mulInt64Int(s15, 997805);
    s7 += _mulInt64Int(s15, 136657);
    s8 -= _mulInt64Int(s15, 683901);

    s2 += _mulInt64Int(s14, 666643);
    s3 += _mulInt64Int(s14, 470296);
    s4 += _mulInt64Int(s14, 654183);
    s5 -= _mulInt64Int(s14, 997805);
    s6 += _mulInt64Int(s14, 136657);
    s7 -= _mulInt64Int(s14, 683901);

    s1 += _mulInt64Int(s13, 666643);
    s2 += _mulInt64Int(s13, 470296);
    s3 += _mulInt64Int(s13, 654183);
    s4 -= _mulInt64Int(s13, 997805);
    s5 += _mulInt64Int(s13, 136657);
    s6 -= _mulInt64Int(s13, 683901);

    s0 += _mulInt64Int(s12, 666643);
    s1 += _mulInt64Int(s12, 470296);
    s2 += _mulInt64Int(s12, 654183);
    s3 -= _mulInt64Int(s12, 997805);
    s4 += _mulInt64Int(s12, 136657);
    s5 -= _mulInt64Int(s12, 683901);
    s12 = Int64.zero;

    carry0 = (s0 + (Int64.one << 20)) >> 21;
    s1 += carry0;
    s0 -= carry0 << 21;
    carry2 = (s2 + (Int64.one << 20)) >> 21;
    s3 += carry2;
    s2 -= carry2 << 21;
    carry4 = (s4 + (Int64.one << 20)) >> 21;
    s5 += carry4;
    s4 -= carry4 << 21;
    carry6 = (s6 + (Int64.one << 20)) >> 21;
    s7 += carry6;
    s6 -= carry6 << 21;
    carry8 = (s8 + (Int64.one << 20)) >> 21;
    s9 += carry8;
    s8 -= carry8 << 21;
    carry10 = (s10 + (Int64.one << 20)) >> 21;
    s11 += carry10;
    s10 -= carry10 << 21;

    carry1 = (s1 + (Int64.one << 20)) >> 21;
    s2 += carry1;
    s1 -= carry1 << 21;
    carry3 = (s3 + (Int64.one << 20)) >> 21;
    s4 += carry3;
    s3 -= carry3 << 21;
    carry5 = (s5 + (Int64.one << 20)) >> 21;
    s6 += carry5;
    s5 -= carry5 << 21;
    carry7 = (s7 + (Int64.one << 20)) >> 21;
    s8 += carry7;
    s7 -= carry7 << 21;
    carry9 = (s9 + (Int64.one << 20)) >> 21;
    s10 += carry9;
    s9 -= carry9 << 21;
    carry11 = (s11 + (Int64.one << 20)) >> 21;
    s12 += carry11;
    s11 -= carry11 << 21;

    s0 += _mulInt64Int(s12, 666643);
    s1 += _mulInt64Int(s12, 470296);
    s2 += _mulInt64Int(s12, 654183);
    s3 -= _mulInt64Int(s12, 997805);
    s4 += _mulInt64Int(s12, 136657);
    s5 -= _mulInt64Int(s12, 683901);
    s12 = Int64.zero;

    carry0 = s0 >> 21;
    s1 += carry0;
    s0 -= carry0 << 21;
    carry1 = s1 >> 21;
    s2 += carry1;
    s1 -= carry1 << 21;
    carry2 = s2 >> 21;
    s3 += carry2;
    s2 -= carry2 << 21;
    carry3 = s3 >> 21;
    s4 += carry3;
    s3 -= carry3 << 21;
    carry4 = s4 >> 21;
    s5 += carry4;
    s4 -= carry4 << 21;
    carry5 = s5 >> 21;
    s6 += carry5;
    s5 -= carry5 << 21;
    carry6 = s6 >> 21;
    s7 += carry6;
    s6 -= carry6 << 21;
    carry7 = s7 >> 21;
    s8 += carry7;
    s7 -= carry7 << 21;
    carry8 = s8 >> 21;
    s9 += carry8;
    s8 -= carry8 << 21;
    carry9 = s9 >> 21;
    s10 += carry9;
    s9 -= carry9 << 21;
    carry10 = s10 >> 21;
    s11 += carry10;
    s10 -= carry10 << 21;
    carry11 = s11 >> 21;
    s12 += carry11;
    s11 -= carry11 << 21;

    s0 += _mulInt64Int(s12, 666643);
    s1 += _mulInt64Int(s12, 470296);
    s2 += _mulInt64Int(s12, 654183);
    s3 -= _mulInt64Int(s12, 997805);
    s4 += _mulInt64Int(s12, 136657);
    s5 -= _mulInt64Int(s12, 683901);

    carry0 = s0 >> 21;
    s1 += carry0;
    s0 -= carry0 << 21;
    carry1 = s1 >> 21;
    s2 += carry1;
    s1 -= carry1 << 21;
    carry2 = s2 >> 21;
    s3 += carry2;
    s2 -= carry2 << 21;
    carry3 = s3 >> 21;
    s4 += carry3;
    s3 -= carry3 << 21;
    carry4 = s4 >> 21;
    s5 += carry4;
    s4 -= carry4 << 21;
    carry5 = s5 >> 21;
    s6 += carry5;
    s5 -= carry5 << 21;
    carry6 = s6 >> 21;
    s7 += carry6;
    s6 -= carry6 << 21;
    carry7 = s7 >> 21;
    s8 += carry7;
    s7 -= carry7 << 21;
    carry8 = s8 >> 21;
    s9 += carry8;
    s8 -= carry8 << 21;
    carry9 = s9 >> 21;
    s10 += carry9;
    s9 -= carry9 << 21;
    carry10 = s10 >> 21;
    s11 += carry10;
    s10 -= carry10 << 21;
    final List<Int64> sBig = List<Int64>.filled(32, Int64.zero);

    sBig[0] = s0 >> 0;
    sBig[1] = s0 >> 8;
    sBig[2] = (s0 >> 16) | (s1 << 5);
    sBig[3] = s1 >> 3;
    sBig[4] = s1 >> 11;
    sBig[5] = (s1 >> 19) | (s2 << 2);
    sBig[6] = s2 >> 6;
    sBig[7] = (s2 >> 14) | (s3 << 7);
    sBig[8] = s3 >> 1;
    sBig[9] = s3 >> 9;
    sBig[10] = (s3 >> 17) | (s4 << 4);
    sBig[11] = s4 >> 4;
    sBig[12] = s4 >> 12;
    sBig[13] = (s4 >> 20) | (s5 << 1);
    sBig[14] = s5 >> 7;
    sBig[15] = (s5 >> 15) | (s6 << 6);
    sBig[16] = s6 >> 2;
    sBig[17] = s6 >> 10;
    sBig[18] = (s6 >> 18) | (s7 << 3);
    sBig[19] = s7 >> 5;
    sBig[20] = s7 >> 13;
    sBig[21] = s8 >> 0;
    sBig[22] = s8 >> 8;
    sBig[23] = (s8 >> 16) | (s9 << 5);
    sBig[24] = s9 >> 3;
    sBig[25] = s9 >> 11;
    sBig[26] = (s9 >> 19) | (s10 << 2);
    sBig[27] = s10 >> 6;
    sBig[28] = (s10 >> 14) | (s11 << 7);
    sBig[29] = s11 >> 1;
    sBig[30] = s11 >> 9;
    sBig[31] = s11 >> 17;
    for (int i = 0; i < sBig.length; i++) {
      r[i] = sBig[i].toUint8();
    }
  }

  static void geP3Tobytes(List<int> s, GroupElementP3 h) {
    final FieldElement recip = FieldElement();
    final FieldElement x = FieldElement();
    final FieldElement y = FieldElement();

    feInvert(recip, h.z);
    feMul(x, h.x, recip);
    feMul(y, h.y, recip);
    feTobytes(s, y);
    s[31] ^= feIsnegative(x) << 7;
  }

  static void geAdd(GroupElementP1P1 r, GroupElementP3 p, GroupElementCached q) {
    final FieldElement t0 = FieldElement();
    feAdd(r.x, p.y, p.x);
    feSub(r.y, p.y, p.x);
    feMul(r.z, r.x, q.yPlusX);
    feMul(r.y, r.y, q.yMinusX);
    feMul(r.t, q.t2d, p.t);
    feMul(r.x, p.z, q.z);
    feAdd(t0, r.x, r.x);
    feSub(r.x, r.z, r.y);
    feAdd(r.y, r.z, r.y);
    feAdd(r.z, t0, r.t);
    feSub(r.t, t0, r.t);
  }

  static void geCached0(GroupElementCached r) {
    fe1(r.yPlusX);
    fe1(r.yMinusX);
    fe1(r.z);
    fe0(r.t2d);
  }

  static int negative(int b) {
    BigInt x = b.toBigInt;
    x >>= 63;
    return (x & BigInt.one).toInt();
  }

  static int equal(int b, int c) {
    final int ub = b & 0xFF;
    final int uc = c & 0xFF;
    final int x = ub ^ uc;
    BigInt y = BigInt.from(x) & BigInt.from(0xFFFFFFFF);
    y = y - BigInt.one;
    y = y >> 31;
    return (y & BigInt.one).toInt();
  }

  static void geP2Zero(GroupElementP2 h) {
    fe0(h.x);
    fe1(h.y);
    fe1(h.z);
  }

  static void geP3Zero(GroupElementP3 h) {
    fe0(h.x);
    fe1(h.y);
    fe1(h.z);
    fe0(h.t);
  }

  static void geMadd(GroupElementP1P1 r, GroupElementP3 p, GroupElementPrecomp q) {
    final FieldElement t0 = FieldElement();
    feAdd(r.x, p.y, p.x);
    feSub(r.y, p.y, p.x);
    feMul(r.z, r.x, q.yplusx);
    feMul(r.y, r.y, q.yminusx);
    feMul(r.t, q.xy2d, p.t);
    feAdd(t0, p.z, p.z);
    feSub(r.x, r.z, r.y);
    feAdd(r.y, r.z, r.y);
    feAdd(r.z, t0, r.t);
    feSub(r.t, t0, r.t);
  }

  static void geP3Dbl(GroupElementP1P1 r, GroupElementP3 p) {
    final GroupElementP2 q = GroupElementP2();
    geP3ToP2(q, p);
    geP2Dbl(r, q);
  }

  static void geP3ToP2(GroupElementP2 r, GroupElementP3 p) {
    feCopy(r.x, p.x);
    feCopy(r.y, p.y);
    feCopy(r.z, p.z);
  }

  static void gePrecompCmov(GroupElementPrecomp t, GroupElementPrecomp u, int b) {
    feCmov(t.yplusx, u.yplusx, b);
    feCmov(t.yminusx, u.yminusx, b);
    feCmov(t.xy2d, u.xy2d, b);
  }

  static void gePrecompZero(GroupElementPrecomp h) {
    fe1(h.yplusx);
    fe1(h.yminusx);
    fe0(h.xy2d);
  }

  static void select(GroupElementPrecomp t, int pos, int b) {
    final GroupElementPrecomp minust = GroupElementPrecomp();
    final int bnegative = negative(b);
    final int babs = b - (((-bnegative) & b) << 1);
    gePrecompZero(t);
    gePrecompCmov(t, CryptoOpsConst.geBase[pos][0], equal(babs, 1));

    gePrecompCmov(t, CryptoOpsConst.geBase[pos][1], equal(babs, 2));

    gePrecompCmov(t, CryptoOpsConst.geBase[pos][2], equal(babs, 3));

    gePrecompCmov(t, CryptoOpsConst.geBase[pos][3], equal(babs, 4));

    gePrecompCmov(t, CryptoOpsConst.geBase[pos][4], equal(babs, 5));

    gePrecompCmov(t, CryptoOpsConst.geBase[pos][5], equal(babs, 6));

    gePrecompCmov(t, CryptoOpsConst.geBase[pos][6], equal(babs, 7));
    gePrecompCmov(t, CryptoOpsConst.geBase[pos][7], equal(babs, 8));

    feCopy(minust.yplusx, t.yminusx);
    feCopy(minust.yminusx, t.yplusx);
    feNeg(minust.xy2d, t.xy2d);
    gePrecompCmov(t, minust, bnegative);
  }

  static void geScalarMultBase(GroupElementP3 h, List<int> a) {
    a.asMin32("geScalarMultBase");
    final List<int> e = List<int>.filled(64, 0);
    int carry;
    final GroupElementP1P1 r = GroupElementP1P1();
    final GroupElementP2 s = GroupElementP2();
    final GroupElementPrecomp t = GroupElementPrecomp();
    int i;

    for (i = 0; i < 32; ++i) {
      e[2 * i + 0] = (a[i] >> 0) & 15;
      e[2 * i + 1] = (a[i] >> 4) & 15;
    }
    /* each e[i] is between 0 and 15 */
    /* e[63] is between 0 and 7 */

    carry = 0;
    for (i = 0; i < 63; ++i) {
      e[i] += carry;
      carry = e[i] + 8;
      carry >>= 4;
      e[i] -= carry << 4;
    }
    e[63] += carry;
    geP3Zero(h);
    for (i = 1; i < 64; i += 2) {
      select(t, i ~/ 2, e[i]);
      geMadd(r, h, t);
      geP1P1ToP3(h, r);
    }

    geP3Dbl(r, h);
    geP1P1ToP2(s, r);
    geP2Dbl(r, s);
    geP1P1ToP2(s, r);
    geP2Dbl(r, s);
    geP1P1ToP2(s, r);
    geP2Dbl(r, s);
    geP1P1ToP3(h, r);
    for (i = 0; i < 64; i += 2) {
      select(t, i ~/ 2, e[i]);
      geMadd(r, h, t);
      geP1P1ToP3(h, r);
    }
  }

  static List<int> scalarmultBase_(List<int> a) {
    final List<int> ag = List<int>.filled(32, 0);
    final GroupElementP3 point = GroupElementP3();
    CryptoOps.scReduce32Copy(ag, a);
    CryptoOps.geScalarMultBase(point, ag);
    CryptoOps.geP3Tobytes(ag, point);
    return ag;
  }

  static void geScalarMult(GroupElementP2 r, List<int> a, GroupElementP3 gA) {
    a.asMin32("geScalarMultBase");
    final List<int> e = List<int>.filled(64, 0);
    int carry, carry2, i;
    final List<GroupElementCached> aI =
        GroupElementCached.dsmp; /* 1 * A, 2 * A, ..., 8 * A */
    final GroupElementP1P1 t = GroupElementP1P1();
    final GroupElementP3 u = GroupElementP3();

    carry = 0; /* 0..1 */
    for (i = 0; i < 31; i++) {
      carry += a[i]; /* 0..256 */
      carry2 = (carry + 8) >> 4; /* 0..16 */
      e[2 * i] = carry - (carry2 << 4); /* -8..7 */
      carry = (carry2 + 8) >> 4; /* 0..1 */
      e[2 * i + 1] = carry2 - (carry << 4); /* -8..7 */
    }
    carry += a[31]; /* 0..128 */
    carry2 = (carry + 8) >> 4; /* 0..8 */
    e[62] = carry - (carry2 << 4); /* -8..7 */
    e[63] = carry2; /* 0..8 */

    geP3ToCached(aI[0], gA);
    for (i = 0; i < 7; i++) {
      geAdd(t, gA, aI[i]);
      geP1P1ToP3(u, t);
      geP3ToCached(aI[i + 1], u);
    }

    geP2Zero(r);
    for (i = 63; i >= 0; i--) {
      final int b = e[i];
      final int bnegative = negative(b);
      final int babs = b - (((-bnegative) & b) << 1);
      final GroupElementCached cur = GroupElementCached(),
          minuscur = GroupElementCached();
      geP2Dbl(t, r);
      geP1P1ToP2(r, t);
      geP2Dbl(t, r);
      geP1P1ToP2(r, t);
      geP2Dbl(t, r);
      geP1P1ToP2(r, t);
      geP2Dbl(t, r);
      geP1P1ToP3(u, t);
      geCached0(cur);
      geCachedCmov(cur, aI[0], equal(babs, 1));
      geCachedCmov(cur, aI[1], equal(babs, 2));
      geCachedCmov(cur, aI[2], equal(babs, 3));
      geCachedCmov(cur, aI[3], equal(babs, 4));
      geCachedCmov(cur, aI[4], equal(babs, 5));
      geCachedCmov(cur, aI[5], equal(babs, 6));
      geCachedCmov(cur, aI[6], equal(babs, 7));
      geCachedCmov(cur, aI[7], equal(babs, 8));
      feCopy(minuscur.yPlusX, cur.yMinusX);
      feCopy(minuscur.yMinusX, cur.yPlusX);
      feCopy(minuscur.z, cur.z);
      feNeg(minuscur.t2d, cur.t2d);
      geCachedCmov(cur, minuscur, bnegative);
      geAdd(t, u, cur);
      geP1P1ToP2(r, t);
    }
  }

  static void _setSign({
    required GroupElementP2 r,
    required int sign,
    required FieldElement z,
    required FieldElement w,
  }) {
    if (feIsnegative(r.x) != sign) {
      feNeg(r.x, r.x);
    }
    feAdd(r.z, z, w);
    feSub(r.y, z, w);
    feMul(r.x, r.x, r.z);
  }

  static int feIsnegative(FieldElement f) {
    final List<int> s = List<int>.filled(32, 0);
    feTobytes(s, f);
    return s[0] & 1;
  }

  static void feNeg(FieldElement h, FieldElement f) {
    final Int32 f0 = f.h[0];
    final Int32 f1 = f.h[1];
    final Int32 f2 = f.h[2];
    final Int32 f3 = f.h[3];
    final Int32 f4 = f.h[4];
    final Int32 f5 = f.h[5];
    final Int32 f6 = f.h[6];
    final Int32 f7 = f.h[7];
    final Int32 f8 = f.h[8];
    final Int32 f9 = f.h[9];
    final Int32 h0 = -f0;
    final Int32 h1 = -f1;
    final Int32 h2 = -f2;
    final Int32 h3 = -f3;
    final Int32 h4 = -f4;
    final Int32 h5 = -f5;
    final Int32 h6 = -f6;
    final Int32 h7 = -f7;
    final Int32 h8 = -f8;
    final Int32 h9 = -f9;
    h.h[0] = h0;
    h.h[1] = h1;
    h.h[2] = h2;
    h.h[3] = h3;
    h.h[4] = h4;
    h.h[5] = h5;
    h.h[6] = h6;
    h.h[7] = h7;
    h.h[8] = h8;
    h.h[9] = h9;
  }

  static void scMulSub(List<int> s, List<int> a, List<int> b, List<int> c) {
    s.asMin32("scMulSub");
    a.asMin32("scMulSub");
    b.asMin32("scMulSub");
    c.asMin32("scMulSub");
    final Int64 a0 = _andU64(_b2097151, _load3(a, 0));
    final Int64 a1 = _andU64(_b2097151, (_load4(a, 2) >> 5));
    final Int64 a2 = _andU64(_b2097151, (_load3(a, 5) >> 2));
    final Int64 a3 = _andU64(_b2097151, (_load4(a, 7) >> 7));
    final Int64 a4 = _andU64(_b2097151, (_load4(a, 10) >> 4));
    final Int64 a5 = _andU64(_b2097151, (_load3(a, 13) >> 1));
    final Int64 a6 = _andU64(_b2097151, (_load4(a, 15) >> 6));
    final Int64 a7 = _andU64(_b2097151, (_load3(a, 18) >> 3));
    final Int64 a8 = _andU64(_b2097151, _load3(a, 21));
    final Int64 a9 = _andU64(_b2097151, (_load4(a, 23) >> 5));
    final Int64 a10 = _andU64(_b2097151, (_load3(a, 26) >> 2));
    final Int64 a11 = (_load4(a, 28) >> 7).toInt64();
    final Int64 b0 = _andU64(_b2097151, _load3(b, 0));
    final Int64 b1 = _andU64(_b2097151, (_load4(b, 2) >> 5));
    final Int64 b2 = _andU64(_b2097151, (_load3(b, 5) >> 2));
    final Int64 b3 = _andU64(_b2097151, (_load4(b, 7) >> 7));
    final Int64 b4 = _andU64(_b2097151, (_load4(b, 10) >> 4));
    final Int64 b5 = _andU64(_b2097151, (_load3(b, 13) >> 1));
    final Int64 b6 = _andU64(_b2097151, (_load4(b, 15) >> 6));
    final Int64 b7 = _andU64(_b2097151, (_load3(b, 18) >> 3));
    final Int64 b8 = _andU64(_b2097151, _load3(b, 21));
    final Int64 b9 = _andU64(_b2097151, (_load4(b, 23) >> 5));
    final Int64 b10 = _andU64(_b2097151, (_load3(b, 26) >> 2));
    final Int64 b11 = (_load4(b, 28) >> 7).toInt64();
    final Int64 c0 = _andU64(_b2097151, _load3(c, 0));
    final Int64 c1 = _andU64(_b2097151, (_load4(c, 2) >> 5));
    final Int64 c2 = _andU64(_b2097151, (_load3(c, 5) >> 2));
    final Int64 c3 = _andU64(_b2097151, (_load4(c, 7) >> 7));
    final Int64 c4 = _andU64(_b2097151, (_load4(c, 10) >> 4));
    final Int64 c5 = _andU64(_b2097151, (_load3(c, 13) >> 1));
    final Int64 c6 = _andU64(_b2097151, (_load4(c, 15) >> 6));
    final Int64 c7 = _andU64(_b2097151, (_load3(c, 18) >> 3));
    final Int64 c8 = _andU64(_b2097151, _load3(c, 21));
    final Int64 c9 = _andU64(_b2097151, (_load4(c, 23) >> 5));
    final Int64 c10 = _andU64(_b2097151, (_load3(c, 26) >> 2));
    final Int64 c11 = (_load4(c, 28) >> 7).toInt64();
    Int64 s0;
    Int64 s1;
    Int64 s2;
    Int64 s3;
    Int64 s4;
    Int64 s5;
    Int64 s6;
    Int64 s7;
    Int64 s8;
    Int64 s9;
    Int64 s10;
    Int64 s11;
    Int64 s12;
    Int64 s13;
    Int64 s14;
    Int64 s15;
    Int64 s16;
    Int64 s17;
    Int64 s18;
    Int64 s19;
    Int64 s20;
    Int64 s21;
    Int64 s22;
    Int64 s23;
    Int64 carry0;
    Int64 carry1;
    Int64 carry2;
    Int64 carry3;
    Int64 carry4;
    Int64 carry5;
    Int64 carry6;
    Int64 carry7;
    Int64 carry8;
    Int64 carry9;
    Int64 carry10;
    Int64 carry11;
    Int64 carry12;
    Int64 carry13;
    Int64 carry14;
    Int64 carry15;
    Int64 carry16;
    Int64 carry17;
    Int64 carry18;
    Int64 carry19;
    Int64 carry20;
    Int64 carry21;
    Int64 carry22;

    s0 = c0 - a0 * b0;
    s1 = c1 - (a0 * b1 + a1 * b0);
    s2 = c2 - (a0 * b2 + a1 * b1 + a2 * b0);
    s3 = c3 - (a0 * b3 + a1 * b2 + a2 * b1 + a3 * b0);
    s4 = c4 - (a0 * b4 + a1 * b3 + a2 * b2 + a3 * b1 + a4 * b0);
    s5 = c5 - (a0 * b5 + a1 * b4 + a2 * b3 + a3 * b2 + a4 * b1 + a5 * b0);
    s6 = c6 - (a0 * b6 + a1 * b5 + a2 * b4 + a3 * b3 + a4 * b2 + a5 * b1 + a6 * b0);
    s7 =
        c7 -
        (a0 * b7 + a1 * b6 + a2 * b5 + a3 * b4 + a4 * b3 + a5 * b2 + a6 * b1 + a7 * b0);
    s8 =
        c8 -
        (a0 * b8 +
            a1 * b7 +
            a2 * b6 +
            a3 * b5 +
            a4 * b4 +
            a5 * b3 +
            a6 * b2 +
            a7 * b1 +
            a8 * b0);
    s9 =
        c9 -
        (a0 * b9 +
            a1 * b8 +
            a2 * b7 +
            a3 * b6 +
            a4 * b5 +
            a5 * b4 +
            a6 * b3 +
            a7 * b2 +
            a8 * b1 +
            a9 * b0);
    s10 =
        c10 -
        (a0 * b10 +
            a1 * b9 +
            a2 * b8 +
            a3 * b7 +
            a4 * b6 +
            a5 * b5 +
            a6 * b4 +
            a7 * b3 +
            a8 * b2 +
            a9 * b1 +
            a10 * b0);
    s11 =
        c11 -
        (a0 * b11 +
            a1 * b10 +
            a2 * b9 +
            a3 * b8 +
            a4 * b7 +
            a5 * b6 +
            a6 * b5 +
            a7 * b4 +
            a8 * b3 +
            a9 * b2 +
            a10 * b1 +
            a11 * b0);
    s12 =
        -(a1 * b11 +
            a2 * b10 +
            a3 * b9 +
            a4 * b8 +
            a5 * b7 +
            a6 * b6 +
            a7 * b5 +
            a8 * b4 +
            a9 * b3 +
            a10 * b2 +
            a11 * b1);
    s13 =
        -(a2 * b11 +
            a3 * b10 +
            a4 * b9 +
            a5 * b8 +
            a6 * b7 +
            a7 * b6 +
            a8 * b5 +
            a9 * b4 +
            a10 * b3 +
            a11 * b2);
    s14 =
        -(a3 * b11 +
            a4 * b10 +
            a5 * b9 +
            a6 * b8 +
            a7 * b7 +
            a8 * b6 +
            a9 * b5 +
            a10 * b4 +
            a11 * b3);
    s15 =
        -(a4 * b11 +
            a5 * b10 +
            a6 * b9 +
            a7 * b8 +
            a8 * b7 +
            a9 * b6 +
            a10 * b5 +
            a11 * b4);
    s16 = -(a5 * b11 + a6 * b10 + a7 * b9 + a8 * b8 + a9 * b7 + a10 * b6 + a11 * b5);
    s17 = -(a6 * b11 + a7 * b10 + a8 * b9 + a9 * b8 + a10 * b7 + a11 * b6);
    s18 = -(a7 * b11 + a8 * b10 + a9 * b9 + a10 * b8 + a11 * b7);
    s19 = -(a8 * b11 + a9 * b10 + a10 * b9 + a11 * b8);
    s20 = -(a9 * b11 + a10 * b10 + a11 * b9);
    s21 = -(a10 * b11 + a11 * b10);
    s22 = -a11 * b11;
    s23 = Int64.zero;

    carry0 = (s0 + _bitMaskFor20) >> 21;
    s1 += carry0;
    s0 -= carry0 << 21;
    carry2 = (s2 + _bitMaskFor20) >> 21;
    s3 += carry2;
    s2 -= carry2 << 21;
    carry4 = (s4 + _bitMaskFor20) >> 21;
    s5 += carry4;
    s4 -= carry4 << 21;
    carry6 = (s6 + _bitMaskFor20) >> 21;
    s7 += carry6;
    s6 -= carry6 << 21;
    carry8 = (s8 + _bitMaskFor20) >> 21;
    s9 += carry8;
    s8 -= carry8 << 21;
    carry10 = (s10 + _bitMaskFor20) >> 21;
    s11 += carry10;
    s10 -= carry10 << 21;
    carry12 = (s12 + _bitMaskFor20) >> 21;
    s13 += carry12;
    s12 -= carry12 << 21;
    carry14 = (s14 + _bitMaskFor20) >> 21;
    s15 += carry14;
    s14 -= carry14 << 21;
    carry16 = (s16 + _bitMaskFor20) >> 21;
    s17 += carry16;
    s16 -= carry16 << 21;
    carry18 = (s18 + _bitMaskFor20) >> 21;
    s19 += carry18;
    s18 -= carry18 << 21;
    carry20 = (s20 + _bitMaskFor20) >> 21;
    s21 += carry20;
    s20 -= carry20 << 21;
    carry22 = (s22 + _bitMaskFor20) >> 21;
    s23 += carry22;
    s22 -= carry22 << 21;

    carry1 = (s1 + _bitMaskFor20) >> 21;
    s2 += carry1;
    s1 -= carry1 << 21;
    carry3 = (s3 + _bitMaskFor20) >> 21;
    s4 += carry3;
    s3 -= carry3 << 21;
    carry5 = (s5 + _bitMaskFor20) >> 21;
    s6 += carry5;
    s5 -= carry5 << 21;
    carry7 = (s7 + _bitMaskFor20) >> 21;
    s8 += carry7;
    s7 -= carry7 << 21;
    carry9 = (s9 + _bitMaskFor20) >> 21;
    s10 += carry9;
    s9 -= carry9 << 21;
    carry11 = (s11 + _bitMaskFor20) >> 21;
    s12 += carry11;
    s11 -= carry11 << 21;
    carry13 = (s13 + _bitMaskFor20) >> 21;
    s14 += carry13;
    s13 -= carry13 << 21;
    carry15 = (s15 + _bitMaskFor20) >> 21;
    s16 += carry15;
    s15 -= carry15 << 21;
    carry17 = (s17 + _bitMaskFor20) >> 21;
    s18 += carry17;
    s17 -= carry17 << 21;
    carry19 = (s19 + _bitMaskFor20) >> 21;
    s20 += carry19;
    s19 -= carry19 << 21;
    carry21 = (s21 + _bitMaskFor20) >> 21;
    s22 += carry21;
    s21 -= carry21 << 21;

    s11 += _mulInt64Int(s23, 666643);
    s12 += _mulInt64Int(s23, 470296);
    s13 += _mulInt64Int(s23, 654183);
    s14 -= _mulInt64Int(s23, 997805);
    s15 += _mulInt64Int(s23, 136657);
    s16 -= _mulInt64Int(s23, 683901);

    s10 += _mulInt64Int(s22, 666643);
    s11 += _mulInt64Int(s22, 470296);
    s12 += _mulInt64Int(s22, 654183);
    s13 -= _mulInt64Int(s22, 997805);
    s14 += _mulInt64Int(s22, 136657);
    s15 -= _mulInt64Int(s22, 683901);

    s9 += _mulInt64Int(s21, 666643);
    s10 += _mulInt64Int(s21, 470296);
    s11 += _mulInt64Int(s21, 654183);
    s12 -= _mulInt64Int(s21, 997805);
    s13 += _mulInt64Int(s21, 136657);
    s14 -= _mulInt64Int(s21, 683901);

    s8 += _mulInt64Int(s20, 666643);
    s9 += _mulInt64Int(s20, 470296);
    s10 += _mulInt64Int(s20, 654183);
    s11 -= _mulInt64Int(s20, 997805);
    s12 += _mulInt64Int(s20, 136657);
    s13 -= _mulInt64Int(s20, 683901);

    s7 += _mulInt64Int(s19, 666643);
    s8 += _mulInt64Int(s19, 470296);
    s9 += _mulInt64Int(s19, 654183);
    s10 -= _mulInt64Int(s19, 997805);
    s11 += _mulInt64Int(s19, 136657);
    s12 -= _mulInt64Int(s19, 683901);

    s6 += _mulInt64Int(s18, 666643);
    s7 += _mulInt64Int(s18, 470296);
    s8 += _mulInt64Int(s18, 654183);
    s9 -= _mulInt64Int(s18, 997805);
    s10 += _mulInt64Int(s18, 136657);
    s11 -= _mulInt64Int(s18, 683901);

    carry6 = (s6 + _bitMaskFor20) >> 21;
    s7 += carry6;
    s6 -= carry6 << 21;
    carry8 = (s8 + _bitMaskFor20) >> 21;
    s9 += carry8;
    s8 -= carry8 << 21;
    carry10 = (s10 + _bitMaskFor20) >> 21;
    s11 += carry10;
    s10 -= carry10 << 21;
    carry12 = (s12 + _bitMaskFor20) >> 21;
    s13 += carry12;
    s12 -= carry12 << 21;
    carry14 = (s14 + _bitMaskFor20) >> 21;
    s15 += carry14;
    s14 -= carry14 << 21;
    carry16 = (s16 + _bitMaskFor20) >> 21;
    s17 += carry16;
    s16 -= carry16 << 21;

    carry7 = (s7 + _bitMaskFor20) >> 21;
    s8 += carry7;
    s7 -= carry7 << 21;
    carry9 = (s9 + _bitMaskFor20) >> 21;
    s10 += carry9;
    s9 -= carry9 << 21;
    carry11 = (s11 + _bitMaskFor20) >> 21;
    s12 += carry11;
    s11 -= carry11 << 21;
    carry13 = (s13 + _bitMaskFor20) >> 21;
    s14 += carry13;
    s13 -= carry13 << 21;
    carry15 = (s15 + _bitMaskFor20) >> 21;
    s16 += carry15;
    s15 -= carry15 << 21;

    s5 += _mulInt64Int(s17, 666643);
    s6 += _mulInt64Int(s17, 470296);
    s7 += _mulInt64Int(s17, 654183);
    s8 -= _mulInt64Int(s17, 997805);
    s9 += _mulInt64Int(s17, 136657);
    s10 -= _mulInt64Int(s17, 683901);

    s4 += _mulInt64Int(s16, 666643);
    s5 += _mulInt64Int(s16, 470296);
    s6 += _mulInt64Int(s16, 654183);
    s7 -= _mulInt64Int(s16, 997805);
    s8 += _mulInt64Int(s16, 136657);
    s9 -= _mulInt64Int(s16, 683901);

    s3 += _mulInt64Int(s15, 666643);
    s4 += _mulInt64Int(s15, 470296);
    s5 += _mulInt64Int(s15, 654183);
    s6 -= _mulInt64Int(s15, 997805);
    s7 += _mulInt64Int(s15, 136657);
    s8 -= _mulInt64Int(s15, 683901);

    s2 += _mulInt64Int(s14, 666643);
    s3 += _mulInt64Int(s14, 470296);
    s4 += _mulInt64Int(s14, 654183);
    s5 -= _mulInt64Int(s14, 997805);
    s6 += _mulInt64Int(s14, 136657);
    s7 -= _mulInt64Int(s14, 683901);

    s1 += _mulInt64Int(s13, 666643);
    s2 += _mulInt64Int(s13, 470296);
    s3 += _mulInt64Int(s13, 654183);
    s4 -= _mulInt64Int(s13, 997805);
    s5 += _mulInt64Int(s13, 136657);
    s6 -= _mulInt64Int(s13, 683901);

    s0 += _mulInt64Int(s12, 666643);
    s1 += _mulInt64Int(s12, 470296);
    s2 += _mulInt64Int(s12, 654183);
    s3 -= _mulInt64Int(s12, 997805);
    s4 += _mulInt64Int(s12, 136657);
    s5 -= _mulInt64Int(s12, 683901);
    s12 = Int64.zero;

    carry0 = (s0 + _bitMaskFor20) >> 21;
    s1 += carry0;
    s0 -= carry0 << 21;
    carry2 = (s2 + _bitMaskFor20) >> 21;
    s3 += carry2;
    s2 -= carry2 << 21;
    carry4 = (s4 + _bitMaskFor20) >> 21;
    s5 += carry4;
    s4 -= carry4 << 21;
    carry6 = (s6 + _bitMaskFor20) >> 21;
    s7 += carry6;
    s6 -= carry6 << 21;
    carry8 = (s8 + _bitMaskFor20) >> 21;
    s9 += carry8;
    s8 -= carry8 << 21;
    carry10 = (s10 + _bitMaskFor20) >> 21;
    s11 += carry10;
    s10 -= carry10 << 21;

    carry1 = (s1 + _bitMaskFor20) >> 21;
    s2 += carry1;
    s1 -= carry1 << 21;
    carry3 = (s3 + _bitMaskFor20) >> 21;
    s4 += carry3;
    s3 -= carry3 << 21;
    carry5 = (s5 + _bitMaskFor20) >> 21;
    s6 += carry5;
    s5 -= carry5 << 21;
    carry7 = (s7 + _bitMaskFor20) >> 21;
    s8 += carry7;
    s7 -= carry7 << 21;
    carry9 = (s9 + _bitMaskFor20) >> 21;
    s10 += carry9;
    s9 -= carry9 << 21;
    carry11 = (s11 + _bitMaskFor20) >> 21;
    s12 += carry11;
    s11 -= carry11 << 21;

    s0 += _mulInt64Int(s12, 666643);
    s1 += _mulInt64Int(s12, 470296);
    s2 += _mulInt64Int(s12, 654183);
    s3 -= _mulInt64Int(s12, 997805);
    s4 += _mulInt64Int(s12, 136657);
    s5 -= _mulInt64Int(s12, 683901);
    s12 = Int64.zero;

    carry0 = s0 >> 21;
    s1 += carry0;
    s0 -= carry0 << 21;
    carry1 = s1 >> 21;
    s2 += carry1;
    s1 -= carry1 << 21;
    carry2 = s2 >> 21;
    s3 += carry2;
    s2 -= carry2 << 21;
    carry3 = s3 >> 21;
    s4 += carry3;
    s3 -= carry3 << 21;
    carry4 = s4 >> 21;
    s5 += carry4;
    s4 -= carry4 << 21;
    carry5 = s5 >> 21;
    s6 += carry5;
    s5 -= carry5 << 21;
    carry6 = s6 >> 21;
    s7 += carry6;
    s6 -= carry6 << 21;
    carry7 = s7 >> 21;
    s8 += carry7;
    s7 -= carry7 << 21;
    carry8 = s8 >> 21;
    s9 += carry8;
    s8 -= carry8 << 21;
    carry9 = s9 >> 21;
    s10 += carry9;
    s9 -= carry9 << 21;
    carry10 = s10 >> 21;
    s11 += carry10;
    s10 -= carry10 << 21;
    carry11 = s11 >> 21;
    s12 += carry11;
    s11 -= carry11 << 21;

    s0 += _mulInt64Int(s12, 666643);
    s1 += _mulInt64Int(s12, 470296);
    s2 += _mulInt64Int(s12, 654183);
    s3 -= _mulInt64Int(s12, 997805);
    s4 += _mulInt64Int(s12, 136657);
    s5 -= _mulInt64Int(s12, 683901);

    carry0 = s0 >> 21;
    s1 += carry0;
    s0 -= carry0 << 21;
    carry1 = s1 >> 21;
    s2 += carry1;
    s1 -= carry1 << 21;
    carry2 = s2 >> 21;
    s3 += carry2;
    s2 -= carry2 << 21;
    carry3 = s3 >> 21;
    s4 += carry3;
    s3 -= carry3 << 21;
    carry4 = s4 >> 21;
    s5 += carry4;
    s4 -= carry4 << 21;
    carry5 = s5 >> 21;
    s6 += carry5;
    s5 -= carry5 << 21;
    carry6 = s6 >> 21;
    s7 += carry6;
    s6 -= carry6 << 21;
    carry7 = s7 >> 21;
    s8 += carry7;
    s7 -= carry7 << 21;
    carry8 = s8 >> 21;
    s9 += carry8;
    s8 -= carry8 << 21;
    carry9 = s9 >> 21;
    s10 += carry9;
    s9 -= carry9 << 21;
    carry10 = s10 >> 21;
    s11 += carry10;
    s10 -= carry10 << 21;
    final List<Int64> sBig = List<Int64>.filled(32, Int64.zero);
    sBig[0] = s0 >> 0;
    sBig[1] = s0 >> 8;
    sBig[2] = (s0 >> 16) | (s1 << 5);
    sBig[3] = s1 >> 3;
    sBig[4] = s1 >> 11;
    sBig[5] = (s1 >> 19) | (s2 << 2);
    sBig[6] = s2 >> 6;
    sBig[7] = (s2 >> 14) | (s3 << 7);
    sBig[8] = s3 >> 1;
    sBig[9] = s3 >> 9;
    sBig[10] = (s3 >> 17) | (s4 << 4);
    sBig[11] = s4 >> 4;
    sBig[12] = s4 >> 12;
    sBig[13] = (s4 >> 20) | (s5 << 1);
    sBig[14] = s5 >> 7;
    sBig[15] = (s5 >> 15) | (s6 << 6);
    sBig[16] = s6 >> 2;
    sBig[17] = s6 >> 10;
    sBig[18] = (s6 >> 18) | (s7 << 3);
    sBig[19] = s7 >> 5;
    sBig[20] = s7 >> 13;
    sBig[21] = s8 >> 0;
    sBig[22] = s8 >> 8;
    sBig[23] = (s8 >> 16) | (s9 << 5);
    sBig[24] = s9 >> 3;
    sBig[25] = s9 >> 11;
    sBig[26] = (s9 >> 19) | (s10 << 2);
    sBig[27] = s10 >> 6;
    sBig[28] = (s10 >> 14) | (s11 << 7);
    sBig[29] = s11 >> 1;
    sBig[30] = s11 >> 9;
    sBig[31] = s11 >> 17;
    for (int i = 0; i < sBig.length; i++) {
      s[i] = sBig[i].toUint8();
    }
  }

  static void scSub(List<int> s, List<int> a, List<int> b) {
    s.asMin32("scSub");
    a.asMin32("scSub");
    b.asMin32("scSub");
    final Int64 a0 = _andU64(_b2097151, _load3(a, 0));
    final Int64 a1 = _andU64(_b2097151, (_load4(a, 2) >> 5));
    final Int64 a2 = _andU64(_b2097151, (_load3(a, 5) >> 2));
    final Int64 a3 = _andU64(_b2097151, (_load4(a, 7) >> 7));
    final Int64 a4 = _andU64(_b2097151, (_load4(a, 10) >> 4));
    final Int64 a5 = _andU64(_b2097151, (_load3(a, 13) >> 1));
    final Int64 a6 = _andU64(_b2097151, (_load4(a, 15) >> 6));
    final Int64 a7 = _andU64(_b2097151, (_load3(a, 18) >> 3));
    final Int64 a8 = _andU64(_b2097151, _load3(a, 21));
    final Int64 a9 = _andU64(_b2097151, (_load4(a, 23) >> 5));
    final Int64 a10 = _andU64(_b2097151, (_load3(a, 26) >> 2));
    final Int64 a11 = (_load4(a, 28) >> 7).toInt64();
    final Int64 b0 = _andU64(_b2097151, _load3(b, 0));
    final Int64 b1 = _andU64(_b2097151, (_load4(b, 2) >> 5));
    final Int64 b2 = _andU64(_b2097151, (_load3(b, 5) >> 2));
    final Int64 b3 = _andU64(_b2097151, (_load4(b, 7) >> 7));
    final Int64 b4 = _andU64(_b2097151, (_load4(b, 10) >> 4));
    final Int64 b5 = _andU64(_b2097151, (_load3(b, 13) >> 1));
    final Int64 b6 = _andU64(_b2097151, (_load4(b, 15) >> 6));
    final Int64 b7 = _andU64(_b2097151, (_load3(b, 18) >> 3));
    final Int64 b8 = _andU64(_b2097151, _load3(b, 21));
    final Int64 b9 = _andU64(_b2097151, (_load4(b, 23) >> 5));
    final Int64 b10 = _andU64(_b2097151, (_load3(b, 26) >> 2));
    final Int64 b11 = (_load4(b, 28) >> 7).toInt64();
    Int64 s0 = a0 - b0;
    Int64 s1 = a1 - b1;
    Int64 s2 = a2 - b2;
    Int64 s3 = a3 - b3;
    Int64 s4 = a4 - b4;
    Int64 s5 = a5 - b5;
    Int64 s6 = a6 - b6;
    Int64 s7 = a7 - b7;
    Int64 s8 = a8 - b8;
    Int64 s9 = a9 - b9;
    Int64 s10 = a10 - b10;
    Int64 s11 = a11 - b11;
    Int64 s12 = Int64.zero;
    Int64 carry0;
    Int64 carry1;
    Int64 carry2;
    Int64 carry3;
    Int64 carry4;
    Int64 carry5;
    Int64 carry6;
    Int64 carry7;
    Int64 carry8;
    Int64 carry9;
    Int64 carry10;
    Int64 carry11;

    carry0 = (s0 + _bitMaskFor20) >> 21;
    s1 += carry0;
    s0 -= carry0 << 21;
    carry2 = (s2 + _bitMaskFor20) >> 21;
    s3 += carry2;
    s2 -= carry2 << 21;
    carry4 = (s4 + _bitMaskFor20) >> 21;
    s5 += carry4;
    s4 -= carry4 << 21;
    carry6 = (s6 + _bitMaskFor20) >> 21;
    s7 += carry6;
    s6 -= carry6 << 21;
    carry8 = (s8 + _bitMaskFor20) >> 21;
    s9 += carry8;
    s8 -= carry8 << 21;
    carry10 = (s10 + _bitMaskFor20) >> 21;
    s11 += carry10;
    s10 -= carry10 << 21;

    carry1 = (s1 + _bitMaskFor20) >> 21;
    s2 += carry1;
    s1 -= carry1 << 21;
    carry3 = (s3 + _bitMaskFor20) >> 21;
    s4 += carry3;
    s3 -= carry3 << 21;
    carry5 = (s5 + _bitMaskFor20) >> 21;
    s6 += carry5;
    s5 -= carry5 << 21;
    carry7 = (s7 + _bitMaskFor20) >> 21;
    s8 += carry7;
    s7 -= carry7 << 21;
    carry9 = (s9 + _bitMaskFor20) >> 21;
    s10 += carry9;
    s9 -= carry9 << 21;
    carry11 = (s11 + _bitMaskFor20) >> 21;
    s12 += carry11;
    s11 -= carry11 << 21;

    s0 += _mulInt64Int(s12, 666643);
    s1 += _mulInt64Int(s12, 470296);
    s2 += _mulInt64Int(s12, 654183);
    s3 -= _mulInt64Int(s12, 997805);
    s4 += _mulInt64Int(s12, 136657);
    s5 -= _mulInt64Int(s12, 683901);
    s12 = Int64.zero;

    carry0 = s0 >> 21;
    s1 += carry0;
    s0 -= carry0 << 21;
    carry1 = s1 >> 21;
    s2 += carry1;
    s1 -= carry1 << 21;
    carry2 = s2 >> 21;
    s3 += carry2;
    s2 -= carry2 << 21;
    carry3 = s3 >> 21;
    s4 += carry3;
    s3 -= carry3 << 21;
    carry4 = s4 >> 21;
    s5 += carry4;
    s4 -= carry4 << 21;
    carry5 = s5 >> 21;
    s6 += carry5;
    s5 -= carry5 << 21;
    carry6 = s6 >> 21;
    s7 += carry6;
    s6 -= carry6 << 21;
    carry7 = s7 >> 21;
    s8 += carry7;
    s7 -= carry7 << 21;
    carry8 = s8 >> 21;
    s9 += carry8;
    s8 -= carry8 << 21;
    carry9 = s9 >> 21;
    s10 += carry9;
    s9 -= carry9 << 21;
    carry10 = s10 >> 21;
    s11 += carry10;
    s10 -= carry10 << 21;
    carry11 = s11 >> 21;
    s12 += carry11;
    s11 -= carry11 << 21;

    s0 += _mulInt64Int(s12, 666643);
    s1 += _mulInt64Int(s12, 470296);
    s2 += _mulInt64Int(s12, 654183);
    s3 -= _mulInt64Int(s12, 997805);
    s4 += _mulInt64Int(s12, 136657);
    s5 -= _mulInt64Int(s12, 683901);

    carry0 = s0 >> 21;
    s1 += carry0;
    s0 -= carry0 << 21;
    carry1 = s1 >> 21;
    s2 += carry1;
    s1 -= carry1 << 21;
    carry2 = s2 >> 21;
    s3 += carry2;
    s2 -= carry2 << 21;
    carry3 = s3 >> 21;
    s4 += carry3;
    s3 -= carry3 << 21;
    carry4 = s4 >> 21;
    s5 += carry4;
    s4 -= carry4 << 21;
    carry5 = s5 >> 21;
    s6 += carry5;
    s5 -= carry5 << 21;
    carry6 = s6 >> 21;
    s7 += carry6;
    s6 -= carry6 << 21;
    carry7 = s7 >> 21;
    s8 += carry7;
    s7 -= carry7 << 21;
    carry8 = s8 >> 21;
    s9 += carry8;
    s8 -= carry8 << 21;
    carry9 = s9 >> 21;
    s10 += carry9;
    s9 -= carry9 << 21;
    carry10 = s10 >> 21;
    s11 += carry10;
    s10 -= carry10 << 21;
    final List<Int64> sBig = List<Int64>.filled(32, Int64.zero);
    sBig[0] = s0 >> 0;
    sBig[1] = s0 >> 8;
    sBig[2] = (s0 >> 16) | (s1 << 5);
    sBig[3] = s1 >> 3;
    sBig[4] = s1 >> 11;
    sBig[5] = (s1 >> 19) | (s2 << 2);
    sBig[6] = s2 >> 6;
    sBig[7] = (s2 >> 14) | (s3 << 7);
    sBig[8] = s3 >> 1;
    sBig[9] = s3 >> 9;
    sBig[10] = (s3 >> 17) | (s4 << 4);
    sBig[11] = s4 >> 4;
    sBig[12] = s4 >> 12;
    sBig[13] = (s4 >> 20) | (s5 << 1);
    sBig[14] = s5 >> 7;
    sBig[15] = (s5 >> 15) | (s6 << 6);
    sBig[16] = s6 >> 2;
    sBig[17] = s6 >> 10;
    sBig[18] = (s6 >> 18) | (s7 << 3);
    sBig[19] = s7 >> 5;
    sBig[20] = s7 >> 13;
    sBig[21] = s8 >> 0;
    sBig[22] = s8 >> 8;
    sBig[23] = (s8 >> 16) | (s9 << 5);
    sBig[24] = s9 >> 3;
    sBig[25] = s9 >> 11;
    sBig[26] = (s9 >> 19) | (s10 << 2);
    sBig[27] = s10 >> 6;
    sBig[28] = (s10 >> 14) | (s11 << 7);
    sBig[29] = s11 >> 1;
    sBig[30] = s11 >> 9;
    sBig[31] = s11 >> 17;
    for (int i = 0; i < sBig.length; i++) {
      s[i] = sBig[i].toUint8();
    }
  }

  static void scZero(List<int> s) {
    s.asMin32("scZero");
    int i;
    for (i = 0; i < 32; i++) {
      s[i] = 0;
    }
  }

  static void scFill(List<int> s, List<int> a) {
    s.asMin32("scFill");
    a.asMin32("scFill");
    int i;
    for (i = 0; i < 32; i++) {
      s[i] = a[i];
    }
  }

  static void geP1P1ToP2(GroupElementP2 r, GroupElementP1P1 p) {
    feMul(r.x, p.x, p.t);
    feMul(r.y, p.y, p.z);
    feMul(r.z, p.z, p.t);
  }

  static void geP2Dbl(GroupElementP1P1 r, GroupElementP2 p) {
    final FieldElement t0 = FieldElement();
    feSq(r.x, p.x);
    feSq(r.z, p.y);
    feSq2(r.t, p.z);
    feAdd(r.y, p.x, p.y);
    feSq(t0, r.y);
    feAdd(r.y, r.z, r.x);
    feSub(r.z, r.z, r.x);
    feSub(r.x, t0, r.y);
    feSub(r.t, r.t, r.z);
  }

  static void geMul8(GroupElementP1P1 r, GroupElementP2 t) {
    final GroupElementP2 u = GroupElementP2();
    geP2Dbl(r, t);
    geP1P1ToP2(u, r);
    geP2Dbl(r, u);
    geP1P1ToP2(u, r);
    geP2Dbl(r, u);
  }

  static void geCachedCmov(GroupElementCached t, GroupElementCached u, int b) {
    feCmov(t.yPlusX, u.yPlusX, b);
    feCmov(t.yMinusX, u.yMinusX, b);
    feCmov(t.z, u.z, b);
    feCmov(t.t2d, u.t2d, b);
  }

  static void scAdd(List<int> s, List<int> a, List<int> b) {
    s.asMin32("scAdd");
    a.asMin32("scAdd");
    b.asMin32("scAdd");
    final Int64 a0 = _andU64(_b2097151, _load3(a, 0));
    final Int64 a1 = _andU64(_b2097151, (_load4(a, 2) >> 5));
    final Int64 a2 = _andU64(_b2097151, (_load3(a, 5) >> 2));
    final Int64 a3 = _andU64(_b2097151, (_load4(a, 7) >> 7));
    final Int64 a4 = _andU64(_b2097151, (_load4(a, 10) >> 4));
    final Int64 a5 = _andU64(_b2097151, (_load3(a, 13) >> 1));
    final Int64 a6 = _andU64(_b2097151, (_load4(a, 15) >> 6));
    final Int64 a7 = _andU64(_b2097151, (_load3(a, 18) >> 3));
    final Int64 a8 = _andU64(_b2097151, _load3(a, 21));
    final Int64 a9 = _andU64(_b2097151, (_load4(a, 23) >> 5));
    final Int64 a10 = _andU64(_b2097151, (_load3(a, 26) >> 2));
    final Int64 a11 = (_load4(a, 28) >> 7).toInt64();
    final Int64 b0 = _andU64(_b2097151, _load3(b, 0));
    final Int64 b1 = _andU64(_b2097151, (_load4(b, 2) >> 5));
    final Int64 b2 = _andU64(_b2097151, (_load3(b, 5) >> 2));
    final Int64 b3 = _andU64(_b2097151, (_load4(b, 7) >> 7));
    final Int64 b4 = _andU64(_b2097151, (_load4(b, 10) >> 4));
    final Int64 b5 = _andU64(_b2097151, (_load3(b, 13) >> 1));
    final Int64 b6 = _andU64(_b2097151, (_load4(b, 15) >> 6));
    final Int64 b7 = _andU64(_b2097151, (_load3(b, 18) >> 3));
    final Int64 b8 = _andU64(_b2097151, _load3(b, 21));
    final Int64 b9 = _andU64(_b2097151, (_load4(b, 23) >> 5));
    final Int64 b10 = _andU64(_b2097151, (_load3(b, 26) >> 2));
    final Int64 b11 = (_load4(b, 28) >> 7).toInt64();
    Int64 s0 = a0 + b0;
    Int64 s1 = a1 + b1;
    Int64 s2 = a2 + b2;
    Int64 s3 = a3 + b3;
    Int64 s4 = a4 + b4;
    Int64 s5 = a5 + b5;
    Int64 s6 = a6 + b6;
    Int64 s7 = a7 + b7;
    Int64 s8 = a8 + b8;
    Int64 s9 = a9 + b9;
    Int64 s10 = a10 + b10;
    Int64 s11 = a11 + b11;
    Int64 s12 = Int64.zero;
    Int64 carry0;
    Int64 carry1;
    Int64 carry2;
    Int64 carry3;
    Int64 carry4;
    Int64 carry5;
    Int64 carry6;
    Int64 carry7;
    Int64 carry8;
    Int64 carry9;
    Int64 carry10;
    Int64 carry11;

    carry0 = (s0 + _bitMaskFor20) >> 21;
    s1 += carry0;
    s0 -= carry0 << 21;
    carry2 = (s2 + _bitMaskFor20) >> 21;
    s3 += carry2;
    s2 -= carry2 << 21;
    carry4 = (s4 + _bitMaskFor20) >> 21;
    s5 += carry4;
    s4 -= carry4 << 21;
    carry6 = (s6 + _bitMaskFor20) >> 21;
    s7 += carry6;
    s6 -= carry6 << 21;
    carry8 = (s8 + _bitMaskFor20) >> 21;
    s9 += carry8;
    s8 -= carry8 << 21;
    carry10 = (s10 + _bitMaskFor20) >> 21;
    s11 += carry10;
    s10 -= carry10 << 21;

    carry1 = (s1 + _bitMaskFor20) >> 21;
    s2 += carry1;
    s1 -= carry1 << 21;
    carry3 = (s3 + _bitMaskFor20) >> 21;
    s4 += carry3;
    s3 -= carry3 << 21;
    carry5 = (s5 + _bitMaskFor20) >> 21;
    s6 += carry5;
    s5 -= carry5 << 21;
    carry7 = (s7 + _bitMaskFor20) >> 21;
    s8 += carry7;
    s7 -= carry7 << 21;
    carry9 = (s9 + _bitMaskFor20) >> 21;
    s10 += carry9;
    s9 -= carry9 << 21;
    carry11 = (s11 + _bitMaskFor20) >> 21;
    s12 += carry11;
    s11 -= carry11 << 21;

    s0 += _mulInt64Int(s12, 666643);
    s1 += _mulInt64Int(s12, 470296);
    s2 += _mulInt64Int(s12, 654183);
    s3 -= _mulInt64Int(s12, 997805);
    s4 += _mulInt64Int(s12, 136657);
    s5 -= _mulInt64Int(s12, 683901);
    s12 = Int64.zero;

    carry0 = s0 >> 21;
    s1 += carry0;
    s0 -= carry0 << 21;
    carry1 = s1 >> 21;
    s2 += carry1;
    s1 -= carry1 << 21;
    carry2 = s2 >> 21;
    s3 += carry2;
    s2 -= carry2 << 21;
    carry3 = s3 >> 21;
    s4 += carry3;
    s3 -= carry3 << 21;
    carry4 = s4 >> 21;
    s5 += carry4;
    s4 -= carry4 << 21;
    carry5 = s5 >> 21;
    s6 += carry5;
    s5 -= carry5 << 21;
    carry6 = s6 >> 21;
    s7 += carry6;
    s6 -= carry6 << 21;
    carry7 = s7 >> 21;
    s8 += carry7;
    s7 -= carry7 << 21;
    carry8 = s8 >> 21;
    s9 += carry8;
    s8 -= carry8 << 21;
    carry9 = s9 >> 21;
    s10 += carry9;
    s9 -= carry9 << 21;
    carry10 = s10 >> 21;
    s11 += carry10;
    s10 -= carry10 << 21;
    carry11 = s11 >> 21;
    s12 += carry11;
    s11 -= carry11 << 21;

    s0 += _mulInt64Int(s12, 666643);
    s1 += _mulInt64Int(s12, 470296);
    s2 += _mulInt64Int(s12, 654183);
    s3 -= _mulInt64Int(s12, 997805);
    s4 += _mulInt64Int(s12, 136657);
    s5 -= _mulInt64Int(s12, 683901);

    carry0 = s0 >> 21;
    s1 += carry0;
    s0 -= carry0 << 21;
    carry1 = s1 >> 21;
    s2 += carry1;
    s1 -= carry1 << 21;
    carry2 = s2 >> 21;
    s3 += carry2;
    s2 -= carry2 << 21;
    carry3 = s3 >> 21;
    s4 += carry3;
    s3 -= carry3 << 21;
    carry4 = s4 >> 21;
    s5 += carry4;
    s4 -= carry4 << 21;
    carry5 = s5 >> 21;
    s6 += carry5;
    s5 -= carry5 << 21;
    carry6 = s6 >> 21;
    s7 += carry6;
    s6 -= carry6 << 21;
    carry7 = s7 >> 21;
    s8 += carry7;
    s7 -= carry7 << 21;
    carry8 = s8 >> 21;
    s9 += carry8;
    s8 -= carry8 << 21;
    carry9 = s9 >> 21;
    s10 += carry9;
    s9 -= carry9 << 21;
    carry10 = s10 >> 21;
    s11 += carry10;
    s10 -= carry10 << 21;
    final List<Int64> sBig = List<Int64>.filled(32, Int64.zero);
    sBig[0] = s0 >> 0;
    sBig[1] = s0 >> 8;
    sBig[2] = (s0 >> 16) | (s1 << 5);
    sBig[3] = s1 >> 3;
    sBig[4] = s1 >> 11;
    sBig[5] = (s1 >> 19) | (s2 << 2);
    sBig[6] = s2 >> 6;
    sBig[7] = (s2 >> 14) | (s3 << 7);
    sBig[8] = s3 >> 1;
    sBig[9] = s3 >> 9;
    sBig[10] = (s3 >> 17) | (s4 << 4);
    sBig[11] = s4 >> 4;
    sBig[12] = s4 >> 12;
    sBig[13] = (s4 >> 20) | (s5 << 1);
    sBig[14] = s5 >> 7;
    sBig[15] = (s5 >> 15) | (s6 << 6);
    sBig[16] = s6 >> 2;
    sBig[17] = s6 >> 10;
    sBig[18] = (s6 >> 18) | (s7 << 3);
    sBig[19] = s7 >> 5;
    sBig[20] = s7 >> 13;
    sBig[21] = s8 >> 0;
    sBig[22] = s8 >> 8;
    sBig[23] = (s8 >> 16) | (s9 << 5);
    sBig[24] = s9 >> 3;
    sBig[25] = s9 >> 11;
    sBig[26] = (s9 >> 19) | (s10 << 2);
    sBig[27] = s10 >> 6;
    sBig[28] = (s10 >> 14) | (s11 << 7);
    sBig[29] = s11 >> 1;
    sBig[30] = s11 >> 9;
    sBig[31] = s11 >> 17;
    for (int i = 0; i < sBig.length; i++) {
      s[i] = sBig[i].toUint8();
    }
    0xFFFFFFFF;
  }

  static void scReduce32(List<int> s) {
    s.asMin32("scReduce32");
    Int64 s0 = _andU64(_b2097151, _load3(s, 0));
    Int64 s1 = _andU64(_b2097151, (_load4(s, 2) >> 5));
    Int64 s2 = _andU64(_b2097151, (_load3(s, 5) >> 2));
    Int64 s3 = _andU64(_b2097151, (_load4(s, 7) >> 7));
    Int64 s4 = _andU64(_b2097151, (_load4(s, 10) >> 4));
    Int64 s5 = _andU64(_b2097151, (_load3(s, 13) >> 1));
    Int64 s6 = _andU64(_b2097151, (_load4(s, 15) >> 6));
    Int64 s7 = _andU64(_b2097151, (_load3(s, 18) >> 3));
    Int64 s8 = _andU64(_b2097151, _load3(s, 21));
    Int64 s9 = _andU64(_b2097151, (_load4(s, 23) >> 5));
    Int64 s10 = _andU64(_b2097151, (_load3(s, 26) >> 2));
    Int64 s11 = (_load4(s, 28) >> 7).toInt64();
    Int64 s12 = Int64.zero;
    Int64 carry0;
    Int64 carry1;
    Int64 carry2;
    Int64 carry3;
    Int64 carry4;
    Int64 carry5;
    Int64 carry6;
    Int64 carry7;
    Int64 carry8;
    Int64 carry9;
    Int64 carry10;
    Int64 carry11;

    carry0 = (s0 + _bitMaskFor20) >> 21;
    s1 += carry0;
    s0 -= carry0 << 21;
    carry2 = (s2 + _bitMaskFor20) >> 21;
    s3 += carry2;
    s2 -= carry2 << 21;
    carry4 = (s4 + _bitMaskFor20) >> 21;
    s5 += carry4;
    s4 -= carry4 << 21;
    carry6 = (s6 + _bitMaskFor20) >> 21;
    s7 += carry6;
    s6 -= carry6 << 21;
    carry8 = (s8 + _bitMaskFor20) >> 21;
    s9 += carry8;
    s8 -= carry8 << 21;
    carry10 = (s10 + _bitMaskFor20) >> 21;
    s11 += carry10;
    s10 -= carry10 << 21;

    carry1 = (s1 + _bitMaskFor20) >> 21;
    s2 += carry1;
    s1 -= carry1 << 21;
    carry3 = (s3 + _bitMaskFor20) >> 21;
    s4 += carry3;
    s3 -= carry3 << 21;
    carry5 = (s5 + _bitMaskFor20) >> 21;
    s6 += carry5;
    s5 -= carry5 << 21;
    carry7 = (s7 + _bitMaskFor20) >> 21;
    s8 += carry7;
    s7 -= carry7 << 21;
    carry9 = (s9 + _bitMaskFor20) >> 21;
    s10 += carry9;
    s9 -= carry9 << 21;
    carry11 = (s11 + _bitMaskFor20) >> 21;
    s12 += carry11;
    s11 -= carry11 << 21;

    s0 += _mulInt64Int(s12, 666643);
    s1 += _mulInt64Int(s12, 470296);
    s2 += _mulInt64Int(s12, 654183);
    s3 -= _mulInt64Int(s12, 997805);
    s4 += _mulInt64Int(s12, 136657);
    s5 -= _mulInt64Int(s12, 683901);
    s12 = Int64.zero;

    carry0 = s0 >> 21;
    s1 += carry0;
    s0 -= carry0 << 21;
    carry1 = s1 >> 21;
    s2 += carry1;
    s1 -= carry1 << 21;
    carry2 = s2 >> 21;
    s3 += carry2;
    s2 -= carry2 << 21;
    carry3 = s3 >> 21;
    s4 += carry3;
    s3 -= carry3 << 21;
    carry4 = s4 >> 21;
    s5 += carry4;
    s4 -= carry4 << 21;
    carry5 = s5 >> 21;
    s6 += carry5;
    s5 -= carry5 << 21;
    carry6 = s6 >> 21;
    s7 += carry6;
    s6 -= carry6 << 21;
    carry7 = s7 >> 21;
    s8 += carry7;
    s7 -= carry7 << 21;
    carry8 = s8 >> 21;
    s9 += carry8;
    s8 -= carry8 << 21;
    carry9 = s9 >> 21;
    s10 += carry9;
    s9 -= carry9 << 21;
    carry10 = s10 >> 21;
    s11 += carry10;
    s10 -= carry10 << 21;
    carry11 = s11 >> 21;
    s12 += carry11;
    s11 -= carry11 << 21;

    s0 += _mulInt64Int(s12, 666643);
    s1 += _mulInt64Int(s12, 470296);
    s2 += _mulInt64Int(s12, 654183);
    s3 -= _mulInt64Int(s12, 997805);
    s4 += _mulInt64Int(s12, 136657);
    s5 -= _mulInt64Int(s12, 683901);

    carry0 = s0 >> 21;
    s1 += carry0;
    s0 -= carry0 << 21;
    carry1 = s1 >> 21;
    s2 += carry1;
    s1 -= carry1 << 21;
    carry2 = s2 >> 21;
    s3 += carry2;
    s2 -= carry2 << 21;
    carry3 = s3 >> 21;
    s4 += carry3;
    s3 -= carry3 << 21;
    carry4 = s4 >> 21;
    s5 += carry4;
    s4 -= carry4 << 21;
    carry5 = s5 >> 21;
    s6 += carry5;
    s5 -= carry5 << 21;
    carry6 = s6 >> 21;
    s7 += carry6;
    s6 -= carry6 << 21;
    carry7 = s7 >> 21;
    s8 += carry7;
    s7 -= carry7 << 21;
    carry8 = s8 >> 21;
    s9 += carry8;
    s8 -= carry8 << 21;
    carry9 = s9 >> 21;
    s10 += carry9;
    s9 -= carry9 << 21;
    carry10 = s10 >> 21;
    s11 += carry10;
    s10 -= carry10 << 21;
    final List<Int64> sBig = List<Int64>.filled(32, Int64.zero);
    sBig[0] = s0 >> 0;
    sBig[1] = s0 >> 8;
    sBig[2] = (s0 >> 16) | (s1 << 5);
    sBig[3] = s1 >> 3;
    sBig[4] = s1 >> 11;
    sBig[5] = (s1 >> 19) | (s2 << 2);
    sBig[6] = s2 >> 6;
    sBig[7] = (s2 >> 14) | (s3 << 7);
    sBig[8] = s3 >> 1;
    sBig[9] = s3 >> 9;
    sBig[10] = (s3 >> 17) | (s4 << 4);
    sBig[11] = s4 >> 4;
    sBig[12] = s4 >> 12;
    sBig[13] = (s4 >> 20) | (s5 << 1);
    sBig[14] = s5 >> 7;
    sBig[15] = (s5 >> 15) | (s6 << 6);
    sBig[16] = s6 >> 2;
    sBig[17] = s6 >> 10;
    sBig[18] = (s6 >> 18) | (s7 << 3);
    sBig[19] = s7 >> 5;
    sBig[20] = s7 >> 13;
    sBig[21] = s8 >> 0;
    sBig[22] = s8 >> 8;
    sBig[23] = (s8 >> 16) | (s9 << 5);
    sBig[24] = s9 >> 3;
    sBig[25] = s9 >> 11;
    sBig[26] = (s9 >> 19) | (s10 << 2);
    sBig[27] = s10 >> 6;
    sBig[28] = (s10 >> 14) | (s11 << 7);
    sBig[29] = s11 >> 1;
    sBig[30] = s11 >> 9;
    sBig[31] = s11 >> 17;
    for (int i = 0; i < sBig.length; i++) {
      s[i] = sBig[i].toUint8();
    }
  }

  static GroupElementP3 geFromBytesVartime(List<int> s) {
    s.asMin32("geFromBytesVartime");
    final p = GroupElementP3();
    if (geFromBytesVartime_(p, s) != 0) {
      throw ArgumentException.invalidOperationArguments(
        "geFromBytesVartime",
        reason: "Invalid point encoding bytes.",
      );
    }
    return p;
  }

  static int geFromBytesVartime_(GroupElementP3 h, List<int> s) {
    s.asMin32("geFromBytesVartime");
    final FieldElement u = FieldElement();
    final FieldElement v = FieldElement();
    final FieldElement vxx = FieldElement();
    final FieldElement check = FieldElement();

    Int64 h0 = _load4(s, 0).toInt64();
    Int64 h1 = (_load3(s, 4) << 6).toInt64();
    Int64 h2 = (_load3(s, 7) << 5).toInt64();
    Int64 h3 = (_load3(s, 10) << 3).toInt64();
    Int64 h4 = (_load3(s, 13) << 2).toInt64();
    Int64 h5 = _load4(s, 16).toInt64();
    Int64 h6 = (_load3(s, 20) << 7).toInt64();
    Int64 h7 = (_load3(s, 23) << 5).toInt64();
    Int64 h8 = (_load3(s, 26) << 4).toInt64();
    Int64 h9 = ((_load3(s, 29) & Uint64(8388607)) << 2).toInt64();
    Int64 carry0;
    Int64 carry1;
    Int64 carry2;
    Int64 carry3;
    Int64 carry4;
    Int64 carry5;
    Int64 carry6;
    Int64 carry7;
    Int64 carry8;
    Int64 carry9;

    /* Validate the number to be canonical */
    if (h9 == 33554428.toInt64 &&
        h8 == 268435440.toInt64 &&
        h7 == 536870880.toInt64 &&
        h6 == 2147483520.toInt64 &&
        h5 == 4294967295.toInt64 &&
        h4 == 67108860.toInt64 &&
        h3 == 134217720.toInt64 &&
        h2 == 536870880.toInt64 &&
        h1 == 1073741760.toInt64 &&
        h0 >= 4294967277.toInt64) {
      return -1;
    }

    carry9 = (h9 + _bitMaskFor24) >> 25;
    h0 += carry9 * Int64(19);
    h9 -= carry9 << 25;
    carry1 = (h1 + _bitMaskFor24) >> 25;
    h2 += carry1;
    h1 -= carry1 << 25;
    carry3 = (h3 + _bitMaskFor24) >> 25;
    h4 += carry3;
    h3 -= carry3 << 25;
    carry5 = (h5 + _bitMaskFor24) >> 25;
    h6 += carry5;
    h5 -= carry5 << 25;
    carry7 = (h7 + _bitMaskFor24) >> 25;
    h8 += carry7;
    h7 -= carry7 << 25;

    carry0 = (h0 + _bitMaskFor25) >> 26;
    h1 += carry0;
    h0 -= carry0 << 26;
    carry2 = (h2 + _bitMaskFor25) >> 26;
    h3 += carry2;
    h2 -= carry2 << 26;
    carry4 = (h4 + _bitMaskFor25) >> 26;
    h5 += carry4;
    h4 -= carry4 << 26;
    carry6 = (h6 + _bitMaskFor25) >> 26;
    h7 += carry6;
    h6 -= carry6 << 26;
    carry8 = (h8 + _bitMaskFor25) >> 26;
    h9 += carry8;
    h8 -= carry8 << 26;

    h.y.h[0] = h0.toI32;
    h.y.h[1] = h1.toI32;
    h.y.h[2] = h2.toI32;
    h.y.h[3] = h3.toI32;
    h.y.h[4] = h4.toI32;
    h.y.h[5] = h5.toI32;
    h.y.h[6] = h6.toI32;
    h.y.h[7] = h7.toI32;
    h.y.h[8] = h8.toI32;
    h.y.h[9] = h9.toI32;

    /* End fe_frombytes.c */

    fe1(h.z);
    feSq(u, h.y);
    feMul(v, u, CryptoOpsConst.d);
    feSub(u, u, h.z); /* u = y^2-1 */
    feAdd(v, v, h.z); /* v = dy^2+1 */

    feDivpowm1(h.x, u, v); /* x = uv^3(uv^7)^((q-5)/8) */

    feSq(vxx, h.x);
    feMul(vxx, vxx, v);
    feSub(check, vxx, u); /* vx^2-u */
    if (feIsnonzero(check) != 0) {
      feAdd(check, vxx, u); /* vx^2+u */
      if (feIsnonzero(check) != 0) {
        return -1;
      }
      feMul(h.x, h.x, CryptoOpsConst.feSqrtm1);
    }

    if (feIsnegative(h.x) != (s[31] >> 7)) {
      /* If x = 0, the sign must be positive */
      if (feIsnonzero(h.x) == 0) {
        return -1;
      }
      feNeg(h.x, h.x);
    }

    feMul(h.t, h.x, h.y);
    return 0;
  }

  static void geDoubleScalarMultPrecompVartime(
    GroupElementP2 r,
    List<int> a,
    GroupElementP3 A,
    List<int> b,
    List<GroupElementCached> bI,
  ) {
    a.asMin32("geDoubleScalarMultPrecompVartime");
    b.asMin32("geDoubleScalarMultPrecompVartime");
    final List<GroupElementCached> aI = GroupElementCached.dsmp;
    geDsmPrecomp(aI, A);
    geDoubleScalarMultPrecompVartime2(r, a, aI, b, bI);
  }

  static void geDoubleScalarMultPrecompVartime2(
    GroupElementP2 r,
    List<int> a,
    List<GroupElementCached> aI,
    List<int> b,
    List<GroupElementCached> bI,
  ) {
    a.asMin32("geDoubleScalarMultPrecompVartime2");
    b.asMin32("geDoubleScalarMultPrecompVartime2");
    final List<int> aslide = List<int>.filled(256, 0);
    final List<int> bslide = List<int>.filled(256, 0);

    final GroupElementP1P1 t = GroupElementP1P1();
    final GroupElementP3 u = GroupElementP3();
    int i;

    slide(aslide, a);
    slide(bslide, b);

    geP2Zero(r);

    for (i = 255; i >= 0; --i) {
      if ((aslide[i] != 0) || (bslide[i] != 0)) break;
    }

    for (; i >= 0; --i) {
      geP2Dbl(t, r);

      if (aslide[i] > 0) {
        geP1P1ToP3(u, t);
        geAdd(t, u, aI[aslide[i] ~/ 2]);
      } else if (aslide[i] < 0) {
        geP1P1ToP3(u, t);
        geSub(t, u, aI[(-aslide[i]) ~/ 2]);
      }

      if (bslide[i] > 0) {
        geP1P1ToP3(u, t);
        geAdd(t, u, bI[bslide[i] ~/ 2]);
      } else if (bslide[i] < 0) {
        geP1P1ToP3(u, t);
        geSub(t, u, bI[(-bslide[i]) ~/ 2]);
      }

      geP1P1ToP2(r, t);
    }
  }

  static void geDoubleScalarMultPrecompVartime2P3(
    GroupElementP3 r3,
    List<int> a,
    List<GroupElementCached> aI,
    List<int> b,
    List<GroupElementCached> bI,
  ) {
    b.asMin32("geDoubleScalarMultPrecompVartime2P3");
    a.asMin32("geDoubleScalarMultPrecompVartime2P3");
    final List<int> aslide = List<int>.filled(256, 0);
    final List<int> bslide = List<int>.filled(256, 0);
    final GroupElementP1P1 t = GroupElementP1P1();
    final GroupElementP3 u = GroupElementP3();
    final GroupElementP2 r = GroupElementP2();
    int i = 0;

    slide(aslide, a);
    slide(bslide, b);

    geP2Zero(r);

    for (i = 255; i >= 0; --i) {
      if (aslide[i] != 0 || bslide[i] != 0) {
        break;
      }
    }

    for (; i >= 0; --i) {
      geP2Dbl(t, r);

      if (aslide[i] > 0) {
        geP1P1ToP3(u, t);
        geAdd(t, u, aI[aslide[i] ~/ 2]);
      } else if (aslide[i] < 0) {
        geP1P1ToP3(u, t);
        geSub(t, u, aI[(-aslide[i]) ~/ 2]);
      }

      if (bslide[i] > 0) {
        geP1P1ToP3(u, t);
        geAdd(t, u, bI[bslide[i] ~/ 2]);
      } else if (bslide[i] < 0) {
        geP1P1ToP3(u, t);
        geSub(t, u, bI[(-bslide[i]) ~/ 2]);
      }

      if (i == 0) {
        geP1P1ToP3(r3, t);
      } else {
        geP1P1ToP2(r, t);
      }
    }
  }

  static void geTripleScalarMultBaseVartime(
    GroupElementP2 r,
    List<int> a,
    List<int> b,
    GroupElementDsmp bI,
    List<int> c,
    GroupElementDsmp cI,
  ) {
    b.asMin32("geTripleScalarMultBaseVartime");
    a.asMin32("geTripleScalarMultBaseVartime");
    c.asMin32("geTripleScalarMultBaseVartime");
    final List<int> aslide = List<int>.filled(256, 0);
    final List<int> bslide = List<int>.filled(256, 0);
    final List<int> cslide = List<int>.filled(256, 0);

    final GroupElementP1P1 t = GroupElementP1P1();
    final GroupElementP3 u = GroupElementP3();
    int i;

    slide(aslide, a);
    slide(bslide, b);
    slide(cslide, c);

    geP2Zero(r);

    for (i = 255; i >= 0; --i) {
      if (aslide[i] != 0 || bslide[i] != 0 || cslide[i] != 0) {
        break;
      }
    }

    for (; i >= 0; --i) {
      geP2Dbl(t, r);

      if (aslide[i] > 0) {
        geP1P1ToP3(u, t);
        geMadd(t, u, CryptoOpsConst.geBi[aslide[i] ~/ 2]);
      } else if (aslide[i] < 0) {
        geP1P1ToP3(u, t);
        geMsub(t, u, CryptoOpsConst.geBi[(-aslide[i]) ~/ 2]);
      }

      if (bslide[i] > 0) {
        geP1P1ToP3(u, t);
        geAdd(t, u, bI[bslide[i] ~/ 2]);
      } else if (bslide[i] < 0) {
        geP1P1ToP3(u, t);
        geSub(t, u, bI[(-bslide[i]) ~/ 2]);
      }

      if (cslide[i] > 0) {
        geP1P1ToP3(u, t);
        geAdd(t, u, cI[cslide[i] ~/ 2]);
      } else if (cslide[i] < 0) {
        geP1P1ToP3(u, t);
        geSub(t, u, cI[(-cslide[i]) ~/ 2]);
      }

      geP1P1ToP2(r, t);
    }
  }

  static void geTripleScalarMultBasePrecompVartime(
    GroupElementP2 r,
    List<int> a,
    GroupElementDsmp aI,
    List<int> b,
    GroupElementDsmp bI,
    List<int> c,
    GroupElementDsmp cI,
  ) {
    b.asMin32("geTripleScalarMultBasePrecompVartime");
    a.asMin32("geTripleScalarMultBasePrecompVartime");
    c.asMin32("geTripleScalarMultBasePrecompVartime");
    final List<int> aslide = List<int>.filled(256, 0);
    final List<int> bslide = List<int>.filled(256, 0);
    final List<int> cslide = List<int>.filled(256, 0);
    final GroupElementP1P1 t = GroupElementP1P1();
    final GroupElementP3 u = GroupElementP3();
    int i;

    slide(aslide, a);
    slide(bslide, b);
    slide(cslide, c);

    geP2Zero(r);

    for (i = 255; i >= 0; --i) {
      if (aslide[i] != 0 || bslide[i] != 0 || cslide[i] != 0) {
        break;
      }
    }

    for (; i >= 0; --i) {
      geP2Dbl(t, r);

      if (aslide[i] > 0) {
        geP1P1ToP3(u, t);
        geAdd(t, u, aI[aslide[i] ~/ 2]);
      } else if (aslide[i] < 0) {
        geP1P1ToP3(u, t);
        geSub(t, u, aI[(-aslide[i]) ~/ 2]);
      }

      if (bslide[i] > 0) {
        geP1P1ToP3(u, t);
        geAdd(t, u, bI[bslide[i] ~/ 2]);
      } else if (bslide[i] < 0) {
        geP1P1ToP3(u, t);
        geSub(t, u, bI[(-bslide[i]) ~/ 2]);
      }

      if (cslide[i] > 0) {
        geP1P1ToP3(u, t);
        geAdd(t, u, cI[cslide[i] ~/ 2]);
      } else if (cslide[i] < 0) {
        geP1P1ToP3(u, t);
        geSub(t, u, cI[(-cslide[i]) ~/ 2]);
      }

      geP1P1ToP2(r, t);
    }
  }

  /// these method is not related to cryptoOps
  static List<EDPoint> geDsmPrecompVar(EDPoint point) {
    final List<EDPoint> oddMultiples = [];
    final twoP = point.double();
    var current = point;

    for (int i = 0; i < 8; i++) {
      oddMultiples.add(current);
      current = current + twoP; // Next odd multiple
    }

    return oddMultiples;
  }

  static EDPoint geDoubleScalarMultPrecompPointVar(
    List<int> a,
    List<EDPoint> aI,
    List<int> b,
    List<EDPoint> bI,
  ) {
    final aslide = List<int>.filled(256, 0);
    final bslide = List<int>.filled(256, 0);
    CryptoOps.slide(aslide, a);
    CryptoOps.slide(bslide, b);

    EDPoint? r;

    for (int i = 255; i >= 0; i--) {
      final aVal = aslide[i];
      final bVal = bslide[i];

      if (r == null) {
        if (aVal != 0) {
          final idx = (aVal.abs() - 1) ~/ 2;
          final ai = aI[idx];
          r = aVal > 0 ? ai : -ai;
        }

        if (bVal != 0) {
          final idx = (bVal.abs() - 1) ~/ 2;
          final bi = bI[idx];
          r = (r == null) ? (bVal > 0 ? bi : -bi) : (r + (bVal > 0 ? bi : -bi));
        }

        if (r == null) continue; // still no op
      } else {
        r = r * BigInt.two;

        if (aVal != 0) {
          final idx = (aVal.abs() - 1) ~/ 2;
          final ai = aI[idx];
          r += aVal > 0 ? ai : -ai;
        }

        if (bVal != 0) {
          final idx = (bVal.abs() - 1) ~/ 2;
          final bi = bI[idx];
          r += bVal > 0 ? bi : -bi;
        }
      }
    }

    if (r == null) {
      throw CryptoException.failed(
        "geDoubleScalarMultPrecompPointVar",
        reason: "Both scalars are zero; result undefined without identity support.",
      );
    }

    return r;
  }

  static EDPoint geTripleScalarMultBasePointVar({
    required List<int> a,
    required List<int> b,
    required List<EDPoint> bI,
    required List<int> c,
    required List<EDPoint> cI,
  }) {
    final aslide = List<int>.filled(256, 0);
    final bslide = List<int>.filled(256, 0);
    final cslide = List<int>.filled(256, 0);
    CryptoOps.slide(aslide, a);
    CryptoOps.slide(bslide, b);
    CryptoOps.slide(cslide, c);

    EDPoint? r;
    for (int i = 255; i >= 0; i--) {
      final aVal = aslide[i];
      final bVal = bslide[i];
      final cVal = cslide[i];

      if (r == null) {
        if (aVal != 0) {
          final idx = (aVal.abs() - 1) ~/ 2;
          final ai = Ed25519Utils.asPoint(
            BytesUtils.fromHexString(CryptoOpsConst.geBiPointBytes[idx]),
          );
          r = aVal > 0 ? ai : -ai;
        }

        if (bVal != 0) {
          final idx = (bVal.abs() - 1) ~/ 2;
          final bi = bI[idx];
          r = (r == null) ? (bVal > 0 ? bi : -bi) : (r + (bVal > 0 ? bi : -bi));
        }

        if (cVal != 0) {
          final idx = (cVal.abs() - 1) ~/ 2;
          final ci = cI[idx];
          r = (r == null) ? (cVal > 0 ? ci : -ci) : (r + (cVal > 0 ? ci : -ci));
        }

        if (r == null) continue;
      } else {
        r = r * BigInt.two;

        if (aVal != 0) {
          final idx = (aVal.abs() - 1) ~/ 2;
          final ai = Ed25519Utils.asPoint(
            BytesUtils.fromHexString(CryptoOpsConst.geBiPointBytes[idx]),
          );
          r += aVal > 0 ? ai : -ai;
        }

        if (bVal != 0) {
          final idx = (bVal.abs() - 1) ~/ 2;
          final bi = bI[idx];
          r += bVal > 0 ? bi : -bi;
        }

        if (cVal != 0) {
          final idx = (cVal.abs() - 1) ~/ 2;
          final ci = cI[idx];
          r += cVal > 0 ? ci : -ci;
        }
      }
    }

    if (r == null) {
      throw CryptoException.failed(
        "geTripleScalarMultBasePointVar",
        reason: "Both scalars are zero; result undefined without identity support.",
      );
    }

    return r;
  }

  static EDPoint geDoubleScalarMultBasePointVar({
    required List<int> a,
    required EDPoint gA,
    required List<int> b,
  }) {
    final aslide = List<int>.filled(256, 0);
    final bslide = List<int>.filled(256, 0);
    CryptoOps.slide(aslide, a);
    CryptoOps.slide(bslide, b);
    final aI = geDsmPrecompVar(gA);
    final Map<int, String> res = {};
    EDPoint? r;
    for (int i = 255; i >= 0; i--) {
      final aVal = aslide[i];
      final bVal = bslide[i];

      if (r == null) {
        if (aVal != 0) {
          final idx = (aVal.abs() - 1) ~/ 2;
          final bi = aI[idx];
          r = aVal > 0 ? bi : -bi;
        }
        if (bVal != 0) {
          final idx = (bVal.abs() - 1) ~/ 2;
          final ai = Ed25519Utils.asPoint(
            BytesUtils.fromHexString(CryptoOpsConst.geBiPointBytes[idx]),
          );
          r = (r == null) ? (bVal > 0 ? ai : -ai) : (r + (bVal > 0 ? ai : -ai));
        }

        // if (r == null) continue;
      } else {
        r = r * BigInt.two;

        if (aVal != 0) {
          final idx = (aVal.abs() - 1) ~/ 2;
          final bi = aI[idx];
          r += aVal > 0 ? bi : -bi;
        }
        if (bVal != 0) {
          final idx = (bVal.abs() - 1) ~/ 2;
          final ai = Ed25519Utils.asPoint(
            BytesUtils.fromHexString(CryptoOpsConst.geBiPointBytes[idx]),
          );
          r += bVal > 0 ? ai : -ai;
        }
        res.addAll({i: r.toHex()});
      }
    }

    if (r == null) {
      throw CryptoException.failed(
        "geDoubleScalarMultBasePointVar",
        reason: "All scalars are zero; result undefined without identity support.",
      );
    }

    return r;
  }

  static EDPoint geTripleScalarMultPrecompPointVar(
    List<int> a,
    List<EDPoint> aI,
    List<int> b,
    List<EDPoint> bI,
    List<int> c,
    List<EDPoint> cI,
  ) {
    final aslide = List<int>.filled(256, 0);
    final bslide = List<int>.filled(256, 0);
    final cslide = List<int>.filled(256, 0);

    CryptoOps.slide(aslide, a);
    CryptoOps.slide(bslide, b);
    CryptoOps.slide(cslide, c);

    EDPoint? r;

    for (int i = 255; i >= 0; i--) {
      final aVal = aslide[i];
      final bVal = bslide[i];
      final cVal = cslide[i];

      if (r == null) {
        if (aVal != 0) {
          final idx = (aVal.abs() - 1) ~/ 2;
          final ai = aI[idx];
          r = aVal > 0 ? ai : -ai;
        }
        if (bVal != 0) {
          final idx = (bVal.abs() - 1) ~/ 2;
          final bi = bI[idx];
          r = (r == null) ? (bVal > 0 ? bi : -bi) : (r + (bVal > 0 ? bi : -bi));
        }
        if (cVal != 0) {
          final idx = (cVal.abs() - 1) ~/ 2;
          final ci = cI[idx];
          r = (r == null) ? (cVal > 0 ? ci : -ci) : (r + (cVal > 0 ? ci : -ci));
        }

        if (r == null) continue; // still no op
      } else {
        r = r * BigInt.two;

        if (aVal != 0) {
          final idx = (aVal.abs() - 1) ~/ 2;
          final ai = aI[idx];
          r += aVal > 0 ? ai : -ai;
        }
        if (bVal != 0) {
          final idx = (bVal.abs() - 1) ~/ 2;
          final bi = bI[idx];
          r += bVal > 0 ? bi : -bi;
        }
        if (cVal != 0) {
          final idx = (cVal.abs() - 1) ~/ 2;
          final ci = cI[idx];
          r += cVal > 0 ? ci : -ci;
        }
      }
    }

    if (r == null) {
      throw CryptoException.failed(
        "geTripleScalarMultPrecompPointVar",
        reason: "All scalars are zero; result undefined without identity support.",
      );
    }

    return r;
  }
}

extension _BytesHelper on List<int> {
  void asMin32(String methodName) {
    if (length < 32) {
      throw ArgumentException.invalidOperationArguments(
        methodName,
        reason: "Invalid bytes length.",
      );
    }
  }
}

extension _T on int {
  Int64 get toInt64 => Int64(this);
}
