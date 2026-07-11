import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/serialization/identifier.dart';

class Web3SecretStorageDefinationV3Exception extends BlockchainUtilsException {
  const Web3SecretStorageDefinationV3Exception._(super.message);

  static Web3SecretStorageDefinationV3Exception unsuportedBackupContent =
      Web3SecretStorageDefinationV3Exception._("Unsupported backup content.");
  static Web3SecretStorageDefinationV3Exception wrongBackupPassword =
      Web3SecretStorageDefinationV3Exception._("Wrong backup password.");

  factory Web3SecretStorageDefinationV3Exception.deserialize({
    List<int>? bytes,
    CborObject? object,
  }) {
    final values = CborTagSerializable.decodeTaggedValue(
      identifier: BlockchainUtilsSerializationIdentifier.secretStorageError,
      cborBytes: bytes,
      cborObject: object,
    );
    return Web3SecretStorageDefinationV3Exception._(values.rawValueAt(0));
  }

  @override
  BlockchainUtilsSerializationIdentifier get serializationIdentifier =>
      BlockchainUtilsSerializationIdentifier.secretStorageError;
}
