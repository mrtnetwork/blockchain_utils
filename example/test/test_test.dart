import 'package:example/test/address/ada_shelly/ada_shelly_test.dart';
import 'package:example/test/address/algo/algo_test.dart';
import 'package:example/test/address/aptos/aptos_test.dart';
import 'package:example/test/address/atom/atom_test.dart';
import 'package:example/test/address/avax/avax_test.dart';
import 'package:example/test/address/bch_p2pkh/bch_p2pkh_test.dart';
import 'package:example/test/address/bch_p2sh/bch_p2sh_test.dart';
import 'package:example/test/address/egld/egld_test.dart';
import 'package:example/test/address/eos/eos_test.dart';
import 'package:example/test/address/ergo/ergo_test.dart';
import 'package:example/test/address/eth/eth_test.dart';
import 'package:example/test/address/fil/fil_test.dart';
import 'package:example/test/address/icx/icx_test.dart';
import 'package:example/test/address/inj/inj_test.dart';
import 'package:example/test/address/nano/nano_test.dart';
import 'package:example/test/address/near/near_test.dart';
import 'package:example/test/address/neo/neo_test.dart';
import 'package:example/test/address/okex/okex_test.dart';
import 'package:example/test/address/one/one_test.dart';
import 'package:example/test/address/p2pkh/p2pkh_test.dart';
import 'package:example/test/address/p2sh/p2sh_test.dart';
import 'package:example/test/address/p2tr/p2tr_test.dart';
import 'package:example/test/address/p2wpkh/p2wpkh_test.dart';
import 'package:example/test/address/sol/sol_test.dart';
import 'package:example/test/address/substrate/substrate_test.dart';
import 'package:example/test/address/trx/trx_test.dart';
import 'package:example/test/address/xlm/xml_test.dart';
import 'package:example/test/address/xmr/xmr_test.dart';
import 'package:example/test/address/xrp/xrp_test.dart';
import 'package:example/test/address/xtz/xtz_test.dart';
import 'package:example/test/address/zil/zil_test.dart';
import 'package:example/test/algorand/mnemonic_test.dart';
import 'package:example/test/base58/base58_test.dart';
import 'package:example/test/base58/base58_xmr_test.dart';
import 'package:example/test/bech32/bch_bech32_test.dart';
import 'package:example/test/bech32/bech32_test.dart';
import 'package:example/test/bech32/segwit_bech32_test.dart';
import 'package:example/test/bip/bip32/ed25519/ed25519_test.dart';
import 'package:example/test/bip/bip32/ed25519_blake2b/ed25519_blake2b_test.dart';
import 'package:example/test/bip/bip32/ed25519_khalow/ed25519_khalow_test.dart';
import 'package:example/test/bip/bip32/nist256p1/nist256p1_test.dart';
import 'package:example/test/bip/bip32/secp256k1/secp256k1_test.dart';
import 'package:example/test/bip/bip38/bip38_addr_test.dart';
import 'package:example/test/bip/bip38/bip38_ec_test.dart';
import 'package:example/test/bip/bip38/bip38_no_ec_test.dart';
import 'package:example/test/bip/bip39/bip39_test.dart';
import 'package:example/test/bip/bip44/bip44_test.dart';
import 'package:example/test/bip/bip49/bip49_test.dart';
import 'package:example/test/bip/bip84/bip84_test.dart';
import 'package:example/test/bip/bip86/bip86_test.dart';
import 'package:example/test/cardano/bip32/icarus_test.dart';
import 'package:example/test/cardano/bip32/legacy_test.dart';
import 'package:example/test/cardano/byron/byron_lagacy_test.dart';
import 'package:example/test/cardano/cip1852/cip1852_test.dart';
import 'package:example/test/cardano/mnemonic/mnemonic_test.dart';
import 'package:example/test/cardano/shelly/shelly_test.dart';
import 'package:example/test/cbor_test.dart';
import 'package:example/test/crypto/aes/aes_ctr_test.dart';
import 'package:example/test/crypto/blake2b/blake2b_test.dart';
import 'package:example/test/crypto/chacha20_poly1305/chacha20_poly1305_test.dart';
import 'package:example/test/crypto/crc32/crc32_test.dart';
import 'package:example/test/crypto/hmac/hmac_test.dart';
import 'package:example/test/crypto/keccack/keccack_test.dart';
import 'package:example/test/crypto/md4/md4_test.dart';
import 'package:example/test/crypto/md5/md5_test.dart';
import 'package:example/test/crypto/pbkdf2/pbkdf2_test.dart';
import 'package:example/test/crypto/ripemd/ripemd_test.dart';
import 'package:example/test/crypto/scrypt/scrypt_test.dart';
import 'package:example/test/crypto/sha1/sha1_test.dart';
import 'package:example/test/crypto/sha256/sha256_test.dart';
import 'package:example/test/crypto/sha3/sha3_test.dart';
import 'package:example/test/crypto/sha512/sha512_test.dart';
import 'package:example/test/crypto/sha512_256/sha512_256_test.dart';
import 'package:example/test/crypto/shake/shake_test.dart';
import 'package:example/test/crypto/x_modem_crc/x_modem_crc_test.dart';
import 'package:example/test/ecdsa/ed_test.dart';
import 'package:example/test/ecdsa/projective_test.dart';
import 'package:example/test/elctrum/mnemonic/mnemonic_test.dart';
import 'package:example/test/elctrum/v1/v1_test.dart';
import 'package:example/test/elctrum/v2/v2_test.dart';
import 'package:example/test/monero/mnemonic/monero_mnemonic_test.dart';
import 'package:example/test/monero/monero_test.dart';
import 'package:example/test/schnorrkel/derive_test.dart';
import 'package:example/test/schnorrkel/schnorrkel_key_test.dart';
import 'package:example/test/schnorrkel/sign_test.dart';
import 'package:example/test/schnorrkel/vrf_test.dart';
import 'package:example/test/secure_storage_test.dart';
import 'package:example/test/ss58/ss58_test.dart';
import 'package:example/test/substrate/scale_test.dart';
import 'package:example/test/substrate/substrate_test.dart';
import 'package:example/test/uuid_test.dart';
import 'package:example/test/wif/wif_test.dart';
import 'package:flutter/foundation.dart';

void main() {
  _testAll();
}

typedef TestMethod = void Function();

/// its very slow in web debugging
/// if you want to test this method on the web  should remove the condition
void _web() {
  if (kIsWeb) return;
  _test("bip38 No Ecdsa", bip38NoEcdsaTest);
  _test("bip38 ECDSA", bip38ECDSATest);
  _test("scrypt", testScrypt);
  _test("pbkdf2", pbkdf2Test);
  _test("secure storage", testSecureStorage);
}

void _test(String name, TestMethod process) {
  try {
    process();
    print("pass $name");
  } catch (e) {
    throw Exception();
  }
}

void _testAll() async {
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
