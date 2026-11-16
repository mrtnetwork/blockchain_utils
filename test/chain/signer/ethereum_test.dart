import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

import '../../utils.dart';

void main() {
  BlockchainUtilsTestApi.runTest(ethereumTest, "Ethereum");
}

void ethereumTest() {
  test("sign verify test", () {
    final signer = ETHSigner.fromBytes(
      BytesUtils.fromHexString(
        "cd23c9f2e2c096ee3be3c4e0e58199800c0036ea27b7cd4e838bbde8b21788b3",
      ),
    );
    final message = BytesUtils.fromHexString(
      "0x84df2267aa318f451199223385516162",
    );
    final sign = signer.signPersonalMessage(message);
    final signConst = signer.signPersonalMessage(message);
    final verify = signer.toVerifier().verifyPersonalMessage(
      message,
      sign.encoded,
    );
    expect(
      sign.encoded.toHex(),
      "4b57a6ca5e2f5da5ae9667d69bb61285808b54ed08dacc76d77b02a8e6f6be905bf4f6fce63ff4142af25458c3bb8ecbda4990b76783a35561382096e30082321b",
    );
    expect(
      signConst.encoded.toHex(),
      "4b57a6ca5e2f5da5ae9667d69bb61285808b54ed08dacc76d77b02a8e6f6be905bf4f6fce63ff4142af25458c3bb8ecbda4990b76783a35561382096e30082321b",
    );

    expect(verify, true);
    final publicKey = ETHVerifier.getPublicKey(message, sign.encoded);
    expect(
      BytesUtils.bytesEqual(
        publicKey.toBytes(),
        signer.toVerifier().verificationKey.toBytes(),
      ),
      true,
    );
  });
}
