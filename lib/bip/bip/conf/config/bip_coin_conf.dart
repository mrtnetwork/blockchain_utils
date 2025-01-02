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

import 'package:blockchain_utils/bip/address/encoder.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_key_net_ver.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_keys.dart';
import 'package:blockchain_utils/bip/bip/conf/core/coin_conf.dart';
import 'package:blockchain_utils/bip/ecc/curve/elliptic_curve_types.dart';
import 'package:blockchain_utils/bip/coin_conf/models/coins_name.dart';

/// A base class representing configuration parameters for a cryptocurrency coin.
class BipCoinConfig implements CoinConfig {
  /// Returns the address encoder for this coin configuration.
  BlockchainAddressEncoder encoder() {
    return addressEncoder();
  }

  /// Configuration properties.
  @override
  final CoinNames coinNames;
  final int coinIdx;
  @override
  final ChainType chainType;
  final String defPath;
  @override
  final Bip32KeyNetVersions keyNetVer;
  @override
  final List<int>? wifNetVer;
  @override
  final AddrEncoder addressEncoder;
  @override
  final Map<String, dynamic> addrParams;
  @override
  final EllipticCurveTypes type;

  /// Creates a copy of the BipCoinConfig object with optional properties updated.
  BipCoinConfig copy({
    CoinNames? coinNames,
    int? coinIdx,
    ChainType? chainType,
    String? defPath,
    Bip32KeyNetVersions? keyNetVer,
    List<int>? wifNetVer,
    Map<String, dynamic>? addrParams,
    EllipticCurveTypes? type,
    AddrEncoder? addressEncoder,
  }) {
    return BipCoinConfig(
        coinNames: coinNames ?? this.coinNames,
        coinIdx: coinIdx ?? this.coinIdx,
        chainType: chainType ?? this.chainType,
        defPath: defPath ?? this.defPath,
        keyNetVer: keyNetVer ?? this.keyNetVer,
        wifNetVer: wifNetVer ?? this.wifNetVer,
        addrParams: addrParams ?? this.addrParams,
        type: type ?? this.type,
        addressEncoder: addressEncoder ?? this.addressEncoder);
  }

  /// Constructor for BipCoinConfig.
  const BipCoinConfig({
    required this.coinNames,
    required this.coinIdx,
    required this.chainType,
    required this.defPath,
    required this.keyNetVer,
    required this.wifNetVer,
    required this.addrParams,
    required this.type,
    required this.addressEncoder,
  });

  /// Get address parameters with optional chain code inclusion.
  /// If 'chain_code' is specified in 'addrParams', it will be replaced with the chain code
  /// from the provided 'pubKey'.
  Map<String, dynamic> getParams(Bip32PublicKey pubKey) {
    if (addrParams["chain_code"] == true) {
      final params = {...addrParams};
      params["chain_code"] = pubKey.chainCode.toBytes();
      return params;
    }
    return addrParams;
  }

  @override
  bool get hasExtendedKeys => true;

  @override
  bool get hasWif => wifNetVer != null;
}
