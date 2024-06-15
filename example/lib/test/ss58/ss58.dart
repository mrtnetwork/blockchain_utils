// ignore_for_file: depend_on_referenced_packages

import 'package:example/test/quick_hex.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:blockchain_utils/ss58/ss58.dart';

final List<Map<String, dynamic>> _testVector = [
  {
    "raw": "facc4de5b7745215ec8255c743f044d2a94ef72b2fb6d8e22c35ffbc3ac8ac9e",
    "ss58_format": 0,
    "encode": "16fqfQjHSWMoMxydLYoYixYcTGvcE3csECC69Lik312jNWS9",
  },
  {
    "raw": "0ae7387f2bbf2846df7a1fb07b0676f1e4c35787f96b6a618e254afea5434d04",
    "ss58_format": 2,
    "encode": "CpcgbdXbwSbUJF38WTzR2r8CpeF29Jeyqm1EZmJmey7sXVE",
  },
  {
    "raw": "9494d77c224df8b09e05b91ebe7a2f475c12a4cfd103da6b58679b22fc995fda",
    "ss58_format": 42,
    "encode": "5FRXACEYAEcDiWnScWfuqGkYVrq8wyNysbgMGvjDnKLUKFv5",
  },
  {
    "raw": "f2b0e94f4d04acb16ecbe3348482b207ba6e60585dd641a8b0f6f28ca99795bc",
    "ss58_format": 63,
    "encode": "7P5mRixqQk1Z1h4U15Z2zMc6vKoprgWs645jehsbti5irbc7",
  },
  {
    "raw": "735ec2e330426e8643745d5bf6b287bfec4e50eaca556c9f2781b02db5e7a236",
    "ss58_format": 64,
    "encode": "cEYBURAnCdz1eMtzsDW3JAz8dEGrahsjYiHXZCBFsxHK7VJX1",
  },
  {
    "raw": "735ec2e330426e8643745d5bf6b287bfec4e50eaca556c9f2781b02db5e7a236",
    "ss58_format": 127,
    "encode": "jArK6dHqpF4QE6a9H8B54gNRy6hSBzpYBGjCwp4KrqxoADwNq",
  },
];
void ss58Test() {
  for (final i in _testVector) {
    final dec = SS58Decoder.decode(i["encode"]);
    assert(dec.item1 == i["ss58_format"]);
    assert(dec.item2.toHex() == i["raw"]);
  }
  for (final i in _testVector) {
    final dec = SS58Encoder.encode(
        BytesUtils.fromHexString(i["raw"]), i["ss58_format"]);
    assert(dec == i["encode"]);
  }
}
