import 'package:blockchain_utils/exception/exception/exception.dart';

class Utf8Exception extends BlockchainUtilsException {
  const Utf8Exception(super.message, {super.details});
  static const Utf8Exception invalidUf16String = Utf8Exception(
    "Invalid UTF-16 string.",
  );
  static const Utf8Exception invalidUf8String = Utf8Exception(
    "Invalid UTF-8 string.",
  );
}
