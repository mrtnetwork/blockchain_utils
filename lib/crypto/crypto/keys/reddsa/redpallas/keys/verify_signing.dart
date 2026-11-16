import 'package:blockchain_utils/api/api/api.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/crypto/crypto/keys/reddsa/redpallas/api/src/api.dart';
import 'package:blockchain_utils/crypto/crypto/group/group.dart';
import 'package:blockchain_utils/crypto/crypto/keys/reddsa/types/types.dart';
import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Parameters for a RedPallas sign operation.
class RedPallasSigningParams implements ISigningParams {
  final BuBytes message;
  final BuBytes? random;
  RedPallasSigningParams(List<int> message, {List<int>? random})
    : message = message.asImmutableBytes,
      random =
          random
              ?.exc(
                length: 80,
                operation: "RedPallasSigningParams",
                reason: "Invalid random bytes length.",
              )
              .asImmutableBytes;
}

/// Parameters for a RedPallas verify operation.
class RedPallasVerifyingParams implements IVerifiyingParams {
  final BuBytes message;
  final ReddsaSignature signature;
  RedPallasVerifyingParams(List<int> message, this.signature)
    : message = message.asImmutableBytes;
}

/// Common interface every RedPallas public key implements.
abstract class IRedPallasVerificationKey
    implements IVerifiyingKey<RedPallasVerifyingParams> {
  const IRedPallasVerificationKey();
  // PallasPoint get point;
  @override
  bool verify(RedPallasVerifyingParams verifyParams) {
    return blockchainUtils.api.signing.pallas.verify(
      pk: toBytes(),
      message: verifyParams.message,
      signature: verifyParams.signature,
      variant: switch (type) {
        CryptoKeyType.redPallasBinding => RedPallasVariant.binding,
        CryptoKeyType.redPallasSpend => RedPallasVariant.spendAuth,
        _ =>
          throw CoreErrors.cryptoFailed(
            "IRedPallasVerificationKey.verify",
            reason: "Unexpected key type.",
          ),
      },
    );
  }
}

/// Common interface every RedPallas private key implements.
abstract class IRedPallasSigningKey<P extends IRedPallasVerificationKey>
    implements ISigningKey<ReddsaSignature, RedPallasSigningParams, P> {
  VestaFq scalar();
  const IRedPallasSigningKey();

  @override
  ReddsaSignature sign(RedPallasSigningParams params) {
    return takeSecretKey().useValue(
      (k) => blockchainUtils.api.signing.pallas.sign(
        sk: k,
        message: params.message,
        rand80: params.random,
        variant: switch (type) {
          CryptoKeyType.redPallasBinding => RedPallasVariant.binding,
          CryptoKeyType.redPallasSpend => RedPallasVariant.spendAuth,
          _ =>
            throw CoreErrors.cryptoFailed(
              "IRedPallasSigningKey.sign",
              reason: "Unexpected key type.",
            ),
        },
      ),
    );
  }
}
