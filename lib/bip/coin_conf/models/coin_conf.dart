import 'coins_name.dart';

/// A class representing the configuration of a specific cryptocurrency coin.
class CoinConf {
  final CoinNames coinName;

  final CoinParams params;

  /// Constructor to create a CoinConf instance.
  ///
  /// Parameters:
  /// - `coinName`: An enum representing the name of the cryptocurrency coin.
  /// - `params`: A map containing various parameters specific to the coin.
  const CoinConf({required this.coinName, required this.params});

  /// Retrieves and returns the name of the cryptocurrency coin.
  String get name => coinName.name;

  // /// Retrieves and returns a specific parameter of the coin configuration.
  // ///
  // /// Parameters:
  // /// - `name`: The name of the parameter to retrieve.
  // T? getParam<T>(String name) => params[name];

  @override
  String toString() {
    return name;
  }
}

/// The [CoinParams] class defines parameters for a specific cryptocurrency coin.
class CoinParams {
  const CoinParams({
    // Network versions for Pay-to-Public-Key-Hash (P2PKH) addresses
    this.p2pkhNetVer,
    // Network versions for Pay-to-Script-Hash (P2SH) addresses
    this.p2shNetVer,
    // Human-Readable Part (HRP) for Pay-to-Witness-Public-Key-Hash (P2WPKH) addresses
    this.p2wpkhHrp,
    // Witness version for Pay-to-Witness-Public-Key-Hash (P2WPKH) addresses
    this.p2wpkhWitVer,
    // Human-Readable Part (HRP) for Pay-to-Taproot (P2TR) addresses
    this.p2trHrp,
    // Witness version for Pay-to-Taproot (P2TR) addresses
    this.p2trWitVer,
    // Network versions for Wallet Import Format (WIF)
    this.wifNetVer,
    // SS58 format for addresses
    this.addrSs58Format,
    // Human-Readable Part (HRP) for custom addresses
    this.addrHrp,
    // Prefix for custom addresses
    this.addrPrefix,
    // Standard HRP for Pay-to-Public-Key-Hash (P2PKH) addresses
    this.p2pkhStdHrp,
    // Network versions for standard Pay-to-Public-Key-Hash (P2PKH) addresses
    this.p2pkhStdNetVer,
    // Legacy network versions for Pay-to-Public-Key-Hash (P2PKH) addresses
    this.p2pkhLegacyNetVer,
    // Standard HRP for Pay-to-Script-Hash (P2SH) addresses
    this.p2shStdHrp,
    // Network versions for standard Pay-to-Script-Hash (P2SH) addresses
    this.p2shStdNetVer,
    // Legacy network versions for Pay-to-Script-Hash (P2SH) addresses
    this.p2shLegacyNetVer,
    // HRP for staking addresses
    this.stakingAddrHrp,
    // Network versions for deprecated Pay-to-Public-Key-Hash (P2PKH) addresses
    this.p2pkhDeprNetVer,
    // Network versions for deprecated Pay-to-Script-Hash (P2SH) addresses
    this.p2shDeprNetVer,

    // Network versions for various address formats
    this.addrNetVer,
    this.addrIntNetVer,
    this.subaddrNetVer,

    // Address versions
    this.addrVer,
    this.workchain,
  });

  // Network versions for Pay-to-Public-Key-Hash (P2PKH) addresses
  final List<int>? p2pkhNetVer;
  // Network versions for Pay-to-Script-Hash (P2SH) addresses
  final List<int>? p2shNetVer;
  // Human-Readable Part (HRP) for Pay-to-Witness-Public-Key-Hash (P2WPKH) addresses
  final String? p2wpkhHrp;
  // Witness version for Pay-to-Witness-Public-Key-Hash (P2WPKH) addresses
  final int? p2wpkhWitVer;
  // Human-Readable Part (HRP) for Pay-to-Taproot (P2TR) addresses
  final String? p2trHrp;
  // Witness version for Pay-to-Taproot (P2TR) addresses
  final int? p2trWitVer;
  // Network versions for Wallet Import Format (WIF)
  final List<int>? wifNetVer;
  // SS58 format for addresses
  final int? addrSs58Format;
  // Human-Readable Part (HRP) for custom addresses
  final String? addrHrp;
  // Prefix for custom addresses
  final String? addrPrefix;
  // Standard HRP for Pay-to-Public-Key-Hash (P2PKH) addresses
  final String? p2pkhStdHrp;
  // Network versions for standard Pay-to-Public-Key-Hash (P2PKH) addresses
  final List<int>? p2pkhStdNetVer;
  // Legacy network versions for Pay-to-Public-Key-Hash (P2PKH) addresses
  final List<int>? p2pkhLegacyNetVer;
  // Standard HRP for Pay-to-Script-Hash (P2SH) addresses
  final String? p2shStdHrp;
  // Network versions for standard Pay-to-Script-Hash (P2SH) addresses
  final List<int>? p2shStdNetVer;
  // Legacy network versions for Pay-to-Script-Hash (P2SH) addresses
  final List<int>? p2shLegacyNetVer;
  // HRP for staking addresses
  final String? stakingAddrHrp;
  // Network versions for deprecated Pay-to-Public-Key-Hash (P2PKH) addresses
  final List<int>? p2pkhDeprNetVer;
  // Network versions for deprecated Pay-to-Script-Hash (P2SH) addresses
  final List<int>? p2shDeprNetVer;

  // Network versions for various address formats
  final List<int>? addrNetVer;
  final List<int>? addrIntNetVer;
  final List<int>? subaddrNetVer;

  // Address versions
  final List<int>? addrVer;
  // Ton workchain ID
  final int? workchain;
}
