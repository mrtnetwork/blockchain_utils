
import 'package:blockchain_utils/helper/extensions/extensions.dart';

abstract class JsonifyConfig {
  Object? encodeBigint(BigInt? big) => big;
  Map<K, V> encodeMap<K, V>(Map<K, V> map) => map;
}

class DefaultJsonifyConfig implements JsonifyConfig {
  final bool bigAsString;
  final bool notJsonNullableValue;
  const DefaultJsonifyConfig({
    this.bigAsString = true,
    this.notJsonNullableValue = true,
  });

  @override
  Object? encodeBigint(BigInt? big) {
    if (bigAsString) return big?.toString();
    return big;
  }

  @override
  Map<K, V> encodeMap<K, V>(Map<K, V> map) {
    if (notJsonNullableValue) return map.notNullValue;
    return map;
  }

  static const DefaultJsonifyConfig defaultConfig = DefaultJsonifyConfig();
}
