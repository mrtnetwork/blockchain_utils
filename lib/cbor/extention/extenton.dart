import 'package:blockchain_utils/blockchain_utils.dart';

extension QuickCastingCbor on CborObject {
  T cast<T extends CborObject>() {
    if (this is T) return this as T;
    throw CborException("cbor object casting faild",
        details: {"excepted": "$T", "value": runtimeType.toString()});
  }
}
