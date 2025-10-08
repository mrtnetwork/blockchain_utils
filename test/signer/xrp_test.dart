import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

void main() {
  test("TEST", () {
    const String blob =
        "535458001200052200000000240272eb8c201b0272ec4a68400000000000000a732103ef451404c8753525f760059c5f4431181f29d09448856cc8fd867a7346698aae8114440bee336b72b7f4ad58b1b2fd2ba0ce9ba7625288140000000000000000000000000000000000000001f9ea7c04546578747d0e4d52544e4554574f524b2e636f6d7e0a746578742f706c61696ee1f1";
    const String sig =
        "3044022043b52acacfe98066ade99274ac96d5dab65738b344fed8d78acca1c33894d8a5022021f3dd6caba9c9904cf1347a3440652ba47af844cfb1bfcd7ad878a6dd9a3909";
    final signer = XrpSigner.fromKeyBytes(
        BytesUtils.fromHexString(
            "C63383DAC6B5B043A66B8E1BBBC3CF48E6B170862B7AE36217F516237211E39B"),
        EllipticCurveTypes.secp256k1);

    expect(BytesUtils.toHexString(signer.sign(BytesUtils.fromHexString(blob))),
        sig);
    expect(
        BytesUtils.toHexString(
            signer.signConst(BytesUtils.fromHexString(blob))),
        sig);
  });
  test("TEST2", () {
    const String blob =
        "535458001200032200000000240272eb8d201b0272eedc20210000000468400000000000000a732103ef451404c8753525f760059c5f4431181f29d09448856cc8fd867a7346698aae8114440bee336b72b7f4ad58b1b2fd2ba0ce9ba76252f9ea7c04546578747d0e4d52544e4554574f524b2e636f6d7e0a746578742f706c61696ee1f1";
    const String sig =
        "3045022100d37aac7c901baa32a5fc1759d41740216264193f85662e186c419e7481f0f7a102202948dfd2f13b724bdc16e71335117b9a644a27f409c4ec905f5568bad96ec680";
    final signer = XrpSigner.fromKeyBytes(
        BytesUtils.fromHexString(
            "C63383DAC6B5B043A66B8E1BBBC3CF48E6B170862B7AE36217F516237211E39B"),
        EllipticCurveTypes.secp256k1);
    expect(BytesUtils.toHexString(signer.sign(BytesUtils.fromHexString(blob))),
        sig);
    expect(
        BytesUtils.toHexString(
            signer.signConst(BytesUtils.fromHexString(blob))),
        sig);
  });
}
