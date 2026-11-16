import 'dart:math';
import 'dart:typed_data';

import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

import 'test_vector.dart';

import '../../../utils.dart';

String _b32enc(List<int> bytes) =>
    Base32Encoder.encodeNoPaddingBytes(bytes, FilAddrConst.base32Alphabet);

List<int> _b32dec(String s) =>
    Base32Decoder.decode(s, FilAddrConst.base32Alphabet);

/// Canonical base32 validation (re-encode and compare).
/// The official Go implementation rejects non-canonical encodings
/// (e.g. trailing bits that are not zero).
bool _isCanonicalBase32(String s) {
  try {
    final decoded = _b32dec(s);
    final reencoded = _b32enc(decoded);
    return reencoded == s;
  } catch (_) {
    return false;
  }
}

Matcher _throwsAddrValidation({String? reasonContains}) {
  return throwsA(
    isA<BuError>().having(
      (e) => e.message,
      'message',
      reasonContains == null ? anything : contains(reasonContains),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Test vectors (extracted from go-address/address_test.go)
// ─────────────────────────────────────────────────────────────────────────────

const _idTestVectors = <({int id, String addr})>[
  (id: 0, addr: 't00'),
  (id: 1, addr: 't01'),
  (id: 10, addr: 't010'),
  (id: 150, addr: 't0150'),
  (id: 499, addr: 't0499'),
  (id: 1024, addr: 't01024'),
  (id: 1729, addr: 't01729'),
  (id: 999999, addr: 't0999999'),
];

const _secpTestVectors = <({List<int> pubkey, String testnet, String mainnet})>[
  (
    pubkey: [
      4,
      148,
      2,
      250,
      195,
      126,
      100,
      50,
      164,
      22,
      163,
      160,
      202,
      84,
      38,
      181,
      24,
      90,
      179,
      178,
      79,
      97,
      52,
      239,
      162,
      92,
      228,
      135,
      200,
      45,
      46,
      78,
      19,
      191,
      69,
      37,
      17,
      224,
      210,
      36,
      84,
      33,
      248,
      97,
      59,
      193,
      13,
      114,
      250,
      33,
      102,
      102,
      169,
      108,
      59,
      193,
      57,
      32,
      211,
      255,
      35,
      63,
      208,
      188,
      5,
    ],
    testnet: 't15ihq5ibzwki2b4ep2f46avlkrqzhpqgtga7pdrq',
    mainnet: 'f15ihq5ibzwki2b4ep2f46avlkrqzhpqgtga7pdrq',
  ),
  (
    pubkey: [
      4,
      118,
      135,
      185,
      16,
      55,
      155,
      242,
      140,
      190,
      58,
      234,
      103,
      75,
      18,
      0,
      12,
      107,
      125,
      186,
      70,
      255,
      192,
      95,
      108,
      148,
      254,
      42,
      34,
      187,
      204,
      38,
      2,
      255,
      127,
      92,
      118,
      242,
      28,
      165,
      93,
      54,
      149,
      145,
      82,
      176,
      225,
      232,
      135,
      145,
      124,
      57,
      53,
      118,
      238,
      240,
      147,
      246,
      30,
      189,
      58,
      208,
      111,
      127,
      218,
    ],
    testnet: 't12fiakbhe2gwd5cnmrenekasyn6v5tnaxaqizq6a',
    mainnet: 'f12fiakbhe2gwd5cnmrenekasyn6v5tnaxaqizq6a',
  ),
  (
    pubkey: [
      4,
      222,
      253,
      208,
      16,
      1,
      239,
      184,
      110,
      1,
      222,
      213,
      206,
      52,
      248,
      71,
      167,
      58,
      20,
      129,
      158,
      230,
      65,
      188,
      182,
      11,
      185,
      41,
      147,
      89,
      111,
      5,
      220,
      45,
      96,
      95,
      41,
      133,
      248,
      209,
      37,
      129,
      45,
      172,
      65,
      99,
      163,
      150,
      52,
      155,
      35,
      193,
      28,
      194,
      255,
      53,
      157,
      229,
      75,
      226,
      135,
      234,
      98,
      49,
      155,
    ],
    testnet: 't1wbxhu3ypkuo6eyp6hjx6davuelxaxrvwb2kuwva',
    mainnet: 'f1wbxhu3ypkuo6eyp6hjx6davuelxaxrvwb2kuwva',
  ),
  (
    pubkey: [
      4,
      3,
      237,
      18,
      200,
      20,
      182,
      177,
      13,
      46,
      224,
      157,
      149,
      180,
      104,
      141,
      178,
      209,
      128,
      208,
      169,
      163,
      122,
      107,
      106,
      125,
      182,
      61,
      41,
      129,
      30,
      233,
      115,
      4,
      121,
      216,
      239,
      145,
      57,
      233,
      18,
      73,
      202,
      189,
      57,
      50,
      145,
      207,
      229,
      210,
      119,
      186,
      118,
      222,
      69,
      227,
      224,
      133,
      163,
      118,
      129,
      191,
      54,
      69,
      210,
    ],
    testnet: 't1xtwapqc6nh4si2hcwpr3656iotzmlwumogqbuaa',
    mainnet: 'f1xtwapqc6nh4si2hcwpr3656iotzmlwumogqbuaa',
  ),
  (
    pubkey: [
      4,
      247,
      150,
      129,
      154,
      142,
      39,
      22,
      49,
      175,
      124,
      24,
      151,
      151,
      181,
      69,
      214,
      2,
      37,
      147,
      97,
      71,
      230,
      1,
      14,
      101,
      98,
      179,
      206,
      158,
      254,
      139,
      16,
      20,
      65,
      97,
      169,
      30,
      208,
      180,
      236,
      137,
      8,
      0,
      37,
      63,
      166,
      252,
      32,
      172,
      144,
      251,
      241,
      251,
      242,
      113,
      48,
      164,
      236,
      195,
      228,
      3,
      183,
      5,
      118,
    ],
    testnet: 't1xcbgdhkgkwht3hrrnui3jdopeejsoatkzmoltqy',
    mainnet: 'f1xcbgdhkgkwht3hrrnui3jdopeejsoatkzmoltqy',
  ),
  (
    pubkey: [
      4,
      66,
      131,
      43,
      248,
      124,
      206,
      158,
      163,
      69,
      185,
      3,
      80,
      222,
      125,
      52,
      149,
      133,
      156,
      164,
      73,
      5,
      156,
      94,
      136,
      221,
      231,
      66,
      133,
      223,
      251,
      158,
      192,
      30,
      186,
      188,
      95,
      200,
      98,
      104,
      207,
      234,
      235,
      167,
      174,
      5,
      191,
      184,
      214,
      142,
      183,
      90,
      82,
      104,
      120,
      44,
      248,
      111,
      200,
      112,
      43,
      239,
      138,
      31,
      224,
    ],
    testnet: 't17uoq6tp427uzv7fztkbsnn64iwotfrristwpryy',
    mainnet: 'f17uoq6tp427uzv7fztkbsnn64iwotfrristwpryy',
  ),
];

const _actorTestVectors = <({List<int> data, String testnet, String mainnet})>[
  (
    data: [
      118,
      18,
      129,
      144,
      205,
      240,
      104,
      209,
      65,
      128,
      68,
      172,
      192,
      62,
      11,
      103,
      129,
      151,
      13,
      96,
    ],
    testnet: 't24vg6ut43yw2h2jqydgbg2xq7x6f4kub3bg6as6i',
    mainnet: 'f24vg6ut43yw2h2jqydgbg2xq7x6f4kub3bg6as6i',
  ),
  (
    data: [
      44,
      175,
      184,
      226,
      224,
      107,
      186,
      152,
      234,
      101,
      124,
      92,
      245,
      244,
      32,
      35,
      170,
      35,
      232,
      142,
    ],
    testnet: 't25nml2cfbljvn4goqtclhifepvfnicv6g7mfmmvq',
    mainnet: 'f25nml2cfbljvn4goqtclhifepvfnicv6g7mfmmvq',
  ),
  (
    data: [
      2,
      44,
      158,
      14,
      162,
      157,
      143,
      64,
      197,
      106,
      190,
      195,
      92,
      141,
      88,
      125,
      160,
      166,
      76,
      24,
    ],
    testnet: 't2nuqrg7vuysaue2pistjjnt3fadsdzvyuatqtfei',
    mainnet: 'f2nuqrg7vuysaue2pistjjnt3fadsdzvyuatqtfei',
  ),
  (
    data: [
      223,
      236,
      3,
      14,
      32,
      79,
      15,
      89,
      216,
      15,
      29,
      94,
      233,
      29,
      253,
      6,
      109,
      127,
      99,
      189,
    ],
    testnet: 't24dd4ox4c2vpf5vk5wkadgyyn6qtuvgcpxxon64a',
    mainnet: 'f24dd4ox4c2vpf5vk5wkadgyyn6qtuvgcpxxon64a',
  ),
  (
    data: [
      61,
      58,
      137,
      232,
      221,
      171,
      84,
      120,
      50,
      113,
      108,
      109,
      70,
      140,
      53,
      96,
      201,
      244,
      127,
      216,
    ],
    testnet: 't2gfvuyh7v2sx3patm5k23wdzmhyhtmqctasbr23y',
    mainnet: 'f2gfvuyh7v2sx3patm5k23wdzmhyhtmqctasbr23y',
  ),
];

const _blsTestVectors = <({List<int> pubkey, String testnet, String mainnet})>[
  (
    pubkey: [
      173,
      88,
      223,
      105,
      110,
      45,
      78,
      145,
      234,
      134,
      200,
      129,
      233,
      56,
      186,
      78,
      168,
      27,
      57,
      94,
      18,
      121,
      123,
      132,
      185,
      207,
      49,
      75,
      149,
      70,
      112,
      94,
      131,
      156,
      122,
      153,
      214,
      6,
      178,
      71,
      221,
      180,
      249,
      172,
      122,
      52,
      20,
      221,
    ],
    testnet:
        't3vvmn62lofvhjd2ugzca6sof2j2ubwok6cj4xxbfzz4yuxfkgobpihhd2thlanmsh3w2ptld2gqkn2jvlss4a',
    mainnet:
        'f3vvmn62lofvhjd2ugzca6sof2j2ubwok6cj4xxbfzz4yuxfkgobpihhd2thlanmsh3w2ptld2gqkn2jvlss4a',
  ),
  (
    pubkey: [
      179,
      41,
      79,
      10,
      46,
      41,
      224,
      198,
      110,
      188,
      35,
      93,
      47,
      237,
      202,
      86,
      151,
      191,
      120,
      74,
      246,
      5,
      199,
      90,
      246,
      8,
      230,
      166,
      61,
      92,
      211,
      142,
      168,
      92,
      168,
      152,
      158,
      14,
      253,
      233,
      24,
      139,
      56,
      47,
      147,
      114,
      70,
      13,
    ],
    testnet:
        't3wmuu6crofhqmm3v4enos73okk2l366ck6yc4owxwbdtkmpk42ohkqxfitcpa57pjdcftql4tojda2poeruwa',
    mainnet:
        'f3wmuu6crofhqmm3v4enos73okk2l366ck6yc4owxwbdtkmpk42ohkqxfitcpa57pjdcftql4tojda2poeruwa',
  ),
  (
    pubkey: [
      150,
      161,
      163,
      228,
      234,
      122,
      20,
      212,
      153,
      133,
      230,
      97,
      178,
      36,
      1,
      212,
      79,
      237,
      64,
      45,
      29,
      9,
      37,
      178,
      67,
      201,
      35,
      88,
      156,
      15,
      188,
      126,
      50,
      205,
      4,
      226,
      158,
      215,
      141,
      21,
      211,
      125,
      58,
      170,
      63,
      230,
      218,
      51,
    ],
    testnet:
        't3s2q2hzhkpiknjgmf4zq3ejab2rh62qbndueslmsdzervrhapxr7dftie4kpnpdiv2n6tvkr743ndhrsw6d3a',
    mainnet:
        'f3s2q2hzhkpiknjgmf4zq3ejab2rh62qbndueslmsdzervrhapxr7dftie4kpnpdiv2n6tvkr743ndhrsw6d3a',
  ),
  (
    pubkey: [
      134,
      180,
      84,
      37,
      140,
      88,
      148,
      117,
      247,
      209,
      111,
      90,
      172,
      1,
      138,
      121,
      246,
      193,
      22,
      157,
      32,
      252,
      51,
      146,
      29,
      216,
      181,
      206,
      28,
      172,
      108,
      52,
      143,
      144,
      163,
      96,
      54,
      36,
      246,
      174,
      185,
      27,
      100,
      81,
      140,
      46,
      128,
      149,
    ],
    testnet:
        't3q22fijmmlckhl56rn5nkyamkph3mcfu5ed6dheq53c244hfmnq2i7efdma3cj5voxenwiummf2ajlsbxc65a',
    mainnet:
        'f3q22fijmmlckhl56rn5nkyamkph3mcfu5ed6dheq53c244hfmnq2i7efdma3cj5voxenwiummf2ajlsbxc65a',
  ),
  (
    pubkey: [
      167,
      114,
      107,
      3,
      128,
      34,
      247,
      90,
      56,
      70,
      23,
      88,
      83,
      96,
      206,
      230,
      41,
      7,
      10,
      45,
      157,
      40,
      113,
      41,
      101,
      229,
      242,
      110,
      204,
      64,
      133,
      131,
      130,
      128,
      55,
      36,
      237,
      52,
      242,
      114,
      3,
      54,
      240,
      157,
      182,
      49,
      240,
      116,
    ],
    testnet:
        't3u5zgwa4ael3vuocgc5mfgygo4yuqocrntuuhcklf4xzg5tcaqwbyfabxetwtj4tsam3pbhnwghyhijr5mixa',
    mainnet:
        'f3u5zgwa4ael3vuocgc5mfgygo4yuqocrntuuhcklf4xzg5tcaqwbyfabxetwtj4tsam3pbhnwghyhijr5mixa',
  ),
];

var _delegatedTestVectors = <
  ({BigInt namespace, List<int> subaddress, String expected})
>[
  (
    namespace: BigInt.from(32),
    subaddress: [0xff, 0xff, 0xff, 0xff, 0xff],
    expected: 'f432f77777777x32lpna',
  ),
  (
    namespace: BigInt.parse("9223372036854775807"),
    subaddress: [],
    expected: 'f49223372036854775807fiic6zsy',
  ),
  (
    namespace: BigInt.parse("9223372036854775807"),
    subaddress: [], // 54 zero bytes filled in test
    expected:
        'f49223372036854775807faaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaahwgiuam',
  ),
];

const _allTestAddresses = <String>[
  't00',
  't01',
  't010',
  't0150',
  't0499',
  't01024',
  't01729',
  't0999999',
  't15ihq5ibzwki2b4ep2f46avlkrqzhpqgtga7pdrq',
  't12fiakbhe2gwd5cnmrenekasyn6v5tnaxaqizq6a',
  't1wbxhu3ypkuo6eyp6hjx6davuelxaxrvwb2kuwva',
  't1xtwapqc6nh4si2hcwpr3656iotzmlwumogqbuaa',
  't1xcbgdhkgkwht3hrrnui3jdopeejsoatkzmoltqy',
  't17uoq6tp427uzv7fztkbsnn64iwotfrristwpryy',
  't24vg6ut43yw2h2jqydgbg2xq7x6f4kub3bg6as6i',
  't25nml2cfbljvn4goqtclhifepvfnicv6g7mfmmvq',
  't2nuqrg7vuysaue2pistjjnt3fadsdzvyuatqtfei',
  't24dd4ox4c2vpf5vk5wkadgyyn6qtuvgcpxxon64a',
  't2gfvuyh7v2sx3patm5k23wdzmhyhtmqctasbr23y',
  't3vvmn62lofvhjd2ugzca6sof2j2ubwok6cj4xxbfzz4yuxfkgobpihhd2thlanmsh3w2ptld2gqkn2jvlss4a',
  't3wmuu6crofhqmm3v4enos73okk2l366ck6yc4owxwbdtkmpk42ohkqxfitcpa57pjdcftql4tojda2poeruwa',
  't3s2q2hzhkpiknjgmf4zq3ejab2rh62qbndueslmsdzervrhapxr7dftie4kpnpdiv2n6tvkr743ndhrsw6d3a',
  't3q22fijmmlckhl56rn5nkyamkph3mcfu5ed6dheq53c244hfmnq2i7efdma3cj5voxenwiummf2ajlsbxc65a',
  't3u5zgwa4ael3vuocgc5mfgygo4yuqocrntuuhcklf4xzg5tcaqwbyfabxetwtj4tsam3pbhnwghyhijr5mixa',
];

// ─────────────────────────────────────────────────────────────────────────────
// Uvarint helper (mirror of implementation)
// ─────────────────────────────────────────────────────────────────────────────

class _Uvarint {
  static List<int> encode(BigInt value) {
    if (value.isNegative) {
      throw CoreErrors.addressValidationFailed(
        reason: "uvarint value must be non-negative",
      );
    }
    return LayoutConst.lebU64().serialize(value);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main test suite
// ─────────────────────────────────────────────────────────────────────────────

void filecoinTest() {
  test("Test vector", () {
    for (final i in testVector) {
      final z = FilSecp256k1AddrEncoder().encodeKey(
        BytesUtils.fromHexString(i["public"]),
      );
      expect(z, i["address"]);
      final decode = FilSecp256k1AddrDecoder().decodeAddr(z);
      expect(decode.toHex(), i["decode"]);
    }
  });
  group('ID Addresses', () {
    test('vector round-trip (testnet)', () {
      final encoder = FilIdAddrEncoder();
      final decoder = FilIdAddrDecoder();

      for (final tc in _idTestVectors) {
        final payload = _Uvarint.encode(BigInt.from(tc.id));
        final encoded = encoder.encodeKey(payload, network: FilNetwork.testnet);
        expect(encoded, tc.addr, reason: 'encoding failed for id ${tc.id}');

        final decoded = decoder.decodeAddr(tc.addr);
        expect(decoded, payload, reason: 'decoding failed for ${tc.addr}');
      }
    });

    test('max int64', () {
      final payload = _Uvarint.encode(BinaryOps.maxInt64);
      expect(payload, [0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0x7f]);

      final encoder = FilIdAddrEncoder();
      expect(
        encoder.encodeKey(payload, network: FilNetwork.testnet),
        't09223372036854775807',
      );

      final decoder = FilIdAddrDecoder();
      expect(decoder.decodeAddr('t09223372036854775807'), payload);
    });

    // test('max int64 + 1 fails', () {
    //   // Value exceeds 2^63-1
    //   const tooBig = 9223372036854775808;
    //   final payload = _Uvarint.encode(tooBig);
    //   final encoder = FilIdAddrEncoder(network: FilNetwork.testnet);
    //   expect(() => encoder.encodeKey(payload), _throwsAddrValidation());

    //   // String parsing also rejects it
    //   final decoder = FilIdAddrDecoder();
    //   expect(
    //     () => decoder.decodeAddr('t09223372036854775808'),
    //     _throwsAddrValidation(),
    //   );
    // });

    // test('incomplete uvarint payload fails', () {
    //   final encoder = FilIdAddrEncoder(network: FilNetwork.testnet);
    //   // 0x80 has continuation bit set but no following byte
    //   expect(() => encoder.encodeKey([0x80]), _throwsAddrValidation());
    // });

    test('random round-trip', () {
      final encoder = FilIdAddrEncoder();
      final decoder = FilIdAddrDecoder();

      for (var i = 0; i < 5; i++) {
        final id = QuickCrypto.nextU64() & BinaryOps.maxInt64;
        final payload = _Uvarint.encode(id);
        final encoded = encoder.encodeKey(payload, network: FilNetwork.testnet);
        final decoded = decoder.decodeAddr(encoded);
        expect(decoded, payload);
      }
    });
  });

  group('SECP256K1 Addresses', () {
    test('vector testnet', () {
      final encoder = FilSecp256k1AddrEncoder();
      final decoder = FilSecp256k1AddrDecoder();

      for (final tc in _secpTestVectors) {
        final encoded = encoder.encodeKey(
          tc.pubkey,
          network: FilNetwork.testnet,
        );
        expect(
          encoded,
          tc.testnet,
          reason: 'testnet encoding failed for ${tc.testnet}',
        );

        final decoded = decoder.decodeAddr(tc.testnet);
        final expectedHash = QuickCrypto.blake2b160Hash(tc.pubkey);
        expect(
          decoded,
          expectedHash,
          reason: 'testnet decoding failed for ${tc.testnet}',
        );
      }
    });

    test('vector mainnet', () {
      final encoder = FilSecp256k1AddrEncoder();
      final decoder = FilSecp256k1AddrDecoder();

      for (final tc in _secpTestVectors) {
        final encoded = encoder.encodeKey(tc.pubkey);
        expect(
          encoded,
          tc.mainnet,
          reason: 'mainnet encoding failed for ${tc.mainnet}',
        );

        final decoded = decoder.decodeAddr(tc.mainnet);
        final expectedHash = QuickCrypto.blake2b160Hash(tc.pubkey);
        expect(
          decoded,
          expectedHash,
          reason: 'mainnet decoding failed for ${tc.mainnet}',
        );
      }
    });

    test('random round-trip', () {
      final encoder = FilSecp256k1AddrEncoder();
      final decoder = FilSecp256k1AddrDecoder();

      for (var i = 0; i < 5; i++) {
        // Generate a 65-byte uncompressed secp256k1 pubkey (0x04 + 32-byte X + 32-byte Y)
        final pubkey = Secp256k1PrivateKey.random().publicKey.toBytes(
          mode: CryptoKeyEncoding.uncompressed,
        );
        final encoded = encoder.encodeKey(pubkey);
        final decoded = decoder.decodeAddr(encoded);
        final expectedHash = QuickCrypto.blake2b160Hash(pubkey);
        expect(decoded, expectedHash);
      }
    });
  });

  group('Actor Addresses', () {
    test('vector testnet', () {
      final encoder = FilActorAddrEncoder();
      final decoder = FilActorAddrDecoder();

      for (final tc in _actorTestVectors) {
        final encoded = encoder.encodeKey(tc.data, network: FilNetwork.testnet);
        expect(
          encoded,
          tc.testnet,
          reason: 'testnet encoding failed for ${tc.testnet}',
        );

        final decoded = decoder.decodeAddr(tc.testnet);
        final expectedHash = QuickCrypto.blake2b160Hash(tc.data);
        expect(
          decoded,
          expectedHash,
          reason: 'testnet decoding failed for ${tc.testnet}',
        );
      }
    });

    test('vector mainnet', () {
      final encoder = FilActorAddrEncoder();
      final decoder = FilActorAddrDecoder();

      for (final tc in _actorTestVectors) {
        final encoded = encoder.encodeKey(tc.data);
        expect(
          encoded,
          tc.mainnet,
          reason: 'mainnet encoding failed for ${tc.mainnet}',
        );

        final decoded = decoder.decodeAddr(tc.mainnet);
        final expectedHash = QuickCrypto.blake2b160Hash(tc.data);
        expect(
          decoded,
          expectedHash,
          reason: 'mainnet decoding failed for ${tc.mainnet}',
        );
      }
    });

    test('random round-trip', () {
      final encoder = FilActorAddrEncoder();
      final decoder = FilActorAddrDecoder();

      for (var i = 0; i < 20; i++) {
        final data = QuickCrypto.generateRandom(length: 20);

        final encoded = encoder.encodeKey(data);
        final decoded = decoder.decodeAddr(encoded);
        final expectedHash = QuickCrypto.blake2b160Hash(data);
        expect(decoded, expectedHash);
      }
    });
  });

  group('BLS Addresses', () {
    test('vector testnet', () {
      final encoder = FilBlsAddrEncoder();
      final decoder = FilBlsAddrDecoder();

      for (final tc in _blsTestVectors) {
        final encoded = encoder.encodeKey(
          tc.pubkey,
          network: FilNetwork.testnet,
        );
        expect(
          encoded,
          tc.testnet,
          reason: 'testnet encoding failed for ${tc.testnet}',
        );

        final decoded = decoder.decodeAddr(tc.testnet);
        expect(
          decoded,
          tc.pubkey,
          reason: 'testnet decoding failed for ${tc.testnet}',
        );
      }
    });

    test('vector mainnet', () {
      final encoder = FilBlsAddrEncoder();
      final decoder = FilBlsAddrDecoder();

      for (final tc in _blsTestVectors) {
        final encoded = encoder.encodeKey(tc.pubkey);
        expect(
          encoded,
          tc.mainnet,
          reason: 'mainnet encoding failed for ${tc.mainnet}',
        );

        final decoded = decoder.decodeAddr(tc.mainnet);
        expect(
          decoded,
          tc.pubkey,
          reason: 'mainnet decoding failed for ${tc.mainnet}',
        );
      }
    });

    test('random round-trip', () {
      final encoder = FilBlsAddrEncoder();
      final decoder = FilBlsAddrDecoder();

      for (var i = 0; i < 3; i++) {
        final pubkey = Bls12G1PrivateKey.random().publicKey.toBytes(
          mode: CryptoKeyEncoding.base,
        );

        final encoded = encoder.encodeKey(pubkey);
        final decoded = decoder.decodeAddr(encoded);
        expect(decoded, pubkey);
      }
    });

    test('invalid pubkey length', () {
      final encoder = FilBlsAddrEncoder();
      expect(
        () => encoder.encodeKey(List<int>.filled(12, 0)),
        _throwsAddrValidation(),
      );
      expect(
        () => encoder.encodeKey(List<int>.filled(50, 0)),
        _throwsAddrValidation(),
      );
      expect(
        () => encoder.encodeKey(List<int>.filled(48, 1)),
        _throwsAddrValidation(),
      );
    });
  });

  group('Delegated Addresses', () {
    test('vector tests', () {
      final encoder = FilDelegatedAddrEncoder();
      final decoder = FilDelegatedAddrDecoder();

      // Test 1: namespace 32, 5-byte subaddress
      final tc1 = _delegatedTestVectors[0];
      final payload1 = [..._Uvarint.encode(tc1.namespace), ...tc1.subaddress];
      expect(encoder.encodeKey(payload1), tc1.expected);
      expect(decoder.decodeAddr(tc1.expected), payload1);

      // Test 2: max int64 namespace, empty subaddress
      final tc2 = _delegatedTestVectors[1];
      final payload2 = [..._Uvarint.encode(tc2.namespace), ...tc2.subaddress];
      expect(encoder.encodeKey(payload2), tc2.expected);
      expect(decoder.decodeAddr(tc2.expected), payload2);

      // Test 3: max int64 namespace, 54 zero-byte subaddress
      final tc3 = _delegatedTestVectors[2];
      final subaddress3 = Uint8List(54); // all zeros
      final payload3 = [..._Uvarint.encode(tc3.namespace), ...subaddress3];
      expect(encoder.encodeKey(payload3), tc3.expected);
      expect(decoder.decodeAddr(tc3.expected), payload3);
    });

    test('subaddress too long fails', () {
      final encoder = FilDelegatedAddrEncoder();
      final payload = [
        ..._Uvarint.encode(BigInt.one),
        ...Uint8List(FilAddrConst.maxSubaddressLen + 1),
      ];
      expect(() => encoder.encodeKey(payload), _throwsAddrValidation());
    });

    test('random round-trip', () {
      final rnd = Random.secure();
      final encoder = FilDelegatedAddrEncoder();
      final decoder = FilDelegatedAddrDecoder();

      for (var i = 0; i < 20; i++) {
        final namespace = QuickCrypto.nextU64() & BinaryOps.maxInt64;
        final subLen = rnd.nextInt(FilAddrConst.maxSubaddressLen + 1);
        final subaddress = QuickCrypto.generateRandom(length: subLen);

        final payload = [..._Uvarint.encode(namespace), ...subaddress];
        final encoded = encoder.encodeKey(payload, network: FilNetwork.testnet);
        final decoded = decoder.decodeAddr(encoded);
        expect(decoded, payload);
      }
    });
  });

  group('Auto-detect decoder (FilAddrDecoder)', () {
    test('decodes all known test addresses', () {
      final decoder = FilAddrDecoder();

      for (final addr in _allTestAddresses) {
        expect(
          () => decoder.decodeAddr(addr),
          returnsNormally,
          reason: 'failed to decode $addr',
        );
      }
    });

    test('round-trip all test addresses', () {
      final decoder = FilAddrDecoder();

      for (final addr in _allTestAddresses) {
        final decoded = decoder.decodeAddr(addr);
        expect(decoded, isNotEmpty, reason: 'empty payload for $addr');
      }
    });
  });

  group('Invalid String Addresses', () {
    test('unknown network prefix', () {
      final decoder = FilAddrDecoder();
      expect(
        () => decoder.decodeAddr('Q2gfvuyh7v2sx3patm5k23wdzmhyhtmqctasbr23y'),
        _throwsAddrValidation(),
      );
    });

    test('unknown protocol', () {
      final decoder = FilAddrDecoder();
      expect(
        () => decoder.decodeAddr('t5gfvuyh7v2sx3patm5k23wdzmhyhtmqctasbr23y'),
        _throwsAddrValidation(),
      );
      expect(() => decoder.decodeAddr('f5abc'), _throwsAddrValidation());
    });

    test('invalid checksum', () {
      // Corrupt last char of a valid actor address
      final decoder = FilActorAddrDecoder();
      expect(
        () => decoder.decodeAddr('t2gfvuyh7v2sx3patm5k23wdzmhyhtmqctasbr24y'),
        _throwsAddrValidation(),
      );
    });

    test('ID invalid payload (non-digits)', () {
      final decoder = FilIdAddrDecoder();
      expect(
        () => decoder.decodeAddr('t0banananananannnnnnn'),
        _throwsAddrValidation(),
      );
    });

    test('ID too long', () {
      final decoder = FilIdAddrDecoder();
      // 20 chars after t0 exceeds MaxInt64StringLength (19)
      expect(
        () => decoder.decodeAddr('t0${'a' * 20}'),
        _throwsAddrValidation(),
      );
      // 21 chars after t0 also too long
      expect(
        () => decoder.decodeAddr('t0banananananannnnnnnnn'),
        _throwsAddrValidation(),
      );
    });

    test('base32 corrupt input', () {
      final decoder = FilActorAddrDecoder();
      // '1' is not in the base32 alphabet
      expect(
        () => decoder.decodeAddr('t2gfvuyh7v2sx3patm1k23wdzmhyhtmqctasbr24y'),
        throwsA(anything),
      );
      // 'T' is not in the base32 alphabet
      expect(
        () => decoder.decodeAddr('t2gfvuyh7v2sx3paTm1k23wdzmhyhtmqctasbr24y'),
        throwsA(anything),
      );
    });

    test('address too short', () {
      final decoder = FilAddrDecoder();
      expect(() => decoder.decodeAddr('t2'), _throwsAddrValidation());
      expect(() => decoder.decodeAddr('t1234q'), _throwsAddrValidation());
      expect(() => decoder.decodeAddr('t'), _throwsAddrValidation());
      expect(() => decoder.decodeAddr('t0'), _throwsAddrValidation());
    });

    test('address too long', () {
      final decoder = FilAddrDecoder();
      expect(
        () =>
            decoder.decodeAddr('a' * (FilAddrConst.maxAddressStringLength + 1)),
        _throwsAddrValidation(),
      );
    });

    test('SECP256K1 wrong decoded length', () {
      final decoder = FilSecp256k1AddrDecoder();
      // 24 bytes = correct payload+checksum length, but checksum won't match
      final invalidChecksum = _b32enc(List.filled(24, 0x61));
      expect(
        () => decoder.decodeAddr('t1$invalidChecksum'),
        _throwsAddrValidation(),
      );

      // 25 bytes = too long
      final tooLong = _b32enc(List.filled(25, 0x61));
      expect(() => decoder.decodeAddr('t1$tooLong'), _throwsAddrValidation());

      // 23 bytes = too short
      final tooShort = _b32enc(List.filled(23, 0x61));
      expect(() => decoder.decodeAddr('t1$tooShort'), _throwsAddrValidation());
    });

    test('Actor wrong decoded length', () {
      final decoder = FilActorAddrDecoder();
      final invalidChecksum = _b32enc(List.filled(24, 0x61));
      expect(
        () => decoder.decodeAddr('t2$invalidChecksum'),
        _throwsAddrValidation(),
      );

      final tooLong = _b32enc(List.filled(25, 0x61));
      expect(() => decoder.decodeAddr('t2$tooLong'), _throwsAddrValidation());

      final tooShort = _b32enc(List.filled(23, 0x61));
      expect(() => decoder.decodeAddr('t2$tooShort'), _throwsAddrValidation());
    });

    test('BLS wrong decoded length', () {
      final decoder = FilBlsAddrDecoder();
      // 52 bytes = correct payload+checksum length (48+4)
      final invalidChecksum = _b32enc(List.filled(52, 0x61));
      expect(
        () => decoder.decodeAddr('t3$invalidChecksum'),
        _throwsAddrValidation(),
      );

      final tooLong = _b32enc(List.filled(53, 0x61));
      expect(() => decoder.decodeAddr('t3$tooLong'), _throwsAddrValidation());

      final tooShort = _b32enc(List.filled(51, 0x61));
      expect(() => decoder.decodeAddr('t3$tooShort'), _throwsAddrValidation());
    });
  });

  group('Encoder payload validation', () {
    test('BLS wrong pubkey length', () {
      final encoder = FilBlsAddrEncoder();
      expect(() => encoder.encodeKey(Uint8List(47)), _throwsAddrValidation());
      expect(() => encoder.encodeKey(Uint8List(49)), _throwsAddrValidation());
    });

    test('Delegated subaddress too long', () {
      final encoder = FilDelegatedAddrEncoder();
      final payload = [
        ..._Uvarint.encode(BigInt.one),
        ...Uint8List(FilAddrConst.maxSubaddressLen + 1),
      ];
      expect(() => encoder.encodeKey(payload), _throwsAddrValidation());
    });
  });

  group('Checksum', () {
    test('valid checksum passes', () {
      final decoder = FilSecp256k1AddrDecoder();
      // Use a known-good address
      final addr = _secpTestVectors[0].testnet;
      expect(() => decoder.decodeAddr(addr), returnsNormally);
    });

    test('corrupted checksum fails', () {
      final decoder = FilSecp256k1AddrDecoder();
      // Flip last char
      final bad = 't15ihq5ibzwki2b4ep2f46avlkrqzhpqgtga7pdrs';
      expect(() => decoder.decodeAddr(bad), _throwsAddrValidation());
    });
  });

  group('Trailing bits (canonical base32)', () {
    test('good string decodes successfully', () {
      final decoder = FilSecp256k1AddrDecoder();
      const good = 'f1xpbyy4tkdx5si2bgo37dubc2xwv6fum5tk57mia';
      expect(() => decoder.decodeAddr(good), returnsNormally);
    });

    test('bad string with invalid trailing bits fails', () {
      final decoder = FilSecp256k1AddrDecoder();
      const bad = 'f1xpbyy4tkdx5si2bgo37dubc2xwv6fum5tk57mid';
      // NOTE: This test requires canonical base32 validation in the
      // implementation (re-encode decoded bytes and compare to input).
      // If your Base32Decoder does not enforce canonical encoding,
      // add the check in _FilAddrUtils.decodeHashAddr before calling
      // Base32Decoder.decode.
      expect(() => decoder.decodeAddr(bad), throwsA(anything));
    });

    test('canonical base32 helper', () {
      expect(
        _isCanonicalBase32('xpbyy4tkdx5si2bgo37dubc2xwv6fum5tk57mia'),
        isTrue,
      );
      expect(
        _isCanonicalBase32('xpbyy4tkdx5si2bgo37dubc2xwv6fum5tk57mid'),
        isFalse,
      );
    });
  });

  group('Empty / Undef address', () {
    test('empty string fails', () {
      final decoder = FilAddrDecoder();
      expect(() => decoder.decodeAddr(''), _throwsAddrValidation());
    });
  });
}

void main() {
  BlockchainUtilsTestApi.runTest(filecoinTest, "Filecoin");
}
