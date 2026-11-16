import 'package:blockchain_utils/crypto/crypto/keys/keys.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/encoding/layout/layout.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';
import 'package:blockchain_utils/utils/json/extension/json.dart';

/// Represents a RedDSA signature consisting of r and s components.
class ReddsaSignature extends ISignature with LayoutSerializable, Equality {
  final BuBytes rBytes;
  final BuBytes sBytes;
  ReddsaSignature.fromBytes(List<int> bytes)
    : rBytes =
          bytes
              .exc(
                length: 64,
                operation: "ReddsaSignature",
                reason: "Invalid signature bytes length.",
              )
              .sublist(0, 32)
              .asImmutableBytes,
      sBytes = bytes.sublist(32).asImmutableBytes;
  ReddsaSignature({required this.rBytes, required this.sBytes});
  factory ReddsaSignature.deserializeJson(Map<String, dynamic> json) {
    return ReddsaSignature.fromBytes(json.valueAsBytes("signature"));
  }
  static Layout<Map<String, dynamic>> layout({String? property}) {
    return LayoutConst.struct([
      LayoutConst.fixedBlobN(64, property: "signature"),
    ], property: property);
  }

  @override
  Map<String, dynamic> toSerializeJson() {
    return {"signature": toBytes()};
  }

  @override
  Layout<Map<String, dynamic>> toLayout({String? property}) {
    return layout(property: property);
  }

  @override
  BuBytes toBytes() {
    return BuBytes([...rBytes, ...sBytes]);
  }

  @override
  List<dynamic> get variables => [rBytes, sBytes];
}
