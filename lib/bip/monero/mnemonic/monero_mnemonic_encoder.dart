import 'dart:typed_data';
import 'package:blockchain_utils/bip/mnemonic/src/mnemonic.dart';
import 'package:blockchain_utils/bip/mnemonic/src/mnemonic_encoder_base.dart';
import 'package:blockchain_utils/bip/mnemonic/src/mnemonic_utils.dart';
import 'package:blockchain_utils/exception/exceptions.dart';

import 'monero_entropy_generator.dart';
import 'monero_mnemonic.dart';
import 'monero_mnemonic_utils.dart';

/// An abstract base class for encoding entropy into Monero mnemonics.
/// -[language]: The Monero language to use for encoding. Defaults to English.
///
abstract class MoneroMnemonicEncoderBase extends MnemonicEncoderBase {
  final MoneroLanguages language;

  /// Constructs a MoneroMnemonicEncoderBase with an optional language parameter.
  ///
  /// -[language]: The Monero language to use for encoding. Defaults to English.
  ///
  MoneroMnemonicEncoderBase([this.language = MoneroLanguages.english])
    : super(language, MoneroWordsListGetter());

  /// Encodes the provided entropy bytes into a list of Monero mnemonic words.
  ///
  /// -[entropyBytes]: The entropy bytes to encode.
  ///
  List<String> _encodeToList(List<int> entropyBytes) {
    final int entropyByteLen = entropyBytes.length;
    if (!MoneroEntropyGenerator.isValidEntropyByteLen(entropyByteLen)) {
      throw ArgumentException.invalidOperationArguments(
        "encode",
        name: "entropyBytes",
        reason: "Invalid entropy bytes length",
      );
    }
    final List<String> mnemonic = [];
    for (int i = 0; i < entropyByteLen ~/ 4; i++) {
      mnemonic.addAll(
        MnemonicUtils.bytesChunkToWords(
          entropyBytes.sublist(i * 4, (i * 4) + 4),
          wordsList,
          endian: Endian.little,
        ),
      );
    }

    return mnemonic;
  }
}

/// A class that encodes entropy into Monero mnemonics without a checksum.
class MoneroMnemonicNoChecksumEncoder extends MoneroMnemonicEncoderBase {
  /// Constructs a MoneroMnemonicNoChecksumEncoder with an optional language parameter.
  ///
  /// -[language]: The Monero language to use for encoding. Defaults to the language
  /// specified in the superclass.
  ///
  MoneroMnemonicNoChecksumEncoder([super.language]);

  /// Encodes the provided entropy bytes into a Monero mnemonic without a checksum.
  ///
  /// -[entropyBytes]: The entropy bytes to encode.
  ///
  @override
  Mnemonic encode(List<int> entropyBytes) {
    return Mnemonic.fromList(_encodeToList(entropyBytes));
  }
}

/// A class that encodes entropy into Monero mnemonics with a checksum.
class MoneroMnemonicWithChecksumEncoder extends MoneroMnemonicEncoderBase {
  /// Constructs a MoneroMnemonicWithChecksumEncoder with an optional language parameter.
  ///
  /// -[language]: The Monero language to use for encoding. Defaults to the language
  /// specified in the superclass.
  ///
  MoneroMnemonicWithChecksumEncoder([super.language]);

  /// Encodes the provided entropy bytes into a Monero mnemonic with a checksum.
  ///
  /// -[entropyBytes]: The entropy bytes to encode.
  ///
  @override
  Mnemonic encode(List<int> entropyBytes) {
    final List<String> words = _encodeToList(entropyBytes);
    final String checksumWord = MoneroMnemonicUtils.computeChecksum(
      words,
      language,
    );

    return Mnemonic.fromList([...words, checksumWord]);
  }
}

/// A class that provides utility for encoding entropy into Monero mnemonics.
class MoneroMnemonicEncoder {
  final MoneroMnemonicNoChecksumEncoder nochecksumEncoder;
  final MoneroMnemonicWithChecksumEncoder withChecksumEncoder;

  /// Constructs a MoneroMnemonicEncoder with an optional language parameter.
  ///
  /// -[language]: The Monero language to use for encoding. Defaults to English.
  ///
  MoneroMnemonicEncoder([MoneroLanguages language = MoneroLanguages.english])
    : nochecksumEncoder = MoneroMnemonicNoChecksumEncoder(language),
      withChecksumEncoder = MoneroMnemonicWithChecksumEncoder(language);

  /// Encodes the provided entropy bytes into a Monero mnemonic without a checksum.
  ///
  /// -[entropyBytes]: The entropy bytes to encode.
  Mnemonic encodeNoChecksum(List<int> entropyBytes) {
    return nochecksumEncoder.encode(entropyBytes);
  }

  /// Encodes the provided entropy bytes into a Monero mnemonic with a checksum.
  ///
  /// -[entropyBytes]: The entropy bytes to encode.
  Mnemonic encodeWithChecksum(List<int> entropyBytes) {
    return withChecksumEncoder.encode(entropyBytes);
  }
}
