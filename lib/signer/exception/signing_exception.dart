import 'package:blockchain_utils/crypto/crypto/exception/exception.dart';

class CryptoSignException extends CryptoException {
  const CryptoSignException(super.message, {super.details});
  static const CryptoSignException signatureVerificationFailed =
      CryptoSignException('The created signature does not pass verification.');
}
