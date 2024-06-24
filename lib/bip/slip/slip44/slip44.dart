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

/// SLIP-0044 class.
/// It defines the coin types in accordance with SLIP-0044.
class Slip44 {
  static const int bitcoin = 0;
  static const int testnet = 1;
  static const int litecoin = 2;
  static const int dogecoin = 3;
  static const int dash = 5;
  static const int ethereum = 60;
  static const int ethereumClassic = 61;
  static const int icon = 74;
  static const int verge = 77;
  static const int atom = 118;
  static const int monero = 128;
  static const int zcash = 133;
  static const int ripple = 144;
  static const int bitcoinCash = 145;
  static const int stellar = 148;
  static const int nano = 165;
  static const int eos = 194;
  static const int tron = 195;
  static const int bitcoinSv = 236;
  static const int algorand = 283;
  static const int zilliqa = 313;
  static const int ton = 607;
  static const int terra = 330;
  static const int polkadot = 354;
  static const int nearProtocol = 397;
  static const int ergo = 429;
  static const int kusama = 434;
  static const int kava = 459;
  static const int filecoin = 461;
  static const int bandProtocol = 494;
  static const int theta = 500;
  static const int solana = 501;
  static const int elrond = 508;
  static const int secretNetwork = 529;
  static const int nineChronicles = 567;
  static const int aptos = 637;
  static const int binanceChain = 714;
  static const int vechain = 818;
  static const int neo = 888;
  static const int okexChain = 996;
  static const int harmonyOne = 1023;
  static const int ontology = 1024;
  static const int tezos = 1729;
  static const int cardano = 1815;
  static const int avalanche = 9000;
  static const int celo = 52752;
  static const int piNetwork = 314159;

  /// Unofficial coin id
  static const int pepecoin = 3434;
}
