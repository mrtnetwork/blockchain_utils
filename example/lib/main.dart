// ignore_for_file: unused_local_variable

import 'package:blockchain_utils/blockchain_utils.dart';

void main() {
  const String passphrase = 'MRTNETWORK';
  final mnemonic = Bip39MnemonicGenerator(Bip39Languages.japanese)
      .fromWordsNumber(Bip39WordsNum.wordsNum24);
  final seed = Bip39SeedGenerator(mnemonic).generate(passphrase);
  final ethereumWallet = Bip44.fromSeed(seed, Bip44Coins.ethereum);
  final defaultEthereumWallet = ethereumWallet.deriveDefaultPath;
  final ethereumaddress = defaultEthereumWallet.publicKey.toAddress;

  final tronmWallet = Bip44.fromSeed(seed, Bip44Coins.tron);
  final defaultTronWallet = ethereumWallet.deriveDefaultPath;
  final tronaddress = defaultEthereumWallet.publicKey.toAddress;

  Bip49.fromSeed(seed, Bip49Coins.litecoin);
  Bip84.fromSeed(seed, Bip84Coins.bitcoin);
  Bip86.fromSeed(seed, Bip86Coins.bitcoin);

  final bitconWallet = Bip44.fromSeed(seed, Bip44Coins.tron);
  final defaultBitcoinWallet = ethereumWallet.deriveDefaultPath;
  final bitconP2pkh = defaultEthereumWallet.publicKey.toAddress;

  final cardano = CardanoIcarusSeedGenerator(mnemonic.toStr());

  final substrate = Substrate.fromSeed(
      List<int>.filled(32, 1), SubstrateCoins.polkadotSr25519);
  final substrateAddress = substrate.publicKey.toAddress;

  final moneromnemonic =
      MoneroMnemonicGenerator().fromWordsNumber(MoneroWordsNum.wordsNum25);
  final moneroSeed = MoneroSeedGenerator(moneromnemonic).generate();
  final monero = MoneroAccount.fromSeed(moneroSeed);
  final moneroAddress = monero.primaryAddress;
  final subAddress = monero.subaddress(1, majorIndex: 0);

  final slip10Ed = Bip32Slip10Ed25519.fromSeed(List<int>.filled(32, 1));
  final edWallet = slip10Ed.derivePath("44'/0'/0'");
  final slipScp = Bip32Slip10Secp256k1.fromSeed(List<int>.filled(32, 1));
  final ecWallet = slipScp.derivePath("44'/0'/0'/1/2");
}
