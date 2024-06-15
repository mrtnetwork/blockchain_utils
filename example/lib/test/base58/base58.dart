import 'package:blockchain_utils/base58/base58.dart';
import 'package:example/test/quick_hex.dart';
import 'package:blockchain_utils/utils/utils.dart';

final List<Map<String, String>> testVectBtc = [
  {"raw": "", "encode": "", "check_encode": "3QJmnh"},
  {"raw": "61", "encode": "2g", "check_encode": "C2dGTwc"},
  {"raw": "626262", "encode": "a3gV", "check_encode": "4jF5uERJAK"},
  {"raw": "636363", "encode": "aPEr", "check_encode": "4mT4krqUYJ"},
  {
    "raw": "73696d706c792061206c6f6e6720737472696e67",
    "encode": "2cFupjhnEsSn59qHXstmK2ffpLv2",
    "check_encode": "BXF1HuEUCqeVzZdrKeJjG74rjeXxqJ7dW"
  },
  {
    "raw": "00eb15231dfceb60925886b67d065299925915aeb172c06647",
    "encode": "1NS17iag9jJgTHD1VXjvLCEnZuQ3rJDE9L",
    "check_encode": "13REmUhe2ckUKy1FvM7AMCdtyYq831yxM3QeyEu4"
  },
  {"raw": "516b6fcd0f", "encode": "ABnLTmg", "check_encode": "237LSrY9NUUas"},
  {
    "raw": "bf4f89001e670274dd",
    "encode": "3SEo3LWLoPntC",
    "check_encode": "GwDDDeduj1jpykc27e"
  },
  {"raw": "572e4794", "encode": "3EFU7m", "check_encode": "FamExfqCeza"},
  {
    "raw": "ecac89cad93923c02321",
    "encode": "EJDM8drfXA6uyA",
    "check_encode": "2W1Yd5Zu6WGyKVtHGMrH"
  },
  {"raw": "10c8511e", "encode": "Rt5zm", "check_encode": "3op3iuGMmhs"},
  {
    "raw": "00000000000000000000",
    "encode": "1111111111",
    "check_encode": "111111111146Momb"
  },
  {
    "raw":
        "000111d38e5fc9071ffcd20b4a763cc9ae4f252bb4e48fd66a835e252ada93ff480d6dd43dc62a641155a5",
    "encode": "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz",
    "check_encode":
        "17mxz9b2TuLnDf6XyQrHjAc3UvMoEg7YzRsJkBd4VwNpFh8a1StKmCe5WtAW27Y"
  },
  {
    "raw":
        "000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132333435363738393a3b3c3d3e3f404142434445464748494a4b4c4d4e4f505152535455565758595a5b5c5d5e5f606162636465666768696a6b6c6d6e6f707172737475767778797a7b7c7d7e7f808182838485868788898a8b8c8d8e8f909192939495969798999a9b9c9d9e9fa0a1a2a3a4a5a6a7a8a9aaabacadaeafb0b1b2b3b4b5b6b7b8b9babbbcbdbebfc0c1c2c3c4c5c6c7c8c9cacbcccdcecfd0d1d2d3d4d5d6d7d8d9dadbdcdddedfe0e1e2e3e4e5e6e7e8e9eaebecedeeeff0f1f2f3f4f5f6f7f8f9fafbfcfdfeff",
    "encode":
        "1cWB5HCBdLjAuqGGReWE3R3CguuwSjw6RHn39s2yuDRTS5NsBgNiFpWgAnEx6VQi8csexkgYw3mdYrMHr8x9i7aEwP8kZ7vccXWqKDvGv3u1GxFKPuAkn8JCPPGDMf3vMMnbzm6Nh9zh1gcNsMvH3ZNLmP5fSG6DGbbi2tuwMWPthr4boWwCxf7ewSgNQeacyozhKDDQQ1qL5fQFUW52QKUZDZ5fw3KXNQJMcNTcaB723LchjeKun7MuGW5qyCBZYzA1KjofN1gYBV3NqyhQJ3Ns746GNuf9N2pQPmHz4xpnSrrfCvy6TVVz5d4PdrjeshsWQwpZsZGzvbdAdN8MKV5QsBDY",
    "check_encode":
        "151KWPPBRzdWPr1ASeu172gVgLf1YfUp6VJyk6K9t4cLqYtFHcMa2iX8S3NJEprUcW7W5LvaPRpz7UG7puBj5STE3nKhCGt5eckYq7mMn5nT7oTTic2BAX6zDdqrmGCnkszQkzkz8e5QLGDjf7KeQgtEDm4UER6DMSdBjFQVa6cHrrJn9myVyyhUrsVnfUk2WmNFZvkWv3Tnvzo2cJ1xW62XDfUgYz1pd97eUGGPuXvDFfLsBVd1dfdUhPwxW7pMPgdWHTmg5uqKGFF6vE4xXpAqZTbTxRZjCDdTn68c2wrcxApm8hq3JX65Hix7VtcD13FF8b7BzBtwjXq1ze6NMjKgUcqpGV5XA5"
  }
];

