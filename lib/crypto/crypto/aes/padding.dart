import 'package:blockchain_utils/crypto/crypto/exception/exception.dart';

/// Enumeration representing various padding algorithms for block ciphers.
enum PaddingAlgorithm { pkcs7, iso7816, x923 }

/// A utility class for adding and removing padding for block ciphers.
class BlockCipherPadding {
  /// Adds padding to the provided data to match the specified block size.
  ///
  /// Parameters:
  /// - [dataToPad]: The input data to be padded.
  /// - [blockSize]: The desired block size for the data.
  /// - [style]: The padding style, which can be one of the PaddingAlgorithm values (default is pkcs7).
  static List<int> pad(
    List<int> dataToPad,
    int blockSize, {
    PaddingAlgorithm style = PaddingAlgorithm.pkcs7,
  }) {
    final int paddingLen = blockSize - dataToPad.length % blockSize;
    List<int> padding;

    if (style == PaddingAlgorithm.pkcs7) {
      padding = List<int>.filled(paddingLen, 0);
      for (int i = 0; i < paddingLen; i++) {
        padding[i] = paddingLen;
      }
    } else if (style == PaddingAlgorithm.x923) {
      padding = List<int>.filled(paddingLen, 0);
      for (int i = 0; i < paddingLen - 1; i++) {
        padding[i] = 0;
      }
      padding[paddingLen - 1] = paddingLen;
    } else {
      padding = List<int>.filled(paddingLen, 0);
      padding[0] = 128;
      for (int i = 1; i < paddingLen; i++) {
        padding[i] = 0;
      }
    }

    final List<int> result = List<int>.filled(dataToPad.length + paddingLen, 0);
    result.setAll(0, dataToPad);
    result.setAll(dataToPad.length, padding);

    return result;
  }

  /// Removes padding from the provided data.
  ///
  /// Parameters:
  /// - [paddedData]: The padded data from which padding will be removed.
  /// - [blockSize]: The block size used for padding.
  /// - [style]: The padding style, which can be one of the PaddingAlgorithm values (default is pkcs7).
  ///
  /// Throws:
  /// - [CryptoException] for various scenarios, such as incorrect padding or zero-length input.
  static List<int> unpad(
    List<int> paddedData,
    int blockSize, {
    PaddingAlgorithm style = PaddingAlgorithm.pkcs7,
  }) {
    final int paddedDataLen = paddedData.length;

    if (paddedDataLen == 0) {
      throw CryptoException.failed(
        'unpad',
        reason: "Zero-length input cannot be unpadded.",
      );
    }

    if (paddedDataLen % blockSize != 0) {
      throw CryptoException.failed(
        "unpad",
        reason: "Input data is not padded.",
      );
    }

    int paddingLen;

    if (style == PaddingAlgorithm.pkcs7 || style == PaddingAlgorithm.x923) {
      paddingLen = paddedData[paddedDataLen - 1];
      if (paddingLen < 1 || paddingLen > blockSize) {
        throw CryptoException.failed("unpad", reason: "Incorrect padding.");
      }

      if (style == PaddingAlgorithm.pkcs7) {
        for (int i = 1; i <= paddingLen; i++) {
          if (paddedData[paddedDataLen - i] != paddingLen) {
            throw CryptoException.failed("unpad", reason: "Incorrect padding.");
          }
        }
      } else {
        for (int i = 1; i < paddingLen; i++) {
          if (paddedData[paddedDataLen - i - 1] != 0) {
            throw CryptoException.failed("unpad", reason: "Incorrect padding.");
          }
        }
      }
    } else {
      final int index = paddedData.lastIndexOf(128);
      if (index < 0) {
        throw CryptoException.failed("unpad", reason: "Incorrect padding.");
      }
      paddingLen = paddedDataLen - index;
      if (paddingLen < 1 || paddingLen > blockSize) {
        throw CryptoException.failed("unpad", reason: "Incorrect padding.");
      }
      for (int i = 1; i < paddingLen; i++) {
        if (paddedData[index + i] != 0) {
          throw CryptoException.failed("unpad", reason: "Incorrect padding.");
        }
      }
    }
    return paddedData.sublist(0, paddedDataLen - paddingLen);
  }
}
