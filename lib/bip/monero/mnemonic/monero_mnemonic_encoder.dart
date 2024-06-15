import 'dart:typed_data';
import 'package:blockchain_utils/bip/mnemonic/mnemonic.dart';
import 'package:blockchain_utils/bip/mnemonic/mnemonic_encoder_base.dart';
import 'package:blockchain_utils/bip/mnemonic/mnemonic_utils.dart';
import 'package:blockchain_utils/exception/exceptions.dart';

import 'monero_entropy_generator.dart';
import 'monero_mnemonic.dart';
import 'monero_mnemonic_utils.dart';

/// An abstract base class for encoding entropy into Monero mnemonics.
///
/// This class extends `MnemonicEncoderBase` and provides specific functionality
/// for encoding entropy into Monero mnemonics. It allows you to specify the Monero
/// language to be used for encoding, with English as the default language.
///
/// [language]: The Monero language to use for encoding. Defaults to English.
abstract class MoneroMnemonicEncoderBase extends MnemonicEncoderBase {
  final MoneroLanguages language;

  /// Constructs a MoneroMnemonicEncoderBase with an optional language parameter.
  ///
  /// [language]: The Monero language to use for encoding. Defaults to English.
  MoneroMnemonicEncoderBase([this.language = MoneroLanguages.english])
      : super(language, MoneroWordsListGetter());

  /// Encodes the provided entropy bytes into a list of Monero mnemonic words.
  ///
  /// This method takes a List<int> of entropy bytes as input and encodes it into
  /// a list of Monero mnemonic words. It validates the entropy byte length and
  /// converts the bytes into words using the specified Monero language.
  ///
  /// Throws an Exception if the entropy byte length is not valid.
  ///
  /// [entropyBytes]: The entropy bytes to encode.
  List<String> _encodeToList(List<int> entropyBytes) {
    int entropyByteLen = entropyBytes.length;
    if (!MoneroEntropyGenerator.isValidEntropyByteLen(entropyByteLen)) {
      throw ArgumentException(
          'Entropy byte length ($entropyByteLen) is not valid');
    }
    List<String> mnemonic = [];
    for (int i = 0; i < entropyByteLen ~/ 4; i++) {
      mnemonic.addAll(MnemonicUtils.bytesChunkToWords(
          entropyBytes.sublist(i * 4, (i * 4) + 4), wordsList,
          endian: Endian.little));
    }

    return mnemonic;
  }
}

/// A class that encodes entropy into Monero mnemonics without a checksum.
///
/// This class extends `MoneroMnemonicEncoderBase` and is specialized for encoding
/// entropy into Monero mnemonics without including a checksum. The absence of a
/// checksum means that the resulting mnemonic may lack the ability to detect errors
/// in the entered words or recover from mistakes.
class MoneroMnemonicNoChecksumEncoder extends MoneroMnemonicEncoderBase {
  /// Constructs a MoneroMnemonicNoChecksumEncoder with an optional language parameter.
  ///
  /// [language]: The Monero language to use for encoding. Defaults to the language
  /// specified in the superclass.
  MoneroMnemonicNoChecksumEncoder(
      [MoneroLanguages language = MoneroLanguages.english])
      : super(language);

  /// Encodes the provided entropy bytes into a Monero mnemonic without a checksum.
  ///
  /// This method encodes the given entropy bytes into a Monero mnemonic without
  /// including a checksum. The resulting mnemonic may be less error-tolerant and
  /// should be handled with caution.
  ///s
  /// [entropyBytes]: The entropy bytes to encode.
  @override
  Mnemonic encode(List<int> entropyBytes) {
    return Mnemonic.fromList(_encodeToList(entropyBytes));
  }
}

/// A class that encodes entropy into Monero mnemonics with a checksum.
///
/// This class extends `MoneroMnemonicEncoderBase` and is specialized for encoding
/// entropy into Monero mnemonics with an additional checksum. The checksum enhances
/// error detection and correction capabilities in the resulting mnemonic.
class MoneroMnemonicWithChecksumEncoder extends MoneroMnemonicEncoderBase {
  /// Constructs a MoneroMnemonicWithChecksumEncoder with an optional language parameter.
  ///
  /// [language]: The Monero language to use for encoding. Defaults to the language
  /// specified in the superclass.
  MoneroMnemonicWithChecksumEncoder(
      [MoneroLanguages language = MoneroLanguages.english])
      : super(language);

  /// Encodes the provided entropy bytes into a Monero mnemonic with a checksum.
  ///
  /// This method encodes the given entropy bytes into a Monero mnemonic and includes
  /// a checksum word for enhanced error detection and correction.
  ///
  /// [entropyBytes]: The entropy bytes to encode.
  @override
  Mnemonic encode(List<int> entropyBytes) {
    List<String> words = _encodeToList(entropyBytes);
    String checksumWord = MoneroMnemonicUtils.computeChecksum(words, language);

    return Mnemonic.fromList([...words, checksumWord]);
  }
}

/// A class that provides utility for encoding entropy into Monero mnemonics.
///
/// This class serves as a convenient utility for encoding entropy into Monero mnemonics.
/// It encapsulates instances of both `MoneroMnemonicNoChecksumEncoder` and
/// `MoneroMnemonicWithChecksumEncoder`, allowing you to choose whether to include
/// a checksum in the generated mnemonic.
class MoneroMnemonicEncoder {
  final MoneroMnemonicNoChecksumEncoder nochecksumEncoder;
  final MoneroMnemonicWithChecksumEncoder withChecksumEncoder;

  /// Constructs a MoneroMnemonicEncoder with an optional language parameter.
  ///
  /// [language]: The Monero language to use for encoding. Defaults to English.
  MoneroMnemonicEncoder([MoneroLanguages language = MoneroLanguages.english])
      : nochecksumEncoder = MoneroMnemonicNoChecksumEncoder(language),
        withChecksumEncoder = MoneroMnemonicWithChecksumEncoder(language);

  /// Encodes the provided entropy bytes into a Monero mnemonic without a checksum.
  ///
  /// This method uses the no-checksum encoder to generate a Monero mnemonic without
  /// including a checksum.
  ///
  /// [entropyBytes]: The entropy bytes to encode.
  Mnemonic encodeNoChecksum(List<int> entropyBytes) {
    return nochecksumEncoder.encode(entropyBytes);
  }

  /// Encodes the provided entropy bytes into a Monero mnemonic with a checksum.
  ///
  /// This method uses the checksum encoder to generate a Monero mnemonic with an
  /// included checksum for error detection and correction.
  ///
  /// [entropyBytes]: The entropy bytes to encode.
  Mnemonic encodeWithChecksum(List<int> entropyBytes) {
    return withChecksumEncoder.encode(entropyBytes);
  }
}
