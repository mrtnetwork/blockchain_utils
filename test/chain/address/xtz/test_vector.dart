// ------------------------------------------------------------------
// Real test vectors
// Sources:
//   - tz1/tz2/tz3: github.com/ecadlabs/taquito/issues/643
//   - tz1 #2: pytezos.baking-bad.org/tutorials/01.html
//   - tz1 #3: tezos.stackexchange.com/q/2060
//   - tz2 #2: unit410.com/blog/tezos-hsm
//   - tz4: forum.tezosagora.org/t/native-multisig-accounts/6805
// ------------------------------------------------------------------
import 'package:blockchain_utils/chain/address/neworks/others/xtz_addr.dart'
    show XtzAddrPrefixes;

final testVecotr = <Map<String, dynamic>>[
  // ═══════════════════════════════════════════════════════════════
  // tz1 — Ed25519 (3 vectors)
  // ═══════════════════════════════════════════════════════════════
  {
    'type': XtzAddrPrefixes.tz1,
    "Base58": 'edpku61nGAwkeoA7PQJEFWmrVP1eWrSTVoHgCaF2isjWqDeGdux37k',
    'public':
        '3a8f6fe7e79d3ad8a269683fcedd0f8eafbcbb081a75d6bf7bf94a86a6bc4f31',
    'address': 'tz1ipB38oB5F76HnbTRqWPLEnVtCgj6yf2nB',
    'decode': 'fe3604cf37af81293926a37443f2faec40538721',
  },
  {
    'type': XtzAddrPrefixes.tz1,
    "Base58": "edpku976gpuAD2bXyx1XGraeKuCo1gUZ3LAJcHM12W1ecxZwoiu22R",
    'public':
        '419491b1796b13d756d394ed925c10727bca06e97353c5ca09402a9b6b07abcc',
    'address': 'tz1eKkWU5hGtfLUiqNpucHrXymm83z3DG9Sq',
    'decode': 'ccf564a5a0bdb15c3dbdf84d68dacac3e1f968a3',
  },
  {
    'type': XtzAddrPrefixes.tz1,
    "Base58": "edpku3g7CeTEvSKhxipD4Q2B6EiEP8cR323u8PFmGFgKRVRvCneEmT",
    'public':
        '353fb5be7bb114b21f74d7ab0a8cd4129d67edd16a4a6d74919503cd9bf3c33b',
    'address': 'tz1TNw1upMFLryJZXG8iBoXcRhmERoJkJ4iW',
    'decode': '54e6075cde20045561c0f06de3159732695aba94',
  },

  // ═══════════════════════════════════════════════════════════════
  // tz2 — Secp256k1 (2 vectors)
  // ═══════════════════════════════════════════════════════════════
  {
    'type': XtzAddrPrefixes.tz2,
    "Base58": "sppk7czKu6So3zDWjhBPBv9wgCrBAfbEFoKYzEaKUsjhNr5Ug6E4Sn1",
    'public':
        '03e535d02065bfb5cf48359f575a4d839a79163894882a312dcc4cbc58974d0773',
    'address': 'tz2Gsf1Q857wUzkNGzHsJNC98z881UutMwjg',
    'decode': '5de2a3d6ab255834d5f2b7333eaeeabb5ac791ff',
  },
  {
    'type': XtzAddrPrefixes.tz2,
    "Base58": "sppk7c9QAGWCJEvFWp6vGBs3VuxFax7GDwWQiPXR2rGSYPN7NMQN9rP",
    'public':
        '03761dd62881d368eede5c78495d718b90f4c6616426e09bd6c2775a6faaf4332e',
    'address': 'tz2PH72CdqfsBJRsDcGfUu3UvuXwEyzqzs3s',
    'decode': 'a422ad54460c3ed396a13cc7e6bd6648b270611d',
  },

  // ═══════════════════════════════════════════════════════════════
  // tz3 — P-256 / secp256r1 (1 vector)
  // ═══════════════════════════════════════════════════════════════
  {
    'type': XtzAddrPrefixes.tz3,
    "Base58": "p2pk67BANWUUX2fod9EQbv8ev7GGLpb4UXvLHEVVMiHBSWPHgyzf1tv",
    'public':
        '0356dd0702b5db36aec8565e9377c298c28d3d8d1dca79f066a58391d53df0ce34',
    'address': 'tz3daYfTrShLBfH24hv2kGwXD5y2bApH83RC',
    'decode': 'bd3835c8a2e74e12231044ba5c597aef8550382b',
  },

  // ═══════════════════════════════════════════════════════════════
  // tz4 — BLS12-381 MinPk (4 vectors)
  // ═══════════════════════════════════════════════════════════════
  {
    'type': XtzAddrPrefixes.tz4,
    "Base58":
        "BLpk1wiReQSN3PzrwQafTtFD4szTnszesNPSaro3q2myQETj2BH1HUUA76VytNqD8YczqX1DyX8t",
    'public':
        'ae1f3823d63cd925298302063cc79146794861f778877c5c5b47e18cf5069bd27afc951e9ad068c180a0a63a369546bd',
    'address': 'tz4Hgy9DDhKJzBDe5kg3VW1no766scaz7nU7',
    'decode': '5f43eb50430295e2de9db3c66843f080aec64b7c',
  },
  {
    'type': XtzAddrPrefixes.tz4,
    "Base58":
        "BLpk1vF6GZqiqdAwA78upao7AYNuyJcKQbTJ6FXYp97bAjKPRrcVT9LZebacVMpg2tkgEow4k1K4",
    'public':
        'a7fe19c2a7475266264781dcdff651f75adbda6f21893bc8a1f08c49cdb6a7ea68a5e3ab95d139e1ab1b25802baee1e3',
    'address': 'tz4CJsoQMDZVvAcEQEFjFcBU5hZuoeVz2aLd',
    'decode': '243dae242e62e588ca0b4d82536b996b70e3d42a',
  },
  {
    'type': XtzAddrPrefixes.tz4,
    "Base58":
        "BLpk1tvA7VVVtccUz1VpCcvNgysintAReyaTdEzrCU6Ai9gftLMDQQNniKtmH5sMG7BqeR1uN4hy",
    'public':
        'a27772741a3499ab5314c32ca428bf967bc1af267d02e3e4a71c2beadc599c791ac93ceb38da14f54a858d6d367c6acd',
    'address': 'tz4SY87c9MTEknnhcmwfu3d7Qu8HqmgwfJkY',
    'decode': 'c050cc1cf74b548e2f4a38601359f9193ad8e0f6',
  },
  {
    'type': XtzAddrPrefixes.tz4,
    "Base58":
        "BLpk1xq2ihLjsxccmdTsgi1YKWQb1khbwYKx5xhbdNG67HwQJ5nAuyLXBe9pJyjFRWizN7t6EHN4",
    'public':
        'b2c32aec20e8dd216d85a8a3a39e3f7228940dcd5f1b08e3c792af78fdfaf400a2e61b42a42d3b3260b557e73adcca2b',
    'address': 'tz4WZtJkSbbboha3UrmpPPSkon7aTU82iWK3',
    'decode': 'ec869b2bf20b048fac696cf8e43b892f68fc06c3',
  },
];
