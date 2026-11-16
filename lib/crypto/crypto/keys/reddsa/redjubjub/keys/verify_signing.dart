import 'package:blockchain_utils/api/api/api.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/crypto/crypto/keys/reddsa/redjubjub/api/src/api.dart';
import 'package:blockchain_utils/crypto/crypto/keys/reddsa/types/types.dart';
import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/crypto/crypto/group/jubjub/fields/field.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Parameters for a RedJubjub sign operation.
class RedJubJubSigningParams implements ISigningParams {
  final BuBytes message;
  final BuBytes? random;
  RedJubJubSigningParams(List<int> message, {List<int>? random})
    : message = message.asImmutableBytes,
      random =
          random
              ?.exc(
                length: 80,
                operation: "RedJubJubSigningParams",
                reason: "Invalid random bytes length.",
              )
              .asImmutableBytes;
}

/// Parameters for a RedJubjub verify operation.
class RedJubJubVerifyingParams implements IVerifiyingParams {
  final BuBytes message;
  final ReddsaSignature signature;
  RedJubJubVerifyingParams(List<int> message, this.signature)
    : message = message.asImmutableBytes;
}

/// Common interface every RedJubjub public key implements.
abstract class IRedJubJubVerificationKey
    implements IVerifiyingKey<RedJubJubVerifyingParams> {
  const IRedJubJubVerificationKey();
  BuBytes get keyBytes;
  @override
  bool verify(RedJubJubVerifyingParams verifyParams) {
    return blockchainUtils.api.signing.jubjub.verify(
      pk: keyBytes,
      message: verifyParams.message,
      signature: verifyParams.signature,
      variant: switch (type) {
        CryptoKeyType.redJubJubBinding => RedJubJubVariant.binding,
        CryptoKeyType.redJubJubSpend => RedJubJubVariant.spendAuth,
        _ =>
          throw CoreErrors.cryptoFailed(
            "IRedJubJubVerificationKey.verify",
            reason: "Unexpected key type.",
          ),
      },
    );
  }
}

/// Common interface every RedJubjub private key implements.
abstract class IRedJubJubSigningKey<P extends IRedJubJubVerificationKey>
    implements ISigningKey<ReddsaSignature, RedJubJubSigningParams, P> {
  JubJubFr scalar();
  const IRedJubJubSigningKey();

  @override
  ReddsaSignature sign(RedJubJubSigningParams params) {
    return takeSecretKey().useValue(
      (k) => blockchainUtils.api.signing.jubjub.sign(
        sk: k,
        message: params.message,
        rand80: params.random,
        variant: switch (type) {
          CryptoKeyType.redJubJubBinding => RedJubJubVariant.binding,
          CryptoKeyType.redJubJubSpend => RedJubJubVariant.spendAuth,
          _ =>
            throw CoreErrors.cryptoFailed(
              "IRedJubJubSigningKey.sign",
              reason: "Unexpected key type.",
            ),
        },
      ),
    );
  }
}
