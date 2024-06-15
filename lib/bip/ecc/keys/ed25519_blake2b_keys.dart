/*
  The MIT License (MIT)
  
  Copyright (c) 2021 Emanuele Bellocchia

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
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
import 'package:blockchain_utils/bip/ecc/keys/ed25519_keys.dart';
import 'package:blockchain_utils/bip/ecc/keys/i_keys.dart';
import 'package:blockchain_utils/bip/ecc/curve/elliptic_curve_types.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/curve/curves.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/eddsa/privatekey.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/eddsa/publickey.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/point/edwards.dart';
import 'package:blockchain_utils/crypto/crypto/hash/hash.dart';
import 'package:blockchain_utils/exception/exception.dart';

/// Represents an Ed25519 public key with Blake2b hashing, implementing the IPublicKey interface.
class Ed25519Blake2bPublicKey implements IPublicKey {
  /// EDDSA public key
  final EDDSAPublicKey _publicKey;

  /// Private constructor to create an Ed25519Blake2bPublicKey instance from an EDDSAPublicKey.
  Ed25519Blake2bPublicKey._(this._publicKey);

  /// Factory constructor to create an Ed25519Blake2bPublicKey from raw key bytes.
  factory Ed25519Blake2bPublicKey.fromBytes(List<int> keyBytes) {
    if (keyBytes.length ==
            Ed25519KeysConst.pubKeyByteLen +
                Ed25519KeysConst.pubKeyPrefix.length &&
        keyBytes[0] == Ed25519KeysConst.pubKeyPrefix[0]) {
      keyBytes = keyBytes.sublist(1);
    }
    return Ed25519Blake2bPublicKey._(
        EDDSAPublicKey(Curves.generatorED25519, keyBytes));
  }

  /// curve type
  @override
  EllipticCurveTypes get curve {
    return EllipticCurveTypes.ed25519Blake2b;
  }

  /// public key compressed length
  @override
  int get length {
    return Ed25519KeysConst.pubKeyByteLen +
        Ed25519KeysConst.pubKeyPrefix.length;
  }

  /// public key uncompressed length
  @override
  int get uncompressedLength {
    return length;
  }

  /// check if if key bytes is valid for this public key
  static bool isValidBytes(List<int> keyBytes) {
    try {
      Ed25519Blake2bPublicKey.fromBytes(keyBytes);
      return true;
      // ignore: empty_catches
    } catch (e) {}
    return false;
  }

  /// edwards point of public key
  @override
  EDPoint get point {
    return _publicKey.point;
  }

  /// compressed bytes of public key
  @override
  List<int> get compressed {
    return List<int>.from(
        [...Ed25519KeysConst.pubKeyPrefix, ..._publicKey.point.toBytes()]);
  }

  /// uncompressed bytes of public key
  @override
  List<int> get uncompressed {
    return compressed;
  }

  @override
  String toHex(
      {bool withPrefix = true, bool lowerCase = true, String? prefix = ""}) {
    List<int> key = _publicKey.point.toBytes();
    if (withPrefix) {
      key = compressed;
    }
    return BytesUtils.toHexString(key, prefix: prefix, lowerCase: lowerCase);
  }
}

/// Represents an Ed25519 private key with Blake2b hashing, implementing the IPrivateKey interface.
class Ed25519Blake2bPrivateKey implements IPrivateKey {
  /// Private constructor for creating an Ed25519Blake2bPrivateKey instance from an EDDSAPrivateKey.
  Ed25519Blake2bPrivateKey._(this._privateKey);

  final EDDSAPrivateKey _privateKey;

  /// Factory method for creating an Ed25519Blake2bPrivateKey from a byte array.
  /// It checks the length of the provided keyBytes to ensure it matches the expected length.
  /// Then, it initializes an EdDSA private key using the Edward generator and BLAKE2b hash function.
  factory Ed25519Blake2bPrivateKey.fromBytes(List<int> keyBytes) {
    if (keyBytes.length != Ed25519KeysConst.privKeyByteLen) {
      throw const ArgumentException("invalid private key length");
    }
    final edwardGenerator = Curves.generatorED25519;
    final eddsaPrivateKey =
        EDDSAPrivateKey(edwardGenerator, keyBytes, () => BLAKE2b());
    return Ed25519Blake2bPrivateKey._(eddsaPrivateKey);
  }

  /// curve type
  @override
  EllipticCurveTypes get curveType {
    return EllipticCurveTypes.ed25519Blake2b;
  }

  /// check if bytes valid for this key
  static bool isValidBytes(List<int> keyBytes) {
    try {
      Ed25519Blake2bPrivateKey.fromBytes(keyBytes);
      return true;
      // ignore: empty_catches
    } catch (e) {}
    return false;
  }

  /// private key bytes length
  @override
  int get length {
    return Ed25519KeysConst.privKeyByteLen;
  }

  /// access to public key
  @override
  IPublicKey get publicKey {
    return Ed25519Blake2bPublicKey._(_privateKey.publicKey);
  }

  /// private key raw bytes
  @override
  List<int> get raw {
    return _privateKey.privateKey;
  }

  @override
  String toHex({bool lowerCase = true, String? prefix = ""}) {
    return BytesUtils.toHexString(raw, lowerCase: lowerCase, prefix: prefix);
  }
}
