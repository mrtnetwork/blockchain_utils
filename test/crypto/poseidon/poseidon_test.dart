// ignore_for_file: non_constant_identifier_names

import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:blockchain_utils/numbers/src/u64.dart';
import 'package:test/test.dart';

void main() {
  // return;
  group("poseidon", () {
    test("Hash Fq constants", _hashFqWithConstants);
    test("Hash Fq", _hashFq);
    test("Hash Fq Native", _hashNativeFq);
    test("Grain", _grain);
    test("Mds", _mds);
    test("Mds native", _mdsNative);
    test("Hash Fp", _hashFp);
    test("Hash native Fp", _hashFpNative);
    test("Permute Fp", _permute);
    test("Permute native Fp", _permuteNative);
    _testConstants();
    _testConstantsNative();
    _testConstantsNativeFq();
  });
}

void _permuteNative() {
  final spec = P128Pow5T3NativeFp();
  for (final i in _poseidon) {
    final inputs = JsonParser.valueEnsureAsList<String>(i.elementAt(0));
    final outputs = JsonParser.valueEnsureAsList<String>(i.elementAt(1));
    final state =
        inputs
            .map((e) => PallasNativeFp.fromBytes(BytesUtils.fromHexString(e)))
            .toList();
    PoseidonUtils.permute(state, spec);
    final outputsFields =
        outputs
            .map((e) => PallasNativeFp.fromBytes(BytesUtils.fromHexString(e)))
            .toList();
    for (var e in state.indexed) {
      expect(e.$2, outputsFields[e.$1]);
    }
  }
}

void _permute() {
  final spec = P128Pow5T3Fp();
  for (final i in _poseidon) {
    final inputs = JsonParser.valueEnsureAsList<String>(i.elementAt(0));
    final outputs = JsonParser.valueEnsureAsList<String>(i.elementAt(1));
    final state =
        inputs
            .map((e) => PallasFp.fromBytes(BytesUtils.fromHexString(e)))
            .toList();
    PoseidonUtils.permute(state, spec);
    final outputsFields =
        outputs
            .map((e) => PallasFp.fromBytes(BytesUtils.fromHexString(e)))
            .toList();
    for (var e in state.indexed) {
      expect(e.$2, outputsFields[e.$1]);
    }
  }
}

void _mds() {
  final int size = 3;
  final Grain<PallasFp> grain = Grain(
    sbox: SboxType.pow,
    t: size,
    rF: 8,
    rP: 86,
    fromBytes: (bytes) {
      if (bytes.length == 32) return PallasFp.fromBytes(bytes);
      return PallasFp.fromBytes64(bytes);
    },
  );
  final mds = PoseidonUtils.generateMds(
    grain,
    size,
    0,
    PallasFp.one,
    PallasFp.zero,
  );
  for (int i = 0; i < size; i++) {
    for (int j = 0; j < size; j++) {
      final exp = i == j ? PallasFp.one : PallasFp.zero;
      // final result = [0, 1, 2].fold(PallasFp.zero, (acc, k) => acc + (mds.$1.fields[i][k] * mds.$2.fields[k][j]));
      // assert(exp == result);
      PallasFp sum = PallasFp.zero;
      for (int k = 0; k < size; k++) {
        sum = sum + (mds.mds[i][k] * mds.mdsInv[k][j]);
      }
      expect(exp, sum);
    }
  }
}

void _mdsNative() {
  final int size = 3;
  final Grain<PallasNativeFp> grain = Grain(
    sbox: SboxType.pow,
    fromBytes: (bytes) {
      if (bytes.length == 32) return PallasNativeFp.fromBytes(bytes);
      return PallasNativeFp.fromBytes64(bytes);
    },
    t: size,
    rF: 8,
    rP: 86,
  );
  final mds = PoseidonUtils.generateMds(
    grain,
    size,
    0,
    PallasNativeFp.one(),
    PallasNativeFp.zero(),
  );
  for (int i = 0; i < size; i++) {
    for (int j = 0; j < size; j++) {
      final exp = i == j ? PallasNativeFp.one() : PallasNativeFp.zero();
      // final result = [0, 1, 2].fold(PallasFp.zero, (acc, k) => acc + (mds.$1.fields[i][k] * mds.$2.fields[k][j]));
      // assert(exp == result);
      PallasNativeFp sum = PallasNativeFp.zero();
      for (int k = 0; k < size; k++) {
        sum = sum + (mds.mds[i][k] * mds.mdsInv[k][j]);
      }
      expect(exp, sum);
    }
  }
}

void _grain() {
  //
  for (final i in _grainTestVector) {
    final sbox = switch (i["sbox"]) {
      0 => SboxType.pow,
      _ => SboxType.inv,
    };
    final Grain grain = Grain<PallasFp>(
      sbox: sbox,
      t: i["t"],
      fromBytes: (bytes) {
        if (bytes.length == 32) return PallasFp.fromBytes(bytes);
        return PallasFp.fromBytes64(bytes);
      },
      rF: i["r_f"],
      rP: i["r_p"],
    );
    final List trys = i["try"];
    for (final i in trys) {
      final f = grain.nextFieldElement();
      expect(
        i,
        BytesUtils.toHexString(f.toBytes().reversed.toList(), prefix: "0x"),
      );
    }
  }
  for (final i in _grainWithoutRejectionTestVector) {
    final sbox = switch (i["sbox"]) {
      0 => SboxType.pow,
      _ => SboxType.inv,
    };
    final Grain grain = Grain<PallasFp>(
      sbox: sbox,
      t: i["t"],
      fromBytes: (bytes) {
        if (bytes.length == 32) return PallasFp.fromBytes(bytes);
        return PallasFp.fromBytes64(bytes);
      },
      rF: i["r_f"],
      rP: i["r_p"],
    );
    final List trys = i["try"];
    for (final i in trys) {
      final f = grain.nextFieldElementWithoutRejection();
      expect(
        i,
        BytesUtils.toHexString(f.toBytes().reversed.toList(), prefix: "0x"),
      );
    }
  }
}

void _hashFp() {
  for (final i in _testVector) {
    final inputs = JsonParser.valueEnsureAsList<String>(i.elementAt(0));
    final output = PallasFp.fromBytes(
      BytesUtils.fromHexString(JsonParser.valueAs<String>(i.elementAt(1))),
    );
    final messages =
        inputs
            .map(
              (e) => PallasFp.fromBytes(BytesUtils.fromHexString(e).toList()),
            )
            .toList();
    final p = P128Pow5T3Fp();
    final hasher = PoseidonHash<PallasFp>(p);
    final result = hasher.hash(messages);
    expect(result, output);
  }
}

void _hashFpNative() {
  for (final i in _testVector) {
    final inputs = JsonParser.valueEnsureAsList<String>(i.elementAt(0));
    final output = PallasNativeFp.fromBytes(
      BytesUtils.fromHexString(JsonParser.valueAs<String>(i.elementAt(1))),
    );
    final messages =
        inputs
            .map(
              (e) => PallasNativeFp.fromBytes(
                BytesUtils.fromHexString(e).toList(),
              ),
            )
            .toList();
    final p = P128Pow5T3NativeFp();
    final hasher = PoseidonHash<PallasNativeFp>(p);
    final result = hasher.hash(messages);
    expect(result, output);
  }
}

void _hashFq() {
  for (final i in _hashFqTestVector) {
    final inputs = [i[0], i[1]];
    final output = VestaFq.fromBytes(BytesUtils.fromHexString(i.elementAt(2)));
    final messages =
        inputs
            .map((e) => VestaFq.fromBytes(BytesUtils.fromHexString(e).toList()))
            .toList();
    final p = P128Pow5T3Fq();
    final hasher = PoseidonHash<VestaFq>(p);
    final result = hasher.hash(messages);
    expect(result, output);
  }
}

void _hashFqWithConstants() {
  for (final i in _hashFqTestVector) {
    final inputs = [i[0], i[1]];
    final output = VestaFq.fromBytes(BytesUtils.fromHexString(i.elementAt(2)));
    final messages =
        inputs
            .map((e) => VestaFq.fromBytes(BytesUtils.fromHexString(e).toList()))
            .toList();
    final p = P128Pow5T3Fq(
      constants: MdsGenerateResult(
        mds: _PoseidonFQConstants.mds,
        mdsInv: _PoseidonFQConstants.mdsInv,
        constants: _PoseidonFQConstants.roundConstants,
      ),
    );
    final hasher = PoseidonHash<VestaFq>(p);
    final result = hasher.hash(messages);
    expect(result, output);
  }
}

void _hashNativeFq() {
  for (final i in _hashFqTestVector) {
    final inputs = [i[0], i[1]];
    final output = VestaNativeFq.fromBytes(
      BytesUtils.fromHexString(i.elementAt(2)),
    );
    final messages =
        inputs
            .map(
              (e) =>
                  VestaNativeFq.fromBytes(BytesUtils.fromHexString(e).toList()),
            )
            .toList();
    final p = P128Pow5T3NativeFq();
    final hasher = PoseidonHash<VestaNativeFq>(p);
    final result = hasher.hash(messages);
    expect(result, output);
  }
}

void _testConstants() {
  test("generate constant", () {
    final r = PoseidonUtils.generateConstants(
      fromBytes: (bytes) {
        if (bytes.length == 32) return PallasFp.fromBytes(bytes);
        return PallasFp.fromBytes64(bytes);
      },
      zero: PallasFp.zero,
      one: PallasFp.one,
    );
    final rounts = _PoseidonFPConstants.roundConstants;
    for (final i in r.constants.indexed) {
      final exp = rounts.elementAt(i.$1);
      for (final fp in i.$2.indexed) {
        expect(exp.elementAt(fp.$1).toBytes(), fp.$2.toBytes());
      }
    }
    final mds = _PoseidonFPConstants.mds;
    for (final i in r.mds.indexed) {
      final exp = mds.elementAt(i.$1);
      for (final fp in i.$2.indexed) {
        expect(exp.elementAt(fp.$1).toBytes(), fp.$2.toBytes());
      }
    }
    final mdsInv = _PoseidonFPConstants.mdsInv;
    for (final i in r.mdsInv.indexed) {
      final exp = mdsInv.elementAt(i.$1);
      for (final fp in i.$2.indexed) {
        expect(exp.elementAt(fp.$1).toBytes(), fp.$2.toBytes());
      }
    }
  });
}

void _testConstantsNative() {
  test("generate constant", () {
    final r = PoseidonUtils.generateConstants(
      fromBytes: (bytes) {
        if (bytes.length == 32) return PallasNativeFp.fromBytes(bytes);
        return PallasNativeFp.fromBytes64(bytes);
      },
      zero: PallasNativeFp.zero(),
      one: PallasNativeFp.one(),
    );
    final rounts = _PoseidonFPConstants.roundConstants;
    for (final i in r.constants.indexed) {
      final exp = rounts.elementAt(i.$1);
      for (final fp in i.$2.indexed) {
        expect(exp.elementAt(fp.$1).toBytes(), fp.$2.toBytes());
      }
    }
    final mds = _PoseidonFPConstants.mds;
    for (final i in r.mds.indexed) {
      final exp = mds.elementAt(i.$1);
      for (final fp in i.$2.indexed) {
        expect(exp.elementAt(fp.$1).toBytes(), fp.$2.toBytes());
      }
    }
    final mdsInv = _PoseidonFPConstants.mdsInv;
    for (final i in r.mdsInv.indexed) {
      final exp = mdsInv.elementAt(i.$1);
      for (final fp in i.$2.indexed) {
        expect(exp.elementAt(fp.$1).toBytes(), fp.$2.toBytes());
      }
    }
  });
}

void _testConstantsNativeFq() {
  test("generate constant", () {
    final r = PoseidonUtils.generateConstants(
      fromBytes: (bytes) {
        if (bytes.length == 32) return VestaNativeFq.fromBytes(bytes);
        return VestaNativeFq.fromBytes64(bytes);
      },
      zero: VestaNativeFq.zero(),
      one: VestaNativeFq.one(),
    );
    final rounts = _PoseidonFQConstants.roundConstants;
    for (final i in r.constants.indexed) {
      final exp = rounts.elementAt(i.$1);
      for (final fp in i.$2.indexed) {
        expect(exp.elementAt(fp.$1).toBytes(), fp.$2.toBytes());
      }
    }
    final mds = _PoseidonFQConstants.mds;
    for (final i in r.mds.indexed) {
      final exp = mds.elementAt(i.$1);
      for (final fp in i.$2.indexed) {
        expect(exp.elementAt(fp.$1).toBytes(), fp.$2.toBytes());
      }
    }
    final mdsInv = _PoseidonFQConstants.mdsInv;
    for (final i in r.mdsInv.indexed) {
      final exp = mdsInv.elementAt(i.$1);
      for (final fp in i.$2.indexed) {
        expect(exp.elementAt(fp.$1).toBytes(), fp.$2.toBytes());
      }
    }
  });
}

