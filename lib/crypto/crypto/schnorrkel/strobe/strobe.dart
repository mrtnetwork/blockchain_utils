import 'package:blockchain_utils/utils/utils.dart';
import 'package:blockchain_utils/crypto/crypto/hash/hash.dart';
import 'package:blockchain_utils/exception/exceptions.dart';

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
  static const StrobeOperation key =
      StrobeOperation._(StrobeFlags.A | StrobeFlags.C);

  /// Pseudo-Random Function (I | A | C)
  static const StrobeOperation prf =
      StrobeOperation._(StrobeFlags.I | StrobeFlags.A | StrobeFlags.C);

  /// Send cleartext data
  static const StrobeOperation sendClr =
      StrobeOperation._(StrobeFlags.A | StrobeFlags.T);

  /// Receive cleartext data
  static const StrobeOperation recvClr =
      StrobeOperation._(StrobeFlags.I | StrobeFlags.A | StrobeFlags.T);

  /// Send encrypted data
  static const StrobeOperation sendEnc =
      StrobeOperation._(StrobeFlags.A | StrobeFlags.C | StrobeFlags.T);

  /// Receive encrypted data
  static const StrobeOperation recvEnc = StrobeOperation._(
      StrobeFlags.I | StrobeFlags.A | StrobeFlags.C | StrobeFlags.T);

  /// Send message authentication code
  static const StrobeOperation sendMac =
      StrobeOperation._(StrobeFlags.C | StrobeFlags.T);

  /// Receive message authentication code
  static const StrobeOperation recvMac =
      StrobeOperation._(StrobeFlags.I | StrobeFlags.C | StrobeFlags.T);

  /// Prevent rollback
  static const StrobeOperation ratchet = StrobeOperation._(StrobeFlags.C);

  final int value;

  const StrobeOperation._(this.value);
}

