import 'package:blockchain_utils/exception/exceptions.dart';

class AddressConverterException implements BlockchainUtilsException {
  @override
  final String message;

  @override
  final Map<String, dynamic>? details;

  const AddressConverterException(this.message, {this.details});
}
