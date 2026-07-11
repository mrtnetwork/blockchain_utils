import 'package:blockchain_utils/cbor/core/cbor.dart';
import 'package:blockchain_utils/cbor/types/types.dart';
import 'cbor.dart';
import 'exception.dart';

/// identifiers from 11000
abstract class SerializationIdentifier {
  /// Identifier id must be grather than 258 for custom types.
  int get id;
  bool isValid(int? tag);
}

abstract mixin class CborTagSerializable {
  SerializationIdentifier get serializationIdentifier;
  List<CborObject?> get serializationItems;
  CborTagValue toCbor() => CborTagValue(listFromDynamic(serializationItems), [
    serializationIdentifier.id,
  ]);

  static CborListValue decodeTaggedValue({
    List<int>? cborBytes,
    CborObject? cborObject,
    String? cborHex,
    required SerializationIdentifier? identifier,
  }) {
    try {
      return CborSerializable.decodeTaggedValue<CborListValue>(
        cborBytes: cborBytes,
        cborHex: cborHex,
        cborObject: cborObject,
        onValidateTags: (e) {
          if (e.length == 1) {
            if (identifier?.isValid(e[0]) ?? true) {
              return true;
            }
          }
          throw CborSerializableException.incorrectTagValue(tag: e);
        },
      );
    } on CborSerializableException {
      rethrow;
    } catch (e) {
      throw CborSerializableException.invalidCborEncodingBytes;
    }
  }

  static DecodeTaggedValue<IDENTIFIER>
  decodeTaggedValueWithInfo<IDENTIFIER extends SerializationIdentifier>({
    List<int>? cborBytes,
    CborObject? cborObject,
    String? cborHex,
    required List<IDENTIFIER> expectedTags,
  }) {
    try {
      final CborTagValue tag = CborTagSerializable.decode(
        cborBytes: cborBytes,
        cborHex: cborHex,
        cborObject: cborObject,
      );
      final tagId = tag.tags.length == 1 ? tag.tags[0] : null;
      if (tagId == null) {
        throw CborSerializableException.incorrectTagValue(tag: tag.tags);
      }
      final decode = CborSerializable.decodeTaggedValue<CborListValue>(
        cborObject: tag,
      );
      return DecodeTaggedValue(
        expectedTags.firstWhere(
          (e) {
            return e.isValid(tagId);
          },
          orElse:
              () =>
                  throw CborSerializableException.incorrectTagValue(
                    tag: tag.tags,
                  ),
        ),
        decode,
        tag,
      );
    } on CborSerializableException {
      rethrow;
    } catch (e) {
      throw CborSerializableException.invalidCborEncodingBytes;
    }
  }

  static T decode<T extends CborObject>({
    List<int>? cborBytes,
    CborObject? cborObject,
    String? cborHex,
  }) {
    try {
      return CborSerializable.decode(
        cborBytes: cborBytes,
        cborHex: cborHex,
        cborObject: cborObject,
      );
    } on CborSerializableException {
      rethrow;
    } catch (e) {
      throw CborSerializableException.invalidCborEncodingBytes;
    }
  }

  static CborListValue listFromDynamic(List<CborObject?> items) {
    return CborListValue.definite(
      items.map<CborObject>((e) => e ?? const CborNullValue()).toList(),
    );
  }

  static CborObject mapToCbor(
    Map<String, dynamic>? map, {
    CborObject Function(Object value)? unknownType,
  }) {
    if (map == null || map.isEmpty) return CborNullValue();
    return CborMapValue<CborString<String>, CborObject>.inDefinite({
      for (final i in map.entries)
        CborStringValue(i.key): CborObject.fromDynamic(
          i.value,
          unknownType: unknownType,
        ),
    });
  }
}

class DecodeTaggedValue<IDENTIFIER extends SerializationIdentifier> {
  final IDENTIFIER identifier;
  final CborListValue values;
  final CborTagValue tag;
  const DecodeTaggedValue(this.identifier, this.values, this.tag);
}
