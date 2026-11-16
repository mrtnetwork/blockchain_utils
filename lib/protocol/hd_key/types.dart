import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';

abstract class HDKeyNetVar {}

abstract class IChildKey {}

abstract class IMasterKey {}

abstract class IChildKeyDerivator<
  CHILD extends IChildKey,
  PARENTKEY extends CryptoKeyBase?,
  DERIVATIONCONTXT extends CryptoKeyBase?,
  INDEX extends HdKeyIndex?
> {
  /// Checks if public key derivation is supported.
  bool isPublicDerivationSupported();
  CHILD deriveFromSecret({
    required PARENTKEY parent,
    required DERIVATIONCONTXT ctx,
    required INDEX index,
  });

  CHILD deriveFromPublic({
    required DERIVATIONCONTXT parent,
    required INDEX index,
  });
}

abstract class IMasterKeyKeyGenerator<MASTERKEY extends IMasterKey> {
  MASTERKEY generateFromSeed(List<int> seedBytes);
}

abstract class ChainCode with Equality {
  BuBytes toBytes();
}

abstract class HdKeyIndex with Equality {
  BuBytes toBytes();
}

abstract class KeyDepth with Equality {
  abstract final int depth;
  BuBytes toBytes();
}

abstract class KeyFingerPrint with Equality {
  BuBytes toBytes();
}

abstract class BaseCryptoKeyData<
  CHAINCODE extends ChainCode?,
  INDEX extends HdKeyIndex?,
  D extends KeyDepth?,
  FP extends KeyFingerPrint?
>
    with Equality {
  abstract final CHAINCODE chainCode;
  abstract final INDEX index;
  abstract final D depth;
  abstract final FP fingerPrint;
}

abstract class CryptoKeyBase<KEYDATA extends BaseCryptoKeyData> {
  final KEYDATA keyData;
  const CryptoKeyBase(this.keyData);
}

abstract class HDKeyManager<
  SK extends CryptoKeyBase,
  PK extends CryptoKeyBase,
  KEYINDEX extends HdKeyIndex,
  KEY extends HDKeyManager<SK, PK, KEYINDEX, KEY>
>
    with SecretState {
  abstract final PK publicKey;
  abstract final SK privateKey;

  /// Derives a child key at the given [index].
  KEY childKey(KEYINDEX index);

  /// Derives a key along a BIP32 path (e.g., "m/32'/0'/0'").
  KEY derivePath(String path);
}
