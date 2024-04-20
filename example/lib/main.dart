// ignore_for_file: avoid_print

import 'package:example/test/address/ada_shelly/ada_shelly.dart';
import 'package:example/test/address/algo/algo.dart';
import 'package:example/test/address/aptos/aptos.dart';
import 'package:example/test/address/atom/atom.dart';
import 'package:example/test/address/avax/avax.dart';
import 'package:example/test/address/bch_p2pkh/bch_p2pkh.dart';
import 'package:example/test/address/bch_p2sh/bch_p2sh.dart';
import 'package:example/test/address/egld/egld.dart';
import 'package:example/test/address/eos/eos.dart';
import 'package:example/test/address/ergo/ergo.dart';
import 'package:example/test/address/eth/eth.dart';
import 'package:example/test/address/fil/fil.dart';
import 'package:example/test/address/icx/icx.dart';
import 'package:example/test/address/inj/inj.dart';
import 'package:example/test/address/nano/nano.dart';
import 'package:example/test/address/neo/neo.dart';
import 'package:example/test/address/okex/okex.dart';
import 'package:example/test/address/one/one.dart';
import 'package:example/test/address/p2pkh/p2pkh.dart';
import 'package:example/test/address/p2sh/p2sh.dart';
import 'package:example/test/address/p2tr/p2tr.dart';
import 'package:example/test/address/p2wpkh/p2wpkh.dart';
import 'package:example/test/address/sol/sol.dart';
import 'package:example/test/address/substrate/substrate.dart';
import 'package:example/test/address/trx/trx.dart';
import 'package:example/test/address/xlm/xml.dart';
import 'package:example/test/address/xmr/xmr.dart';
import 'package:example/test/address/xrp/xrp.dart';
import 'package:example/test/address/xtz/xtz.dart';
import 'package:example/test/address/zil/zil.dart';
import 'package:example/test/algorand/mnemonic.dart';
import 'package:example/test/base58/base58.dart';
import 'package:example/test/base58/base58_xmr.dart';
import 'package:example/test/bech32/bch_bech32.dart';
import 'package:example/test/bech32/bech32.dart';
import 'package:example/test/bech32/segwit_bech32.dart';
import 'package:example/test/bip/bip32/ed25519/ed25519.dart';
import 'package:example/test/bip/bip32/ed25519_blake2b/ed25519_blake2b.dart';
import 'package:example/test/bip/bip32/ed25519_khalow/ed25519_khalow.dart';
import 'package:example/test/bip/bip32/nist256p1/nist256p1.dart';
import 'package:example/test/bip/bip32/secp256k1/secp256k1.dart';
import 'package:example/test/bip/bip38/bip38_addr.dart';
import 'package:example/test/bip/bip38/bip38_ec.dart';
import 'package:example/test/bip/bip38/bip38_no_ec.dart';
import 'package:example/test/bip/bip39/bip39.dart';
import 'package:example/test/bip/bip44/bip44.dart';
import 'package:example/test/bip/bip49/bip49.dart';
import 'package:example/test/bip/bip84/bip84.dart';
import 'package:example/test/bip/bip86/bip86.dart';
import 'package:example/test/cardano/bip32/icarus.dart';
import 'package:example/test/cardano/bip32/legacy.dart';
import 'package:example/test/cardano/byron/byron_lagacy.dart';
import 'package:example/test/cardano/cip1852/cip1852.dart';
import 'package:example/test/cardano/mnemonic/mnemonic.dart';
import 'package:example/test/cardano/shelly/shelly.dart';
import 'package:example/test/cbor.dart';
import 'package:example/test/crypto/aes/aes_ctr.dart';
import 'package:example/test/crypto/blake2b/blake2b.dart';
import 'package:example/test/crypto/chacha20_poly1305/chacha20_poly1305.dart';
import 'package:example/test/crypto/crc32/crc32.dart';
import 'package:example/test/crypto/hmac/hmac.dart';
import 'package:example/test/crypto/keccack/keccack.dart';
import 'package:example/test/crypto/md4/md4.dart';
import 'package:example/test/crypto/md5/md5.dart';
import 'package:example/test/crypto/pbkdf2/pbkdf2.dart';
import 'package:example/test/crypto/ripemd/ripemd.dart';
import 'package:example/test/crypto/scrypt/scrypt.dart';
import 'package:example/test/crypto/sha1/sha1.dart';
import 'package:example/test/crypto/sha256/sha256.dart';
import 'package:example/test/crypto/sha3/sha3.dart';
import 'package:example/test/crypto/sha512/sha512.dart';
import 'package:example/test/crypto/sha512_256/sha512_256.dart';
import 'package:example/test/crypto/shake/shake.dart';
import 'package:example/test/crypto/x_modem_crc/x_modem_crc.dart';
import 'package:example/test/ecdsa/ed.dart';
import 'package:example/test/ecdsa/projective.dart';
import 'package:example/test/elctrum/mnemonic/mnemonic.dart';
import 'package:example/test/elctrum/v1/v1.dart';
import 'package:example/test/elctrum/v2/v2.dart';
import 'package:example/test/monero/mnemonic/monero_mnemonic.dart';
import 'package:example/test/monero/monero.dart';
import 'package:example/test/schnorrkel/derive.dart';
import 'package:example/test/schnorrkel/schnorrkel_key.dart';
import 'package:example/test/schnorrkel/sign.dart';
import 'package:example/test/schnorrkel/vrf.dart';
import 'package:example/test/secure_storage.dart';
import 'package:example/test/ss58/ss58.dart';
import 'package:example/test/substrate/scale.dart';
import 'package:example/test/substrate/substrate.dart';
import 'package:example/test/uuid.dart';
import 'package:example/test/wif/wif.dart';
import 'package:flutter/material.dart';

