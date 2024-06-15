/*
  The MIT License (MIT)
  
  Copyright (c) 2021 Emanuele Bellocchia

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deals
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
  of the Software, and to permit persons to whom the Software is furnished to do so,
  subject to the following conditions:

  The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS," WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
  INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
  PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
  FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
  ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
  
  Note: This code has been adapted from its original Python version to Dart.
*/

/*
  The 3-Clause BSD License
  
  Copyright (c) 2023 Mohsen Haydari (MRTNETWORK)
  All rights reserved.
  
  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are met:
  
  1. Redistributions of source code must retain the above copyright notice, this
     list of conditions, and the following disclaimer.
  2. Redistributions in binary form must reproduce the above copyright notice, this
     list of conditions, and the following disclaimer in the documentation and/or
     other materials provided with the distribution.
  3. Neither the name of the [organization] nor the names of its contributors may be
     used to endorse or promote products derived from this software without
     specific prior written permission.
  
  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
  IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
  INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
  BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
  OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
  OF THE POSSIBILITY OF SUCH DAMAGE.
*/

import 'package:blockchain_utils/utils/utils.dart';
import 'package:blockchain_utils/bip/ecc/keys/ecdsa_keys.dart';
import 'package:blockchain_utils/bip/ecc/keys/i_keys.dart';
import 'package:blockchain_utils/bip/ecc/curve/elliptic_curve_types.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/curve/curves.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/ecdsa/private_key.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/ecdsa/public_key.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/point/base.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/point/ec_projective_point.dart';

/// A class representing a NIST P-256 public key that implements the IPublicKey interface.
class Nist256p1PublicKey implements IPublicKey {
  final ECDSAPublicKey publicKey;

  /// Private constructor for creating a Nist256p1PublicKey instance from an ECDSAPublicKey.
  Nist256p1PublicKey._(this.publicKey);

  /// Factory method for creating a Nist256p1PublicKey from a byte array.
  factory Nist256p1PublicKey.fromBytes(List<int> keyBytes) {
    final point = ProjectiveECCPoint.fromBytes(
        curve: Curves.curve256, data: keyBytes, order: null);
    final pub = ECDSAPublicKey(Curves.generator256, point);
    return Nist256p1PublicKey._(pub);
  }

  /// public key compressed bytes length.
  @override
  int get length {
    return EcdsaKeysConst.pubKeyCompressedByteLen;
  }

  /// curve type
  @override
  EllipticCurveTypes get curve {
    return EllipticCurveTypes.nist256p1;
  }

  /// check if bytes is valid for this key.
  static bool isValidBytes(List<int> keyBytes) {
    try {
      Nist256p1PublicKey.fromBytes(keyBytes);
      return true;
      // ignore: empty_catches
    } catch (e) {}
    return false;
  }

  /// public key point.
  @override
  ProjectiveECCPoint get point {
    return publicKey.point;
  }

  /// public key compressed bytes.
  @override
  List<int> get compressed {
    return publicKey.point.toBytes(EncodeType.comprossed);
  }

  /// public key uncompressed bytes.
  @override
  List<int> get uncompressed {
    return publicKey.point.toBytes(EncodeType.uncompressed);
  }

  @override
  int get uncompressedLength {
    return EcdsaKeysConst.pubKeyUncompressedByteLen;
  }

  @override
  String toHex(
      {bool withPrefix = true, bool lowerCase = true, String? prefix = ""}) {
    return BytesUtils.toHexString(compressed,
        prefix: prefix, lowerCase: lowerCase);
  }
}

/// A class representing a NIST P-256 private key that implements the IPrivateKey interface.
class Nist256p1PrivateKey implements IPrivateKey {
  final ECDSAPrivateKey privateKey;

  /// Private constructor for creating a Nist256p1PrivateKey instance from an ECDSAPrivateKey.
  Nist256p1PrivateKey._(this.privateKey);

  /// Factory method for creating a Nist256p1PrivateKey from a byte array.
  factory Nist256p1PrivateKey.fromBytes(List<int> keyBytes) {
    final prv = ECDSAPrivateKey.fromBytes(keyBytes, Curves.generator256);
    return Nist256p1PrivateKey._(prv);
  }

  /// curve type.
  @override
  EllipticCurveTypes get curveType {
    return EllipticCurveTypes.nist256p1;
  }

  /// check if bytes is valid for this key.
  static bool isValidBytes(List<int> keyBytes) {
    try {
      ECDSAPrivateKey.fromBytes(keyBytes, Curves.generator256);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// private key bytes length
  @override
  int get length {
    return EcdsaKeysConst.privKeyByteLen;
  }

  /// accsess to public key
  @override
  IPublicKey get publicKey {
    return Nist256p1PublicKey._(privateKey.publicKey);
  }

  /// private key raw bytes
  @override
  List<int> get raw {
    return privateKey.toBytes();
  }

  @override
  String toHex({bool lowerCase = true, String? prefix = ""}) {
    return BytesUtils.toHexString(raw, lowerCase: lowerCase, prefix: prefix);
  }
}
