import 'package:blockchain_utils/crypto/crypto/cipher/blockcipher/core/blockcipher.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/utils/binary/src/binary_operation.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// CBC mode over a [BuBlockCipher]. Stateful: [encrypt]/[decrypt] each
/// handle one block and carry the chaining value forward to the next call.
class CBC implements BlockCipherCbc {
  late BuBlockCipher _cipher;
  late List<int> _prevBlock;
  late List<int> _tmpBlock;
  BuBlockCipher get cipher => _cipher;
  @override
  int get blockSize => _cipher.blockSize;

  CBC(BuBlockCipher cipher, List<int> iv) {
    if (iv.length != cipher.blockSize) {
      throw CoreErrors.invalidOperationArguments(
        "CBC",
        name: "iv",
        reason: "Invalid IV bytes length.",
      );
    }

    _cipher = cipher;
    _prevBlock = iv.clone();
    _tmpBlock = List<int>.filled(cipher.blockSize, 0);
  }

  /// A new [CBC] resuming from this one's current chaining value.
  /// NOTE: the underlying cipher instance is shared, not copied.
  CBC clone() {
    return CBC(cipher, _prevBlock);
  }

  /// Encrypts exactly one [blockSize]-byte block.
  @override
  BuBytes encrypt(List<int> src, [List<int>? dst]) {
    final out = BuBytes.unsafeMutable(dst ?? List<int>.filled(blockSize, 0));
    if (src.length != blockSize) {
      throw CoreErrors.invalidOperationArguments(
        "encrypt",
        name: "src",
        reason: "Invalid source bytes length.",
      );
    }
    if (out.length != blockSize) {
      throw CoreErrors.invalidOperationArguments(
        "encrypt",
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

  /// Decrypts exactly one [blockSize]-byte block.
  @override
  BuBytes decrypt(List<int> input, [List<int>? dst]) {
    final out = BuBytes.unsafeMutable(dst ?? List<int>.filled(blockSize, 0));

    if (input.length != blockSize) {
      throw CoreErrors.invalidOperationArguments(
        "decrypt",
        name: "input",
        reason: "Invalid input bytes length.",
      );
    }
    if (out.length != blockSize) {
      throw CoreErrors.invalidOperationArguments(
        "decrypt",
        name: "dst",
        reason: "Invalid destination bytes length.",
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

  /// Drops the chaining state. The instance is unusable afterwards.
  @override
  BlockCipherCbc clean() {
    BinaryOps.zero(_tmpBlock);
    BinaryOps.zero(_prevBlock);
    _tmpBlock = [];
    _prevBlock = [];
    return this;
  }
}
