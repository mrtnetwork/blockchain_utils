import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

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
  nearNetwork(11015),
  algorandNetwork(11016),
  hederaNetwork(11017),
  icpNetwork(11018),
  filecoinNetwork(11019),
  tezosNetwork(11020),

  argumentException(11101),
  stateException(11102),
  itemNotFound(11103),
  casting(11104),
  rpcError(11105),
  base58Error(11106),
  base58ChecksumError(11137),

  bech32Error(11107),
  addressConverterError(11108),
  bip32KeyError(11109),
  bip32PathError(11110),
  bip44Error(11111),
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
  ss58FormatError(11141),
  utf8Error(11126),
  base64Error(11127),
  cborSerializationError(11128),
  amountConverterError(11129),
  jsonParserError(11130),
  mnemonic(11131),
  pedersenHashError(11132),
  integerError(11133),
  base32Error(11134),
  uuidError(11135),
  hexError(11136),
  bytesError(11138),
  secretBytesError(11139),
  jsonError(11140),
  customServiceParams(11142);

  @override
  final int id;
  const BlockchainUtilsSerializationIdentifier(this.id);

  static BlockchainUtilsSerializationIdentifier fromIdentifier(int? value) {
    return values.firstWhere(
      (e) => e.id == value,
      orElse:
          () =>
              throw BuError(
                DefaultErrorType.notFound,
                "No matching BlockchainUtilsSerializationIdentifier found for the given value. null",
              ),
    );
  }

  @override
  bool isValid(int? tag) {
    return tag == id;
  }
}
