import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/utils/utils.dart';

const int iteration = int.fromEnvironment("ITER", defaultValue: 0);
const bool native = bool.fromEnvironment('dart.library.io');

extension ExtHEX on List<int> {
  String toHex() => BytesUtils.toHexString(this);
}

extension TAKE on List<Map<String, dynamic>> {
  List<Map<String, dynamic>> shuffleTake([int? total]) {
    final shuffle = clone()..shuffle();
    if (shuffle.isEmpty || iteration != 0) {
      return shuffle.take(iteration).toList();
    }
    if (total != null) {
      return shuffle.take(total).toList();
    }
    int max =
        shuffle.length ~/
        switch (native) {
          true => 2,
          false => 3,
        };

    return shuffle.take(IntUtils.min(IntUtils.max(max, 1), 5)).toList();
  }
}
