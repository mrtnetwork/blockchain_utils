import 'package:blockchain_utils/cbor/serialization/cbor/tag.dart';
import 'package:blockchain_utils/exception/exception/blockchain_utils.dart';

/// 12000
enum BlockchainUtilsSerializationIdentifier implements SerializationIdentifier {
  aptosNetwork(11001),
  ethereumNetwork(11002),
  cardanoNetwork(11003),
  solanaNetwork(11004),
  suiNetwork(11005),
  tronNetwork(11006),
  bitcoinAndRelatedNetwork(11007),
  tonNetwork(11008),
  substrateAndRelatedNetworks(11009),
  cosmosAndRelatedNetworks(11010),
  moneroNetwork(11011),
  stellarNetwork(11012),
  xrplNetwork(11013),
  zcashNetwork(11014),

  argumentException(11101),
  stateException(11102),
  itemNotFound(11103),
  casting(11104),
  rpcError(11105),
  base58Error(11106),

  bech32Error(11107),
  addressConverterError(11108),
  bip32KeyError(11109),
  bip32PathError(11110),
  bip44DepthError(11111),
  zip32Error(11112),
  electrumError(11113),
  mnemonicError(11114),
  moneroKeyError(11115),
  substrateKeyError(11116),
  substratePathError(11117),
  zcashError(11118),
  zcashKeyEncodingError(11119),
  cborError(11120),
  cryptoError(11121),
  layoutExceptionError(11122),
  protoError(11123),
  secretStorageError(11124),
  ss58Error(11125),
  utf8Error(11126),
  base64Error(11127),
  cborSerializationError(11128),
  amountConverterError(11129),
  jsonParserError(11130),
  mnemonic(11131),
  pedersenHashError(11132),
  integerError(11133);

  @override
  final int id;
  const BlockchainUtilsSerializationIdentifier(this.id);

  static BlockchainUtilsSerializationIdentifier fromIdentifier(int? value) {
    return values.firstWhere(
      (e) => e.id == value,
      orElse:
          () =>
              throw ItemNotFoundException(
                name: "BlockchainUtilsSerializationIdentifier",
              ),
    );
  }

  @override
  bool isValid(int? tag) {
    return tag == id;
  }
}
