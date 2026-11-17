import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

import '../../../utils.dart';

void blsTest() {
  group("bls", () {
    final dstSigProofG2 =
        "BLS_SIG_BLS12381G2_XMD:SHA-256_SSWU_RO_POP_".codeUnits;

    test("aggregate single key", () {
      final sigHex =
          "0xb6ed936746e01f8ecf281f020953fbf1f01debd5657c4a383940b020b26507f6076334f91e2366c96e9ab279fb5158090352ea1c5b0c9274504f4f0e7053af24802e51e4568d164fe986834f41e55c8e850ce1f98458c0cfc9ab380b55285a55";
      final pubKey = Bls12G2PublicKey.fromBytes(
        BytesUtils.fromHexString(sigHex),
      );
      final k = Bls12G2AggregatePublicKey.fromPubKeys([pubKey]);
      expect(k.aggregateKey, pubKey);
    });
    test("aggregate single key", () {
      final sigHex =
          "0xb6ed936746e01f8ecf281f020953fbf1f01debd5657c4a383940b020b26507f6076334f91e2366c96e9ab279fb5158090352ea1c5b0c9274504f4f0e7053af24802e51e4568d164fe986834f41e55c8e850ce1f98458c0cfc9ab380b55285a55";
      final pubKey = Bls12G2PublicKey.fromBytes(
        BytesUtils.fromHexString(sigHex),
      );
      final k = Bls12G2AggregatePublicKey.fromPubKeys([pubKey]);
      expect(k.aggregateKey, pubKey);
    });
    test("aggregate infinity key", () {
      final sigHex =
          "0xc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";

      expect(
        () => Bls12G2PublicKey.fromBytes(BytesUtils.fromHexString(sigHex)),
        throwsA(isA<BuError>()),
      );
    });

    test("aggregate verify", () {
      for (final i in _signatures) {
        final pubKeys =
            i
                .valueEnsureAsMap("input")
                .valueEnsureAsList<String>("pubkeys")
                .map((e) {
                  return Bls12G1PublicKey.fromBytes(
                    BytesUtils.fromHexString(e),
                  );
                })
                .toList();
        final messages =
            i
                .valueEnsureAsMap("input")
                .valueEnsureAsList<String>("messages")
                .map(BytesUtils.fromHexString)
                .toList();
        final dec = Bls12G1AggregatePublicKey.fromPubKeys(pubKeys);
        final signature = i
            .valueEnsureAsMap("input")
            .valueAsBytes<List<int>>("signature");
        final verify = dec.verify(
          Bls12G1AggregateVerifiyingParams(
            signature: Bls12G1Signature.fromBytes(signature),
            messages: messages,
            dst: dstSigProofG2,
          ),
        );
        expect(verify, i.valueAsBool("output"));
      }
    });
    test("batch verify", () {
      for (final i in _batcSignatures) {
        final pubKeys =
            i
                .valueEnsureAsMap("input")
                .valueEnsureAsList<String>("pubkeys")
                .map((e) {
                  return Bls12G1PublicKey.fromBytes(
                    BytesUtils.fromHexString(e),
                  );
                })
                .toList();
        final messages =
            i
                .valueEnsureAsMap("input")
                .valueEnsureAsList<String>("messages")
                .map(BytesUtils.fromHexString)
                .toList();
        final dec = Bls12G1AggregatePublicKey.fromPubKeys(pubKeys);
        final signatures =
            i
                .valueEnsureAsMap("input")
                .valueEnsureAsList<String>("signatures")
                .map(BytesUtils.fromHexString)
                .toList();
        final verify = dec.batchVerify(
          Bls12G1AggregateBatchVerifiyingParams(
            signatures:
                signatures.map((e) => Bls12G1Signature.fromBytes(e)).toList(),
            messages: messages,
            dst: dstSigProofG2,
          ),
        );
        expect(verify, i.valueAsBool("output"));
      }
    });

    test("fast verify", () {
      for (final i in _fastVerify) {
        final pubKeys =
            i
                .valueEnsureAsMap("input")
                .valueEnsureAsList<String>("pubkeys")
                .map((e) {
                  return Bls12G1PublicKey.fromBytes(
                    BytesUtils.fromHexString(e),
                  );
                })
                .toList();
        final dec = Bls12G1AggregatePublicKey.fromPubKeys(pubKeys);
        final message = i
            .valueEnsureAsMap("input")
            .valueAsBytes<List<int>>("message");
        final signature = i
            .valueEnsureAsMap("input")
            .valueAsBytes<List<int>>("signature");
        final verify = dec.verifyFast(
          Bls12G1AggregateFastVerifiyingParams(
            signature: Bls12G1Signature.fromBytes(signature),
            signingParams: Bls12SigningParams(
              message: message,
              dst: dstSigProofG2,
            ),
          ),
        );
        expect(verify, i.valueAsBool("output"));
      }
    });

    test("G1 sign/verify", () {
      for (int i = 0; i < 3; i++) {
        final key = Bls12G1AggregatePrivateKey.fromSecretKeys(
          List.generate(i + 1, (i) => Bls12G1PrivateKey.random()),
        );
        final decode = Bls12G1AggregatePrivateKey.fromBytes(key.toBytes());
        expect(decode, key);
        final messages = List.generate(
          i + 1,
          (_) => QuickCrypto.generateRandom(),
        );
        final signature = key.sign(
          Bls12AggregateSigningParams(messages: messages, dst: dstSigProofG2),
        );
        expect(
          key.verificationKey().batchVerify(
            Bls12G1AggregateBatchVerifiyingParams(
              signatures: signature.signatures,
              messages: messages,
              dst: dstSigProofG2,
            ),
          ),
          true,
        );
        expect(
          key.verificationKey().verify(
            Bls12G1AggregateVerifiyingParams(
              signature: signature.aggregateSignature,
              messages: messages,
              dst: dstSigProofG2,
            ),
          ),
          true,
        );
        {
          final message = QuickCrypto.generateRandom();
          final signature = key.signFast(
            Bls12FastAggregateSigningParams(
              message: message,
              dst: dstSigProofG2,
            ),
          );
          expect(
            key.verificationKey().verifyFast(
              Bls12G1AggregateFastVerifiyingParams(
                signature: signature,
                signingParams: Bls12SigningParams(
                  message: message,
                  dst: dstSigProofG2,
                ),
              ),
            ),
            true,
          );
        }
      }
    });

    test("G2 sign/verify", () {
      for (int i = 0; i < 3; i++) {
        final key = Bls12G2AggregatePrivateKey.fromSecretKeys(
          List.generate(i + 1, (i) => Bls12G2PrivateKey.random()),
        );
        final decode = Bls12G2AggregatePrivateKey.fromBytes(key.toBytes());
        expect(decode, key);
        final messages = List.generate(
          i + 1,
          (_) => QuickCrypto.generateRandom(),
        );
        final signature = key.sign(
          Bls12AggregateSigningParams(messages: messages, dst: dstSigProofG2),
        );
        expect(
          key.verificationKey().batchVerify(
            Bls12G2AggregateBatchVerifiyingParams(
              signatures: signature.signatures,
              messages: messages,
              dst: dstSigProofG2,
            ),
          ),
          true,
        );
        expect(
          key.verificationKey().verify(
            Bls12G2AggregateVerifiyingParams(
              signature: signature.aggregateSignature,
              messages: messages,
              dst: dstSigProofG2,
            ),
          ),
          true,
        );
        {
          final message = QuickCrypto.generateRandom();
          final signature = key.signFast(
            Bls12FastAggregateSigningParams(
              message: message,
              dst: dstSigProofG2,
            ),
          );
          expect(
            key.verificationKey().verifyFast(
              Bls12G2AggregateFastVerifiyingParams(
                signature: signature,
                signingParams: Bls12SigningParams(
                  message: message,
                  dst: dstSigProofG2,
                ),
              ),
            ),
            true,
          );
        }
      }
    });

    test("Bls publicKey, signature, verifySignature", () {
      final t = _testVector.map((e) => _BLSTestVector.fromJson(e)).toList();
      for (final i in t) {
        final key = Bls12G1PrivateKey.fromBytes(i.privateKey);
        expect(
          key.publicKey.toBytes(mode: CryptoKeyEncoding.base),
          i.publicKey,
        );
        final pubKey = Bls12G1PublicKey.fromBytes(i.publicKey);
        expect(pubKey, key.publicKey);
        for (final s in i.signatures) {
          final signingParams = Bls12SigningParams(
            message: s.message,
            dst: s.dest,
          );
          final signature = key.sign(signingParams);

          final vr = pubKey.verify(
            Bls12G1VerifiyingParams(
              signature: signature,
              signingParams: signingParams,
            ),
          );
          expect(vr, isTrue);
          expect(signature.toBytes(), s.signature);
        }
      }
    });
    test("Bls publicKey, signature, verifySignature", () {
      for (int i = 0; i < 5; i++) {
        final key = Bls12G2PrivateKey.random();
        final params = Bls12SigningParams(
          message: "test$i".codeUnits,
          dst: "BLS12381G1_XMD:SHA-256_SSWU_RO_".codeUnits,
        );
        final signature = key.sign(params);
        final verify = key.publicKey.verify(
          Bls12G2VerifiyingParams(signature: signature, signingParams: params),
        );
        expect(verify, isTrue);
      }
    });
  });
}

