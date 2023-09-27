import 'dart:typed_data';
import "package:blockchain_utils/formating/bytes_num_formating.dart";
import "package:pointycastle/ecc/curves/secp256k1.dart" show ECCurve_secp256k1;
import 'package:pointycastle/ecc/api.dart' show ECPoint;

// Define the elliptic curve group order as a Uint8List.
final _rcOrderBytes = hexToBytes(
    "fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141");

// Define the elliptic curve prime field parameter 'p' as a Uint8List.
final _ecPBytes = hexToBytes(
    "fffffffffffffffffffffffffffffffffffffffffffffffffffffffefffffc2f");

// Create an instance of the secp256k1 elliptic curve.
final secp256k1 = ECCurve_secp256k1();

// Extract the elliptic curve's group order 'n' and generator point 'G'.
final n = secp256k1.n; // Group order 'n'
final G = secp256k1.G; // Generator point 'G'

// This function checks if a Uint8List 'x' represents a valid private key.
// It performs multiple checks to ensure 'x' is a valid scalar within a specified range.
// It returns true if 'x' is a valid private key; otherwise, it returns false.
bool isPrivate(Uint8List x) {
  // Check if 'x' is a valid scalar; if not, return false.
  if (!isScalar(x)) {
    return false;
  }

  // Compare 'x' to the all-zero byte sequence and the elliptic curve group order.
  // If 'x' is greater than 0 and less than the group order, it's a valid private key.
  return _compare(x, Uint8List(32)) > 0 && _compare(x, _rcOrderBytes) < 0;
}

// This function generates a tweaked private key from a private key and a tweak.
// It performs validation checks and returns the tweaked private key as a Uint8List.
// If the inputs are invalid or the resulting tweaked private key is invalid, it returns null.
Uint8List? generateTweek(Uint8List point, Uint8List tweak) {
  // Check if 'point' is a valid private key; if not, raise an error.
  if (!isPrivate(point)) {
    throw ArgumentError("Bad Private");
  }

  // Check if 'tweak' is a valid scalar; if not, raise an error.
  if (!isOrderScalar(tweak)) {
    throw ArgumentError("Bad Tweek");
  }

  // Decode 'point' and 'tweak' into BigInt values.
  BigInt dd = decodeBigInt(point);
  BigInt tt = decodeBigInt(tweak);

  // Calculate the new private key by adding 'dd' and 'tt', and take the result modulo 'n'.
  BigInt newPrivateKey = (dd + tt) % n;

  // Encode the new private key as a Uint8List.
  Uint8List dt = encodeBigInt(newPrivateKey);

  // Ensure that the resulting 'dt' has a length of at least 32 bytes.
  if (dt.length < 32) {
    Uint8List padLeadingZero = Uint8List(32 - dt.length);
    dt = Uint8List.fromList(padLeadingZero + dt);
  }

  // Check if the resulting 'dt' is a valid private key; if not, return null.
  if (!isPrivate(dt)) {
    return null;
  }

  // Return the valid tweaked private key as a Uint8List.
  return dt;
}

// This function checks if a Uint8List 'p' represents a valid elliptic curve point.
// It performs several checks on the structure and values within 'p' to determine validity.
// It returns true if 'p' is a valid point; otherwise, it returns false.
bool isPoint(Uint8List p) {
  // Check if the length of 'p' is less than 33 bytes; if so, it's not a valid point.
  if (p.length < 33) {
    return false;
  }

  // Extract the first byte ('t') and the next 32 bytes ('x') from 'p'.
  var t = p[0];
  var x = p.sublist(1, 33);

  // Check if 'x' is an all-zero byte sequence, which is not a valid point.
  if (_compare(x, Uint8List(32)) == 0) {
    return false;
  }

  // Check if 'x' is greater than or equal to the elliptic curve parameter 'EC_P', which is not a valid point.
  if (_compare(x, _ecPBytes) == 1) {
    return false;
  }

  // Attempt to decode 'p' into an elliptic curve point using '_decodeFrom'.
  // If an error is raised, it's not a valid point.
  try {
    _decodeFrom(p);
  } catch (err) {
    return false;
  }

  // Check if 'p' is in compressed format (t == 0x02 or t == 0x03) and has a length of 33 bytes; if so, it's a valid point.
  if ((t == 0x02 || t == 0x03) && p.length == 33) {
    return true;
  }

  // Extract the remaining bytes ('y') from 'p'.
  var y = p.sublist(33);

  // Check if 'y' is an all-zero byte sequence, which is not a valid point.
  if (_compare(y, Uint8List(32)) == 0) {
    return false;
  }

  // Check if 'y' is greater than or equal to 'EC_P', which is not a valid point.
  if (_compare(y, _ecPBytes) == 1) {
    return false;
  }

  // Check if 'p' is in uncompressed format (t == 0x04) and has a length of 65 bytes; if so, it's a valid point.
  if (t == 0x04 && p.length == 65) {
    return true;
  }

  // If none of the conditions are met, it's not a valid point.
  return false;
}

