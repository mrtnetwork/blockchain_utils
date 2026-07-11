import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/serialization/identifier.dart';

enum BlockchainNetwork {
  aptos(BlockchainUtilsSerializationIdentifier.aptosNetwork),
  ethereum(BlockchainUtilsSerializationIdentifier.ethereumNetwork),
  cardano(BlockchainUtilsSerializationIdentifier.cardanoNetwork),
  solana(BlockchainUtilsSerializationIdentifier.solanaNetwork),
  sui(BlockchainUtilsSerializationIdentifier.suiNetwork),
  tron(BlockchainUtilsSerializationIdentifier.tronNetwork),
  bitcoinAndRelated(
    BlockchainUtilsSerializationIdentifier.bitcoinAndRelatedNetwork,
  ),
  ton(BlockchainUtilsSerializationIdentifier.tonNetwork),
  substrateAndRelated(
    BlockchainUtilsSerializationIdentifier.substrateAndRelatedNetworks,
  ),
  cosmosAndRelated(
    BlockchainUtilsSerializationIdentifier.cosmosAndRelatedNetworks,
  ),
  monero(BlockchainUtilsSerializationIdentifier.moneroNetwork),
  stellar(BlockchainUtilsSerializationIdentifier.stellarNetwork),
  xrpl(BlockchainUtilsSerializationIdentifier.xrplNetwork),
  zcash(BlockchainUtilsSerializationIdentifier.zcashNetwork);

  final BlockchainUtilsSerializationIdentifier identifier;
  const BlockchainNetwork(this.identifier);

  static BlockchainNetwork fromIdentifier(int? value) {
    return values.firstWhere(
      (e) => e.identifier.id == value,
      orElse: () => throw ItemNotFoundException(name: "BlockchainNetwork"),
    );
  }
}
