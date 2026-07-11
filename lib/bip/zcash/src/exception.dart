import 'package:blockchain_utils/bip/zcash/src/types.dart';
import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/serialization/identifier.dart';

class ZcashKeyError extends BlockchainUtilsException {
  const ZcashKeyError(super.message, {super.details});

  factory ZcashKeyError.deserialize({List<int>? bytes, CborObject? object}) {
    final values = CborTagSerializable.decodeTaggedValue(
      identifier: BlockchainUtilsSerializationIdentifier.zcashError,
      cborBytes: bytes,
      cborObject: object,
    );
    return ZcashKeyError(
      values.rawValueAt(0),
      details: values.maybeRawMapAt<String, String?>(1),
    );
  }

  @override
  BlockchainUtilsSerializationIdentifier get serializationIdentifier =>
      BlockchainUtilsSerializationIdentifier.zcashError;
}

class ZcashKeyEncodingError extends ZcashKeyError {
  const ZcashKeyEncodingError(super.message, {super.details});
  factory ZcashKeyEncodingError.deserialize({
    List<int>? bytes,
    CborObject? object,
  }) {
    final values = CborTagSerializable.decodeTaggedValue(
      identifier: BlockchainUtilsSerializationIdentifier.zcashKeyEncodingError,
      cborBytes: bytes,
      cborObject: object,
    );
    return ZcashKeyEncodingError(
      values.rawValueAt(0),
      details: values.maybeRawMapAt<String, String?>(1),
    );
  }

  static ZcashKeyEncodingError invalidUnifiedArguments(
    UnifiedReceiverMode mode, {
    String? reason,
  }) {
    return ZcashKeyEncodingError(
      "Invalid unified ${mode.viewName()} arguments.",
      details: {"reason": reason},
    );
  }

  static ZcashKeyEncodingError invalidUnifiedBytes(
    UnifiedReceiverMode mode, {
    String? reason,
  }) {
    return ZcashKeyEncodingError(
      "Invalid unified ${mode.viewName()} bytes.",
      details: {"reason": reason},
    );
  }

  static ZcashKeyEncodingError invalidKeyData(String type, {String? reason}) {
    return ZcashKeyEncodingError(
      "Invalid $type key data.",
      details: {"reason": reason},
    );
  }

  static ZcashKeyEncodingError invalidUnifiedObject(
    UnifiedReceiverMode mode, {
    String? reason,
    Map<String, String?>? details,
  }) {
    return ZcashKeyEncodingError(
      "Invalid unified ${mode.viewName()}.",
      details: {"reason": reason, ...details ?? {}},
    );
  }

  static ZcashKeyEncodingError invalidUnifiedTypeCode(
    UnifiedReceiverMode mode, {
    String? reason,
    Map<String, String>? details,
  }) {
    return ZcashKeyEncodingError(
      "Invalid unified ${mode.viewName()} typecode.",
      details: {"reason": reason, ...details ?? {}},
    );
  }

  @override
  BlockchainUtilsSerializationIdentifier get serializationIdentifier =>
      BlockchainUtilsSerializationIdentifier.zcashKeyEncodingError;
}
