// import 'dart:typed_data';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:blockchain_utils/exception/exception.dart';

const _digestLength = 16;

/// The `Poly1305` class represents an implementation of the Poly1305 one-time message authentication code (MAC).
///
/// Poly1305 is a fast and secure MAC algorithm used for data integrity verification and authentication.
/// The algorithm produces a fixed-size digest of 16 bytes.
class Poly1305 {
  /// The length of the Poly1305 digest (always 16 bytes).
  final int digestLength = _digestLength;

  /// A buffer for temporary data storage.
  final List<int> _buffer = List<int>.filled(16, 0);
  final List<int> _r = List<int>.filled(10, 0);
  final List<int> _h = List<int>.filled(10, 0);
  final List<int> _pad = List<int>.filled(8, 0);
  int _leftover = 0;
  int _fin = 0;
  bool _finished = false;

  /// Constructor for the `Poly1305` class.
  ///
  /// This constructor initializes the Poly1305 instance with a provided key and sets up the necessary data structures
  /// for Poly1305 calculations.
  ///
  /// Parameters:
  /// - `key`: A `List<int>` containing the key used for Poly1305 authentication and data integrity verification.
  Poly1305(List<int> key) {
    /// Initialize the Poly1305 instance with the provided key.
    _init(key);
  }
  void _init(List<int> key) {
    int t0 = key[0] | (key[1] << 8);
    _r[0] = (t0) & mask13;
    int t1 = key[2] | (key[3] << 8);
    _r[1] = ((t0 >> 13) | (t1 << 3)) & mask13;
    int t2 = key[4] | (key[5] << 8);
    _r[2] = ((t1 >> 10) | (t2 << 6)) & 0x1f03;
    int t3 = key[6] | (key[7] << 8);
    _r[3] = ((t2 >> 7) | (t3 << 9)) & mask13;
    int t4 = key[8] | (key[9] << 8);
    _r[4] = ((t3 >> 4) | (t4 << 12)) & 0x00ff;
    _r[5] = ((t4 >> 1)) & 0x1ffe;
    int t5 = key[10] | (key[11] << 8);
    _r[6] = ((t4 >> 14) | (t5 << 2)) & mask13;
    int t6 = key[12] | (key[13] << 8);
    _r[7] = ((t5 >> 11) | (t6 << 5)) & 0x1f81;
    int t7 = key[14] | (key[15] << 8);
    _r[8] = ((t6 >> 8) | (t7 << 8)) & mask13;
    _r[9] = ((t7 >> 5)) & 0x007f;
    _pad[0] = key[16] | (key[17] << 8);
    _pad[1] = key[18] | (key[19] << 8);
    _pad[2] = key[20] | (key[21] << 8);
    _pad[3] = key[22] | (key[23] << 8);
    _pad[4] = key[24] | (key[25] << 8);
    _pad[5] = key[26] | (key[27] << 8);
    _pad[6] = key[28] | (key[29] << 8);
    _pad[7] = key[30] | (key[31] << 8);
  }

