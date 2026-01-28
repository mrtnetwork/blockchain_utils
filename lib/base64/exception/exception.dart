import 'package:blockchain_utils/exception/exception/exception.dart';

class B64ConverterException extends BlockchainUtilsException {
  const B64ConverterException({super.details})
    : super("Invalid base64 string.");
}
