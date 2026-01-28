import 'package:blockchain_utils/crypto/crypto/exception/exception.dart';
import 'package:blockchain_utils/exception/exception/exception.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';

import 'package:blockchain_utils/crypto/crypto/hash/hash.dart';
import 'package:blockchain_utils/utils/binary/binary_operation.dart';

class StrobeSecParam {
  /// 128-bit security level
  static const StrobeSecParam sec128 = StrobeSecParam._(128);

  /// 256-bit security level
  static const StrobeSecParam sec256 = StrobeSecParam._(256);

  final int value;

  /// Constructor for creating a StrobeSecParam enum value with the specified security level.
  const StrobeSecParam._(this.value);
}

/// Class representing Strobe operation flags.
class StrobeFlags {
  /// Flag indicating an initiation operation.
  static const int I = 1;

  /// Flag indicating an "AD" (associated data) operation.
  static const int A = 2;

  /// Flag indicating a "cipher" operation.
  static const int C = 4;

  static const int T = 8;

  /// Flag indicating a "meta-ad" operation.
  static const int M = 16;

  /// Flag indicating a "key" operation.
  static const int K = 32;
}

/// enum representing Strobe operations.
class StrobeOperation {
  /// Provide associated data
  static const StrobeOperation ad = StrobeOperation._(StrobeFlags.A);

  /// Provide cipher key
  static const StrobeOperation key = StrobeOperation._(
    StrobeFlags.A | StrobeFlags.C,
  );

  /// Pseudo-Random Function (I | A | C)
  static const StrobeOperation prf = StrobeOperation._(
    StrobeFlags.I | StrobeFlags.A | StrobeFlags.C,
  );

  /// Send cleartext data
  static const StrobeOperation sendClr = StrobeOperation._(
    StrobeFlags.A | StrobeFlags.T,
  );

  /// Receive cleartext data
  static const StrobeOperation recvClr = StrobeOperation._(
    StrobeFlags.I | StrobeFlags.A | StrobeFlags.T,
  );

  /// Send encrypted data
  static const StrobeOperation sendEnc = StrobeOperation._(
    StrobeFlags.A | StrobeFlags.C | StrobeFlags.T,
  );

  /// Receive encrypted data
  static const StrobeOperation recvEnc = StrobeOperation._(
    StrobeFlags.I | StrobeFlags.A | StrobeFlags.C | StrobeFlags.T,
  );

  /// Send message authentication code
  static const StrobeOperation sendMac = StrobeOperation._(
    StrobeFlags.C | StrobeFlags.T,
  );

  /// Receive message authentication code
  static const StrobeOperation recvMac = StrobeOperation._(
    StrobeFlags.I | StrobeFlags.C | StrobeFlags.T,
  );

  /// Prevent rollback
  static const StrobeOperation ratchet = StrobeOperation._(StrobeFlags.C);

  final int value;

  const StrobeOperation._(this.value);
}

/// Strobe is a cryptographic framework for building secure, stateful, and authenticated cryptographic protocols.
/// Strobe-128/1600 and Strobe-256/1600 for standards compliance.
class Strobe {
  final keccack = Keccack();
  static const String version = "STROBEv1.0.2";

  Strobe._({
    required this.rate,
    required this.strober,
    required int io,
    int curFlags = 0,
    required int posBegin,
    bool initialized = false,
    List<int> buffer = const [],
    List<int> storage = const [],
    List<int>? state,
  }) : _initialized = initialized,
       _st = storage,
       _buffer = buffer,
       _curFlags = curFlags,
       _posBegin = posBegin,
       _io = io,
       _state =
           state == null
               ? List<int>.filled(200, 0)
               : List.from(state, growable: false);

  final int rate;
  final int strober;

  bool _initialized = false;
  int _posBegin;
  int _io;

  int _curFlags;
  // state
  final List<int> _state;
  List<int> _buffer;
  final List<int> _st;

  Strobe clone() {
    return Strobe._(
      rate: rate,
      strober: strober,
      io: _io,
      posBegin: _posBegin,
      buffer: List.from(_buffer),
      curFlags: _curFlags,
      initialized: _initialized,
      storage: List.from(_st),
      state: List.from(_state),
    );
  }

  /// Create a new instance of the Strobe protocol with the specified parameters.
  ///
  /// Parameters:
  /// - [customizationString]: A string used to customize the Strobe instance.
  /// - [security]: The desired security level, which can be either 128 or 256 bits.
  ///
  /// Throws:
  /// - [CryptoException] if the [security] level is not 128 or 256 bits, indicating an invalid security level.
  ///
  factory Strobe(String customizationString, StrobeSecParam security) {
    final int rate = (1600 ~/ 8) - security.value ~/ 4;
    final Strobe s = Strobe._(
      io: 2,
      rate: rate,
      strober: rate - 2,
      posBegin: 0,
      curFlags: 0,
      storage: List<int>.filled(rate, 0),
      buffer: List.empty(growable: true),
    );
    final List<int> domain = [1, rate, 1, 0, 1, 12 * 8];
    domain.addAll(version.codeUnits);

    s._duplex(domain, false, false, true);

    s._initialized = true;
    s.operate(
      true,
      StrobeOperation.ad,
      customizationString.codeUnits,
      0,
      false,
    );

    return s;
  }

