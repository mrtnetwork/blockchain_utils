import 'package:blockchain_utils/crypto/crypto/blockcipher/blockcipher.dart';
import 'package:blockchain_utils/exception/exception/exception.dart';
import 'package:blockchain_utils/helper/helper.dart';

/// Implements a block cipher using CBC mode.
class CBC implements BlockCipher {
  late BlockCipher _cipher;
  late List<int> _prevBlock;
  late List<int> _tmpBlock;
  BlockCipher get cipher => _cipher;
  @override
  int get blockSize => _cipher.blockSize;

  CBC(BlockCipher cipher, List<int> iv) {
    if (iv.length != cipher.blockSize) {
      throw ArgumentException.invalidOperationArguments(
        "CBC",
        name: "iv",
        reason: "Invalid IV bytes length.",
      );
    }

    _cipher = cipher;
    _prevBlock = iv.clone();
    _tmpBlock = List<int>.filled(cipher.blockSize, 0);
  }

  /// clone current state of cbc
  CBC clone() {
    return CBC(cipher, _prevBlock);
  }

  /// Encrypt exactly 1 block (16 bytes)
  @override
  List<int> encryptBlock(List<int> src, [List<int>? dst]) {
    final out = dst ?? List<int>.filled(blockSize, 0);
    if (src.length != blockSize) {
      throw ArgumentException.invalidOperationArguments(
        "encryptBlock",
        name: "src",
        reason: "Invalid source bytes length.",
      );
    }
    if (out.length != blockSize) {
      throw ArgumentException.invalidOperationArguments(
        "encryptBlock",
        name: "dst",
        reason: "Invalid destination bytes length.",
      );
    }
    // CBC: XOR plaintext with previous ciphertext
    for (int i = 0; i < blockSize; i++) {
      _tmpBlock[i] = (src[i] ^ _prevBlock[i]).toU8;
    }
    // Encrypt XORed block
    _cipher.encryptBlock(_tmpBlock, out);

    // Update previous block for next round
    _prevBlock.setAll(0, out);
    return out;
  }

  /// Decrypt exactly 1 block (16 bytes)
  @override
  List<int> decryptBlock(List<int> input, [List<int>? dst]) {
    final out = dst ?? List<int>.filled(blockSize, 0);

    if (input.length != blockSize) {
      throw ArgumentException.invalidOperationArguments(
        "decryptBlock",
        name: "input",
        reason: "Invalid input bytes length.",
      );
    }

    // Always copy input first because decryptBlock may mutate the buffer
    final saved = input.clone();

    // Decrypt into tmpBlock (never into input!)
    _cipher.decryptBlock(saved, _tmpBlock);
    // XOR with previous block
    for (int i = 0; i < blockSize; i++) {
      out[i] = (_tmpBlock[i] ^ _prevBlock[i]).toU8;
    }

    // Update chaining value
    _prevBlock.setAll(0, saved);

    return out;
  }

  /// Resets all internal state for this cipher.
  ///
  /// After calling this method, the instance is no longer valid for further
  /// encryption or decryption operations.
  @override
  BlockCipher clean() {
    _tmpBlock = [];
    _prevBlock = [];
    return this;
  }
}
