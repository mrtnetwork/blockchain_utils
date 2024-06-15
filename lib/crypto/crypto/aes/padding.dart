import 'package:blockchain_utils/exception/exception.dart';

/// Enumeration representing various padding algorithms for block ciphers.
enum PaddingAlgorithm { pkcs7, iso7816, x923 }

/// A utility class for adding and removing padding for block ciphers.
class BlockCipherPadding {
  /// Adds padding to the provided data to match the specified block size.
  ///
  /// This method adds padding to the input data to make its length a multiple of the specified block size.
  /// The padding style can be selected from the available padding algorithms.
  ///
  /// Parameters:
  /// - `dataToPad`: The input data to be padded.
  /// - `blockSize`: The desired block size for the data.
  /// - `style`: The padding style, which can be one of the PaddingAlgorithm values (default is pkcs7).
  ///
  /// Returns:
  /// - A new `List<int>` containing the input data with the added padding.
  static List<int> pad(List<int> dataToPad, int blockSize,
      {PaddingAlgorithm style = PaddingAlgorithm.pkcs7}) {
    int paddingLen = blockSize - dataToPad.length % blockSize;
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

    List<int> result = List<int>.filled(dataToPad.length + paddingLen, 0);
    result.setAll(0, dataToPad);
    result.setAll(dataToPad.length, padding);

    return result;
  }

  /// Removes padding from the provided data.
  ///
  /// This method removes padding from the input data, assuming it follows a specific padding style.
  ///
  /// Parameters:
  /// - `paddedData`: The padded data from which padding will be removed.
  /// - `blockSize`: The block size used for padding.
  /// - `style`: The padding style, which can be one of the PaddingAlgorithm values (default is pkcs7).
  ///
  /// Returns:
  /// - A new `List<int>` containing the input data with padding removed.
  ///
  /// Throws:
  /// - `Exception` for various scenarios, such as incorrect padding or zero-length input.
  static List<int> unpad(List<int> paddedData, int blockSize,
      {PaddingAlgorithm style = PaddingAlgorithm.pkcs7}) {
    int paddedDataLen = paddedData.length;

    if (paddedDataLen == 0) {
      throw const ArgumentException('Zero-length input cannot be unpadded');
    }

    if (paddedDataLen % blockSize != 0) {
      throw const ArgumentException('Input data is not padded');
    }

    int paddingLen;

    if (style == PaddingAlgorithm.pkcs7 || style == PaddingAlgorithm.x923) {
      paddingLen = paddedData[paddedDataLen - 1];
      if (paddingLen < 1 || paddingLen > blockSize) {
        throw const ArgumentException('incorrect padding');
      }

      if (style == PaddingAlgorithm.pkcs7) {
        for (int i = 1; i <= paddingLen; i++) {
          if (paddedData[paddedDataLen - i] != paddingLen) {
            throw const ArgumentException('incorrect padding');
          }
        }
      } else {
        for (int i = 1; i < paddingLen; i++) {
          if (paddedData[paddedDataLen - i - 1] != 0) {
            throw const ArgumentException('incorrect padding');
          }
        }
      }
    } else {
      int index = paddedData.lastIndexOf(128);
      if (index < 0) {
        throw const ArgumentException('incorrect padding');
      }
      paddingLen = paddedDataLen - index;
      if (paddingLen < 1 || paddingLen > blockSize) {
        throw const ArgumentException('incorrect padding');
      }
      for (int i = 1; i < paddingLen; i++) {
        if (paddedData[index + i] != 0) {
          throw const ArgumentException('incorrect padding');
        }
      }
    }
    return paddedData.sublist(0, paddedDataLen - paddingLen);
  }
}