void main() {
  BlockchainUtilsTestApi.runTest(blsTest, "Bls");
}

const List<Map<String, dynamic>> _fastVerify = [
  {
    "input": {
      "pubkeys": [
        "0xa491d1b0ecd9bb917989f0e74f0dea0422eac4a873e5e2644f368dffb9a6e20fd6e10c1b77654d067c0618f6e5a7f79a",
        "0xb301803f8b5ac4a1133581fc676dfedc60d891dd5fa99028805e5ea5b08d3491af75d0707adab3b70c6a6a580217bf81",
        "0xb53d21a4cfd562c469cc81514d4ce5a6b577d8403d32a394dc265dd190b47fa9f829fdd7963afdf972e5e77854051f6f",
        "0xb53d21a4cfd562c469cc81514d4ce5a6b577d8403d32a394dc265dd190b47fa9f829fdd7963afdf972e5e77854051f6f",
      ],
      "message":
          "0xabababababababababababababababababababababababababababababababab",
      "signature":
          "0x9712c3edd73a209c742b8250759db12549b3eaf43b5ca61376d9f30e2747dbcf842d8b2ac0901d2a093713e20284a7670fcf6954e9ab93de991bb9b313e664785a075fc285806fa5224c82bde146561b446ccfc706a64b8579513cfc4ff1d930",
    },
    "output": false,
  },
  {
    "input": {
      "pubkeys": [
        "0xa491d1b0ecd9bb917989f0e74f0dea0422eac4a873e5e2644f368dffb9a6e20fd6e10c1b77654d067c0618f6e5a7f79a",
        "0xb301803f8b5ac4a1133581fc676dfedc60d891dd5fa99028805e5ea5b08d3491af75d0707adab3b70c6a6a580217bf81",
        "0xb53d21a4cfd562c469cc81514d4ce5a6b577d8403d32a394dc265dd190b47fa9f829fdd7963afdf972e5e77854051f6f",
      ],
      "message":
          "0x5656565656565656565656565656565656565656565656565656565656565656",
      "signature":
          "0x912c3615f69575407db9392eb21fee18fff797eeb2fbe1816366ca2a08ae574d8824dbfafb4c9eaa1cf61b63c6f9b69911f269b664c42947dd1b53ef1081926c1e82bb2a465f927124b08391a5249036146d6f3f1e17ff5f162f779746d830d1",
    },
    "output": false,
  },
  {
    "input": {
      "pubkeys": [
        "0xa491d1b0ecd9bb917989f0e74f0dea0422eac4a873e5e2644f368dffb9a6e20fd6e10c1b77654d067c0618f6e5a7f79a",
        "0xb301803f8b5ac4a1133581fc676dfedc60d891dd5fa99028805e5ea5b08d3491af75d0707adab3b70c6a6a580217bf81",
        "0xb53d21a4cfd562c469cc81514d4ce5a6b577d8403d32a394dc265dd190b47fa9f829fdd7963afdf972e5e77854051f6f",
      ],
      "message":
          "0xabababababababababababababababababababababababababababababababab",
      "signature":
          "0x9712c3edd73a209c742b8250759db12549b3eaf43b5ca61376d9f30e2747dbcf842d8b2ac0901d2a093713e20284a7670fcf6954e9ab93de991bb9b313e664785a075fc285806fa5224c82bde146561b446ccfc706a64b8579513cfc4ff1d930",
    },
    "output": true,
  },
  {
    "input": {
      "pubkeys": [
        "0xa491d1b0ecd9bb917989f0e74f0dea0422eac4a873e5e2644f368dffb9a6e20fd6e10c1b77654d067c0618f6e5a7f79a",
      ],
      "message":
          "0x0000000000000000000000000000000000000000000000000000000000000000",
      "signature":
          "0xb6ed936746e01f8ecf281f020953fbf1f01debd5657c4a383940b020b26507f6076334f91e2366c96e9ab279fb5158090352ea1c5b0c9274504f4f0e7053af24802e51e4568d164fe986834f41e55c8e850ce1f98458c0cfc9ab380b55285a55",
    },
    "output": true,
  },
  {
    "input": {
      "pubkeys": [
        "0xa491d1b0ecd9bb917989f0e74f0dea0422eac4a873e5e2644f368dffb9a6e20fd6e10c1b77654d067c0618f6e5a7f79a",
        "0xb301803f8b5ac4a1133581fc676dfedc60d891dd5fa99028805e5ea5b08d3491af75d0707adab3b70c6a6a580217bf81",
      ],
      "message":
          "0x5656565656565656565656565656565656565656565656565656565656565656",
      "signature":
          "0x912c3615f69575407db9392eb21fee18fff797eeb2fbe1816366ca2a08ae574d8824dbfafb4c9eaa1cf61b63c6f9b69911f269b664c42947dd1b53ef1081926c1e82bb2a465f927124b08391a5249036146d6f3f1e17ff5f162f779746d830d1",
    },
    "output": true,
  },
];

