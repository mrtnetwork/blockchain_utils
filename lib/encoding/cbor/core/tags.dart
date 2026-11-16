/// Constants representing CBOR tags
class CborTags {
  static const List<int> dateString = [0];
  static const List<int> dateEpoch = [1];
  static const List<int> posBigInt = [2];
  static const List<int> negBigInt = [3];
  static const List<int> decimalFrac = [4];
  static const List<int> bigFloat = [5];
  static const List<int> base64UrlExpected = [21];
  static const List<int> base64Expected = [22];
  static const List<int> base16Expected = [23];
  static const List<int> cbor = [24];
  static const List<int> uri = [32];
  static const List<int> base64Url = [33];
  static const List<int> base64 = [34];
  static const List<int> regexp = [35];
  static const List<int> mime = [36];
  static const List<int> set = [258];
}

/// Constants representing major CBOR tags
class MajorTags {
  static const int posInt = 0;
  static const int negInt = 1;
  static const int byteString = 2;
  static const int utf8String = 3;
  static const int array = 4;
  static const int map = 5;
  static const int tag = 6;
  static const int simpleOrFloat = 7;
}

/// Constants representing the number of bytes in CBOR encoding
class NumBytes {
  static const int zero = 0;
  static const int one = 24;
  static const int two = 25;
  static const int four = 26;
  static const int eight = 27;
  static const int indefinite = 31;
}

/// Constants representing simple values in CBOR encoding
class SimpleTags {
  static const int simpleFalse = 20;
  static const int simpleTrue = 21;
  static const int simpleNull = 22;
  static const int simpleUndefined = 23;
}
