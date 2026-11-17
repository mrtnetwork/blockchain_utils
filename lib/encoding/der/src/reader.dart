import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

class DerNode {
  final int tag;
  final BuBytes value;
  DerNode(this.tag, List<int> value) : value = value.asImmutableBytes;

  bool get isConstructed => (tag & 0x20) != 0;

  /// Parses [value] as a sequence of child TLVs (for constructed nodes).
  List<DerNode> children() => DerReader(value).readAll();
}

class DerReader {
  final BuBytes data;
  int pos = 0;
  DerReader(List<int> data) : data = data.asImmutableBytes;

  bool get hasMore => pos < data.length;

  DerNode readNode() {
    if (pos >= data.length) {
      throw CoreErrors.cryptoFailed(
        "DerReader",
        reason: "Unexpected end of DER data",
      );
    }
    final tag = data[pos++];
    if (pos >= data.length) {
      throw CoreErrors.cryptoFailed(
        "DerReader",
        reason: "Truncated DER length",
      );
    }
    int len = data[pos++];
    if (len & 0x80 != 0) {
      final numBytes = len & 0x7F;
      if (numBytes == 0) {
        throw CoreErrors.cryptoFailed(
          "DerReader",
          reason: 'Indefinite length not supported (BER only)',
        );
      }
      if (pos + numBytes > data.length) {
        throw CoreErrors.cryptoFailed(
          "DerReader",
          reason: 'Truncated DER length',
        );
      }
      len = 0;
      for (var i = 0; i < numBytes; i++) {
        len = (len << 8) | data[pos++];
      }
    }
    if (pos + len > data.length) {
      throw CoreErrors.cryptoFailed(
        "DerReader",
        reason: 'DER length exceeds available data',
      );
    }
    final value = data.sublist(pos, pos + len);
    pos += len;
    return DerNode(tag, value);
  }

  List<DerNode> readAll() {
    final nodes = <DerNode>[];
    while (hasMore) {
      nodes.add(readNode());
    }
    return nodes;
  }
}
