import 'dart:typed_data';
import 'package:blockchain_utils/formating/bytes_num_formating.dart';
part 'currencies.dart';

/// Currecy Symbols
enum CurrencySymbol {
  anon,
  agm,
  xax,
  aya,
  ac,
  atom,
  aur,
  axe,
  bta,
  beet,
  bela,
  btdx,
  bsd,
  bch,
  btg,
  btc,
  xbc,
  bsv,
  btctest,
  btcz,
  btx,
  blk,
  bst,
  bnd,
  bndtest,
  boli,
  brit,
  cpu,
  cdn,
  ccn,
  clam,
  club,
  cmp,
  crp,
  crave,
  dash,
  dashtest,
  onion,
  dfc,
  dnr,
  dmd,
  dgb,
  dgc,
  doge,
  dogetest,
  edrc,
  ecn,
  emc2,
  ela,
  nrg,
  eth,
  erc,
  excl,
  fix,
  fixtest,
  ftc,
  frst,
  flash,
  flux,
  fjc,
  gcr,
  game,
  gbx,
  grc,
  grs,
  grstest,
  nlg,
  hnc,
  thc,
  hush,
  ixc,
  insn,
  iop,
  jbs,
  kobo,
  kmd,
  lbc,
  linx,
  lcc,
  ltc,
  ltctest,
  ltz,
  lkr,
  lynx,
  mzc,
  mec,
  mnx,
  mona,
  monk,
  xmy,
  nix,
  nmc,
  nav,
  nebl,
  neos,
  nro,
  nyc,
  nvc,
  nbt,
  nsr,
  ok,
  omni,
  omnitest,
  onx,
  ppc,
  psb,
  phr,
  pink,
  pivx,
  pivxtest,
  posw,
  pot,
  prj,
  put,
  qtum,
  qtumtest,
  rbtc,
  rbtctest,
  rpd,
  rvn,
  rdd,
  rby,
  safe,
  sls,
  scribe,
  sdc,
  sdctest,
  slm,
  slmtest,
  smly,
  slr,
  stash,
  strat,
  strattest,
  sugar,
  sugartest,
  sys,
  toa,
  tht,
  trx,
  twins,
  twinstest,
  usc,
  uno,
  vash,
  vc,
  xvg,
  vtc,
  via,
  viatest,
  vivo,
  xwc,
  wc,
  xuez,
  xdc,
  yec,
  zcl,
  zec,
  zectest,
  zen;

  factory CurrencySymbol.fromName(String name) {
    final lower = name.toLowerCase();
    return values.firstWhere((element) => element.name == lower);
  }
}

/// Represents a Segwit address with Human-Readable Part (HRP) and version.
class SegwitAddress {
  final String? hrp;
  final int version;

  SegwitAddress({this.hrp, this.version = 0x00});

  /// Creates a SegwitAddress instance from a JSON map.
  factory SegwitAddress.fromJson(Map<String, dynamic> json) {
    return SegwitAddress(
      hrp: json['HRP'],
      version: json['VERSION'] ?? 0x00,
    );
  }

  /// Converts the SegwitAddress instance to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'HRP': hrp,
      'VERSION': version,
    };
  }
}

/// Represents a CoinType with an index and a flag indicating if it's hardened.
class CoinType {
  final int index;
  final bool hardened;

  CoinType(this.index, this.hardened);

  /// Creates a CoinType instance from a JSON map.
  factory CoinType.fromJson(Map<String, dynamic> json) {
    return CoinType(
      json['INDEX'],
      json['HARDENED'],
    );
  }

  @override
  String toString() {
    return hardened ? "$index'" : index.toString();
  }

  /// Converts the CoinType instance to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'INDEX': index,
      'HARDENED': hardened,
    };
  }
}

/// Enum representing different Extended Key Types.
enum ExtendedKeyType {
  p2pkh,
  p2sh,
  p2wpkh,
  p2wpkhInP2sh,
  p2wsh,
  p2wshInP2sh;

  factory ExtendedKeyType.fromName(String name) {
    final lower = name.toLowerCase();
    return values.firstWhere((element) => element.name == lower);
  }
}

