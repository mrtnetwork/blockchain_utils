import 'dart:typed_data';

// Define the BITCOIN (BTC) base58 alphabet.
const String bitcoin =
    '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';

// Define the Ripple (XRP) base58 alphabet.
const String ripple =
    'rpshnaf39wBUDNEGHJKLM4PQRST7VWXYZ2bcdeCg65jkm8oFqi1tuvAxyz';

// Encode Uint8List data into a string using the specified alphabet.
String encode(Uint8List source, {String alphabet = bitcoin}) {
  if (source.isEmpty) {
    return "";
  }
  final length = alphabet.length;
  // final characters = _loadAlphabet(alphabet);
  List<int> digits = [0];

  for (var i = 0; i < source.length; ++i) {
    var carry = source[i];
    for (var j = 0; j < digits.length; ++j) {
      carry += digits[j] << 8;
      digits[j] = carry % length;
      carry = carry ~/ length;
    }
    while (carry > 0) {
      digits.add(carry % length);
      carry = carry ~/ length;
    }
  }
  var string = "";

  // Deal with leading zeros
  for (var k = 0; source[k] == 0 && k < source.length - 1; ++k) {
    string += alphabet[0];
  }
  // Convert digits to a string
  for (var q = digits.length - 1; q >= 0; --q) {
    string += alphabet[digits[q]];
  }
  return string;
}

// Decode a string into Uint8List data using the specified alphabet.
Uint8List decode(String string, {String alphabet = bitcoin}) {
  if (string.isEmpty) {
    throw ArgumentError('invalid base58 characters');
  }
  final length = alphabet.length;
  List<int> bytes = [0];
  for (var i = 0; i < string.length; i++) {
    var value = alphabet.indexOf(string[i]);
    if (value < 0) {
      throw ArgumentError('invalid base58 character');
    }
    var carry = value;
    for (var j = 0; j < bytes.length; ++j) {
      carry += bytes[j] * length;
      bytes[j] = carry & 0xff;
      carry >>= 8;
    }
    while (carry > 0) {
      bytes.add(carry & 0xff);
      carry >>= 8;
    }
  }
  // Deal with leading zeros
  for (var k = 0; string[k] == alphabet[0] && k < string.length - 1; ++k) {
    bytes.add(0);
  }
  return Uint8List.fromList(bytes.reversed.toList());
}
