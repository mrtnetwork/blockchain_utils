import 'package:blockchain_utils/bip/address/exception/exception.dart';
import 'package:blockchain_utils/bip/bip.dart';
import '../../quick_hex.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:test/test.dart';
import 'test_vector.dart';

void main() {
  test("aptos address test", () {
    for (final i in testVector) {
      final params = Map<String, dynamic>.from(i["params"]);

      final z = AptosAddrEncoder()
          .encodeKey(BytesUtils.fromHexString(i["public"]), params);
      expect(z, i["address"]);
      final decode = AptosAddrDecoder().decodeAddr(z, params);
      expect(decode.toHex(), i["decode"]);
    }
  });
  _testMultiKey();
  _testMultiKey2();
  _testMultiEdAccount4();
  _testMultiEdAccount();
  _testMultiEdAccount2();
  _testSignleKeyEd25519();
  _testSignleKeySecp256k1();
}

void _testMultiKey2() {
  test("MultiKey account 2", () {
    final privateKey1 = Ed25519PrivateKey.fromBytes(List<int>.filled(32, 12));
    final privateKey2 = Ed25519PrivateKey.fromBytes(List<int>.filled(32, 13));
    final privateKey3 =
        Secp256k1PrivateKeyEcdsa.fromBytes(List<int>.filled(32, 14));
    final account = AptosAddrEncoder().encodeMultiKey(publicKeys: [
      privateKey1.publicKey,
      privateKey2.publicKey,
      privateKey3.publicKey,
    ], requiredSignature: 3);
    expect(account,
        "0x4b7c50ba0047625f75407f5dc73a0d00524c50016ea483d44439d5ee72369d05");
  });
}

void _testMultiKey() {
  test("MultiKey account", () {
    final privateKey1 = Ed25519PrivateKey.fromBytes(List<int>.filled(32, 12));
    final privateKey2 = Ed25519PrivateKey.fromBytes(List<int>.filled(32, 13));
    final privateKey3 = Ed25519PrivateKey.fromBytes(List<int>.filled(32, 14));
    final account = AptosAddrEncoder().encodeMultiKey(publicKeys: [
      privateKey1.publicKey,
      privateKey2.publicKey,
      privateKey3.publicKey,
    ], requiredSignature: 3);
    expect(account,
        "0x82a01ce96b00669a8ac358eac6551cc17dbb16f1841a5ecfe69f4750e20fe56c");
  });
}

void _testMultiEdAccount4() {
  test("Multi Ed25519 account wrong public keys", () {
    final privateKey1 = Ed25519PrivateKey.fromBytes(List<int>.filled(32, 12));
    expect(
        () => AptosAddrEncoder().encodeMultiEd25519Key(publicKeys: [
              privateKey1.publicKey,
            ], threshold: 2),
        throwsA(TypeMatcher<AddressConverterException>()));
  });
  test("Multi Ed25519 account wrong threshold", () {
    final privateKey1 = Ed25519PrivateKey.fromBytes(List<int>.filled(32, 12));
    expect(
        () => AptosAddrEncoder().encodeMultiEd25519Key(publicKeys: [
              privateKey1.publicKey,
              privateKey1.publicKey,
              privateKey1.publicKey,
              privateKey1.publicKey,
            ], threshold: 7),
        throwsA(TypeMatcher<AddressConverterException>()));
  });
}

void _testMultiEdAccount2() {
  test("Multi Ed25519 account 3", () {
    final privateKey1 = Ed25519PrivateKey.fromBytes(List<int>.filled(32, 12));
    final privateKey2 = Ed25519PrivateKey.fromBytes(List<int>.filled(32, 13));
    final privateKey3 = Ed25519PrivateKey.fromBytes(List<int>.filled(32, 14));
    final account = AptosAddrEncoder().encodeMultiEd25519Key(publicKeys: [
      privateKey1.publicKey,
      privateKey2.publicKey,
      privateKey3.publicKey
    ], threshold: 2);
    expect(account,
        "0xdab62cecd6d92eca7968f1184bce94992b062868d23ea09752c6d04ce6318407");
  });
}

void _testMultiEdAccount() {
  test("Multi Ed25519 account 2", () {
    final privateKey1 = Ed25519PrivateKey.fromBytes(List<int>.filled(32, 12));
    final privateKey2 = Ed25519PrivateKey.fromBytes(List<int>.filled(32, 13));
    final privateKey3 = Ed25519PrivateKey.fromBytes(List<int>.filled(32, 14));
    final account = AptosAddrEncoder().encodeMultiEd25519Key(publicKeys: [
      privateKey1.publicKey,
      privateKey2.publicKey,
      privateKey3.publicKey
    ], threshold: 3);
    expect(account,
        "0xbca0f886d39361116fc4dbe2c80f9ca7edae425030df03b4a158fd448faac91b");
  });
}

void _testSignleKeyEd25519() {
  test("Ed25519 singleKey account", () {
    final privateKey = Ed25519PrivateKey.fromBytes(List<int>.filled(32, 12));
    final account = AptosAddrEncoder().encodeSingleKey(privateKey.publicKey);
    expect(account,
        "0x6f1468722b30e87e8be765554d244db068b8de2222bb9600cf5a03139922ef86");
  });
}

void _testSignleKeySecp256k1() {
  test("Secp256k1 singleKey account", () {
    final privateKey =
        Secp256k1PrivateKeyEcdsa.fromBytes(List<int>.filled(32, 12));
    final account = AptosAddrEncoder().encodeSingleKey(privateKey.publicKey);
    expect(account,
        "0x89dd43dcedf165f975202fae5f8aecf03013ebc14bb3c09a1431313b4ee52b02");
  });
}
