import 'package:blockchain_utils/helper/extensions/extensions.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

class Secp256k1Pkcs8Key implements SecretState {
  final SecretBytes privateKey;
  final BuBytes? publicKeyPoint;
  Secp256k1Pkcs8Key(List<int> privateKey, List<int>? publicKeyPoint)
    : privateKey = SecretBytes(privateKey.asImmutableBytes),
      publicKeyPoint = publicKeyPoint?.asImmutableBytes;
  Secp256k1Pkcs8Key.from(this.privateKey, this.publicKeyPoint);

  @override
  void dispose() {
    privateKey.zero();
  }
}

class Secp256k1Sec1Key implements SecretState {
  final SecretBytes privateKey;
  final BuBytes? publicKeyPoint;
  final String? curveOid;
  Secp256k1Sec1Key.from({
    required this.privateKey,
    required this.publicKeyPoint,
    required this.curveOid,
  });
  Secp256k1Sec1Key(
    List<int> privateKey,
    List<int>? publicKeyPoint,
    this.curveOid,
  ) : privateKey = SecretBytes(privateKey),
      publicKeyPoint = publicKeyPoint?.asImmutableBytes;

  @override
  void dispose() {
    privateKey.zero();
  }
}

class Secp256r1Pkcs8Key implements SecretState {
  final SecretBytes privateKey;
  final BuBytes? publicKeyPoint;
  Secp256r1Pkcs8Key(List<int> privateKey, List<int>? publicKeyPoint)
    : privateKey = SecretBytes(privateKey),
      publicKeyPoint = publicKeyPoint?.asImmutableBytes;
  Secp256r1Pkcs8Key.from({
    required this.privateKey,
    required this.publicKeyPoint,
  });
  @override
  void dispose() {
    privateKey.zero();
  }
}

class Secp256r1Sec1Key implements SecretState {
  final SecretBytes privateKey;
  final BuBytes? publicKeyPoint;
  final String? curveOid;
  Secp256r1Sec1Key(
    List<int> privateKey,
    List<int>? publicKeyPoint,
    this.curveOid,
  ) : privateKey = SecretBytes(privateKey),
      publicKeyPoint = publicKeyPoint?.asImmutableBytes;
  Secp256r1Sec1Key.from({
    required this.privateKey,
    required this.publicKeyPoint,
    required this.curveOid,
  });
  @override
  void dispose() {
    privateKey.zero();
  }
}
