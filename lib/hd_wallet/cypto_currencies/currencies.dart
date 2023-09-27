/// copied from https://github.com/meherett/python-hdwallet/blob/master/hdwallet/cryptocurrencies.py

part of 'package:blockchain_utils/hd_wallet/cypto_currencies/cyrpto_currency.dart';

final Map<String, dynamic> currenciesData = {
  "ANON": {
    "SYMBOL": "ANON",
    "NAME": "Anon",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 220, "HARDENED": true},
    "SCRIPT_ADDRESS": 21385,
    "PUBLIC_KEY_ADDRESS": 1410,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018ANON Signed Message:\n",
    "DEFAULT_PATH": "m/44'/220'/0'/0/0",
    "WIF_SECRET_KEY": 128
  },
  "AGM": {
    "SYMBOL": "AGM",
    "NAME": "Argoneum",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 421, "HARDENED": true},
    "SCRIPT_ADDRESS": 97,
    "PUBLIC_KEY_ADDRESS": 50,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": null,
    "DEFAULT_PATH": "m/44'/421'/0'/0/0",
    "WIF_SECRET_KEY": 191
  },
  "XAX": {
    "SYMBOL": "XAX",
    "NAME": "Artax",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 219, "HARDENED": true},
    "SCRIPT_ADDRESS": 7357,
    "PUBLIC_KEY_ADDRESS": 23,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018Artax Signed Message:\n",
    "DEFAULT_PATH": "m/44'/219'/0'/0/0",
    "WIF_SECRET_KEY": 151
  },
  "AYA": {
    "SYMBOL": "AYA",
    "NAME": "Aryacoin",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 357, "HARDENED": true},
    "SCRIPT_ADDRESS": 111,
    "PUBLIC_KEY_ADDRESS": 23,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018Aryacoin Signed Message:\n",
    "DEFAULT_PATH": "m/44'/357'/0'/0/0",
    "WIF_SECRET_KEY": 151
  },
  "AC": {
    "SYMBOL": "AC",
    "NAME": "Asiacoin",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 51, "HARDENED": true},
    "SCRIPT_ADDRESS": 8,
    "PUBLIC_KEY_ADDRESS": 23,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018AsiaCoin Signed Message:\n",
    "DEFAULT_PATH": "m/44'/51'/0'/0/0",
    "WIF_SECRET_KEY": 151
  },
  "ATOM": {
    "SYMBOL": "ATOM",
    "NAME": "Atom",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 118, "HARDENED": true},
    "SCRIPT_ADDRESS": 10,
    "PUBLIC_KEY_ADDRESS": 23,
    "SEGWIT_ADDRESS": {"HRP": "atom", "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": 76066276,
      "P2WPKH_IN_P2SH": 76066276,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": 76067358,
      "P2WPKH_IN_P2SH": 76067358,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018Bitcoin Atom Signed Message:\n",
    "DEFAULT_PATH": "m/44'/118'/0'/0/0",
    "WIF_SECRET_KEY": 128
  },
  "AUR": {
    "SYMBOL": "AUR",
    "NAME": "Auroracoin",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 85, "HARDENED": true},
    "SCRIPT_ADDRESS": 5,
    "PUBLIC_KEY_ADDRESS": 23,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018AuroraCoin Signed Message:\n",
    "DEFAULT_PATH": "m/44'/85'/0'/0/0",
    "WIF_SECRET_KEY": 151
  },
  "AXE": {
    "SYMBOL": "AXE",
    "NAME": "Axe",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 4242, "HARDENED": true},
    "SCRIPT_ADDRESS": 16,
    "PUBLIC_KEY_ADDRESS": 55,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": null,
    "DEFAULT_PATH": "m/44'/4242'/0'/0/0",
    "WIF_SECRET_KEY": 204
  },
  "BTA": {
    "SYMBOL": "BTA",
    "NAME": "Bata",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 89, "HARDENED": true},
    "SCRIPT_ADDRESS": 5,
    "PUBLIC_KEY_ADDRESS": 25,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 2752221629,
      "P2SH": 2752221629,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 2752284410,
      "P2SH": 2752284410,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018Bata Signed Message:\n",
    "DEFAULT_PATH": "m/44'/89'/0'/0/0",
    "WIF_SECRET_KEY": 164
  },
  "BEET": {
    "SYMBOL": "BEET",
    "NAME": "Beetle Coin",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 800, "HARDENED": true},
    "SCRIPT_ADDRESS": 85,
    "PUBLIC_KEY_ADDRESS": 26,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0019Beetlecoin Signed Message:\n",
    "DEFAULT_PATH": "m/44'/800'/0'/0/0",
    "WIF_SECRET_KEY": 153
  },
  "BELA": {
    "SYMBOL": "BELA",
    "NAME": "Bela Coin",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 73, "HARDENED": true},
    "SCRIPT_ADDRESS": 5,
    "PUBLIC_KEY_ADDRESS": 25,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018BelaCoin Signed Message:\n",
    "DEFAULT_PATH": "m/44'/73'/0'/0/0",
    "WIF_SECRET_KEY": 153
  },
  "BTDX": {
    "SYMBOL": "BTDX",
    "NAME": "Bit Cloud",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 218, "HARDENED": true},
    "SCRIPT_ADDRESS": 5,
    "PUBLIC_KEY_ADDRESS": 25,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018BitCloud Signed Message:\n",
    "DEFAULT_PATH": "m/44'/218'/0'/0/0",
    "WIF_SECRET_KEY": 153
  },
  "BSD": {
    "SYMBOL": "BSD",
    "NAME": "Bit Send",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 91, "HARDENED": true},
    "SCRIPT_ADDRESS": 5,
    "PUBLIC_KEY_ADDRESS": 102,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018Bitsend Signed Message:\n",
    "DEFAULT_PATH": "m/44'/91'/0'/0/0",
    "WIF_SECRET_KEY": 204
  },
  "BCH": {
    "SYMBOL": "BCH",
    "NAME": "Bitcoin Cash",
    "NETWORK": "mainnet",
    "SOURCE_CODE": "https://github.com/bitcoincashorg/bitcoincash.org",
    "COIN_TYPE": {"INDEX": 145, "HARDENED": true},
    "SCRIPT_ADDRESS": 40,
    "PUBLIC_KEY_ADDRESS": 28,
    "SEGWIT_ADDRESS": {"HRP": "bc", "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": 78791436,
      "P2WPKH_IN_P2SH": 77428856,
      "P2WSH": 44726937,
      "P2WSH_IN_P2SH": 43364357
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": 78792518,
      "P2WPKH_IN_P2SH": 77429938,
      "P2WSH": 44728019,
      "P2WSH_IN_P2SH": 43365439
    },
    "MESSAGE_PREFIX": null,
    "DEFAULT_PATH": "m/44'/145'/0'/0/0",
    "WIF_SECRET_KEY": 128
  },
  "BTG": {
    "SYMBOL": "BTG",
    "NAME": "Bitcoin Gold",
    "NETWORK": "mainnet",
    "SOURCE_CODE": "https://github.com/BTCGPU/BTCGPU",
    "COIN_TYPE": {"INDEX": 156, "HARDENED": true},
    "SCRIPT_ADDRESS": 23,
    "PUBLIC_KEY_ADDRESS": 38,
    "SEGWIT_ADDRESS": {"HRP": "btg", "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": 78791436,
      "P2WPKH_IN_P2SH": 77428856,
      "P2WSH": 44726937,
      "P2WSH_IN_P2SH": 43364357
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": 78792518,
      "P2WPKH_IN_P2SH": 77429938,
      "P2WSH": 44728019,
      "P2WSH_IN_P2SH": 43365439
    },
    "MESSAGE_PREFIX": "\u001dBitcoin Gold Signed Message:\n",
    "DEFAULT_PATH": "m/44'/156'/0'/0/0",
    "WIF_SECRET_KEY": 128
  },
  "BTC": {
    "SYMBOL": "BTC",
    "NAME": "Bitcoin",
    "NETWORK": "mainnet",
    "SOURCE_CODE": "https://github.com/bitcoin/bitcoin",
    "COIN_TYPE": {"INDEX": 0, "HARDENED": true},
    "SCRIPT_ADDRESS": 5,
    "PUBLIC_KEY_ADDRESS": 0,
    "SEGWIT_ADDRESS": {"HRP": "bc", "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": 78791436,
      "P2WPKH_IN_P2SH": 77428856,
      "P2WSH": 44726937,
      "P2WSH_IN_P2SH": 43364357
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": 78792518,
      "P2WPKH_IN_P2SH": 77429938,
      "P2WSH": 44728019,
      "P2WSH_IN_P2SH": 43365439
    },
    "MESSAGE_PREFIX": "\u0018Bitcoin Signed Message:\n",
    "DEFAULT_PATH": "m/44'/0'/0'/0/0",
    "WIF_SECRET_KEY": 128
  },
  "XBC": {
    "SYMBOL": "XBC",
    "NAME": "Bitcoin Plus",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 65, "HARDENED": true},
    "SCRIPT_ADDRESS": 8,
    "PUBLIC_KEY_ADDRESS": 25,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018BitcoinPlus Signed Message:\n",
    "DEFAULT_PATH": "m/44'/65'/0'/0/0",
    "WIF_SECRET_KEY": 153
  },
  "BSV": {
    "SYMBOL": "BSV",
    "NAME": "Bitcoin SV",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 236, "HARDENED": true},
    "SCRIPT_ADDRESS": 5,
    "PUBLIC_KEY_ADDRESS": 0,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": null,
    "DEFAULT_PATH": "m/44'/236'/0'/0/0",
    "WIF_SECRET_KEY": 128
  },
  "BTCTEST": {
    "SYMBOL": "BTCTEST",
    "NAME": "Bitcoin",
    "NETWORK": "testnet",
    "SOURCE_CODE": "https://github.com/bitcoin/bitcoin",
    "COIN_TYPE": {"INDEX": 1, "HARDENED": true},
    "SCRIPT_ADDRESS": 196,
    "PUBLIC_KEY_ADDRESS": 111,
    "SEGWIT_ADDRESS": {"HRP": "tb", "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 70615956,
      "P2SH": 70615956,
      "P2WPKH": 73341116,
      "P2WPKH_IN_P2SH": 71978536,
      "P2WSH": 39276616,
      "P2WSH_IN_P2SH": 37914037
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 70617039,
      "P2SH": 70617039,
      "P2WPKH": 73342198,
      "P2WPKH_IN_P2SH": 71979618,
      "P2WSH": 39277699,
      "P2WSH_IN_P2SH": 37915119
    },
    "MESSAGE_PREFIX": "\u0018Bitcoin Signed Message:\n",
    "DEFAULT_PATH": "m/44'/1'/0'/0/0",
    "WIF_SECRET_KEY": 239
  },
  "BTCZ": {
    "SYMBOL": "BTCZ",
    "NAME": "BitcoinZ",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 177, "HARDENED": true},
    "SCRIPT_ADDRESS": 7357,
    "PUBLIC_KEY_ADDRESS": 7352,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018BitcoinZ Signed Message:\n",
    "DEFAULT_PATH": "m/44'/177'/0'/0/0",
    "WIF_SECRET_KEY": 128
  },
  "BTX": {
    "SYMBOL": "BTX",
    "NAME": "Bitcore",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 160, "HARDENED": true},
    "SCRIPT_ADDRESS": 125,
    "PUBLIC_KEY_ADDRESS": 3,
    "SEGWIT_ADDRESS": {"HRP": "bitcore", "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": 76066276,
      "P2WPKH_IN_P2SH": 76066276,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": 76067358,
      "P2WPKH_IN_P2SH": 76067358,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018BitCore Signed Message:\n",
    "DEFAULT_PATH": "m/44'/160'/0'/0/0",
    "WIF_SECRET_KEY": 128
  },
  "BLK": {
    "SYMBOL": "BLK",
    "NAME": "Blackcoin",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 10, "HARDENED": true},
    "SCRIPT_ADDRESS": 85,
    "PUBLIC_KEY_ADDRESS": 25,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 47169376,
      "P2SH": 47169376,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 47169246,
      "P2SH": 47169246,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018BlackCoin Signed Message:\n",
    "DEFAULT_PATH": "m/44'/10'/0'/0/0",
    "WIF_SECRET_KEY": 153
  },
  "BST": {
    "SYMBOL": "BST",
    "NAME": "Block Stamp",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 254, "HARDENED": true},
    "SCRIPT_ADDRESS": 5,
    "PUBLIC_KEY_ADDRESS": 0,
    "SEGWIT_ADDRESS": {"HRP": "bc", "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": 76066276,
      "P2WPKH_IN_P2SH": 76066276,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": 76067358,
      "P2WPKH_IN_P2SH": 76067358,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018BlockStamp Signed Message:\n",
    "DEFAULT_PATH": "m/44'/254'/0'/0/0",
    "WIF_SECRET_KEY": 128
  },
  "BND": {
    "SYMBOL": "BND",
    "NAME": "Blocknode",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 2941, "HARDENED": true},
    "SCRIPT_ADDRESS": 63,
    "PUBLIC_KEY_ADDRESS": 25,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018Blocknode Signed Message:\n",
    "DEFAULT_PATH": "m/44'/2941'/0'/0/0",
    "WIF_SECRET_KEY": 75
  },
  "BNDTEST": {
    "SYMBOL": "BNDTEST",
    "NAME": "Blocknode",
    "NETWORK": "testnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 1, "HARDENED": true},
    "SCRIPT_ADDRESS": 125,
    "PUBLIC_KEY_ADDRESS": 85,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 70615956,
      "P2SH": 70615956,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 70617039,
      "P2SH": 70617039,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018Blocknode Testnet Signed Message:\n",
    "DEFAULT_PATH": "m/44'/1'/0'/0/0",
    "WIF_SECRET_KEY": 137
  },
  "BOLI": {
    "SYMBOL": "BOLI",
    "NAME": "Bolivarcoin",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 278, "HARDENED": true},
    "SCRIPT_ADDRESS": 5,
    "PUBLIC_KEY_ADDRESS": 85,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "Bolivarcoin Signed Message:\n",
    "DEFAULT_PATH": "m/44'/278'/0'/0/0",
    "WIF_SECRET_KEY": 213
  },
  "BRIT": {
    "SYMBOL": "BRIT",
    "NAME": "Brit Coin",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 70, "HARDENED": true},
    "SCRIPT_ADDRESS": 85,
    "PUBLIC_KEY_ADDRESS": 25,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018BritCoin Signed Message:\n",
    "DEFAULT_PATH": "m/44'/70'/0'/0/0",
    "WIF_SECRET_KEY": 153
  },
  "CPU": {
    "SYMBOL": "CPU",
    "NAME": "CPU Chain",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 363, "HARDENED": true},
    "SCRIPT_ADDRESS": 30,
    "PUBLIC_KEY_ADDRESS": 28,
    "SEGWIT_ADDRESS": {"HRP": "cpu", "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": 78791436,
      "P2WPKH_IN_P2SH": 77428856,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": 78792518,
      "P2WPKH_IN_P2SH": 77429938,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u001dCPUchain Signed Message:\n",
    "DEFAULT_PATH": "m/44'/363'/0'/0/0",
    "WIF_SECRET_KEY": 128
  },
  "CDN": {
    "SYMBOL": "CDN",
    "NAME": "Canada eCoin",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 34, "HARDENED": true},
    "SCRIPT_ADDRESS": 5,
    "PUBLIC_KEY_ADDRESS": 28,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018Canada eCoin Signed Message:\n",
    "DEFAULT_PATH": "m/44'/34'/0'/0/0",
    "WIF_SECRET_KEY": 156
  },
  "CCN": {
    "SYMBOL": "CCN",
    "NAME": "Cannacoin",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 19, "HARDENED": true},
    "SCRIPT_ADDRESS": 5,
    "PUBLIC_KEY_ADDRESS": 28,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018Cannacoin Signed Message:\n",
    "DEFAULT_PATH": "m/44'/19'/0'/0/0",
    "WIF_SECRET_KEY": 156
  },
  "CLAM": {
    "SYMBOL": "CLAM",
    "NAME": "Clams",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 23, "HARDENED": true},
    "SCRIPT_ADDRESS": 13,
    "PUBLIC_KEY_ADDRESS": 137,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 2831251494,
      "P2SH": 2831251494,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 2831314276,
      "P2SH": 2831314276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": null,
    "DEFAULT_PATH": "m/44'/23'/0'/0/0",
    "WIF_SECRET_KEY": 133
  },
  "CLUB": {
    "SYMBOL": "CLUB",
    "NAME": "Club Coin",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 79, "HARDENED": true},
    "SCRIPT_ADDRESS": 85,
    "PUBLIC_KEY_ADDRESS": 28,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018ClubCoin Signed Message:\n",
    "DEFAULT_PATH": "m/44'/79'/0'/0/0",
    "WIF_SECRET_KEY": 153
  },
  "CMP": {
    "SYMBOL": "CMP",
    "NAME": "Compcoin",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 71, "HARDENED": true},
    "SCRIPT_ADDRESS": 85,
    "PUBLIC_KEY_ADDRESS": 28,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018CompCoin Signed Message:\n",
    "DEFAULT_PATH": "m/44'/71'/0'/0/0",
    "WIF_SECRET_KEY": 156
  },
  "CRP": {
    "SYMBOL": "CRP",
    "NAME": "Crane Pay",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 2304, "HARDENED": true},
    "SCRIPT_ADDRESS": 10,
    "PUBLIC_KEY_ADDRESS": 28,
    "SEGWIT_ADDRESS": {"HRP": "cp", "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": 78791436,
      "P2WPKH_IN_P2SH": 77428856,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": 78792518,
      "P2WPKH_IN_P2SH": 77429938,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018Bitcoin Signed Message:\n",
    "DEFAULT_PATH": "m/44'/2304'/0'/0/0",
    "WIF_SECRET_KEY": 123
  },
  "CRAVE": {
    "SYMBOL": "CRAVE",
    "NAME": "Crave",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 186, "HARDENED": true},
    "SCRIPT_ADDRESS": 85,
    "PUBLIC_KEY_ADDRESS": 70,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018DarkNet Signed Message:\n",
    "DEFAULT_PATH": "m/44'/186'/0'/0/0",
    "WIF_SECRET_KEY": 153
  },
  "DASH": {
    "SYMBOL": "DASH",
    "NAME": "Dash",
    "NETWORK": "mainnet",
    "SOURCE_CODE": "https://github.com/dashpay/dash",
    "COIN_TYPE": {"INDEX": 5, "HARDENED": true},
    "SCRIPT_ADDRESS": 16,
    "PUBLIC_KEY_ADDRESS": 76,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018Bitcoin Signed Message:\n",
    "DEFAULT_PATH": "m/44'/5'/0'/0/0",
    "WIF_SECRET_KEY": 204
  },
  "DASHTEST": {
    "SYMBOL": "DASHTEST",
    "NAME": "Dash",
    "NETWORK": "testnet",
    "SOURCE_CODE": "https://github.com/dashpay/dash",
    "COIN_TYPE": {"INDEX": 1, "HARDENED": true},
    "SCRIPT_ADDRESS": 19,
    "PUBLIC_KEY_ADDRESS": 140,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 70615956,
      "P2SH": 70615956,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 70617039,
      "P2SH": 70617039,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018Bitcoin Signed Message:\n",
    "DEFAULT_PATH": "m/44'/1'/0'/0/0",
    "WIF_SECRET_KEY": 239
  },
  "ONION": {
    "SYMBOL": "ONION",
    "NAME": "Deep Onion",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 305, "HARDENED": true},
    "SCRIPT_ADDRESS": 78,
    "PUBLIC_KEY_ADDRESS": 31,
    "SEGWIT_ADDRESS": {"HRP": "dpn", "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": 76066276,
      "P2WPKH_IN_P2SH": 76066276,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": 76067358,
      "P2WPKH_IN_P2SH": 76067358,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018DeepOnion Signed Message:\n",
    "DEFAULT_PATH": "m/44'/305'/0'/0/0",
    "WIF_SECRET_KEY": 159
  },
  "DFC": {
    "SYMBOL": "DFC",
    "NAME": "Defcoin",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 1337, "HARDENED": true},
    "SCRIPT_ADDRESS": 5,
    "PUBLIC_KEY_ADDRESS": 30,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018defcoin Signed Message:\n",
    "DEFAULT_PATH": "m/44'/1337'/0'/0/0",
    "WIF_SECRET_KEY": 158
  },
  "DNR": {
    "SYMBOL": "DNR",
    "NAME": "Denarius",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 116, "HARDENED": true},
    "SCRIPT_ADDRESS": 90,
    "PUBLIC_KEY_ADDRESS": 30,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0019Denarius Signed Message:\n",
    "DEFAULT_PATH": "m/44'/116'/0'/0/0",
    "WIF_SECRET_KEY": 158
  },
  "DMD": {
    "SYMBOL": "DMD",
    "NAME": "Diamond",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 152, "HARDENED": true},
    "SCRIPT_ADDRESS": 8,
    "PUBLIC_KEY_ADDRESS": 90,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018Diamond Signed Message:\n",
    "DEFAULT_PATH": "m/44'/152'/0'/0/0",
    "WIF_SECRET_KEY": 218
  },
  "DGB": {
    "SYMBOL": "DGB",
    "NAME": "Digi Byte",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 20, "HARDENED": true},
    "SCRIPT_ADDRESS": 5,
    "PUBLIC_KEY_ADDRESS": 30,
    "SEGWIT_ADDRESS": {"HRP": "dgb", "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": 78791436,
      "P2WPKH_IN_P2SH": 77428856,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": 78792518,
      "P2WPKH_IN_P2SH": 77429938,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0019DigiByte Signed Message:\n",
    "DEFAULT_PATH": "m/44'/20'/0'/0/0",
    "WIF_SECRET_KEY": 128
  },
  "DGC": {
    "SYMBOL": "DGC",
    "NAME": "Digitalcoin",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 18, "HARDENED": true},
    "SCRIPT_ADDRESS": 5,
    "PUBLIC_KEY_ADDRESS": 30,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 2651097266,
      "P2SH": 2651097266,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018Digitalcoin Signed Message:\n",
    "DEFAULT_PATH": "m/44'/18'/0'/0/0",
    "WIF_SECRET_KEY": 158
  },
  "DOGE": {
    "SYMBOL": "DOGE",
    "NAME": "Dogecoin",
    "NETWORK": "mainnet",
    "SOURCE_CODE": "https://github.com/dogecoin/dogecoin",
    "COIN_TYPE": {"INDEX": 3, "HARDENED": true},
    "SCRIPT_ADDRESS": 22,
    "PUBLIC_KEY_ADDRESS": 30,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 49988504,
      "P2SH": 49988504,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 49990397,
      "P2SH": 49990397,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0019Dogecoin Signed Message:\n",
    "DEFAULT_PATH": "m/44'/3'/0'/0/0",
    "WIF_SECRET_KEY": 241
  },
  "DOGETEST": {
    "SYMBOL": "DOGETEST",
    "NAME": "Dogecoin",
    "NETWORK": "testnet",
    "SOURCE_CODE": "https://github.com/dogecoin/dogecoin",
    "COIN_TYPE": {"INDEX": 3, "HARDENED": true},
    "SCRIPT_ADDRESS": 196,
    "PUBLIC_KEY_ADDRESS": 113,
    "SEGWIT_ADDRESS": {"HRP": "dogecointestnet", "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 70615956,
      "P2SH": 70615956,
      "P2WPKH": 70615956,
      "P2WPKH_IN_P2SH": 70615956,
      "P2WSH": 70615956,
      "P2WSH_IN_P2SH": 70615956
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 70617039,
      "P2SH": 70617039,
      "P2WPKH": 70617039,
      "P2WPKH_IN_P2SH": 70617039,
      "P2WSH": 70617039,
      "P2WSH_IN_P2SH": 70617039
    },
    "MESSAGE_PREFIX": "\u0019Dogecoin Signed Message:\n",
    "DEFAULT_PATH": "m/44'/3'/0'/0/0",
    "WIF_SECRET_KEY": 241
  },
  "EDRC": {
    "SYMBOL": "EDRC",
    "NAME": "EDR Coin",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 56, "HARDENED": true},
    "SCRIPT_ADDRESS": 28,
    "PUBLIC_KEY_ADDRESS": 93,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018EDRcoin Signed Message:\n",
    "DEFAULT_PATH": "m/44'/56'/0'/0/0",
    "WIF_SECRET_KEY": 221
  },
  "ECN": {
    "SYMBOL": "ECN",
    "NAME": "Ecoin",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 115, "HARDENED": true},
    "SCRIPT_ADDRESS": 20,
    "PUBLIC_KEY_ADDRESS": 92,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018eCoin Signed Message:\n",
    "DEFAULT_PATH": "m/44'/115'/0'/0/0",
    "WIF_SECRET_KEY": 220
  },
  "EMC2": {
    "SYMBOL": "EMC2",
    "NAME": "Einsteinium",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 41, "HARDENED": true},
    "SCRIPT_ADDRESS": 5,
    "PUBLIC_KEY_ADDRESS": 33,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018Einsteinium Signed Message:\n",
    "DEFAULT_PATH": "m/44'/41'/0'/0/0",
    "WIF_SECRET_KEY": 161
  },
  "ELA": {
    "SYMBOL": "ELA",
    "NAME": "Elastos",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 2305, "HARDENED": true},
    "SCRIPT_ADDRESS": 196,
    "PUBLIC_KEY_ADDRESS": 33,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": null,
    "DEFAULT_PATH": "m/44'/2305'/0'/0/0",
    "WIF_SECRET_KEY": 239
  },
  "NRG": {
    "SYMBOL": "NRG",
    "NAME": "Energi",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 9797, "HARDENED": true},
    "SCRIPT_ADDRESS": 53,
    "PUBLIC_KEY_ADDRESS": 33,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 3621547679,
      "P2SH": 3621547679,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 62441558,
      "P2SH": 62441558,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "DarkCoin Signed Message:\n",
    "DEFAULT_PATH": "m/44'/9797'/0'/0/0",
    "WIF_SECRET_KEY": 106
  },
  "ETH": {
    "SYMBOL": "ETH",
    "NAME": "Ethereum",
    "NETWORK": "mainnet",
    "SOURCE_CODE": "https://github.com/ethereum/go-ethereum",
    "COIN_TYPE": {"INDEX": 60, "HARDENED": true},
    "SCRIPT_ADDRESS": 5,
    "PUBLIC_KEY_ADDRESS": 0,
    "SEGWIT_ADDRESS": {"HRP": "bc", "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": 78791436,
      "P2WPKH_IN_P2SH": 77428856,
      "P2WSH": 44726937,
      "P2WSH_IN_P2SH": 43364357
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": 78792518,
      "P2WPKH_IN_P2SH": 77429938,
      "P2WSH": 44728019,
      "P2WSH_IN_P2SH": 43365439
    },
    "MESSAGE_PREFIX": null,
    "DEFAULT_PATH": "m/44'/60'/0'/0/0",
    "WIF_SECRET_KEY": 128
  },
  "ERC": {
    "SYMBOL": "ERC",
    "NAME": "Europe Coin",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 151, "HARDENED": true},
    "SCRIPT_ADDRESS": 5,
    "PUBLIC_KEY_ADDRESS": 33,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018Bitcoin Signed Message:\n",
    "DEFAULT_PATH": "m/44'/151'/0'/0/0",
    "WIF_SECRET_KEY": 168
  },
  "EXCL": {
    "SYMBOL": "EXCL",
    "NAME": "Exclusive Coin",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 190, "HARDENED": true},
    "SCRIPT_ADDRESS": 137,
    "PUBLIC_KEY_ADDRESS": 33,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018ExclusiveCoin Signed Message:\n",
    "DEFAULT_PATH": "m/44'/190'/0'/0/0",
    "WIF_SECRET_KEY": 161
  },
  "FIX": {
    "SYMBOL": "FIX",
    "NAME": "FIX",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 336, "HARDENED": true},
    "SCRIPT_ADDRESS": 95,
    "PUBLIC_KEY_ADDRESS": 35,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 35729707,
      "P2SH": 35729707,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 36513075,
      "P2SH": 36513075,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": null,
    "DEFAULT_PATH": "m/44'/336'/0'/0/0",
    "WIF_SECRET_KEY": 60
  },
  "FIXTEST": {
    "SYMBOL": "FIXTEST",
    "NAME": "FIX",
    "NETWORK": "testnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 1, "HARDENED": true},
    "SCRIPT_ADDRESS": 137,
    "PUBLIC_KEY_ADDRESS": 76,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 981489719,
      "P2SH": 981489719,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 981492128,
      "P2SH": 981492128,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": null,
    "DEFAULT_PATH": "m/44'/1'/0'/0/0",
    "WIF_SECRET_KEY": 237
  },
  "FTC": {
    "SYMBOL": "FTC",
    "NAME": "Feathercoin",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 8, "HARDENED": true},
    "SCRIPT_ADDRESS": 5,
    "PUBLIC_KEY_ADDRESS": 14,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76077806,
      "P2SH": 76077806,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76069926,
      "P2SH": 76069926,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018Feathercoin Signed Message:\n",
    "DEFAULT_PATH": "m/44'/8'/0'/0/0",
    "WIF_SECRET_KEY": 142
  },
  "FRST": {
    "SYMBOL": "FRST",
    "NAME": "Firstcoin",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 167, "HARDENED": true},
    "SCRIPT_ADDRESS": 5,
    "PUBLIC_KEY_ADDRESS": 35,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018FirstCoin Signed Message:\n",
    "DEFAULT_PATH": "m/44'/167'/0'/0/0",
    "WIF_SECRET_KEY": 163
  },
  "FLASH": {
    "SYMBOL": "FLASH",
    "NAME": "Flashcoin",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 120, "HARDENED": true},
    "SCRIPT_ADDRESS": 130,
    "PUBLIC_KEY_ADDRESS": 68,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018Flashcoin Signed Message:\n",
    "DEFAULT_PATH": "m/44'/120'/0'/0/0",
    "WIF_SECRET_KEY": 196
  },
  "FLUX": {
    "SYMBOL": "FLUX",
    "NAME": "Flux",
    "NETWORK": "mainnet",
    "SOURCE_CODE": "https://github.com/RunOnFlux/fluxd",
    "COIN_TYPE": {"INDEX": 19167, "HARDENED": true},
    "SCRIPT_ADDRESS": 7357,
    "PUBLIC_KEY_ADDRESS": 7352,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018Zelcash Signed Message:\n",
    "DEFAULT_PATH": "m/44'/19167'/0'/0/0",
    "WIF_SECRET_KEY": 128
  },
  "FJC": {
    "SYMBOL": "FJC",
    "NAME": "Fuji Coin",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 75, "HARDENED": true},
    "SCRIPT_ADDRESS": 16,
    "PUBLIC_KEY_ADDRESS": 36,
    "SEGWIT_ADDRESS": {"HRP": "fc", "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": 78791436,
      "P2WPKH_IN_P2SH": 77428856,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": 78792518,
      "P2WPKH_IN_P2SH": 77429938,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0019FujiCoin Signed Message:\n",
    "DEFAULT_PATH": "m/44'/75'/0'/0/0",
    "WIF_SECRET_KEY": 164
  },
  "GCR": {
    "SYMBOL": "GCR",
    "NAME": "GCR Coin",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 49, "HARDENED": true},
    "SCRIPT_ADDRESS": 97,
    "PUBLIC_KEY_ADDRESS": 38,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018GCR Signed Message:\n",
    "DEFAULT_PATH": "m/44'/49'/0'/0/0",
    "WIF_SECRET_KEY": 154
  },
  "GAME": {
    "SYMBOL": "GAME",
    "NAME": "Game Credits",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 101, "HARDENED": true},
    "SCRIPT_ADDRESS": 5,
    "PUBLIC_KEY_ADDRESS": 38,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": null,
    "DEFAULT_PATH": "m/44'/101'/0'/0/0",
    "WIF_SECRET_KEY": 166
  },
  "GBX": {
    "SYMBOL": "GBX",
    "NAME": "Go Byte",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 176, "HARDENED": true},
    "SCRIPT_ADDRESS": 10,
    "PUBLIC_KEY_ADDRESS": 38,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018DarkCoin Signed Message:\n",
    "DEFAULT_PATH": "m/44'/176'/0'/0/0",
    "WIF_SECRET_KEY": 198
  },
  "GRC": {
    "SYMBOL": "GRC",
    "NAME": "Gridcoin",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 84, "HARDENED": true},
    "SCRIPT_ADDRESS": 85,
    "PUBLIC_KEY_ADDRESS": 62,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018Gridcoin Signed Message:\n",
    "DEFAULT_PATH": "m/44'/84'/0'/0/0",
    "WIF_SECRET_KEY": 190
  },
  "GRS": {
    "SYMBOL": "GRS",
    "NAME": "Groestl Coin",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 17, "HARDENED": true},
    "SCRIPT_ADDRESS": 5,
    "PUBLIC_KEY_ADDRESS": 36,
    "SEGWIT_ADDRESS": {"HRP": "grs", "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": 78791436,
      "P2WPKH_IN_P2SH": 77428856,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": 78792518,
      "P2WPKH_IN_P2SH": 77429938,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0019GroestlCoin Signed Message:\n",
    "DEFAULT_PATH": "m/44'/17'/0'/0/0",
    "WIF_SECRET_KEY": 128
  },
  "GRSTEST": {
    "SYMBOL": "GRSTEST",
    "NAME": "Groestl Coin",
    "NETWORK": "testnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 1, "HARDENED": true},
    "SCRIPT_ADDRESS": 196,
    "PUBLIC_KEY_ADDRESS": 111,
    "SEGWIT_ADDRESS": {"HRP": "tgrs", "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 70615956,
      "P2SH": 70615956,
      "P2WPKH": 73341116,
      "P2WPKH_IN_P2SH": 71978536,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 70617039,
      "P2SH": 70617039,
      "P2WPKH": 73342198,
      "P2WPKH_IN_P2SH": 71979618,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0019GroestlCoin Signed Message:\n",
    "DEFAULT_PATH": "m/44'/1'/0'/0/0",
    "WIF_SECRET_KEY": 239
  },
  "NLG": {
    "SYMBOL": "NLG",
    "NAME": "Gulden",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 87, "HARDENED": true},
    "SCRIPT_ADDRESS": 98,
    "PUBLIC_KEY_ADDRESS": 38,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018Guldencoin Signed Message:\n",
    "DEFAULT_PATH": "m/44'/87'/0'/0/0",
    "WIF_SECRET_KEY": 98
  },
  "HNC": {
    "SYMBOL": "HNC",
    "NAME": "Helleniccoin",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 168, "HARDENED": true},
    "SCRIPT_ADDRESS": 5,
    "PUBLIC_KEY_ADDRESS": 48,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018helleniccoin Signed Message:\n",
    "DEFAULT_PATH": "m/44'/168'/0'/0/0",
    "WIF_SECRET_KEY": 176
  },
  "THC": {
    "SYMBOL": "THC",
    "NAME": "Hempcoin",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 113, "HARDENED": true},
    "SCRIPT_ADDRESS": 8,
    "PUBLIC_KEY_ADDRESS": 40,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018Hempcoin Signed Message:\n",
    "DEFAULT_PATH": "m/44'/113'/0'/0/0",
    "WIF_SECRET_KEY": 168
  },
  "HUSH": {
    "SYMBOL": "HUSH",
    "NAME": "Hush",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 197, "HARDENED": true},
    "SCRIPT_ADDRESS": 7357,
    "PUBLIC_KEY_ADDRESS": 7352,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018Hush Signed Message:\n",
    "DEFAULT_PATH": "m/44'/197'/0'/0/0",
    "WIF_SECRET_KEY": 128
  },
  "IXC": {
    "SYMBOL": "IXC",
    "NAME": "IX Coin",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 86, "HARDENED": true},
    "SCRIPT_ADDRESS": 5,
    "PUBLIC_KEY_ADDRESS": 138,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018Ixcoin Signed Message:\n",
    "DEFAULT_PATH": "m/44'/86'/0'/0/0",
    "WIF_SECRET_KEY": 128
  },
  "INSN": {
    "SYMBOL": "INSN",
    "NAME": "Insane Coin",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 68, "HARDENED": true},
    "SCRIPT_ADDRESS": 57,
    "PUBLIC_KEY_ADDRESS": 102,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018INSaNe Signed Message:\n",
    "DEFAULT_PATH": "m/44'/68'/0'/0/0",
    "WIF_SECRET_KEY": 55
  },
  "IOP": {
    "SYMBOL": "IOP",
    "NAME": "Internet Of People",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 66, "HARDENED": true},
    "SCRIPT_ADDRESS": 174,
    "PUBLIC_KEY_ADDRESS": 117,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 2922649334,
      "P2SH": 2922649334,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 662737247,
      "P2SH": 662737247,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018IoP Signed Message:\n",
    "DEFAULT_PATH": "m/44'/66'/0'/0/0",
    "WIF_SECRET_KEY": 49
  },
  "JBS": {
    "SYMBOL": "JBS",
    "NAME": "Jumbucks",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 26, "HARDENED": true},
    "SCRIPT_ADDRESS": 5,
    "PUBLIC_KEY_ADDRESS": 43,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 58352736,
      "P2SH": 58352736,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 58353818,
      "P2SH": 58353818,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0019Jumbucks Signed Message:\n",
    "DEFAULT_PATH": "m/44'/26'/0'/0/0",
    "WIF_SECRET_KEY": 171
  },
  "KOBO": {
    "SYMBOL": "KOBO",
    "NAME": "Kobocoin",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 196, "HARDENED": true},
    "SCRIPT_ADDRESS": 28,
    "PUBLIC_KEY_ADDRESS": 35,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018Kobocoin Signed Message:\n",
    "DEFAULT_PATH": "m/44'/196'/0'/0/0",
    "WIF_SECRET_KEY": 163
  },
  "KMD": {
    "SYMBOL": "KMD",
    "NAME": "Komodo",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 141, "HARDENED": true},
    "SCRIPT_ADDRESS": 85,
    "PUBLIC_KEY_ADDRESS": 60,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018Komodo Signed Message:\n",
    "DEFAULT_PATH": "m/44'/141'/0'/0/0",
    "WIF_SECRET_KEY": 188
  },
  "LBC": {
    "SYMBOL": "LBC",
    "NAME": "LBRY Credits",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 140, "HARDENED": true},
    "SCRIPT_ADDRESS": 122,
    "PUBLIC_KEY_ADDRESS": 85,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018LBRYcrd Signed Message:\n",
    "DEFAULT_PATH": "m/44'/140'/0'/0/0",
    "WIF_SECRET_KEY": 28
  },
  "LINX": {
    "SYMBOL": "LINX",
    "NAME": "Linx",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 114, "HARDENED": true},
    "SCRIPT_ADDRESS": 5,
    "PUBLIC_KEY_ADDRESS": 75,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018LinX Signed Message:\n",
    "DEFAULT_PATH": "m/44'/114'/0'/0/0",
    "WIF_SECRET_KEY": 203
  },
  "LCC": {
    "SYMBOL": "LCC",
    "NAME": "Litecoin Cash",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 192, "HARDENED": true},
    "SCRIPT_ADDRESS": 5,
    "PUBLIC_KEY_ADDRESS": 28,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018Litecoin Signed Message:\n",
    "DEFAULT_PATH": "m/44'/192'/0'/0/0",
    "WIF_SECRET_KEY": 176
  },
  "LTC": {
    "SYMBOL": "LTC",
    "NAME": "Litecoin",
    "NETWORK": "mainnet",
    "SOURCE_CODE": "https://github.com/litecoin-project/litecoin",
    "COIN_TYPE": {"INDEX": 2, "HARDENED": true},
    "SCRIPT_ADDRESS": 50,
    "PUBLIC_KEY_ADDRESS": 48,
    "SEGWIT_ADDRESS": {"HRP": "ltc", "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0019Litecoin Signed Message:\n",
    "DEFAULT_PATH": "m/44'/2'/0'/0/0",
    "WIF_SECRET_KEY": 176
  },
  "LTCTEST": {
    "SYMBOL": "LTCTEST",
    "NAME": "Litecoin",
    "NETWORK": "testnet",
    "SOURCE_CODE": "https://github.com/litecoin-project/litecoin",
    "COIN_TYPE": {"INDEX": 1, "HARDENED": true},
    "SCRIPT_ADDRESS": 58,
    "PUBLIC_KEY_ADDRESS": 111,
    "SEGWIT_ADDRESS": {"HRP": "tltc", "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 70615956,
      "P2SH": 70615956,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 70617039,
      "P2SH": 70617039,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0019Litecoin Signed Message:\n",
    "DEFAULT_PATH": "m/44'/1'/0'/0/0",
    "WIF_SECRET_KEY": 239
  },
  "LTZ": {
    "SYMBOL": "LTZ",
    "NAME": "LitecoinZ",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 221, "HARDENED": true},
    "SCRIPT_ADDRESS": 2744,
    "PUBLIC_KEY_ADDRESS": 2739,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066275,
      "P2SH": 76066275,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018LitecoinZ Signed Message:\n",
    "DEFAULT_PATH": "m/44'/221'/0'/0/0",
    "WIF_SECRET_KEY": 128
  },
  "LKR": {
    "SYMBOL": "LKR",
    "NAME": "Lkrcoin",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 557, "HARDENED": true},
    "SCRIPT_ADDRESS": 85,
    "PUBLIC_KEY_ADDRESS": 48,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018LKRcoin Signed Message:\n",
    "DEFAULT_PATH": "m/44'/557'/0'/0/0",
    "WIF_SECRET_KEY": 176
  },
  "LYNX": {
    "SYMBOL": "LYNX",
    "NAME": "Lynx",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 191, "HARDENED": true},
    "SCRIPT_ADDRESS": 50,
    "PUBLIC_KEY_ADDRESS": 45,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018Lynx Signed Message:\n",
    "DEFAULT_PATH": "m/44'/191'/0'/0/0",
    "WIF_SECRET_KEY": 173
  },
  "MZC": {
    "SYMBOL": "MZC",
    "NAME": "Mazacoin",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 13, "HARDENED": true},
    "SCRIPT_ADDRESS": 9,
    "PUBLIC_KEY_ADDRESS": 50,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": null,
    "DEFAULT_PATH": "m/44'/13'/0'/0/0",
    "WIF_SECRET_KEY": 224
  },
  "MEC": {
    "SYMBOL": "MEC",
    "NAME": "Megacoin",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 217, "HARDENED": true},
    "SCRIPT_ADDRESS": 5,
    "PUBLIC_KEY_ADDRESS": 50,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018Megacoin Signed Message:\n",
    "DEFAULT_PATH": "m/44'/217'/0'/0/0",
    "WIF_SECRET_KEY": 178
  },
  "MNX": {
    "SYMBOL": "MNX",
    "NAME": "Minexcoin",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 182, "HARDENED": true},
    "SCRIPT_ADDRESS": 5,
    "PUBLIC_KEY_ADDRESS": 75,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018Bitcoin Signed Message:\n",
    "DEFAULT_PATH": "m/44'/182'/0'/0/0",
    "WIF_SECRET_KEY": 128
  },
  "MONA": {
    "SYMBOL": "MONA",
    "NAME": "Monacoin",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 22, "HARDENED": true},
    "SCRIPT_ADDRESS": 55,
    "PUBLIC_KEY_ADDRESS": 50,
    "SEGWIT_ADDRESS": {"HRP": "mona", "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": 76066276,
      "P2WPKH_IN_P2SH": 76066276,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": 76067358,
      "P2WPKH_IN_P2SH": 76067358,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018Monacoin Signed Message:\n",
    "DEFAULT_PATH": "m/44'/22'/0'/0/0",
    "WIF_SECRET_KEY": 176
  },
  "MONK": {
    "SYMBOL": "MONK",
    "NAME": "Monkey Project",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 214, "HARDENED": true},
    "SCRIPT_ADDRESS": 28,
    "PUBLIC_KEY_ADDRESS": 51,
    "SEGWIT_ADDRESS": {"HRP": "monkey", "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76078564,
      "P2SH": 76078564,
      "P2WPKH": 76078564,
      "P2WPKH_IN_P2SH": 76078564,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": 76067358,
      "P2WPKH_IN_P2SH": 76067358,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "Monkey Signed Message:\n",
    "DEFAULT_PATH": "m/44'/214'/0'/0/0",
    "WIF_SECRET_KEY": 55
  },
  "XMY": {
    "SYMBOL": "XMY",
    "NAME": "Myriadcoin",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 90, "HARDENED": true},
    "SCRIPT_ADDRESS": 9,
    "PUBLIC_KEY_ADDRESS": 50,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": null,
    "DEFAULT_PATH": "m/44'/90'/0'/0/0",
    "WIF_SECRET_KEY": 178
  },
  "NIX": {
    "SYMBOL": "NIX",
    "NAME": "NIX",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 400, "HARDENED": true},
    "SCRIPT_ADDRESS": 53,
    "PUBLIC_KEY_ADDRESS": 38,
    "SEGWIT_ADDRESS": {"HRP": "nix", "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": 76066276,
      "P2WPKH_IN_P2SH": 76066276,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": 76067358,
      "P2WPKH_IN_P2SH": 76067358,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018Nix Signed Message:\n",
    "DEFAULT_PATH": "m/44'/400'/0'/0/0",
    "WIF_SECRET_KEY": 128
  },
  "NMC": {
    "SYMBOL": "NMC",
    "NAME": "Namecoin",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 7, "HARDENED": true},
    "SCRIPT_ADDRESS": 13,
    "PUBLIC_KEY_ADDRESS": 52,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": null,
    "DEFAULT_PATH": "m/44'/7'/0'/0/0",
    "WIF_SECRET_KEY": 128
  },
  "NAV": {
    "SYMBOL": "NAV",
    "NAME": "Navcoin",
    "NETWORK": "mainnet",
    "SOURCE_CODE": "https://github.com/navcoin/navcoin-core",
    "COIN_TYPE": {"INDEX": 130, "HARDENED": true},
    "SCRIPT_ADDRESS": 85,
    "PUBLIC_KEY_ADDRESS": 53,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018Navcoin Signed Message:\n",
    "DEFAULT_PATH": "m/44'/130'/0'/0/0",
    "WIF_SECRET_KEY": 150
  },
  "NEBL": {
    "SYMBOL": "NEBL",
    "NAME": "Neblio",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 146, "HARDENED": true},
    "SCRIPT_ADDRESS": 112,
    "PUBLIC_KEY_ADDRESS": 53,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018Neblio Signed Message:\n",
    "DEFAULT_PATH": "m/44'/146'/0'/0/0",
    "WIF_SECRET_KEY": 181
  },
  "NEOS": {
    "SYMBOL": "NEOS",
    "NAME": "Neoscoin",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 25, "HARDENED": true},
    "SCRIPT_ADDRESS": 5,
    "PUBLIC_KEY_ADDRESS": 53,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018NeosCoin Signed Message:\n",
    "DEFAULT_PATH": "m/44'/25'/0'/0/0",
    "WIF_SECRET_KEY": 177
  },
  "NRO": {
    "SYMBOL": "NRO",
    "NAME": "Neurocoin",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 110, "HARDENED": true},
    "SCRIPT_ADDRESS": 117,
    "PUBLIC_KEY_ADDRESS": 53,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018PPCoin Signed Message:\n",
    "DEFAULT_PATH": "m/44'/110'/0'/0/0",
    "WIF_SECRET_KEY": 181
  },
  "NYC": {
    "SYMBOL": "NYC",
    "NAME": "New York Coin",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 179, "HARDENED": true},
    "SCRIPT_ADDRESS": 22,
    "PUBLIC_KEY_ADDRESS": 60,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018newyorkc Signed Message:\n",
    "DEFAULT_PATH": "m/44'/179'/0'/0/0",
    "WIF_SECRET_KEY": 188
  },
  "NVC": {
    "SYMBOL": "NVC",
    "NAME": "Novacoin",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 50, "HARDENED": true},
    "SCRIPT_ADDRESS": 20,
    "PUBLIC_KEY_ADDRESS": 8,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018NovaCoin Signed Message:\n",
    "DEFAULT_PATH": "m/44'/50'/0'/0/0",
    "WIF_SECRET_KEY": 136
  },
  "NBT": {
    "SYMBOL": "NBT",
    "NAME": "NuBits",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 12, "HARDENED": true},
    "SCRIPT_ADDRESS": 26,
    "PUBLIC_KEY_ADDRESS": 25,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018Nu Signed Message:\n",
    "DEFAULT_PATH": "m/44'/12'/0'/0/0",
    "WIF_SECRET_KEY": 150
  },
  "NSR": {
    "SYMBOL": "NSR",
    "NAME": "NuShares",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 11, "HARDENED": true},
    "SCRIPT_ADDRESS": 64,
    "PUBLIC_KEY_ADDRESS": 63,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018Nu Signed Message:\n",
    "DEFAULT_PATH": "m/44'/11'/0'/0/0",
    "WIF_SECRET_KEY": 149
  },
  "OK": {
    "SYMBOL": "OK",
    "NAME": "OK Cash",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 69, "HARDENED": true},
    "SCRIPT_ADDRESS": 28,
    "PUBLIC_KEY_ADDRESS": 55,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 63708275,
      "P2SH": 63708275,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 63710167,
      "P2SH": 63710167,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018OKCash Signed Message:\n",
    "DEFAULT_PATH": "m/44'/69'/0'/0/0",
    "WIF_SECRET_KEY": 3
  },
  "OMNI": {
    "SYMBOL": "OMNI",
    "NAME": "Omni",
    "NETWORK": "mainnet",
    "SOURCE_CODE": "https://github.com/omnilayer/omnicore",
    "COIN_TYPE": {"INDEX": 200, "HARDENED": true},
    "SCRIPT_ADDRESS": 5,
    "PUBLIC_KEY_ADDRESS": 0,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018Bitcoin Signed Message:\n",
    "DEFAULT_PATH": "m/44'/200'/0'/0/0",
    "WIF_SECRET_KEY": 128
  },
  "OMNITEST": {
    "SYMBOL": "OMNITEST",
    "NAME": "Omni",
    "NETWORK": "testnet",
    "SOURCE_CODE": "https://github.com/omnilayer/omnicore",
    "COIN_TYPE": {"INDEX": 1, "HARDENED": true},
    "SCRIPT_ADDRESS": 196,
    "PUBLIC_KEY_ADDRESS": 111,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 70615956,
      "P2SH": 70615956,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 70617039,
      "P2SH": 70617039,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018Bitcoin Signed Message:\n",
    "DEFAULT_PATH": "m/44'/1'/0'/0/0",
    "WIF_SECRET_KEY": 239
  },
  "ONX": {
    "SYMBOL": "ONX",
    "NAME": "Onix Coin",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 174, "HARDENED": true},
    "SCRIPT_ADDRESS": 5,
    "PUBLIC_KEY_ADDRESS": 75,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "ONIX Signed Message:\n",
    "DEFAULT_PATH": "m/44'/174'/0'/0/0",
    "WIF_SECRET_KEY": 203
  },
  "PPC": {
    "SYMBOL": "PPC",
    "NAME": "Peercoin",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 6, "HARDENED": true},
    "SCRIPT_ADDRESS": 117,
    "PUBLIC_KEY_ADDRESS": 55,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": null,
    "DEFAULT_PATH": "m/44'/6'/0'/0/0",
    "WIF_SECRET_KEY": 183
  },
  "PSB": {
    "SYMBOL": "PSB",
    "NAME": "Pesobit",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 62, "HARDENED": true},
    "SCRIPT_ADDRESS": 85,
    "PUBLIC_KEY_ADDRESS": 55,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018Pesobit Signed Message:\n",
    "DEFAULT_PATH": "m/44'/62'/0'/0/0",
    "WIF_SECRET_KEY": 183
  },
  "PHR": {
    "SYMBOL": "PHR",
    "NAME": "Phore",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 444, "HARDENED": true},
    "SCRIPT_ADDRESS": 13,
    "PUBLIC_KEY_ADDRESS": 55,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 35729707,
      "P2SH": 35729707,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 36513075,
      "P2SH": 36513075,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018Phore Signed Message:\n",
    "DEFAULT_PATH": "m/44'/444'/0'/0/0",
    "WIF_SECRET_KEY": 212
  },
  "PINK": {
    "SYMBOL": "PINK",
    "NAME": "Pinkcoin",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 117, "HARDENED": true},
    "SCRIPT_ADDRESS": 28,
    "PUBLIC_KEY_ADDRESS": 3,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018Pinkcoin Signed Message:\n",
    "DEFAULT_PATH": "m/44'/117'/0'/0/0",
    "WIF_SECRET_KEY": 131
  },
  "PIVX": {
    "SYMBOL": "PIVX",
    "NAME": "Pivx",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 119, "HARDENED": true},
    "SCRIPT_ADDRESS": 13,
    "PUBLIC_KEY_ADDRESS": 30,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 35729707,
      "P2SH": 35729707,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 36513075,
      "P2SH": 36513075,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": null,
    "DEFAULT_PATH": "m/44'/119'/0'/0/0",
    "WIF_SECRET_KEY": 212
  },
  "PIVXTEST": {
    "SYMBOL": "PIVXTEST",
    "NAME": "Pivx",
    "NETWORK": "testnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 1, "HARDENED": true},
    "SCRIPT_ADDRESS": 19,
    "PUBLIC_KEY_ADDRESS": 139,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 981489719,
      "P2SH": 981489719,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 981492128,
      "P2SH": 981492128,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": null,
    "DEFAULT_PATH": "m/44'/1'/0'/0/0",
    "WIF_SECRET_KEY": 239
  },
  "POSW": {
    "SYMBOL": "POSW",
    "NAME": "Posw Coin",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 47, "HARDENED": true},
    "SCRIPT_ADDRESS": 85,
    "PUBLIC_KEY_ADDRESS": 55,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018Poswcoin Signed Message:\n",
    "DEFAULT_PATH": "m/44'/47'/0'/0/0",
    "WIF_SECRET_KEY": 183
  },
  "POT": {
    "SYMBOL": "POT",
    "NAME": "Potcoin",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 81, "HARDENED": true},
    "SCRIPT_ADDRESS": 5,
    "PUBLIC_KEY_ADDRESS": 55,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018Potcoin Signed Message:\n",
    "DEFAULT_PATH": "m/44'/81'/0'/0/0",
    "WIF_SECRET_KEY": 183
  },
  "PRJ": {
    "SYMBOL": "PRJ",
    "NAME": "Project Coin",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 533, "HARDENED": true},
    "SCRIPT_ADDRESS": 8,
    "PUBLIC_KEY_ADDRESS": 55,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 35729707,
      "P2SH": 35729707,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 36513075,
      "P2SH": 36513075,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018ProjectCoin Signed Message:\n",
    "DEFAULT_PATH": "m/44'/533'/0'/0/0",
    "WIF_SECRET_KEY": 117
  },
  "PUT": {
    "SYMBOL": "PUT",
    "NAME": "Putincoin",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 122, "HARDENED": true},
    "SCRIPT_ADDRESS": 20,
    "PUBLIC_KEY_ADDRESS": 55,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018PutinCoin Signed Message:\n",
    "DEFAULT_PATH": "m/44'/122'/0'/0/0",
    "WIF_SECRET_KEY": 183
  },
  "QTUM": {
    "SYMBOL": "QTUM",
    "NAME": "Qtum",
    "NETWORK": "mainnet",
    "SOURCE_CODE": "https://github.com/qtumproject/qtum",
    "COIN_TYPE": {"INDEX": 2301, "HARDENED": true},
    "SCRIPT_ADDRESS": 50,
    "PUBLIC_KEY_ADDRESS": 58,
    "SEGWIT_ADDRESS": {"HRP": "qc1", "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": 73341116,
      "P2WPKH_IN_P2SH": 77428856,
      "P2WSH": 44726937,
      "P2WSH_IN_P2SH": 43364357
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": 73342198,
      "P2WPKH_IN_P2SH": 77429938,
      "P2WSH": 44728019,
      "P2WSH_IN_P2SH": 43365439
    },
    "MESSAGE_PREFIX": null,
    "DEFAULT_PATH": "m/44'/2301'/0'/0/0",
    "WIF_SECRET_KEY": 128
  },
  "QTUMTEST": {
    "SYMBOL": "QTUMTEST",
    "NAME": "Qtum",
    "NETWORK": "testnet",
    "SOURCE_CODE": "https://github.com/qtumproject/qtum",
    "COIN_TYPE": {"INDEX": 1, "HARDENED": true},
    "SCRIPT_ADDRESS": 110,
    "PUBLIC_KEY_ADDRESS": 120,
    "SEGWIT_ADDRESS": {"HRP": "tq1", "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 70615956,
      "P2SH": 70615956,
      "P2WPKH": 73341116,
      "P2WPKH_IN_P2SH": 71978536,
      "P2WSH": 39276616,
      "P2WSH_IN_P2SH": 37914037
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 70617039,
      "P2SH": 70617039,
      "P2WPKH": 73342198,
      "P2WPKH_IN_P2SH": 71979618,
      "P2WSH": 39277699,
      "P2WSH_IN_P2SH": 37915119
    },
    "MESSAGE_PREFIX": null,
    "DEFAULT_PATH": "m/44'/1'/0'/0/0",
    "WIF_SECRET_KEY": 239
  },
  "RBTC": {
    "SYMBOL": "RBTC",
    "NAME": "RSK",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 137, "HARDENED": true},
    "SCRIPT_ADDRESS": 5,
    "PUBLIC_KEY_ADDRESS": 0,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018RSK Signed Message:\n",
    "DEFAULT_PATH": "m/44'/137'/0'/0/0",
    "WIF_SECRET_KEY": 128
  },
  "RBTCTEST": {
    "SYMBOL": "RBTCTEST",
    "NAME": "RSK",
    "NETWORK": "testnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 1, "HARDENED": true},
    "SCRIPT_ADDRESS": 196,
    "PUBLIC_KEY_ADDRESS": 111,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 70615956,
      "P2SH": 70615956,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 70617039,
      "P2SH": 70617039,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018RSK Testnet Signed Message:\n",
    "DEFAULT_PATH": "m/44'/1'/0'/0/0",
    "WIF_SECRET_KEY": 239
  },
  "RPD": {
    "SYMBOL": "RPD",
    "NAME": "Rapids",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 320, "HARDENED": true},
    "SCRIPT_ADDRESS": 6,
    "PUBLIC_KEY_ADDRESS": 61,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "DarkNet Signed Message:\n",
    "DEFAULT_PATH": "m/44'/320'/0'/0/0",
    "WIF_SECRET_KEY": 46
  },
  "RVN": {
    "SYMBOL": "RVN",
    "NAME": "Ravencoin",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 175, "HARDENED": true},
    "SCRIPT_ADDRESS": 122,
    "PUBLIC_KEY_ADDRESS": 60,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0016Raven Signed Message:\n",
    "DEFAULT_PATH": "m/44'/175'/0'/0/0",
    "WIF_SECRET_KEY": 128
  },
  "RDD": {
    "SYMBOL": "RDD",
    "NAME": "Reddcoin",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 4, "HARDENED": true},
    "SCRIPT_ADDRESS": 5,
    "PUBLIC_KEY_ADDRESS": 61,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018Reddcoin Signed Message:\n",
    "DEFAULT_PATH": "m/44'/4'/0'/0/0",
    "WIF_SECRET_KEY": 189
  },
  "RBY": {
    "SYMBOL": "RBY",
    "NAME": "Rubycoin",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 16, "HARDENED": true},
    "SCRIPT_ADDRESS": 85,
    "PUBLIC_KEY_ADDRESS": 60,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018Rubycoin Signed Message:\n",
    "DEFAULT_PATH": "m/44'/16'/0'/0/0",
    "WIF_SECRET_KEY": 188
  },
  "SAFE": {
    "SYMBOL": "SAFE",
    "NAME": "Safecoin",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 19165, "HARDENED": true},
    "SCRIPT_ADDRESS": 86,
    "PUBLIC_KEY_ADDRESS": 61,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018Safecoin Signed Message:\n",
    "DEFAULT_PATH": "m/44'/19165'/0'/0/0",
    "WIF_SECRET_KEY": 189
  },
  "SLS": {
    "SYMBOL": "SLS",
    "NAME": "Saluscoin",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 572, "HARDENED": true},
    "SCRIPT_ADDRESS": 196,
    "PUBLIC_KEY_ADDRESS": 63,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018Salus Signed Message:\n",
    "DEFAULT_PATH": "m/44'/572'/0'/0/0",
    "WIF_SECRET_KEY": 191
  },
  "SCRIBE": {
    "SYMBOL": "SCRIBE",
    "NAME": "Scribe",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 545, "HARDENED": true},
    "SCRIPT_ADDRESS": 125,
    "PUBLIC_KEY_ADDRESS": 60,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": null,
    "DEFAULT_PATH": "m/44'/545'/0'/0/0",
    "WIF_SECRET_KEY": 110
  },
  "SDC": {
    "SYMBOL": "SDC",
    "NAME": "Shadow Cash",
    "NETWORK": "mainnet",
    "SOURCE_CODE": "https://github.com/shadowproject/shadow",
    "COIN_TYPE": {"INDEX": 35, "HARDENED": true},
    "SCRIPT_ADDRESS": 125,
    "PUBLIC_KEY_ADDRESS": 63,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 4001378792,
      "P2SH": 4001378792,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 4001376362,
      "P2SH": 4001376362,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": null,
    "DEFAULT_PATH": "m/44'/35'/0'/0/0",
    "WIF_SECRET_KEY": 191
  },
  "SDCTEST": {
    "SYMBOL": "SDCTEST",
    "NAME": "Shadow Cash",
    "NETWORK": "testnet",
    "SOURCE_CODE": "https://github.com/shadowproject/shadow",
    "COIN_TYPE": {"INDEX": 1, "HARDENED": true},
    "SCRIPT_ADDRESS": 196,
    "PUBLIC_KEY_ADDRESS": 127,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 1992361850,
      "P2SH": 1992361850,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 1992359419,
      "P2SH": 1992359419,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": null,
    "DEFAULT_PATH": "m/44'/1'/0'/0/0",
    "WIF_SECRET_KEY": 255
  },
  "SLM": {
    "SYMBOL": "SLM",
    "NAME": "Slimcoin",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 63, "HARDENED": true},
    "SCRIPT_ADDRESS": 125,
    "PUBLIC_KEY_ADDRESS": 63,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 4016695936,
      "P2SH": 4016695936,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 4016758544,
      "P2SH": 4016758544,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": null,
    "DEFAULT_PATH": "m/44'/63'/0'/0/0",
    "WIF_SECRET_KEY": 70
  },
  "SLMTEST": {
    "SYMBOL": "SLMTEST",
    "NAME": "Slimcoin",
    "NETWORK": "testnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 1, "HARDENED": true},
    "SCRIPT_ADDRESS": 196,
    "PUBLIC_KEY_ADDRESS": 111,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 70615956,
      "P2SH": 70615956,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 70617039,
      "P2SH": 70617039,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": null,
    "DEFAULT_PATH": "m/44'/1'/0'/0/0",
    "WIF_SECRET_KEY": 87
  },
  "SMLY": {
    "SYMBOL": "SMLY",
    "NAME": "Smileycoin",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 59, "HARDENED": true},
    "SCRIPT_ADDRESS": 5,
    "PUBLIC_KEY_ADDRESS": 25,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 508965308,
      "P2SH": 508965308,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 508964250,
      "P2SH": 508964250,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018Smileycoin Signed Message:\n",
    "DEFAULT_PATH": "m/44'/59'/0'/0/0",
    "WIF_SECRET_KEY": 5
  },
  "SLR": {
    "SYMBOL": "SLR",
    "NAME": "Solarcoin",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 58, "HARDENED": true},
    "SCRIPT_ADDRESS": 5,
    "PUBLIC_KEY_ADDRESS": 18,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018SolarCoin Signed Message:\n",
    "DEFAULT_PATH": "m/44'/58'/0'/0/0",
    "WIF_SECRET_KEY": 146
  },
  "STASH": {
    "SYMBOL": "STASH",
    "NAME": "Stash",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 49344, "HARDENED": true},
    "SCRIPT_ADDRESS": 16,
    "PUBLIC_KEY_ADDRESS": 76,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018Stash Signed Message:\n",
    "DEFAULT_PATH": "m/44'/49344'/0'/0/0",
    "WIF_SECRET_KEY": 204
  },
  "STRAT": {
    "SYMBOL": "STRAT",
    "NAME": "Stratis",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 105, "HARDENED": true},
    "SCRIPT_ADDRESS": 125,
    "PUBLIC_KEY_ADDRESS": 63,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018Stratis Signed Message:\n",
    "DEFAULT_PATH": "m/44'/105'/0'/0/0",
    "WIF_SECRET_KEY": 191
  },
  "STRATTEST": {
    "SYMBOL": "STRATTEST",
    "NAME": "Stratis",
    "NETWORK": "testnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 1, "HARDENED": true},
    "SCRIPT_ADDRESS": 125,
    "PUBLIC_KEY_ADDRESS": 65,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018Stratis Test Signed Message:\n",
    "DEFAULT_PATH": "m/44'/1'/0'/0/0",
    "WIF_SECRET_KEY": 191
  },
  "SUGAR": {
    "SYMBOL": "SUGAR",
    "NAME": "Sugarchain",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 408, "HARDENED": true},
    "SCRIPT_ADDRESS": 125,
    "PUBLIC_KEY_ADDRESS": 63,
    "SEGWIT_ADDRESS": {"HRP": "sugar", "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": 78791436,
      "P2WPKH_IN_P2SH": 77428856,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": 78792518,
      "P2WPKH_IN_P2SH": 77429938,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018Sugarchain Signed Message:\n",
    "DEFAULT_PATH": "m/44'/408'/0'/0/0",
    "WIF_SECRET_KEY": 128
  },
  "SUGARTEST": {
    "SYMBOL": "SUGARTEST",
    "NAME": "Sugarchain",
    "NETWORK": "testnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 1, "HARDENED": true},
    "SCRIPT_ADDRESS": 128,
    "PUBLIC_KEY_ADDRESS": 66,
    "SEGWIT_ADDRESS": {"HRP": "tugar", "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 73341116,
      "P2SH": 73341116,
      "P2WPKH": 73341116,
      "P2WPKH_IN_P2SH": 71978536,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 73342198,
      "P2SH": 73342198,
      "P2WPKH": 73342198,
      "P2WPKH_IN_P2SH": 71979618,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018Sugarchain Signed Message:\n",
    "DEFAULT_PATH": "m/44'/1'/0'/0/0",
    "WIF_SECRET_KEY": 239
  },
  "SYS": {
    "SYMBOL": "SYS",
    "NAME": "Syscoin",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 57, "HARDENED": true},
    "SCRIPT_ADDRESS": 5,
    "PUBLIC_KEY_ADDRESS": 63,
    "SEGWIT_ADDRESS": {"HRP": "sys", "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": 78791436,
      "P2WPKH_IN_P2SH": 77428856,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": 78792518,
      "P2WPKH_IN_P2SH": 77429938,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018Syscoin Signed Message:\n",
    "DEFAULT_PATH": "m/44'/57'/0'/0/0",
    "WIF_SECRET_KEY": 128
  },
  "TOA": {
    "SYMBOL": "TOA",
    "NAME": "TOA Coin",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 159, "HARDENED": true},
    "SCRIPT_ADDRESS": 23,
    "PUBLIC_KEY_ADDRESS": 65,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018TOA Signed Message:\n",
    "DEFAULT_PATH": "m/44'/159'/0'/0/0",
    "WIF_SECRET_KEY": 193
  },
  "THT": {
    "SYMBOL": "THT",
    "NAME": "Thought AI",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 502, "HARDENED": true},
    "SCRIPT_ADDRESS": 9,
    "PUBLIC_KEY_ADDRESS": 7,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 1525405894,
      "P2SH": 1525405894,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 4224098317,
      "P2SH": 4224098317,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": null,
    "DEFAULT_PATH": "m/44'/502'/0'/0/0",
    "WIF_SECRET_KEY": 123
  },
  "TRX": {
    "SYMBOL": "TRX",
    "NAME": "Tron",
    "NETWORK": "mainnet",
    "SOURCE_CODE": "https://github.com/tronprotocol/java-tron",
    "COIN_TYPE": {"INDEX": 195, "HARDENED": true},
    "SCRIPT_ADDRESS": 5,
    "PUBLIC_KEY_ADDRESS": 65,
    "SEGWIT_ADDRESS": {"HRP": "bc", "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": 78791436,
      "P2WPKH_IN_P2SH": 77428856,
      "P2WSH": 44726937,
      "P2WSH_IN_P2SH": 43364357
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": 78792518,
      "P2WPKH_IN_P2SH": 77429938,
      "P2WSH": 44728019,
      "P2WSH_IN_P2SH": 43365439
    },
    "MESSAGE_PREFIX": null,
    "DEFAULT_PATH": "m/44'/195'/0'/0/0",
    "WIF_SECRET_KEY": 128
  },
  "TWINS": {
    "SYMBOL": "TWINS",
    "NAME": "Twins",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 970, "HARDENED": true},
    "SCRIPT_ADDRESS": 83,
    "PUBLIC_KEY_ADDRESS": 73,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 35729707,
      "P2SH": 35729707,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 36513075,
      "P2SH": 36513075,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": null,
    "DEFAULT_PATH": "m/44'/970'/0'/0/0",
    "WIF_SECRET_KEY": 66
  },
  "TWINSTEST": {
    "SYMBOL": "TWINSTEST",
    "NAME": "Twins",
    "NETWORK": "testnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 1, "HARDENED": true},
    "SCRIPT_ADDRESS": 137,
    "PUBLIC_KEY_ADDRESS": 76,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 981489719,
      "P2SH": 981489719,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 981492128,
      "P2SH": 981492128,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": null,
    "DEFAULT_PATH": "m/44'/1'/0'/0/0",
    "WIF_SECRET_KEY": 237
  },
  "USC": {
    "SYMBOL": "USC",
    "NAME": "Ultimate Secure Cash",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 112, "HARDENED": true},
    "SCRIPT_ADDRESS": 125,
    "PUBLIC_KEY_ADDRESS": 68,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 4001378792,
      "P2SH": 4001378792,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 4001376362,
      "P2SH": 4001376362,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018UltimateSecureCash Signed Message:\n",
    "DEFAULT_PATH": "m/44'/112'/0'/0/0",
    "WIF_SECRET_KEY": 191
  },
  "UNO": {
    "SYMBOL": "UNO",
    "NAME": "Unobtanium",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 92, "HARDENED": true},
    "SCRIPT_ADDRESS": 30,
    "PUBLIC_KEY_ADDRESS": 130,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018Unobtanium Signed Message:\n",
    "DEFAULT_PATH": "m/44'/92'/0'/0/0",
    "WIF_SECRET_KEY": 224
  },
  "VASH": {
    "SYMBOL": "VASH",
    "NAME": "Virtual Cash",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 33, "HARDENED": true},
    "SCRIPT_ADDRESS": 5,
    "PUBLIC_KEY_ADDRESS": 71,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018VpnCoin Signed Message:\n",
    "DEFAULT_PATH": "m/44'/33'/0'/0/0",
    "WIF_SECRET_KEY": 199
  },
  "VC": {
    "SYMBOL": "VC",
    "NAME": "Vcash",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 127, "HARDENED": true},
    "SCRIPT_ADDRESS": 8,
    "PUBLIC_KEY_ADDRESS": 71,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018Vcash Signed Message:\n",
    "DEFAULT_PATH": "m/44'/127'/0'/0/0",
    "WIF_SECRET_KEY": 199
  },
  "XVG": {
    "SYMBOL": "XVG",
    "NAME": "Verge Currency",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 77, "HARDENED": true},
    "SCRIPT_ADDRESS": 33,
    "PUBLIC_KEY_ADDRESS": 30,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018VERGE Signed Message:\n",
    "DEFAULT_PATH": "m/44'/77'/0'/0/0",
    "WIF_SECRET_KEY": 158
  },
  "VTC": {
    "SYMBOL": "VTC",
    "NAME": "Vertcoin",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 28, "HARDENED": true},
    "SCRIPT_ADDRESS": 5,
    "PUBLIC_KEY_ADDRESS": 71,
    "SEGWIT_ADDRESS": {"HRP": "vtc", "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": 76066276,
      "P2WPKH_IN_P2SH": 76066276,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": 76067358,
      "P2WPKH_IN_P2SH": 76067358,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018Vertcoin Signed Message:\n",
    "DEFAULT_PATH": "m/44'/28'/0'/0/0",
    "WIF_SECRET_KEY": 128
  },
  "VIA": {
    "SYMBOL": "VIA",
    "NAME": "Viacoin",
    "NETWORK": "mainnet",
    "SOURCE_CODE": "https://github.com/viacoin/viacore-viacoin",
    "COIN_TYPE": {"INDEX": 14, "HARDENED": true},
    "SCRIPT_ADDRESS": 33,
    "PUBLIC_KEY_ADDRESS": 71,
    "SEGWIT_ADDRESS": {"HRP": "viacoin", "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": 76066276,
      "P2WPKH_IN_P2SH": 76066276,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": 76067358,
      "P2WPKH_IN_P2SH": 76067358,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018Viacoin Signed Message:\n",
    "DEFAULT_PATH": "m/44'/14'/0'/0/0",
    "WIF_SECRET_KEY": 199
  },
  "VIATEST": {
    "SYMBOL": "VIATEST",
    "NAME": "Viacoin",
    "NETWORK": "testnet",
    "SOURCE_CODE": "https://github.com/viacoin/viacore-viacoin",
    "COIN_TYPE": {"INDEX": 14, "HARDENED": true},
    "SCRIPT_ADDRESS": 196,
    "PUBLIC_KEY_ADDRESS": 127,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 70615956,
      "P2SH": 70615956,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 70617039,
      "P2SH": 70617039,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018Viacoin Signed Message:\n",
    "DEFAULT_PATH": "m/44'/14'/0'/0/0",
    "WIF_SECRET_KEY": 255
  },
  "VIVO": {
    "SYMBOL": "VIVO",
    "NAME": "Vivo",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 166, "HARDENED": true},
    "SCRIPT_ADDRESS": 10,
    "PUBLIC_KEY_ADDRESS": 70,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018DarkCoin Signed Message:\n",
    "DEFAULT_PATH": "m/44'/166'/0'/0/0",
    "WIF_SECRET_KEY": 198
  },
  "XWC": {
    "SYMBOL": "XWC",
    "NAME": "Whitecoin",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 559, "HARDENED": true},
    "SCRIPT_ADDRESS": 87,
    "PUBLIC_KEY_ADDRESS": 73,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76059885,
      "P2SH": 76059885,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76054302,
      "P2SH": 76054302,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018Whitecoin Signed Message:\n",
    "DEFAULT_PATH": "m/44'/559'/0'/0/0",
    "WIF_SECRET_KEY": 201
  },
  "WC": {
    "SYMBOL": "WC",
    "NAME": "Wincoin",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 181, "HARDENED": true},
    "SCRIPT_ADDRESS": 28,
    "PUBLIC_KEY_ADDRESS": 73,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018WinCoin Signed Message:\n",
    "DEFAULT_PATH": "m/44'/181'/0'/0/0",
    "WIF_SECRET_KEY": 201
  },
  "XUEZ": {
    "SYMBOL": "XUEZ",
    "NAME": "XUEZ",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 225, "HARDENED": true},
    "SCRIPT_ADDRESS": 18,
    "PUBLIC_KEY_ADDRESS": 75,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 35729707,
      "P2SH": 35729707,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 36513075,
      "P2SH": 36513075,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": null,
    "DEFAULT_PATH": "m/44'/225'/0'/0/0",
    "WIF_SECRET_KEY": 212
  },
  "XDC": {
    "SYMBOL": "XDC",
    "NAME": "XinFin",
    "NETWORK": "mainnet",
    "SOURCE_CODE": "https://github.com/XinFinOrg/XDPoSChain",
    "COIN_TYPE": {"INDEX": 550, "HARDENED": true},
    "SCRIPT_ADDRESS": 5,
    "PUBLIC_KEY_ADDRESS": 0,
    "SEGWIT_ADDRESS": {"HRP": "bc", "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": 78791436,
      "P2WPKH_IN_P2SH": 77428856,
      "P2WSH": 44726937,
      "P2WSH_IN_P2SH": 43364357
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": 78792518,
      "P2WPKH_IN_P2SH": 77429938,
      "P2WSH": 44728019,
      "P2WSH_IN_P2SH": 43365439
    },
    "MESSAGE_PREFIX": null,
    "DEFAULT_PATH": "m/44'/550'/0'/0/0",
    "WIF_SECRET_KEY": 128
  },
  "YEC": {
    "SYMBOL": "YEC",
    "NAME": "Ycash",
    "NETWORK": "mainnet",
    "SOURCE_CODE": "https://github.com/ycashfoundation/ycash",
    "COIN_TYPE": {"INDEX": 347, "HARDENED": true},
    "SCRIPT_ADDRESS": 7212,
    "PUBLIC_KEY_ADDRESS": 7208,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018Ycash Signed Message:\n",
    "DEFAULT_PATH": "m/44'/347'/0'/0/0",
    "WIF_SECRET_KEY": 128
  },
  "ZCL": {
    "SYMBOL": "ZCL",
    "NAME": "ZClassic",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 147, "HARDENED": true},
    "SCRIPT_ADDRESS": 7357,
    "PUBLIC_KEY_ADDRESS": 7352,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018Zcash Signed Message:\n",
    "DEFAULT_PATH": "m/44'/147'/0'/0/0",
    "WIF_SECRET_KEY": 128
  },
  "ZEC": {
    "SYMBOL": "ZEC",
    "NAME": "Zcash",
    "NETWORK": "mainnet",
    "SOURCE_CODE": "https://github.com/zcash/zcash",
    "COIN_TYPE": {"INDEX": 133, "HARDENED": true},
    "SCRIPT_ADDRESS": 7357,
    "PUBLIC_KEY_ADDRESS": 7352,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018Zcash Signed Message:\n",
    "DEFAULT_PATH": "m/44'/133'/0'/0/0",
    "WIF_SECRET_KEY": 128
  },
  "ZECTEST": {
    "SYMBOL": "ZECTEST",
    "NAME": "Zcash",
    "NETWORK": "testnet",
    "SOURCE_CODE": "https://github.com/zcash/zcash",
    "COIN_TYPE": {"INDEX": 1, "HARDENED": true},
    "SCRIPT_ADDRESS": 7354,
    "PUBLIC_KEY_ADDRESS": 7461,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 70615956,
      "P2SH": 70615956,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 70617039,
      "P2SH": 70617039,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018Zcash Signed Message:\n",
    "DEFAULT_PATH": "m/44'/1'/0'/0/0",
    "WIF_SECRET_KEY": 239
  },
  "ZEN": {
    "SYMBOL": "ZEN",
    "NAME": "Zencash",
    "NETWORK": "mainnet",
    "SOURCE_CODE": null,
    "COIN_TYPE": {"INDEX": 121, "HARDENED": true},
    "SCRIPT_ADDRESS": 8342,
    "PUBLIC_KEY_ADDRESS": 8329,
    "SEGWIT_ADDRESS": {"HRP": null, "VERSION": 0},
    "EXTENDED_PRIVATE_KEY": {
      "P2PKH": 76066276,
      "P2SH": 76066276,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "EXTENDED_PUBLIC_KEY": {
      "P2PKH": 76067358,
      "P2SH": 76067358,
      "P2WPKH": null,
      "P2WPKH_IN_P2SH": null,
      "P2WSH": null,
      "P2WSH_IN_P2SH": null
    },
    "MESSAGE_PREFIX": "\u0018Zcash Signed Message:\n",
    "DEFAULT_PATH": "m/44'/121'/0'/0/0",
    "WIF_SECRET_KEY": 128
  }
};
