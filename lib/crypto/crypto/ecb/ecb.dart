import 'package:blockchain_utils/crypto/crypto/aes/aes.dart';
import 'package:blockchain_utils/crypto/crypto/aes/padding.dart';
import 'package:blockchain_utils/exception/exception.dart';

/// Electronic Codebook (ECB) mode for AES encryption and decryption.
///
/// This class extends the AES block cipher to implement the Electronic Codebook (ECB) mode,
/// which is a basic block cipher mode that encrypts and decrypts data in fixed-size blocks.
class ECB extends AES {
  /// Creates an ECB instance with the specified encryption key.
  ///
  /// Parameters:
  /// - `key`: The encryption key used for ECB mode.
  ECB(List<int> key) : super(key);

  /// Encrypts a single data block using the Electronic Codebook (ECB) mode.
  ///
  /// This method encrypts a single data block using the AES block cipher in Electronic Codebook (ECB) mode.
  /// The block size is determined by the AES algorithm. Optionally, a padding style can be applied to the
  /// input data before encryption.
  ///
  /// Parameters:
  /// - `src`: The data block to be encrypted.
  /// - `dst`: (Optional) The destination for the encrypted block. If not provided, a new `List<int>` is created.
  /// - `paddingStyle`: (Optional) The padding style to be applied before encryption (default is PKCS#7).
  ///
  /// Returns:
  /// - The encrypted data block.
  ///
  /// Throws:
  /// - `ArgumentException` if the source data size is not a multiple of the block size or if the destination size
  ///   does not match the source size.
  /// - Exceptions related to padding, if padding is applied.
  ///
  /// Note: This method encrypts a single block of data using AES in ECB mode. If padding is applied, it ensures
  /// the source data is appropriately padded before encryption.
  @override
  List<int> encryptBlock(List<int> src,
      [List<int>? dst,
      PaddingAlgorithm? paddingStyle = PaddingAlgorithm.pkcs7]) {
    if (paddingStyle == null) {
      if ((src.length % blockSize) != 0) {
        throw ArgumentException("src size must be a multiple of $blockSize");
      }
    }
    List<int> input = List<int>.from(src);
    if (paddingStyle != null) {
      input = BlockCipherPadding.pad(input, blockSize, style: paddingStyle);
    }

    final out = dst ?? List<int>.filled(input.length, 0);
    if (out.length != input.length) {
      throw const ArgumentException(
          "The destination size does not match with source size");
    }
    final numBlocks = input.length ~/ blockSize;
    for (var i = 0; i < numBlocks; i++) {
      final start = i * blockSize;
      final end = (i + 1) * blockSize;
      List<int> block = List<int>.from(input.sublist(start, end));
      final enc = super.encryptBlock(block);
      out.setRange(start, end, enc);
    }
    return out;
  }

  /// Decrypts a single data block using the Electronic Codebook (ECB) mode.
  ///
  /// This method decrypts a single data block using the AES block cipher in Electronic Codebook (ECB) mode.
  /// The block size is determined by the AES algorithm. Optionally, a padding style can be applied to the
  /// output data after decryption.
  ///
  /// Parameters:
  /// - `src`: The data block to be decrypted.
  /// - `dst`: (Optional) The destination for the decrypted block. If not provided, a new `List<int>` is created.
  /// - `paddingStyle`: (Optional) The padding style to be applied after decryption (default is PKCS#7).
  ///
  /// Returns:
  /// - The decrypted data block.
  ///
  /// Throws:
  /// - `ArgumentException` if the source data size is not a multiple of the block size or if the destination size
  ///   is too small.
  /// - Exceptions related to padding, if padding is applied.
  ///
  /// Note: This method decrypts a single block of data using AES in ECB mode. If padding is applied, it ensures
  /// the output data is appropriately unpadded after decryption.
  @override
  List<int> decryptBlock(List<int> src,
      [List<int>? dst,
      PaddingAlgorithm? paddingStyle = PaddingAlgorithm.pkcs7]) {
    if ((src.length % blockSize) != 0) {
      throw ArgumentException("src size must be a multiple of $blockSize");
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
        throw const ArgumentException("Destination size is small");
      }
      dst.setAll(0, out);
      return dst;
    }
    return out;
  }
}