/// Strobe is a cryptographic framework for building secure, stateful, and authenticated cryptographic protocols.
/// Strobe-128/1600 and Strobe-256/1600 for standards compliance.
class Strobe {
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
  })  : _initialized = initialized,
        _st = storage,
        _buffer = buffer,
        _curFlags = curFlags,
        _posBegin = posBegin,
        _io = io,
        _state = state == null
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
        state: List.from(_state));
  }

  /// Create a new instance of the Strobe protocol with the specified parameters.
  ///
  /// This factory constructor is used to initialize a Strobe instance with the given `customizationString` and `security` level. It performs the necessary setup and configuration for the Strobe protocol with the specified security level.
  ///
  /// Parameters:
  /// - `customizationString`: A string used to customize the Strobe instance.
  /// - `security`: The desired security level, which can be either 128 or 256 bits.
  ///
  /// Returns:
  /// A new Strobe instance configured with the provided `customizationString` and `security` level.
  ///
  /// Throws:
  /// - `ArgumentException` if the `security` level is not 128 or 256 bits, indicating an invalid security level.
  ///
  /// Example Usage:
  /// ```dart
  /// Strobe strobeInstance = Strobe("MyCustomizationString", 128);
  /// ```
  ///
  /// This factory constructor ensures that the Strobe instance is properly initialized and configured based on the provided parameters, allowing it to be used for secure protocol operations.
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
        true, StrobeOperation.ad, customizationString.codeUnits, 0, false);

    return s;
  }

  /// Runs the permutation function on the internal state
  void _run() {
    if (_initialized) {
      if (_buffer.length > strober) {
        throw const MessageException(
            "strobe: buffer is never supposed to reach strobeR");
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
    Keccack.keccackF1600(_state);

    // _temp.setAll(0, _state.sublist(0, _temp.length));
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
    _posBegin = (_buffer.length + 1) & mask8; // s.pos + 1
    final forceF = (flags & (StrobeFlags.C | StrobeFlags.K) != 0);
    _duplex(List<int>.from([oldBegin, flags]), false, false, forceF);
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
        // _temp.setAll(0, _state.sublist(0, _temp.length));

        for (int idx = 0; idx < todo; idx++) {
          data[idx] ^= _state[_buffer.length + idx];
        }
      }

      _buffer.addAll(data.sublist(0, todo));
      _st.setAll(0, _buffer);

      if (cafter) {
        // _temp.setAll(0, _state.sublist(0, _temp.length));
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
      state[i] = (state[i] ^ b[i]) & mask8;
    }
  }

  /// STROBE main duplexing mode.
  List<int> operate(bool meta, StrobeOperation operation, List<int> dataConst,
      int length, bool more) {
    int flags = operation.value;

    if (meta) {
      flags |= StrobeFlags.M;
    }

    List<int> data;
    if (((flags & (StrobeFlags.I | StrobeFlags.T)) !=
            (StrobeFlags.I | StrobeFlags.T)) &&
        ((flags & (StrobeFlags.I | StrobeFlags.A)) != StrobeFlags.A)) {
      if (length == 0) {
        throw const MessageException(
            "A length should be set for this operation.");
      }
      data = List<int>.filled(length, 0);
    } else {
      if (length != 0) {
        throw const MessageException(
            "Output length must be zero except for PRF, send_MAC, and RATCHET operations.");
      }
      data = List<int>.from(dataConst);
    }
    if (more) {
      if (flags != _curFlags) {
        throw const MessageException(
            "Flag should be the same when streaming operations.");
      }
    } else {
      // If `more` isn't set, this is a new operation. Do the begin_op sequence
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
        throw const MessageException(
            "Not supposed to check a MAC with the 'more' streaming option");
      }
      int failures = 0;
      for (final dataByte in data) {
        failures |= dataByte;
      }
      return List<int>.from([failures]); // 0 if correct, 1 if not
    }

    return List.empty();
  }

  /// Set a key for the Strobe protocol.
  ///
  /// The `key` method is used to set a key for the Strobe protocol. This key can be used for cryptographic operations within the protocol.
  ///
  /// Parameters:
  /// - `key`: A `List<int>` representing the key to be set.
  ///
  /// Usage:
  /// ```dart
  /// `List<int>` secretKey = ...; // Your secret key.
  /// strobeInstance.key(secretKey);
  /// // Set the secret key for cryptographic operations.
  /// ```
  ///
  /// This method is essential for initializing the Strobe protocol with the required key material for secure communication.
  void key(List<int> key) {
    operate(false, StrobeOperation.key, key, 0, false);
  }

  /// Generate pseudo-random data using the PRF operation in Strobe.
  ///
  /// The `pseudoRandomData` method is used to generate pseudo-random data by invoking the PRF (Pseudo-Random Function)
  /// operation in the Strobe protocol. PRF generates cryptographically secure random bytes that can be used for various purposes,
  /// such as key derivation or secure random number generation.
  ///
  /// Parameters:
  /// - `outputLen`: The length (in bytes) of the pseudo-random data to generate.
  ///
  /// Returns:
  /// - A `List<int>` containing the generated pseudo-random data.
  ///
  /// Usage:
  /// ```dart
  /// int outputLength = 32; // Length of the desired pseudo-random data.
  /// `List<int>` randomData = strobeInstance.pseudoRandomData(outputLength);
  /// // Generate pseudo-random data for a specific use case.
  /// ```
  ///
  /// The `pseudoRandomData` method is suitable for generating random data with high entropy,
  /// making it suitable for cryptographic applications.
  List<int> pseudoRandomData(int outputLen) {
    return operate(false, StrobeOperation.prf, List.empty(), outputLen, false);
  }

  /// Encrypt and send data without authentication in Strobe.
  ///
  /// The `sendUnauthenticatedEncryptedMessage` method is used to encrypt and send data without authentication in the Strobe protocol.
  /// This operation is typically used for secure communication where confidentiality is the primary concern,
  /// and data integrity is not strictly required. The method encrypts the provided plaintext,
  /// updates the internal state of the Strobe instance, and returns the ciphertext.
  ///
  /// Parameters:
  /// - `meta`: A boolean flag indicating whether metadata is included in the operation.
  /// - `plaintext`: The plaintext data to be encrypted and sent.
  ///
  /// Returns:
  /// - A `List<int>` containing the ciphertext for the provided plaintext.
  ///
  /// Usage:
  /// ```dart
  /// `List<int>` plaintext = ...; // Data to be encrypted and sent.
  /// `List<int>` ciphertext = strobeInstance.sendEncUnauthenticated(true, plaintext);
  /// // Encrypt and send data without authentication.
  /// ```
  ///
  /// The `sendUnauthenticatedEncryptedMessage` method is suitable for use cases where data confidentiality is the primary concern, and data integrity can be ensured through other means.
  List<int> sendUnauthenticatedEncryptedMessage(
      bool meta, List<int> plaintext) {
    return operate(meta, StrobeOperation.sendEnc, plaintext, 0, false);
  }

  /// Receive and process an unauthenticated encrypted message in Strobe.
  ///
  /// The `recvUnauthenticatedEncryptMessage` method is used to receive and process an unauthenticated encrypted
  /// message within the Strobe protocol. This operation is typically used for secure communication where integrity
  /// is not a requirement. The method processes the ciphertext, updating the internal state of the Strobe instance
  /// and returning the decrypted message.
  ///
  /// Parameters:
  /// - `meta`: A boolean flag indicating whether metadata is included in the operation.
  /// - `ciphertext`: The ciphertext to be received and decrypted.
  ///
  /// Returns:
  /// - A `List<int>` containing the decrypted message.
  ///
  /// Usage:
  /// ```dart
  /// `List<int>` ciphertext = ...; // Received unauthenticated ciphertext.
  /// `List<int>` plaintext = strobeInstance.recvUnauthenticatedEncryptMessage(true, ciphertext);
  /// // Receive and process unauthenticated encrypted message.
  /// ```
  ///
  /// The `recvUnauthenticatedEncryptMessage` method is suitable for use cases where encryption is the primary concern,
  /// and data integrity is not a strict requirement.
  List<int> recvUnauthenticatedEncryptMessage(bool meta, List<int> ciphertext) {
    return operate(meta, StrobeOperation.recvEnc, ciphertext, 0, false);
  }

  /// Process and add additional data to the Strobe protocol state.
  ///
  /// The `ad` method is used to process and add additional data (AD) to the Strobe protocol state.
  /// Additional data is used to update the protocol state without producing output, often for metadata or configuration purposes.
  ///
  /// Parameters:
  /// - `meta`: A boolean flag indicating whether metadata is included in the operation.
  /// - `additionalData`: A list of integers containing the additional data to be processed and added.
  ///
  /// Usage:
  /// ```dart
  /// `List<int>` metadata = ...; // Additional data or metadata to include.
  /// strobeInstance.additionalData(true, metadata);
  /// // Process and add additional data to the Strobe protocol state.
  /// ```
  ///
  /// The `additionalData` method is a fundamental operation in the Strobe protocol,
  /// allowing you to incorporate additional data into the protocol's internal state without producing output.
  void additionalData(bool meta, List<int> additionalData) {
    operate(meta, StrobeOperation.ad, additionalData, 0, false);
  }

  /// Process and send clear text data within the Strobe protocol.
  ///
  /// The `sendClearText` method is used to process and send clear text data within the Strobe protocol.
  /// It applies operations specific to clear text data and incorporates metadata when necessary, preparing the data for transmission.
  ///
  /// Parameters:
  /// - `meta`: A boolean flag indicating whether metadata is included in the operation.
  /// - `cleartext`: A `List<int>` containing the clear text data to be processed and sent.
  ///
  /// Usage:
  /// ```dart
  /// `List<int>` dataToSend = ...; // Clear text data to send.
  /// strobeInstance.sendClearText(true, dataToSend);
  /// // Process and send the clear text data within the Strobe protocol.
  /// ```
  ///
  /// The `sendClearText` method is a crucial part of the Strobe protocol, ensuring that clear text data is properly processed,
  /// potentially with metadata, and made ready for transmission.
  void sendClearText(bool meta, List<int> cleartext) {
    operate(meta, StrobeOperation.sendClr, cleartext, 0, false);
  }

  /// Process received clear text within the Strobe protocol.
  ///
  /// The `receivedClearText` method is used to process received clear text within the Strobe protocol. It applies operations specific to received clear text data while considering the provided metadata.
  ///
  /// Parameters:
  /// - `meta`: A boolean flag indicating whether metadata is included in the operation.
  /// - `cleartext`: A `List<int>` containing the received clear text data to be processed.
  ///
  /// Usage:
  /// ```dart
  /// `List<int>` receivedData = ...; // Received clear text data.
  /// strobeInstance.receivedClearText(true, receivedData);
  /// // Process the received clear text data within the Strobe protocol.
  /// ```
  ///
  /// The `receivedClearText` method is essential for handling received clear text data as part of the Strobe protocol,
  /// ensuring that the necessary cryptographic operations are applied.
  void receivedClearText(bool meta, List<int> cleartext) {
    operate(meta, StrobeOperation.recvClr, cleartext, 0, false);
  }

  /// Generate and append a Message Authentication Code (MAC) to data in the Strobe protocol.
  ///
  /// The `sendMac` method is used to generate and append a Message Authentication Code (MAC) to data within the Strobe protocol.
  /// This MAC ensures the integrity and authenticity of the data being sent over the communication channel.
  ///
  /// Parameters:
  /// - `meta`: A boolean flag indicating whether metadata is included in the operation.
  /// - `outputLength`: The desired output length of the generated MAC.
  ///
  /// Returns:
  /// - A `List<int>` containing the generated MAC of the specified length.
  ///
  /// Usage:
  /// ```dart
  /// int desiredMacLength = 16; // Specify the desired MAC length in bytes.
  /// `List<int>` generatedMac = strobeInstance.sendMac(true, desiredMacLength);
  /// // Append the generated MAC to the data to be sent.
  /// ```
  ///
  /// The `sendMac` method plays a crucial role in ensuring data integrity during the transmission process by generating and appending MACs to the data to be sent.
  List<int> sendMac(bool meta, int outputLength) {
    return operate(
        meta, StrobeOperation.sendMac, List.empty(), outputLength, false);
  }

  /// Verify and process a received MAC in the Strobe protocol.
  ///
  /// The `recvMac` method is used to verify and process a received Message Authentication Code (MAC) within the Strobe protocol. It checks the authenticity of the provided MAC and its metadata to ensure the integrity of the received data.
  ///
  /// Parameters:
  /// - `meta`: A boolean flag indicating whether metadata is included in the operation.
  /// - `mac`: The received MAC to be verified.
  ///
  /// Returns:
  /// - `true` if the MAC verification is successful, indicating the received data's integrity.
  /// - `false` if the MAC verification fails, suggesting potential data tampering.
  ///
  /// Usage:
  /// ```dart
  /// bool isMacValid = strobeInstance.received(true, receivedMac);
  /// if (isMacValid) {
  ///   // Process the received data.
  /// } else {
  ///   // Handle potential data tampering.
  /// }
  /// ```
  ///
  /// The `received` method is an essential part of the Strobe protocol for ensuring the integrity of data received over the communication channel.
  bool receivedMac(bool meta, List<int> mac) {
    return operate(meta, StrobeOperation.recvMac, mac, 0, false)[0] == 0;
  }

  /// Ratchet the Strobe protocol state to enhance security.
  ///
  /// The `ratchet` method is used to update the Strobe protocol state by invoking the "RATCHET" operation.
  /// This operation is typically performed to enhance security by deriving new key material and ensuring forward secrecy.
  ///
  /// Parameters:
  /// - `length`: The length of the key material to derive during the ratchet operation.
  ///
  /// Usage:
  /// ```dart
  /// strobeInstance.ratchet(32); // Ratchet the Strobe protocol to derive 32 bytes of key material.
  /// ```
  ///
  /// The `ratchet` method should be called periodically to advance the Strobe protocol's internal
  /// state and derive fresh key material, helping to protect the confidentiality of data.
  void ratchet(int length) {
    operate(false, StrobeOperation.ratchet, List.empty(), length, false);
  }
}
