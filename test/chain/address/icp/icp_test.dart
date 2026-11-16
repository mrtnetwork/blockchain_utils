import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

import '../../../utils.dart';

void icpTest() {
  group('ICP principal encode/decode', () {
    final vectors = {
      'aaaaa-aa': <int>[],
      '2vxsx-fae': [0x04],
      'ryjl3-tyaaa-aaaaa-aaaba-cai': BytesUtils.fromHexString(
        '00000000000000020101',
      ),
      'rkp4c-7iaaa-aaaaa-aaaca-cai': BytesUtils.fromHexString(
        '00000000000000040101',
      ),
      'em77e-bvlzu-aq': BytesUtils.fromHexString('abcd01'),
      'e3mmv-5qaaa-aaaah-aadma-cai': BytesUtils.fromHexString(
        '0000000000e000d80101',
      ),
    };

    final decoder = IcpAddrDecoder();
    final encoder = IcpAddrEncoder();

    for (final e in vectors.entries) {
      test('round-trip ${e.key}', () {
        final decoded = decoder.decodeAddr(e.key);
        expect(decoded.type, ICPAddressType.principal);
        expect(decoded.bytes, e.value);

        final encoded = encoder.encode(
          decoded.bytes,
          addrType: ICPAddressType.principal,
        );
        expect(encoded.address, e.key);
      });
    }

    test('invalid CRC rejected', () {
      expect(
        () => decoder.decodeAddr('aaaaa-ab'), // wrong checksum
        throwsA(isA<BuError>()),
      );
    });
  });

  group('ICP account identifier', () {
    final decoder = IcpAddrDecoder();
    final encoder = IcpAddrEncoder();

    final vectors = {
      // principal raw → account id hex
      '': '2d0e897f7e862d2b57d9bc9ea5c65f9a24ac6c074575f47898314b8d6cb0929d',
      '04': '1c7a48ba6a562aa9eaa2481a9049cdf0433b9738c992d698c31d8abf89cadc79',
      '00000000000000020101':
          '883eef7c44be51afe4a4420d4df4beff708f3cf2f5de5efcc9f58680bb0f3690',
    };

    for (final e in vectors.entries) {
      test('account id for ${e.key.isEmpty ? "empty" : e.key}', () {
        final principal =
            e.key.isEmpty ? <int>[] : BytesUtils.fromHexString(e.key);

        final encoded = encoder.encode(
          principal,
          addrType: ICPAddressType.accountIdentifier,
          // default subaccount = zeros
        );
        expect(encoded.address, e.value);

        final decoded = decoder.decodeAddr(e.value);
        expect(decoded.type, ICPAddressType.accountIdentifier);
        expect(BytesUtils.toHexString(decoded.bytes), e.value);
      });
    }

    test('invalid account id CRC rejected', () {
      // flip last nibble of a valid id
      expect(
        () => decoder.decodeAddr(
          '883eef7c44be51afe4a4420d4df4beff708f3cf2f5de5efcc9f58680bb0f3691',
        ),
        throwsA(isA<BuError>()),
      );
    });
  });

  test('uppercase principal accepted and normalized', () {
    final d = IcpAddrDecoder().decodeAddr('RYJL3-TYAAA-AAAAA-AAABA-CAI');
    expect(
      IcpAddrEncoder().encode(d.bytes).address,
      'ryjl3-tyaaa-aaaaa-aaaba-cai',
    );
  });

  test('0x-prefixed account id accepted', () {
    final d = IcpAddrDecoder().decodeAddr(
      '0x883eef7c44be51afe4a4420d4df4beff708f3cf2f5de5efcc9f58680bb0f3690',
    );
    expect(d.type, ICPAddressType.accountIdentifier);
  });

  test('subaccount changes account id', () {
    final principal = BytesUtils.fromHexString('00000000000000020101');
    final sub = List<int>.filled(32, 0)..[31] = 1;

    final a = IcpAddrEncoder().encode(
      principal,
      addrType: ICPAddressType.accountIdentifier,
    );
    final b = IcpAddrEncoder().encode(
      principal,
      addrType: ICPAddressType.accountIdentifier,
      subaccount: sub,
    );
    expect(a.address, isNot(equals(b.address)));
  });
}

void main() {
  BlockchainUtilsTestApi.runTest(icpTest, "Icp");
}