/// Creates an ExtendedKeyType enum value from its name.
class ExtendedKey {
  final int p2pkh;
  final int p2sh;
  final int? p2wpkh;
  final int? p2wpkhInP2sh;
  final int? p2wsh;
  final int? p2wshInP2sh;

  /// Returns an extended key value for the specified key type.
  String? getExtended(ExtendedKeyType type) {
    switch (type) {
      case ExtendedKeyType.p2pkh:
        return p2pkh.toRadixString(16).padLeft(8, '0');
      case ExtendedKeyType.p2sh:
        return p2sh.toRadixString(16).padLeft(8, '0');
      case ExtendedKeyType.p2wpkh:
        return p2wpkh?.toRadixString(16).padLeft(8, '0');
      case ExtendedKeyType.p2wpkhInP2sh:
        return p2wpkhInP2sh?.toRadixString(16).padLeft(8, '0');
      case ExtendedKeyType.p2wsh:
        return p2wsh?.toRadixString(16).padLeft(8, '0');
      default:
        return p2wshInP2sh?.toRadixString(16).padLeft(8, '0');
    }
  }

  /// Returns the ExtendedKeyType for the given bytes.
  ExtendedKeyType? getExtendedType(Uint8List bytes) {
    final toHex = bytesToHex(bytes);
    final toInt = int.parse(toHex, radix: 16);
    if (toInt == p2pkh) {
      return ExtendedKeyType.p2pkh;
    } else if (toInt == p2sh) {
      return ExtendedKeyType.p2sh;
    } else if (toInt == p2wpkh) {
      return ExtendedKeyType.p2wpkh;
    } else if (toInt == p2wpkhInP2sh) {
      return ExtendedKeyType.p2wpkhInP2sh;
    } else if (toInt == p2wsh) {
      return ExtendedKeyType.p2wsh;
    } else if (toInt == p2wshInP2sh) {
      return ExtendedKeyType.p2wshInP2sh;
    }
    return null;
  }

  ExtendedKey({
    required this.p2pkh,
    required this.p2sh,
    this.p2wpkh,
    this.p2wpkhInP2sh,
    this.p2wsh,
    this.p2wshInP2sh,
  });

  /// Creates an ExtendedKey instance from a JSON map.
  factory ExtendedKey.fromJson(Map<String, dynamic> json) {
    return ExtendedKey(
      p2pkh: json['P2PKH'],
      p2sh: json['P2SH'],
      p2wpkh: json['P2WPKH'],
      p2wpkhInP2sh: json['P2WPKH_IN_P2SH'],
      p2wsh: json['P2WSH'],
      p2wshInP2sh: json['P2WSH_IN_P2SH'],
    );
  }

  /// Converts the ExtendedKey instance to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'P2PKH': p2pkh,
      'P2SH': p2sh,
      'P2WPKH': p2wpkh,
      'P2WPKH_IN_P2SH': p2wpkhInP2sh,
      'P2WSH': p2wsh,
      'P2WSH_IN_P2SH': p2wshInP2sh,
    };
  }
}

/// Represents an Extended Private Key that extends ExtendedKey.
class ExtendedPrivateKey extends ExtendedKey {
  ExtendedPrivateKey({
    required int p2pkh,
    required int p2sh,
    int? p2wpkh,
    int? p2wpkhInP2sh,
    int? p2wsh,
    int? p2wshInP2sh,
  }) : super(
          p2pkh: p2pkh,
          p2sh: p2sh,
          p2wpkh: p2wpkh,
          p2wpkhInP2sh: p2wpkhInP2sh,
          p2wsh: p2wsh,
          p2wshInP2sh: p2wshInP2sh,
        );

  /// Creates an ExtendedPrivateKey instance from a JSON map.
  factory ExtendedPrivateKey.fromJson(Map<String, dynamic> json) {
    return ExtendedPrivateKey(
      p2pkh: json['P2PKH'],
      p2sh: json['P2SH'],
      p2wpkh: json['P2WPKH'],
      p2wpkhInP2sh: json['P2WPKH_IN_P2SH'],
      p2wsh: json['P2WSH'],
      p2wshInP2sh: json['P2WSH_IN_P2SH'],
    );
  }
}

