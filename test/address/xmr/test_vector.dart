import 'dart:typed_data';

final List<Map<String, dynamic>> testVector = [
  {
    "public":
        "23e98445b5dfe3240a15ca5dfd00f62334d2eef0e4a94d3c0c4c32e08323cb32",
    "address":
        "42z3MVZMRgE72dPA89MtCD6tYeWke8cV2B3YPYg1pe5x9X7VVqee6MWhjPrjCMiUFwejWkh8KL6MpN8cwX7B5WuZAxw2YbQ",
    "decode":
        "23e98445b5dfe3240a15ca5dfd00f62334d2eef0e4a94d3c0c4c32e08323cb32eecbb34bdf8671f383ab7d6feeacb6e1973c3f4c890c637e5612f5377bb57c58",
    "params": {
      "net_ver": Uint8List.fromList([0x12]),
      "pub_vkey":
          "eecbb34bdf8671f383ab7d6feeacb6e1973c3f4c890c637e5612f5377bb57c58"
    }
  },
  {
    "public":
        "8e19cf96ffb31025a1bfb74ecf18bc0982d5c1ab03d0a1c76dcb5ba38f5ead34",
    "address":
        "471SLbc2E2j7J5QMCEAV6K2bGd3C3TjrGaMiBQxAnR7z9ozebfZdbjJWbGWq7fuBWWj6nfj2PK8xJVCT6eVu9b7oKxCaZrA",
    "decode":
        "8e19cf96ffb31025a1bfb74ecf18bc0982d5c1ab03d0a1c76dcb5ba38f5ead34ac48be40f72bbdb0e9754ffdfbffd7fbb2ba26d66540d3a894d13b24bcfa12a7",
    "params": {
      "net_ver": Uint8List.fromList([0x12]),
      "pub_vkey":
          "ac48be40f72bbdb0e9754ffdfbffd7fbb2ba26d66540d3a894d13b24bcfa12a7"
    }
  },
  {
    "public":
        "6d51ad1391438723e12ae80210090bc7ceefa5e5131aeb2c12c569e5a2913624",
    "address":
        "45mPJPfAqJe715SyK5n57QaRPh6WsAtHx8NZrZwr657s773aSMqd76qeQAxDxM9EHyTwRVxNFVSSSTJxJiJn9ft1Lm6rSJU",
    "decode":
        "6d51ad1391438723e12ae80210090bc7ceefa5e5131aeb2c12c569e5a29136247ea573b8b9ce0adf98d90a8ffa4a0ca10dbdb43a05e1679d4b63610bd19756af",
    "params": {
      "net_ver": Uint8List.fromList([0x12]),
      "pub_vkey":
          "7ea573b8b9ce0adf98d90a8ffa4a0ca10dbdb43a05e1679d4b63610bd19756af"
    }
  },
  {
    "public":
        "811a20969a67c1e837897b59b5ae14df9f4d3602ad4147e62590fa4a02520b54",
    "address":
        "46WsFRPkXDzfqo87wKrssqeQR8xRgzBFUfViHB9umxxzF81gT9EJJYYBo7mBe7YTM7LpNPpZbbaiRYwg5PbxXSgwH7qbwC7",
    "decode":
        "811a20969a67c1e837897b59b5ae14df9f4d3602ad4147e62590fa4a02520b546c5d25f8be2401408a2e25fa115a0e7679f10c147f1836bef8fe2ecd9802708e",
    "params": {
      "net_ver": Uint8List.fromList([0x12]),
      "pub_vkey":
          "6c5d25f8be2401408a2e25fa115a0e7679f10c147f1836bef8fe2ecd9802708e"
    }
  },
  {
    "public":
        "5381e6ee5b4957c8de2f38565ada954ee0f4f1d8a72809eb927b0a2ebc6dd4b0",
    "address":
        "44nepe755wkabfsyV6V7aLECDuhVHjEmngQM2hSUfDVDWYTJL6kZbyo6dHy8kkGV32bt1nzWAPbsMMz14moFuWXAA64Xe63",
    "decode":
        "5381e6ee5b4957c8de2f38565ada954ee0f4f1d8a72809eb927b0a2ebc6dd4b09f33292efb0bb621a251fdf9d6f00dd087fb78f38705107d72a52d2a11fa2950",
    "params": {
      "net_ver": Uint8List.fromList([0x12]),
      "pub_vkey":
          "9f33292efb0bb621a251fdf9d6f00dd087fb78f38705107d72a52d2a11fa2950"
    }
  },
  {
    "public":
        "b99863e7814e01f097b74b2bd1ddb89f748da8baf5e5ddd690ee484dc75bcbfa",
    "address":
        "48f32veKzithF3uB6f8YKqTfv8VkTf5dvctZVqDoXvnNiw2btyjPxEJ3rHMfY5yt7HXhkpkVGDEQ4VKh2rCLydhoAzq2zmF",
    "decode":
        "b99863e7814e01f097b74b2bd1ddb89f748da8baf5e5ddd690ee484dc75bcbfab12eeb34de598f110984beb4bb3c78b78f312cf951789da953e022921e69de58",
    "params": {
      "net_ver": Uint8List.fromList([0x12]),
      "pub_vkey":
          "b12eeb34de598f110984beb4bb3c78b78f312cf951789da953e022921e69de58"
    }
  },
  {
    "public":
        "1c13a9d806b7ff5cc1c2fa452d190093535c93df2357fee9bade5fd598d590c5",
    "address":
        "42gpVpsap22GWrm7eKJ3L3ReF72ko9pzyg6UTMehwt6sZyYMWUFC2qXRV3ZwYqKzCrDWHx5MCmPQ929dnBEp417U4CqXQad",
    "decode":
        "1c13a9d806b7ff5cc1c2fa452d190093535c93df2357fee9bade5fd598d590c524c7bee28d4cda92609e32daabd3634ac342f5368491e606de5d36495ffdff1c",
    "params": {
      "net_ver": Uint8List.fromList([0x12]),
      "pub_vkey":
          "24c7bee28d4cda92609e32daabd3634ac342f5368491e606de5d36495ffdff1c"
    }
  },
  {
    "public":
        "330b05541129753e1f23256734867b4414c6ec977de481b79c3e765f1280bf75",
    "address":
        "43ZJFDz9yB2BPf9G8UaQQJCPUQcgrSNc8XiFWcZ3cihLLiuD19FSnN8YHQ5V2q7STT221mc8Lq3nj3ijDE3PBDrJ1RFMLJT",
    "decode":
        "330b05541129753e1f23256734867b4414c6ec977de481b79c3e765f1280bf75e9a17ad1b94de5bb06f4fd49e2a012061543227e4f027410422cc1c578e44b03",
    "params": {
      "net_ver": Uint8List.fromList([0x12]),
      "pub_vkey":
          "e9a17ad1b94de5bb06f4fd49e2a012061543227e4f027410422cc1c578e44b03"
    }
  },
  {
    "public":
        "3c19152be2de5b8f9c8b639b245ce7e912d33745bd039a4f8bda1323df3cb3a9",
    "address":
        "43uCaCQcL66R2DGN5soknSfz7759mmF5TEJhXVFVxy8eVQc7vEjPnyZ8g2yfZP3uHxXhvjPaF5onET1sg6KsWhnA9MZ28e9",
    "decode":
        "3c19152be2de5b8f9c8b639b245ce7e912d33745bd039a4f8bda1323df3cb3a9d59508994ccc942ddfb6811effe357b793b32344108f579b88addf5e46d3834a",
    "params": {
      "net_ver": Uint8List.fromList([0x12]),
      "pub_vkey":
          "d59508994ccc942ddfb6811effe357b793b32344108f579b88addf5e46d3834a"
    }
  },
  {
    "public":
        "c0812a2df78774503bcf60d02caa3961996a353151822577651b6c632b76763e",
    "address":
        "48vDqDGxoJTERNGjVHteCGHKqSkzKk6fWLyHGr1qfDchBUMBBD6vXWrH6oAB8uS4qRe76DmJaxY6DGhr2MgQMSEkKhjYTYX",
    "decode":
        "c0812a2df78774503bcf60d02caa3961996a353151822577651b6c632b76763e9ae7909d9f41936041538c64dd4becddd617cf106b7bd25de3b2b12e97b311a5",
    "params": {
      "net_ver": Uint8List.fromList([0x12]),
      "pub_vkey":
          "9ae7909d9f41936041538c64dd4becddd617cf106b7bd25de3b2b12e97b311a5"
    }
  },
  {
    "public":
        "3faaa18b36f802d6ec839ca39467364ceeac5c23f8ec79628d35799476d7b024",
    "address":
        "4433Vab4gFbcx2nvQD79wBDsLiFeEfU4YHV5HkJgMQ3H75hdsEWxNU41HaLodGgZsrh1WvjhA4upnjWe8wET2UyuNwZShee",
    "decode":
        "3faaa18b36f802d6ec839ca39467364ceeac5c23f8ec79628d35799476d7b0245b2f77b0ce871d01b5620745b5628def32935d83918b2bfe282a87da547098c2",
    "params": {
      "net_ver": Uint8List.fromList([0x12]),
      "pub_vkey":
          "5b2f77b0ce871d01b5620745b5628def32935d83918b2bfe282a87da547098c2"
    }
  },
  {
    "public":
        "fd20edfb56c7da849554de67d9dd029b0bca34ef9587bc36f0022c3718ae79a3",
    "address":
        "4BDUDowyJh7PBE1hSWgJYHSw9B8th27f1ABxrAE38tvtUGjfsups7uB53vUfbGx1Xh6c3xKtLRsYD419c1pSgaMMQuQC4Xf",
    "decode":
        "fd20edfb56c7da849554de67d9dd029b0bca34ef9587bc36f0022c3718ae79a30b630c8314846a1837340428258abc21818e55d8ca08ea11f37c86b1e0d4c8d3",
    "params": {
      "net_ver": Uint8List.fromList([0x12]),
      "pub_vkey":
          "0b630c8314846a1837340428258abc21818e55d8ca08ea11f37c86b1e0d4c8d3"
    }
  },
  {
    "public":
        "56f2a92004887a31ac1ab5c83da038b26d49b1372dc8077624d06522e09c119e",
    "address":
        "44vDQyjyCDP9JtEdhgMfyZWqxwYxNPeXgLm9HiWqSueQTUQgJPpMevPBC68RuXKfsW24zwsSoD8zqYtzJYURS6NU57wwH9a",
    "decode":
        "56f2a92004887a31ac1ab5c83da038b26d49b1372dc8077624d06522e09c119e44e1c454be5fdc3cedd84c6f29cc7906640d85d10dd2f6beb21edb06b28d1924",
    "params": {
      "net_ver": Uint8List.fromList([0x12]),
      "pub_vkey":
          "44e1c454be5fdc3cedd84c6f29cc7906640d85d10dd2f6beb21edb06b28d1924"
    }
  },
  {
    "public":
        "016879c5e2dd6c9ec0c446f4361f3eb8624bcbb84d0537c20070ebb6fa2c9ea3",
    "address":
        "41gCku8TDLoTZ6yCaqzhL9XqkpPynfg9kZT4Tw1kYte9UPmhSQUUdo7UHxv6b8oPuzf8sfWTXHj2iGFc9qknwKo9LWqq5yP",
    "decode":
        "016879c5e2dd6c9ec0c446f4361f3eb8624bcbb84d0537c20070ebb6fa2c9ea3c5070a960f2c0aa32bcd29c87889b9e3ffae5681d2492b5b2f4a47ce3bf41cac",
    "params": {
      "net_ver": Uint8List.fromList([0x12]),
      "pub_vkey":
          "c5070a960f2c0aa32bcd29c87889b9e3ffae5681d2492b5b2f4a47ce3bf41cac"
    }
  },
  {
    "public":
        "936786e498fd3c3dfa4749b0f13e2477ce12a1ee7c6976487a42ff86d9c9ff1b",
    "address":
        "47D6SZrS7asBNG8UnSFZxFM3FyvW2RUiqD889zN2tCqk5ZQHvZFeAXf16BugtzS47RLS4RYLgJHYp5KNd9Shiw5YB687S9E",
    "decode":
        "936786e498fd3c3dfa4749b0f13e2477ce12a1ee7c6976487a42ff86d9c9ff1b411ec083b1aa1e0088e79d09efeff8742d38d5da1a652d19ceec9472d7a32759",
    "params": {
      "net_ver": Uint8List.fromList([0x12]),
      "pub_vkey":
          "411ec083b1aa1e0088e79d09efeff8742d38d5da1a652d19ceec9472d7a32759"
    }
  },
  {
    "public":
        "a299d28d19f5a6d7f52e280b65390d52bd72b6bd576d7a63cb1d0169d586b9ff",
    "address":
        "47nVhGpNwsbd84WhtdAxB6EqgZ5tQsEaDHh82NLkDkVejpLCXpFCDRK3aGYGsrSqDcHJwetdeSJYmSgqpA24vzKt4fAvgNE",
    "decode":
        "a299d28d19f5a6d7f52e280b65390d52bd72b6bd576d7a63cb1d0169d586b9fffafebca2bec22a0f62eeeac31dd5136181d9fd788e758e9992743608e0682320",
    "params": {
      "net_ver": Uint8List.fromList([0x12]),
      "pub_vkey":
          "fafebca2bec22a0f62eeeac31dd5136181d9fd788e758e9992743608e0682320"
    }
  },
  {
    "public":
        "2ccba4c6598b6f29b2537ebc1297b9881e7d9113c040eae4e1266483bc6f3a61",
    "address":
        "43KZoXMBsQa7yWXgYhWPGLPmXVqYouNRffHREQjykCkyHN7sZDF74FAhQCbDYAAjiD5GmnFQPbMZi4vgmXGfX58JQWVMCQx",
    "decode":
        "2ccba4c6598b6f29b2537ebc1297b9881e7d9113c040eae4e1266483bc6f3a61d5aa6640041ef1f1892a3b6a3c8196198a4b7b951c6a4917783f55c7a3da27d0",
    "params": {
      "net_ver": Uint8List.fromList([0x12]),
      "pub_vkey":
          "d5aa6640041ef1f1892a3b6a3c8196198a4b7b951c6a4917783f55c7a3da27d0"
    }
  },
  {
    "public":
        "683ea8053725734bd27bb390c9a4002bfd1532e07441e0bdd0e567bb3568a784",
    "address":
        "45aERhsdfDcDga5Z6Yp5cT8MkBjBAC7XuYkTGpM86JFYPF2raGh4AXcQd4UGEUNgDh3iYysmbx32Y6mW4Revehat3fhhkpu",
    "decode":
        "683ea8053725734bd27bb390c9a4002bfd1532e07441e0bdd0e567bb3568a784f9cf033c71904b8d399c74b00b82b4103d8538de512259227aed9ed653d00517",
    "params": {
      "net_ver": Uint8List.fromList([0x12]),
      "pub_vkey":
          "f9cf033c71904b8d399c74b00b82b4103d8538de512259227aed9ed653d00517"
    }
  },
  {
    "public":
        "88f031c1841dc965a1a4e3c678a4e9b8419de1325b8fbbaf4da97c089ebe31ee",
    "address":
        "46p6DGGmHbeHzxDt3vS7ptXpWzR2jsa3LWKfQqPEiFMzgq3EC9WtMUfNGAMbcYNzR2Ccq7F4WRy5FUtdqMbYshJ5RgTAAXQ",
    "decode":
        "88f031c1841dc965a1a4e3c678a4e9b8419de1325b8fbbaf4da97c089ebe31ee1e170589c8961c7f1d15e07d846b0d45753e5ffc9090c6a6beb63af6f1347eda",
    "params": {
      "net_ver": Uint8List.fromList([0x12]),
      "pub_vkey":
          "1e170589c8961c7f1d15e07d846b0d45753e5ffc9090c6a6beb63af6f1347eda"
    }
  },
  {
    "public":
        "aa59bad4e8699eaa03127c62236b3fc5185fb9b84ee6a3b0ab06e1901c44d071",
    "address":
        "485Xd6KjLvZVSL71kh8amkZy55wgcwHuUWYuJ3eCo9tbL4id486bBg8gPdHW3bLwwreFG87oXMdL7dydeknsadNNMFomyWo",
    "decode":
        "aa59bad4e8699eaa03127c62236b3fc5185fb9b84ee6a3b0ab06e1901c44d071fa0ec2b8e46e05eb7f7cea1290e39ddeadb486dbbbb124dd1149517697cc8fb3",
    "params": {
      "net_ver": Uint8List.fromList([0x12]),
      "pub_vkey":
          "fa0ec2b8e46e05eb7f7cea1290e39ddeadb486dbbbb124dd1149517697cc8fb3"
    }
  },
  {
    "public":
        "313b220a47b1abec2ef412f7cc75d4f6f163f986bf8e63fb600f3ce3e992e1f3",
    "address":
        "43VKF5FF3rzgWGwvxqFEPuiJf31q5EW9xj3eyDGe4RiGhefkwG1as47Y9RtauPmBcd3ZQpAcW9QeYdr4uctVXkm8EyrfGct",
    "decode":
        "313b220a47b1abec2ef412f7cc75d4f6f163f986bf8e63fb600f3ce3e992e1f306f6572b7cd244ba34acb7e199f7fa0f4c4f32213a9c6ddc49aba76e6a561b7b",
    "params": {
      "net_ver": Uint8List.fromList([0x12]),
      "pub_vkey":
          "06f6572b7cd244ba34acb7e199f7fa0f4c4f32213a9c6ddc49aba76e6a561b7b"
    }
  },
  {
    "public":
        "7ec5485f28c7b961c07885d75867845516822488233937e1bcfb5ead9cac4dd4",
    "address":
        "46Rk3AzabexHMKHdPCiPaTFETeZao8pRLekwiePb64x4cWcRS4x9Stz7Kxt9TeHAR79SLfzF7D2dSirDLNatWxCt41CjMX6",
    "decode":
        "7ec5485f28c7b961c07885d75867845516822488233937e1bcfb5ead9cac4dd44db7b556baee1b25d38f0fc81ac04a3270d9d439af9ca5fa321fdccb6784851a",
    "params": {
      "net_ver": Uint8List.fromList([0x12]),
      "pub_vkey":
          "4db7b556baee1b25d38f0fc81ac04a3270d9d439af9ca5fa321fdccb6784851a"
    }
  },
  {
    "public":
        "09d2d91b8cce1845f010d878c51a6db39c258fdd513160e2067ba90ba41fd139",
    "address":
        "41zha9DmZjuChV4g7wQnEpX3ScA9FAEoReojGcFV3gwAAbo49aB27BVY2eoPEwJTfn9Y2kicLP7bPA1YSd1jK5NdMi9oEyg",
    "decode":
        "09d2d91b8cce1845f010d878c51a6db39c258fdd513160e2067ba90ba41fd13964df82eeb90f20b981d4813e62bd19330707514cca4de235dd0565b1127f66b7",
    "params": {
      "net_ver": Uint8List.fromList([0x12]),
      "pub_vkey":
          "64df82eeb90f20b981d4813e62bd19330707514cca4de235dd0565b1127f66b7"
    }
  },
  {
    "public":
        "3dc6e7bdfd047632324b7d5567f1c0d8fbbac5bd57064878c4557e72c713e265",
    "address":
        "43xtcTr4d739PyBKC6qjRydJ1adEYjGETMCbFRiVqSVfHzBsWcQRFA7jF7VpJ7XEjyCFJ5nf13KsRbSmSCzscyso1Rj1eo2",
    "decode":
        "3dc6e7bdfd047632324b7d5567f1c0d8fbbac5bd57064878c4557e72c713e2658d772f95af6558fc8e669066d7a900433cf90eaf2bae44cdedbdb59f1785da03",
    "params": {
      "net_ver": Uint8List.fromList([0x12]),
      "pub_vkey":
          "8d772f95af6558fc8e669066d7a900433cf90eaf2bae44cdedbdb59f1785da03"
    }
  },
  {
    "public":
        "7a50b48a158d452cb85c38ba413ae1f45c6730db36ca793f75b87d847b6213b6",
    "address":
        "46Fx4fZG3Cg8UqoxEVjikphscDzRXqskLBce7yC2qbg6XTLNPSBigJPFwajXV1zyFB3qcBmbiMTW9Pd3EXww8tAiFh1LxXa",
    "decode":
        "7a50b48a158d452cb85c38ba413ae1f45c6730db36ca793f75b87d847b6213b612a10ff9ffe9145953a77c983a5cfe10f7b27032a52532873e8644fa1cee9782",
    "params": {
      "net_ver": Uint8List.fromList([0x12]),
      "pub_vkey":
          "12a10ff9ffe9145953a77c983a5cfe10f7b27032a52532873e8644fa1cee9782"
    }
  },
  {
    "public":
        "b29a2ee93cb399a775901b5c0d4688399b48a428576ee4c22f0682bc6c1491ea",
    "address":
        "48PfZcs6WD6V1ZjJmw1L4FAdreSxjj83dZUprXYwRsPEgE6xEDVJzQFVPXthAgjDvk4V9k48FJkK4aPFXPNK4oK2A3YT57B",
    "decode":
        "b29a2ee93cb399a775901b5c0d4688399b48a428576ee4c22f0682bc6c1491ea843148bf68e5f0a9b9452b06f82ffd14d66c53a8bd264bc7967189323192c550",
    "params": {
      "net_ver": Uint8List.fromList([0x12]),
      "pub_vkey":
          "843148bf68e5f0a9b9452b06f82ffd14d66c53a8bd264bc7967189323192c550"
    }
  },
  {
    "public":
        "8e01629147c5bd16941f91b73c8ccd4072eb4bbfd0400ca48d8c0c167c44a1f2",
    "address":
        "471EB82kEDA4n3N9MvFgpkBnEdqmcBpF5UXNRmzMwEGQhZ6kMu826cMaWznNXdsjKAEiy87Z5bYH6hWsJ8LpoAh8G5X35Xo",
    "decode":
        "8e01629147c5bd16941f91b73c8ccd4072eb4bbfd0400ca48d8c0c167c44a1f27400815528894ec862d7de6dae9195520c44b08ff3e191f2391ad8aaff759b85",
    "params": {
      "net_ver": Uint8List.fromList([0x12]),
      "pub_vkey":
          "7400815528894ec862d7de6dae9195520c44b08ff3e191f2391ad8aaff759b85"
    }
  },
  {
    "public":
        "2e8cb23659354b7be1979bb54e06dbc17aec3cdf4410d72a2fd5c8938bb38b6c",
    "address":
        "43PRRCHv1KGMioaKuoRtM8ZMzzx4uA9Nn84GPdNT6VTpK7YNdQgH5GsSXp1HQGH69aAajV2aF2F4oa89RwnVw8jNMATZkLm",
    "decode":
        "2e8cb23659354b7be1979bb54e06dbc17aec3cdf4410d72a2fd5c8938bb38b6c4a092b465d49f898a422dd50bf1e753948dc2a740ec7bcc607d88778bd1465b2",
    "params": {
      "net_ver": Uint8List.fromList([0x12]),
      "pub_vkey":
          "4a092b465d49f898a422dd50bf1e753948dc2a740ec7bcc607d88778bd1465b2"
    }
  },
  {
    "public":
        "1fd2d4e42145ae74563356c5e23273ac39e18ceadfe536a294978f28ab7c8773",
    "address":
        "42q48pBey8qLTcVWGvJMcWVoov6sPz1JMUCEZqxgBDGJLKtQPFoY9AdgqMYomRUgj3T5bwgzqjsWm1y1JiV33aNj4CXPism",
    "decode":
        "1fd2d4e42145ae74563356c5e23273ac39e18ceadfe536a294978f28ab7c87738a5549c28b2bc6ee266ce8faecd23a9beb134c15c4c2b605c5e2e2cf3505401c",
    "params": {
      "net_ver": Uint8List.fromList([0x12]),
      "pub_vkey":
          "8a5549c28b2bc6ee266ce8faecd23a9beb134c15c4c2b605c5e2e2cf3505401c"
    }
  },
  {
    "public":
        "765ccc031de7461051cc8020f80ab55640203e2c52c1d90b5f27746783932121",
    "address":
        "467GARKYg1K3jKYyrqXTw2FRjo1NXSQCx2uKYT7548xx6cC7rW7hqyvD5PcKhE8HFyKe3EPp35hWq1iEYFpC7cZN2xV48NQ",
    "decode":
        "765ccc031de7461051cc8020f80ab55640203e2c52c1d90b5f2774678393212185454013afd9a5483220b8905c458c6f6ed0d44d568d82044014fa47626c4111",
    "params": {
      "net_ver": Uint8List.fromList([0x12]),
      "pub_vkey":
          "85454013afd9a5483220b8905c458c6f6ed0d44d568d82044014fa47626c4111"
    }
  },
  {
    "public":
        "7ff1abe262aa047321bd9e81ab9d35535a4f387b9979953d5d38a090959cc29b",
    "address":
        "46UKd6Hz9kXLFvWtC3rKpYEwdKrQURKJcBGJvjhyf9F7T3q3yAZ6BmGXwUX1jj9hD53JRYSQdrSkp3RQgjw175qc6HLaCxj",
    "decode":
        "7ff1abe262aa047321bd9e81ab9d35535a4f387b9979953d5d38a090959cc29bbc4337e69d73d7b8f935d256fafc7c0dc0d0d7487637790e7924f43de2db432e",
    "params": {
      "net_ver": Uint8List.fromList([0x12]),
      "pub_vkey":
          "bc4337e69d73d7b8f935d256fafc7c0dc0d0d7487637790e7924f43de2db432e"
    }
  },
  {
    "public":
        "1c23f92b42d5d402b2b71ab0d9fc3044953ec1f0dabd5422bbe2b5e519632872",
    "address":
        "42gxctjDRHu1TB9k1VDyTDCULmoA276Ls6oxqE85d93MLATB1YGaVCRZwbrhGcwRJGfsXrHKi3KLn3DHuenKKqCREcGJJjM",
    "decode":
        "1c23f92b42d5d402b2b71ab0d9fc3044953ec1f0dabd5422bbe2b5e519632872915bddd325ccfec4f198f102e40bc9e8655d6b252872a30d396693de71e1a678",
    "params": {
      "net_ver": Uint8List.fromList([0x12]),
      "pub_vkey":
          "915bddd325ccfec4f198f102e40bc9e8655d6b252872a30d396693de71e1a678"
    }
  },
  {
    "public":
        "e4a5348225b0f86aae9aab63ccb7eb454f82bd8ce9361a6971566e2cd8b44a33",
    "address":
        "4AHf5UPcGEsJqx57DYp8tSCbQB2YLjmxMJdvjoR5mFfP9Y97FTeKCgPXSXWLdpD45nJCtKmj7ixXPGR3UqWeX8ds5LDXXyS",
    "decode":
        "e4a5348225b0f86aae9aab63ccb7eb454f82bd8ce9361a6971566e2cd8b44a3309eb628731aa58b5fd4ed065635a1166dc87d2fb4f89a65c284efd9d8c40f626",
    "params": {
      "net_ver": Uint8List.fromList([0x12]),
      "pub_vkey":
          "09eb628731aa58b5fd4ed065635a1166dc87d2fb4f89a65c284efd9d8c40f626"
    }
  },
  {
    "public":
        "6b428b4ce2658f6e3701460010a9823d4a5d071e9c70efa133434da4f3333112",
    "address":
        "45groc5FwtSKSDtbSh5UzDBFbUjWCXdwcTxqyGE2DAPa4ANXk75z6Mye3tosfAouGbSayxCyari7NezwRfQdwdL8Ph2kP4K",
    "decode":
        "6b428b4ce2658f6e3701460010a9823d4a5d071e9c70efa133434da4f3333112e6dcd74a0ac21cdd81bc6283eb83d898f7d3a99fa0442de32e4918257a46f5c9",
    "params": {
      "net_ver": Uint8List.fromList([0x12]),
      "pub_vkey":
          "e6dcd74a0ac21cdd81bc6283eb83d898f7d3a99fa0442de32e4918257a46f5c9"
    }
  },
  {
    "public":
        "9b1553ede0100e5ceeeb7e97ce90b8444d72551787f2d68ad761f0fb48fd317c",
    "address":
        "47VyMRxLYQMGYa1v2jEjwDCRcxt6F3vHsQDwE1HuKH2gMsnKHWtpyFPgAeD1sDpSjXcgoDpVVWhEDAGffFgNkcESNRfHzXF",
    "decode":
        "9b1553ede0100e5ceeeb7e97ce90b8444d72551787f2d68ad761f0fb48fd317cce83ad4307afcaea28dbf79fed5e7ed55a83bfcf5d2626376c215144a867dfbd",
    "params": {
      "net_ver": Uint8List.fromList([0x12]),
      "pub_vkey":
          "ce83ad4307afcaea28dbf79fed5e7ed55a83bfcf5d2626376c215144a867dfbd"
    }
  },
  {
    "public":
        "34f96da7dfd1bec84c904288783f9aaafefc871539c98eea5d4006710a53c92f",
    "address":
        "43dYSrVwfDXaW9p99czaZXVbsoAsnSJTFgCdMq2Vz3Yt8tyWje5XXnEFBta2gSDFGwP3gUNLCCVkfjA6U7ioTVaE3GQPBGB",
    "decode":
        "34f96da7dfd1bec84c904288783f9aaafefc871539c98eea5d4006710a53c92f352f6b4786f28754d2ae9bd368772483ce436318ad55dcfc09fd98d8bec70714",
    "params": {
      "net_ver": Uint8List.fromList([0x12]),
      "pub_vkey":
          "352f6b4786f28754d2ae9bd368772483ce436318ad55dcfc09fd98d8bec70714"
    }
  },
  {
    "public":
        "83fb0b11d4338899f2193b321dba5a7acb5b5f0b0231dbf70246468b8bd65a7b",
    "address":
        "46dCDFdpeoHSkU2ys5zSufMYG2kB2kSEWiKJ9PqzzokmMeissXZxWSXUrrRDQpwdeRLZipswdwPejM3j1EzzkSYoSiBPDyu",
    "decode":
        "83fb0b11d4338899f2193b321dba5a7acb5b5f0b0231dbf70246468b8bd65a7b75e6d01a7a2cb4a68fa910573c7b4a74f76993ea528f1477da5e0b40a2ece0e3",
    "params": {
      "net_ver": Uint8List.fromList([0x12]),
      "pub_vkey":
          "75e6d01a7a2cb4a68fa910573c7b4a74f76993ea528f1477da5e0b40a2ece0e3"
    }
  },
  {
    "public":
        "e84f76f9aa4ef8242a335ec035cd6ebabda1137119647094dc047293dfd307ab",
    "address":
        "4ARiJaJXUzb73qyGJWLBg9YEcuctB8PzPRu88zQBtZbUVfk4P9DufrzKVAuXy4JkgS3p9X6dvJDFdULtfo5FGfxCADsADLb",
    "decode":
        "e84f76f9aa4ef8242a335ec035cd6ebabda1137119647094dc047293dfd307ab6504f54890f88b6e84cffdf074435310d12d12c1600cb8a37908ccfb7e911151",
    "params": {
      "net_ver": Uint8List.fromList([0x12]),
      "pub_vkey":
          "6504f54890f88b6e84cffdf074435310d12d12c1600cb8a37908ccfb7e911151"
    }
  },
  {
    "public":
        "abe9647de0bf228dc323429d10f788e238f18f50a777ccabdd07285b1051680d",
    "address":
        "488xeGqyCy7QiGkDvzJCKHeqeBLybzEmyVkHq97LjWbZ3GtxfNRYwpmPhv8tbzGvJhN9w1bjshjedYcFTfC6SbX3SCdK6wY",
    "decode":
        "abe9647de0bf228dc323429d10f788e238f18f50a777ccabdd07285b1051680d98836a60818ae287bf3cb54d97d1de7e78af135d992e8ebcf86a2ce424392edf",
    "params": {
      "net_ver": Uint8List.fromList([0x12]),
      "pub_vkey":
          "98836a60818ae287bf3cb54d97d1de7e78af135d992e8ebcf86a2ce424392edf"
    }
  },
  {
    "public":
        "e7a39f63d025092c14c34716b9b3928e7dc2fdaf7155be0609d9da71b2a316d9",
    "address":
        "4AQEjNsqUsi8NeETzgm2sjQqLw9CyvDwj21agtnMeBdXdLfEvTGXJKscowwjUzPJWxfYhfTjjjNLL87jv9e3TvfxJE6q6pJ",
    "decode":
        "e7a39f63d025092c14c34716b9b3928e7dc2fdaf7155be0609d9da71b2a316d941a4002322624ad617339d13d9218de6747381dc8ccb452a8b86166a77841798",
    "params": {
      "net_ver": Uint8List.fromList([0x12]),
      "pub_vkey":
          "41a4002322624ad617339d13d9218de6747381dc8ccb452a8b86166a77841798"
    }
  },
  {
    "public":
        "eaba117c6f22c506047326daa048868805bf2f45e786ac516aa52fe3bf8be03b",
    "address":
        "4AX2MGk7nNp21NpMB4VZMoPkb7VzHd9ddEcqtKdDw6LoAzyBC5pyAxtYGsfgasXyxqT9o8fjq15R248MZwJx93mVLyZ6ayk",
    "decode":
        "eaba117c6f22c506047326daa048868805bf2f45e786ac516aa52fe3bf8be03bc868f4e4954bddbaf91f0351ac8ab69c59b8353ecd364112b1a5f0a257eb2cb1",
    "params": {
      "net_ver": Uint8List.fromList([0x12]),
      "pub_vkey":
          "c868f4e4954bddbaf91f0351ac8ab69c59b8353ecd364112b1a5f0a257eb2cb1"
    }
  },
  {
    "public":
        "4e5f35bde9b01d80d077a7c22e2c7e60a02793cee5976948accb87d34622a7ba",
    "address":
        "44bN9JLQJNGNYfJKH2qi1jHAPavqMRmeQDA3E1FYKFtaY96mcghx2zJCvFw5UMayFjgBNNcJWrCk9CjybUkaTvpUM3JDXbL",
    "decode":
        "4e5f35bde9b01d80d077a7c22e2c7e60a02793cee5976948accb87d34622a7ba2bf9bde13e6857474123dafbc7fb7eea3c0b1609a7d2aa4631d2c5ca0071f5b1",
    "params": {
      "net_ver": Uint8List.fromList([0x12]),
      "pub_vkey":
          "2bf9bde13e6857474123dafbc7fb7eea3c0b1609a7d2aa4631d2c5ca0071f5b1"
    }
  },
  {
    "public":
        "d4f369a67ad6e534fe74f92df47afe3efef92d694247161f320c3ea11467b2e4",
    "address":
        "49hALN1U7VW9s7G2W8xhBsBY97zw3gGDB6DdrZCHHu3FfF3CvCQhNmChrmpQo1SzNtDGmPmkWJmJD55iHwsNEhseESBQSEX",
    "decode":
        "d4f369a67ad6e534fe74f92df47afe3efef92d694247161f320c3ea11467b2e4a25a2a144e9347f446612652aa65e1495e4f7ed37e3b6e18666fa67f02733177",
    "params": {
      "net_ver": Uint8List.fromList([0x12]),
      "pub_vkey":
          "a25a2a144e9347f446612652aa65e1495e4f7ed37e3b6e18666fa67f02733177"
    }
  },
  {
    "public":
        "5e4801276a24d33ccbde270e8837585f7f2e149db7aa6392c2f4c6123d52d2bd",
    "address":
        "45CLGzu5WEEBAoT1PfmfcKGySSJ8co8NeRYmi9L8UJe5YcvWRRuwtZNPSRiQShdn7SJ61CAM9JQr4J1bAUCUWB92UQCdJK7",
    "decode":
        "5e4801276a24d33ccbde270e8837585f7f2e149db7aa6392c2f4c6123d52d2bd0a2e288d675db186267b0ee1689dc96626efefe81060c165b273877557b791f2",
    "params": {
      "net_ver": Uint8List.fromList([0x12]),
      "pub_vkey":
          "0a2e288d675db186267b0ee1689dc96626efefe81060c165b273877557b791f2"
    }
  },
  {
    "public":
        "1aebb3bc0ca26aec4c4a7b66ff615313d94a7fc9598bc110c3b97b6f4575504f",
    "address":
        "42eH7nAVrXjgXPRts51ANE4KZNduiPphN3odxHnWfUrBENHffHPm14H6FaqRaBzVxu6gHprFYw9JPDbE9jtPHwK8NW5qULp",
    "decode":
        "1aebb3bc0ca26aec4c4a7b66ff615313d94a7fc9598bc110c3b97b6f4575504fea8ccec86b9b7e1f65736315670ac221f16b9ab3b28ef04b45799287caa5f3be",
    "params": {
      "net_ver": Uint8List.fromList([0x12]),
      "pub_vkey":
          "ea8ccec86b9b7e1f65736315670ac221f16b9ab3b28ef04b45799287caa5f3be"
    }
  },
  {
    "public":
        "48e2a09335f235fdb04fd2f0ce02d57676e1818b9db4b07b8a176af5add426d9",
    "address":
        "44PJhiJACPNjS6hquewXQgLpFfe62ftPhMfVFgkq2uqodTHfgGMytLM8vG5CZ8tuEiULxPTg7LsgM8tDhj5kyjHUAR944C3",
    "decode":
        "48e2a09335f235fdb04fd2f0ce02d57676e1818b9db4b07b8a176af5add426d9f08b3a4839abae2f571b97534a6f93a37ab9e3b22edf2a2f2140b0dc950d1353",
    "params": {
      "net_ver": Uint8List.fromList([0x12]),
      "pub_vkey":
          "f08b3a4839abae2f571b97534a6f93a37ab9e3b22edf2a2f2140b0dc950d1353"
    }
  },
  {
    "public":
        "0d45bb8969aa7759d59eb40c34f9fd76380f5186d6d46eacff245822fd1e5468",
    "address":
        "428HDt95p4nG2WPcwgt62gLmsbBRabBcyVwHV2VAwdRMJU3Xp3YXUpDfVATBR9JfWZhqk3u7aufFFaZLZH99vfLVJ9EmP41",
    "decode":
        "0d45bb8969aa7759d59eb40c34f9fd76380f5186d6d46eacff245822fd1e54686c8b802083231ee61715f12b412eb2f42b2fdfe130fc82c8a09ddce09be28a97",
    "params": {
      "net_ver": Uint8List.fromList([0x12]),
      "pub_vkey":
          "6c8b802083231ee61715f12b412eb2f42b2fdfe130fc82c8a09ddce09be28a97"
    }
  },
  {
    "public":
        "0617474a78be5a777968f0539072f5a919595ed4fb6aa6bb172c37894c025346",
    "address":
        "41rVj67mL8yLz3u4FBB72tVHUPsQPdJBXYJ1ig4DRv26Cs9TWWSxRV8Ryqdqaiajz2BRxN62tn424edpg4KyY49eHJhbkjD",
    "decode":
        "0617474a78be5a777968f0539072f5a919595ed4fb6aa6bb172c37894c025346ef0768b83f88479558736c94717b2b3e5bbfc55554fb41e1010ef39157ec3990",
    "params": {
      "net_ver": Uint8List.fromList([0x12]),
      "pub_vkey":
          "ef0768b83f88479558736c94717b2b3e5bbfc55554fb41e1010ef39157ec3990"
    }
  },
  {
    "public":
        "c5bc45b6bc113520c52f023aac95ef0efae6d823b4c4ae780e20ca9edb745c80",
    "address":
        "497ifj6n9GQ6UuvX1UE2Tp3WKtHCi1KrVM5gmj9R7xpBNZyTUeP9R7h5R35xPYHzt2TqYeQhuN5utQKz4gGxyS5L3h8rf88",
    "decode":
        "c5bc45b6bc113520c52f023aac95ef0efae6d823b4c4ae780e20ca9edb745c80f31dfa4facf3641a645d75fe9a4f83a072a97e0cf369538b77012012e5514f17",
    "params": {
      "net_ver": Uint8List.fromList([0x12]),
      "pub_vkey":
          "f31dfa4facf3641a645d75fe9a4f83a072a97e0cf369538b77012012e5514f17"
    }
  },
  {
    "public":
        "3dfcbc65fe13a63dd93151e42a8fc7be3a281f2b5c94963dfb1e3b47a60a0df4",
    "address":
        "43yMRDbvwKKBM1QgaSUmTCYpSdVfKVezyBNHyWrVMjnthvUJfJfKRckYejGm4wHh7dUrRi2htha4hJ95k9Rc58yqUU8h76b",
    "decode":
        "3dfcbc65fe13a63dd93151e42a8fc7be3a281f2b5c94963dfb1e3b47a60a0df4a7f70972b9f749bd39d85b6e894c60a6846b03ac99d6aa66782c4e392b0f2cf3",
    "params": {
      "net_ver": Uint8List.fromList([0x12]),
      "pub_vkey":
          "a7f70972b9f749bd39d85b6e894c60a6846b03ac99d6aa66782c4e392b0f2cf3"
    }
  }
];