  void _blocks(List<int> m, int mpos, int bytes) {
    final hibit = _fin != 0 ? 0 : 1 << 11;
    int h0 = _h[0],
        h1 = _h[1],
        h2 = _h[2],
        h3 = _h[3],
        h4 = _h[4],
        h5 = _h[5],
        h6 = _h[6],
        h7 = _h[7],
        h8 = _h[8],
        h9 = _h[9];

    int r0 = _r[0],
        r1 = _r[1],
        r2 = _r[2],
        r3 = _r[3],
        r4 = _r[4],
        r5 = _r[5],
        r6 = _r[6],
        r7 = _r[7],
        r8 = _r[8],
        r9 = _r[9];

    while (bytes >= 16) {
      final t0 = m[mpos] | m[mpos + 1] << 8;
      h0 += (t0) & mask13;
      final t1 = m[mpos + 2] | m[mpos + 3] << 8;
      h1 += ((t0 >> 13) | (t1 << 3)) & mask13;
      final t2 = m[mpos + 4] | m[mpos + 5] << 8;
      h2 += ((t1 >> 10) | (t2 << 6)) & mask13;
      final t3 = m[mpos + 6] | m[mpos + 7] << 8;
      h3 += ((t2 >> 7) | (t3 << 9)) & mask13;
      final t4 = m[mpos + 8] | m[mpos + 9] << 8;
      h4 += ((t3 >> 4) | (t4 << 12)) & mask13;
      h5 += ((t4 >> 1)) & mask13;
      final t5 = m[mpos + 10] | m[mpos + 11] << 8;
      h6 += ((t4 >> 14) | (t5 << 2)) & mask13;
      final t6 = m[mpos + 12] | m[mpos + 13] << 8;
      h7 += ((t5 >> 11) | (t6 << 5)) & mask13;
      final t7 = m[mpos + 14] | m[mpos + 15] << 8;
      h8 += ((t6 >> 8) | (t7 << 8)) & mask13;
      h9 += ((t7 >> 5)) | hibit;

      var c = 0;

      var d0 = c;
      d0 += h0 * r0;
      d0 += h1 * (5 * r9);
      d0 += h2 * (5 * r8);
      d0 += h3 * (5 * r7);
      d0 += h4 * (5 * r6);
      c = (d0 >> 13);
      d0 &= mask13;
      d0 += h5 * (5 * r5);
      d0 += h6 * (5 * r4);
      d0 += h7 * (5 * r3);
      d0 += h8 * (5 * r2);
      d0 += h9 * (5 * r1);
      c += (d0 >> 13);
      d0 &= mask13;

      var d1 = c;
      d1 += h0 * r1;
      d1 += h1 * r0;
      d1 += h2 * (5 * r9);
      d1 += h3 * (5 * r8);
      d1 += h4 * (5 * r7);
      c = (d1 >> 13);
      d1 &= mask13;
      d1 += h5 * (5 * r6);
      d1 += h6 * (5 * r5);
      d1 += h7 * (5 * r4);
      d1 += h8 * (5 * r3);
      d1 += h9 * (5 * r2);
      c += (d1 >> 13);
      d1 &= mask13;

      var d2 = c;
      d2 += h0 * r2;
      d2 += h1 * r1;
      d2 += h2 * r0;
      d2 += h3 * (5 * r9);
      d2 += h4 * (5 * r8);
      c = (d2 >> 13);
      d2 &= mask13;
      d2 += h5 * (5 * r7);
      d2 += h6 * (5 * r6);
      d2 += h7 * (5 * r5);
      d2 += h8 * (5 * r4);
      d2 += h9 * (5 * r3);
      c += (d2 >> 13);
      d2 &= mask13;

      var d3 = c;
      d3 += h0 * r3;
      d3 += h1 * r2;
      d3 += h2 * r1;
      d3 += h3 * r0;
      d3 += h4 * (5 * r9);
      c = (d3 >> 13);
      d3 &= mask13;
      d3 += h5 * (5 * r8);
      d3 += h6 * (5 * r7);
      d3 += h7 * (5 * r6);
      d3 += h8 * (5 * r5);
      d3 += h9 * (5 * r4);
      c += (d3 >> 13);
      d3 &= mask13;

      var d4 = c;
      d4 += h0 * r4;
      d4 += h1 * r3;
      d4 += h2 * r2;
      d4 += h3 * r1;
      d4 += h4 * r0;
      c = (d4 >> 13);
      d4 &= mask13;
      d4 += h5 * (5 * r9);
      d4 += h6 * (5 * r8);
      d4 += h7 * (5 * r7);
      d4 += h8 * (5 * r6);
      d4 += h9 * (5 * r5);
      c += (d4 >> 13);
      d4 &= mask13;

      var d5 = c;
      d5 += h0 * r5;
      d5 += h1 * r4;
      d5 += h2 * r3;
      d5 += h3 * r2;
      d5 += h4 * r1;
      c = (d5 >> 13);
      d5 &= mask13;
      d5 += h5 * r0;
      d5 += h6 * (5 * r9);
      d5 += h7 * (5 * r8);
      d5 += h8 * (5 * r7);
      d5 += h9 * (5 * r6);
      c += (d5 >> 13);
      d5 &= mask13;

      var d6 = c;
      d6 += h0 * r6;
      d6 += h1 * r5;
      d6 += h2 * r4;
      d6 += h3 * r3;
      d6 += h4 * r2;
      c = (d6 >> 13);
      d6 &= mask13;
      d6 += h5 * r1;
      d6 += h6 * r0;
      d6 += h7 * (5 * r9);
      d6 += h8 * (5 * r8);
      d6 += h9 * (5 * r7);
      c += (d6 >> 13);
      d6 &= mask13;

      var d7 = c;
      d7 += h0 * r7;
      d7 += h1 * r6;
      d7 += h2 * r5;
      d7 += h3 * r4;
      d7 += h4 * r3;
      c = (d7 >> 13);
      d7 &= mask13;
      d7 += h5 * r2;
      d7 += h6 * r1;
      d7 += h7 * r0;
      d7 += h8 * (5 * r9);
      d7 += h9 * (5 * r8);
      c += (d7 >> 13);
      d7 &= mask13;

      var d8 = c;
      d8 += h0 * r8;
      d8 += h1 * r7;
      d8 += h2 * r6;
      d8 += h3 * r5;
      d8 += h4 * r4;
      c = (d8 >> 13);
      d8 &= mask13;
      d8 += h5 * r3;
      d8 += h6 * r2;
      d8 += h7 * r1;
      d8 += h8 * r0;
      d8 += h9 * (5 * r9);
      c += (d8 >> 13);
      d8 &= mask13;

      var d9 = c;
      d9 += h0 * r9;
      d9 += h1 * r8;
      d9 += h2 * r7;
      d9 += h3 * r6;
      d9 += h4 * r5;
      c = (d9 >> 13);
      d9 &= mask13;
      d9 += h5 * r4;
      d9 += h6 * r3;
      d9 += h7 * r2;
      d9 += h8 * r1;
      d9 += h9 * r0;
      c += (d9 >> 13);
      d9 &= mask13;

      c = (((c << 2) + c)) | 0;
      c = (c + d0) | 0;
      d0 = c & mask13;
      c = (c >> 13);
      d1 += c;

      h0 = d0;
      h1 = d1;
      h2 = d2;
      h3 = d3;
      h4 = d4;
      h5 = d5;
      h6 = d6;
      h7 = d7;
      h8 = d8;
      h9 = d9;

      mpos += 16;
      bytes -= 16;
    }

    _h[0] = h0;
    _h[1] = h1;
    _h[2] = h2;
    _h[3] = h3;
    _h[4] = h4;
    _h[5] = h5;
    _h[6] = h6;
    _h[7] = h7;
    _h[8] = h8;
    _h[9] = h9;
  }

