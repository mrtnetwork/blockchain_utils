import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

void main() {
  test("sign verify test", () {
    final signer = ETHSigner.fromKeyBytes(BytesUtils.fromHexString(
        "cd23c9f2e2c096ee3be3c4e0e58199800c0036ea27b7cd4e838bbde8b21788b3"));
    final message =
        BytesUtils.fromHexString("0x84df2267aa318f451199223385516162");
    final sign = signer.signProsonalMessage(message);
    final verify = signer.toVerifyKey().verifyPersonalMessage(message, sign);
    expect(BytesUtils.toHexString(sign),
        "4b57a6ca5e2f5da5ae9667d69bb61285808b54ed08dacc76d77b02a8e6f6be905bf4f6fce63ff4142af25458c3bb8ecbda4990b76783a35561382096e30082321b");
    expect(verify, true);
    final publicKey = ETHVerifier.getPublicKey(message, sign);
    expect(
        BytesUtils.bytesEqual(publicKey?.toBytes(),
            signer.toVerifyKey().edsaVerifyKey.publicKey.toBytes()),
        true);
  });
}
