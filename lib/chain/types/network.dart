import 'package:blockchain_utils/serialization/identifier.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Blockchain networks supported for address encoding/decoding.
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
  zcash(BlockchainUtilsSerializationIdentifier.zcashNetwork),
  near(BlockchainUtilsSerializationIdentifier.nearNetwork),
  algorand(BlockchainUtilsSerializationIdentifier.algorandNetwork),
  hedera(BlockchainUtilsSerializationIdentifier.hederaNetwork),
  icp(BlockchainUtilsSerializationIdentifier.icpNetwork),
  filecoin(BlockchainUtilsSerializationIdentifier.filecoinNetwork),
  tezos(BlockchainUtilsSerializationIdentifier.tezosNetwork);

  final BlockchainUtilsSerializationIdentifier identifier;
  const BlockchainNetwork(this.identifier);

  /// Looks up the network matching a serialized identifier id.
  static BlockchainNetwork fromIdentifier(int? value) {
    return values.firstWhere(
      (e) => e.identifier.id == value,
      orElse: () => throw BuError(DefaultErrorType.notFound, "No matching BlockchainNetwork found for the given value. null"),
    );
  }
}
