import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/protocol/bip/bip/conf/core/coin_conf.dart';
import 'package:blockchain_utils/protocol/bip/bip/conf/core/coins.dart';
import 'package:blockchain_utils/protocol/bip/coin_conf/models/coins_name.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';

import 'package:blockchain_utils/protocol/non_derivable_coin/conf/non_derivable_coin_conf.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Coins without an HD derivation standard.
///
/// These entries only tag imported or randomly generated keys with the
/// correct key type (e.g. Filecoin BLS f3 accounts, NEAR ML-DSA-65 access
/// keys). Identifiers start at 2000 to stay clear of the BIP proposal
/// identifier ranges.
enum NonDerivableCoins implements CryptoCoins<NonDerivableCoinConfig> {
  filecoinBls('filecoinBls', 2000),
  nearMlDsa65('nearMlDsa65', 2001);

  final String name;
  @override
  final int identifier;

  const NonDerivableCoins(this.name, this.identifier);

  @override
  NonDerivableCoins get value {
    return this;
  }

  @override
  String get coinName {
    return name;
  }

  @override
  NonDerivableCoinConfig get conf {
    return switch (this) {
      NonDerivableCoins.filecoinBls => const NonDerivableCoinConfig(
        coinNames: CoinNames("Filecoin", "FIL"),
        type: CryptoKeyType.bls12G1,
        chainType: ChainType.mainnet,
        addressEncoder: _throwingEncoder,
      ),
      NonDerivableCoins.nearMlDsa65 => const NonDerivableCoinConfig(
        coinNames: CoinNames("Near Protocol", "NEAR"),
        type: CryptoKeyType.mldsa65,
        chainType: ChainType.mainnet,
        addressEncoder: _throwingEncoder,
      ),
    };
  }

  static String _throwingEncoder(
    EncodeAddressDefaultParams params,
    NonDerivableCoinConfig config,
  ) {
    throw BuError(
      DefaultErrorType.invalidAddress,
      "Non-derivable coins have no HD standard; import the key instead.",
    );
  }

  static NonDerivableCoins? fromName(String name) {
    return values.firstWhereNullable((element) => element.name == name);
  }

  @override
  CoinProposal get proposal => CoinProposal.nonDerivable;
}