  /// Finalizes the Poly1305 authentication process and computes the authentication code (MAC).
  ///
  /// This method completes the Poly1305 authentication operation, producing the message authentication code (MAC).
  ///
  /// Parameters:
  /// - `mac`: A `List<int>` to store the computed MAC.
  /// - `macpos`: An optional parameter that specifies the starting position within the `mac` buffer to store the MAC.
  ///
  /// Returns:
  /// A reference to the `Poly1305` instance, allowing method chaining if needed.
  ///
  /// This method is used to complete the Poly1305 authentication, and the resulting MAC is stored in the `mac` buffer.
  Poly1305 finish(List<int> mac, [int macpos = 0]) {
    final g = List<int>.filled(10, 0);
    int c;
    int mask;
    int f;
    int i;

    if (_leftover != 0) {
      i = _leftover;
      _buffer[i++] = 1;
      for (; i < 16; i++) {
        _buffer[i] = 0;
      }
      _fin = 1;
      _blocks(_buffer, 0, 16);
    }

    c = _h[1] >> 13;
    _h[1] &= mask13;
    for (i = 2; i < 10; i++) {
      _h[i] += c;
      c = _h[i] >> 13;
      _h[i] &= mask13;
    }
    _h[0] += (c * 5);
    c = _h[0] >> 13;
    _h[0] &= mask13;
    _h[1] += c;
    c = _h[1] >> 13;
    _h[1] &= mask13;
    _h[2] += c;

    g[0] = _h[0] + 5;
    c = g[0] >> 13;
    g[0] &= mask13;
    for (i = 1; i < 10; i++) {
      g[i] = _h[i] + c;
      c = g[i] >> 13;
      g[i] &= mask13;
    }
    g[9] -= (1 << 13);

    mask = (c ^ 1) - 1;
    for (i = 0; i < 10; i++) {
      g[i] &= mask;
    }
    mask = ~mask;
    for (i = 0; i < 10; i++) {
      _h[i] = (_h[i] & mask) | g[i];
    }

    _h[0] = ((_h[0]) | (_h[1] << 13)) & mask16;
    _h[1] = ((_h[1] >> 3) | (_h[2] << 10)) & mask16;
    _h[2] = ((_h[2] >> 6) | (_h[3] << 7)) & mask16;
    _h[3] = ((_h[3] >> 9) | (_h[4] << 4)) & mask16;
    _h[4] = ((_h[4] >> 12) | (_h[5] << 1) | (_h[6] << 14)) & mask16;
    _h[5] = ((_h[6] >> 2) | (_h[7] << 11)) & mask16;
    _h[6] = ((_h[7] >> 5) | (_h[8] << 8)) & mask16;
    _h[7] = ((_h[8] >> 8) | (_h[9] << 5)) & mask16;

    f = _h[0] + _pad[0];
    _h[0] = f & mask16;
    for (i = 1; i < 8; i++) {
      f = (((_h[i] + _pad[i]) | 0) + (f >> 16)) | 0;
      _h[i] = f & mask16;
    }
    for (int i = 0; i < 8; i++) {
      writeUint16LE(_h[i], mac, i * 2);
    }

    _finished = true;
    return this;
  }