// This function checks whether a Uint8List represents a scalar value.
// In many cryptographic contexts, scalar values are expected to be 32 bytes long.
// It returns true if the input Uint8List has a length of 32 bytes, indicating it's a scalar; otherwise, it returns false.
bool isScalar(Uint8List x) {
  // Check if the length of the input Uint8List is equal to 32 bytes.
  return x.length == 32;
}

// This function checks if a value 'x' is a valid scalar less than the elliptic curve group order.
// It first ensures that 'x' is a scalar and then compares it to the group order.
// It returns true if 'x' is a valid scalar less than the group order; otherwise, it returns false.
bool isOrderScalar(x) {
  // Check if 'x' is a valid scalar; if not, return false.
  if (!isScalar(x)) {
    return false;
  }

  // Compare 'x' to the elliptic curve group order.
  // If 'x' is less than the group order, return true; otherwise, return false.
  return _compare(x, _rcOrderBytes) < 0; // < G
}

// This function checks if a Uint8List 'p' represents a compressed elliptic curve point.
// It returns true if 'p' is compressed (the first byte is not 0x04); otherwise, it returns false.
bool _isPointCompressed(Uint8List p) {
  // Check if the first byte of 'p' is not equal to 0x04.
  return p[0] != 0x04;
}

// This method performs point addition with a scalar value and optional compression.
// It takes a point 'p', a tweak 'tweak', and a boolean 'compress' flag as input.
// If the inputs are valid, it returns the result of the point addition as a Uint8List.
// If any input is invalid or if the result is infinity, it returns null.
Uint8List? pointAddScalar(Uint8List p, Uint8List tweak, bool compress) {
  // Check if 'p' is a valid ECPoint; if not, raise an error.
  if (!isPoint(p)) {
    throw ArgumentError("Bad Point");
  }

  // Check if 'tweak' is a valid scalar value; if not, raise an error.
  if (!isOrderScalar(tweak)) {
    throw ArgumentError("Bad Tweek");
  }

  // Decode the input 'p' into an ECPoint.
  ECPoint? pp = _decodeFrom(p);

  // If 'tweak' is zero, return the original point 'p' with optional compression.
  if (_compare(tweak, Uint8List(32)) == 0) {
    return pp!.getEncoded(compress);
  }

  // Decode the 'tweak' into a BigInt.
  BigInt tt = decodeBigInt(tweak);

  // Calculate the new point 'qq' as 'G * tt', where 'G' is a predefined generator point.
  ECPoint qq = (G * tt) as ECPoint;

  // Calculate the result point 'uu' as 'pp + qq'.
  ECPoint uu = (pp! + qq) as ECPoint;

  // Check if 'uu' is infinity (an invalid result); if so, return null.
  if (uu.isInfinity) {
    return null;
  }

  // Return the encoded representation of the result point 'uu' with optional compression.
  return uu.getEncoded(compress);
}

// This method decodes a Uint8List 'P' into an ECPoint.
// It uses the secp256k1 curve's decodePoint method to perform the decoding.
// If successful, it returns the decoded ECPoint; otherwise, it returns null.
ECPoint? _decodeFrom(Uint8List P) {
  // Use the secp256k1 curve's decodePoint method to attempt decoding.
  return secp256k1.curve.decodePoint(P);
}

// This function re-encodes a given Uint8List point representation based on a compression flag.
// If 'compressed' is true, it ensures that the point representation is compressed.
// If 'compressed' is false, it ensures that the point representation is uncompressed.
Uint8List reEncodedFromForm(Uint8List p, bool compressed) {
  // Decode the input Uint8List 'p' to obtain a point representation.
  final decode = _decodeFrom(p);

  // Check if decoding was successful. If not, raise an error.
  if (decode == null) {
    throw ArgumentError("Bad point");
  }

  // Get the encoded representation of the point with the desired compression status.
  final encode = decode.getEncoded(compressed);

  // Check if the resulting 'encode' is not compressed.
  if (!_isPointCompressed(encode)) {
    // If it's not compressed, remove the compression flag (first byte).
    return encode.sublist(1, encode.length);
  }

  // If it is compressed or remains compressed, return it as is.
  return encode;
}

// This function compares two Uint8List values by interpreting them as BigInts.
// It returns 0 if a and b are equal, 1 if a is greater than b, and -1 if a is less than b.
int _compare(Uint8List a, Uint8List b) {
  // Convert Uint8List a and b into BigInts for comparison.
  BigInt aa = decodeBigInt(a);
  BigInt bb = decodeBigInt(b);

  // Compare aa and bb using BigInt comparison operators.
  if (aa == bb) {
    return 0; // a and b are equal
  } else if (aa > bb) {
    return 1; // a is greater than b
  } else {
    return -1; // a is less than b
  }
}

Uint8List? pointFromScalar(Uint8List d, bool compress) {
  if (!isPrivate(d)) throw ArgumentError("Bad Private");
  BigInt dd = decodeBigInt(d);
  ECPoint pp = (G * dd) as ECPoint;
  if (pp.isInfinity) return null;
  return pp.getEncoded(compress);
}
