import 'package:blockchain_utils/blockchain_utils.dart';

class Web3SecretStorageDefinationV3Exception extends BlockchainUtilsException {
  /// The error message associated with this exception.
  @override
  final String message;

  @override
  final Map<String, dynamic>? details;

  /// Creates a new instance of [Web3SecretStorageDefinationV3Exception] with an optional [message].
  const Web3SecretStorageDefinationV3Exception(this.message, {this.details});
}
