import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/serialization/identifier.dart';

/// An exception representing an error related to mnemonic.
class MnemonicException extends BlockchainUtilsException {
  const MnemonicException(super.message, {super.details});
  static const MnemonicException invalidChecksum = MnemonicException(
    "Invalid mnemonic checksum.",
  );

  factory MnemonicException.deserialize({
    List<int>? bytes,
    CborObject? object,
  }) {
    final values = CborTagSerializable.decodeTaggedValue(
      identifier: BlockchainUtilsSerializationIdentifier.mnemonicError,
      cborBytes: bytes,
      cborObject: object,
    );
    return MnemonicException(
      values.rawValueAt(0),
      details: values.maybeRawMapAt<String, String?>(1),
    );
  }

  @override
  BlockchainUtilsSerializationIdentifier get serializationIdentifier =>
      BlockchainUtilsSerializationIdentifier.mnemonicError;
}
