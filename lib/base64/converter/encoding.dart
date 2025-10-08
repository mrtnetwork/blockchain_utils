import 'package:blockchain_utils/blockchain_utils.dart';

/// A Base64 encoder that supports streaming data in chunks.
/// It accumulates bytes and encodes them in groups of 3,
/// handling padding for incomplete final blocks.
class _Base64StreamEncoder {
  static const _base64Table =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

  static String _encode(List<int> bytes) {
    final output = StringBuffer();
    int i = 0;

    while (i + 3 <= bytes.length) {
      int chunk = (bytes[i] << 16) | (bytes[i + 1] << 8) | (bytes[i + 2]);
      output.write(_base64Table[(chunk >> 18) & 0x3F]);
      output.write(_base64Table[(chunk >> 12) & 0x3F]);
      output.write(_base64Table[(chunk >> 6) & 0x3F]);
      output.write(_base64Table[chunk & 0x3F]);
      i += 3;
    }

    int remaining = bytes.length - i;
    if (remaining == 1) {
      int chunk = bytes[i] << 16;
      output.write(_base64Table[(chunk >> 18) & 0x3F]);
      output.write(_base64Table[(chunk >> 12) & 0x3F]);
      output.write('=');
      output.write('=');
    } else if (remaining == 2) {
      int chunk = (bytes[i] << 16) | (bytes[i + 1] << 8);
      output.write(_base64Table[(chunk >> 18) & 0x3F]);
      output.write(_base64Table[(chunk >> 12) & 0x3F]);
      output.write(_base64Table[(chunk >> 6) & 0x3F]);
      output.write('=');
    }

    return output.toString();
  }

  final StringBuffer _buffer = StringBuffer();
  final List<int> _partial = [];

  /// Adds bytes to the encoder buffer, encoding full 3-byte chunks immediately.
  void add(List<int> bytes) {
    _partial.addAll(bytes);
    while (_partial.length >= 3) {
      final chunk = _partial.sublist(0, 3);
      _buffer.write(_encode(chunk));
      _partial.removeRange(0, 3);
    }
  }

  /// Finalizes the encoding, encoding any remaining bytes with padding.
  /// Returns the full Base64 encoded string.
  String finalize() {
    if (_partial.isNotEmpty) {
      _buffer.write(_encode(_partial));
    }
    return _buffer.toString();
  }

  /// Clears internal buffers to reset the encoder state.
  void clean() {
    _buffer.clear();
    _partial.clear();
  }
}

/// Utility class for encoding bytes into Base64 strings with options for
/// URL-safe encoding and optional padding removal.
class B64Encoder {
  /// Encodes the given [data] bytes to a Base64 string.
  ///
  /// [noPadding]: If true, removes the '=' padding characters from the output.
  /// Defaults to false (padding included).
  ///
  /// [urlSafe]: If true, uses URL-safe Base64 encoding by replacing '+' with '-'
  /// and '/' with '_'. Defaults to false (standard Base64).
  ///
  /// Returns the Base64-encoded string.
  static String encode(List<int> data,
      {bool noPadding = false, bool urlSafe = false}) {
    final encoder = _Base64StreamEncoder();
    try {
      encoder.add(data.asBytes);
      String b64 = encoder.finalize();
      if (urlSafe) {
        b64 = b64.replaceAll('+', '-').replaceAll('/', '_');
      }
      if (noPadding) {
        b64 = b64.replaceAll('=', '');
      }
      return b64;
    } finally {
      encoder.clean();
    }
  }
}
