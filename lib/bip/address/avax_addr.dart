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

import 'package:blockchain_utils/bip/address/decoder.dart';
import 'package:blockchain_utils/bip/address/encoder.dart';
import 'package:blockchain_utils/bip/coin_conf/constant/coins_conf.dart';

import 'addr_dec_utils.dart';
import 'atom_addr.dart';

/// A utility class providing methods for decoding Avax (Avalanche) addresses.
class _AvaxAddrUtils {
  /// Decodes an Avax address with the specified [prefix] and Human-Readable Part (HRP).
  ///
  /// [addr]: The Avax address to decode.
  /// [prefix]: The address prefix to be validated and removed.
  /// [hrp]: The Human-Readable Part (HRP) to use for decoding.
  ///
  /// This method validates and removes the address prefix, then delegates
  /// the decoding process to the [AtomAddrDecoder], providing the [hrp] as a parameter.
  ///
  /// Returns the decoded address as a List.
  static List<int> decodeAddr(String addr, String prefix, String hrp) {
    final addrNoPrefix = AddrDecUtils.validateAndRemovePrefix(addr, prefix);
    return AtomAddrDecoder().decodeAddr(addrNoPrefix, {"hrp": hrp});
  }
}

/// Implementation of the [BlockchainAddressDecoder] for Avax P-Chain address.
class AvaxPChainAddrDecoder implements BlockchainAddressDecoder {
  /// Overrides the address decoding method for Avax P-Chain addresses.
  ///
  /// [addr]: The Avax P-Chain address to decode.
  /// [kwargs]: A map of optional decoding parameters.
  ///
  /// This method delegates the decoding of Avax P-Chain addresses to the
  /// [_AvaxAddrUtils.decodeAddr] method, providing the address prefix and Human-Readable Part (HRP)
  /// from the Avax P-Chain configuration.
  ///
  /// Returns the decoded address as a List.
  @override
  List<int> decodeAddr(String addr, [Map<String, dynamic> kwargs = const {}]) {
    return _AvaxAddrUtils.decodeAddr(
      addr,
      CoinsConf.avaxPChain.params.addrPrefix!,
      CoinsConf.avaxPChain.params.addrHrp!,
    );
  }
}

/// Implementation of the [BlockchainAddressEncoder] for Avax P-Chain address.
class AvaxPChainAddrEncoder implements BlockchainAddressEncoder {
  /// Overrides the address encoding method for Avax P-Chain addresses.
  ///
  /// [pubKey]: The public key to encode into an Avax P-Chain address.
  /// [kwargs]: A map of optional encoding parameters.
  ///
  /// This method constructs an Avax P-Chain address by combining the address prefix
  /// with the result of encoding the public key using the AtomAddrEncoder with the
  /// Human-Readable Part (HRP) from the Avax P-Chain configuration.
  ///
  /// Returns the encoded Avax P-Chain address as a String.
  @override
  String encodeKey(List<int> pubKey, [Map<String, dynamic> kwargs = const {}]) {
    final String prefix = CoinsConf.avaxPChain.params.addrPrefix!;
    return prefix +
        AtomAddrEncoder().encodeKey(
          pubKey,
          {"hrp": CoinsConf.avaxPChain.params.addrHrp!},
        );
  }
}

/// Implementation of the [BlockchainAddressDecoder] for Avax X-Chain address.
class AvaxXChainAddrDecoder implements BlockchainAddressDecoder {
  /// Overrides the address decoding method for Avax X-Chain addresses.
  ///
  /// [addr]: The Avax X-Chain address to decode.
  /// [kwargs]: A map of optional decoding parameters.
  ///
  /// This method delegates the decoding of Avax X-Chain addresses to the
  /// [_AvaxAddrUtils.decodeAddr] method, providing the address prefix and Human-Readable Part (HRP)
  /// from the Avax P-Chain configuration.
  ///
  /// Returns the decoded address as a List.
  @override
  List<int> decodeAddr(String addr, [Map<String, dynamic> kwargs = const {}]) {
    return _AvaxAddrUtils.decodeAddr(
      addr,
      CoinsConf.avaxXChain.params.addrPrefix!,
      CoinsConf.avaxXChain.params.addrHrp!,
    );
  }
}

/// Implementation of the [BlockchainAddressEncoder] for Avax X-Chain address.
class AvaxXChainAddrEncoder implements BlockchainAddressEncoder {
  /// Overrides the address encoding method for Avax X-Chain addresses.
  ///
  /// [pubKey]: The public key to encode into an Avax X-Chain address.
  /// [kwargs]: A map of optional encoding parameters.
  ///
  /// This method constructs an Avax X-Chain address by combining the address prefix
  /// with the result of encoding the public key using the AtomAddrEncoder with the
  /// Human-Readable Part (HRP) from the Avax X-Chain configuration.
  ///
  /// Returns the encoded Avax X-Chain address as a String.
  @override
  String encodeKey(List<int> pubKey, [Map<String, dynamic> kwargs = const {}]) {
    final String prefix = CoinsConf.avaxXChain.params.addrPrefix!;
    return prefix +
        AtomAddrEncoder().encodeKey(
          pubKey,
          {"hrp": CoinsConf.avaxXChain.params.addrHrp!},
        );
  }
}
