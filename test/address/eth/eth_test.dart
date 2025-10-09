import 'package:blockchain_utils/bech32/bech32.dart';
import 'package:blockchain_utils/bip/address/addr_dec_utils.dart';
import 'package:blockchain_utils/bip/address/eth_addr.dart';
import 'package:blockchain_utils/bip/coin_conf/constant/coins_conf.dart';
import '../../quick_hex.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:test/test.dart';

import 'test_vector.dart' show testVector, convertorTestVector;

void main() {
  test("eth address test", () {
    for (final i in testVector) {
      final params = Map<String, dynamic>.from(i["params"]);
      final z = EthAddrEncoder()
          .encodeKey(BytesUtils.fromHexString(i["public"]), params);
      expect(z, i["address"]);
      final decode = EthAddrDecoder().decodeAddr(z, params);
      expect(decode.toHex(), i["decode"]);
    }
  });

  test("eth address convertor test", () {
    for (final i in convertorTestVector) {
      final bech32Address = i["bech32"]!;
      final ethAddress = i["hex"]!;
      expect(
          AddrDecUtils.validateAndRemovePrefix(
                  ethAddress, CoinsConf.ethereum.params.addrPrefix!
          ).length,
          EthAddrConst.addrLen
      );

      final prefix = bech32Address.split(Bech32Const.separator)[0];

      // Convert Bech32 to Hex
      final convertedHex =
          EthBech32Converter.bech32ToEthAddress(bech32Address, prefix);
      expect(convertedHex, ethAddress.toLowerCase(),
          reason:
              "Converting $bech32Address, Expected: $ethAddress, but got: $convertedHex");

      // Convert Hex to Bech32
      final convertedBech32 =
          EthBech32Converter.ethAddressToBech32(ethAddress, prefix);
      expect(convertedBech32, bech32Address,
          reason:
              "Converting $ethAddress, Expected: $bech32Address, but got: $convertedBech32");
    }

    final invalidAddressWithWrongLength =
        "0x1448b2449076672aCD167b91406c09552101C5";
    expect(
        AddrDecUtils.validateAndRemovePrefix(
            invalidAddressWithWrongLength,
            CoinsConf.ethereum.params.addrPrefix!
        ).length,
        isNot(EthAddrConst.addrLen)
    );

    (
      () => EthBech32Converter.ethAddressToBech32(
          invalidAddressWithWrongLength, "eth"),
      throwsA(isA<AssertionError>())
    );
  });
}