  /// Runs the permutation function on the internal state
  void _run() {
    if (_initialized) {
      if (_buffer.length > strober) {
        throw CryptoException.failed(
          "Strobe",
          reason: "Buffer is never supposed to reach strober",
        );
      }
      _buffer.add(_posBegin);
      _buffer.add(0x04);
      _st.setAll(0, _buffer);
      final int zerosStart = _buffer.length;
      _buffer = _st.sublist(0, rate);
      for (int i = zerosStart; i < rate; i++) {
        _buffer[i] = 0;
      }
      _buffer[rate - 1] ^= 0x80;
      _st.setAll(0, _buffer);
      _xor(_state, _buffer);
    } else if (_buffer.isNotEmpty) {
      final int zerosStart = _buffer.length;
      _buffer = _st.sublist(0, rate);
      for (int i = zerosStart; i < rate; i++) {
        _buffer[i] = 0;
      }

      _xor(_state, _buffer);
    }
    keccack.keccackF1600(_state);

    _buffer.clear();

    _posBegin = 0;
  }

  /// Adjust direction information so that sender and receiver agree
  void _op(int flags) {
    if (flags & StrobeFlags.T != 0) {
      if (_io == 2) {
        _io = flags & StrobeFlags.I;
      }
      flags ^= _io;
    }
    final oldBegin = _posBegin;
    _posBegin = (_buffer.length + 1) & BinaryOps.mask8; // s.pos + 1
    final forceF = (flags & (StrobeFlags.C | StrobeFlags.K) != 0);
    _duplex([oldBegin, flags], false, false, forceF);
  }

  /// STROBE main duplexing mode.
  void _duplex(List<int> data, bool cbefore, bool cafter, bool forceF) {
    int todo;

    while (data.isNotEmpty) {
      todo = strober - _buffer.length;
      if (todo > data.length) {
        todo = data.length;
      }

      if (cbefore) {
        for (int idx = 0; idx < todo; idx++) {
          data[idx] ^= _state[_buffer.length + idx];
        }
      }

      _buffer.addAll(data.sublist(0, todo));
      _st.setAll(0, _buffer);

      if (cafter) {
        for (int idx = 0; idx < todo; idx++) {
          data[idx] ^= _state[_buffer.length - todo + idx];
        }
      }
      data = data.sublist(todo);

      if (_buffer.length == strober) {
        _run();
      }
    }

    if (forceF && _buffer.isNotEmpty) {
      _run();
    }
  }

  void _xor(List<int> state, List<int> b) {
    assert(b.length == 168);
    for (int i = 0; i < b.length; i++) {
      state[i] = (state[i] ^ b[i]) & BinaryOps.mask8;
    }
  }

  /// STROBE main duplexing mode.
  List<int> operate(
    bool meta,
    StrobeOperation operation,
    List<int> dataConst,
    int length,
    bool more,
  ) {
    int flags = operation.value;

    if (meta) {
      flags |= StrobeFlags.M;
    }

    List<int> data;
    if (((flags & (StrobeFlags.I | StrobeFlags.T)) !=
            (StrobeFlags.I | StrobeFlags.T)) &&
        ((flags & (StrobeFlags.I | StrobeFlags.A)) != StrobeFlags.A)) {
      if (length == 0) {
        throw ArgumentException.invalidOperationArguments(
          "operate",
          name: "length",
          reason: "A length should be set for this operation.",
        );
      }
      data = List<int>.filled(length, 0);
    } else {
      if (length != 0) {
        throw ArgumentException.invalidOperationArguments(
          "operate",
          name: "length",
          reason:
              "Output length must be zero except for PRF, send_MAC, and RATCHET operations.",
        );
      }
      data = dataConst.clone();
    }
    if (more) {
      if (flags != _curFlags) {
        throw ArgumentException.invalidOperationArguments(
          "operate",
          name: "length",
          reason: "Flag should be the same when streaming operations.",
        );
      }
    } else {
      // If [more] isn't set, this is a new operation. Do the begin_op sequence
      _op(flags);
      _curFlags = flags;
    }

    // Operation
    final bool cAfter =
        ((flags & (StrobeFlags.C | StrobeFlags.I | StrobeFlags.T)) ==
            (StrobeFlags.C | StrobeFlags.T));
    final bool cBefore = ((flags & StrobeFlags.C) != 0) && (!cAfter);

    _duplex(data, cBefore, cAfter, false);
    if ((flags & (StrobeFlags.I | StrobeFlags.A)) ==
        (StrobeFlags.I | StrobeFlags.A)) {
      return data;
    } else if ((flags & (StrobeFlags.I | StrobeFlags.T)) == StrobeFlags.T) {
      return data;
    } else if ((flags & (StrobeFlags.I | StrobeFlags.A | StrobeFlags.T)) ==
        (StrobeFlags.I | StrobeFlags.T)) {
      if (more) {
        throw ArgumentException.invalidOperationArguments(
          "operate",
          name: "more",
          reason:
              "Not supposed to check a MAC with the 'more' streaming option.",
        );
      }
      int failures = 0;
      for (final dataByte in data) {
        failures |= dataByte;
      }
      return [failures]; // 0 if correct, 1 if not
    }

    return List.empty();
  }