  /// Updates the Poly1305 authentication state with additional data from the given `List<int>`.
  ///
  /// This method incorporates more data into the Poly1305 authentication process, allowing it to be computed incrementally.
  ///
  /// Parameters:
  /// - `data`: A `List<int>` containing the additional data to be included in the authentication calculation.
  ///
  /// Returns:
  /// A reference to the `Poly1305` instance, enabling method chaining for convenience.
  ///
  /// This method extends the Poly1305 authentication state with the provided data from `data`.
  Poly1305 update(List<int> data) {
    int mpos = 0;
    int bytes = data.length;
    int want;
    if (_leftover != 0) {
      want = (16 - _leftover);
      if (want > bytes) {
        want = bytes;
      }
      for (int i = 0; i < want; i++) {
        _buffer[_leftover + i] = data[mpos + i] & mask8;
      }
      bytes -= want;
      mpos += want;
      _leftover += want;
      if (_leftover < 16) {
        return this;
      }
      _blocks(_buffer, 0, 16);
      _leftover = 0;
    }

    if (bytes >= 16) {
      want = bytes - (bytes % 16);
      _blocks(data, mpos, want);
      mpos += want;
      bytes -= want;
    }

    if (bytes > 0) {
      for (int i = 0; i < bytes; i++) {
        _buffer[_leftover + i] = data[mpos + i] & mask8;
      }
      _leftover += bytes;
    }

    return this;
  }

  /// Computes and returns the Poly1305 message authentication code (MAC) for the current state.
  ///
  /// This method finalizes the Poly1305 authentication and produces the authentication code (MAC) based on
  /// the current state of the instance. After calling this method, further updates or finishing operations
  /// are not allowed.
  ///
  /// Returns:
  /// A `List<int>` containing the computed Poly1305 message authentication code (MAC).
  ///
  /// Throws:
  /// - `StateError` if the `Poly1305` instance was already finished before calling `digest`.
  ///
  /// This method is used to obtain the final MAC from the current Poly1305 state, and it should not be called
  /// after the `Poly1305` instance has been finished.
  List<int> digest() {
    if (_finished) {
      throw const MessageException("Poly1305 was finished");
    }
    List<int> mac = List<int>.filled(16, 0);
    finish(mac);
    return mac;
  }

  /// Cleans up and resets the internal state of the Poly1305 instance.
  ///
  /// This method is used to securely clear sensitive data and prepare the instance for reuse or disposal.
  ///
  /// Returns:
  /// A reference to the `Poly1305` instance, allowing method chaining if needed.
  ///
  /// This method zeros and resets the internal buffers, counters, and flags of the Poly1305 instance
  /// to ensure that sensitive data is securely cleared and the instance is marked as finished.
  Poly1305 clean() {
    zero(_buffer);
    zero(_r);
    zero(_h);
    zero(_pad);
    _leftover = 0;
    _fin = 0;
    _finished = true;
    return this;
  }

  /// Computes a Poly1305 authentication code (MAC) for the provided data using the given key.
  ///
  /// This static method simplifies the process of generating a Poly1305 authentication code (MAC) for a
  /// specific data set and key.
  ///
  /// Parameters:
  /// - `key`: A `List<int>` representing the key used for Poly1305 authentication.
  /// - `data`: A `List<int>` containing the data to be authenticated.
  ///
  /// Returns:
  /// A `List<int>` containing the computed Poly1305 authentication code (MAC).
  ///
  /// This method creates a `Poly1305` instance initialized with the provided key, updates it with the data,
  /// computes the MAC, and then cleans up the instance before returning the MAC.
  static List<int> auth(List<int> key, List<int> data) {
    Poly1305 h = Poly1305(key);
    h.update(data);
    List<int> digest = h.digest();
    h.clean();
    return digest;
  }
}
