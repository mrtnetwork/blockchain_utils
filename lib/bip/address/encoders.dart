/// A address_encoder liberary for encoding blockchain addresses from public keys.
library address_encoder;

/// Export statements for Ada Byron address encoders.
export 'ada/ada_byron_addr.dart'
    show AdaByronIcarusAddrEncoder, AdaByronLegacyAddrEncoder;

/// Export statements for Ada Shelley address encoders.
export 'ada/ada.dart'
    show
        AdaShelleyAddrEncoder,
        AdaShelleyStakingAddrEncoder,
        AdaPointerAddrEncoder,
        AdaShelleyEnterpriseAddrEncoder,
        AdaStakeCredType,
        AdaStakeCredential,
        Pointer,
        ADAAddressType,
        ADANetwork,
        ADAByronAddrTypes;
export 'ada/network.dart';

/// Export statement for Algorand address encoder.
export 'algo_addr.dart' show AlgoAddrEncoder;

/// Export statement for Aptos address encoder.
export 'aptos_addr.dart' show AptosAddrEncoder;

/// Export statement for Atom address encoder.
export 'atom_addr.dart' show AtomAddrEncoder;

/// Export statements for Avalanche (AVAX) address encoders.
export 'avax_addr.dart' show AvaxXChainAddrEncoder, AvaxPChainAddrEncoder;

/// Export statement for Bitcoin Cash address converter.
export 'bch_addr_converter.dart' show BchAddrConverter;

/// Export statement for Elrond (EGLD) address encoder.
export 'egld_addr.dart' show EgldAddrEncoder;

/// Export statement for EOS address encoder.
export 'eos_addr.dart' show EosAddrEncoder;

/// Export statement for Ergo address encoder.
export 'ergo.dart' show ErgoP2PKHAddrEncoder;

/// Export statement for Ethereum address encoder.
export 'eth_addr.dart' show EthAddrEncoder;

/// Export statement for Filecoin (FIL) address encoder.
export 'fil_addr.dart' show FilSecp256k1AddrEncoder;

/// Export statement for ICON (ICX) address encoder.
export 'icx_addr.dart' show IcxAddrEncoder;

/// Export statement for Injective Protocol (INJ) address encoder.
export 'inj_addr.dart' show InjAddrEncoder;

/// Export statement for Nano address encoder.
export 'nano_addr.dart' show NanoAddrEncoder;

/// Export statement for NEAR Protocol address encoder.
export 'near_addr.dart' show NearAddrEncoder;

/// Export statement for Neo address encoder.
export 'neo_addr.dart' show NeoAddrEncoder;

/// Export statement for OKEx address encoder.
export 'okex_addr.dart' show OkexAddrEncoder;

/// Export statement for Harmony (ONE) address encoder.
export 'one_addr.dart' show OneAddrEncoder;

/// Export statements for Bitcoin and Bitcoin Cash P2PKH address encoders.
export 'p2pkh_addr.dart' show BchP2PKHAddrEncoder, P2PKHAddrEncoder;

/// Export statements for Bitcoin and Bitcoin Cash P2SH address encoders.
export 'p2sh_addr.dart' show BchP2SHAddrEncoder, P2SHAddrEncoder;

/// Export statement for Taproot (P2TR) address encoder.
export 'p2tr_addr.dart' show P2TRAddrEncoder, P2TRUtils;

/// Export statement for Segregated Witness (P2WPKH) address encoder.
export 'p2wpkh_addr.dart' show P2WPKHAddrEncoder;

/// Export statement for Solana (SOL) address encoder.
export 'sol_addr.dart' show SolAddrEncoder;

/// Export statements for Substrate address encoders (Sr25519 and Ed25519).
export 'substrate_addr.dart'
    show SubstrateSr25519AddrEncoder, SubstrateEd25519AddrEncoder;

/// Export statement for TRON (TRX) address encoder.
export 'trx_addr.dart' show TrxAddrEncoder;

/// Export statement for Stellar (XLM) address encoder.
export 'xlm_addr.dart' show XlmAddrEncoder;

/// Export statements for Monero (XMR) address encoders.
export 'xmr_addr.dart' show XmrAddrEncoder, XmrIntegratedAddrEncoder;

/// Export statement for Ripple (XRP) address encoder.
export 'xrp_addr.dart' show XrpAddrEncoder, XrpXAddrEncoder, XRPAddressUtils;

/// Export statement for Tezos (XTZ) address encoder.
export 'xtz_addr.dart' show XtzAddrEncoder;

/// Export statement for Zilliqa (ZIL) address encoder.
export 'zil_addr.dart' show ZilAddrEncoder;
