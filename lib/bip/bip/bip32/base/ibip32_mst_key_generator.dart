import 'package:blockchain_utils/utils/utils.dart';

/// An abstract class that defines a method for generating master keys from a seed.
///
/// This class outlines a method for generating BIP-32 master keys from seed bytes.
abstract class IBip32MstKeyGenerator {
  /// Generates master keys from the given [seedBytes].
  ///
  /// The [seedBytes] parameter represents the seed data from which master keys are derived.
  /// The method returns a pair of [List<int>] objects containing the private and public keys.
  Tuple<List<int>, List<int>> generateFromSeed(List<int> seedBytes);
}
