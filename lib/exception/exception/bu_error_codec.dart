import 'package:blockchain_utils/encoding/cbor/cbor.dart';
import 'package:blockchain_utils/exception/exception/rpc_error.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// CBOR codec for [BuError]. Lives in `blockchain_utils` (not the connector)
/// so the base stays serialization-free. Wire format: `CborTag(identifier)`
/// wrapping `[message, details]`, plus 5 extra slots for [RpcError].
/// Tag id == [BuErrorType.id] by construction.
abstract final class BuErrorCodec {
  static final Map<int, BuErrorType> _types = {
    for (final t in DefaultErrorType.values) t.id: t,
  };

  /// Register chain-specific enums for decoding. Core types are pre-registered.
  static void registerTypes(Iterable<BuErrorType> types) {
    for (final t in types) {
      _types[t.id] = t;
    }
  }

  static BuErrorType? lookupType(int identifier) => _types[identifier];

  static CborTagValue encode(BuError e) {
    final items = <CborObject?>[e.message.toCbor(), e.details?.toCbor()];
    if (e case RPCError()) {
      return e.toCbor();
    }
    return CborTagValue(CborTagSerializable.listFromDynamic(items), [
      e.type.id,
    ]);
  }

  static BuError decode({List<int>? bytes, CborObject? object, String? hex}) {
    try {
      final CborTagValue tag = CborTagSerializable.decode(
        cborBytes: bytes,
        cborObject: object,
        cborHex: hex,
      );
      final tagId = tag.tags.length == 1 ? tag.tags[0] : null;
      final type = tagId == null ? null : _types[tagId];
      if (type == null) {
        return BuError(
          DefaultErrorType.invalidArgument,
          'unknown error identifier $tagId',
          details: {'identifier': '$tagId'},
        );
      }
      final values = CborSerializable.decodeTaggedValue<CborListValue>(
        cborObject: tag,
      );

      if (type == DefaultErrorType.network && values.hasIndex(6)) {
        return RPCError.deserialize(object: tag);
      }
      final message = values.rawValueAt<String>(0);
      final details = values.maybeRawMapAt<String, String?>(1);
      return BuError(type, message, details: details);
    } on BuError {
      rethrow;
    } catch (_) {
      throw BuError(
        DefaultErrorType.badCbor,
        'invalid error payload: undecodable bytes',
      );
    }
  }
}

/// CBOR encoding for any [BuError].
extension BuErrorEncoding on BuError {
  CborTagValue toCbor() => BuErrorCodec.encode(this);

  List<int> toCborBytes() => BuErrorCodec.encode(this).encode();
}
