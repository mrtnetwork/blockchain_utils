import 'package:blockchain_utils/chain/address/protocol/p2pkh_addr.dart';
import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/protocol/bip/coin_conf/constant/coins_conf.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';
import 'package:blockchain_utils/utils/string/string.dart';

/// bip38 address class
class Bip38Addr {
  /// Calculate the address hash from a public key and a specified public key mode.
  static BuBytes addressHash(List<int> pubKey, CryptoKeyEncoding pubKeyMode) {
    const int addrHashLen = 4;
    final address = P2PKHAddrEncoder().encodeKey(
      pubKey,
      netVersion: CoinsConf.bitcoinMainNet.params.p2pkhNetVer,
      pubKeyMode: pubKeyMode,
    );
    return QuickCrypto.sha256DoubleHash(
      StringUtils.encode(address),
    ).sublist(0, addrHashLen);
  }
}
