import 'package:blockchain_utils/exception/exceptions.dart';

class AddressConverterException extends BlockchainUtilsException {
  const AddressConverterException(String message,
      {Map<String, dynamic>? details})
      : super(message, details: details);
}