const _testVector = [
  [
    [
      "0000000000000000000000000000000000000000000000000000000000000000",
      "0100000000000000000000000000000000000000000000000000000000000000",
    ],
    "8358d711a0329d38becd54fba7c283ed3e089a39c91b6a9d10efb02bc3f12f06",
  ],
  [
    [
      "5c7a8f73adfc70fb3f139449ac6b57074c4d6e66b164939daffa2ef6ee692108",
      "1add86b3f2e1bda62a5d2e0e982b77e6b0ef9ca3f24988c7b3534201cfb1cd0d",
    ],
    "db2675ff3ef8fe30c4d5de61cac02a8ef1a08523be92394b79d26726303be603",
  ],
  [
    [
      "bd69b82532b6940ff2590f679ba9c7271fe01f7e9c8e36d6a5e29d4e30a73514",
      "bc50984255d6afbe9ef92848ed5ac00862c2fa7b2fecbcb64b6968912a63810e",
    ],
    "f5121d1e1d5cfe8da896ac0f9c183d760031f6ef8c7a41e65eb007cddc1d143d",
  ],
  [
    [
      "3dc166d56a1d62f5a8d7551db5fd9313e8c7203d996af7d477083756d59af80d",
      "05a745f45d7ff6db10bc67fdf0f03ebf8130ab33362697b0e4e4c763ccb8f636",
    ],
    "a416a5e7135136a05056900058fa50bf186ad73390ace6323d8d81aa8adbd411",
  ],
  [
    [
      "495c222f7fba1e31defa3d5a57efc2e1e9b01a035587d5fb1a38e01d94903d3c",
      "3d0ad3361fec097790d9be0e42988d7d25c9a138f49b1a537edcf04be34a9811",
    ],
    "1abaf306fed05fa892848c49f6ba104163433f3f633108a13bc15b2a1d55d40c",
  ],
  [
    [
      "a4af9db6d27b5072835f0c3e88395ed7a41b0052ad8084a8b9da948d320dad16",
      "4d5431e6437d0b5bedbbcdaf345b86c4121fc00fe7f235734276d38d47f1e111",
    ],
    "04a18aeb593f790b76a399b7c1528acdede93b3b2c496bd71bd587cbd7cfdf35",
  ],
  [
    [
      "dd0c7a1d811c7d9cd46d377b3fdeab3fb679f3dc601d008285edcbdae69ce83c",
      "19e4aac0359017ec85a183d22053db33f73476f21a482ec9378365c8f7393c14",
    ],
    "1103ccdc00d0f35f658314116bc2bcd94374a91ff9877e70663329042bd2f61f",
  ],
  [
    [
      "e2885315eb4671098b79535e790fe53e29fef2b3766697ac32b4f473f468a008",
      "e62389fc1657e0def0b632c6ae25f9f783b27db59a4a153d882d2b2103596515",
    ],
    "f8f8c65f437c45beac11eb7d9e47586d879afd6f930435be0c01d19c895b8d10",
  ],
  [
    [
      "eb9494c6d227e2163b4699d991f433bf9486a7afcf4a0d9c731e985d99589c0b",
      "b738e8aa0a1526a5bdef613120372e831a20da8aba18d1dbebbc862ded42431e",
    ],
    "5aeb489621b02e8e6927b94fd29a610183df7f4287e9cbf1ccc881d7d0b73827",
  ],
  [
    [
      "91476930e3385cd3e3379e3853d93467e001afa2fb8dc3436d75a4a6f2657210",
      "4b192232ecb9f0c02411e52596bc5e90457e745939ffedbd12863ce71a02af11",
    ],
    "b0144720f5f2a25d492a504ec0737f097ed852174f55f5863091306c1af20035",
  ],
  [
    [
      "7b417adb63b37122a5bf62d26f1e7f268fb86b12b56da9c382857deecc40a90d",
      "5e29353971b34994b621b0b261aeb3786dd984d567db2857b927b7fae2db5831",
    ],
    "bbbeb742d6e7c01adbf4d3855e35fec462043089c18ba80290647bb0e581ad11",
  ],
];
const List<Map<String, dynamic>> _grainTestVector = [
  {
    "sbox": 0,
    "t": 4,
    "r_f": 16,
    "r_p": 4,
    "try": [
      "0x1facd0789b57ee1b1cab8de7840805f1c0060a872f0f822795a25f1ac4e65a9b",
    ],
  },
  {
    "sbox": 0,
    "t": 7,
    "r_f": 14,
    "r_p": 15,
    "try": [
      "0x16c02b6ce4496d14332d6bc87868a6c370931846f29d5c657280a9c54489c19f",
      "0x1e3fe54637bab635bc7fb7e798b7f1c0fc3937ec651168b35b10cb020e4484ce",
      "0x0964fe6ceb2a8de17c00a5f660b024fd59fa7610e9dd2f4e64c2a5ccc223e317",
    ],
  },
  {
    "sbox": 0,
    "t": 6,
    "r_f": 5,
    "r_p": 18,
    "try": [
      "0x03b9f81e3322d6bd2d1c36fb47e4e19e6f6529b033e8b3ed858ed5889f414dc2",
      "0x1abd4d07c9917b2a621f4009fba61901a68ac0447b0593d970375111574d6c47",
      "0x1c41f3c20ea6315642f52b7a10124b51e85413ed1eae50ffe23bc375a9d3c221",
      "0x06a82078bc600ce32bbcfffe5c9d11191b12964a40b6692bb7a5fcd8cf657f3e",
    ],
  },
  {
    "sbox": 1,
    "t": 3,
    "r_f": 17,
    "r_p": 59,
    "try": [
      "0x0389019a78f66ef1779cbef76b991790970ee87e49660e022cde14e0d65ecddf",
      "0x192c01d981a5b838782176dabd54e8f2b126109257f28dff8c45c9983455ac4f",
      "0x13b6822d15dc1561a8f606e5dced38bb8728db396125fb1dd372d570acbf9032",
      "0x2a2f7d09ff672d0197a7bc724127f5ae0e49bd7d6de6ce3343f8b5735d40ae5b",
    ],
  },
  {
    "sbox": 1,
    "t": 5,
    "r_f": 9,
    "r_p": 48,
    "try": [
      "0x350b0e8bbf1d6e997e53e5b4e457b3e2c15fb29493b1fa2bda978422d284510b",
      "0x069c673820489efe6b7569965da0fd0807e07e0ff17debf2e9da172357425b73",
    ],
  },
  {
    "sbox": 1,
    "t": 4,
    "r_f": 1,
    "r_p": 59,
    "try": [
      "0x38f5b70bd44b293ffcf550b3fe5f669b3355e1fd0158ecdac6f90515d1681eaa",
      "0x1acd7f3454afd4a3a38df6b70dac9a002f7c82fcff31e1437e5af8dba66f2235",
    ],
  },
  {
    "sbox": 0,
    "t": 9,
    "r_f": 10,
    "r_p": 20,
    "try": [
      "0x06f6469e6e531f22b791baf97feff885eae93dd9b0162da536f5b7b420d247d0",
      "0x1c42b488e3f511d4bb296b09319aa033ee4a1d0aa9d865e37e429ae370cba3f3",
    ],
  },
  {
    "sbox": 1,
    "t": 7,
    "r_f": 16,
    "r_p": 59,
    "try": [
      "0x264f23cc62945521ed32d77251413e18f6f212a0e9d687e7a3c55cc23cc78ac3",
      "0x2fc7414a77c87ff147299f29ff158a6d090021065793a05f3810e47c84b6d60d",
      "0x3807b16c195b3bc806ce16fd6c525545013bb4738b4c4a654d338e504ef77bc6",
    ],
  },
  {
    "sbox": 1,
    "t": 5,
    "r_f": 8,
    "r_p": 5,
    "try": [
      "0x069568d5b4b87fa29abb068a876c73fd6af38144958126212d88446d9523bfd4",
      "0x1b7f92fb32832b8d6e2779a3ca681d964bb7e3d7e6890ba11dbbf40e5612ec0f",
      "0x3370c06dc26f09297215a70eebcbbb007bd7c868fb84ba28fb490154981ab988",
    ],
  },
  {
    "sbox": 1,
    "t": 2,
    "r_f": 5,
    "r_p": 12,
    "try": [
      "0x1d8557f47e37b38067739e34eca34e2787e803137fe35fc5bd8d6711abe9938b",
    ],
  },
  {
    "sbox": 0,
    "t": 7,
    "r_f": 1,
    "r_p": 20,
    "try": [
      "0x3592124aac7d65f68deff2126a8e4052853607689eb418925e4ee1c4dd7661c0",
      "0x26f4b9bb4b9d7b1fd336180d617210154406f0f16667333b508b2aab1f455a30",
      "0x37e5e89388d361e0d314d603e8b3003b12408ebf389f064ab85decd3144e4738",
      "0x337c78bd3b7be2b8fc433569c31f074a59bc929175f035f09475e3a72448a82f",
      "0x174042ed90b018f19b3f966af649a1953828c08b69fdc646a033d0e24bbea03e",
    ],
  },
  {
    "sbox": 0,
    "t": 5,
    "r_f": 5,
    "r_p": 13,
    "try": [
      "0x17f78c12269569884fc975fad114d15b588fd76eab4b132b0eef7183e259f7ff",
      "0x0abb68582cf6649ba06bbcf3de30a90542f754e8e82f2b0ea7adf898c79186f8",
      "0x170cc49c7e4b2c9f20629c9e6c140c34bbd16a72041b2787172cacc501f0d6fb",
    ],
  },
  {
    "sbox": 1,
    "t": 2,
    "r_f": 15,
    "r_p": 53,
    "try": [
      "0x0d76223c69efb12e2bf9c63109cc0d1fce3f24fd973965a23d1775e44e3617df",
      "0x0c2b6ad41763cc83f16df42b6e1f426a8723775b75a253fc1d580a70da2e1d6a",
      "0x07df723db5b6f4b2dbf69e684034efca09913ec2a9a27620bf17f9211faa217e",
    ],
  },
  {
    "sbox": 1,
    "t": 9,
    "r_f": 7,
    "r_p": 34,
    "try": [
      "0x15c999e345479e23fa15c0c8f084a1a262c3207a0ee8a6f5d1b1d8917438edc3",
      "0x2cd3a4b0816afc35b286459d4fd55fe6e21c630efeb0f610cb0fa786ce04bdda",
      "0x15d22b16a424e607f358a3a50104e2fbf2408a0418ecaeedd4f413da1c71b64f",
    ],
  },
  {
    "sbox": 0,
    "t": 9,
    "r_f": 13,
    "r_p": 19,
    "try": [
      "0x3ab3c7c5148b3e5a69740b0257f357d8bc3d71638db05d1114e6c122a730ff41",
      "0x325188582fc9a98b8aa44244eaba48cc01088152e6467b1f43dc7a76c8b5c6d8",
      "0x0cba7f486b9f80a4c9d34ab47610d27b813ac01d88d4833d08e26ead3cc2b585",
    ],
  },
  {
    "sbox": 0,
    "t": 8,
    "r_f": 2,
    "r_p": 45,
    "try": [
      "0x12ba3fc6d834a9c6b57493f8aed185bc6b563122def74434abd1e8395cf880ed",
      "0x23e8ab68edfd9c0549e9ff177f0a7e41814f784b48f54a62ce350857cbf3b188",
      "0x1d011e8688f29bfb0bc10b208fd4ec6b8b6815d798e8e53e98e518b4645a2229",
      "0x09d40d0683850e829b776b1109050539dca42ae60a6733c542ceb27513d1b5f8",
    ],
  },
  {
    "sbox": 0,
    "t": 8,
    "r_f": 4,
    "r_p": 47,
    "try": [
      "0x1f2c2b7cea1facff69d8b4a811569c66e2b04fbb8874d385d7c07e87f9f89e4e",
      "0x1f2f30f2926c560043094be6c29ea1973a8efc7ef371670a4c4546f7d671d950",
    ],
  },
  {
    "sbox": 1,
    "t": 8,
    "r_f": 8,
    "r_p": 18,
    "try": [
      "0x30ca557a089d91c777dcd2eeb00d7f9423a9dfd553d0cf1a422da31eb1927420",
    ],
  },
  {
    "sbox": 1,
    "t": 8,
    "r_f": 3,
    "r_p": 21,
    "try": [
      "0x1d06dec9455c814bc82537dfbd13b7c0e79e008579196ebf9f416b426dc9b22d",
      "0x0356896d396e3d751595d382f8714a7c82890baab88010f2c09597c01ebf949d",
      "0x0d9d08a2d5eb9417ccb9cc4aedf0c1a9cfabeade9f3725185f81e68096d2b263",
      "0x0ce944ec573e5d22f85d0fc7f05b92111ed9a4e8cbb662fed5e8ced9b898a372",
    ],
  },
  {
    "sbox": 1,
    "t": 8,
    "r_f": 2,
    "r_p": 29,
    "try": [
      "0x1c3e0f5c536ab7cb333787681741deac28bc0d88fbe0c3a2c6a6d70191c6b337",
      "0x1b1466273d824d7a5118b4ec5343a36323cd0193031e5160262530b98283fba7",
      "0x169ab24fba46b8b2742ecc636dee2b3ff3ba94a8ac3188ad91dde37cf75f5139",
    ],
  },
];

const List<Map<String, dynamic>> _grainWithoutRejectionTestVector = [
  {
    "sbox": 1,
    "t": 101,
    "r_f": 10435,
    "r_p": 31292,
    "try": [
      "0x2e53da8ccc5a0582d76943f4074746d2dfbde637dfd2be51235fdb7177d0f89d",
      "0x1584108fdec592adaefacbe808fc9c25c3654840db70b376197c9ab8eadcc25d",
      "0x32e3ed391c31bc6be0f52e9d7d74c56ad74994ab83b5586e5b57043d4fe0121d",
      "0x364ebf0028e36a30c66eb8735ef31f814162341145e76b6d4a27bfaf51a1114c",
      "0x18e76869ce1d59517f1e415dbe0fe49b014c9681427d31eb92623479059c66a6",
    ],
  },
  {
    "sbox": 0,
    "t": 184,
    "r_f": 8806,
    "r_p": 19886,
    "try": [
      "0x27b46e0c2ec5f6f3e203ca4c837535f31ba1cad15c7649414f32618b02282599",
      "0x143502ff7413d2cc95dcabf86d42a2832924ee602b8a761a816b921b1c0541b6",
      "0x38ec7ee75050317ad04a79631e8557547f8080766d52b87976dab9a53ce3fa46",
    ],
  },
  {
    "sbox": 1,
    "t": 1677,
    "r_f": 12995,
    "r_p": 27818,
    "try": [
      "0x0e969ed2b10c8f07b2f7245c2e84da915e8d1d252332d44e5ecd518439a57c1f",
      "0x2309ec865965c9b03fefaa91b09e6548bfd2adec10b69d4287473e81f4f2be40",
      "0x21dd089e1cf73014526a8d764e3eb4284ca042fd705cfa3236b153413e690c94",
      "0x043b01337f218884c9c8843cb30b75b0bbb7593bc9572bc0b2bdf6fffa708df8",
      "0x1ab84e8ffac92b8cea2aa49da9952cf9cd5a627593e8d8fc64ebde6f7f2b3f2d",
    ],
  },
  {
    "sbox": 1,
    "t": 1446,
    "r_f": 6068,
    "r_p": 11052,
    "try": [
      "0x3d6c2a0760575146021dc43018fc0a11a7f6e5c5bacbf6f8e2c3aaf4d07d90f3",
    ],
  },
  {
    "sbox": 1,
    "t": 629,
    "r_f": 9670,
    "r_p": 8945,
    "try": [
      "0x1b270c1cc9441edbc8b06d5224708475c1e8d66ba8fd7a940d142e156364e231",
      "0x02b0db9c269ae5c58070d38a19cc5885b5ee13e5c76c5cd4a48fafa83d8a13d5",
      "0x3eace18a48a13f201e0474af93279a9e697024ff60b9502e3149c9d4e9019b2a",
      "0x30338280ead41d8a07c4adc7aa97e0e214ddf3fa4df1bb4aeb68a3fb1f9df6b0",
      "0x33d1196cfb1d7675def78d751eed49f0cc29c2f9ad940c9e3cfabb7e6e8d3a0d",
    ],
  },
];
const List<List<List<String>>> _poseidon = [
  [
    [
      "0000000000000000000000000000000000000000000000000000000000000000",
      "0100000000000000000000000000000000000000000000000000000000000000",
      "0200000000000000000000000000000000000000000000000000000000000000",
    ],
    [
      "56a4ec4a02bcb1aea042b6d0719ae6f70f2466f964b3ef9453b4640bcd6a522a",
      "2ab8e528963e2a01fedad9be7f2ed4dc12553d34ae7dff7630a44a8b56d1c513",
      "dd9d4ed3a12990357b2ca4bde1dfcff71a56847959cd6f25446597c668c8490a",
    ],
  ],
  [
    [
      "5c7a8f73adfc70fb3f139449ac6b57074c4d6e66b164939daffa2ef6ee692108",
      "1add86b3f2e1bda62a5d2e0e982b77e6b0ef9ca3f24988c7b3534201cfb1cd0d",
      "bd69b82532b6940ff2590f679ba9c7271fe01f7e9c8e36d6a5e29d4e30a73514",
    ],
    [
      "d06e2f8338928a7ee7380c77928087cda2fd2961a15269037a22d6d120aedd21",
      "2955a45f416f10d6bc79ac94d0c069c949e5f4bd09481e1f368cb9b8ee51140d",
      "0d8376bbe9d65d2b1e136fb7d982ab87c51c403044be5c799d56bb68acf95b10",
    ],
  ],
  [
    [
      "bc50984255d6afbe9ef92848ed5ac00862c2fa7b2fecbcb64b6968912a63810e",
      "3dc166d56a1d62f5a8d7551db5fd9313e8c7203d996af7d477083756d59af80d",
      "05a745f45d7ff6db10bc67fdf0f03ebf8130ab33362697b0e4e4c763ccb8f636",
    ],
    [
      "0b77ec5307145a0c052dc7a9d6f96ac341ae72640832d58e51eb92a417801712",
      "3b523f44f00e463f8b0fd7d4fc0e280cdbdeb927f18168077bb362f2675a2e18",
      "957a9706ffcc351564ae802a9911314c05e23e22afcf834059df80fac1057626",
    ],
  ],
  [
    [
      "495c222f7fba1e31defa3d5a57efc2e1e9b01a035587d5fb1a38e01d94903d3c",
      "3d0ad3361fec097790d9be0e42988d7d25c9a138f49b1a537edcf04be34a9811",
      "a4af9db6d27b5072835f0c3e88395ed7a41b0052ad8084a8b9da948d320dad16",
    ],
    [
      "6780083f7f82cb4254e7b66f4b83846ac9773fb9c39c6ec9818b06222309552a",
      "a5f9a57e2c40b158d8165343e602652c3efc0b64ddcaeee5ce3d951fd59f5008",
      "dca46436127c477e83950fa07cc68a566e541855adc268529787352488921e3b",
    ],
  ],
  [
    [
      "4d5431e6437d0b5bedbbcdaf345b86c4121fc00fe7f235734276d38d47f1e111",
      "dd0c7a1d811c7d9cd46d377b3fdeab3fb679f3dc601d008285edcbdae69ce83c",
      "19e4aac0359017ec85a183d22053db33f73476f21a482ec9378365c8f7393c14",
    ],
    [
      "89998e5e0fa1952a40b8b52b62d94570a49a7d91dd226d692bc9b1a613c90830",
      "d0ee44d9a90d9079effb2486d3d84d1a184edf14970bac36c74804c7ffbee50b",
      "048145a661ce787c7e122ac6447e9ba393d367ac054faac5b7b5f7192b2fde21",
    ],
  ],
  [
    [
      "e2885315eb4671098b79535e790fe53e29fef2b3766697ac32b4f473f468a008",
      "e62389fc1657e0def0b632c6ae25f9f783b27db59a4a153d882d2b2103596515",
      "eb9494c6d227e2163b4699d991f433bf9486a7afcf4a0d9c731e985d99589c0b",
    ],
    [
      "ce2d1f8d677ffbfd73b235e8c687fb42187f7881c3ce9c794f2bd46140f7cc2a",
      "af829239b6d55d5f43ec6f32b84a2a011e64c574739f87cb47dc702383fa5a34",
      "03d1085b214c69b8bfe89102bd617ece0c54001796404105c53330d249581d0f",
    ],
  ],
  [
    [
      "b738e8aa0a1526a5bdef613120372e831a20da8aba18d1dbebbc862ded42431e",
      "91476930e3385cd3e3379e3853d93467e001afa2fb8dc3436d75a4a6f2657210",
      "4b192232ecb9f0c02411e52596bc5e90457e745939ffedbd12863ce71a02af11",
    ],
    [
      "5fccd87d2f667b9ee388f34c1c710687127bff5b0221fd8a529488669157942b",
      "8962b58030aa6352d990f3b9001ccbe88a5627581bbfb901ac4a6aedfae5c634",
      "7c0b7659f24c98af310e3e8d82b5f399433cdda58f48d9ef8dd0ca864272da3f",
    ],
  ],
  [
    [
      "7b417adb63b37122a5bf62d26f1e7f268fb86b12b56da9c382857deecc40a90d",
      "5e29353971b34994b621b0b261aeb3786dd984d567db2857b927b7fae2db5831",
      "05415d4642789d38f50b8dbcc129cab3d17d19f3355bcf73cecb8cb8a5da0130",
    ],
    [
      "9ee1addc6f64dab6acdceaecc1fbbc8a32458e49c19e798556c64b598ba6ff14",
      "42cc10364fd659c3cc772584db91c49a38672b692493b9075f1653ca1fae1c33",
      "ff41f351801456c4960b393affa86213a7eac06c66213b45c3b50ec648d67d0d",
    ],
  ],
  [
    [
      "7152f13936a270572670dc82d39026c6cb4cd4b0f7f5aa2a4f5a5341ec5dd715",
      "406f2fdd2afa733f5f641c8c21862a1bafce2609d9eecfa158cfb5cd79f88008",
      "e215dc7d9657bad3fb88b01e993844543624c25fa959cc97489ce75745824b37",
    ],
    [
      "630915d7d825eb7437b0e46e37286a88b389dc69859307116d347b98ca145c31",
      "aa581baee94fb546a761f17a5d6eaa7029527842f31c3987b868ed7daffdb534",
      "7dc117b3391aab85de9f424db6651e0045ab7998f28e54101535906199ce1f1a",
    ],
  ],
  [
    [
      "868c53239cfbdf73caec65604037314faaceb56218c6bd30f8374ac13386793f",
      "21a9fb80ad03bc0cda4a44946c00e1b1a1df0e5b87b5bece477a709649e95006",
      "049139482564f185c7900e83c738070af6556df6ed4b4ddd3d9a69f53357d736",
    ],
    [
      "6a5a1919a449a5e029711f488adbd6b03e5c927b6f9d9d35c5b3cceb76605203",
      "80475b4689596147ab2adf0173db289b3a26a104842173e88bdbfec04a28671b",
      "1ef3c8d0f54444f555b15f7bc9fa4ffa0f567c0f19ac7d0ff944fd36426e323a",
    ],
  ],
  [
    [
      "7d4f5ccb01643c31db845eecd5d63dc16a95e3025b9792fff7f244fc71626939",
      "26d62e9596fa825c6bf21aff9e68625a192440ea06828123d97884806f15fa08",
      "d952754a2364b666ffc30fdb014786da3a6128aef784a64610a89d1a7099212d",
    ],
    [
      "1b4ac9bef56bdb6fb42d3e3cd3a2ac70a4c40c425b0bd6679ca57b307ef1d42f",
      "1a2ef41194aaa23432e086ed8adbd1deec3c7cb396de35bae95aaf5a08a0ec36",
      "68eb80c73e2ccbdee1ba71247761d5b5ecc620e6e48e003b023d9f5561662f20",
    ],
  ],
];
const List<List<String>> _hashFqTestVector = [
  [
    "0000000000000000000000000000000000000000000000000000000000000000",
    "0100000000000000000000000000000000000000000000000000000000000000",
    "4e68f685702957f3bf546b7a0901314e514f195ee3b1644622779d93df96ba15",
  ],
  [
    "3dc166d56a1d62f5a8d7551db5fd9313e8c7203d996af7d477083756d59af80d",
    "05a745f429c5dce84e0c20fdf0f03ebf8130ab33362697b0e4e4c763ccb8f636",
    "ada8cae46a042d00b02e33c36e658c2213fe8134538b560319e999f3f5829000",
  ],
  [
    "495c222f7fba1e31defa3d5a57efc2e1e9b01a035587d5fb1a38e01d94903d3c",
    "3d0ad336eb31f083ce29770e42988d7d25c9a138f49b1a537edcf04be34a9811",
    "19949fc7740499370058127d040f11245eba6c3780e93e2616f4c1775630782d",
  ],
];

