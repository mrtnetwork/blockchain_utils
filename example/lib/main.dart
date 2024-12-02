import 'package:blockchain_utils/blockchain_utils.dart';

void main() {
  final bip = Bip44.fromSeed(List<int>.filled(32, 12), Bip44Coins.binanceChain);
  final defaultPath = bip.deriveDefaultPath;
  // ignore: unused_local_variable
  final p2pkhAddress = defaultPath.publicKey.toAddress;
}
