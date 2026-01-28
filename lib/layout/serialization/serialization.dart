import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/layout/core/core/core.dart';
import 'package:blockchain_utils/layout/exception/exception.dart';

abstract mixin class LayoutSerializable {
  static Map<String, dynamic> deserialize({
    required List<int> bytes,
    required Layout<Map<String, dynamic>> layout,
  }) {
    final decode = layout.deserialize(bytes);
    return decode.value;
  }

  const LayoutSerializable();
  Layout<Map<String, dynamic>> toLayout({String? property});
  Map<String, dynamic> toSerializeJson();
  List<int> toSerializeBytes({String? property}) {
    final layout = toLayout(property: property);
    return layout.serialize(toSerializeJson());
  }
}

class VariantDeserializeResult {
  final Map<String, dynamic> result;
  String get variantName => result['key'];
  Map<String, dynamic> get value => result['value'];
  VariantDeserializeResult(Map<String, dynamic> result)
    : result = result.immutable;

  @override
  String toString() {
    return '$variantName: $value';
  }
}

abstract mixin class VariantLayoutSerializable implements LayoutSerializable {
  const VariantLayoutSerializable();
  static VariantDeserializeResult toVariantDecodeResult(
    Map<String, dynamic> json,
  ) {
    if (json['key'] is! String || !json.containsKey('value')) {
      throw const LayoutException("Invalid variant json encoding.");
    }
    return VariantDeserializeResult(json);
  }

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

  String get variantName;
  Layout<Map<String, dynamic>> toVariantLayout({String? property});

  Map<String, dynamic> toSerializeVariantJson() {
    return {variantName: toSerializeJson()};
  }

  List<int> toSerializeVariantBytes() {
    final layout = toVariantLayout();
    return layout.serialize(toSerializeVariantJson());
  }

  @override
  List<int> toSerializeBytes({String? property}) {
    final layout = toLayout(property: property);
    return layout.serialize(toSerializeJson());
  }
}
