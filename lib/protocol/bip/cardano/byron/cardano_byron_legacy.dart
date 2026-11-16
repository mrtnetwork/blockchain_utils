import 'package:blockchain_utils/chain/address/neworks/ada/src/ada_byron_addr.dart';
import 'package:blockchain_utils/chain/address/neworks/ada/src/network.dart';
import 'package:blockchain_utils/protocol/bip/bip/bip32/base/bip32_base.dart';
import 'package:blockchain_utils/protocol/bip/bip/bip32/bip32_key_data.dart';
import 'package:blockchain_utils/protocol/bip/bip/bip32/bip32_keys.dart';
import 'package:blockchain_utils/protocol/bip/bip/bip32/bip32_path.dart';
import 'package:blockchain_utils/protocol/bip/cardano/bip32/cardano_byron_legacy_bip32.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';
import 'package:blockchain_utils/utils/string/string.dart';

/// A class that holds constants related to the Cardano Byron legacy key derivation process.
class CardanoByronLegacyConst {
  /// The salt used for PBKDF2 when deriving keys along the HD path.
  static const String hdPathKeyPbkdf2Salt = 'address-hashing';

  /// The number of rounds for PBKDF2 key derivation along the HD path.
  static const int hdPathKeyPbkdf2Rounds = 500;

  /// The length of the output bytes from PBKDF2 key derivation along the HD path.
  static const int hdPathKeyPbkdf2OutByteLen = 32;
}

/// A class that represents a Cardano Byron Legacy wallet.
class CardanoByronLegacy {
  final Bip32Base<dynamic> bip32;

  /// CardanoByronLegacy

  /// Constructor to create a Cardano Byron Legacy wallet from a seed.
  ///
  /// Initializes the wallet's hierarchical deterministic (HD) structure using the
  /// provided seed bytes.
  ///
  /// Parameters:
  /// - `seedBytes`: The seed bytes used for wallet initialization.
  CardanoByronLegacy.fromSeed(List<int> seedBytes)
    : bip32 = CardanoByronLegacyBip32.fromSeed(seedBytes);

  CardanoByronLegacy.fromBip32(this.bip32);

  /// Computes and returns the HD path key for Cardano Byron Legacy wallet.
  ///
  /// The HD path key is derived using the PBKDF2 key derivation function based on
  /// the wallet's public key (compressed), chain code, and specified parameters.
  ///
  /// Returns:
  /// - A `List<int>` containing the derived HD path key.
  BuBytes get hdPathKey {
    final hdPath = QuickCrypto.pbkdf2Sha512DeriveKey(
      password: [
        ...bip32.publicKey.toPublicKeyBytes(),
        ...bip32.chainCode.toBytes(),
      ],
      salt: StringUtils.encode(CardanoByronLegacyConst.hdPathKeyPbkdf2Salt),
      dklen: CardanoByronLegacyConst.hdPathKeyPbkdf2OutByteLen,
      iterations: CardanoByronLegacyConst.hdPathKeyPbkdf2Rounds,
    );
    return hdPath;
  }

  /// Decodes and retrieves the BIP32 HD path from a Cardano Byron Legacy address.
  ///
  /// This method takes a Cardano Byron Legacy address, decodes it, and decrypts
  /// the embedded HD path using the provided `hdPathKey`.
  ///
  /// Parameters:
  /// - `address`: The Cardano Byron Legacy address to decode and extract the HD path from.
  ///
  /// Returns:
  /// - A BIP32Path object representing the hierarchical deterministic (HD) path.
  Bip32Path hdPathFromAddress(String address) {
    final addrDecBytes = AdaByronAddrDecoder().decodeAddr(address);
    final hdPathDecBytes = AdaByronAddrDecoder.decryptHdPath(
      AdaByronAddrDecoder.splitDecodedBytes(addrDecBytes).$2,
      hdPathKey,
    );
    return hdPathDecBytes;
  }

  /// master private key
  Bip32PrivateKey get masterPrivateKey {
    return bip32.privateKey;
  }

  /// master public key
  Bip32PublicKey get masterPublicKey {
    return bip32.publicKey;
  }

  /// Derives and returns a BIP32 base key based on two key indices, 'firstIndex' and 'secondIndex'.
  Bip32Base<dynamic> deriveKey(
    Bip32KeyIndex firstIndex,
    Bip32KeyIndex secondIndex,
  ) {
    return _deriveKey(firstIndex, secondIndex);
  }

  /// Retrieves and returns the public key associated with the specified key indices.
  ///
  /// Parameters:
  /// - 'firstIndex': The first key index for key derivation.
  /// - 'secondIndex': The second key index for key derivation.
  Bip32PublicKey getPublicKey({
    required Bip32KeyIndex firstIndex,
    required Bip32KeyIndex secondIndex,
  }) {
    final derive = deriveKey(firstIndex, secondIndex);
    return derive.publicKey;
  }

  /// Retrieves and returns the private key associated with the specified key indices.
  ///
  /// Parameters:
  /// - 'firstIndex': The first key index for key derivation.
  /// - 'secondIndex': The second key index for key derivation.
  Bip32PrivateKey getPrivateKey({
    required Bip32KeyIndex firstIndex,
    required Bip32KeyIndex secondIndex,
  }) {
    final derive = deriveKey(firstIndex, secondIndex);
    return derive.privateKey;
  }

  /// Computes and returns a Cardano Byron Legacy address based on two key indices, 'firstIndex' and 'secondIndex'.
  ///
  /// Parameters:
  /// - 'firstIndex': The first key index for address derivation.
  /// - 'secondIndex': The second key index for address derivation.
  String getAddress(
    Bip32KeyIndex firstIndex,
    Bip32KeyIndex secondIndex, {
    ADANetwork network = ADANetwork.mainnet,
  }) {
    final pubKey = getPublicKey(
      firstIndex: firstIndex,
      secondIndex: secondIndex,
    );
    final hdPath = _getDerivationPath(firstIndex, secondIndex);
    return AdaByronLegacyAddrEncoder().encodeKey(
      pubKey.key.toBytes(),
      chainCode: pubKey.keyData.chainCode.toBytes(),
      path: hdPath,
      hdPathKey: hdPathKey,
      network: network,
    );
  }

  /// Derives and returns a BIP32 base key based on two key indices, 'firstIndex' and 'secondIndex'.
  ///
  /// Parameters:
  /// - 'firstIndex': The first key index for key derivation.
  /// - 'secondIndex': The second key index for key derivation.
  Bip32Base<dynamic> _deriveKey(
    Bip32KeyIndex firstIndex,
    Bip32KeyIndex secondIndex,
  ) {
    return bip32.derivePath(_getDerivationPath(firstIndex, secondIndex));
  }

  /// Generates the hierarchical derivation path based on two key indices.
  ///
  /// Parameters:
  /// - 'firstIndex': The first key index.
  /// - 'secondIndex': The second key index.
  String _getDerivationPath(
    Bip32KeyIndex firstIndex,
    Bip32KeyIndex secondIndex,
  ) {
    return 'm/${firstIndex.toInt()}\'/${secondIndex.toInt()}\'';
  }
}
