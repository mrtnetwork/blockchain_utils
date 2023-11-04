import 'package:blockchain_utils/bip/substrate/scale/substrate_scale_enc_base.dart';
import 'package:blockchain_utils/bip/substrate/scale/substrate_scale_enc_bytes.dart';
import 'package:blockchain_utils/bip/substrate/scale/substrate_scale_enc_cuint.dart';
import 'package:blockchain_utils/bip/substrate/scale/substrate_scale_enc_uint.dart';
import 'package:example/test/quick_hex.dart';

List<Map<String, dynamic>> _vector = [
  {
    "scale_enc": const SubstrateScaleU8Encoder(),
    "value": "12",
    "enc_value": "0c",
  },
  {
    "scale_enc": const SubstrateScaleU16Encoder(),
    "value": "18426",
    "enc_value": "fa47",
  },
  {
    "scale_enc": const SubstrateScaleU32Encoder(),
    "value": "1706095648",
    "enc_value": "20f4b065",
  },
  {
    "scale_enc": const SubstrateScaleU64Encoder(),
    "value": "2579765632504954883",
    "enc_value": "030038b12c2bcd23",
  },
  {
    "scale_enc": const SubstrateScaleU128Encoder(),
    "value": "1981057649835179426526325300541830",
    "enc_value": "8639b01a20016476244b8076ac610000",
  },
  {
    "scale_enc": const SubstrateScaleU256Encoder(),
    "value":
        "4512471174635598247890384632897562349411987594382343298700199879854632446",
    "enc_value":
        "fead49273e86747ef831ed3aba591de566f0989853ffccb38852bddbd08d0200",
  },
  {
    "scale_enc": const SubstrateScaleCUintEncoder(),
    "value": "48",
    "enc_value": "c0",
  },
  {
    "scale_enc": const SubstrateScaleCUintEncoder(),
    "value": "13429",
    "enc_value": "d5d1",
  },
  {
    "scale_enc": const SubstrateScaleCUintEncoder(),
    "value": "1013741822",
    "enc_value": "fae3b1f1",
  },
  {
    "scale_enc": const SubstrateScaleCUintEncoder(),
    "value": "2579765632504954883",
    "enc_value": "13030038b12c2bcd23",
  },
  {
    "scale_enc": const SubstrateScaleCUintEncoder(),
    "value": "1981057649835179426526325300541830",
    "enc_value": "2b8639b01a20016476244b8076ac61",
  },
  {
    "scale_enc": const SubstrateScaleCUintEncoder(),
    "value":
        "4512471174635598247890384632897562349411987594382343298700199879854632446",
    "enc_value":
        "6ffead49273e86747ef831ed3aba591de566f0989853ffccb38852bddbd08d02",
  },
  {
    "scale_enc": const SubstrateScaleBytesEncoder(),
    "value": "Test string",
    "enc_value": "2c5465737420737472696e67",
  },
];
void substrateScaleTest() {
  for (final i in _vector) {
    final SubstrateScaleEncoderBase encoder = i["scale_enc"]!;
    final encode = encoder.encode(i["value"]);
    assert(encode.toHex() == i["enc_value"]);
  }
}
