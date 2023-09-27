/// Decode a base58check-encoded string into a Uint8List payload.
import 'dart:typed_data';

import 'package:blockchain_utils/crypto/crypto.dart';
import 'package:blockchain_utils/formating/bytes_num_formating.dart';
import 'base58.dart' as bs58;

/// Decode a base58check-encoded string into a Uint8List payload.
Uint8List decodeCheck(String string, {String alphabet = bs58.bitcoin}) {
  final bytes = bs58.decode(string, alphabet: alphabet);
  if (bytes.length < 5) {
    throw ArgumentError("invalid base58check");
  }
  Uint8List payload = bytes.sublist(0, bytes.length - 4);
  Uint8List checksum = bytes.sublist(bytes.length - 4);
  Uint8List newChecksum = doubleHash(payload).sublist(0, 4);
  if (!bytesListEqual(checksum, newChecksum)) {
    throw ArgumentError("Invalid checksum");
  }
  return payload;
}

/// Encode data and add checksum for error detection (used in Bitcoin).
String encodeCheck(Uint8List bytes, {String alphabet = bs58.bitcoin}) {
  Uint8List hash = doubleHash(bytes);
  Uint8List combine = Uint8List.fromList(
      [bytes, hash.sublist(0, 4)].expand((i) => i).toList(growable: false));
  return bs58.encode(combine, alphabet: alphabet);
}
