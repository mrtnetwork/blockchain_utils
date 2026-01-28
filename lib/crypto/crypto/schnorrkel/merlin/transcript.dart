import 'dart:typed_data';
import 'package:blockchain_utils/helper/extensions/extensions.dart';

import 'package:blockchain_utils/crypto/crypto/ec/utils/ed25519.dart';
import 'package:blockchain_utils/crypto/crypto/schnorrkel/strobe/strobe.dart';
import 'package:blockchain_utils/utils/binary/binary_operation.dart';
import 'package:blockchain_utils/utils/numbers/utils/bigint_utils.dart';

/// A transcript object for the Merlin cryptographic protocol.
class MerlinTranscript {
  final Strobe strobe;
  static const String merlinVersion = "Merlin v1.0";
  const MerlinTranscript.fromStrobe(this.strobe);

  /// The Strobe instance used for cryptographic operations.
  factory MerlinTranscript(String label) {
    final transcript = MerlinTranscript.fromStrobe(
      Strobe(merlinVersion, StrobeSecParam.sec128),
    );
    transcript.additionalData("dom-sep".codeUnits, label.codeUnits);
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
  List<int> toBytes(List<int> label, int outLen) {
    final len = List.filled(4, 0);
    BinaryOps.writeUint32LE(outLen, len);
    final List<int> labelSize = [...label, ...len];
    strobe.additionalData(true, labelSize);

    final List<int> outBytes = strobe.pseudoRandomData(outLen);
    return outBytes.asBytes;
  }

  /// Generates pseudo-random bytes and reduces them using scalar reduction.
  ///
  /// Parameters:
  /// - [label]: A list of integers representing the label for the pseudo-random data.
  /// - [outLen]: The length of the pseudo-random data to generate, specified as an integer.
  ///
  List<int> toBytesWithReduceScalar(List<int> label, int outLen) {
    return Ed25519Utils.scalarReduceConst(toBytes(label, outLen));
  }

  /// Converts pseudo-random bytes into a [BigInt] with scalar reduction.
  ///
  /// Parameters:
  /// - [label]: A list of integers representing the label for the pseudo-random data.
  /// - [outLen]: The length of the pseudo-random data to generate, specified as an integer.
  ///
  BigInt toBigint(List<int> label, int outLen) {
    return BigintUtils.fromBytes(
      toBytesWithReduceScalar(label, outLen),
      byteOrder: Endian.little,
    );
  }
}
