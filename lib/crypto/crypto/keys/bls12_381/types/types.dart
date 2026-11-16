import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

class Bls12SigningParams implements ISigningParams {
  final BuBytes message;
  final BuBytes? dst;
  Bls12SigningParams({required List<int> message, List<int>? dst})
    : message = message.asImmutableBytes,
      dst = dst?.asImmutableBytes;
}

class Bls12AggregateSigningParams implements ISigningParams {
  final List<BuBytes> messages;
  final BuBytes? dst;
  Bls12AggregateSigningParams({
    required List<List<int>> messages,
    List<int>? dst,
  }) : messages = messages.map((e) => e.asImmutableBytes).toImutableList,
       dst = dst?.asImmutableBytes;
}

class Bls12FastAggregateSigningParams implements ISigningParams {
  final BuBytes message;
  final BuBytes? dst;
  Bls12FastAggregateSigningParams({required List<int> message, List<int>? dst})
    : message = message.asImmutableBytes,
      dst = dst?.asImmutableBytes;
}
