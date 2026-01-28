import 'package:blockchain_utils/bip/bip/bip32/base/derivator.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_key_data.dart';
import 'package:blockchain_utils/bip/bip/bip44/base/bip44_base.dart';
import 'package:blockchain_utils/bip/bip/hd_key/types.dart';
import 'package:blockchain_utils/bip/bip/zip32/base/context.dart';
import 'package:blockchain_utils/bip/bip/zip32/zip32/types.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';

abstract class IZip32ChildKeyDerivator<
  PARENTKEY extends CryptoKeyBase?,
  DERIVATIONCONTXT extends CryptoKeyBase?
>
    implements
        IChildKeyDerivator<
          Bip32ChildKey,
          PARENTKEY,
          DERIVATIONCONTXT,
          Bip32KeyIndex
        > {}

abstract class IZip32MasterKeyGenerator
    extends IMasterKeyKeyGenerator<Bip32MasterKey> {}

abstract class IZip32CryptoKey<KEYDATA extends BaseCryptoKeyData>
    extends CryptoKeyBase<KEYDATA> {
  IZip32CryptoKey(super.keyData);
}

abstract class Zip32ExtendedSpendKey<KEYDATA extends BaseCryptoKeyData>
    extends IZip32CryptoKey<KEYDATA>
    with Equality {
  Zip32ExtendedSpendKey(super.keyData);

  List<int> spendKeyBytes();
}

abstract class Zip32ExtendedFullViewKey<
  IVK extends IncomingViewingKey,
  KEYDATA extends BaseCryptoKeyData
>
    extends IZip32CryptoKey<KEYDATA>
    with Equality {
  Zip32ExtendedFullViewKey(super.keyData);
  IVK incomingViewingKey(
    ZCryptoContext context, {
    Bip44Changes scope = Bip44Changes.chainInt,
  });
}

abstract class Zip32Base<
  SK extends Zip32ExtendedSpendKey,
  PK extends Zip32ExtendedFullViewKey,
  KEYINDEX extends HdKeyIndex,
  KEYDRIVATOR extends IChildKeyDerivator,
  MASTERKEYGENERATOR extends IMasterKeyKeyGenerator,
  KEY extends HDKeyManager<SK, PK, KEYINDEX, KEY>
>
    implements HDKeyManager<SK, PK, KEYINDEX, KEY> {
  const Zip32Base();
  Bip32Depth get depth;
  Bip32ChainCode get chainCode;
  Bip32FingerPrint get fingerPrint;

  /// Gets the key derivator for this key.
  KEYDRIVATOR get keyDerivator;

  /// Gets the master key generator for this key.
  MASTERKEYGENERATOR get masterKeyGenerator;

  KEY childKey(KEYINDEX index, ZCryptoContext context);
  KEY derivePath(String path, ZCryptoContext context);
}

class Zip32HrpNetVar implements HDKeyNetVar {
  final String extendedSpendingKey;
  final String extendedFullViewingKey;
  const Zip32HrpNetVar({
    required this.extendedFullViewingKey,
    required this.extendedSpendingKey,
  });
}