const List<Map<String, dynamic>> _batcSignatures = [
  {
    "input": {
      "pubkeys": [
        "0xa491d1b0ecd9bb917989f0e74f0dea0422eac4a873e5e2644f368dffb9a6e20fd6e10c1b77654d067c0618f6e5a7f79a",
        "0xb301803f8b5ac4a1133581fc676dfedc60d891dd5fa99028805e5ea5b08d3491af75d0707adab3b70c6a6a580217bf81",
      ],
      "messages": [
        "0x0000000000000000000000000000000000000000000000000000000000000000",
        "0x5656565656565656565656565656565656565656565656565656565656565656",
      ],
      "signatures": [
        "0xa70f1f1b4bd97d182ebb55d08be3f90b1dc232bb50b44e259381a642ef0bad3629ad3542f3e8ff6a84e451fc0b595e090fc4f0e860cfc5584715ef1b6cd717b9994378f7a51b815bbf5a0d95bc3402583ad2e95a229731e539906249a5e4355c",
        "0xb758eb7e15c101f53be2214d2a6b65e8fe7053146dbe3c73c9fe9b5efecdf63ca06a4d5d938dbf18fe6600529c0011a7013f45ae012b02904d5c7c33316e935a0e084abead4f43f84383c52cd3b3f14024437e251a2a7c0d5147954022873a58",
      ],
    },
    "output": false,
  },
  {
    "input": {
      "pubkeys": [
        "0xa491d1b0ecd9bb917989f0e74f0dea0422eac4a873e5e2644f368dffb9a6e20fd6e10c1b77654d067c0618f6e5a7f79a",
        "0xb301803f8b5ac4a1133581fc676dfedc60d891dd5fa99028805e5ea5b08d3491af75d0707adab3b70c6a6a580217bf81",
      ],
      "messages": [
        "0x0000000000000000000000000000000000000000000000000000000000000000",
        "0x5656565656565656565656565656565656565656565656565656565656565656",
      ],
      "signatures": [
        "0xb6ed936746e01f8ecf281f020953fbf1f01debd5657c4a383940b020b26507f6076334f91e2366c96e9ab279fb5158090352ea1c5b0c9274504f4f0e7053af24802e51e4568d164fe986834f41e55c8e850ce1f98458c0cfc9ab380b55285a55",
        "0xaf1390c3c47acdb37131a51216da683c509fce0e954328a59f93aebda7e4ff974ba208d9a4a2a2389f892a9d418d618418dd7f7a6bc7aa0da999a9d3a5b815bc085e14fd001f6a1948768a3f4afefc8b8240dda329f984cb345c6363272ba4fe",
      ],
    },
    "output": true,
  },
  {
    "input": {
      "pubkeys": [
        "0xa491d1b0ecd9bb917989f0e74f0dea0422eac4a873e5e2644f368dffb9a6e20fd6e10c1b77654d067c0618f6e5a7f79a",
        "0xb301803f8b5ac4a1133581fc676dfedc60d891dd5fa99028805e5ea5b08d3491af75d0707adab3b70c6a6a580217bf81",
        "0xb53d21a4cfd562c469cc81514d4ce5a6b577d8403d32a394dc265dd190b47fa9f829fdd7963afdf972e5e77854051f6f",
      ],
      "messages": [
        "0x0000000000000000000000000000000000000000000000000000000000000000",
        "0x5656565656565656565656565656565656565656565656565656565656565656",
        "0xabababababababababababababababababababababababababababababababab",
      ],
      "signatures": [
        "0xb6ed936746e01f8ecf281f020953fbf1f01debd5657c4a383940b020b26507f6076334f91e2366c96e9ab279fb5158090352ea1c5b0c9274504f4f0e7053af24802e51e4568d164fe986834f41e55c8e850ce1f98458c0cfc9ab380b55285a55",
        "0xaf1390c3c47acdb37131a51216da683c509fce0e954328a59f93aebda7e4ff974ba208d9a4a2a2389f892a9d418d618418dd7f7a6bc7aa0da999a9d3a5b815bc085e14fd001f6a1948768a3f4afefc8b8240dda329f984cb345c6363272ba4fe",
        "0xae82747ddeefe4fd64cf9cedb9b04ae3e8a43420cd255e3c7cd06a8d88b7c7f8638543719981c5d16fa3527c468c25f0026704a6951bde891360c7e8d12ddee0559004ccdbe6046b55bae1b257ee97f7cdb955773d7cf29adf3ccbb9975e4eb9",
      ],
    },
    "output": true,
  },
];

