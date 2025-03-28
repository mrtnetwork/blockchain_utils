const Map<String, dynamic> detSignVector = {
  "sk": "7FB9E0E687ADA1EEBF7ECFE2F21E73EBDB51A7D450948DFE8D76D7F2D1007671",
  "pubkeys": [
    "03935F972DA013F80AE011890FA89B67A27B7BE6CCB24D3274D18B2D4067F261A9",
    "02F9308A019258C31049344F85F89D5229B531C845836F99B08601F113BCE036F9",
    "02DFF1D77F2A671C5F36183726DB2341BE58FEAE1DA2DECED843240F7B502BA659",
    "020000000000000000000000000000000000000000000000000000000000000007"
  ],
  "msgs": [
    "F95466D086770E689964664219266FE5ED215C92AE20BAB5C9D79ADDDDF3C0CF",
    "2626262626262626262626262626262626262626262626262626262626262626262626262626"
  ],
  "valid_test_cases": [
    {
      "rand":
          "0000000000000000000000000000000000000000000000000000000000000000",
      "aggothernonce":
          "0337C87821AFD50A8644D820A8F3E02E499C931865C2360FB43D0A0D20DAFE07EA0287BF891D2A6DEAEBADC909352AA9405D1428C15F4B75F04DAE642A95C2548480",
      "key_indices": [0, 1, 2],
      "tweaks": [],
      "is_xonly": [],
      "msg_index": 0,
      "signer_index": 0,
      "expected": [
        "03D96275257C2FCCBB6EEB77BDDF51D3C88C26EE1626C6CDA8999B9D34F4BA13A60309BE2BF883C6ABE907FA822D9CA166D51A3DCC28910C57528F6983FC378B7843",
        "41EA65093F71D084785B20DC26A887CD941C9597860A21660CBDB9CC2113CAD3"
      ]
    },
    {
      "rand": null,
      "aggothernonce":
          "0337C87821AFD50A8644D820A8F3E02E499C931865C2360FB43D0A0D20DAFE07EA0287BF891D2A6DEAEBADC909352AA9405D1428C15F4B75F04DAE642A95C2548480",
      "key_indices": [1, 0, 2],
      "tweaks": [],
      "is_xonly": [],
      "msg_index": 0,
      "signer_index": 1,
      "expected": [
        "028FBCCF5BB73A7B61B270BAD15C0F9475D577DD85C2157C9D38BEF1EC922B48770253BE3638C87369BC287E446B7F2C8CA5BEB9FFBD1EA082C62913982A65FC214D",
        "AEAA31262637BFA88D5606679018A0FEEEC341F3107D1199857F6C81DE61B8DD"
      ]
    },
    {
      "rand":
          "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF",
      "aggothernonce":
          "0279BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F817980279BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798",
      "key_indices": [1, 2, 0],
      "tweaks": [],
      "is_xonly": [],
      "msg_index": 1,
      "signer_index": 2,
      "expected": [
        "024FA8D774F0C8743FAA77AFB4D08EE5A013C2E8EEAD8A6F08A77DDD2D28266DB803050905E8C994477F3F2981861A2E3791EF558626E645FBF5AA131C5D6447C2C2",
        "FEE28A56B8556B7632E42A84122C51A4861B1F2DEC7E81B632195E56A52E3E13"
      ],
      "comment": "Message longer than 32 bytes"
    },
    {
      "rand":
          "0000000000000000000000000000000000000000000000000000000000000000",
      "aggothernonce":
          "032DE2662628C90B03F5E720284EB52FF7D71F4284F627B68A853D78C78E1FFE9303E4C5524E83FFE1493B9077CF1CA6BEB2090C93D930321071AD40B2F44E599046",
      "key_indices": [0, 1, 2],
      "tweaks": [
        "E8F791FF9225A2AF0102AFFF4A9A723D9612A682A25EBE79802B263CDFCD83BB"
      ],
      "is_xonly": [true],
      "msg_index": 0,
      "signer_index": 0,
      "expected": [
        "031E07C0D11A0134E55DB1FC16095ADCBD564236194374AA882BFB3C78273BF673039D0336E8CA6288C00BFC1F8B594563529C98661172B9BC1BE85C23A4CE1F616B",
        "7B1246C5889E59CB0375FA395CC86AC42D5D7D59FD8EAB4FDF1DCAB2B2F006EA"
      ],
      "comment": "Tweaked public key"
    }
  ],
  "error_test_cases": [
    {
      "rand":
          "0000000000000000000000000000000000000000000000000000000000000000",
      "aggothernonce":
          "0337C87821AFD50A8644D820A8F3E02E499C931865C2360FB43D0A0D20DAFE07EA0287BF891D2A6DEAEBADC909352AA9405D1428C15F4B75F04DAE642A95C2548480",
      "key_indices": [1, 0, 3],
      "tweaks": [],
      "is_xonly": [],
      "msg_index": 0,
      "signer_index": 1,
      "error": {
        "type": "invalid_contribution",
        "signer": 2,
        "contrib": "pubkey"
      },
      "comment": "Signer 2 provided an invalid public key"
    },
    {
      "rand":
          "0000000000000000000000000000000000000000000000000000000000000000",
      "aggothernonce":
          "0337C87821AFD50A8644D820A8F3E02E499C931865C2360FB43D0A0D20DAFE07EA0287BF891D2A6DEAEBADC909352AA9405D1428C15F4B75F04DAE642A95C2548480",
      "key_indices": [1, 2],
      "tweaks": [],
      "is_xonly": [],
      "msg_index": 0,
      "signer_index": 1,
      "error": {
        "type": "value",
        "message":
            "The signer's pubkey must be included in the list of pubkeys."
      },
      "comment": "The signers pubkey is not in the list of pubkeys"
    },
    {
      "rand":
          "0000000000000000000000000000000000000000000000000000000000000000",
      "aggothernonce":
          "0437C87821AFD50A8644D820A8F3E02E499C931865C2360FB43D0A0D20DAFE07EA0287BF891D2A6DEAEBADC909352AA9405D1428C15F4B75F04DAE642A95C2548480",
      "key_indices": [1, 2, 0],
      "tweaks": [],
      "is_xonly": [],
      "msg_index": 0,
      "signer_index": 2,
      "error": {
        "type": "invalid_contribution",
        "signer": null,
        "contrib": "aggothernonce"
      },
      "comment":
          "aggothernonce is invalid due wrong tag, 0x04, in the first half"
    },
    {
      "rand":
          "0000000000000000000000000000000000000000000000000000000000000000",
      "aggothernonce":
          "0000000000000000000000000000000000000000000000000000000000000000000287BF891D2A6DEAEBADC909352AA9405D1428C15F4B75F04DAE642A95C2548480",
      "key_indices": [1, 2, 0],
      "tweaks": [],
      "is_xonly": [],
      "msg_index": 0,
      "signer_index": 2,
      "error": {
        "type": "invalid_contribution",
        "signer": null,
        "contrib": "aggothernonce"
      },
      "comment":
          "aggothernonce is invalid because first half corresponds to point at infinity"
    },
    {
      "rand":
          "0000000000000000000000000000000000000000000000000000000000000000",
      "aggothernonce":
          "0337C87821AFD50A8644D820A8F3E02E499C931865C2360FB43D0A0D20DAFE07EA0287BF891D2A6DEAEBADC909352AA9405D1428C15F4B75F04DAE642A95C2548480",
      "key_indices": [1, 2, 0],
      "tweaks": [
        "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141"
      ],
      "is_xonly": [false],
      "msg_index": 0,
      "signer_index": 2,
      "error": {"type": "value", "message": "The tweak must be less than n."},
      "comment": "Tweak is invalid because it exceeds group size"
    }
  ]
};
