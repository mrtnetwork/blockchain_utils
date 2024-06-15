import 'package:blockchain_utils/bip/substrate/scale/substrate_scale_enc_base.dart';
import 'package:blockchain_utils/bip/substrate/scale/substrate_scale_enc_cuint.dart';
import 'package:blockchain_utils/utils/utils.dart';

/// A Substrate SCALE encoder for string values represented as bytes.
class SubstrateScaleBytesEncoder extends SubstrateScaleEncoderBase {
  const SubstrateScaleBytesEncoder();

  /// Encode the provided [value] as bytes and wrap it in Substrate SCALE format.
  @override
  List<int> encode(String value) {
    final toBytes = StringUtils.encode(value);
    List<int> lengthBytes =
        const SubstrateScaleCUintEncoder().encode(toBytes.length.toString());
    return List<int>.from([...lengthBytes, ...toBytes]);
  }
}