  /// Set a key for the Strobe protocol.
  ///
  /// Parameters:
  /// - [key]: Representing the key to be set.
  ///
  void key(List<int> key) {
    operate(false, StrobeOperation.key, key, 0, false);
  }

  /// Generate pseudo-random data using the PRF operation in Strobe.
  ///
  /// Parameters:
  /// - [outputLen]: The length (in bytes) of the pseudo-random data to generate.
  ///
  List<int> pseudoRandomData(int outputLen) {
    return operate(false, StrobeOperation.prf, List.empty(), outputLen, false);
  }

  /// Encrypt and send data without authentication in Strobe.
  ///
  /// Parameters:
  /// - [meta]: A boolean flag indicating whether metadata is included in the operation.
  /// - [plaintext]: The plaintext data to be encrypted and sent.
  ///
  List<int> sendUnauthenticatedEncryptedMessage(
    bool meta,
    List<int> plaintext,
  ) {
    return operate(meta, StrobeOperation.sendEnc, plaintext, 0, false);
  }

  /// Receive and process an unauthenticated encrypted message in Strobe.
  ///
  /// Parameters:
  /// - [meta]: A boolean flag indicating whether metadata is included in the operation.
  /// - [ciphertext]: The ciphertext to be received and decrypted.
  ///
  List<int> recvUnauthenticatedEncryptMessage(bool meta, List<int> ciphertext) {
    return operate(meta, StrobeOperation.recvEnc, ciphertext, 0, false);
  }

  /// Process and add additional data to the Strobe protocol state.
  ///
  /// Parameters:
  /// - [meta]: A boolean flag indicating whether metadata is included in the operation.
  /// - [additionalData]: A list of integers containing the additional data to be processed and added.
  ///
  void additionalData(bool meta, List<int> additionalData) {
    operate(meta, StrobeOperation.ad, additionalData, 0, false);
  }

  /// Process and send clear text data within the Strobe protocol.
  ///
  /// Parameters:
  /// - [meta]: A boolean flag indicating whether metadata is included in the operation.
  /// - [cleartext]: A [List<int>] containing the clear text data to be processed and sent.
  ///
  void sendClearText(bool meta, List<int> cleartext) {
    operate(meta, StrobeOperation.sendClr, cleartext, 0, false);
  }

  /// Process received clear text within the Strobe protocol.
  ///
  /// Parameters:
  /// - [meta]: A boolean flag indicating whether metadata is included in the operation.
  /// - [cleartext]: A [List<int>] containing the received clear text data to be processed.
  ///
  void receivedClearText(bool meta, List<int> cleartext) {
    operate(meta, StrobeOperation.recvClr, cleartext, 0, false);
  }

  /// Generate and append a Message Authentication Code (MAC) to data in the Strobe protocol.
  ///
  /// Parameters:
  /// - [meta]: A boolean flag indicating whether metadata is included in the operation.
  /// - [outputLength]: The desired output length of the generated MAC.
  ///
  List<int> sendMac(bool meta, int outputLength) {
    return operate(
      meta,
      StrobeOperation.sendMac,
      List.empty(),
      outputLength,
      false,
    );
  }

  /// Verify and process a received MAC in the Strobe protocol.
  ///
  /// Parameters:
  /// - [meta]: A boolean flag indicating whether metadata is included in the operation.
  /// - [mac]: The received MAC to be verified.
  ///
  bool receivedMac(bool meta, List<int> mac) {
    return operate(meta, StrobeOperation.recvMac, mac, 0, false)[0] == 0;
  }

  /// Ratchet the Strobe protocol state to enhance security.
  ///
  /// Parameters:
  /// - [length]: The length of the key material to derive during the ratchet operation.
  ///
  void ratchet(int length) {
    operate(false, StrobeOperation.ratchet, List.empty(), length, false);
  }
}
