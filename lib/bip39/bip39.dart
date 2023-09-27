import 'dart:typed_data';
import 'package:blockchain_utils/crypto/crypto.dart';
import 'package:blockchain_utils/formating/bytes_num_formating.dart';
import 'load_languages/languages.dart' as languages;

// Enum representing supported BIP-39 mnemonic word languages.
class Bip39Language {
  final String value;

  const Bip39Language._(this.value);

  // Supported BIP-39 languages
  static const Bip39Language english = Bip39Language._("english");
  static const Bip39Language spanish = Bip39Language._("spanish");
  static const Bip39Language portuguese = Bip39Language._("portuguese");
  static const Bip39Language korean = Bip39Language._("korean");
  static const Bip39Language japanese = Bip39Language._("japanese");
  static const Bip39Language italian = Bip39Language._("italian");
  static const Bip39Language french = Bip39Language._("french");
  static const Bip39Language czech = Bip39Language._("czech");
  static const Bip39Language chineseTraditional =
      Bip39Language._("chinese_traditional");
  static const Bip39Language chineseSimplified =
      Bip39Language._("chinese_simplified");
  List<String> get words {
    switch (this) {
      case Bip39Language.english:
        return languages.english;
      case Bip39Language.spanish:
        return languages.spanish;
      case Bip39Language.portuguese:
        return languages.portuguese;
      case Bip39Language.korean:
        return languages.korean;
      case Bip39Language.japanese:
        return languages.japanese;
      case Bip39Language.italian:
        return languages.italian;
      case Bip39Language.french:
        return languages.french;
      case Bip39Language.czech:
        return languages.czech;
      case Bip39Language.chineseTraditional:
        return languages.chineseTraditional;
      case Bip39Language.chineseSimplified:
        return languages.chineseSimplified;
      default:
        return languages.english;
    }
  }
}

// Enum representing supported BIP-39 mnemonic word lengths.
class Bip39WordLength {
  final int value;

  const Bip39WordLength._(this.value);
  // Supported BIP-39 word lengths
  static const Bip39WordLength words12 = Bip39WordLength._(128);
  static const Bip39WordLength words15 = Bip39WordLength._(160);
  static const Bip39WordLength words18 = Bip39WordLength._(192);
  static const Bip39WordLength words21 = Bip39WordLength._(224);
  static const Bip39WordLength words24 = Bip39WordLength._(256);
}

// Class for handling BIP-39 mnemonic generation and validation.
class BIP39 {
  BIP39({this.language = Bip39Language.english});

  // List of BIP-39 mnemonic words for the selected language.
  // List<String> _words = [];

  // Selected BIP-39 word language.
  final Bip39Language language;

  // Helper function to derive checksum bits from entropy.
  /// Derives the checksum bits from the given entropy bytes.
  ///
  /// The method calculates the checksum bits for a mnemonic phrase by taking the
  /// SHA-256 hash of the provided entropy and converting it into binary form.
  /// The checksum length is determined based on the entropy length, and it is
  /// used to ensure the validity of the mnemonic phrase.
  ///
  /// Parameters:
  /// - [entropy]: The input entropy bytes.
  ///
  /// Returns:
  /// A binary string representing the derived checksum bits.
  ///
  String _deriveChecksumBits(Uint8List entropy) {
    final ent = entropy.length * 8;
    final cs = ent ~/ 32;
    final hash = singleHash(entropy);
    return bytesToBinary(hash).substring(0, cs);
  }

  // Generates a BIP-39 mnemonic phrase with the specified strength.
  /// Generates a random BIP-39 mnemonic phrase of a specified word length.
  ///
  /// This method generates a random entropy of the specified size (in bytes)
  /// and converts it into a BIP-39 mnemonic phrase. The [strength] parameter
  /// determines the word length of the mnemonic (e.g., 12, 15, 18, 21, or 24 words).
  ///
  /// Parameters:
  /// - [strength]: The desired word length for the mnemonic phrase.
  ///
  /// Returns:
  /// A randomly generated BIP-39 mnemonic phrase as a String.
  ///
  String generateMnemonic(
      {Bip39WordLength strength = Bip39WordLength.words12}) {
    final entropy = generateRandom(size: strength.value ~/ 8);
    return entropyToMnemonic(bytesToHex(entropy));
  }

  /// Derives a cryptographic seed from a BIP-39 mnemonic and an optional passphrase.
  ///
  /// This method takes a BIP-39 mnemonic phrase and an optional passphrase and
  /// uses them to derive a cryptographic seed. The passphrase is typically empty
  /// or a user-defined value. The resulting seed can be used for generating
  /// private keys and addresses.
  ///
  /// Parameters:
  /// - [mnemonic]: The BIP-39 mnemonic phrase.
  /// - [passphrase]: An optional passphrase (default is an empty string).
  ///
  /// Returns:
  /// A cryptographic seed as a Uint8List.
  static Uint8List toSeed(String mnemonic, {String passphrase = ""}) {
    final String salt = "mnemonic$passphrase";
    return pbkdfDeriveDigest(mnemonic, salt);
  }

