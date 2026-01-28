/// An abstract base class for encoding values in Substrate SCALE format.
abstract class SubstrateScaleEncoderBase {
  const SubstrateScaleEncoderBase();

  /// Encode the provided [value] in Substrate SCALE format.
  List<int> encode(String value);
}
