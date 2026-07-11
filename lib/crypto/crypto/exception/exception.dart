import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/serialization/identifier.dart';

class CryptoException extends BlockchainUtilsException {
  const CryptoException(super.message, {super.details});
  static CryptoException failed(
    String operation, {
    String? reason,
    Map<String, String>? details,
  }) {
    return CryptoException(
      "Crypto operation failed during $operation",
      details: {"reason": reason, ...details ?? {}},
    );
  }

  factory CryptoException.deserialize({List<int>? bytes, CborObject? object}) {
    final values = CborTagSerializable.decodeTaggedValue(
      identifier: BlockchainUtilsSerializationIdentifier.cryptoError,
      cborBytes: bytes,
      cborObject: object,
    );
    return CryptoException(
      values.rawValueAt(0),
      details: values.maybeRawMapAt<String, String?>(1),
    );
  }

  @override
  BlockchainUtilsSerializationIdentifier get serializationIdentifier =>
      BlockchainUtilsSerializationIdentifier.cryptoError;

  static CryptoException get operationNotSupported =>
      CryptoException("Current operation not supported.");

  @override
  String toString() {
    return message;
  }
}