  /// Converts binary entropy data to a BIP-39 mnemonic phrase.
  ///
  /// This method takes binary entropy data, typically generated from a
  /// cryptographic source, and converts it into a BIP-39 mnemonic phrase. The
  /// mnemonic phrase is a human-readable representation of the binary entropy,
  /// providing a more user-friendly way to manage cryptographic secrets.
  ///
  /// Parameters:
  /// - [entropyString]: Binary entropy data as a hexadecimal string.
  ///
  /// Returns:
  /// A BIP-39 mnemonic phrase.
  ///
  /// Throws:
  /// - [ArgumentError]: If the provided entropy is invalid.
  String entropyToMnemonic(String entropyString) {
    final entropy = Uint8List.fromList(hexToBytes(entropyString));

    // Validate the entropy length and format.
    if (entropy.length < 16 || entropy.length > 32 || entropy.length % 4 != 0) {
      throw ArgumentError("Invalid entropy");
    }

    final entropyBits = bytesToBinary(entropy);
    final checksumBits = _deriveChecksumBits(entropy);
    final bits = entropyBits + checksumBits;

    // Split bits into groups of 11 and map to corresponding BIP-39 words.
    final regex = RegExp(r".{1,11}", caseSensitive: false, multiLine: false);
    final chunks = regex
        .allMatches(bits)
        .map((match) => match.group(0)!)
        .toList(growable: false);

    final words = chunks.map((binary) {
      int index = binaryToByte(binary);
      return language.words[index];
    }).join(' ');

    return words;
  }

  // Validates a BIP-39 mnemonic phrase.
  /// Validates a BIP-39 mnemonic phrase.
  ///
  /// This method checks whether a given BIP-39 mnemonic phrase is valid. A valid
  /// mnemonic phrase conforms to the BIP-39 specification and can be successfully
  /// converted back to entropy.
  ///
  /// Parameters:
  /// - [mnemonic]: The BIP-39 mnemonic phrase to validate.
  ///
  /// Returns:
  /// `true` if the mnemonic is valid, `false` otherwise.
  /// Note: This method will return `false` if the mnemonic is invalid or if any
  /// errors occur during the validation process.
  ///
  bool validateMnemonic(String mnemonic) {
    try {
      // Attempt to convert the mnemonic back to entropy.
      mnemonicToEntropy(mnemonic);
    } on Exception {
      rethrow; // Rethrow exceptions to be caught by the caller.
    } catch (e) {
      return false; // Catch other errors and return false.
    }
    return true; // If no exceptions or errors occur, the mnemonic is valid.
  }

  /// Converts a BIP-39 mnemonic phrase to entropy bytes.
  ///
  /// This method takes a BIP-39 mnemonic phrase as input and converts it into
  /// the raw entropy bytes it represents. It performs various checks to ensure
  /// the validity of the conversion, including verifying the checksum.
  ///
  /// Parameters:
  /// - [mnemonic]: The BIP-39 mnemonic phrase to convert.
  ///
  /// Returns:
  /// Raw entropy bytes as a hexadecimal string.
  ///
  /// Throws:
  /// - [ArgumentError]: If an invalid mnemonic word is encountered or the mnemonic
  ///   phrase is of an incorrect length.
  /// - [StateError]: If the entropy or checksum is invalid.
  String mnemonicToEntropy(String mnemonic) {
    // Split the mnemonic into individual words.
    List<String> words = mnemonic.split(' ');
    if (words.length % 3 != 0) {
      throw ArgumentError('Invalid mnemonic');
    }

    // Convert word indices to 11-bit binary strings.
    final bits = words.map((word) {
      final index = language.words.indexOf(word);
      if (index == -1) {
        throw ArgumentError('Invalid mnemonic');
      }
      return index.toRadixString(2).padLeft(11, '0');
    }).join('');

    // Divide bits into entropy and checksum sections.
    final dividerIndex = (bits.length / 33).floor() * 32;
    final entropyBits = bits.substring(0, dividerIndex);
    final checksumBits = bits.substring(dividerIndex);

    // Convert entropy bits back to bytes and perform validation checks.
    final regex = RegExp(r".{1,8}");
    final entropyBytes = Uint8List.fromList(regex
        .allMatches(entropyBits)
        .map((match) => binaryToByte(match.group(0)!))
        .toList(growable: false));
    if (entropyBytes.length < 16) {
      throw StateError("Invalid entropy");
    }
    if (entropyBytes.length > 32) {
      throw StateError("Invalid entropy");
    }
    if (entropyBytes.length % 4 != 0) {
      throw StateError("Invalid entropy");
    }

    // Verify the checksum.
    final newChecksum = _deriveChecksumBits(entropyBytes);
    if (newChecksum != checksumBits) {
      throw StateError("Invalid mnemonic checksum");
    }

    // Convert valid entropy bytes back to hexadecimal.
    return entropyBytes.map((byte) {
      return byte.toRadixString(16).padLeft(2, '0');
    }).join('');
  }
}
