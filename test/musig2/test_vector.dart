const keyAggTestVector = {
  "pubkeys": [
    "02F9308A019258C31049344F85F89D5229B531C845836F99B08601F113BCE036F9",
    "03DFF1D77F2A671C5F36183726DB2341BE58FEAE1DA2DECED843240F7B502BA659",
    "023590A94E768F8E1815C2F24B4D80A8E3149316C3518CE7B7AD338368D038CA66",
    "020000000000000000000000000000000000000000000000000000000000000005",
    "02FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC30",
    "04F9308A019258C31049344F85F89D5229B531C845836F99B08601F113BCE036F9",
    "03935F972DA013F80AE011890FA89B67A27B7BE6CCB24D3274D18B2D4067F261A9"
  ],
  "tweaks": [
    "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141",
    "252E4BD67410A76CDF933D30EAA1608214037F1B105A013ECCD3C5C184A6110B"
  ],
  "valid_test_cases": [
    {
      "key_indices": [0, 1, 2],
      "expected":
          "90539EEDE565F5D054F32CC0C220126889ED1E5D193BAF15AEF344FE59D4610C"
    },
    {
      "key_indices": [2, 1, 0],
      "expected":
          "6204DE8B083426DC6EAF9502D27024D53FC826BF7D2012148A0575435DF54B2B"
    },
    {
      "key_indices": [0, 0, 0],
      "expected":
          "B436E3BAD62B8CD409969A224731C193D051162D8C5AE8B109306127DA3AA935"
    },
    {
      "key_indices": [0, 0, 1, 1],
      "expected":
          "69BC22BFA5D106306E48A20679DE1D7389386124D07571D0D872686028C26A3E"
    }
  ],
  "error_test_cases": [
    {
      "key_indices": [0, 3],
      "tweak_indices": [],
      "is_xonly": [],
      "error": {
        "type": "invalid_contribution",
        "signer": 1,
        "contrib": "pubkey"
      },
      "comment": "Invalid public key"
    },
    {
      "key_indices": [0, 4],
      "tweak_indices": [],
      "is_xonly": [],
      "error": {
        "type": "invalid_contribution",
        "signer": 1,
        "contrib": "pubkey"
      },
      "comment": "Public key exceeds field size"
    },
    {
      "key_indices": [5, 0],
      "tweak_indices": [],
      "is_xonly": [],
      "error": {
        "type": "invalid_contribution",
        "signer": 0,
        "contrib": "pubkey"
      },
      "comment": "First byte of public key is not 2 or 3"
    },
    {
      "key_indices": [0, 1],
      "tweak_indices": [0],
      "is_xonly": [true],
      "error": {"type": "value", "message": "The tweak must be less than n."},
      "comment": "Tweak is out of range"
    },
    {
      "key_indices": [6],
      "tweak_indices": [1],
      "is_xonly": [false],
      "error": {
        "type": "value",
        "message": "The result of tweaking cannot be infinity."
      },
      "comment": "Intermediate tweaking result is point at infinity"
    }
  ]
};
