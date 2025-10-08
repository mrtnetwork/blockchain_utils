import 'package:blockchain_utils/exception/exception/exception.dart';

class ExceptionConst {
  static GenericException itemNotFound({String? item}) =>
      GenericException("${item ?? 'item'} not found.");
}