const List<Map<String, dynamic>> _signatures = [
  {
    "input": {
      "pubkeys": [
        "0xa491d1b0ecd9bb917989f0e74f0dea0422eac4a873e5e2644f368dffb9a6e20fd6e10c1b77654d067c0618f6e5a7f79a",
        "0xb301803f8b5ac4a1133581fc676dfedc60d891dd5fa99028805e5ea5b08d3491af75d0707adab3b70c6a6a580217bf81",
        "0xb53d21a4cfd562c469cc81514d4ce5a6b577d8403d32a394dc265dd190b47fa9f829fdd7963afdf972e5e77854051f6f",
      ],
      "messages": [
        "0x0000000000000000000000000000000000000000000000000000000000000000",
        "0x5656565656565656565656565656565656565656565656565656565656565656",
        "0xabababababababababababababababababababababababababababababababab",
      ],
      "signature":
          "0x9104e74b9dfd3ad502f25d6a5ef57db0ed7d9a0e00f3500586d8ce44231212542fcfaf87840539b398bf07626705cf1105d246ca1062c6c2e1a53029a0f790ed5e3cb1f52f8234dc5144c45fc847c0cd37a92d68e7c5ba7c648a8a339f171244",
    },
    "output": true,
  },
];

class _BLSTestVector {
  final List<int> privateKey;
  final List<int> publicKey;
  final List<_Signature> signatures;
  const _BLSTestVector({
    required this.privateKey,
    required this.publicKey,
    required this.signatures,
  });
  factory _BLSTestVector.fromJson(Map<String, dynamic> json) {
    return _BLSTestVector(
      privateKey: json.valueAsBytes("privateKey"),
      publicKey: json.valueAsBytes("publicKey"),
      signatures:
          json
              .valueEnsureAsList("signatures")
              .map((e) => _Signature.fromJson(e))
              .toList(),
    );
  }
}

class _Signature {
  final List<int> message;
  final List<int> dest;
  final List<int> signature;
  const _Signature({
    required this.message,
    required this.dest,
    required this.signature,
  });
  factory _Signature.fromJson(Map<String, dynamic> json) {
    return _Signature(
      message: json.valueAsBytes("message"),
      dest: json.valueAsBytes("dest"),
      signature: json.valueAsBytes("signature"),
    );
  }
}

