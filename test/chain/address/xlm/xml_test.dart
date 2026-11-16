import 'package:blockchain_utils/chain/address/neworks/others/xlm_addr.dart';

import 'package:blockchain_utils/utils/utils.dart';
import 'package:test/test.dart';

import 'test_vector.dart' show testVector;

import '../../../utils.dart';

void xmlTest() {
  test("xml address test", () {
    for (final i in testVector.shuffleTake()) {
      final params = Map<String, dynamic>.from(i["params"]);
      final addrType = XlmAddrTypes.values.firstWhere(
        (element) => element.value == params["addr_type"],
      );

      final z = XlmAddrEncoder().encodeKey(
        BytesUtils.fromHexString(i["public"]),
        addrType: addrType,
      );
      expect(z, i["address"]);
      final decode = XlmAddrDecoder().decodeAddr(z, addrType: addrType);
      expect(decode.toHex(), i["decode"]);
    }
  });

  test("xml muxed contract (W, CAP-84) address test", () {
    // Contract id from the SEP-23 examples; W vectors cross-checked with an
    // independent strkey implementation (version byte 22 << 3).
    const contractIdHex =
        "3f0c34bf93ad0d9971d04ccc90f705511c838aad9734a4a2fb0d7a03fc7fe89a";
    const contractBase =
        "CA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUWDA";
    final contractId = BytesUtils.fromHexString(contractIdHex);
    const vectors = {
      0:
          "WA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUAAAAAAAAAAAAAWWC",
      1:
          "WA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUAAAAAAAAAAAAEGHC",
    };
    const maxU64Str = "18446744073709551615";
    const maxU64Addr =
        "WA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJV7777777777777GMO";
    for (final entry in vectors.entries) {
      final addr = XlmAddrEncoder().encodeKey(
        contractId,
        addrType: XlmAddrTypes.muxedContract,
        muxedId: BigInt.from(entry.key),
      );
      expect(addr, entry.value);
      expect(addr[0], "W");
      final decoded = XlmAddrDecoder().decode(addr);
      expect(decoded.type, XlmAddrTypes.muxedContract);
      expect(BytesUtils.toHexString(decoded.pubKeyBytes), contractIdHex);
      expect(decoded.accountId, BigInt.from(entry.key));
      expect(decoded.baseAddress, contractBase);
      final raw = XlmAddrDecoder().decodeAddr(
        addr,
        addrType: XlmAddrTypes.muxedContract,
      );
      expect(raw.toHex(), contractIdHex);
    }
    final maxAddr = XlmAddrEncoder().encodeKey(
      contractId,
      addrType: XlmAddrTypes.muxedContract,
      muxedId: BigInt.parse(maxU64Str),
    );
    expect(maxAddr, maxU64Addr);
    expect(
      XlmAddrDecoder().decode(maxAddr).accountId,
      BigInt.parse(maxU64Str),
    );

    // A contract id is a hash, not an Ed25519 point: encoding must not
    // require a valid curve point.
    const zeroAddr =
        "WAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA4R5U";
    final zeroEnc = XlmAddrEncoder().encodeKey(
      List<int>.filled(32, 0),
      addrType: XlmAddrTypes.muxedContract,
      muxedId: BigInt.from(7),
    );
    expect(zeroEnc, zeroAddr);
    final zeroDec = XlmAddrDecoder().decode(zeroAddr);
    expect(zeroDec.type, XlmAddrTypes.muxedContract);
    expect(zeroDec.accountId, BigInt.from(7));

    // muxedId is required, as for M addresses.
    expect(
      () => XlmAddrEncoder().encodeKey(
        contractId,
        addrType: XlmAddrTypes.muxedContract,
      ),
      throwsA(anything),
    );
  });

  test("xml muxed account (M) regression test", () {
    // SEP-23 vector guards the shared muxed decode branch.
    const muxed =
        "MA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUAAAAAAAAAAAACJUQ";
    const base =
        "GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ";
    final decoded = XlmAddrDecoder().decode(muxed);
    expect(decoded.type, XlmAddrTypes.muxed);
    expect(decoded.accountId, BigInt.zero);
    expect(decoded.baseAddress, base);
  });
}

void main() {
  BlockchainUtilsTestApi.runTest(xmlTest, "Xml");
}
