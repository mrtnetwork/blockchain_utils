// ignore_for_file: depend_on_referenced_packages

import 'package:blockchain_utils/bip/address/p2pkh_addr.dart';
import 'package:blockchain_utils/bip/coin_conf/coins_conf.dart';
import 'package:blockchain_utils/bip/wif/wif.dart';
import 'package:example/test/quick_hex.dart';
import 'package:blockchain_utils/utils/utils.dart';

final List<Map<String, dynamic>> _testVector = [
  {
    "key_bytes":
        "5e9441950b3918772cc3da1fc6735b7c33f1bbe08a8f1e704be46cb664f7e457",
    "encode": "5JXwUhNu98kXkyhR8EpvpaTGRjj8JZEP7hWboB5xscgjbgK2zNk",
    "pub_key_mode": PubKeyModes.uncompressed,
    "net_ver": CoinsConf.bitcoinMainNet.params.wifNetVer,
  },
  {
    "key_bytes":
        "5e9441950b3918772cc3da1fc6735b7c33f1bbe08a8f1e704be46cb664f7e457",
    "encode": "92Ja4SCSjMpfj3ChkaiqhB1E5Q5qTimaTeNYsoSUDMRnNiDZUez",
    "pub_key_mode": PubKeyModes.uncompressed,
    "net_ver": CoinsConf.bitcoinTestNet.params.wifNetVer,
  },
  {
    "key_bytes":
        "1837c1be8e2995ec11cda2b066151be2cfb48adf9e47b151d46adab3a21cdf67",
    "encode": "Kx2nc8CerNfcsutaet3rPwVtxQvXuQTYxw1mSsfFHsWExJ9xVpLf",
    "pub_key_mode": PubKeyModes.compressed,
    "net_ver": CoinsConf.bitcoinMainNet.params.wifNetVer,
  },
  {
    "key_bytes":
        "1837c1be8e2995ec11cda2b066151be2cfb48adf9e47b151d46adab3a21cdf67",
    "encode": "cNPn53CWHSMt3MMr3HrymFzxaeDwZrZF2yAEZJ7knzAFD3GTTi2x",
    "pub_key_mode": PubKeyModes.compressed,
    "net_ver": CoinsConf.bitcoinTestNet.params.wifNetVer,
  },
  {
    "key_bytes":
        "a215750fac2ad0382e40ad02d11aa1467f5ec844f0a7e995c1b3e979fbdc71d0",
    "encode": "7rnFCh34mBbn3uxT9FwNbS4hfdbn7W75u19Jmn3YoS5mXZjPoaX",
    "pub_key_mode": PubKeyModes.uncompressed,
    "net_ver": CoinsConf.dashMainNet.params.wifNetVer,
  },
  {
    "key_bytes":
        "a215750fac2ad0382e40ad02d11aa1467f5ec844f0a7e995c1b3e979fbdc71d0",
    "encode": "92pJNokBb5GhmdJ8sYfLyf3oid9us9bjSNd5K27vbNKLoLLfwfP",
    "pub_key_mode": PubKeyModes.uncompressed,
    "net_ver": CoinsConf.dashTestNet.params.wifNetVer,
  },
  {
    "key_bytes":
        "132750b8489385430d8bfa3871ade97da7f5d5ef134a5c85184f88743b526e38",
    "encode": "XBvs6XpB5U7xxB6muoJmWzFKssp8PzNvPzfQsGMNeLMLcd3pdCC9",
    "pub_key_mode": PubKeyModes.compressed,
    "net_ver": CoinsConf.dashMainNet.params.wifNetVer,
  },
  {
    "key_bytes":
        "132750b8489385430d8bfa3871ade97da7f5d5ef134a5c85184f88743b526e38",
    "encode": "cNDw7BRfCrBn4HZfGT82P5ZNb5qxcdsN6TTyTAUgq5jFUD5xFN65",
    "pub_key_mode": PubKeyModes.compressed,
    "net_ver": CoinsConf.dashTestNet.params.wifNetVer,
  },
  {
    "key_bytes":
        "21f5e16d57b9b70a1625020b59a85fa9342de9c103af3dd9f7b94393a4ac2f46",
    "encode": "6JPaMAeJjouhb8xPzFzETYCHJAJ9wBoFsCyC1LXFSTcZDmHgy6L",
    "pub_key_mode": PubKeyModes.uncompressed,
    "net_ver": CoinsConf.dogecoinMainNet.params.wifNetVer,
  },
  {
    "key_bytes":
        "21f5e16d57b9b70a1625020b59a85fa9342de9c103af3dd9f7b94393a4ac2f46",
    "encode": "95jMzQtxU83VnEBwENWAd9xZJdQktdjwBFr8FmcewrAkBNHta8u",
    "pub_key_mode": PubKeyModes.uncompressed,
    "net_ver": CoinsConf.dogecoinTestNet.params.wifNetVer,
  },
  {
    "key_bytes":
        "7c5e3d057ec9d8cd61c8e59873fd3ff478cbe0808c444092986e34cc533fa5d7",
    "encode": "QSnP9ZrYTcs3iu5x2uft3mGsnFMMisgshuhAMxYLaES6cndEdopn",
    "pub_key_mode": PubKeyModes.compressed,
    "net_ver": CoinsConf.dogecoinMainNet.params.wifNetVer,
  },
  {
    "key_bytes":
        "7c5e3d057ec9d8cd61c8e59873fd3ff478cbe0808c444092986e34cc533fa5d7",
    "encode": "ciuibxmCzNuTbrBhwCS18D8JSK2W1cCDDaPyofJCKwzAzG51dDJk",
    "pub_key_mode": PubKeyModes.compressed,
    "net_ver": CoinsConf.dogecoinTestNet.params.wifNetVer,
  },
  {
    "key_bytes":
        "4baa38b7623a40da63836cd9ee8c51d0b6273e766c88adde156fd5fec6e19008",
    "encode": "6uhLoqNczaCPTj3GmT7qfau4Qrp5qb7riHtYshudPgbiGSx3bVs",
    "pub_key_mode": PubKeyModes.uncompressed,
    "net_ver": CoinsConf.litecoinMainNet.params.wifNetVer,
  },
  {
    "key_bytes":
        "4baa38b7623a40da63836cd9ee8c51d0b6273e766c88adde156fd5fec6e19008",
    "encode": "92AEvSedgNoexQehsyDnknfr73cKnxD2HZMLF9F71y29MZAdg13",
    "pub_key_mode": PubKeyModes.uncompressed,
    "net_ver": CoinsConf.litecoinTestNet.params.wifNetVer,
  },
  {
    "key_bytes":
        "abd83a20f1161f5ddb561b64de3e60d2b6350e3b6bc35968e52edb097c73a2c3",
    "encode": "T8p29oRNZpvaE1QbpQ2Fr3kQcrgfzT9KjvzwapwgsqBdMotY6kQW",
    "pub_key_mode": PubKeyModes.compressed,
    "net_ver": CoinsConf.litecoinMainNet.params.wifNetVer,
  },
  {
    "key_bytes":
        "abd83a20f1161f5ddb561b64de3e60d2b6350e3b6bc35968e52edb097c73a2c3",
    "encode": "cTLkAy83bWeEccEzfAtX11i6JELmapE7zmF9qSmeoyfU6fQWAyxC",
    "pub_key_mode": PubKeyModes.compressed,
    "net_ver": CoinsConf.litecoinTestNet.params.wifNetVer,
  },
];

void wifTest() {
  for (final i in _testVector) {
    final dec = WifDecoder.decode(i["encode"], netVer: i["net_ver"]);
    assert(
        dec.item1.toHex() == i["key_bytes"] && dec.item2 == i["pub_key_mode"],
        true);
  }
  for (final i in _testVector) {
    final encode = WifEncoder.encode(BytesUtils.fromHexString(i["key_bytes"]),
        netVer: i["net_ver"], pubKeyMode: i["pub_key_mode"]);
    assert(i["encode"] == encode);
  }
}
