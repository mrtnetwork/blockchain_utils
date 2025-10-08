import 'package:blockchain_utils/signer/signer.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';
import 'package:test/test.dart';

void main() {
  _test();
}

void _test() {
  group("ED25519", () {
    test("sign/verify", () {
      final digest = BytesUtils.fromHexString(
          "80010001030b513ad9b4924015ca0902ed079044d3ac5dbec2306f06948c10da8eb6e39f2d807e1b63e7c241c72448e8f9f05e65d421ea40ceae40f47ca347f7d79c38d0e60000000000000000000000000000000000000000000000000000000000000000be4325d9b7456f6393d0c1bbf8ef09c05d5c179fb830b7e16f1c3d1f21c8540b01020200010c0200000040420f000000000000");
      final signer = Ed25519Signer.fromKeyBytes(BytesUtils.fromHexString(
          "0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c"));
      final sig = BytesUtils.fromHexString(
          "47c2764edb810b97c7a883c292a74c9850af349473fcbd9f08b13fd772b215f4129d90b4eacae7112f04d2a9c3fb871cd2ae382772ff9da0528071b9f68d7300");
      List<int> signature = signer.sign(digest);
      expect(signature, sig);
      signature = signer.signConst(digest);
      expect(signature, sig);
    });
  });
}