final List<Map<String, dynamic>> _testVector = [
  {
    "privateKey":
        "0x00e83d790514806cd17c56383e803991e9690fa4c34193473b7bf46a41484f57",
    "publicKey":
        "0xb96ab84afe4e7bad3415bca55e982a1079f33b375e768326cb87d9d79db412d4d1df6e2b7e8c5cd2923a86cd0c65ebdd",
    "signatures": [
      {
        "message": "0x68656c6c6f20776f726c64",
        "dest":
            "0x424c535f5349475f424c53313233383147325f584d443a5348412d3235365f535357555f524f5f4e554c5f",
        "signature":
            "0xb5c337919236730ac6d961d871ba29c1226667b2a3cca29bc2f523e63d0db82d52865ae539448a5f962d10c562e88112095d23b72b15ea2d7991c87741b5d212e72cfc61002f520b516ad298a812d311d1875977472ce5d1dedc2044571bfd9d",
      },
    ],
  },
  {
    "privateKey":
        "0x5106b2540175c9165fb8617042a9d15dab016e255e8dfcfa0135dfa060676e76",
    "publicKey":
        "0xa8fff278c506d973090003d0e6f8a61e0ab76fd72bd9dca6c80c777d8848e607005483ae66b6bd146623f66b3fa48577",
    "signatures": [
      {
        "message": "0x",
        "dest":
            "0x515555582d5630312d435330322d776974682d424c53313233383147325f584d443a5348412d3235365f535357555f524f5f",
        "signature":
            "0xa11132c61c34e19d4542ab8da453063907f562201a7b67cfffc1dc0d4cce360093bea3b00ff65b78f058888ea4e0c8720c0d04e196a5244b3391cdbeb591a55e6ac60d2c4f4936f997ee74836c470fe356854ca6f806b4dc3db9b92de4b7b06d",
      },
      {
        "message":
            "0x54686520717569636b2062726f776e20666f78206a756d7073206f76657220746865206c617a7920646f67",
        "dest": "0x4d592d4150502d424c532d5349472d5631",
        "signature":
            "0x833172cdde86dc9a9131bc6dbbc62c690ae6e890a2c556c3f316db25d3e8492b53128311139b3b539260b3a11163afcf13ba608e1ffd07cf55cf7093bca7475714d70e24ab5ede6d381801fefd6d1ffc6ac3ae8e80173329d759bc8b8d3ee6a1",
      },
    ],
  },
  {
    "privateKey":
        "0x2d377fdbd4399477bab9939f3c30922519dd28a2f9dc0aadc6efcad77f868d95",
    "publicKey":
        "0xa2b2a00b430ef1a801a5a78ad14fc4ddb0f42e3418f9d05c9b82bd718d0c5c89cbd038cc4bf3a22ce32574addd5977ac",
    "signatures": [
      {
        "message":
            "0x54686520717569636b2062726f776e20666f78206a756d7073206f76657220746865206c617a7920646f67",
        "dest": "0x4d592d4150502d424c532d5349472d5631",
        "signature":
            "0xb449fae2ec319c697cf1420c530223a24e9e8b825f53841b1b2f2e9a51dc8a54de991fcd014872cc48efc46b5b041415107ef9dfb10569219e481d59e381ecc35e0ae5dc8cafa02b9341fffdc9edc63c8a5bc44a216fc30b2bdcf2b89e4a50af",
      },
      {
        "message": "0x7b22616d6f756e74223a3130302c22746f223a22616c696365227d",
        "dest":
            "0x424c535f5349475f424c53313233383147325f584d443a5348412d3235365f535357555f524f5f4e554c5f",
        "signature":
            "0x972fa0ac66fbabb391a24f2f5a5cd34a38b8636c58d31044d4192553d63b5255b033a91b1895b91bd07539950397b21b0a4864d7e36d76fbf8acca3e7fb1f61af60865572d91d6910b835fd7b6e54c825a348c06d34e6f81242a7ce9ccd94700",
      },
      {
        "message":
            "0x3031303230333034303530363037303830393061306230633064306530663130",
        "dest":
            "0x515555582d5630312d435330322d776974682d424c53313233383147325f584d443a5348412d3235365f535357555f524f5f",
        "signature":
            "0x88e7a9cb423c7b4349fdbdda229134f47a625889fea1be41b7b065c93471abb905f00a80670aa2c5c682915162bd387c09d2bb9ecfe475220da2384daedf6230770727330d68125357fd9b7df3e69ae433ad315f4e575ca9feea23ff8be43bc0",
      },
    ],
  },
  {
    "privateKey":
        "0x09684d63a6fc5ed814bbc6cf36b852ec88b8e320952a18618ca9b60e9ea5acb4",
    "publicKey":
        "0xb35ed7094bc0730495dbab035825675c6fb2b1fe7d99b75c6a47923b08ea1ee55f744096fdcdc50561c081a3ff6273a4",
    "signatures": [
      {
        "message": "0x7b22616d6f756e74223a3130302c22746f223a22616c696365227d",
        "dest":
            "0x424c535f5349475f424c53313233383147325f584d443a5348412d3235365f535357555f524f5f4e554c5f",
        "signature":
            "0x8874edbd202397410200567e38da0d12e91d75230a4e26a91e97c920b4658cb11b72db6f38db10e50072ac2250af8de70def76f542c0bda68d6d86685e423c0ecc64f7948c5f3169d538aabfef977c88c330dc17e64f23218322418ee24a3515",
      },
    ],
  },
  {
    "privateKey":
        "0x5885c13da25da781a2f7d2073ae1ebb94b5241a1307682145263a144bdc4cbd3",
    "publicKey":
        "0xa8ad22dff7856bc7758bac8e397365cf20990a80bdc36d312d71739cface0d0d06d5255a503f35d653f6b301433fe835",
    "signatures": [
      {
        "message":
            "0x3031303230333034303530363037303830393061306230633064306530663130",
        "dest":
            "0x515555582d5630312d435330322d776974682d424c53313233383147325f584d443a5348412d3235365f535357555f524f5f",
        "signature":
            "0x8925b6bf06ac05e91c6b70086266c9378919189596b2dd7a488da4095780d1034f158fd09a91286f2305a9b2d18480ff19904162fe0ad5275cffa1130d0f4cc54d95a6d1fc246a5cdba2b7da239901db30e8232f27ff01c7ff9e4f673db9a1a9",
      },
      {
        "message": "0x68656c6c6f20776f726c64",
        "dest": "0x4d592d4150502d424c532d5349472d5631",
        "signature":
            "0x92322ecd75e8090b343589ea697bdcd413cbef4a7734b74408d0439ad55d0af240fdbc55bc1f7a232cd305c66b64d297145381e2dabe1040c7653b8889ef70a430eadea019736075bddc53e3446c18911f67cc8370904b1d41d02131dd036df0",
      },
    ],
  },
  {
    "privateKey":
        "0x30b7dd1d51707465001918b3bb4e729e387024d2ae3d73ab15e6045edce3eaf2",
    "publicKey":
        "0xb1e27f171ce31f0cf93a23b51c69c3aabf646a03b4e7439c577cf5c8e3edd13998abe1fa1d3dda0ad85485d353c7b920",
    "signatures": [
      {
        "message": "0x68656c6c6f20776f726c64",
        "dest": "0x4d592d4150502d424c532d5349472d5631",
        "signature":
            "0x9022b48cd8ffcdc58bf0ffbc59c7d285783d39a9e765dad23c6b73f08a7fe07df8049cf2d199ba651592c1ed183d98e615991c7b867f1a0f033b91c4a3e0b2ee144294c75d39756bd826c81886681e9c44086f005355f259406bbc13d258d433",
      },
      {
        "message": "0x",
        "dest":
            "0x424c535f5349475f424c53313233383147325f584d443a5348412d3235365f535357555f524f5f4e554c5f",
        "signature":
            "0xa06ba2e8184d0b8858bd27455643301c8e9c7cd980577f022d5a10f7861c538dc80a1b2577c303d5ad89f3e3c5c78f7119547bcdd867ecef6390b7916318675f2e85aefb6615080354523993176ebf04f561c4a7dd90d69e661cca8ea98f52e7",
      },
      {
        "message":
            "0x54686520717569636b2062726f776e20666f78206a756d7073206f76657220746865206c617a7920646f67",
        "dest":
            "0x515555582d5630312d435330322d776974682d424c53313233383147325f584d443a5348412d3235365f535357555f524f5f",
        "signature":
            "0xb2e3d3bf85f4705e62d78e006c06510187242e5ddf2ec06213ee22ee48de7c07a24e65c460d7bb73c4823ed844cf43320425c1712ab6cf9863d259b17370b5d8293dd4ba3e02b76ec68a788837ecff9c221e471844cca34a6e7d6c02ceace7a4",
      },
    ],
  },
  {
    "privateKey":
        "0x3f44e0d6b8fab284a295933960fc824144f4c0c318fcad3ed2cd8f92fb020911",
    "publicKey":
        "0xac2a6485b094c5dc4cdebacb4890de7bd8c3411aa0ff57fbe0f7739ca0f17cc692bf9a34e8fdc3aa8c0ec91c40d5e037",
    "signatures": [
      {
        "message": "0x",
        "dest":
            "0x424c535f5349475f424c53313233383147325f584d443a5348412d3235365f535357555f524f5f4e554c5f",
        "signature":
            "0x95f2d2e0b3b4e1e4774c38f6f476270a83ed4a35a10ceb92bebe414de0ff4801927c3f311d3344fc16057da8ae3a13d91453ff325b22567c47f8c8350378a75d53be2517ab9d6ee05ea257866cd946e9d945f51637e7845d810dc8294ccff00f",
      },
    ],
  },
  {
    "privateKey":
        "0x50ce901839035d1a8874c795306d1cf5d92b9d1d12bf4874ce05faca1a212830",
    "publicKey":
        "0x93312efd983c08d7e711f14aeab69ad1e5fd0c28846a5e72c92adfb3aef33d01aaed49e7fdddd9cac149f802e4a07ffc",
    "signatures": [
      {
        "message":
            "0x54686520717569636b2062726f776e20666f78206a756d7073206f76657220746865206c617a7920646f67",
        "dest":
            "0x515555582d5630312d435330322d776974682d424c53313233383147325f584d443a5348412d3235365f535357555f524f5f",
        "signature":
            "0xb44b604f487447d34b3152cbc67f285ab7fca21b87e75afff354a8c8738fe48098e0bcecfc40a870baf06f8d5f92397a01d8757f99f34523aaca0ee602f7069b1c14219c512d3905d0a64f1be0d5a5ce7243d8657862923df22e3ac05e183fae",
      },
      {
        "message": "0x7b22616d6f756e74223a3130302c22746f223a22616c696365227d",
        "dest": "0x4d592d4150502d424c532d5349472d5631",
        "signature":
            "0x8d0e5d19f14f9ff00d8c0041664b8c39c5e14e50fd10ff5a51691d451d1c4c55a7278af3e67aaa96f0fe3f464324d2830555629749041d3692f6245907cb1aa9bb09c03e50768b3a788ad323922edca94accfbe73c8a43995975fddac0c29c1f",
      },
    ],
  },
  {
    "privateKey":
        "0x54f0d77b1b16081f2da116731cd61f936e2ed6b7d4fad35a4243b7b63940474f",
    "publicKey":
        "0x93190bd0de06bc80bf15f2f52261538660e4baee0629f5fa7e60630c79c30633d87c224a890dd7b1ea6e4d005d7db90c",
    "signatures": [
      {
        "message": "0x7b22616d6f756e74223a3130302c22746f223a22616c696365227d",
        "dest": "0x4d592d4150502d424c532d5349472d5631",
        "signature":
            "0x8041015fbb5616ac5fad0e54452da33b93fa72ab02f713d1b011b514ea0937022be40cf9880d9726e7872ed8223ca859189d994781e007463f1155bb10c8781e456a1c01bf077ab2af4fbab89efdd1de6727d111ab15b47ead910c0ae75d3a8d",
      },
      {
        "message":
            "0x3031303230333034303530363037303830393061306230633064306530663130",
        "dest":
            "0x424c535f5349475f424c53313233383147325f584d443a5348412d3235365f535357555f524f5f4e554c5f",
        "signature":
            "0x88e4fd5de42d3907ab689ed4641b0769bf2d7209456a31085c5f712964f05a3f12d13e74e060c5a2dd271b0a647973b006da319bc503deaf6dbaa23aef534ed458819809f974f2d46c641f4366bf250af0102a9687954f696df2b51c729a0684",
      },
      {
        "message": "0x68656c6c6f20776f726c64",
        "dest":
            "0x515555582d5630312d435330322d776974682d424c53313233383147325f584d443a5348412d3235365f535357555f524f5f",
        "signature":
            "0x87deea3b74ecdea189656fee4334eed5318aca6025b2a91ea64c8a1661c9ad5c972e9ad766d0e2d4f01fb0dfd8d3c28a163e8e3b61e72d689032804c84b68d0bbc37515e2b548904102c27898f01a8664e2eed844115a99e05c82553e1304040",
      },
    ],
  },
  {
    "privateKey":
        "0x3121a502edd9d38088a349a3175de059dc0990357048e10e07fda2ed585f666e",
    "publicKey":
        "0xaee18355452458af81246f57f5e837637404b50111b6975228419ad26e15f0f0778fbceea31fd8da7649023e3305ef00",
    "signatures": [
      {
        "message":
            "0x3031303230333034303530363037303830393061306230633064306530663130",
        "dest":
            "0x424c535f5349475f424c53313233383147325f584d443a5348412d3235365f535357555f524f5f4e554c5f",
        "signature":
            "0x8403c061a20737693c1e77884cbccffa4e847fafc7e1d269859915bc7226c9b6dfc2bfd46c706b58d6c180b9a3d0198b09dad18eedd175c41409286bc6d82f4f7c8bc04bc365860b75232d7e27bff6a31ba7fa48e41ca4bff0e0a555fcde60ab",
      },
    ],
  },
  {
    "privateKey":
        "0x0d52728ac09d9ee1e3a57bd210e4a0214ae54ab30b96eec1cdb78e24777e858d",
    "publicKey":
        "0xa55ddd9e7af05527e2f15d9dfbc85eaf2e5fd0157841f7e9cccbdf431fee02d6bfd00d32807f7f87a663db10cff8ee49",
    "signatures": [
      {
        "message": "0x68656c6c6f20776f726c64",
        "dest":
            "0x515555582d5630312d435330322d776974682d424c53313233383147325f584d443a5348412d3235365f535357555f524f5f",
        "signature":
            "0xa5bf6c66f242dbe71420918929e25f8c8c23dc9a23cf685f8f9b80cfb75594ffd426c70a83150a605c8a13a26c4c83cb17d5096fb01b208a06945b890402a95c560d0fc4affaf44be2bda586da1c94b36939688e4d39e27f62ba2ee329165d04",
      },
      {
        "message": "0x",
        "dest": "0x4d592d4150502d424c532d5349472d5631",
        "signature":
            "0xa177ab404d005a75ebcfb14e59d549dfd3b43b541a2d7aacbe0c7e548beaaa25508a36426295d67769db4547e7ff203e0b84cfe4a5ce3bd61bf26169307a57357e48947e28c792eb4f8619d861468bd91b61b81d0444e173fc17637d698480ab",
      },
    ],
  },
  {
    "privateKey":
        "0x5d70e765bcfee68a70e0870a150e38ee0d7ea933a6e358749371795a969da4ac",
    "publicKey":
        "0x97ff4375b3ba89e546fa395544221ace0f7cd15bf9cc0848c2c0fbf7de2318a734e8b2db248fd5f2cf895c18669d838f",
    "signatures": [
      {
        "message": "0x",
        "dest": "0x4d592d4150502d424c532d5349472d5631",
        "signature":
            "0x8623807e061492e8d3e922f61feab83e1ec53a1036c52abd89491273d971da726b2c0dd9a9f246ebfb21caef06590eb4001f50447bf96bbc7cbe18d90c203ea1370400e506f9dcecb580c9796dea0387f9f31ac913dd9e3a28ff5f7941508124",
      },
      {
        "message":
            "0x54686520717569636b2062726f776e20666f78206a756d7073206f76657220746865206c617a7920646f67",
        "dest":
            "0x424c535f5349475f424c53313233383147325f584d443a5348412d3235365f535357555f524f5f4e554c5f",
        "signature":
            "0x8ed2bf68d6ad75845fc6441e70e44cb4ebb16166280975a50fd2e2adb8e6b3cb5e83396f7c8a4430922e803a463f3b4b073460c2ae0274bc773fb1a49639e3c727decdf29985d6ce72483d00a58da0a128c7e21a69c321c1d277bcb42023a7c3",
      },
      {
        "message": "0x7b22616d6f756e74223a3130302c22746f223a22616c696365227d",
        "dest":
            "0x515555582d5630312d435330322d776974682d424c53313233383147325f584d443a5348412d3235365f535357555f524f5f",
        "signature":
            "0x9383374ac16a14b48450897b62382da8e0e4d99ffb105bdb17b9aea8a8049176b354036303132147b472ca343ed19c90195ddbe4e70237ae8cb7ccb1334048403fee2f520fd64b9bb9c86c800c5aec684827ff550d2a9ba11fa026ddb8a0c389",
      },
    ],
  },
  {
    "privateKey":
        "0x39a1b3ec8ec1b1ebcbe2ba3a0f95f9b57c5a63b142316628592b6491b5bcc3cb",
    "publicKey":
        "0x8fc80bd4af9e2cec420a93ca0f59915629fda7d73742d918395b475b77c5b666e87701264f151bee0b48a56d07fccc44",
    "signatures": [
      {
        "message":
            "0x54686520717569636b2062726f776e20666f78206a756d7073206f76657220746865206c617a7920646f67",
        "dest":
            "0x424c535f5349475f424c53313233383147325f584d443a5348412d3235365f535357555f524f5f4e554c5f",
        "signature":
            "0xb64f51f84d70bcb388a5e134bb80a4c330128347e0e6752d289be9bfd99dc31a7d420b8f2c1370d0d268aeeb169230e4181ebbabd9f6b65f810d6325ade8549e59f65daa6fcb599ce95e5895c7174a87e554e9306db94e52c3b2659a9d2ae56f",
      },
    ],
  },
  {
    "privateKey":
        "0x08ab96ce4daaf51d7b197f049d8c49ca6e37e4c33a621c541ee31840d4dbe2ea",
    "publicKey":
        "0x88a5ca54b2351dc32eb33b069fd2b74c60839efe8bdb12a2021a7f86b48d8406bd1de022faa6ddbcbda6eb338075709d",
    "signatures": [
      {
        "message": "0x7b22616d6f756e74223a3130302c22746f223a22616c696365227d",
        "dest":
            "0x515555582d5630312d435330322d776974682d424c53313233383147325f584d443a5348412d3235365f535357555f524f5f",
        "signature":
            "0x896fc39e7d4ecd6b5499828d9bd0a9c77f17c830c3c66c8f26d6e04264bd55707c5436ea342c7ec056c5bb448b58a5180833d3d45f0c7a68e27aadcf267088c4fa2f6e55074a3f28a1f57cd1df46cbc6836ea818d26fcf0dd21db4a5114b497c",
      },
      {
        "message":
            "0x3031303230333034303530363037303830393061306230633064306530663130",
        "dest": "0x4d592d4150502d424c532d5349472d5631",
        "signature":
            "0x889cfd261d4832a4b767809b9ab7aafd22e1e9c1d8280b83b5cfae2793f9391651911746a73b759c443e5af811ac60ca18a80dbe4b020c9ba9ff8fd7ca910e9e4c6bef011e4f8e9940a7f41ce5a72fc8c02053f07b8cd94132f83610417d2ffa",
      },
    ],
  },
  {
    "privateKey":
        "0x57a09ee982242bc1ef0356fbdf44235dfc73b3393f7dfc1ec7943116f3fa0109",
    "publicKey":
        "0xb03ef89e3f57768a0ddac8a181383ba3f0dccbe13bc7b4c51152d029060a1933b9452be8afe26d62e880a977f5cbb38c",
    "signatures": [
      {
        "message":
            "0x3031303230333034303530363037303830393061306230633064306530663130",
        "dest": "0x4d592d4150502d424c532d5349472d5631",
        "signature":
            "0xa7cfd09c92f9d677c74dff5496971bfefa6f088cd846596211a7a40d7c6c03dfa5b564ac0ab8328975e1e9aff64641610571d451e89ad4c52d5eb0627fcab96af78eb8b0c7609e441f040294ed0258bf4b93ed340f6a691db59a7ded6ccc350c",
      },
      {
        "message": "0x68656c6c6f20776f726c64",
        "dest":
            "0x424c535f5349475f424c53313233383147325f584d443a5348412d3235365f535357555f524f5f4e554c5f",
        "signature":
            "0x880fcc0414c9ab69442fd40d09113920b62a4ac09c407754c75f40c6ff6d3a95c8914d6e662084e0b97c2ceacb8209a317d9517681f809e30c61e5f810ab39db84e78c2f6bf2c02258b37429b6017a9c2e969681cbd1518fed0ecc7eb591943a",
      },
      {
        "message": "0x",
        "dest":
            "0x515555582d5630312d435330322d776974682d424c53313233383147325f584d443a5348412d3235365f535357555f524f5f",
        "signature":
            "0x80cce976b2986d3dccde67aaf34aef63d75927b0dd1175a9262587c52e7e85738c5f0d8daf8e3e4fa4cdedbd6ddcd51d0a0939abb23b058ef60e1c9e05c3332f22e1045e9194269d9ee29bcfd6c70021168a2d403a30cf7d3ebad08e30231ef2",
      },
    ],
  },
  {
    "privateKey":
        "0x347ab2fa61bed97fc6c3a1050daa6ed75dc8867cba2a7cbc0e839ace12192028",
    "publicKey":
        "0xb566d3abf174704ca5c83f334301170b9d3ba74062f7251b65db0a41bb3c1cf23d4bbb38c88842619a8683677fb23318",
    "signatures": [
      {
        "message": "0x68656c6c6f20776f726c64",
        "dest":
            "0x424c535f5349475f424c53313233383147325f584d443a5348412d3235365f535357555f524f5f4e554c5f",
        "signature":
            "0x931705f17b7f2480d061bc78c9f8ee97aad68acf7d6b99db05329f461a8a22862a1100215d804062987162880621b2510f268c6769011cd4958ceb12b60fc644189bcf8198f499570408b4e5f7331e112cd2523698b5d187491f46a80232b1a9",
      },
    ],
  },
];