/// Represents an Extended Public Key that extends ExtendedKey.
class ExtendedPublicKey extends ExtendedKey {
  ExtendedPublicKey({
    required int p2pkh,
    required int p2sh,
    int? p2wpkh,
    int? p2wpkhInP2sh,
    int? p2wsh,
    int? p2wshInP2sh,
  }) : super(
          p2pkh: p2pkh,
          p2sh: p2sh,
          p2wpkh: p2wpkh,
          p2wpkhInP2sh: p2wpkhInP2sh,
          p2wsh: p2wsh,
          p2wshInP2sh: p2wshInP2sh,
        );

  /// Creates an ExtendedPublicKey instance from a JSON map.
  factory ExtendedPublicKey.fromJson(Map<String, dynamic> json) {
    return ExtendedPublicKey(
      p2pkh: json['P2PKH'],
      p2sh: json['P2SH'],
      p2wpkh: json['P2WPKH'],
      p2wpkhInP2sh: json['P2WPKH_IN_P2SH'],
      p2wsh: json['P2WSH'],
      p2wshInP2sh: json['P2WSH_IN_P2SH'],
    );
  }
}

/// Represents a Cryptocurrency with various attributes and settings.
class Cryptocurrency {
  final String name;
  final CurrencySymbol symbol;
  final String network;
  final String? sourceCode;
  final CoinType coinType;
  final int scriptAddress;
  final int publicKeyAddress;
  final SegwitAddress segwitAddress;
  final ExtendedPrivateKey extendedPrivateKey;
  final ExtendedPublicKey extendedPublicKey;
  final String? messagePrefix;
  final String defaultPath;
  final int wifSecretKey;

  Cryptocurrency({
    required this.name,
    required this.symbol,
    required this.network,
    this.sourceCode,
    required this.coinType,
    required this.scriptAddress,
    required this.publicKeyAddress,
    required this.segwitAddress,
    required this.extendedPrivateKey,
    required this.extendedPublicKey,
    this.messagePrefix,
    required this.defaultPath,
    required this.wifSecretKey,
  });

  /// Creates a Cryptocurrency instance from a given CurrencySymbol.
  factory Cryptocurrency.fromSymbol(CurrencySymbol network) {
    final Map<String, dynamic> data =
        currenciesData[network.name.toUpperCase()];
    return Cryptocurrency.fromJson(data);
  }

  /// Creates a Cryptocurrency instance from a JSON map.
  factory Cryptocurrency.fromJson(Map<String, dynamic> json) {
    return Cryptocurrency(
      name: json['NAME'],
      symbol: CurrencySymbol.fromName(json['SYMBOL']),
      network: json['NETWORK'],
      sourceCode: json['SOURCE_CODE'],
      coinType: CoinType.fromJson(json['COIN_TYPE']),
      scriptAddress: json['SCRIPT_ADDRESS'],
      publicKeyAddress: json['PUBLIC_KEY_ADDRESS'],
      segwitAddress: SegwitAddress.fromJson(json['SEGWIT_ADDRESS']),
      extendedPrivateKey:
          ExtendedPrivateKey.fromJson(json['EXTENDED_PRIVATE_KEY']),
      extendedPublicKey:
          ExtendedPublicKey.fromJson(json['EXTENDED_PUBLIC_KEY']),
      messagePrefix: json['MESSAGE_PREFIX'],
      defaultPath: json['DEFAULT_PATH'],
      wifSecretKey: json['WIF_SECRET_KEY'],
    );
  }

  /// Converts the Cryptocurrency instance to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'NAME': name,
      'SYMBOL': symbol.name.toUpperCase(),
      'NETWORK': network,
      'SOURCE_CODE': sourceCode,
      'COIN_TYPE': coinType.toJson(),
      'SCRIPT_ADDRESS': scriptAddress,
      'PUBLIC_KEY_ADDRESS': publicKeyAddress,
      'SEGWIT_ADDRESS': segwitAddress.toJson(),
      'EXTENDED_PRIVATE_KEY': extendedPrivateKey.toJson(),
      'EXTENDED_PUBLIC_KEY': extendedPublicKey.toJson(),
      'MESSAGE_PREFIX': messagePrefix,
      'DEFAULT_PATH': defaultPath,
      'WIF_SECRET_KEY': wifSecretKey,
    };
  }
}
