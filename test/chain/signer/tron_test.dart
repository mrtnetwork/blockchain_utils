import 'dart:convert';

import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

import '../../utils.dart';

void tronTest() {
  test("sign verify test", () {
    final signer = TronSigner.fromBytes(
      BytesUtils.fromHexString(
        "43985273a3d94eb753fe6acfd7003e88254effce1eb53e2e97b8522558a98038",
      ),
    );
    final message = utf8.encode("message");
    final sign = signer.signPersonalMessage(message);
    final verify = signer.toVerifier().verifyPersonalMessage(
      message,
      sign.encoded,
    );
    expect(
      sign.encoded.toHex(),
      "fde00bc33d78109bc61de314c1c0526a047e22a2aaae473ca84b32d8aa35ed3e03720e05d614087e3d8c6fae63879755b32aa08818a2d4de66fee1a617a971671b",
    );
    expect(verify, true);
  });
}

void main() {
  BlockchainUtilsTestApi.runTest(tronTest, "Tron");
}
