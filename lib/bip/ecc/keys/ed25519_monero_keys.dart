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
import 'package:blockchain_utils/bip/ecc/keys/i_keys.dart';
import 'package:blockchain_utils/bip/ecc/curve/elliptic_curve_types.dart';
import 'package:blockchain_utils/bip/ecc/keys/ed25519_keys.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/curve/curves.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/eddsa/privatekey.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/eddsa/publickey.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/point/edwards.dart';
import 'package:blockchain_utils/exception/exception.dart';

/// A class representing an Ed25519 Monero-compatible public key that implements the IPublicKey interface.
class Ed25519MoneroPublicKey implements IPublicKey {
  final EDDSAPublicKey _publicKey;

  /// Private constructor for creating an Ed25519MoneroPublicKey instance from an EDDSAPublicKey.
  Ed25519MoneroPublicKey._(this._publicKey);

  /// Factory method for creating an Ed25519MoneroPublicKey from a byte array.
  factory Ed25519MoneroPublicKey.fromBytes(List<int> keyBytes) {
    return Ed25519MoneroPublicKey._(
        EDDSAPublicKey(Curves.generatorED25519, keyBytes));
  }

  /// Factory method for creating an Ed25519MoneroPublicKey from an EDPoint.
  factory Ed25519MoneroPublicKey.fromPoint(EDPoint point) {
    return Ed25519MoneroPublicKey._(
        EDDSAPublicKey.fromPoint(Curves.generatorED25519, point));
  }

  /// curve type
  @override
  EllipticCurveTypes get curve {
    return EllipticCurveTypes.ed25519Monero;
  }

  /// public key compressed bytes length
  @override
  int get length {
    return Ed25519KeysConst.pubKeyByteLen;
  }

  /// public key uncompressed bytes length
  @override
  int get uncompressedLength {
    return length;
  }

  /// check if bytes is valid for this key
  static bool isValidBytes(List<int> keyBytes) {
    return Ed25519MoneroPrivateKey.isValidBytes(keyBytes);
  }

  /// accsess to public key point
  @override
  EDPoint get point {
    return _publicKey.point;
  }

  /// public key compressed bytes
  @override
  List<int> get compressed {
    return List<int>.from(
        [...Ed25519KeysConst.pubKeyPrefix, ..._publicKey.point.toBytes()]);
  }

  /// public key uncompressed bytes
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

/// A class representing an Ed25519 Monero-compatible private key that implements the IPrivateKey interface.
class Ed25519MoneroPrivateKey implements IPrivateKey {
  final EDDSAPrivateKey _privateKey;

  /// Private constructor for creating an Ed25519MoneroPrivateKey instance from an EDDSAPrivateKey.
  Ed25519MoneroPrivateKey._(this._privateKey);

  /// Factory method for creating an Ed25519MoneroPrivateKey from a byte array.
  /// It checks the length of the provided keyBytes to ensure it matches the expected length.
  /// Then, it initializes an EdDSA private key using the Ed25519 generator and the specified keyBytes.
  factory Ed25519MoneroPrivateKey.fromBytes(List<int> keyBytes) {
    if (keyBytes.length != Ed25519KeysConst.privKeyByteLen) {
      throw const ArgumentException("invalid private key length");
    }
    final gn = Curves.generatorED25519;
    final prv = EDDSAPrivateKey.fromKhalow(gn, keyBytes);
    return Ed25519MoneroPrivateKey._(prv);
  }

  /// curve type
  @override
  EllipticCurveTypes get curveType {
    return EllipticCurveTypes.ed25519Monero;
  }

  /// check if bytes is valid for this key
  static bool isValidBytes(List<int> keyBytes) {
    try {
      Ed25519MoneroPrivateKey.fromBytes(keyBytes);

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

  /// accsess to public key
  @override
  IPublicKey get publicKey {
    return Ed25519MoneroPublicKey._(_privateKey.publicKey);
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