import 'test/address/near/near.dart';

/// for test in different ENV
/// The package is created in Pure Dart and this test contains thousands of tests,
/// it may take a long time (5-10) minutes.
void main() {
  runApp(MaterialApp(
    home: Scaffold(
      body: Column(
        children: [
          FilledButton(
              onPressed: () {
                _testAll();
              },
              child: const Text("start test"))
        ],
      ),
    ),
  ));
  // _testAll();
}

typedef TestMethod = void Function();

/// its very slow in web debugging
/// if you want to test this method on the web  should remove the condition
void _web() {
  // if (kIsWeb) return;
  _test("bip38 No Ecdsa", bip38NoEcdsaTest);
  _test("bip38 ECDSA", bip38ECDSATest);
  _test("scrypt", testScrypt);
  _test("pbkdf2", pbkdf2Test);
  _test("secure storage", testSecureStorage);
}

void _test(String name, TestMethod process) {
  try {
    process();
    print("test pass $name");
  } catch (e) {
    print("test error $name $e");
    throw Exception();
  }
}

void _testAll() async {
  final DateTime start = DateTime.now();
  _encodeDecodeAddrTest();

  _test("UUID", testUUID);
  _test("bech32", bech32Test);
  _test("wif", wifTest);
  _test("substrate scale", substrateScaleTest);
  _test("ss58", ss58Test);
  _test("bip38 ", bip38Test);
  _test("segwit Bech32 ", segwitBech32Test);
  _test("bch bech32", bchBech32Test);
  _test("base58 xmr", testBase58XMR);
  _test("base58", testBase58);
  _test("bip49", bip49Test);
  _test("bip44", bip44Test);
  _test("algorandMnemonic and derive address", algorandMnemonicAndAddressTest);
  _test("substrate derive", substrateDeriveTest);
  _test("monero mnemonic", moneroMnemonucTest);
  _test("monero", moneroTest);
  _test("electrum v2", electrumV2Test);
  _test("electrum v1", electrumV1Test);
  _test("electrum mnemonic", electrumMnemonicTest);
  _test("cardano shelly", cardanoShellyTest);
  _test("cardano mnemonic", cardanoMnemonicTest);
  _test("cardano cip1852", cip1852Test);
  _test("byron legacy", byronLegacyTest);
  _test("cardano icarus", cardanoIcarusTest);
  _test("cardano legacy", cardanoLegacyTest);
  _test("bip86", bip86Test);
  _test("bip84", bip84Test);
  _test("bip39", testBip39);
  _test("secp256k1", secpTest);
  _test("nist", nistTest);
  _test("ed25519-blake2b", edBlake2bTest);
  _test("ed25519-khalow", edKhalowTest);
  _test("ed25519", edTest);
  _test("schnorr", schnoorTestDerive);
  _test("vrf sigh", vrfSignTest);
  _test("schnorrkel keys", schnoorKeyTest);
  _test("schnorrkel-sign", testSchnoor);
  _test("ecdsa", testECDSA);
  _test("eddsa", testEDDSa);
  _test("sha1", testSha1);
  _test("ripemd", testRipemd);
  _test("md5", md5Test);
  _test("md4", md4Test);
  _test("keccack", testKecc);
  _test("hmac", testHmac);
  _test("crc", crcTest);
  _test("chacha-poly1305", chachaTest);
  _test("aes", testAes);
  _test("blake2b", blake2bTest);
  _test("sha256", testSha256);
  _test("sha512", testSha512);
  _test("sha3", testSha3);
  _test("sha512/256", testSha512256);
  _test("modemCrc", testModemCrc);
  _test("shake digest", testShakeDigest);
  _test("cbor test", cborTest);

  _web();
  final DateTime end = DateTime.now();
  print("end: ${end.difference(start).inMilliseconds}");
}

void _encodeDecodeAddrTest() {
  _test("zil Address", zilAddressTest);
  _test("xtz Address", xtzAddressTest);
  _test("xrp Address", xrpAddressTest);
  _test("xmr Address", xmrAddressTest);
  _test("xlm Address", xlmAddressTest);
  _test("trx Address", trxAddressTest);
  _test("substrate Address", substrateAddressTest);
  _test("sol Address", solAddressTest);
  _test("p2wpkh Address", p2wpkhAddressTest);
  _test("p2tr Address", p2trAddressTest);
  _test("p2sh Address", p2shAddressTest);
  _test("p2pkh Address", p2pkhAddressTest);
  _test("one Address", oneAddressTest);
  _test("okex Address", okexAddressTest);
  _test("neo Address", neoAddressTest);
  _test("near Address", nearAddressTest);
  _test("nano Address", nanoAddressTest);
  _test("injAddressTest", injAddressTest);
  _test("icx Address", icxAddressTest);
  _test("fil Address", filAddressTest);
  _test("ethereum Address", ethereumAddressTest);
  _test("ergo Address", ergoAddressTest);
  _test("eos Address", eosAddrTest);
  _test("egld Address", egldAddrTest);
  _test("bchP2sh Address", bchP2shAddressTest);
  _test("bchP2pkh Address", bchP2pkhTest);
  _test("avax Address", avaxAddrTest);
  _test("atom Address", atomAddressTest);
  _test("aptos Address", aptosAddressTest);
  _test("algo Address", algoAddressTest);
  _test("ada Shelly Address", adaShellyAddrTest);
}
