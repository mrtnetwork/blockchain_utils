import 'package:blockchain_utils/crypto/crypto/aes/aes.dart';
import 'package:blockchain_utils/crypto/crypto/aes/padding.dart';
import 'package:blockchain_utils/crypto/crypto/exception/exception.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';

/// Electronic Codebook (ECB) mode for AES encryption and decryption.
///
class ECB extends AES {
  /// Creates an ECB instance with the specified encryption key.
  ///
  /// Parameters:
  /// - [key]: The encryption key used for ECB mode.
  ECB(super.key);

  /// Encrypts a single data block using the Electronic Codebook (ECB) mode.
  ///
  /// Parameters:
  /// - [src]: The data block to be encrypted.
  /// - [dst]: (Optional) The destination for the encrypted block. If not provided, a new `List<int>` is created.
  /// - [paddingStyle]: (Optional) The padding style to be applied before encryption (default is PKCS#7).
  @override
  List<int> encryptBlock(
    List<int> src, [
    List<int>? dst,
    PaddingAlgorithm? paddingStyle = PaddingAlgorithm.pkcs7,
  ]) {
    if (paddingStyle == null) {
      if ((src.length % blockSize) != 0) {
        throw ArgumentException.invalidOperationArguments(
          "encryptBlock",
          name: "src",
          reason: "Invalid source bytes length.",
        );
      }
    }
    List<int> input = src.clone();
    if (paddingStyle != null) {
      input = BlockCipherPadding.pad(input, blockSize, style: paddingStyle);
    }

    final out = dst ?? List<int>.filled(input.length, 0);
    if (out.length != input.length) {
      throw ArgumentException.invalidOperationArguments(
        "encryptBlock",
        name: "out",
        reason: "Incorrect destination length.",
      );
    }
    final numBlocks = input.length ~/ blockSize;
    for (var i = 0; i < numBlocks; i++) {
      final start = i * blockSize;
      final end = (i + 1) * blockSize;
      final List<int> block = input.sublist(start, end);
      final enc = super.encryptBlock(block);
      out.setRange(start, end, enc);
    }
    return out;
  }

  /// Decrypts a single data block using the Electronic Codebook (ECB) mode.
  ///
  /// Parameters:
  /// - [src]: The data block to be decrypted.
  /// - [dst]: (Optional) The destination for the decrypted block.
  /// - [paddingStyle]: (Optional) The padding style to be applied after decryption (default is PKCS#7).
  ///
  /// Throws:
  /// - [CryptoException] if the source data size is not a multiple of the block size or if the destination size
  ///   is too small.
  /// - Exceptions related to padding, if padding is applied.
  @override
  List<int> decryptBlock(
    List<int> src, [
    List<int>? dst,
    PaddingAlgorithm? paddingStyle = PaddingAlgorithm.pkcs7,
  ]) {
    if ((src.length % blockSize) != 0) {
      throw ArgumentException.invalidOperationArguments(
        "decryptBlock",
        name: "src",
        reason: "Incorrect source length.",
      );
    }
    List<int> out = List<int>.filled(src.length, 0);

    final numBlocks = src.length ~/ blockSize;
    for (var i = 0; i < numBlocks; i++) {
      final start = i * blockSize;
      final end = (i + 1) * blockSize;
      final enc = super.decryptBlock(src.sublist(start, end));
      out.setRange(start, end, enc);
    }
    if (paddingStyle != null) {
      out = BlockCipherPadding.unpad(out, blockSize, style: paddingStyle);
    }
    if (dst != null) {
      if (dst.length < out.length) {
        throw ArgumentException.invalidOperationArguments(
          "decryptBlock",
          name: "dst",
          reason: "Incorrect destination length.",
        );
      }
      dst.setAll(0, out);
      return dst;
    }
    return out;
  }
}
