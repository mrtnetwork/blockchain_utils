import 'package:blockchain_utils/base64/exception/exception.dart';
import 'package:blockchain_utils/blockchain_utils.dart';

class _Base64StreamDecoder {
  static const _base64Table =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
  static final _base64DecodeTable = () {
    final table = List<int>.filled(256, -1);
    for (int i = 0; i < _base64Table.length; i++) {
      table[_base64Table.codeUnitAt(i)] = i;
    }
    return table.immutable;
  }();

  static List<int> _decode(String encoded) {
    final cleaned = encoded.replaceAll('=', '');
    final output = <int>[];
    int i = 0;

    while (i + 4 <= cleaned.length) {
      int chunk = (_base64DecodeTable[cleaned.codeUnitAt(i)] << 18) |
          (_base64DecodeTable[cleaned.codeUnitAt(i + 1)] << 12) |
          (_base64DecodeTable[cleaned.codeUnitAt(i + 2)] << 6) |
          (_base64DecodeTable[cleaned.codeUnitAt(i + 3)]);
      output.add((chunk >> 16) & 0xFF);
      output.add((chunk >> 8) & 0xFF);
      output.add(chunk & 0xFF);
      i += 4;
    }

    int rem = cleaned.length - i;
    if (rem == 2) {
      int chunk = (_base64DecodeTable[cleaned.codeUnitAt(i)] << 18) |
          (_base64DecodeTable[cleaned.codeUnitAt(i + 1)] << 12);
      output.add((chunk >> 16) & 0xFF);
    } else if (rem == 3) {
      int chunk = (_base64DecodeTable[cleaned.codeUnitAt(i)] << 18) |
          (_base64DecodeTable[cleaned.codeUnitAt(i + 1)] << 12) |
          (_base64DecodeTable[cleaned.codeUnitAt(i + 2)] << 6);
      output.add((chunk >> 16) & 0xFF);
      output.add((chunk >> 8) & 0xFF);
    }

    return output;
  }

  final List<int> _output = [];
  String _carry = '';

  /// Adds Base64 string data to the decoder, buffering as needed.
  /// Strips out newline and carriage return characters.
  void add(String input) {
    _carry += input.replaceAll('\n', '').replaceAll('\r', '');
    while (_carry.length >= 4) {
      final chunk = _carry.substring(0, 4);
      _output.addAll(_decode(chunk));
      _carry = _carry.substring(4);
    }
  }

  /// Finalizes decoding by processing any remaining buffered data.
  /// Returns the full decoded byte list.
  List<int> finalize() {
    if (_carry.isNotEmpty) {
      _output.addAll(_decode(_carry.padRight(4, '=')));
    }
    return _output;
  }

  void clean() {
    _output.clear();
    _carry = '';
  }
}

/// A utility class for decoding Base64-encoded strings with options
/// for URL-safe variant handling and padding validation.
class B64Decoder {
  /// Decodes a Base64 [data] string into bytes.
  ///
  /// [validatePadding]: If true (default), requires input length to be a multiple of 4.
  /// If false, padding '=' is added automatically to fix length.
  ///
  /// [urlSafe]: If true (default), treats input as URL-safe Base64, converting
  /// '-' to '+' and '_' to '/' before decoding. If false, throws if URL-safe
  /// characters are present.
  ///
  /// Throws [B64ConverterException] on invalid input or length.
  static List<int> decode(String data,
      {bool validatePadding = true, bool urlSafe = true}) {
    if (validatePadding && data.length % 4 != 0) {
      throw B64ConverterException("Invalid length, must be multiple of four");
    } else if (!validatePadding) {
      while (data.length % 4 != 0) {
        data += '=';
      }
    }
    if (urlSafe) {
      data = data.replaceAll('-', '+').replaceAll('_', '/');
    } else if (data.contains('-') || data.contains('_')) {
      throw B64ConverterException(
          'Invalid character in standard Base64 string: found URL-safe characters "-" or "_" but urlSafe is false.');
    }
    final encoder = _Base64StreamDecoder();
    try {
      encoder.add(data);
      return encoder.finalize().clone();
    } finally {
      encoder.clean();
    }
  }

  /// Tries to decode a Base64 string, returning null if decoding fails.
  ///
  /// Same parameters as [decode], but catches exceptions and returns null on error.
  static List<int>? tryDecode(String data,
      {bool validatePadding = true, bool urlSafe = true}) {
    try {
      return decode(data, urlSafe: urlSafe, validatePadding: validatePadding);
    } catch (_) {
      return null;
    }
  }
}
