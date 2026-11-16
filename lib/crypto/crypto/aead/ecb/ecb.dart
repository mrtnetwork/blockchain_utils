import 'package:blockchain_utils/crypto/crypto/cipher/blockcipher/aes/aes.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/crypto/crypto/cipher/blockcipher/aes/padding.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Electronic Codebook (ECB) mode for AES encryption and decryption.
class ECB extends AES implements BuAesEcb {
  final PaddingAlgorithm? paddingStyle;

  /// Creates an ECB instance with the given [key] and [paddingStyle]
  /// (PKCS#7 by default; pass null to require pre-padded, block-aligned input).
  ECB(super.key, {this.paddingStyle = PaddingAlgorithm.pkcs7});

  /// Encrypts [src] block-by-block in ECB mode, padding first if
  /// [paddingStyle] is set. Writes into [dst] if provided ([dst] must
  /// be exactly the padded input length).
  @override
  BuBytes encrypt(List<int> src, [List<int>? dst]) {
    final paddingStyle = this.paddingStyle;
    if (paddingStyle == null) {
      if ((src.length % blockSize) != 0) {
        throw CoreErrors.invalidOperationArguments(
          "encrypt",
          name: "src",
          reason: "Invalid source bytes length.",
        );
      }
    }
    List<int> input = src.clone();
    if (paddingStyle != null) {
      input = BlockCipherPadding.pad(input, blockSize, style: paddingStyle);
    }

    final out = BuBytes.unsafeMutable(dst ?? List<int>.filled(input.length, 0));
    if (out.length != input.length) {
      throw CoreErrors.invalidOperationArguments(
        "encrypt",
        name: "dst",
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

  /// Decrypts [src] block-by-block in ECB mode, unpadding after if
  /// [paddingStyle] is set. Writes into [dst] if provided ([dst] must
  /// be exactly the plaintext length — a longer buffer would leave
  /// trailing bytes in the returned value).
  @override
  BuBytes decrypt(List<int> src, [List<int>? dst]) {
    final paddingStyle = this.paddingStyle;
    if ((src.length % blockSize) != 0) {
      throw CoreErrors.invalidOperationArguments(
        "decrypt",
        name: "src",
        reason: "Incorrect source length.",
      );
    }
    BuBytes out = BuBytes.fill(src.length, 0);

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
      if (dst.length != out.length) {
        throw CoreErrors.invalidOperationArguments(
          "decrypt",
          name: "dst",
          reason: "Incorrect destination length.",
        );
      }
      dst.setAll(0, out);
      return BuBytes.unsafeMutable(dst);
    }
    return out;
  }
}
