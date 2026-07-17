import 'dart:io';

import 'package:blockchain_utils/blockchain_utils.dart';

void main() {
  final rand = QuickCrypto.generateRandomHex(100);
  final f = File("/home/mrhaydari/dev/packages/blockchain_utils/test/r.txt")
    ..writeAsStringSync(rand);
  final read = f.readAsStringSync();
  print(read == rand);
}
