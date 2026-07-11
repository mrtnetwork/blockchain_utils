import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

void main() {
  test("exception serialization.", () {
    {
      final error = ArgumentException.invalidOperationArguments(
        "salam",
        reason: "error",
        details: {"alu": "1"},
        name: "2",
      );
      final deserialize = IException.deserialize(
        bytes: error.toCbor().encode(),
      );
      expect(error, deserialize);
    }
    {
      final error = StateException.badState(
        "salam",
        reason: "error",
        details: {"alu": 1},
        name: "2",
      );
      final deserialize = IException.deserialize(
        bytes: error.toCbor().encode(),
      );
      expect(error, deserialize);
    }
    {
      final error = ItemNotFoundException(
        message: "message",
        value: 12,
        details: {"alu": "1"},
        name: "2",
      );
      final deserialize = IException.deserialize(
        bytes: error.toCbor().encode(),
      );
      expect(error, deserialize);
    }
    {
      final error = CastFailedException(
        message: "message",
        value: 12,
        details: {"1": "1"},
      );
      final deserialize = IException.deserialize(
        bytes: error.toCbor().encode(),
      );
      expect(error, deserialize);
    }
    {
      final error = RPCError(
        message: "message",
        errorCode: 12,
        request: {"r1": "1"},
        details: {"1": "1"},
      );
      final deserialize = IException.deserialize(
        bytes: error.toCbor().encode(),
      );
      expect(error, deserialize);
    }
    {
      final error = RPCError(
        message: "message",
        errorCode: 12,
        request: {"r1": "1"},
        details: {
          "1": "1",
          "c":
              {
                "c1": 1,
                "c2": 2,
                "l": {"l1": "l1"},
              }.toString(),
        },
      );
      final deserialize = IException.deserialize(
        bytes: error.toCbor().encode(),
      );
      expect(error, deserialize);
    }
    {
      final error = Base58ChecksumError(details: {"1": "1"});
      final deserialize = IException.deserialize(
        bytes: error.toCbor().encode(),
      );
      expect(error, deserialize);
    }
    {
      final error = B64ConverterException(details: {"1": "1"});
      final deserialize = IException.deserialize(
        bytes: error.toCbor().encode(),
      );
      expect(error, deserialize);
    }
    {
      final error = Bech32Error("error", details: {"1": "1"});
      final deserialize = IException.deserialize(
        bytes: error.toCbor().encode(),
      );
      expect(error, deserialize);
    }

    {
      final error = AddressConverterException("error", details: {"1": "1"});
      final deserialize = IException.deserialize(
        bytes: error.toCbor().encode(),
      );
      expect(error, deserialize);
    }
    {
      final error = Bip44DepthError("error", details: {"1": "1"});
      final deserialize = IException.deserialize(
        bytes: error.toCbor().encode(),
      );
      expect(error, deserialize);
    }
    {
      final error = Bip32KeyError("error", details: {"1": "1", "2": "s"});
      final deserialize = IException.deserialize(
        bytes: error.toCbor().encode(),
      );
      expect(error, deserialize);
    }
    {
      final error = Zip32Error("error", details: {"1": "1", "2": "s"});
      final deserialize = IException.deserialize(
        bytes: error.toCbor().encode(),
      );
      expect(error, deserialize);
    }
    {
      final error = ElectrumException("error");
      final deserialize = IException.deserialize(
        bytes: error.toCbor().encode(),
      );
      expect(error, deserialize);
    }
    {
      final error = MnemonicException("error", details: {"mn": "a"});
      final deserialize = IException.deserialize(
        bytes: error.toCbor().encode(),
      );
      expect(error, deserialize);
    }
    {
      final error = MoneroKeyError("error", details: {"mn": "a"});
      final deserialize = IException.deserialize(
        bytes: error.toCbor().encode(),
      );
      expect(error, deserialize);
    }
    {
      final error = SubstrateKeyError("error", details: {"mn": "a"});
      final deserialize = IException.deserialize(
        bytes: error.toCbor().encode(),
      );
      expect(error, deserialize);
    }
    {
      final error = SubstratePathError("error", details: {"mn": "a"});
      final deserialize = IException.deserialize(
        bytes: error.toCbor().encode(),
      );
      expect(error, deserialize);
    }
    {
      final error = ZcashKeyEncodingError("error", details: {"mn": "a"});
      final deserialize = IException.deserialize(
        bytes: error.toCbor().encode(),
      );
      expect(error, deserialize);
    }
    {
      final error = CborException("error", details: {"mn": "a"});
      final deserialize = IException.deserialize(
        bytes: error.toCbor().encode(),
      );
      expect(error, deserialize);
    }
    {
      final error = CborSerializableException("error", details: {"mn": "a"});
      final deserialize = IException.deserialize(
        bytes: error.toCbor().encode(),
      );
      expect(error, deserialize);
    }
    {
      final error = CryptoException("error", details: {"mn": "a"});
      final deserialize = IException.deserialize(
        bytes: error.toCbor().encode(),
      );
      expect(error, deserialize);
    }
    {
      final error = LayoutException("error", details: {"mn": "a"});
      final deserialize = IException.deserialize(
        bytes: error.toCbor().encode(),
      );
      expect(error, deserialize);
    }
    {
      final error = ProtoException("error", details: {"mn": "a"});
      final deserialize = IException.deserialize(
        bytes: error.toCbor().encode(),
      );
      expect(error, deserialize);
    }
    {
      final error =
          Web3SecretStorageDefinationV3Exception.unsuportedBackupContent;
      final deserialize = IException.deserialize(
        bytes: error.toCbor().encode(),
      );
      expect(error, deserialize);
    }
    {
      final error = SS58ChecksumError("error", details: {"d1": "d"});
      final deserialize = IException.deserialize(
        bytes: error.toCbor().encode(),
      );
      expect(error, deserialize);
    }
    {
      final error = Utf8Exception("error", details: {"d1": "d"});
      final deserialize = IException.deserialize(
        bytes: error.toCbor().encode(),
      );
      expect(error, deserialize);
    }

    {
      final error = AmountConverterException("error", details: {"d1": "d"});
      final deserialize = IException.deserialize(
        bytes: error.toCbor().encode(),
      );
      expect(error, deserialize);
    }
    {
      final error = JsonParserError("error", details: {"d1": "d"});
      final deserialize = IException.deserialize(
        bytes: error.toCbor().encode(),
      );
      expect(error, deserialize);
    }
  });
}
