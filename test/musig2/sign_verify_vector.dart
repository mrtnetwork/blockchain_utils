/// https://github.com/bitcoin/bips/blob/master/bip-0327/vectors/sign_verify_vectors.json
const Map<String, dynamic> signVerifyVector = {
  "sk": "7FB9E0E687ADA1EEBF7ECFE2F21E73EBDB51A7D450948DFE8D76D7F2D1007671",
  "pubkeys": [
    "03935F972DA013F80AE011890FA89B67A27B7BE6CCB24D3274D18B2D4067F261A9",
    "02F9308A019258C31049344F85F89D5229B531C845836F99B08601F113BCE036F9",
    "02DFF1D77F2A671C5F36183726DB2341BE58FEAE1DA2DECED843240F7B502BA661",
    "020000000000000000000000000000000000000000000000000000000000000007"
  ],
  "secnonces": [
    "508B81A611F100A6B2B6B29656590898AF488BCF2E1F55CF22E5CFB84421FE61FA27FD49B1D50085B481285E1CA205D55C82CC1B31FF5CD54A489829355901F703935F972DA013F80AE011890FA89B67A27B7BE6CCB24D3274D18B2D4067F261A9",
    "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003935F972DA013F80AE011890FA89B67A27B7BE6CCB24D3274D18B2D4067F261A9"
  ],
  "pnonces": [
    "0337C87821AFD50A8644D820A8F3E02E499C931865C2360FB43D0A0D20DAFE07EA0287BF891D2A6DEAEBADC909352AA9405D1428C15F4B75F04DAE642A95C2548480",
    "0279BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F817980279BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798",
    "032DE2662628C90B03F5E720284EB52FF7D71F4284F627B68A853D78C78E1FFE9303E4C5524E83FFE1493B9077CF1CA6BEB2090C93D930321071AD40B2F44E599046",
    "0237C87821AFD50A8644D820A8F3E02E499C931865C2360FB43D0A0D20DAFE07EA0387BF891D2A6DEAEBADC909352AA9405D1428C15F4B75F04DAE642A95C2548480",
    "0200000000000000000000000000000000000000000000000000000000000000090287BF891D2A6DEAEBADC909352AA9405D1428C15F4B75F04DAE642A95C2548480"
  ],
  "aggnonces": [
    "028465FCF0BBDBCF443AABCCE533D42B4B5A10966AC09A49655E8C42DAAB8FCD61037496A3CC86926D452CAFCFD55D25972CA1675D549310DE296BFF42F72EEEA8C9",
    "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
    "048465FCF0BBDBCF443AABCCE533D42B4B5A10966AC09A49655E8C42DAAB8FCD61037496A3CC86926D452CAFCFD55D25972CA1675D549310DE296BFF42F72EEEA8C9",
    "028465FCF0BBDBCF443AABCCE533D42B4B5A10966AC09A49655E8C42DAAB8FCD61020000000000000000000000000000000000000000000000000000000000000009",
    "028465FCF0BBDBCF443AABCCE533D42B4B5A10966AC09A49655E8C42DAAB8FCD6102FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC30"
  ],
  "msgs": [
    "F95466D086770E689964664219266FE5ED215C92AE20BAB5C9D79ADDDDF3C0CF",
    "",
    "2626262626262626262626262626262626262626262626262626262626262626262626262626"
  ],
  "valid_test_cases": [
    {
      "key_indices": [0, 1, 2],
      "nonce_indices": [0, 1, 2],
      "aggnonce_index": 0,
      "msg_index": 0,
      "signer_index": 0,
      "expected":
          "012ABBCB52B3016AC03AD82395A1A415C48B93DEF78718E62A7A90052FE224FB"
    },
    {
      "key_indices": [1, 0, 2],
      "nonce_indices": [1, 0, 2],
      "aggnonce_index": 0,
      "msg_index": 0,
      "signer_index": 1,
      "expected":
          "9FF2F7AAA856150CC8819254218D3ADEEB0535269051897724F9DB3789513A52"
    },
    {
      "key_indices": [1, 2, 0],
      "nonce_indices": [1, 2, 0],
      "aggnonce_index": 0,
      "msg_index": 0,
      "signer_index": 2,
      "expected":
          "FA23C359F6FAC4E7796BB93BC9F0532A95468C539BA20FF86D7C76ED92227900"
    },
    {
      "key_indices": [0, 1],
      "nonce_indices": [0, 3],
      "aggnonce_index": 1,
      "msg_index": 0,
      "signer_index": 0,
      "expected":
          "AE386064B26105404798F75DE2EB9AF5EDA5387B064B83D049CB7C5E08879531",
      "comment":
          "Both halves of aggregate nonce correspond to point at infinity"
    },
    {
      "key_indices": [0, 1, 2],
      "nonce_indices": [0, 1, 2],
      "aggnonce_index": 0,
      "msg_index": 1,
      "signer_index": 0,
      "expected":
          "D7D63FFD644CCDA4E62BC2BC0B1D02DD32A1DC3030E155195810231D1037D82D",
      "comment": "Empty message"
    },
    {
      "key_indices": [0, 1, 2],
      "nonce_indices": [0, 1, 2],
      "aggnonce_index": 0,
      "msg_index": 2,
      "signer_index": 0,
      "expected":
          "E184351828DA5094A97C79CABDAAA0BFB87608C32E8829A4DF5340A6F243B78C",
      "comment": "38-byte message"
    }
  ],
  "sign_error_test_cases": [
    {
      "key_indices": [1, 2],
      "aggnonce_index": 0,
      "msg_index": 0,
      "secnonce_index": 0,
      "error": {
        "type": "value",
        "message":
            "The signer's pubkey must be included in the list of pubkeys."
      },
      "comment":
          "The signers pubkey is not in the list of pubkeys. This test case is optional: it can be skipped by implementations that do not check that the signer's pubkey is included in the list of pubkeys."
    },
    {
      "key_indices": [1, 0, 3],
      "aggnonce_index": 0,
      "msg_index": 0,
      "secnonce_index": 0,
      "error": {
        "type": "invalid_contribution",
        "signer": 2,
        "contrib": "pubkey"
      },
      "comment": "Signer 2 provided an invalid public key"
    },
    {
      "key_indices": [1, 2, 0],
      "aggnonce_index": 2,
      "msg_index": 0,
      "secnonce_index": 0,
      "error": {
        "type": "invalid_contribution",
        "signer": null,
        "contrib": "aggnonce"
      },
      "comment":
          "Aggregate nonce is invalid due wrong tag, 0x04, in the first half"
    },
    {
      "key_indices": [1, 2, 0],
      "aggnonce_index": 3,
      "msg_index": 0,
      "secnonce_index": 0,
      "error": {
        "type": "invalid_contribution",
        "signer": null,
        "contrib": "aggnonce"
      },
      "comment":
          "Aggregate nonce is invalid because the second half does not correspond to an X coordinate"
    },
    {
      "key_indices": [1, 2, 0],
      "aggnonce_index": 4,
      "msg_index": 0,
      "secnonce_index": 0,
      "error": {
        "type": "invalid_contribution",
        "signer": null,
        "contrib": "aggnonce"
      },
      "comment":
          "Aggregate nonce is invalid because second half exceeds field size"
    },
    {
      "key_indices": [0, 1, 2],
      "aggnonce_index": 0,
      "msg_index": 0,
      "signer_index": 0,
      "secnonce_index": 1,
      "error": {
        "type": "value",
        "message": "first secnonce value is out of range."
      },
      "comment": "Secnonce is invalid which may indicate nonce reuse"
    }
  ],
  "verify_fail_test_cases": [
    {
      "sig": "FED54434AD4CFE953FC527DC6A5E5BE8F6234907B7C187559557CE87A0541C46",
      "key_indices": [0, 1, 2],
      "nonce_indices": [0, 1, 2],
      "msg_index": 0,
      "signer_index": 0,
      "comment":
          "Wrong signature (which is equal to the negation of valid signature)"
    },
    {
      "sig": "012ABBCB52B3016AC03AD82395A1A415C48B93DEF78718E62A7A90052FE224FB",
      "key_indices": [0, 1, 2],
      "nonce_indices": [0, 1, 2],
      "msg_index": 0,
      "signer_index": 1,
      "comment": "Wrong signer"
    },
    {
      "sig": "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141",
      "key_indices": [0, 1, 2],
      "nonce_indices": [0, 1, 2],
      "msg_index": 0,
      "signer_index": 0,
      "comment": "Signature exceeds group size"
    }
  ],
  "verify_error_test_cases": [
    {
      "sig": "012ABBCB52B3016AC03AD82395A1A415C48B93DEF78718E62A7A90052FE224FB",
      "key_indices": [0, 1, 2],
      "nonce_indices": [4, 1, 2],
      "msg_index": 0,
      "signer_index": 0,
      "error": {
        "type": "invalid_contribution",
        "signer": 0,
        "contrib": "pubnonce"
      },
      "comment": "Invalid pubnonce"
    },
    {
      "sig": "012ABBCB52B3016AC03AD82395A1A415C48B93DEF78718E62A7A90052FE224FB",
      "key_indices": [3, 1, 2],
      "nonce_indices": [0, 1, 2],
      "msg_index": 0,
      "signer_index": 0,
      "error": {
        "type": "invalid_contribution",
        "signer": 0,
        "contrib": "pubkey"
      },
      "comment": "Invalid pubkey"
    }
  ]
};