class _PoseidonFPConstants {
  // Number of round constants: 192
  // Round constants for GF(p):
  static final List<List<PallasFp>> roundConstants = [
    [
      PallasFp.fromRaw([
        Uint64.parseHex('0x57538c2596426303'),
        Uint64.parseHex('0x4e71162f31003b70'),
        Uint64.parseHex('0x353f628f76d110f3'),
        Uint64.parseHex('0x360d7470611e473d'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0xbdb74213bf63188b'),
        Uint64.parseHex('0x4908ac2f12ebe06f'),
        Uint64.parseHex('0x5dc3c6c5febfaa31'),
        Uint64.parseHex('0x2bab94d7ae222d13'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0x0939d92753cc5dc8'),
        Uint64.parseHex('0xef77e7d736766c5d'),
        Uint64.parseHex('0x2bf03e1a29aa871f'),
        Uint64.parseHex('0x150c93fef652fb1c'),
      ]),
    ],
    [
      PallasFp.fromRaw([
        Uint64.parseHex('0x14259dce537782b2'),
        Uint64.parseHex('0x03cc0a60141e894e'),
        Uint64.parseHex('0x955d55db56dc57c1'),
        Uint64.parseHex('0x3270661e68928b3a'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0xce9fb9ffc345afb3'),
        Uint64.parseHex('0xb407c370f2b5a1cc'),
        Uint64.parseHex('0xa0b7afe4e2057299'),
        Uint64.parseHex('0x073f116f04122e25'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0x8ebad76fc71554d8'),
        Uint64.parseHex('0x55c9cd2061ae93ca'),
        Uint64.parseHex('0x7affd09c1f53f5fd'),
        Uint64.parseHex('0x2a32ec5c4ee5b183'),
      ]),
    ],
    [
      PallasFp.fromRaw([
        Uint64.parseHex('0x2d8ccbe292efeead'),
        Uint64.parseHex('0x634d24fc6e2559f2'),
        Uint64.parseHex('0x651e2cfc740628ca'),
        Uint64.parseHex('0x270326ee039df19e'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0xa068fc37c182e274'),
        Uint64.parseHex('0x8af895bce012f182'),
        Uint64.parseHex('0xdc100fe7fcfa5491'),
        Uint64.parseHex('0x27c6642ac633bc66'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0x9ca18682e26d7ff9'),
        Uint64.parseHex('0x710e1fb6ab976a45'),
        Uint64.parseHex('0xd27f57396989129d'),
        Uint64.parseHex('0x1bdfd8b01401c70a'),
      ]),
    ],
    [
      PallasFp.fromRaw([
        Uint64.parseHex('0xc832d824261a35ea'),
        Uint64.parseHex('0xf4f6fb3f9054d373'),
        Uint64.parseHex('0x14b9d6a9c84dd678'),
        Uint64.parseHex('0x162a14c62f9a89b8'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0xf79824667b5b6bec'),
        Uint64.parseHex('0xac0a1fc71e2cf0c0'),
        Uint64.parseHex('0x2af6f79e3127feea'),
        Uint64.parseHex('0x2d193e0f76de586b'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0x5d0bf58dc8a4aa94'),
        Uint64.parseHex('0x4feff82984990ff8'),
        Uint64.parseHex('0x81696ef1104e674f'),
        Uint64.parseHex('0x044ca3cc4a85d73b'),
      ]),
    ],
    [
      PallasFp.fromRaw([
        Uint64.parseHex('0x6198785f0cd6b9af'),
        Uint64.parseHex('0xb8d9e2d4f314f46f'),
        Uint64.parseHex('0x1d0453416d3e235c'),
        Uint64.parseHex('0x1cbaf2b371dac6a8'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0x343e07610f3fede5'),
        Uint64.parseHex('0x293c4ab038fdbbdc'),
        Uint64.parseHex('0x0e6c49d061b6b5f4'),
        Uint64.parseHex('0x1d5b2777692c205b'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0xf60e971b8d73b04f'),
        Uint64.parseHex('0x06a9adb0c1e6f962'),
        Uint64.parseHex('0xaa30535bdd749a7e'),
        Uint64.parseHex('0x2e9bdbba3dd34bff'),
      ]),
    ],
    [
      PallasFp.fromRaw([
        Uint64.parseHex('0x035a13661f22418b'),
        Uint64.parseHex('0xde40fbe26d047b05'),
        Uint64.parseHex('0x8bd5bae36969299f'),
        Uint64.parseHex('0x2de11886b18011ca'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0xbc998884ba96a721'),
        Uint64.parseHex('0x2ab9395c449be947'),
        Uint64.parseHex('0x0d5b4a3f1841dcd8'),
        Uint64.parseHex('0x2e07de1780b8a70d'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0x825e4c2bb74925ca'),
        Uint64.parseHex('0x250440a99d6b8af3'),
        Uint64.parseHex('0xbbdb63dbd52dad16'),
        Uint64.parseHex('0x0f69f1854d20ca0c'),
      ]),
    ],
    [
      PallasFp.fromRaw([
        Uint64.parseHex('0x816c059422dc705e'),
        Uint64.parseHex('0x6ce5113507f96de9'),
        Uint64.parseHex('0x0d135dc639fb09a4'),
        Uint64.parseHex('0x2eb1b25417fe1767'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0xb8b1bdf4953bd82c'),
        Uint64.parseHex('0xff36c661d26cc42d'),
        Uint64.parseHex('0x8c24cb44c3fab48a'),
        Uint64.parseHex('0x115cd0a0643cfb98'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0xde801612311d04cd'),
        Uint64.parseHex('0xbb57ddf14e0f958a'),
        Uint64.parseHex('0x066d7378b999868b'),
        Uint64.parseHex('0x26ca293f7b2c462d'),
      ]),
    ],
    [
      PallasFp.fromRaw([
        Uint64.parseHex('0xf5209d14b24820ca'),
        Uint64.parseHex('0x0f160bf9f71e967f'),
        Uint64.parseHex('0x2a830aa162412cd9'),
        Uint64.parseHex('0x17bf1b93c4c7e01a'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0x05c86f2e7dc293c5'),
        Uint64.parseHex('0xe03c0354bd8cfd38'),
        Uint64.parseHex('0xa24f8456369c85df'),
        Uint64.parseHex('0x35b41a7ac4f3c571'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0x72ac156af435d09e'),
        Uint64.parseHex('0x64e14d3beb2dddde'),
        Uint64.parseHex('0x435927994849bea9'),
        Uint64.parseHex('0x3b1480080523c439'),
      ]),
    ],
    [
      PallasFp.fromRaw([
        Uint64.parseHex('0x271618d874b14c6d'),
        Uint64.parseHex('0x08e286442a2d3eb2'),
        Uint64.parseHex('0x4950856dc907d575'),
        Uint64.parseHex('0x2cc6810031dc1b0d'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0x91f318c09f0cb566'),
        Uint64.parseHex('0x9e517aa93b78341d'),
        Uint64.parseHex('0x059618e2afd2ef99'),
        Uint64.parseHex('0x25bdbbeda1bde8c1'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0xc6313487073f7f7b'),
        Uint64.parseHex('0x2a5ed0a27b61926c'),
        Uint64.parseHex('0xb95f33c25dde8ac0'),
        Uint64.parseHex('0x392a4a8758e06ee8'),
      ]),
    ],
    [
      PallasFp.fromRaw([
        Uint64.parseHex('0xe7bbcef02eb5866c'),
        Uint64.parseHex('0x5e6a6fd15db89365'),
        Uint64.parseHex('0x9aa6111f4de00948'),
        Uint64.parseHex('0x272a55878a08442b'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0x9b925b3c5b21e0e2'),
        Uint64.parseHex('0xa6ebba011694dd12'),
        Uint64.parseHex('0xefa13c4e60e26239'),
        Uint64.parseHex('0x2d5b308b0cf02cdf'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0xef38c57c311673ac'),
        Uint64.parseHex('0x44dff42f18b46c56'),
        Uint64.parseHex('0xdd5d293d72e2e5f2'),
        Uint64.parseHex('0x16549fc6af2f3b72'),
      ]),
    ],
    [
      PallasFp.fromRaw([
        Uint64.parseHex('0x9b7126d9b46860df'),
        Uint64.parseHex('0x7639826534420311'),
        Uint64.parseHex('0xfa69c3a2ad52f76d'),
        Uint64.parseHex('0x1b10bb7a82afce39'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0x90d27f6a00b7dfc8'),
        Uint64.parseHex('0xd1b36968ba0405c0'),
        Uint64.parseHex('0xc79c2df7dc98a3be'),
        Uint64.parseHex('0x0f1e7505ebd91d2f'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0xff457756b819bb20'),
        Uint64.parseHex('0x797fd6e3f18eb1ca'),
        Uint64.parseHex('0x537a7497a3b43f46'),
        Uint64.parseHex('0x2f313faf0d3f6187'),
      ]),
    ],
    [
      PallasFp.fromRaw([
        Uint64.parseHex('0xf0bc3e732ecb26f6'),
        Uint64.parseHex('0x5cad11ebf0f7ceb8'),
        Uint64.parseHex('0xfa3ca61c0ed15bc5'),
        Uint64.parseHex('0x3a5cbb6de450b481'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0x865527cbca915982'),
        Uint64.parseHex('0x51baa6e20f892b62'),
        Uint64.parseHex('0xd92086e253b439d6'),
        Uint64.parseHex('0x3dab54bc9bef688d'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0x368045acf2b71ae3'),
        Uint64.parseHex('0x4c24b33b410fefd4'),
        Uint64.parseHex('0xe280d31670123f74'),
        Uint64.parseHex('0x06dbfb42b979884d'),
      ]),
    ],
    [
      PallasFp.fromRaw([
        Uint64.parseHex('0xa7fc32d22f18b9d3'),
        Uint64.parseHex('0xb8d2de72e3d2c9ec'),
        Uint64.parseHex('0xc6f039ea1973a63e'),
        Uint64.parseHex('0x068d6b4608aae810'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0x2b5dfcc5572555df'),
        Uint64.parseHex('0xb868a7d7e1f1f69a'),
        Uint64.parseHex('0x0ee258c9b8fdfccd'),
        Uint64.parseHex('0x366ebfafa3ad381c'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0xe6bc229e95bc76b1'),
        Uint64.parseHex('0x7ef66d89d044d022'),
        Uint64.parseHex('0x04db3024f41d3f56'),
        Uint64.parseHex('0x39678f65512f1ee4'),
      ]),
    ],
    [
      PallasFp.fromRaw([
        Uint64.parseHex('0xe534c88fe53d85fe'),
        Uint64.parseHex('0xcf82c25f99dc01a4'),
        Uint64.parseHex('0xd58b7750a3bc2fe1'),
        Uint64.parseHex('0x21668f016a8063c0'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0x4bef429bc5331608'),
        Uint64.parseHex('0xe34dea56439fe195'),
        Uint64.parseHex('0x1bc749363e98a768'),
        Uint64.parseHex('0x39d00994a8a5046a'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0x770c956f60d881b3'),
        Uint64.parseHex('0xb163d41605d39f99'),
        Uint64.parseHex('0x6b203bbe12fb3425'),
        Uint64.parseHex('0x1f9dbdc3f8431263'),
      ]),
    ],
    [
      PallasFp.fromRaw([
        Uint64.parseHex('0x9794a9f7c336eab2'),
        Uint64.parseHex('0xbe0bc829fe5e66c6'),
        Uint64.parseHex('0xe5f17b9e0ee0cab6'),
        Uint64.parseHex('0x027745a9cddfad95'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0x52025657abd8aee0'),
        Uint64.parseHex('0x2fa43fe20a45c78d'),
        Uint64.parseHex('0x788d695c61e93212'),
        Uint64.parseHex('0x1cec0803c504b635'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0xd3872a9559a03a73'),
        Uint64.parseHex('0xed5082c8dbf31365'),
        Uint64.parseHex('0x72077448ef87cc6e'),
        Uint64.parseHex('0x123523d75e9fabc1'),
      ]),
    ],
    [
      PallasFp.fromRaw([
        Uint64.parseHex('0x001779e3a1d357f4'),
        Uint64.parseHex('0x27feba35975ee7e5'),
        Uint64.parseHex('0xf419b848e5d694bf'),
        Uint64.parseHex('0x1723d1452c9cf02d'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0x9dab1ee4dcf96622'),
        Uint64.parseHex('0x21c3f776f572836d'),
        Uint64.parseHex('0xfcc0573d7e613694'),
        Uint64.parseHex('0x1739d180a16010bd'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0x70290452042d048d'),
        Uint64.parseHex('0xfafa96fbeb0ab893'),
        Uint64.parseHex('0xacce32391794b627'),
        Uint64.parseHex('0x2d4e6354da9cc554'),
      ]),
    ],
    [
      PallasFp.fromRaw([
        Uint64.parseHex('0x670bcf6f8b485dcd'),
        Uint64.parseHex('0x8f3bd43f99260621'),
        Uint64.parseHex('0x4a869553c9d007f8'),
        Uint64.parseHex('0x153ee6142e535e33'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0xd258d2e2b7782172'),
        Uint64.parseHex('0x968ad4424af83700'),
        Uint64.parseHex('0x635ef7e7a430b486'),
        Uint64.parseHex('0x0c45bfd3a69aaa65'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0x0e5633d251f73307'),
        Uint64.parseHex('0x6897ac0a8ffa5ff1'),
        Uint64.parseHex('0xf2d56aec83144600'),
        Uint64.parseHex('0x0adfd53b256a6957'),
      ]),
    ],
    [
      PallasFp.fromRaw([
        Uint64.parseHex('0xac9d36a8b7516d63'),
        Uint64.parseHex('0x3f87b28f1c1be4bd'),
        Uint64.parseHex('0x8cd1726b7cbab8ee'),
        Uint64.parseHex('0x315d2ac8ebdbac3c'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0x299ce44ea423d8e1'),
        Uint64.parseHex('0xc9bb60d1f6959879'),
        Uint64.parseHex('0xcfaec23d2b16883f'),
        Uint64.parseHex('0x1b8472712d02eef4'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0xc4a5404198adf70c'),
        Uint64.parseHex('0x367d2c54e36928c9'),
        Uint64.parseHex('0xbd0b70fa2255eb6f'),
        Uint64.parseHex('0x3c1cd07efda6ff24'),
      ]),
    ],
    [
      PallasFp.fromRaw([
        Uint64.parseHex('0xbbe523aef9ab107a'),
        Uint64.parseHex('0x4a16073f738f7e0c'),
        Uint64.parseHex('0x687f4e51b2e1dcd3'),
        Uint64.parseHex('0x136052d26bb3d373'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0x676c36c24ef967dd'),
        Uint64.parseHex('0x7b3cfbb873032681'),
        Uint64.parseHex('0xc1bdd859a1232a1d'),
        Uint64.parseHex('0x16c96beef6a0a848'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0x067eec7f2d6340c4'),
        Uint64.parseHex('0x012387bab4f1662d'),
        Uint64.parseHex('0x2ab7fed8f499a9fb'),
        Uint64.parseHex('0x284b38c57ff65c26'),
      ]),
    ],
    [
      PallasFp.fromRaw([
        Uint64.parseHex('0xaf1dff204c922f86'),
        Uint64.parseHex('0xfc06772c1c0411a6'),
        Uint64.parseHex('0x39e242198897d17c'),
        Uint64.parseHex('0x0c5993d175e81f66'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0xbbf53f67b1f87b15'),
        Uint64.parseHex('0xf24887ad48e17759'),
        Uint64.parseHex('0xfcda655d1ba9c8f9'),
        Uint64.parseHex('0x03bf7a3f7bd043da'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0x9b5cd09e36d8be62'),
        Uint64.parseHex('0x4c8f9cbe69f0e827'),
        Uint64.parseHex('0xb0cf999567f00e73'),
        Uint64.parseHex('0x3188fe4ee9f9fafb'),
      ]),
    ],
    [
      PallasFp.fromRaw([
        Uint64.parseHex('0xafea99a2ec6c595a'),
        Uint64.parseHex('0x3af5bf77c1c42652'),
        Uint64.parseHex('0x5a39768c480d61e1'),
        Uint64.parseHex('0x171f528ccf658437'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0x5a0563b9b8e9f1d5'),
        Uint64.parseHex('0x812c3286ee700067'),
        Uint64.parseHex('0x196e41859b35ef88'),
        Uint64.parseHex('0x12f4175c4ab45afc'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0x0e74d4d369118b79'),
        Uint64.parseHex('0x7e23e1aabe96cfab'),
        Uint64.parseHex('0x8f8fdcf800a9ac69'),
        Uint64.parseHex('0x3a509e155cb7ebfd'),
      ]),
    ],
    [
      PallasFp.fromRaw([
        Uint64.parseHex('0x98712c65678cfd30'),
        Uint64.parseHex('0x984bc8f2e4c1b69e'),
        Uint64.parseHex('0x1a89920e2504c3b3'),
        Uint64.parseHex('0x10f2a685df4a27c8'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0xe8a16728cc9d4918'),
        Uint64.parseHex('0x54573c9333c56321'),
        Uint64.parseHex('0x1d8d93d54ab91a0e'),
        Uint64.parseHex('0x09e5f49790c8a0e2'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0x609a740347cf5fea'),
        Uint64.parseHex('0x42d17ed6ee0fab7e'),
        Uint64.parseHex('0x2bf35705d9f84a34'),
        Uint64.parseHex('0x352d69bed80ee3e5'),
      ]),
    ],
    [
      PallasFp.fromRaw([
        Uint64.parseHex('0x3a758af6fa84e0e8'),
        Uint64.parseHex('0xc634debd281b76a6'),
        Uint64.parseHex('0x491562faf2b190d3'),
        Uint64.parseHex('0x058ee73ba9f3f293'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0x621a132510a43904'),
        Uint64.parseHex('0x092cb92119bc76be'),
        Uint64.parseHex('0xcd0f1fc55b1a3250'),
        Uint64.parseHex('0x232f99cc911eddd9'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0xc3b97c1e301bc213'),
        Uint64.parseHex('0xf9efd52ca6bc2961'),
        Uint64.parseHex('0x86c22c6c5d4869f0'),
        Uint64.parseHex('0x201beed7b8f3ab81'),
      ]),
    ],
    [
      PallasFp.fromRaw([
        Uint64.parseHex('0xbf6b3431ba94e9bc'),
        Uint64.parseHex('0x29388842744a1210'),
        Uint64.parseHex('0xa1c9291d58602f51'),
        Uint64.parseHex('0x1376dce6580030c6'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0x6454843c5486d7b3'),
        Uint64.parseHex('0x072ba8b02d92e722'),
        Uint64.parseHex('0x2b3356c38238f761'),
        Uint64.parseHex('0x1793199e6fd6ba34'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0x06a3f1d3b433311b'),
        Uint64.parseHex('0x3c66160dc62aacac'),
        Uint64.parseHex('0x9fee9c20c87a67df'),
        Uint64.parseHex('0x22de7a7488dcc735'),
      ]),
    ],
    [
      PallasFp.fromRaw([
        Uint64.parseHex('0x30d6e3fd516b47a8'),
        Uint64.parseHex('0xdbe0b77fae77e1d0'),
        Uint64.parseHex('0xdf8ff37fe2d8edf8'),
        Uint64.parseHex('0x3514d5e9066bb160'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0x19377427137a81c7'),
        Uint64.parseHex('0xff453d6f900f144a'),
        Uint64.parseHex('0xf919a00dabbf5fa5'),
        Uint64.parseHex('0x30cd3006931ad636'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0x5b6a74220692b506'),
        Uint64.parseHex('0x8f9e4b2cae2ebb51'),
        Uint64.parseHex('0x41f81a5cf613c8df'),
        Uint64.parseHex('0x253d1a5c52934127'),
      ]),
    ],
    [
      PallasFp.fromRaw([
        Uint64.parseHex('0x73f666cb86a48e8e'),
        Uint64.parseHex('0x851b3a59c990fafc'),
        Uint64.parseHex('0xa35e9613e7f5fe92'),
        Uint64.parseHex('0x035b461c02d79d19'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0x7cfbf86a3aa04780'),
        Uint64.parseHex('0x92b1283c2d5fccde'),
        Uint64.parseHex('0x5bc00eedd56b93e0'),
        Uint64.parseHex('0x23a9928079d175bd'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0xf1e4ccd73fa00a82'),
        Uint64.parseHex('0xb5e2ea3436eef957'),
        Uint64.parseHex('0xf1594a0763c611ab'),
        Uint64.parseHex('0x13a7785ae134ea92'),
      ]),
    ],
    [
      PallasFp.fromRaw([
        Uint64.parseHex('0xbbf04f5252de4279'),
        Uint64.parseHex('0x3889c57863446d88'),
        Uint64.parseHex('0x4962ae3c0da17e31'),
        Uint64.parseHex('0x39fce308b7d43c57'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0x3b57e34489b53fad'),
        Uint64.parseHex('0xbef00a08c6ed38d2'),
        Uint64.parseHex('0xc0fdf01662f60d22'),
        Uint64.parseHex('0x1aae18833f8e1d3a'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0x55513e033398513f'),
        Uint64.parseHex('0x27c1b3fd8f85d8a8'),
        Uint64.parseHex('0x8b2e80c064fd83ed'),
        Uint64.parseHex('0x1a761ce82400af01'),
      ]),
    ],
    [
      PallasFp.fromRaw([
        Uint64.parseHex('0x5244ca749b73e481'),
        Uint64.parseHex('0xdcf6af2830a50287'),
        Uint64.parseHex('0x16dd1a87ca22e1cc'),
        Uint64.parseHex('0x275a03e45adda7c3'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0x58a253cfb6a95786'),
        Uint64.parseHex('0x07e561453fc5648b'),
        Uint64.parseHex('0xeb08e47e5feabcf8'),
        Uint64.parseHex('0x2e5a10f08b5ab8bb'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0xe033d82cefe78ce3'),
        Uint64.parseHex('0xc141a5b6d594bec4'),
        Uint64.parseHex('0xb84e9c333b2932f1'),
        Uint64.parseHex('0x1459cb8587208473'),
      ]),
    ],
    [
      PallasFp.fromRaw([
        Uint64.parseHex('0x5cec7e7b338fbe1b'),
        Uint64.parseHex('0x52f9332fbffcfbbd'),
        Uint64.parseHex('0x7b92ce810e14a400'),
        Uint64.parseHex('0x193ae5921d78b5de'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0x60224be67248e82c'),
        Uint64.parseHex('0x374384f4a0728205'),
        Uint64.parseHex('0x89111fb2c4660281'),
        Uint64.parseHex('0x3097898a5d0011a4'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0x549980de862930f5'),
        Uint64.parseHex('0x1979b2d1c465b4d9'),
        Uint64.parseHex('0x571782fd96ce54b4'),
        Uint64.parseHex('0x378d97bf8c864ae7'),
      ]),
    ],
    [
      PallasFp.fromRaw([
        Uint64.parseHex('0x37ea32a971d17884'),
        Uint64.parseHex('0xdbc7f5cb46093421'),
        Uint64.parseHex('0x88136287ce376b08'),
        Uint64.parseHex('0x2eb04ea7c01d97ec'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0xead3726f1af2e7b0'),
        Uint64.parseHex('0x861cbda476804e6c'),
        Uint64.parseHex('0x2302a1c22e49baec'),
        Uint64.parseHex('0x36425347ea03f641'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0xecd627e59590d09e'),
        Uint64.parseHex('0x3f5b5ca5a19a9701'),
        Uint64.parseHex('0xcc996cd85c98a1d8'),
        Uint64.parseHex('0x26b72df47408ad42'),
      ]),
    ],
    [
      PallasFp.fromRaw([
        Uint64.parseHex('0x59bece31f0a31e95'),
        Uint64.parseHex('0xde01212ee4588f89'),
        Uint64.parseHex('0x1f05636c610b89aa'),
        Uint64.parseHex('0x130180e44e2924db'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0x9ea8e7bc79263550'),
        Uint64.parseHex('0xdf7793cc89e5b52f'),
        Uint64.parseHex('0x73275acaed5f579c'),
        Uint64.parseHex('0x219e97737d3979ba'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0x9c12635df251d153'),
        Uint64.parseHex('0x3b0672dd7d42cbb4'),
        Uint64.parseHex('0x3461363f81c489a2'),
        Uint64.parseHex('0x3cdb93598a5ca528'),
      ]),
    ],
    [
      PallasFp.fromRaw([
        Uint64.parseHex('0x2861ce16f219d5a9'),
        Uint64.parseHex('0x4ad0447045a7c5aa'),
        Uint64.parseHex('0x20724b927a0ca81c'),
        Uint64.parseHex('0x0e59e6f332d7ed37'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0x43b0a3fcff2036bd'),
        Uint64.parseHex('0x172cc07b9d33fbf9'),
        Uint64.parseHex('0x3d7369467222697a'),
        Uint64.parseHex('0x1b064342d51a4275'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0x3eb310228a0e5f6c'),
        Uint64.parseHex('0x78fa9fb9171221b7'),
        Uint64.parseHex('0x2f363c55b2882e0b'),
        Uint64.parseHex('0x30b82a998cbd8e8a'),
      ]),
    ],
    [
      PallasFp.fromRaw([
        Uint64.parseHex('0xe46f6d4298740107'),
        Uint64.parseHex('0x8ad71ea715be0573'),
        Uint64.parseHex('0x63df7a76e858a4aa'),
        Uint64.parseHex('0x23e4ab37183acba4'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0xfca995e2b59914a1'),
        Uint64.parseHex('0xacfe14640de044f2'),
        Uint64.parseHex('0x5d33094e0beda75b'),
        Uint64.parseHex('0x2795d5c5fa428022'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0xc26d909dee8b53c0'),
        Uint64.parseHex('0xa6687c3df16c8fe4'),
        Uint64.parseHex('0xd765f26dd03f4c45'),
        Uint64.parseHex('0x3001ca401e89601c'),
      ]),
    ],
    [
      PallasFp.fromRaw([
        Uint64.parseHex('0xe7fea6bdf3471380'),
        Uint64.parseHex('0xe84b5bebae4e501d'),
        Uint64.parseHex('0xf7bf86e89280827f'),
        Uint64.parseHex('0x0072e45cc676b08e'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0xd0c54ddeb26b86c0'),
        Uint64.parseHex('0xb64829e2d40e41bd'),
        Uint64.parseHex('0xe2abe4c518ce599e'),
        Uint64.parseHex('0x13de705484874bb5'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0x38915b432a9959a5'),
        Uint64.parseHex('0x82bb18e5af1b05bb'),
        Uint64.parseHex('0x315950f1211defe8'),
        Uint64.parseHex('0x0408a9fcf9d61abf'),
      ]),
    ],
    [
      PallasFp.fromRaw([
        Uint64.parseHex('0x34070cbee26886a0'),
        Uint64.parseHex('0xae4d23b0b41be9a8'),
        Uint64.parseHex('0xbb4e4a1400ccd2c4'),
        Uint64.parseHex('0x2780b9e75b55676e'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0x9405592098b4056f'),
        Uint64.parseHex('0xdc4d8fbefe24405a'),
        Uint64.parseHex('0xf80333ec85634ac9'),
        Uint64.parseHex('0x3a570d4d7c4e7ac3'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0x78d2b247899520b4'),
        Uint64.parseHex('0xe2cc1507bebdcc62'),
        Uint64.parseHex('0xf347c247fcf09294'),
        Uint64.parseHex('0x0c13cca7cb1f9d2c'),
      ]),
    ],
    [
      PallasFp.fromRaw([
        Uint64.parseHex('0x2e8c88f7707470e0'),
        Uint64.parseHex('0x0b50bb2eb82df74d'),
        Uint64.parseHex('0xd2614a197c6b794b'),
        Uint64.parseHex('0x14f59baa03cd0ca4'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0xbe52476e0a16f3be'),
        Uint64.parseHex('0xa51d54ede66167f5'),
        Uint64.parseHex('0x6f546e1704c39c60'),
        Uint64.parseHex('0x307defee925dfb43'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0x380b67d80473dce3'),
        Uint64.parseHex('0x661106836adfe5e7'),
        Uint64.parseHex('0x7a07e7674b5a2621'),
        Uint64.parseHex('0x1960cd511a91e060'),
      ]),
    ],
    [
      PallasFp.fromRaw([
        Uint64.parseHex('0x15aaf1f7712589dd'),
        Uint64.parseHex('0xb8ee335d88284cbe'),
        Uint64.parseHex('0xca2ad0fb56672500'),
        Uint64.parseHex('0x2301ef9c63ea84c5'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0x5e68478c4d6027a9'),
        Uint64.parseHex('0xc86182d1b4246b58'),
        Uint64.parseHex('0xd10f4cd52be97f6b'),
        Uint64.parseHex('0x029a5a47da79a488'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0x2cc4f962eaae2260'),
        Uint64.parseHex('0xf97fe46b6a925428'),
        Uint64.parseHex('0x2360d17d890e55cb'),
        Uint64.parseHex('0x32d7b16a7f11cc96'),
      ]),
    ],
    [
      PallasFp.fromRaw([
        Uint64.parseHex('0xc0cab915d5363d9f'),
        Uint64.parseHex('0xa5f2404cd7b35eb0'),
        Uint64.parseHex('0x18e857a98d498cf7'),
        Uint64.parseHex('0x26703e48c03b81ca'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0xf691123ae112b928'),
        Uint64.parseHex('0xf44388bd6b89221e'),
        Uint64.parseHex('0x88ac8d25a24603f1'),
        Uint64.parseHex('0x048682a35b3265bc'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0x3ab7defcb8d803e2'),
        Uint64.parseHex('0x91d6e1715164775e'),
        Uint64.parseHex('0xd72cddc6cf06b507'),
        Uint64.parseHex('0x06b1390441fa7030'),
      ]),
    ],
    [
      PallasFp.fromRaw([
        Uint64.parseHex('0xbcd795414a6e2e86'),
        Uint64.parseHex('0x43b360f6386a86d7'),
        Uint64.parseHex('0x1689426dce05fcd8'),
        Uint64.parseHex('0x31aa0eeb868c626d'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0xed77f5d576b99cc3'),
        Uint64.parseHex('0x90efd8f41b2078b2'),
        Uint64.parseHex('0x057abad3764c104b'),
        Uint64.parseHex('0x239464f75bf7b6af'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0xb2cb487307c1cecf'),
        Uint64.parseHex('0xa5cc47c59654b2a7'),
        Uint64.parseHex('0xa45e19ed813a54ab'),
        Uint64.parseHex('0x0a64d4c04fd426bd'),
      ]),
    ],
    [
      PallasFp.fromRaw([
        Uint64.parseHex('0x1f7315322f658735'),
        Uint64.parseHex('0x777c7a921a062e9d'),
        Uint64.parseHex('0x576a4ad259860fb1'),
        Uint64.parseHex('0x21fbbdbb73670734'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0x674324003fc52146'),
        Uint64.parseHex('0x5b86d29463d31564'),
        Uint64.parseHex('0xd9371ca2eb95acf3'),
        Uint64.parseHex('0x31b86f3cf01705d4'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0x7045f48aa4eb4f6f'),
        Uint64.parseHex('0x13541d65157ee1ce'),
        Uint64.parseHex('0x05ef1736d09056f6'),
        Uint64.parseHex('0x2bfde53354377c91'),
      ]),
    ],
    [
      PallasFp.fromRaw([
        Uint64.parseHex('0x5a13a58d20011e2f'),
        Uint64.parseHex('0xf4d5239c11d0eafa'),
        Uint64.parseHex('0xd558f36e65f8eca7'),
        Uint64.parseHex('0x1233ca936ec24671'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0x6e70af0a7a924b3a'),
        Uint64.parseHex('0x878058d0234a576f'),
        Uint64.parseHex('0xc437846d8e0b2b30'),
        Uint64.parseHex('0x27d452a43ac7dea2'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0xa02576b94392f980'),
        Uint64.parseHex('0x6a30641a1c3d87b2'),
        Uint64.parseHex('0xe816ea8da493e0fa'),
        Uint64.parseHex('0x2699dba82184e413'),
      ]),
    ],
    [
      PallasFp.fromRaw([
        Uint64.parseHex('0x608c6f7a61b56e55'),
        Uint64.parseHex('0xf18584664f8cab49'),
        Uint64.parseHex('0xc3988baee42e4b10'),
        Uint64.parseHex('0x36c722f0efcc8803'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0x6e49ac170dbb7fcd'),
        Uint64.parseHex('0x85c38899a7b5a833'),
        Uint64.parseHex('0x08b0f2ec89ccaa37'),
        Uint64.parseHex('0x02b3ff48861e339b'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0xa8c5ae03ad98e405'),
        Uint64.parseHex('0x6fc3ff4c49eb59ad'),
        Uint64.parseHex('0x60162f4427bc657b'),
        Uint64.parseHex('0x0b70d061d58d8a7f'),
      ]),
    ],
    [
      PallasFp.fromRaw([
        Uint64.parseHex('0x2e06cc4af33b0a06'),
        Uint64.parseHex('0xad3de8be46ed9693'),
        Uint64.parseHex('0xf8753adeb9d7cee2'),
        Uint64.parseHex('0x3fc2a13f127f96a4'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0xc12080ac117ee15f'),
        Uint64.parseHex('0x00cb3d621e171d80'),
        Uint64.parseHex('0x1bd63434ac8c419f'),
        Uint64.parseHex('0x0c41a6e48dd23a51'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0x9685213e9692f5e1'),
        Uint64.parseHex('0x72aaad7e4e75339d'),
        Uint64.parseHex('0xed4476537169084e'),
        Uint64.parseHex('0x2de8072a6bd86884'),
      ]),
    ],
    [
      PallasFp.fromRaw([
        Uint64.parseHex('0x0ad01184567b027c'),
        Uint64.parseHex('0xb81cf735cc9c39c0'),
        Uint64.parseHex('0x9d3496a3d9fe05ec'),
        Uint64.parseHex('0x03557a8f7b38a17f'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0x45bcb5ac00826abc'),
        Uint64.parseHex('0x060f43363d818e54'),
        Uint64.parseHex('0xee976d34282f1a37'),
        Uint64.parseHex('0x0b5f59552f498735'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0x2f2909e17e22b0df'),
        Uint64.parseHex('0xf5d646e57507e548'),
        Uint64.parseHex('0xfedbb18570dc7300'),
        Uint64.parseHex('0x0e2923a5fee7b878'),
      ]),
    ],
    [
      PallasFp.fromRaw([
        Uint64.parseHex('0xf71eed73f15b3326'),
        Uint64.parseHex('0xcf1cb37c3b032af6'),
        Uint64.parseHex('0xc787be97020a7fdd'),
        Uint64.parseHex('0x1d785005a7a00592'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0x0acfbfb223f8f00d'),
        Uint64.parseHex('0xa590b88a3b060294'),
        Uint64.parseHex('0x0ba5fedcb8f25bd2'),
        Uint64.parseHex('0x1ad772c273d9c6df'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0xc1ce13d60f2f5031'),
        Uint64.parseHex('0x810510eb61f0672d'),
        Uint64.parseHex('0xa78f3275c278234b'),
        Uint64.parseHex('0x027bd64785fcbd2a'),
      ]),
    ],
    [
      PallasFp.fromRaw([
        Uint64.parseHex('0x8337f5e07923a853'),
        Uint64.parseHex('0xe224313469457b8e'),
        Uint64.parseHex('0xce6f8ffea1031b6d'),
        Uint64.parseHex('0x20800f441b4a0526'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0xa33d7bed89a4408a'),
        Uint64.parseHex('0x36cdc8eed662ad37'),
        Uint64.parseHex('0x6eea2cd49f4312b4'),
        Uint64.parseHex('0x3d5ad61d7b65f938'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0x3bbbae94cc195284'),
        Uint64.parseHex('0x1df96cc03ea4b26d'),
        Uint64.parseHex('0x02c5f91be4dd8e3d'),
        Uint64.parseHex('0x13338bc351fc46dd'),
      ]),
    ],
    [
      PallasFp.fromRaw([
        Uint64.parseHex('0xc5271c297852819e'),
        Uint64.parseHex('0x646c49f9b46cbf19'),
        Uint64.parseHex('0xb87db1e2af3ea923'),
        Uint64.parseHex('0x25e52be507c92760'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0x5c380ab701b52ea9'),
        Uint64.parseHex('0xa34c83a3485c6b2d'),
        Uint64.parseHex('0x71096d8b1b983c98'),
        Uint64.parseHex('0x1c492d64c157aaa4'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0xa20c0b3da0da4ca3'),
        Uint64.parseHex('0xd43487bc288df682'),
        Uint64.parseHex('0xf4e6c5e7a573f592'),
        Uint64.parseHex('0x0c5b801579992718'),
      ]),
    ],
    [
      PallasFp.fromRaw([
        Uint64.parseHex('0x7ea33c93e40833cf'),
        Uint64.parseHex('0x584e9e62a7f9554e'),
        Uint64.parseHex('0x68695c0cd7cbf43d'),
        Uint64.parseHex('0x1090b1b4d2bebe7a'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0xe383e1ec3baa8d69'),
        Uint64.parseHex('0x1b218e35ecf2328e'),
        Uint64.parseHex('0x68f5ce5cbed19cad'),
        Uint64.parseHex('0x33e38018a801387a'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0xb76b0b3d787ee953'),
        Uint64.parseHex('0x5f4a02d28729e3ae'),
        Uint64.parseHex('0xeef8d83d0e876bac'),
        Uint64.parseHex('0x1654af18772b2da5'),
      ]),
    ],
    [
      PallasFp.fromRaw([
        Uint64.parseHex('0xef7ce6a013265477'),
        Uint64.parseHex('0xbb0893870367ec6c'),
        Uint64.parseHex('0x44742de88c5ab0d5'),
        Uint64.parseHex('0x1678be3cc9c67993'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0xaf5d47893348f766'),
        Uint64.parseHex('0xdaf1818355b13b4f'),
        Uint64.parseHex('0x7ff9c6be546e928a'),
        Uint64.parseHex('0x3780bd1e01f34c22'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0xa12380320d7cc1de'),
        Uint64.parseHex('0x5d11e69aa6c0b98c'),
        Uint64.parseHex('0x0786018e7cb77267'),
        Uint64.parseHex('0x1e83d6315c9f125b'),
      ]),
    ],
    [
      PallasFp.fromRaw([
        Uint64.parseHex('0x1799603e855ce731'),
        Uint64.parseHex('0xc486894d76e0c33b'),
        Uint64.parseHex('0x160b41552f2931c8'),
        Uint64.parseHex('0x354afd0a2f9d0b26'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0x8b997ee06be1bff3'),
        Uint64.parseHex('0x60b00dbe1faced07'),
        Uint64.parseHex('0x2d8affa62905c5a5'),
        Uint64.parseHex('0x00cd6d29f166eadc'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0x08d0641917082f2c'),
        Uint64.parseHex('0xc60d01973f183057'),
        Uint64.parseHex('0xdbe0e3d7cdbc66ef'),
        Uint64.parseHex('0x1d6219352768e3ae'),
      ]),
    ],
    [
      PallasFp.fromRaw([
        Uint64.parseHex('0xfa08dd9806387577'),
        Uint64.parseHex('0xafe3ca1db8d4f529'),
        Uint64.parseHex('0xe48d2370d7d1a142'),
        Uint64.parseHex('0x146336e25db5181d'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0xa901d3ce84de0ad4'),
        Uint64.parseHex('0x022e54b49c13d907'),
        Uint64.parseHex('0x997a21163e2e43df'),
        Uint64.parseHex('0x0005d8e085fd72ee'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0x1c36f31341964484'),
        Uint64.parseHex('0x6f8ebc1d2296021a'),
        Uint64.parseHex('0x0dd5e61c8a4e8642'),
        Uint64.parseHex('0x364e97c7a3893227'),
      ]),
    ],
    [
      PallasFp.fromRaw([
        Uint64.parseHex('0xd7a00c03d2e0baaa'),
        Uint64.parseHex('0xfa97ec80ad307a52'),
        Uint64.parseHex('0x561c6fff15346878'),
        Uint64.parseHex('0x01189910671bc16b'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0x63fd8ac57a95ca8c'),
        Uint64.parseHex('0x4c0f7e001df490aa'),
        Uint64.parseHex('0x5229dfaa01231a45'),
        Uint64.parseHex('0x162a7c80f4d2d12e'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0x32e69efb22f40b96'),
        Uint64.parseHex('0xcaff31b4fda32124'),
        Uint64.parseHex('0x2604e4afb09f8603'),
        Uint64.parseHex('0x2a0d6c09576666bb'),
      ]),
    ],
    [
      PallasFp.fromRaw([
        Uint64.parseHex('0xc0a0180f8cbfc0d2'),
        Uint64.parseHex('0xf444d10d63a74e2c'),
        Uint64.parseHex('0xe16a4d603d5a808e'),
        Uint64.parseHex('0x0978e5c51e1e5649'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0x03f4460ebc351b6e'),
        Uint64.parseHex('0x05087d903bdacfd1'),
        Uint64.parseHex('0xebe19bbdce251011'),
        Uint64.parseHex('0x1bdcee3aaca9cd25'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0xf61964bf3ade7670'),
        Uint64.parseHex('0x0c947321e0075e3f'),
        Uint64.parseHex('0xe49479140b1944fd'),
        Uint64.parseHex('0x1862cccb70b5b885'),
      ]),
    ],
    [
      PallasFp.fromRaw([
        Uint64.parseHex('0xc3267da6e94adc50'),
        Uint64.parseHex('0x39ee99c1cc6e5dda'),
        Uint64.parseHex('0xbc26cc883a1987e1'),
        Uint64.parseHex('0x1f3e91d863c16922'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0x0f85b4ac2c367406'),
        Uint64.parseHex('0xfa661465c656ad99'),
        Uint64.parseHex('0xef5c08f8478f663a'),
        Uint64.parseHex('0x1af47a48a6016a49'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0x0eabcd87e7d01b15'),
        Uint64.parseHex('0x1c3698b0a2e3da10'),
        Uint64.parseHex('0x009d57338c693505'),
        Uint64.parseHex('0x3c8ee901956e3d3f'),
      ]),
    ],
    [
      PallasFp.fromRaw([
        Uint64.parseHex('0x8b94772189673476'),
        Uint64.parseHex('0xe10ce2b7069f4dbd'),
        Uint64.parseHex('0x68d0b024f591b520'),
        Uint64.parseHex('0x1660a8cde7fec553'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0x9d8d0f67fdaa79d5'),
        Uint64.parseHex('0x3963c2c1f5586e2f'),
        Uint64.parseHex('0x1303936334dd1132'),
        Uint64.parseHex('0x0f6d991929d5e4e7'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0x7a433091e1ce2d3a'),
        Uint64.parseHex('0x4e7fda770712f343'),
        Uint64.parseHex('0xcc625eaaab52b4dc'),
        Uint64.parseHex('0x02b9cea1921cd9f6'),
      ]),
    ],
    [
      PallasFp.fromRaw([
        Uint64.parseHex('0x3797b2d8376043b3'),
        Uint64.parseHex('0xd8caf468976f0472'),
        Uint64.parseHex('0x214f7c6784acb565'),
        Uint64.parseHex('0x14a323b99b900331'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0x347fef2c00f0953a'),
        Uint64.parseHex('0x718b7fbc7788af78'),
        Uint64.parseHex('0xec01ea79642d5760'),
        Uint64.parseHex('0x190476b580cb9277'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0xff4e7e6fb268dfd7'),
        Uint64.parseHex('0x9660902b60087651'),
        Uint64.parseHex('0xa42463d30b442b6f'),
        Uint64.parseHex('0x090a3a9d869d2eef'),
      ]),
    ],
    [
      PallasFp.fromRaw([
        Uint64.parseHex('0xf983387ea0456203'),
        Uint64.parseHex('0xe365001304f9a11e'),
        Uint64.parseHex('0x0dbe8fd2270a6795'),
        Uint64.parseHex('0x3877a95586367567'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0x39c0af0fe01f4a06'),
        Uint64.parseHex('0x60118c53a2181352'),
        Uint64.parseHex('0x5df39a2cc63ddc0a'),
        Uint64.parseHex('0x2d894691240fe953'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0x1aca9eaf9bba9850'),
        Uint64.parseHex('0x5914e855eeb44aa1'),
        Uint64.parseHex('0x7ef7178020166189'),
        Uint64.parseHex('0x21b9c18292bdbc59'),
      ]),
    ],
    [
      PallasFp.fromRaw([
        Uint64.parseHex('0x33f509a74ad9d39b'),
        Uint64.parseHex('0x272e1cc6c36a2968'),
        Uint64.parseHex('0x505a05f2a6ae834c'),
        Uint64.parseHex('0x2fe76be7cff723e2'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0x0df9fa97277fa8b4'),
        Uint64.parseHex('0xd15bff840ddae8a5'),
        Uint64.parseHex('0x929981d7cfce253b'),
        Uint64.parseHex('0x187aa448f391e3ca'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0xf0c66af5ffc73736'),
        Uint64.parseHex('0x663ccf7b2ffe4b5e'),
        Uint64.parseHex('0x007ab3aa3617f422'),
        Uint64.parseHex('0x0b7083ad751707bf'),
      ]),
    ],
    [
      PallasFp.fromRaw([
        Uint64.parseHex('0x2f9b20f1fbd49791'),
        Uint64.parseHex('0x1975b962f6cb8e0b'),
        Uint64.parseHex('0x3bc4ca9902c52acb'),
        Uint64.parseHex('0x030ddbb470493f16'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0x3a1c62ca8fbf2525'),
        Uint64.parseHex('0x8fb8ab9d60ea17b2'),
        Uint64.parseHex('0x950b0ab18d3546df'),
        Uint64.parseHex('0x3130fbaffb5aa82a'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0x43a876180dc382e0'),
        Uint64.parseHex('0x15ce2ead2fcd051e'),
        Uint64.parseHex('0x4f74d74bac2ee457'),
        Uint64.parseHex('0x337f544707c430f0'),
      ]),
    ],
    [
      PallasFp.fromRaw([
        Uint64.parseHex('0x26de98a8736d1d11'),
        Uint64.parseHex('0x7d8e471a9fb95fef'),
        Uint64.parseHex('0xac9d91b0930dac75'),
        Uint64.parseHex('0x349979919015394f'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0xccfcb61831d5c775'),
        Uint64.parseHex('0x3bf93da6fff31d95'),
        Uint64.parseHex('0x2305cd7a921ec5f1'),
        Uint64.parseHex('0x027cc4efe3fb35dd'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0xc3fa2629635d27de'),
        Uint64.parseHex('0x67f1c6b7314764af'),
        Uint64.parseHex('0x61b71a3698682ad2'),
        Uint64.parseHex('0x037f9f2365954c5b'),
      ]),
    ],
    [
      PallasFp.fromRaw([
        Uint64.parseHex('0x77c5b024848371ae'),
        Uint64.parseHex('0x60414abe362d01c9'),
        Uint64.parseHex('0x10f1cc6df8b4bcd7'),
        Uint64.parseHex('0x1f697cac4d07feb7'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0x786add244aa0ef29'),
        Uint64.parseHex('0x3145c478063109d6'),
        Uint64.parseHex('0x26e6c851fbd572a6'),
        Uint64.parseHex('0x267a750fe5d7cfbc'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0x180e2b4d3e756f65'),
        Uint64.parseHex('0xaf285fa82ce4fae5'),
        Uint64.parseHex('0x678c9996d9a472c8'),
        Uint64.parseHex('0x0c91feab4a43193a'),
      ]),
    ],
    [
      PallasFp.fromRaw([
        Uint64.parseHex('0x79c47c573ac410f7'),
        Uint64.parseHex('0x7e3b83af4a4ba3ba'),
        Uint64.parseHex('0x2186c3038ea05e69'),
        Uint64.parseHex('0x1745569a0a3e3014'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0x1e0388522696191f'),
        Uint64.parseHex('0xfdff66c6f3b5ffe1'),
        Uint64.parseHex('0xeca5120778a56711'),
        Uint64.parseHex('0x29863d546e7e7c0d'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0x2f225e6366bfe390'),
        Uint64.parseHex('0xa79a03df833994c6'),
        Uint64.parseHex('0xbf06bae49ef853f6'),
        Uint64.parseHex('0x1148d6ab2bd00192'),
      ]),
    ],
    [
      PallasFp.fromRaw([
        Uint64.parseHex('0xf4f6331a8b265d15'),
        Uint64.parseHex('0xf745f45d350d41d4'),
        Uint64.parseHex('0xe18b1499060da366'),
        Uint64.parseHex('0x02e0e121b0f3dfef'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0x078ae6aa151054b7'),
        Uint64.parseHex('0x690401736d44a653'),
        Uint64.parseHex('0xb89ef73a40a2b274'),
        Uint64.parseHex('0x0d0aa46e76a6a278'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0x9a4d532c7b6e0958'),
        Uint64.parseHex('0x392dde710f1f06db'),
        Uint64.parseHex('0xeee545f3fa6d3d08'),
        Uint64.parseHex('0x13943675b04aa986'),
      ]),
    ],
    [
      PallasFp.fromRaw([
        Uint64.parseHex('0x961fc818dcbb66b5'),
        Uint64.parseHex('0xc9f2b3257530dafe'),
        Uint64.parseHex('0xd97a11d63088f5d9'),
        Uint64.parseHex('0x2901ec61942d34aa'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0xfdf544b963d1fdc7'),
        Uint64.parseHex('0x22ffa2a2af9fa3e3'),
        Uint64.parseHex('0xf431d54434a3e0cf'),
        Uint64.parseHex('0x20204a2105d22e7e'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0x1211b9e2190d6852'),
        Uint64.parseHex('0xa004abe8e01528c4'),
        Uint64.parseHex('0x5c1e3e9e27a571c3'),
        Uint64.parseHex('0x3a8a628295121d5c'),
      ]),
    ],
  ];

  // mds matrix:
  static final List<List<PallasFp>> mds = [
    [
      PallasFp.fromRaw([
        Uint64.parseHex('0x323f2486d7e11b63'),
        Uint64.parseHex('0x97d7a0ab23850b56'),
        Uint64.parseHex('0xb3d59fbdc8c9ead4'),
        Uint64.parseHex('0x0ab5e5b874a68de7'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0x8eca5596e996ab5e'),
        Uint64.parseHex('0x240d4a7cbf735736'),
        Uint64.parseHex('0x293f0f0d886c7954'),
        Uint64.parseHex('0x31916628e58a5abb'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0x19d1cf25d8e8345d'),
        Uint64.parseHex('0xa0a3b71a5fb15735'),
        Uint64.parseHex('0xd803952bbb364fdf'),
        Uint64.parseHex('0x07c045d5f5e9e5a6'),
      ]),
    ],
    [
      PallasFp.fromRaw([
        Uint64.parseHex('0xd049cdc8d085167c'),
        Uint64.parseHex('0x3a0a464048bd770a'),
        Uint64.parseHex('0xf8e24f66822c2d9f'),
        Uint64.parseHex('0x233162630ebf9ed7'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0x402270113e047a2e'),
        Uint64.parseHex('0x78f8365c85bbab07'),
        Uint64.parseHex('0xb36664548d60957d'),
        Uint64.parseHex('0x25cae2599892a8b0'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0xf84d806f685f747a'),
        Uint64.parseHex('0x9aad3d8262efd83f'),
        Uint64.parseHex('0x74938717989a1957'),
        Uint64.parseHex('0x22f5b5e1e6081c97'),
      ]),
    ],
    [
      PallasFp.fromRaw([
        Uint64.parseHex('0xfee7a9944f84dbe4'),
        Uint64.parseHex('0x21680eabc56bc15d'),
        Uint64.parseHex('0xf333aa91c3833464'),
        Uint64.parseHex('0x2e29dd59c64b1037'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0xc771effa43263664'),
        Uint64.parseHex('0xcbeaf48b3a0624c3'),
        Uint64.parseHex('0x92d15e7dceef1665'),
        Uint64.parseHex('0x1d1aab4ec1cd6788'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0x15639415f6e85ef1'),
        Uint64.parseHex('0x75872c39b59a31f6'),
        Uint64.parseHex('0x51e0cbead65516b9'),
        Uint64.parseHex('0x3bf763086a189364'),
      ]),
    ],
  ];

  static final List<List<PallasFp>> mdsInv = [
    [
      PallasFp.fromRaw([
        Uint64.parseHex('0xc6de463cd1404e6b'),
        Uint64.parseHex('0x4543705f35e98ab5'),
        Uint64.parseHex('0xcc59ffd00de86443'),
        Uint64.parseHex('0x2cc057f3fa14687a'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0x171840417cab7576'),
        Uint64.parseHex('0xfadbf8ae7ae24796'),
        Uint64.parseHex('0x5fd72b55df208385'),
        Uint64.parseHex('0x32e7c439f2f967e5'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0x942645bd7d4464e0'),
        Uint64.parseHex('0x1403db6f50302040'),
        Uint64.parseHex('0xf461778abf6c91fa'),
        Uint64.parseHex('0x2eae5df8c3115969'),
      ]),
    ],
    [
      PallasFp.fromRaw([
        Uint64.parseHex('0xa1ca1516a4a1a6a0'),
        Uint64.parseHex('0x13f074fde9a18b29'),
        Uint64.parseHex('0xdb18b4aefe68d26d'),
        Uint64.parseHex('0x07bf368481067199'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0xe82425bc1b23a059'),
        Uint64.parseHex('0xbb1d65040c85c1bf'),
        Uint64.parseHex('0x018a918b9dac5dad'),
        Uint64.parseHex('0x2aec6906c63f3cf1'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0xe0541adf238e0781'),
        Uint64.parseHex('0x76b2a7139db71b36'),
        Uint64.parseHex('0x1215944a64a246b2'),
        Uint64.parseHex('0x0952e0243aec2af0'),
      ]),
    ],
    [
      PallasFp.fromRaw([
        Uint64.parseHex('0x2a418d8d73a7c908'),
        Uint64.parseHex('0xaef9112e952fdbb5'),
        Uint64.parseHex('0x723a63a0c09dab26'),
        Uint64.parseHex('0x2fcbba6f9159a219'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0x76efab42d4fba90b'),
        Uint64.parseHex('0xc5e4960d7424cd37'),
        Uint64.parseHex('0xb4ddd4b4d6452256'),
        Uint64.parseHex('0x1ec7372574f3851b'),
      ]),
      PallasFp.fromRaw([
        Uint64.parseHex('0xadc8933c6f3c72ee'),
        Uint64.parseHex('0x87a7435d30f8be81'),
        Uint64.parseHex('0x3c26fa4b7d25b1e4'),
        Uint64.parseHex('0x0d0c2efd6472f12a'),
      ]),
    ],
  ];
}

class _PoseidonFQConstants {
  // Number of round constants: 192
  // Round constants for GF(p):
  static final List<List<VestaFq>> roundConstants = [
    [
      VestaFq.fromRaw([
        Uint64.parseHex('0x57538c2596426303'),
        Uint64.parseHex('0x4e71162f31003b70'),
        Uint64.parseHex('0x353f628f76d110f3'),
        Uint64.parseHex('0x360d7470611e473d'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0xbdb74213bf63188b'),
        Uint64.parseHex('0x4908ac2f12ebe06f'),
        Uint64.parseHex('0x5dc3c6c5febfaa31'),
        Uint64.parseHex('0x2bab94d7ae222d13'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0x0939d92753cc5dc8'),
        Uint64.parseHex('0xef77e7d736766c5d'),
        Uint64.parseHex('0x2bf03e1a29aa871f'),
        Uint64.parseHex('0x150c93fef652fb1c'),
      ]),
    ],
    [
      VestaFq.fromRaw([
        Uint64.parseHex('0x14259dce537782b2'),
        Uint64.parseHex('0x03cc0a60141e894e'),
        Uint64.parseHex('0x955d55db56dc57c1'),
        Uint64.parseHex('0x3270661e68928b3a'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0xce9fb9ffc345afb3'),
        Uint64.parseHex('0xb407c370f2b5a1cc'),
        Uint64.parseHex('0xa0b7afe4e2057299'),
        Uint64.parseHex('0x073f116f04122e25'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0x8ebad76fc71554d8'),
        Uint64.parseHex('0x55c9cd2061ae93ca'),
        Uint64.parseHex('0x7affd09c1f53f5fd'),
        Uint64.parseHex('0x2a32ec5c4ee5b183'),
      ]),
    ],
    [
      VestaFq.fromRaw([
        Uint64.parseHex('0x2d8ccbe292efeead'),
        Uint64.parseHex('0x634d24fc6e2559f2'),
        Uint64.parseHex('0x651e2cfc740628ca'),
        Uint64.parseHex('0x270326ee039df19e'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0xa068fc37c182e274'),
        Uint64.parseHex('0x8af895bce012f182'),
        Uint64.parseHex('0xdc100fe7fcfa5491'),
        Uint64.parseHex('0x27c6642ac633bc66'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0x9ca18682e26d7ff9'),
        Uint64.parseHex('0x710e1fb6ab976a45'),
        Uint64.parseHex('0xd27f57396989129d'),
        Uint64.parseHex('0x1bdfd8b01401c70a'),
      ]),
    ],
    [
      VestaFq.fromRaw([
        Uint64.parseHex('0xc832d824261a35ea'),
        Uint64.parseHex('0xf4f6fb3f9054d373'),
        Uint64.parseHex('0x14b9d6a9c84dd678'),
        Uint64.parseHex('0x162a14c62f9a89b8'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0xf79824667b5b6bec'),
        Uint64.parseHex('0xac0a1fc71e2cf0c0'),
        Uint64.parseHex('0x2af6f79e3127feea'),
        Uint64.parseHex('0x2d193e0f76de586b'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0x5d0bf58dc8a4aa94'),
        Uint64.parseHex('0x4feff82984990ff8'),
        Uint64.parseHex('0x81696ef1104e674f'),
        Uint64.parseHex('0x044ca3cc4a85d73b'),
      ]),
    ],
    [
      VestaFq.fromRaw([
        Uint64.parseHex('0x6198785f0cd6b9af'),
        Uint64.parseHex('0xb8d9e2d4f314f46f'),
        Uint64.parseHex('0x1d0453416d3e235c'),
        Uint64.parseHex('0x1cbaf2b371dac6a8'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0x343e07610f3fede5'),
        Uint64.parseHex('0x293c4ab038fdbbdc'),
        Uint64.parseHex('0x0e6c49d061b6b5f4'),
        Uint64.parseHex('0x1d5b2777692c205b'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0xf60e971b8d73b04f'),
        Uint64.parseHex('0x06a9adb0c1e6f962'),
        Uint64.parseHex('0xaa30535bdd749a7e'),
        Uint64.parseHex('0x2e9bdbba3dd34bff'),
      ]),
    ],
    [
      VestaFq.fromRaw([
        Uint64.parseHex('0x035a13661f22418b'),
        Uint64.parseHex('0xde40fbe26d047b05'),
        Uint64.parseHex('0x8bd5bae36969299f'),
        Uint64.parseHex('0x2de11886b18011ca'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0xbc998884ba96a721'),
        Uint64.parseHex('0x2ab9395c449be947'),
        Uint64.parseHex('0x0d5b4a3f1841dcd8'),
        Uint64.parseHex('0x2e07de1780b8a70d'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0x825e4c2bb74925ca'),
        Uint64.parseHex('0x250440a99d6b8af3'),
        Uint64.parseHex('0xbbdb63dbd52dad16'),
        Uint64.parseHex('0x0f69f1854d20ca0c'),
      ]),
    ],
    [
      VestaFq.fromRaw([
        Uint64.parseHex('0x816c059422dc705e'),
        Uint64.parseHex('0x6ce5113507f96de9'),
        Uint64.parseHex('0x0d135dc639fb09a4'),
        Uint64.parseHex('0x2eb1b25417fe1767'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0xb8b1bdf4953bd82c'),
        Uint64.parseHex('0xff36c661d26cc42d'),
        Uint64.parseHex('0x8c24cb44c3fab48a'),
        Uint64.parseHex('0x115cd0a0643cfb98'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0xde801612311d04cd'),
        Uint64.parseHex('0xbb57ddf14e0f958a'),
        Uint64.parseHex('0x066d7378b999868b'),
        Uint64.parseHex('0x26ca293f7b2c462d'),
      ]),
    ],
    [
      VestaFq.fromRaw([
        Uint64.parseHex('0xf5209d14b24820ca'),
        Uint64.parseHex('0x0f160bf9f71e967f'),
        Uint64.parseHex('0x2a830aa162412cd9'),
        Uint64.parseHex('0x17bf1b93c4c7e01a'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0x05c86f2e7dc293c5'),
        Uint64.parseHex('0xe03c0354bd8cfd38'),
        Uint64.parseHex('0xa24f8456369c85df'),
        Uint64.parseHex('0x35b41a7ac4f3c571'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0x72ac156af435d09e'),
        Uint64.parseHex('0x64e14d3beb2dddde'),
        Uint64.parseHex('0x435927994849bea9'),
        Uint64.parseHex('0x3b1480080523c439'),
      ]),
    ],
    [
      VestaFq.fromRaw([
        Uint64.parseHex('0x271618d874b14c6d'),
        Uint64.parseHex('0x08e286442a2d3eb2'),
        Uint64.parseHex('0x4950856dc907d575'),
        Uint64.parseHex('0x2cc6810031dc1b0d'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0x91f318c09f0cb566'),
        Uint64.parseHex('0x9e517aa93b78341d'),
        Uint64.parseHex('0x059618e2afd2ef99'),
        Uint64.parseHex('0x25bdbbeda1bde8c1'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0xc6313487073f7f7b'),
        Uint64.parseHex('0x2a5ed0a27b61926c'),
        Uint64.parseHex('0xb95f33c25dde8ac0'),
        Uint64.parseHex('0x392a4a8758e06ee8'),
      ]),
    ],
    [
      VestaFq.fromRaw([
        Uint64.parseHex('0xe7bbcef02eb5866c'),
        Uint64.parseHex('0x5e6a6fd15db89365'),
        Uint64.parseHex('0x9aa6111f4de00948'),
        Uint64.parseHex('0x272a55878a08442b'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0x9b925b3c5b21e0e2'),
        Uint64.parseHex('0xa6ebba011694dd12'),
        Uint64.parseHex('0xefa13c4e60e26239'),
        Uint64.parseHex('0x2d5b308b0cf02cdf'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0xef38c57c311673ac'),
        Uint64.parseHex('0x44dff42f18b46c56'),
        Uint64.parseHex('0xdd5d293d72e2e5f2'),
        Uint64.parseHex('0x16549fc6af2f3b72'),
      ]),
    ],
    [
      VestaFq.fromRaw([
        Uint64.parseHex('0x9b7126d9b46860df'),
        Uint64.parseHex('0x7639826534420311'),
        Uint64.parseHex('0xfa69c3a2ad52f76d'),
        Uint64.parseHex('0x1b10bb7a82afce39'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0x90d27f6a00b7dfc8'),
        Uint64.parseHex('0xd1b36968ba0405c0'),
        Uint64.parseHex('0xc79c2df7dc98a3be'),
        Uint64.parseHex('0x0f1e7505ebd91d2f'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0xff457756b819bb20'),
        Uint64.parseHex('0x797fd6e3f18eb1ca'),
        Uint64.parseHex('0x537a7497a3b43f46'),
        Uint64.parseHex('0x2f313faf0d3f6187'),
      ]),
    ],
    [
      VestaFq.fromRaw([
        Uint64.parseHex('0xf0bc3e732ecb26f6'),
        Uint64.parseHex('0x5cad11ebf0f7ceb8'),
        Uint64.parseHex('0xfa3ca61c0ed15bc5'),
        Uint64.parseHex('0x3a5cbb6de450b481'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0x865527cbca915982'),
        Uint64.parseHex('0x51baa6e20f892b62'),
        Uint64.parseHex('0xd92086e253b439d6'),
        Uint64.parseHex('0x3dab54bc9bef688d'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0x368045acf2b71ae3'),
        Uint64.parseHex('0x4c24b33b410fefd4'),
        Uint64.parseHex('0xe280d31670123f74'),
        Uint64.parseHex('0x06dbfb42b979884d'),
      ]),
    ],
    [
      VestaFq.fromRaw([
        Uint64.parseHex('0xa7fc32d22f18b9d3'),
        Uint64.parseHex('0xb8d2de72e3d2c9ec'),
        Uint64.parseHex('0xc6f039ea1973a63e'),
        Uint64.parseHex('0x068d6b4608aae810'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0x2b5dfcc5572555df'),
        Uint64.parseHex('0xb868a7d7e1f1f69a'),
        Uint64.parseHex('0x0ee258c9b8fdfccd'),
        Uint64.parseHex('0x366ebfafa3ad381c'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0xe6bc229e95bc76b1'),
        Uint64.parseHex('0x7ef66d89d044d022'),
        Uint64.parseHex('0x04db3024f41d3f56'),
        Uint64.parseHex('0x39678f65512f1ee4'),
      ]),
    ],
    [
      VestaFq.fromRaw([
        Uint64.parseHex('0xe534c88fe53d85fe'),
        Uint64.parseHex('0xcf82c25f99dc01a4'),
        Uint64.parseHex('0xd58b7750a3bc2fe1'),
        Uint64.parseHex('0x21668f016a8063c0'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0x4bef429bc5331608'),
        Uint64.parseHex('0xe34dea56439fe195'),
        Uint64.parseHex('0x1bc749363e98a768'),
        Uint64.parseHex('0x39d00994a8a5046a'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0x770c956f60d881b3'),
        Uint64.parseHex('0xb163d41605d39f99'),
        Uint64.parseHex('0x6b203bbe12fb3425'),
        Uint64.parseHex('0x1f9dbdc3f8431263'),
      ]),
    ],
    [
      VestaFq.fromRaw([
        Uint64.parseHex('0x9794a9f7c336eab2'),
        Uint64.parseHex('0xbe0bc829fe5e66c6'),
        Uint64.parseHex('0xe5f17b9e0ee0cab6'),
        Uint64.parseHex('0x027745a9cddfad95'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0x52025657abd8aee0'),
        Uint64.parseHex('0x2fa43fe20a45c78d'),
        Uint64.parseHex('0x788d695c61e93212'),
        Uint64.parseHex('0x1cec0803c504b635'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0xd3872a9559a03a73'),
        Uint64.parseHex('0xed5082c8dbf31365'),
        Uint64.parseHex('0x72077448ef87cc6e'),
        Uint64.parseHex('0x123523d75e9fabc1'),
      ]),
    ],
    [
      VestaFq.fromRaw([
        Uint64.parseHex('0x001779e3a1d357f4'),
        Uint64.parseHex('0x27feba35975ee7e5'),
        Uint64.parseHex('0xf419b848e5d694bf'),
        Uint64.parseHex('0x1723d1452c9cf02d'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0x9dab1ee4dcf96622'),
        Uint64.parseHex('0x21c3f776f572836d'),
        Uint64.parseHex('0xfcc0573d7e613694'),
        Uint64.parseHex('0x1739d180a16010bd'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0x70290452042d048d'),
        Uint64.parseHex('0xfafa96fbeb0ab893'),
        Uint64.parseHex('0xacce32391794b627'),
        Uint64.parseHex('0x2d4e6354da9cc554'),
      ]),
    ],
    [
      VestaFq.fromRaw([
        Uint64.parseHex('0x670bcf6f8b485dcd'),
        Uint64.parseHex('0x8f3bd43f99260621'),
        Uint64.parseHex('0x4a869553c9d007f8'),
        Uint64.parseHex('0x153ee6142e535e33'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0xd258d2e2b7782172'),
        Uint64.parseHex('0x968ad4424af83700'),
        Uint64.parseHex('0x635ef7e7a430b486'),
        Uint64.parseHex('0x0c45bfd3a69aaa65'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0x0e5633d251f73307'),
        Uint64.parseHex('0x6897ac0a8ffa5ff1'),
        Uint64.parseHex('0xf2d56aec83144600'),
        Uint64.parseHex('0x0adfd53b256a6957'),
      ]),
    ],
    [
      VestaFq.fromRaw([
        Uint64.parseHex('0xac9d36a8b7516d63'),
        Uint64.parseHex('0x3f87b28f1c1be4bd'),
        Uint64.parseHex('0x8cd1726b7cbab8ee'),
        Uint64.parseHex('0x315d2ac8ebdbac3c'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0x299ce44ea423d8e1'),
        Uint64.parseHex('0xc9bb60d1f6959879'),
        Uint64.parseHex('0xcfaec23d2b16883f'),
        Uint64.parseHex('0x1b8472712d02eef4'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0xc4a5404198adf70c'),
        Uint64.parseHex('0x367d2c54e36928c9'),
        Uint64.parseHex('0xbd0b70fa2255eb6f'),
        Uint64.parseHex('0x3c1cd07efda6ff24'),
      ]),
    ],
    [
      VestaFq.fromRaw([
        Uint64.parseHex('0xbbe523aef9ab107a'),
        Uint64.parseHex('0x4a16073f738f7e0c'),
        Uint64.parseHex('0x687f4e51b2e1dcd3'),
        Uint64.parseHex('0x136052d26bb3d373'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0x676c36c24ef967dd'),
        Uint64.parseHex('0x7b3cfbb873032681'),
        Uint64.parseHex('0xc1bdd859a1232a1d'),
        Uint64.parseHex('0x16c96beef6a0a848'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0x067eec7f2d6340c4'),
        Uint64.parseHex('0x012387bab4f1662d'),
        Uint64.parseHex('0x2ab7fed8f499a9fb'),
        Uint64.parseHex('0x284b38c57ff65c26'),
      ]),
    ],
    [
      VestaFq.fromRaw([
        Uint64.parseHex('0xaf1dff204c922f86'),
        Uint64.parseHex('0xfc06772c1c0411a6'),
        Uint64.parseHex('0x39e242198897d17c'),
        Uint64.parseHex('0x0c5993d175e81f66'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0xbbf53f67b1f87b15'),
        Uint64.parseHex('0xf24887ad48e17759'),
        Uint64.parseHex('0xfcda655d1ba9c8f9'),
        Uint64.parseHex('0x03bf7a3f7bd043da'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0x9b5cd09e36d8be62'),
        Uint64.parseHex('0x4c8f9cbe69f0e827'),
        Uint64.parseHex('0xb0cf999567f00e73'),
        Uint64.parseHex('0x3188fe4ee9f9fafb'),
      ]),
    ],
    [
      VestaFq.fromRaw([
        Uint64.parseHex('0xafea99a2ec6c595a'),
        Uint64.parseHex('0x3af5bf77c1c42652'),
        Uint64.parseHex('0x5a39768c480d61e1'),
        Uint64.parseHex('0x171f528ccf658437'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0x5a0563b9b8e9f1d5'),
        Uint64.parseHex('0x812c3286ee700067'),
        Uint64.parseHex('0x196e41859b35ef88'),
        Uint64.parseHex('0x12f4175c4ab45afc'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0x0e74d4d369118b79'),
        Uint64.parseHex('0x7e23e1aabe96cfab'),
        Uint64.parseHex('0x8f8fdcf800a9ac69'),
        Uint64.parseHex('0x3a509e155cb7ebfd'),
      ]),
    ],
    [
      VestaFq.fromRaw([
        Uint64.parseHex('0x98712c65678cfd30'),
        Uint64.parseHex('0x984bc8f2e4c1b69e'),
        Uint64.parseHex('0x1a89920e2504c3b3'),
        Uint64.parseHex('0x10f2a685df4a27c8'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0xe8a16728cc9d4918'),
        Uint64.parseHex('0x54573c9333c56321'),
        Uint64.parseHex('0x1d8d93d54ab91a0e'),
        Uint64.parseHex('0x09e5f49790c8a0e2'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0x609a740347cf5fea'),
        Uint64.parseHex('0x42d17ed6ee0fab7e'),
        Uint64.parseHex('0x2bf35705d9f84a34'),
        Uint64.parseHex('0x352d69bed80ee3e5'),
      ]),
    ],
    [
      VestaFq.fromRaw([
        Uint64.parseHex('0x3a758af6fa84e0e8'),
        Uint64.parseHex('0xc634debd281b76a6'),
        Uint64.parseHex('0x491562faf2b190d3'),
        Uint64.parseHex('0x058ee73ba9f3f293'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0x621a132510a43904'),
        Uint64.parseHex('0x092cb92119bc76be'),
        Uint64.parseHex('0xcd0f1fc55b1a3250'),
        Uint64.parseHex('0x232f99cc911eddd9'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0xc3b97c1e301bc213'),
        Uint64.parseHex('0xf9efd52ca6bc2961'),
        Uint64.parseHex('0x86c22c6c5d4869f0'),
        Uint64.parseHex('0x201beed7b8f3ab81'),
      ]),
    ],
    [
      VestaFq.fromRaw([
        Uint64.parseHex('0xbf6b3431ba94e9bc'),
        Uint64.parseHex('0x29388842744a1210'),
        Uint64.parseHex('0xa1c9291d58602f51'),
        Uint64.parseHex('0x1376dce6580030c6'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0x6454843c5486d7b3'),
        Uint64.parseHex('0x072ba8b02d92e722'),
        Uint64.parseHex('0x2b3356c38238f761'),
        Uint64.parseHex('0x1793199e6fd6ba34'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0x06a3f1d3b433311b'),
        Uint64.parseHex('0x3c66160dc62aacac'),
        Uint64.parseHex('0x9fee9c20c87a67df'),
        Uint64.parseHex('0x22de7a7488dcc735'),
      ]),
    ],
    [
      VestaFq.fromRaw([
        Uint64.parseHex('0x30d6e3fd516b47a8'),
        Uint64.parseHex('0xdbe0b77fae77e1d0'),
        Uint64.parseHex('0xdf8ff37fe2d8edf8'),
        Uint64.parseHex('0x3514d5e9066bb160'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0x19377427137a81c7'),
        Uint64.parseHex('0xff453d6f900f144a'),
        Uint64.parseHex('0xf919a00dabbf5fa5'),
        Uint64.parseHex('0x30cd3006931ad636'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0x5b6a74220692b506'),
        Uint64.parseHex('0x8f9e4b2cae2ebb51'),
        Uint64.parseHex('0x41f81a5cf613c8df'),
        Uint64.parseHex('0x253d1a5c52934127'),
      ]),
    ],
    [
      VestaFq.fromRaw([
        Uint64.parseHex('0x73f666cb86a48e8e'),
        Uint64.parseHex('0x851b3a59c990fafc'),
        Uint64.parseHex('0xa35e9613e7f5fe92'),
        Uint64.parseHex('0x035b461c02d79d19'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0x7cfbf86a3aa04780'),
        Uint64.parseHex('0x92b1283c2d5fccde'),
        Uint64.parseHex('0x5bc00eedd56b93e0'),
        Uint64.parseHex('0x23a9928079d175bd'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0xf1e4ccd73fa00a82'),
        Uint64.parseHex('0xb5e2ea3436eef957'),
        Uint64.parseHex('0xf1594a0763c611ab'),
        Uint64.parseHex('0x13a7785ae134ea92'),
      ]),
    ],
    [
      VestaFq.fromRaw([
        Uint64.parseHex('0xbbf04f5252de4279'),
        Uint64.parseHex('0x3889c57863446d88'),
        Uint64.parseHex('0x4962ae3c0da17e31'),
        Uint64.parseHex('0x39fce308b7d43c57'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0x3b57e34489b53fad'),
        Uint64.parseHex('0xbef00a08c6ed38d2'),
        Uint64.parseHex('0xc0fdf01662f60d22'),
        Uint64.parseHex('0x1aae18833f8e1d3a'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0x55513e033398513f'),
        Uint64.parseHex('0x27c1b3fd8f85d8a8'),
        Uint64.parseHex('0x8b2e80c064fd83ed'),
        Uint64.parseHex('0x1a761ce82400af01'),
      ]),
    ],
    [
      VestaFq.fromRaw([
        Uint64.parseHex('0x5244ca749b73e481'),
        Uint64.parseHex('0xdcf6af2830a50287'),
        Uint64.parseHex('0x16dd1a87ca22e1cc'),
        Uint64.parseHex('0x275a03e45adda7c3'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0x58a253cfb6a95786'),
        Uint64.parseHex('0x07e561453fc5648b'),
        Uint64.parseHex('0xeb08e47e5feabcf8'),
        Uint64.parseHex('0x2e5a10f08b5ab8bb'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0xe033d82cefe78ce3'),
        Uint64.parseHex('0xc141a5b6d594bec4'),
        Uint64.parseHex('0xb84e9c333b2932f1'),
        Uint64.parseHex('0x1459cb8587208473'),
      ]),
    ],
    [
      VestaFq.fromRaw([
        Uint64.parseHex('0x5cec7e7b338fbe1b'),
        Uint64.parseHex('0x52f9332fbffcfbbd'),
        Uint64.parseHex('0x7b92ce810e14a400'),
        Uint64.parseHex('0x193ae5921d78b5de'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0x60224be67248e82c'),
        Uint64.parseHex('0x374384f4a0728205'),
        Uint64.parseHex('0x89111fb2c4660281'),
        Uint64.parseHex('0x3097898a5d0011a4'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0x549980de862930f5'),
        Uint64.parseHex('0x1979b2d1c465b4d9'),
        Uint64.parseHex('0x571782fd96ce54b4'),
        Uint64.parseHex('0x378d97bf8c864ae7'),
      ]),
    ],
    [
      VestaFq.fromRaw([
        Uint64.parseHex('0x37ea32a971d17884'),
        Uint64.parseHex('0xdbc7f5cb46093421'),
        Uint64.parseHex('0x88136287ce376b08'),
        Uint64.parseHex('0x2eb04ea7c01d97ec'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0xead3726f1af2e7b0'),
        Uint64.parseHex('0x861cbda476804e6c'),
        Uint64.parseHex('0x2302a1c22e49baec'),
        Uint64.parseHex('0x36425347ea03f641'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0xecd627e59590d09e'),
        Uint64.parseHex('0x3f5b5ca5a19a9701'),
        Uint64.parseHex('0xcc996cd85c98a1d8'),
        Uint64.parseHex('0x26b72df47408ad42'),
      ]),
    ],
    [
      VestaFq.fromRaw([
        Uint64.parseHex('0x59bece31f0a31e95'),
        Uint64.parseHex('0xde01212ee4588f89'),
        Uint64.parseHex('0x1f05636c610b89aa'),
        Uint64.parseHex('0x130180e44e2924db'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0x9ea8e7bc79263550'),
        Uint64.parseHex('0xdf7793cc89e5b52f'),
        Uint64.parseHex('0x73275acaed5f579c'),
        Uint64.parseHex('0x219e97737d3979ba'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0x9c12635df251d153'),
        Uint64.parseHex('0x3b0672dd7d42cbb4'),
        Uint64.parseHex('0x3461363f81c489a2'),
        Uint64.parseHex('0x3cdb93598a5ca528'),
      ]),
    ],
    [
      VestaFq.fromRaw([
        Uint64.parseHex('0x2861ce16f219d5a9'),
        Uint64.parseHex('0x4ad0447045a7c5aa'),
        Uint64.parseHex('0x20724b927a0ca81c'),
        Uint64.parseHex('0x0e59e6f332d7ed37'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0x43b0a3fcff2036bd'),
        Uint64.parseHex('0x172cc07b9d33fbf9'),
        Uint64.parseHex('0x3d7369467222697a'),
        Uint64.parseHex('0x1b064342d51a4275'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0x3eb310228a0e5f6c'),
        Uint64.parseHex('0x78fa9fb9171221b7'),
        Uint64.parseHex('0x2f363c55b2882e0b'),
        Uint64.parseHex('0x30b82a998cbd8e8a'),
      ]),
    ],
    [
      VestaFq.fromRaw([
        Uint64.parseHex('0xe46f6d4298740107'),
        Uint64.parseHex('0x8ad71ea715be0573'),
        Uint64.parseHex('0x63df7a76e858a4aa'),
        Uint64.parseHex('0x23e4ab37183acba4'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0xfca995e2b59914a1'),
        Uint64.parseHex('0xacfe14640de044f2'),
        Uint64.parseHex('0x5d33094e0beda75b'),
        Uint64.parseHex('0x2795d5c5fa428022'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0xc26d909dee8b53c0'),
        Uint64.parseHex('0xa6687c3df16c8fe4'),
        Uint64.parseHex('0xd765f26dd03f4c45'),
        Uint64.parseHex('0x3001ca401e89601c'),
      ]),
    ],
    [
      VestaFq.fromRaw([
        Uint64.parseHex('0xe7fea6bdf3471380'),
        Uint64.parseHex('0xe84b5bebae4e501d'),
        Uint64.parseHex('0xf7bf86e89280827f'),
        Uint64.parseHex('0x0072e45cc676b08e'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0xd0c54ddeb26b86c0'),
        Uint64.parseHex('0xb64829e2d40e41bd'),
        Uint64.parseHex('0xe2abe4c518ce599e'),
        Uint64.parseHex('0x13de705484874bb5'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0x38915b432a9959a5'),
        Uint64.parseHex('0x82bb18e5af1b05bb'),
        Uint64.parseHex('0x315950f1211defe8'),
        Uint64.parseHex('0x0408a9fcf9d61abf'),
      ]),
    ],
    [
      VestaFq.fromRaw([
        Uint64.parseHex('0x34070cbee26886a0'),
        Uint64.parseHex('0xae4d23b0b41be9a8'),
        Uint64.parseHex('0xbb4e4a1400ccd2c4'),
        Uint64.parseHex('0x2780b9e75b55676e'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0x9405592098b4056f'),
        Uint64.parseHex('0xdc4d8fbefe24405a'),
        Uint64.parseHex('0xf80333ec85634ac9'),
        Uint64.parseHex('0x3a570d4d7c4e7ac3'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0x78d2b247899520b4'),
        Uint64.parseHex('0xe2cc1507bebdcc62'),
        Uint64.parseHex('0xf347c247fcf09294'),
        Uint64.parseHex('0x0c13cca7cb1f9d2c'),
      ]),
    ],
    [
      VestaFq.fromRaw([
        Uint64.parseHex('0x2e8c88f7707470e0'),
        Uint64.parseHex('0x0b50bb2eb82df74d'),
        Uint64.parseHex('0xd2614a197c6b794b'),
        Uint64.parseHex('0x14f59baa03cd0ca4'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0xbe52476e0a16f3be'),
        Uint64.parseHex('0xa51d54ede66167f5'),
        Uint64.parseHex('0x6f546e1704c39c60'),
        Uint64.parseHex('0x307defee925dfb43'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0x380b67d80473dce3'),
        Uint64.parseHex('0x661106836adfe5e7'),
        Uint64.parseHex('0x7a07e7674b5a2621'),
        Uint64.parseHex('0x1960cd511a91e060'),
      ]),
    ],
    [
      VestaFq.fromRaw([
        Uint64.parseHex('0x15aaf1f7712589dd'),
        Uint64.parseHex('0xb8ee335d88284cbe'),
        Uint64.parseHex('0xca2ad0fb56672500'),
        Uint64.parseHex('0x2301ef9c63ea84c5'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0x5e68478c4d6027a9'),
        Uint64.parseHex('0xc86182d1b4246b58'),
        Uint64.parseHex('0xd10f4cd52be97f6b'),
        Uint64.parseHex('0x029a5a47da79a488'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0x2cc4f962eaae2260'),
        Uint64.parseHex('0xf97fe46b6a925428'),
        Uint64.parseHex('0x2360d17d890e55cb'),
        Uint64.parseHex('0x32d7b16a7f11cc96'),
      ]),
    ],
    [
      VestaFq.fromRaw([
        Uint64.parseHex('0xc0cab915d5363d9f'),
        Uint64.parseHex('0xa5f2404cd7b35eb0'),
        Uint64.parseHex('0x18e857a98d498cf7'),
        Uint64.parseHex('0x26703e48c03b81ca'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0xf691123ae112b928'),
        Uint64.parseHex('0xf44388bd6b89221e'),
        Uint64.parseHex('0x88ac8d25a24603f1'),
        Uint64.parseHex('0x048682a35b3265bc'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0x3ab7defcb8d803e2'),
        Uint64.parseHex('0x91d6e1715164775e'),
        Uint64.parseHex('0xd72cddc6cf06b507'),
        Uint64.parseHex('0x06b1390441fa7030'),
      ]),
    ],
    [
      VestaFq.fromRaw([
        Uint64.parseHex('0xbcd795414a6e2e86'),
        Uint64.parseHex('0x43b360f6386a86d7'),
        Uint64.parseHex('0x1689426dce05fcd8'),
        Uint64.parseHex('0x31aa0eeb868c626d'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0xed77f5d576b99cc3'),
        Uint64.parseHex('0x90efd8f41b2078b2'),
        Uint64.parseHex('0x057abad3764c104b'),
        Uint64.parseHex('0x239464f75bf7b6af'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0xb2cb487307c1cecf'),
        Uint64.parseHex('0xa5cc47c59654b2a7'),
        Uint64.parseHex('0xa45e19ed813a54ab'),
        Uint64.parseHex('0x0a64d4c04fd426bd'),
      ]),
    ],
    [
      VestaFq.fromRaw([
        Uint64.parseHex('0x1f7315322f658735'),
        Uint64.parseHex('0x777c7a921a062e9d'),
        Uint64.parseHex('0x576a4ad259860fb1'),
        Uint64.parseHex('0x21fbbdbb73670734'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0x674324003fc52146'),
        Uint64.parseHex('0x5b86d29463d31564'),
        Uint64.parseHex('0xd9371ca2eb95acf3'),
        Uint64.parseHex('0x31b86f3cf01705d4'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0x7045f48aa4eb4f6f'),
        Uint64.parseHex('0x13541d65157ee1ce'),
        Uint64.parseHex('0x05ef1736d09056f6'),
        Uint64.parseHex('0x2bfde53354377c91'),
      ]),
    ],
    [
      VestaFq.fromRaw([
        Uint64.parseHex('0x5a13a58d20011e2f'),
        Uint64.parseHex('0xf4d5239c11d0eafa'),
        Uint64.parseHex('0xd558f36e65f8eca7'),
        Uint64.parseHex('0x1233ca936ec24671'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0x6e70af0a7a924b3a'),
        Uint64.parseHex('0x878058d0234a576f'),
        Uint64.parseHex('0xc437846d8e0b2b30'),
        Uint64.parseHex('0x27d452a43ac7dea2'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0xa02576b94392f980'),
        Uint64.parseHex('0x6a30641a1c3d87b2'),
        Uint64.parseHex('0xe816ea8da493e0fa'),
        Uint64.parseHex('0x2699dba82184e413'),
      ]),
    ],
    [
      VestaFq.fromRaw([
        Uint64.parseHex('0x608c6f7a61b56e55'),
        Uint64.parseHex('0xf18584664f8cab49'),
        Uint64.parseHex('0xc3988baee42e4b10'),
        Uint64.parseHex('0x36c722f0efcc8803'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0x6e49ac170dbb7fcd'),
        Uint64.parseHex('0x85c38899a7b5a833'),
        Uint64.parseHex('0x08b0f2ec89ccaa37'),
        Uint64.parseHex('0x02b3ff48861e339b'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0xa8c5ae03ad98e405'),
        Uint64.parseHex('0x6fc3ff4c49eb59ad'),
        Uint64.parseHex('0x60162f4427bc657b'),
        Uint64.parseHex('0x0b70d061d58d8a7f'),
      ]),
    ],
    [
      VestaFq.fromRaw([
        Uint64.parseHex('0x2e06cc4af33b0a06'),
        Uint64.parseHex('0xad3de8be46ed9693'),
        Uint64.parseHex('0xf8753adeb9d7cee2'),
        Uint64.parseHex('0x3fc2a13f127f96a4'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0xc12080ac117ee15f'),
        Uint64.parseHex('0x00cb3d621e171d80'),
        Uint64.parseHex('0x1bd63434ac8c419f'),
        Uint64.parseHex('0x0c41a6e48dd23a51'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0x9685213e9692f5e1'),
        Uint64.parseHex('0x72aaad7e4e75339d'),
        Uint64.parseHex('0xed4476537169084e'),
        Uint64.parseHex('0x2de8072a6bd86884'),
      ]),
    ],
    [
      VestaFq.fromRaw([
        Uint64.parseHex('0x0ad01184567b027c'),
        Uint64.parseHex('0xb81cf735cc9c39c0'),
        Uint64.parseHex('0x9d3496a3d9fe05ec'),
        Uint64.parseHex('0x03557a8f7b38a17f'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0x45bcb5ac00826abc'),
        Uint64.parseHex('0x060f43363d818e54'),
        Uint64.parseHex('0xee976d34282f1a37'),
        Uint64.parseHex('0x0b5f59552f498735'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0x2f2909e17e22b0df'),
        Uint64.parseHex('0xf5d646e57507e548'),
        Uint64.parseHex('0xfedbb18570dc7300'),
        Uint64.parseHex('0x0e2923a5fee7b878'),
      ]),
    ],
    [
      VestaFq.fromRaw([
        Uint64.parseHex('0xf71eed73f15b3326'),
        Uint64.parseHex('0xcf1cb37c3b032af6'),
        Uint64.parseHex('0xc787be97020a7fdd'),
        Uint64.parseHex('0x1d785005a7a00592'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0x0acfbfb223f8f00d'),
        Uint64.parseHex('0xa590b88a3b060294'),
        Uint64.parseHex('0x0ba5fedcb8f25bd2'),
        Uint64.parseHex('0x1ad772c273d9c6df'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0xc1ce13d60f2f5031'),
        Uint64.parseHex('0x810510eb61f0672d'),
        Uint64.parseHex('0xa78f3275c278234b'),
        Uint64.parseHex('0x027bd64785fcbd2a'),
      ]),
    ],
    [
      VestaFq.fromRaw([
        Uint64.parseHex('0x8337f5e07923a853'),
        Uint64.parseHex('0xe224313469457b8e'),
        Uint64.parseHex('0xce6f8ffea1031b6d'),
        Uint64.parseHex('0x20800f441b4a0526'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0xa33d7bed89a4408a'),
        Uint64.parseHex('0x36cdc8eed662ad37'),
        Uint64.parseHex('0x6eea2cd49f4312b4'),
        Uint64.parseHex('0x3d5ad61d7b65f938'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0x3bbbae94cc195284'),
        Uint64.parseHex('0x1df96cc03ea4b26d'),
        Uint64.parseHex('0x02c5f91be4dd8e3d'),
        Uint64.parseHex('0x13338bc351fc46dd'),
      ]),
    ],
    [
      VestaFq.fromRaw([
        Uint64.parseHex('0xc5271c297852819e'),
        Uint64.parseHex('0x646c49f9b46cbf19'),
        Uint64.parseHex('0xb87db1e2af3ea923'),
        Uint64.parseHex('0x25e52be507c92760'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0x5c380ab701b52ea9'),
        Uint64.parseHex('0xa34c83a3485c6b2d'),
        Uint64.parseHex('0x71096d8b1b983c98'),
        Uint64.parseHex('0x1c492d64c157aaa4'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0xa20c0b3da0da4ca3'),
        Uint64.parseHex('0xd43487bc288df682'),
        Uint64.parseHex('0xf4e6c5e7a573f592'),
        Uint64.parseHex('0x0c5b801579992718'),
      ]),
    ],
    [
      VestaFq.fromRaw([
        Uint64.parseHex('0x7ea33c93e40833cf'),
        Uint64.parseHex('0x584e9e62a7f9554e'),
        Uint64.parseHex('0x68695c0cd7cbf43d'),
        Uint64.parseHex('0x1090b1b4d2bebe7a'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0xe383e1ec3baa8d69'),
        Uint64.parseHex('0x1b218e35ecf2328e'),
        Uint64.parseHex('0x68f5ce5cbed19cad'),
        Uint64.parseHex('0x33e38018a801387a'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0xb76b0b3d787ee953'),
        Uint64.parseHex('0x5f4a02d28729e3ae'),
        Uint64.parseHex('0xeef8d83d0e876bac'),
        Uint64.parseHex('0x1654af18772b2da5'),
      ]),
    ],
    [
      VestaFq.fromRaw([
        Uint64.parseHex('0xef7ce6a013265477'),
        Uint64.parseHex('0xbb0893870367ec6c'),
        Uint64.parseHex('0x44742de88c5ab0d5'),
        Uint64.parseHex('0x1678be3cc9c67993'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0xaf5d47893348f766'),
        Uint64.parseHex('0xdaf1818355b13b4f'),
        Uint64.parseHex('0x7ff9c6be546e928a'),
        Uint64.parseHex('0x3780bd1e01f34c22'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0xa12380320d7cc1de'),
        Uint64.parseHex('0x5d11e69aa6c0b98c'),
        Uint64.parseHex('0x0786018e7cb77267'),
        Uint64.parseHex('0x1e83d6315c9f125b'),
      ]),
    ],
    [
      VestaFq.fromRaw([
        Uint64.parseHex('0x1799603e855ce731'),
        Uint64.parseHex('0xc486894d76e0c33b'),
        Uint64.parseHex('0x160b41552f2931c8'),
        Uint64.parseHex('0x354afd0a2f9d0b26'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0x8b997ee06be1bff3'),
        Uint64.parseHex('0x60b00dbe1faced07'),
        Uint64.parseHex('0x2d8affa62905c5a5'),
        Uint64.parseHex('0x00cd6d29f166eadc'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0x08d0641917082f2c'),
        Uint64.parseHex('0xc60d01973f183057'),
        Uint64.parseHex('0xdbe0e3d7cdbc66ef'),
        Uint64.parseHex('0x1d6219352768e3ae'),
      ]),
    ],
    [
      VestaFq.fromRaw([
        Uint64.parseHex('0xfa08dd9806387577'),
        Uint64.parseHex('0xafe3ca1db8d4f529'),
        Uint64.parseHex('0xe48d2370d7d1a142'),
        Uint64.parseHex('0x146336e25db5181d'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0xa901d3ce84de0ad4'),
        Uint64.parseHex('0x022e54b49c13d907'),
        Uint64.parseHex('0x997a21163e2e43df'),
        Uint64.parseHex('0x0005d8e085fd72ee'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0x1c36f31341964484'),
        Uint64.parseHex('0x6f8ebc1d2296021a'),
        Uint64.parseHex('0x0dd5e61c8a4e8642'),
        Uint64.parseHex('0x364e97c7a3893227'),
      ]),
    ],
    [
      VestaFq.fromRaw([
        Uint64.parseHex('0xd7a00c03d2e0baaa'),
        Uint64.parseHex('0xfa97ec80ad307a52'),
        Uint64.parseHex('0x561c6fff15346878'),
        Uint64.parseHex('0x01189910671bc16b'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0x63fd8ac57a95ca8c'),
        Uint64.parseHex('0x4c0f7e001df490aa'),
        Uint64.parseHex('0x5229dfaa01231a45'),
        Uint64.parseHex('0x162a7c80f4d2d12e'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0x32e69efb22f40b96'),
        Uint64.parseHex('0xcaff31b4fda32124'),
        Uint64.parseHex('0x2604e4afb09f8603'),
        Uint64.parseHex('0x2a0d6c09576666bb'),
      ]),
    ],
    [
      VestaFq.fromRaw([
        Uint64.parseHex('0xc0a0180f8cbfc0d2'),
        Uint64.parseHex('0xf444d10d63a74e2c'),
        Uint64.parseHex('0xe16a4d603d5a808e'),
        Uint64.parseHex('0x0978e5c51e1e5649'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0x03f4460ebc351b6e'),
        Uint64.parseHex('0x05087d903bdacfd1'),
        Uint64.parseHex('0xebe19bbdce251011'),
        Uint64.parseHex('0x1bdcee3aaca9cd25'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0xf61964bf3ade7670'),
        Uint64.parseHex('0x0c947321e0075e3f'),
        Uint64.parseHex('0xe49479140b1944fd'),
        Uint64.parseHex('0x1862cccb70b5b885'),
      ]),
    ],
    [
      VestaFq.fromRaw([
        Uint64.parseHex('0xc3267da6e94adc50'),
        Uint64.parseHex('0x39ee99c1cc6e5dda'),
        Uint64.parseHex('0xbc26cc883a1987e1'),
        Uint64.parseHex('0x1f3e91d863c16922'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0x0f85b4ac2c367406'),
        Uint64.parseHex('0xfa661465c656ad99'),
        Uint64.parseHex('0xef5c08f8478f663a'),
        Uint64.parseHex('0x1af47a48a6016a49'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0x0eabcd87e7d01b15'),
        Uint64.parseHex('0x1c3698b0a2e3da10'),
        Uint64.parseHex('0x009d57338c693505'),
        Uint64.parseHex('0x3c8ee901956e3d3f'),
      ]),
    ],
    [
      VestaFq.fromRaw([
        Uint64.parseHex('0x8b94772189673476'),
        Uint64.parseHex('0xe10ce2b7069f4dbd'),
        Uint64.parseHex('0x68d0b024f591b520'),
        Uint64.parseHex('0x1660a8cde7fec553'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0x9d8d0f67fdaa79d5'),
        Uint64.parseHex('0x3963c2c1f5586e2f'),
        Uint64.parseHex('0x1303936334dd1132'),
        Uint64.parseHex('0x0f6d991929d5e4e7'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0x7a433091e1ce2d3a'),
        Uint64.parseHex('0x4e7fda770712f343'),
        Uint64.parseHex('0xcc625eaaab52b4dc'),
        Uint64.parseHex('0x02b9cea1921cd9f6'),
      ]),
    ],
    [
      VestaFq.fromRaw([
        Uint64.parseHex('0x3797b2d8376043b3'),
        Uint64.parseHex('0xd8caf468976f0472'),
        Uint64.parseHex('0x214f7c6784acb565'),
        Uint64.parseHex('0x14a323b99b900331'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0x347fef2c00f0953a'),
        Uint64.parseHex('0x718b7fbc7788af78'),
        Uint64.parseHex('0xec01ea79642d5760'),
        Uint64.parseHex('0x190476b580cb9277'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0xff4e7e6fb268dfd7'),
        Uint64.parseHex('0x9660902b60087651'),
        Uint64.parseHex('0xa42463d30b442b6f'),
        Uint64.parseHex('0x090a3a9d869d2eef'),
      ]),
    ],
    [
      VestaFq.fromRaw([
        Uint64.parseHex('0xf983387ea0456203'),
        Uint64.parseHex('0xe365001304f9a11e'),
        Uint64.parseHex('0x0dbe8fd2270a6795'),
        Uint64.parseHex('0x3877a95586367567'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0x39c0af0fe01f4a06'),
        Uint64.parseHex('0x60118c53a2181352'),
        Uint64.parseHex('0x5df39a2cc63ddc0a'),
        Uint64.parseHex('0x2d894691240fe953'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0x1aca9eaf9bba9850'),
        Uint64.parseHex('0x5914e855eeb44aa1'),
        Uint64.parseHex('0x7ef7178020166189'),
        Uint64.parseHex('0x21b9c18292bdbc59'),
      ]),
    ],
    [
      VestaFq.fromRaw([
        Uint64.parseHex('0x33f509a74ad9d39b'),
        Uint64.parseHex('0x272e1cc6c36a2968'),
        Uint64.parseHex('0x505a05f2a6ae834c'),
        Uint64.parseHex('0x2fe76be7cff723e2'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0x0df9fa97277fa8b4'),
        Uint64.parseHex('0xd15bff840ddae8a5'),
        Uint64.parseHex('0x929981d7cfce253b'),
        Uint64.parseHex('0x187aa448f391e3ca'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0xf0c66af5ffc73736'),
        Uint64.parseHex('0x663ccf7b2ffe4b5e'),
        Uint64.parseHex('0x007ab3aa3617f422'),
        Uint64.parseHex('0x0b7083ad751707bf'),
      ]),
    ],
    [
      VestaFq.fromRaw([
        Uint64.parseHex('0x2f9b20f1fbd49791'),
        Uint64.parseHex('0x1975b962f6cb8e0b'),
        Uint64.parseHex('0x3bc4ca9902c52acb'),
        Uint64.parseHex('0x030ddbb470493f16'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0x3a1c62ca8fbf2525'),
        Uint64.parseHex('0x8fb8ab9d60ea17b2'),
        Uint64.parseHex('0x950b0ab18d3546df'),
        Uint64.parseHex('0x3130fbaffb5aa82a'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0x43a876180dc382e0'),
        Uint64.parseHex('0x15ce2ead2fcd051e'),
        Uint64.parseHex('0x4f74d74bac2ee457'),
        Uint64.parseHex('0x337f544707c430f0'),
      ]),
    ],
    [
      VestaFq.fromRaw([
        Uint64.parseHex('0x26de98a8736d1d11'),
        Uint64.parseHex('0x7d8e471a9fb95fef'),
        Uint64.parseHex('0xac9d91b0930dac75'),
        Uint64.parseHex('0x349979919015394f'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0xccfcb61831d5c775'),
        Uint64.parseHex('0x3bf93da6fff31d95'),
        Uint64.parseHex('0x2305cd7a921ec5f1'),
        Uint64.parseHex('0x027cc4efe3fb35dd'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0xc3fa2629635d27de'),
        Uint64.parseHex('0x67f1c6b7314764af'),
        Uint64.parseHex('0x61b71a3698682ad2'),
        Uint64.parseHex('0x037f9f2365954c5b'),
      ]),
    ],
    [
      VestaFq.fromRaw([
        Uint64.parseHex('0x77c5b024848371ae'),
        Uint64.parseHex('0x60414abe362d01c9'),
        Uint64.parseHex('0x10f1cc6df8b4bcd7'),
        Uint64.parseHex('0x1f697cac4d07feb7'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0x786add244aa0ef29'),
        Uint64.parseHex('0x3145c478063109d6'),
        Uint64.parseHex('0x26e6c851fbd572a6'),
        Uint64.parseHex('0x267a750fe5d7cfbc'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0x180e2b4d3e756f65'),
        Uint64.parseHex('0xaf285fa82ce4fae5'),
        Uint64.parseHex('0x678c9996d9a472c8'),
        Uint64.parseHex('0x0c91feab4a43193a'),
      ]),
    ],
    [
      VestaFq.fromRaw([
        Uint64.parseHex('0x79c47c573ac410f7'),
        Uint64.parseHex('0x7e3b83af4a4ba3ba'),
        Uint64.parseHex('0x2186c3038ea05e69'),
        Uint64.parseHex('0x1745569a0a3e3014'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0x1e0388522696191f'),
        Uint64.parseHex('0xfdff66c6f3b5ffe1'),
        Uint64.parseHex('0xeca5120778a56711'),
        Uint64.parseHex('0x29863d546e7e7c0d'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0x2f225e6366bfe390'),
        Uint64.parseHex('0xa79a03df833994c6'),
        Uint64.parseHex('0xbf06bae49ef853f6'),
        Uint64.parseHex('0x1148d6ab2bd00192'),
      ]),
    ],
    [
      VestaFq.fromRaw([
        Uint64.parseHex('0xf4f6331a8b265d15'),
        Uint64.parseHex('0xf745f45d350d41d4'),
        Uint64.parseHex('0xe18b1499060da366'),
        Uint64.parseHex('0x02e0e121b0f3dfef'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0x078ae6aa151054b7'),
        Uint64.parseHex('0x690401736d44a653'),
        Uint64.parseHex('0xb89ef73a40a2b274'),
        Uint64.parseHex('0x0d0aa46e76a6a278'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0x9a4d532c7b6e0958'),
        Uint64.parseHex('0x392dde710f1f06db'),
        Uint64.parseHex('0xeee545f3fa6d3d08'),
        Uint64.parseHex('0x13943675b04aa986'),
      ]),
    ],
    [
      VestaFq.fromRaw([
        Uint64.parseHex('0x961fc818dcbb66b5'),
        Uint64.parseHex('0xc9f2b3257530dafe'),
        Uint64.parseHex('0xd97a11d63088f5d9'),
        Uint64.parseHex('0x2901ec61942d34aa'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0xfdf544b963d1fdc7'),
        Uint64.parseHex('0x22ffa2a2af9fa3e3'),
        Uint64.parseHex('0xf431d54434a3e0cf'),
        Uint64.parseHex('0x20204a2105d22e7e'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0x1211b9e2190d6852'),
        Uint64.parseHex('0xa004abe8e01528c4'),
        Uint64.parseHex('0x5c1e3e9e27a571c3'),
        Uint64.parseHex('0x3a8a628295121d5c'),
      ]),
    ],
  ];
  // mds matrix:
  static final List<List<VestaFq>> mds = [
    [
      VestaFq.fromRaw([
        Uint64.parseHex('0xeb4f1f742963421f'),
        Uint64.parseHex('0x5f710afc43ddc5f6'),
        Uint64.parseHex('0x91913f56cf21af2b'),
        Uint64.parseHex('0x1853b4977c6fa227'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0x45e51db6ac6fe4a7'),
        Uint64.parseHex('0x5a0fa4dfa500bcad'),
        Uint64.parseHex('0x63f484c10fcf0586'),
        Uint64.parseHex('0x3d831189cfbbc452'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0xd18837f98347f137'),
        Uint64.parseHex('0x3f8965c780838a94'),
        Uint64.parseHex('0x4ba88b9e401719c0'),
        Uint64.parseHex('0x3a0e3f84d3c177d8'),
      ]),
    ],
    [
      VestaFq.fromRaw([
        Uint64.parseHex('0x84fd7923337cf77e'),
        Uint64.parseHex('0x2896f8d0fd5c9a75'),
        Uint64.parseHex('0x8e9dc529f4718f83'),
        Uint64.parseHex('0x35e26e3984506279'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0x3eb924f56fff7908'),
        Uint64.parseHex('0x3641cecf3a2a5a8a'),
        Uint64.parseHex('0x00cd7dbea79970ab'),
        Uint64.parseHex('0x10a8166302cb753c'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0xb67227c1a141ae94'),
        Uint64.parseHex('0x198e1aee777e2521'),
        Uint64.parseHex('0xf43492ce51214b00'),
        Uint64.parseHex('0x314f762a506d321b'),
      ]),
    ],
    [
      VestaFq.fromRaw([
        Uint64.parseHex('0xabcbd614eaf5eba1'),
        Uint64.parseHex('0xa90f28b0cb3176fb'),
        Uint64.parseHex('0xcb2eab86ef31d915'),
        Uint64.parseHex('0x07b85627c832782a'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0xc255efd006b5db1c'),
        Uint64.parseHex('0xb5d985dc1630a4b2'),
        Uint64.parseHex('0x97564e1b5d1ac72f'),
        Uint64.parseHex('0x2a2de13e70f27e16'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0xcffdf529333429fc'),
        Uint64.parseHex('0x21e3af7ef12332cd'),
        Uint64.parseHex('0xfff540a87327c7ce'),
        Uint64.parseHex('0x2c6094d1c6e1caba'),
      ]),
    ],
  ];
  static final List<List<VestaFq>> mdsInv = [
    [
      VestaFq.fromRaw([
        Uint64.parseHex('0xb204ddc65e582044'),
        Uint64.parseHex('0x47a60484b0a99c91'),
        Uint64.parseHex('0xcaf54d7824c1200e'),
        Uint64.parseHex('0x36df495021cf7828'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0x6a6b94adaa0d9c9e'),
        Uint64.parseHex('0xe2cd38b959d461ff'),
        Uint64.parseHex('0xe43ec4bf3e0df00c'),
        Uint64.parseHex('0x034fbeae4650c2c7'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0xa8627a028c1af7d6'),
        Uint64.parseHex('0x841bebf1a15b746e'),
        Uint64.parseHex('0x1fd56832d0ab5570'),
        Uint64.parseHex('0x20a864d6790f7c1c'),
      ]),
    ],
    [
      VestaFq.fromRaw([
        Uint64.parseHex('0x3470d5c553bc9d20'),
        Uint64.parseHex('0x1f95660feb5db121'),
        Uint64.parseHex('0xdd3197acc8949076'),
        Uint64.parseHex('0x2d08703d48ecd7dc'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0x6b5b42b067d830f3'),
        Uint64.parseHex('0x6169b6fa721a470e'),
        Uint64.parseHex('0xeff318a28983158a'),
        Uint64.parseHex('0x2db10ecd507a2f27'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0xfbaeb537d2784760'),
        Uint64.parseHex('0x0068e70907e7089d'),
        Uint64.parseHex('0x926a5fc0cc1ef726'),
        Uint64.parseHex('0x0c8a58c06473cdfa'),
      ]),
    ],
    [
      VestaFq.fromRaw([
        Uint64.parseHex('0x3a5aca1071296e61'),
        Uint64.parseHex('0x4ad4442e96c9d5e8'),
        Uint64.parseHex('0x5432f0c0b908a411'),
        Uint64.parseHex('0x2a642dca695d744d'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0x1bd9bfcbbe025ff1'),
        Uint64.parseHex('0x24f6ad43b703ad90'),
        Uint64.parseHex('0xebb7238df00d17e7'),
        Uint64.parseHex('0x114ec796fb403f5f'),
      ]),
      VestaFq.fromRaw([
        Uint64.parseHex('0x67f0642e14a9c3bf'),
        Uint64.parseHex('0xf6a6917670697a97'),
        Uint64.parseHex('0x0408110dc66eb147'),
        Uint64.parseHex('0x2825e0675968dbeb'),
      ]),
    ],
  ];
}
