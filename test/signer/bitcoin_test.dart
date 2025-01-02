import 'package:blockchain_utils/signer/bitcoin_signer.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';
import 'package:test/test.dart';

void main() {
  _schnorr();
}

void _schnorr() {
  test("schnorr sig", () {
    final btcSigner = BitcoinSigner.fromKeyBytes(BytesUtils.fromHexString(
        "0000000000000000000000000000000000000000000000000000000000000003"));
    final sig = btcSigner.signSchnorrTransaction(
        BytesUtils.fromHexString(
            "0000000000000000000000000000000000000000000000000000000000000000"),
        tapScripts: [],
        tweak: false,
        auxRand: BytesUtils.fromHexString(
            "0000000000000000000000000000000000000000000000000000000000000000"));
    expect(
        sig,
        BytesUtils.fromHexString(
            "E907831F80848D1069A5371B402410364BDF1C5F8307B0084C55F1CE2DCA821525F66A4A85EA8B71E482A74F382D2CE5EBEEE8FDB2172F477DF4900D310536C0"));
  });
  test("schnorr sig 2", () {
    final btcSigner = BitcoinSigner.fromKeyBytes(BytesUtils.fromHexString(
        "B7E151628AED2A6ABF7158809CF4F3C762E7160F38B4DA56A784D9045190CFEF"));
    final sig = btcSigner.signSchnorrTransaction(
        BytesUtils.fromHexString(
            "243F6A8885A308D313198A2E03707344A4093822299F31D0082EFA98EC4E6C89"),
        tapScripts: [],
        tweak: false,
        auxRand: BytesUtils.fromHexString(
            "0000000000000000000000000000000000000000000000000000000000000001"));
    expect(
        sig,
        BytesUtils.fromHexString(
            "6896BD60EEAE296DB48A229FF71DFE071BDE413E6D43F917DC8DCF8C78DE33418906D11AC976ABCCB20B091292BFF4EA897EFCB639EA871CFA95F6DE339E4B0A"));
  });
  test("schnorr sig 3", () {
    final btcSigner = BitcoinSigner.fromKeyBytes(BytesUtils.fromHexString(
        "C90FDAA22168C234C4C6628B80DC1CD129024E088A67CC74020BBEA63B14E5C9"));
    final sig = btcSigner.signSchnorrTransaction(
        BytesUtils.fromHexString(
            "7E2D58D8B3BCDF1ABADEC7829054F90DDA9805AAB56C77333024B9D0A508B75C"),
        tapScripts: [],
        tweak: false,
        auxRand: BytesUtils.fromHexString(
            "C87AA53824B4D7AE2EB035A2B5BBBCCC080E76CDC6D1692C4B0B62D798E6D906"));
    expect(
        sig,
        BytesUtils.fromHexString(
            "5831AAEED7B44BB74E5EAB94BA9D4294C49BCF2A60728D8B4C200F50DD313C1BAB745879A5AD954A72C45A91C3A51D3C7ADEA98D82F8481E0E1E03674A6F3FB7"));
  });
  test("schnorr sig 4", () {
    final btcSigner = BitcoinSigner.fromKeyBytes(BytesUtils.fromHexString(
        "0B432B2677937381AEF05BB02A66ECD012773062CF3FA2549E44F58ED2401710"));
    final sig = btcSigner.signSchnorrTransaction(
        BytesUtils.fromHexString(
            "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"),
        tapScripts: [],
        tweak: false,
        auxRand: BytesUtils.fromHexString(
            "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"));
    expect(
        sig,
        BytesUtils.fromHexString(
            "7EB0509757E246F19449885651611CB965ECC1A187DD51B64FDA1EDC9637D5EC97582B9CB13DB3933705B32BA982AF5AF25FD78881EBB32771FC5922EFC66EA3"));
  });
}
