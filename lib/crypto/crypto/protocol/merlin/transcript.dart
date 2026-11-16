import 'dart:typed_data';
import 'package:blockchain_utils/api/api/api.dart';
import 'package:blockchain_utils/crypto/crypto/protocol/strobe/strobe.dart';
import 'package:blockchain_utils/utils/binary/src/binary_operation.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';
import 'package:blockchain_utils/utils/numbers/utils/bigint_utils.dart';
import 'package:blockchain_utils/utils/string/string.dart';

/// A transcript object for the Merlin cryptographic protocol.
class MerlinTranscript {
  final Strobe strobe;

  /// Merlin's own domain-separation label ("Merlin v1.0"); the underlying
  /// duplex runs STROBEv1.0.2 framing (see [Strobe.version]).
  static const String merlinVersion = "Merlin v1.0";
  const MerlinTranscript.fromStrobe(this.strobe);

  /// The Strobe instance used for cryptographic operations.
  factory MerlinTranscript(String label) {
    final transcript = MerlinTranscript.fromStrobe(
      Strobe(merlinVersion, StrobeSecParam.sec128),
    );
    transcript.additionalData(
      StringUtils.encode("dom-sep"),
      StringUtils.encode(label),
    );
    return transcript;
  }
  MerlinTranscript clone() {
    return MerlinTranscript.fromStrobe(strobe.clone());
  }

  /// Appends additional data to the transcript for the Merlin cryptographic protocol.
  ///
  /// Parameters:
  /// - [label]: A list of integers representing the label for the additional data.
  /// - [message]: A list of integers representing the actual additional data message.
  ///
  void additionalData(List<int> label, List<int> message) {
    final size = List.filled(4, 0);
    BinaryOps.writeUint32LE(message.length, size);
    final List<int> labelSize = [...label, ...size];
    strobe.additionalData(true, labelSize);
    strobe.additionalData(false, message);
  }

  /// Generates pseudo-random bytes based on the current transcript state.
  ///
  /// Parameters:
  /// - [label]: A list of integers representing the label for the pseudo-random data.
  /// - [outLen]: The length of the pseudo-random data to generate, specified as an integer.
  ///
  BuBytes toBytes(List<int> label, int outLen) {
    final len = List.filled(4, 0);
    BinaryOps.writeUint32LE(outLen, len);
    final List<int> labelSize = [...label, ...len];
    strobe.additionalData(true, labelSize);

    final BuBytes outBytes = strobe.pseudoRandomData(outLen);
    return outBytes;
  }

  /// Generates pseudo-random bytes and reduces them using scalar reduction.
  ///
  /// Parameters:
  /// - [label]: A list of integers representing the label for the pseudo-random data.
  /// - [outLen]: The length of the pseudo-random data to generate, specified as an integer. The output (little-endian) is reduced with Ed25519 scReduce — Ed25519 scalars only.
  ///
  BuBytes toBytesWithReduceScalar(List<int> label, int outLen) {
    return blockchainUtils.api.ed25519.scReduce(toBytes(label, outLen));
  }

  /// Converts pseudo-random bytes into a [BigInt] with scalar reduction.
  ///
  /// Parameters:
  /// - [label]: A list of integers representing the label for the pseudo-random data.
  /// - [outLen]: The length of the pseudo-random data to generate, specified as an integer. Decoded little-endian after Ed25519 scReduce — Ed25519 scalars only.
  ///
  BigInt toBigint(List<int> label, int outLen) {
    return BigintUtils.fromBytes(
      toBytesWithReduceScalar(label, outLen),
      byteOrder: Endian.little,
    );
  }
}
