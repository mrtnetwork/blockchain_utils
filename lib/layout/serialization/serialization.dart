import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/layout/core/core/core.dart';
import 'package:blockchain_utils/layout/exception/exception.dart';

/// Mixin for objects that can be serialized/deserialized via a Layout.
abstract mixin class LayoutSerializable {
  /// Converts bytes into a Map using the provided layout.
  static Map<String, dynamic> deserialize({
    required List<int> bytes,
    required Layout<Map<String, dynamic>> layout,
  }) {
    final decode = layout.deserialize(bytes);
    return decode.value;
  }

  const LayoutSerializable();

  /// Converts the object into a Layout for serialization.
  Layout<Map<String, dynamic>> toLayout({String? property});

  /// Serializes the object to JSON.
  Map<String, dynamic> toSerializeJson();

  /// Serializes the object to bytes using its layout.
  List<int> toSerializeBytes({String? property}) {
    final layout = toLayout(property: property);
    return layout.serialize(toSerializeJson());
  }
}

/// Represents the result of deserializing a variant type.
class VariantDeserializeResult {
  final Map<String, dynamic> result;

  /// Returns the name of the variant.
  String get variantName => result['key'];

  /// Returns the value of the variant.
  Map<String, dynamic> get value => result['value'];
  VariantDeserializeResult(Map<String, dynamic> result)
    : result = result.immutable;

  @override
  String toString() {
    return '$variantName: $value';
  }
}

/// Mixin for variant types that support layout-based serialization.
abstract mixin class VariantLayoutSerializable implements LayoutSerializable {
  const VariantLayoutSerializable();

  /// Converts a JSON map into a VariantDeserializeResult.
  static VariantDeserializeResult toVariantDecodeResult(
    Map<String, dynamic> json,
  ) {
    if (json['key'] is! String || !json.containsKey('value')) {
      throw const LayoutException("Invalid variant json encoding.");
    }
    return VariantDeserializeResult(json);
  }

  /// Deserializes bytes into a JSON map for the variant.
  static Map<String, dynamic> deserialize({
    required List<int> bytes,
    required Layout<Map<String, dynamic>> layout,
  }) {
    Map<String, dynamic> json;
    try {
      json = layout.deserialize(bytes).value;
    } catch (_) {
      throw const LayoutException("Invalid variant bytes encoding.");
    }
    if (json['key'] is! String || !json.containsKey('value')) {
      throw const LayoutException("Invalid variant layout.");
    }
    return json;
  }

  /// Returns the name of the variant.
  String get variantName;

  /// Converts the variant to its Layout representation.
  Layout<Map<String, dynamic>> toVariantLayout({String? property});

  Map<String, dynamic> toSerializeVariantJson() {
    return {variantName: toSerializeJson()};
  }

  /// Serializes the variant to JSON.
  List<int> toSerializeVariantBytes() {
    final layout = toVariantLayout();
    return layout.serialize(toSerializeVariantJson());
  }

  /// Serializes the variant to bytes.
  @override
  List<int> toSerializeBytes({String? property}) {
    final layout = toLayout(property: property);
    return layout.serialize(toSerializeJson());
  }
}
