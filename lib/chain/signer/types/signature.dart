import 'package:blockchain_utils/crypto/crypto/keys/keys.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// A signature paired with the content that was signed and its encoded bytes.
class SignedContent<SIGNATURE extends ISignature> {
  final SIGNATURE signature;
  final BuBytes? content;
  final BuBytes encoded;
  SignedContent({
    required this.signature,
    List<int>? content,
    required List<int> encoded,
  }) : content = content?.asImmutableBytes,
       encoded = encoded.asImmutableBytes;
}
