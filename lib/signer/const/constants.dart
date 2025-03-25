class CryptoSignerConst {
  static const int ed25519SignatureLength = 64;
  static const int schnoorSginatureLength = 64;
  static const int ecdsaSignatureLength = 64;
  static const int ecdsaRecoveryIdLength = 1;
  static const int ecdsaSignatureWithRecoveryIdLength =
      ecdsaSignatureLength + ecdsaRecoveryIdLength;
}