var testVectXrp = [
  {"raw": "", "encode": "", "check_encode": "sQJm86"},
  {"raw": "61", "encode": "pg", "check_encode": "UpdGTAc"},
  {"raw": "626262", "encode": "2sgV", "check_encode": "hjEnuNRJwK"},
  {"raw": "636363", "encode": "2PNi", "check_encode": "hmThkiq7YJ"},
  {
    "raw": "73696d706c792061206c6f6e6720737472696e67",
    "encode": "pcEuFj68N1S8n9qHX1tmKpCCFLvp",
    "check_encode": "BXErHuN7UqeVzZdiKeJjGfhijeXxqJfdW"
  },
  {
    "raw": "00eb15231dfceb60925886b67d065299925915aeb172c06647",
    "encode": "r4Srf52g9jJgTHDrVXjvLUN8ZuQsiJDN9L",
    "check_encode": "rsRNm76epck7KyrEvMfwMUdtyYq3sryxMsQeyNuh"
  },
  {"raw": "516b6fcd0f", "encode": "wB8LTmg", "check_encode": "psfLSiY947721"},
  {
    "raw": "bf4f89001e670274dd",
    "encode": "sSNosLWLoP8tU",
    "check_encode": "GADDDedujrjFykcpfe"
  },
  {"raw": "572e4794", "encode": "sNE7fm", "check_encode": "E2mNxCqUez2"},
  {
    "raw": "ecac89cad93923c02321",
    "encode": "NJDM3diCXwauyw",
    "check_encode": "pWrYdnZuaWGyKVtHGMiH"
  },
  {"raw": "10c8511e", "encode": "Rtnzm", "check_encode": "soFs5uGMm61"},
  {
    "raw": "00000000000000000000",
    "encode": "rrrrrrrrrr",
    "check_encode": "rrrrrrrrrrhaMomb"
  },
  {
    "raw":
        "000111d38e5fc9071ffcd20b4a763cc9ae4f252bb4e48fd66a835e252ada93ff480d6dd43dc62a641155a5",
    "encode": "rpshnaf39wBUDNEGHJKLM4PQRST7VWXYZ2bcdeCg65jkm8oFqi1tuvAxyz",
    "check_encode":
        "rfmxz9bpTuL8DCaXyQiHjwcs7vMoNgfYzR1JkBdhVA4FE632rStKmUenWtwWpfY"
  },
  {
    "raw":
        "000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132333435363738393a3b3c3d3e3f404142434445464748494a4b4c4d4e4f505152535455565758595a5b5c5d5e5f606162636465666768696a6b6c6d6e6f707172737475767778797a7b7c7d7e7f808182838485868788898a8b8c8d8e8f909192939495969798999a9b9c9d9e9fa0a1a2a3a4a5a6a7a8a9aaabacadaeafb0b1b2b3b4b5b6b7b8b9babbbcbdbebfc0c1c2c3c4c5c6c7c8c9cacbcccdcecfd0d1d2d3d4d5d6d7d8d9dadbdcdddedfe0e1e2e3e4e5e6e7e8e9eaebecedeeeff0f1f2f3f4f5f6f7f8f9fafbfcfdfeff",
    "encode":
        "rcWBnHUBdLjwuqGGReWNsRsUguuASjAaRH8s91pyuDRTSn41Bg45EFWgw8NxaVQ53c1exkgYAsmdYiMHi3x95f2NAP3kZfvccXWqKDvGvsurGxEKPuwk83JUPPGDMCsvMM8bzma469z6rgc41MvHsZ4LmPnCSGaDGbb5ptuAMWPt6ihboWAUxCfeASg4Qe2cyoz6KDDQQrqLnCQE7WnpQK7ZDZnCAsKX4QJMc4Tc2BfpsLc6jeKu8fMuGWnqyUBZYzwrKjoC4rgYBVs4qy6QJs41fhaG4uC94pFQPmHzhxF8SiiCUvyaTVVzndhPdije161WQAFZ1ZGzvbdwd43MKVnQ1BDY",
    "check_encode":
        "rnrKWPPBRzdWPirwSeurfpgVgLCrYC7FaVJykaK9thcLqYtEHcM2p5X3Ss4JNFi7cWfWnLv2PRFzf7GfFuBjnSTNs8K6UGtneckYqfmM8n8TfoTT5cpBwXazDdqimGU8k1zQkzkz3enQLGDjCfKeQgtNDmh7NRaDMSdBjEQV2acHiiJ89myVyy67i1V8C7kpWm4EZvkWvsT8vzopcJrxWapXDC7gYzrFd9fe7GGPuXvDECL1BVdrdCd76PAxWfFMPgdWHTmgnuqKGEEavNhxXFwqZTbTxRZjUDdT8a3cpAicxwFm36qsJXanH5xfVtcDrsEE3bfBzBtAjXqrzea4MjKg7cqFGVnXwn"
  }
];

void testBase58() {
  for (final i in testVectBtc) {
    final decode = Base58Decoder.decode(i["encode"]!);
    assert(decode.toHex() == i["raw"]);
    final decodeCheck = Base58Decoder.checkDecode(i["check_encode"]!);
    assert(decodeCheck.toHex() == i["raw"]);
  }
  for (final i in testVectBtc) {
    final encode = Base58Encoder.encode(BytesUtils.fromHexString(i["raw"]!));
    final encodeCheck =
        Base58Encoder.checkEncode(BytesUtils.fromHexString(i["raw"]!));
    assert(i["check_encode"] == encodeCheck);
    assert(i["encode"] == encode);
  }
  for (final i in testVectXrp) {
    final decode = Base58Decoder.decode(i["encode"]!, Base58Alphabets.ripple);
    assert(decode.toHex() == i["raw"]);
    final decodeCheck =
        Base58Decoder.checkDecode(i["check_encode"]!, Base58Alphabets.ripple);
    assert(decodeCheck.toHex() == i["raw"]);
  }
  for (final i in testVectXrp) {
    final encode = Base58Encoder.encode(
        BytesUtils.fromHexString(i["raw"]!), Base58Alphabets.ripple);
    assert(i["encode"] == encode);

    final encodeCheck = Base58Encoder.checkEncode(
        BytesUtils.fromHexString(i["raw"]!), Base58Alphabets.ripple);
    assert(i["check_encode"] == encodeCheck);
  }
}
