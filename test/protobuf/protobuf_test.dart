import 'package:blockchain_utils/exception/exception/exception.dart';
import 'package:blockchain_utils/protobuf/protobuf.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:test/test.dart';

void main() {
  group("Protobuf", () {
    _message();
    _repeatedPacked();
    _repeatedEnum();
    _repeatUnpacked();
    _enum();
    _string();
    _bool();
    _bytes();
    _numbers();
    _skip();
  });
}

void _skip() {
  test("Skip", () {
    final c1 = ProtoFieldConfig.int32(1);
    final c2 = ProtoFieldConfig.string(2);
    final c3 = ProtoFieldConfig.fixed32(3);
    final c4 = ProtoFieldConfig.fixed64(4);
    final encode = [
      ...ProtocolBufferEncoder.encode(-1, c1),
      ...ProtocolBufferEncoder.encode("hi", c2),
      ...ProtocolBufferEncoder.encode(12, c3),
      ...ProtocolBufferEncoder.encode(1, c4),
    ];
    List<ProtocolBufferDecoderResult> decode = ProtocolBufferDecoder.decode(
      encode,
      [c4],
    );
    expect(decode.getBigInt(4), BigInt.from(1));
    decode = ProtocolBufferDecoder.decode(encode, [c2]);
    expect(decode.getString(2), "hi");
    decode = ProtocolBufferDecoder.decode(encode, [c2, c3]);
    expect(decode.getInt(3), 12);
    expect(decode.getString(2), "hi");
  });
}

void _message() {
  test("message", () {
    {
      final value = _TestNestedMessage(i: null, b: null);
      final bytes = value.toBuffer();
      expect(bytes, []);
      final decode = _TestNestedMessage.deserialize(bytes);
      expect(decode, value);
    }
    {
      final value = _TestNestedMessage(i: null, b: "hi");
      final bytes = value.toBuffer();
      expect(bytes, [18, 2, 104, 105]);
      final decode = _TestNestedMessage.deserialize(bytes);
      expect(decode, value);
    }
    {
      final value = _TestNestedMessage(i: 5, b: "hi");
      final bytes = value.toBuffer();
      expect(bytes, [8, 5, 18, 2, 104, 105]);
      final decode = _TestNestedMessage.deserialize(bytes);
      expect(decode, value);
    }
    {
      final r = _TestMessage2(
        repeatedFixed32: [1, 2],
        repeatedUnpackedInt32: [2, 1],
        repeatedMessage: [
          _TestMessage2(
            repeatedFixed32: [1, 2],
            repeatedUnpackedInt32: [2, 1],
            repeatedMessage: [
              _TestMessage2(
                repeatedFixed32: [1, 2],
                repeatedUnpackedInt32: [2, 1],
                repeatedMessage: [
                  _TestMessage2(
                    repeatedFixed32: [1, 2],
                    repeatedUnpackedInt32: [2, 1],
                  ),
                ],
              ),
            ],
          ),
        ],
      );
      expect(
        r.toBuffer(),
        BytesUtils.fromHexString(
          "9a01080100000002000000b00102b00101c201399a01080100000002000000b00102b00101c201259a01080100000002000000b00102b00101c201119a01080100000002000000b00102b00101",
        ),
      );
      final decode = _TestMessage2.deserialize(r.toBuffer());
      expect(decode, r);
    }
    {
      final int int32Field = -123;
      final BigInt int64Field = BigInt.from(-123456789);

      final int uint32Field = 3000000000;
      final BigInt uint64Field = BigInt.parse('9000000000000000000');

      final int sint32Field = -123;
      final BigInt sint64Field = BigInt.from(-123456789);

      final int fixed32Field = 0xDEADBEEF;
      final BigInt fixed64Field = BigInt.parse('0x1122334455667788');

      final int sfixed32Field = -123456;
      final BigInt sfixed64Field = BigInt.from(-1234567890123);

      final double floatField = 3.0;
      final double doubleField = -3.0;

      final bool boolField = false;

      final MyTestEnum enumField = MyTestEnum.c;

      final String stringField = 'hello protobuf 🌍';

      final List<int> bytesField = <int>[0x00, 0x01, 0xFF, 0x7F];

      final List<int> repeatedInt32 = <int>[-1, 0, 1, 127, 128];
      final List<int> repeatedSint32 = <int>[-1, -2, 0, 1];
      final List<int> repeatedFixed32 = <int>[1, 0xFFFFFFFF];

      final List<double> repeatedFloat = <double>[0.0, -1.0, 3.0];
      final List<MyTestEnum> repeatedEnum = <MyTestEnum>[
        MyTestEnum.a,
        MyTestEnum.c,
      ];

      final List<int> repeatedUnpackedInt32 = <int>[1, 2, 3];
      final List<BigInt> repeatedUnpackedSint64 = <BigInt>[
        BigInt.from(-1),
        BigInt.from(-2),
        BigInt.from(-3),
      ];

      final _TestNestedMessage nestedMessage = _TestNestedMessage(
        i: -42,
        b: 'nested',
      );
      final _TestNestedMessage nestedMessage2 = _TestNestedMessage(
        i: 33,
        b: 'nested2',
      );
      final List<_TestNestedMessage> repeatedMessage = <_TestNestedMessage>[
        nestedMessage,
        nestedMessage2,
      ];

      final List<MapEntry<int, String>> mapIntString = <MapEntry<int, String>>[
        const MapEntry(1, 'one'),
        const MapEntry(-2, 'minus two'),
      ];

      final List<MapEntry<String, _TestNestedMessage>> mapStringMessage =
          <MapEntry<String, _TestNestedMessage>>[
            MapEntry('key', _TestNestedMessage(i: 7, b: 'value')),
          ];

      final value = _TestMessage(
        fixed32: fixed32Field,
        boolField: boolField,
        bytesField: bytesField,
        doubleField: doubleField,
        fixed64: fixed64Field,
        enumField: enumField,
        floatField: floatField,
        int32Field: int32Field,
        int64Field: int64Field,
        mapIntString: Map.fromEntries(mapIntString),
        mapStringMessage: Map.fromEntries(mapStringMessage),
        repeatedEnum: repeatedEnum,
        repeatedFloat: repeatedFloat,
        repeatedFixed32: repeatedFixed32,
        sFixed32: sfixed32Field,
        sFixed64: sfixed64Field,
        sInt32Field: sint32Field,
        sInt64Field: sint64Field,
        stringField: stringField,
        uin32Field: uint32Field,
        uint64Field: uint64Field,
        repeatedInt32: repeatedInt32,
        repeatedSInt32: repeatedSint32,
        repeatedUnpackedSint64: repeatedUnpackedSint64.map((e) => e).toList(),
        repeatedUnpackedInt32: repeatedUnpackedInt32,
        repeatedMessage: repeatedMessage,
      );
      final bytes = value.toBuffer();
      expect(
        bytes,
        BytesUtils.fromHexString(
          "0885ffffffffffffffff0110ebe590c5ffffffffff011880bcc1960b20808090948e8a9bf37c28f50130a9b4de753defbeadde4188776655443322114dc01dfeff5135fb048ee0feffff5d000040406100000000000008c0680070feffffff0f7a1368656c6c6f2070726f746f62756620f09f8c8d8201040001ff7f8a010fffffffffffffffffff0100017f8001920104010300029a010801000000ffffffffa2010c00000000000080bf00004040aa010600feffffff0fb00101b00102b00103b80101b80103b80105c2011308d6ffffffffffffffff0112066e6573746564c2010b082112076e657374656432ca0107080112036f6e65ca011608feffffffffffffffff0112096d696e75732074776fd201100a036b657912090807120576616c7565",
        ),
      );
      final decode = _TestMessage.deserialize(bytes);

      expect(decode, value);
    }
    {
      final nested = _TestNestedMessage(i: null, b: null);
      final value = _TestMessage(mapStringMessage: {"one": nested});
      final bytes = value.toBuffer();
      expect(bytes, [210, 1, 7, 10, 3, 111, 110, 101, 18, 0]);
      final decode = _TestMessage.deserialize(bytes);
      expect(decode, value);
    }
  });
}

void _repeatedPacked() {
  test("Repeated packed", () {
    {
      final int fieldNumber = 19;
      final value = [1, 2, 3];
      final config = ProtoFieldConfig.repeated(
        fieldNumber: fieldNumber,
        elementType: ProtoFieldType.fixed32,
        encoding: ProtoRepeatedEncoding.packed,
      );
      final bytes = ProtocolBufferEncoder.encode(value, config);
      expect(bytes, [154, 1, 12, 1, 0, 0, 0, 2, 0, 0, 0, 3, 0, 0, 0]);

      final decode = ProtocolBufferDecoder.decode(bytes, [
        config,
      ]).getList<int>(fieldNumber);
      expect(decode, value);
    }
    {
      final int fieldNumber = 18;
      final value = [-1, 2, -3];
      final config = ProtoFieldConfig.repeated(
        fieldNumber: fieldNumber,
        elementType: ProtoFieldType.sint32,
        encoding: ProtoRepeatedEncoding.packed,
      );
      final bytes = ProtocolBufferEncoder.encode(value, config);
      expect(bytes, [146, 1, 3, 1, 4, 5]);

      final decode = ProtocolBufferDecoder.decode(bytes, [
        config,
      ]).getList<int>(fieldNumber);
      expect(decode, value);
    }
  });
}

void _repeatedEnum() {
  test("Repeated enum", () {
    {
      final int fieldNumber = 21;
      final value = [MyTestEnum.b, MyTestEnum.c, MyTestEnum.a];
      final config = ProtoFieldConfig.repeated(
        fieldNumber: fieldNumber,
        elementType: ProtoFieldType.enumType,
        encoding: ProtoRepeatedEncoding.packed,
      );
      final bytes = ProtocolBufferEncoder.encode(value, config);
      expect(bytes, [170, 1, 7, 1, 254, 255, 255, 255, 15, 0]);
      final decode = ProtocolBufferDecoder.decode(bytes, [
        config,
      ]).getReapeatedEnum(fieldNumber, MyTestEnum.values);
      expect(decode, value);
    }
  });
}

void _repeatUnpacked() {
  test("Unpacked Repeated 32", () {
    {
      final int fieldNumber = 22;
      final value = [];
      final config = ProtoFieldConfig.repeated(
        fieldNumber: fieldNumber,
        elementType: ProtoFieldType.int32,
        encoding: ProtoRepeatedEncoding.unpacked,
      );
      final bytes = ProtocolBufferEncoder.encode(value, config);
      expect(bytes, []);

      final decode = ProtocolBufferDecoder.decode(bytes, [
        config,
      ]).getList<int>(fieldNumber, defaultValue: []);
      expect(decode, value);
    }
    {
      final int fieldNumber = 22;
      final value = [1, 2, 3];
      final config = ProtoFieldConfig.repeated(
        fieldNumber: fieldNumber,
        elementType: ProtoFieldType.int32,
        encoding: ProtoRepeatedEncoding.unpacked,
      );
      final bytes = ProtocolBufferEncoder.encode(value, config);
      expect(bytes, [176, 1, 1, 176, 1, 2, 176, 1, 3]);

      final decode = ProtocolBufferDecoder.decode(bytes, [
        config,
      ]).getList<int>(fieldNumber);
      expect(decode, value);
    }
  });
}

void _enum() {
  test("enum", () {
    {
      final int fieldNumber = 14;
      final value = MyTestEnum.a;
      final config = ProtoFieldConfig.enumType(fieldNumber);
      final bytes = ProtocolBufferEncoder.encode(value, config);
      expect(bytes, [112, 0]);

      final decode = ProtocolBufferDecoder.decode(bytes, [
        config,
      ]).getInt(fieldNumber);
      expect(decode, value.protoValue);
    }
    {
      final int fieldNumber = 14;
      final value = MyTestEnum.a;
      final config = ProtoFieldConfig.enumType(fieldNumber);
      final bytes = ProtocolBufferEncoder.encode(value, config);
      expect(bytes, [112, 0]);

      final decode = ProtocolBufferDecoder.decode(bytes, [
        config,
      ]).getEnum(fieldNumber, MyTestEnum.values);
      expect(decode, value);
    }
    {
      final int fieldNumber = 14;
      final value = MyTestEnum.c;
      final config = ProtoFieldConfig.enumType(fieldNumber);
      final bytes = ProtocolBufferEncoder.encode(value, config);
      expect(bytes, [112, 254, 255, 255, 255, 15]);

      final decode = ProtocolBufferDecoder.decode(bytes, [
        config,
      ]).getEnum(fieldNumber, MyTestEnum.values);
      expect(decode, value);
    }
  });
}

void _string() {
  test("string", () {
    {
      final config = ProtoFieldConfig.string(3);
      expect(
        () => ProtocolBufferEncoder.encode([0xC3, 0x28], config),
        throwsA(isA<ArgumentException>()),
      );
    }
    {
      final int fieldNumber = 15;
      final value = StringUtils.encode('hi');
      final config = ProtoFieldConfig.string(fieldNumber);
      final bytes = ProtocolBufferEncoder.encode(value, config);
      expect(bytes, [122, 2, 104, 105]);

      final decode = ProtocolBufferDecoder.decode(bytes, [
        config,
      ]).getString(fieldNumber);
      expect(decode, "hi");
    }
    {
      final int fieldNumber = 15;
      final value = 'hi';
      final config = ProtoFieldConfig.string(fieldNumber);
      final bytes = ProtocolBufferEncoder.encode(value, config);
      expect(bytes, [122, 2, 104, 105]);

      final decode = ProtocolBufferDecoder.decode(bytes, [
        config,
      ]).getString(fieldNumber);
      expect(decode, value);
    }
  });
}

void _bool() {
  test("bool", () {
    {
      final int fieldNumber = 13;
      final value = "true";
      final config = ProtoFieldConfig.bool(fieldNumber);
      final bytes = ProtocolBufferEncoder.encode(value, config);
      expect(bytes, [104, 1]);

      final decode = ProtocolBufferDecoder.decode(bytes, [
        config,
      ]).getBool(fieldNumber);
      expect(decode, true);
    }
    {
      final int fieldNumber = 13;
      final value = false;
      final config = ProtoFieldConfig.bool(fieldNumber);
      final bytes = ProtocolBufferEncoder.encode(value, config);
      expect(bytes, [104, 0]);

      final decode = ProtocolBufferDecoder.decode(bytes, [
        config,
      ]).getBool(fieldNumber);
      expect(decode, value);
    }
  });
}

void _bytes() {
  test("bytes", () {
    {
      final int fieldNumber = 16;
      final value = BytesUtils.toHexString([0, 1, 2]);
      final config = ProtoFieldConfig.bytes(fieldNumber);
      final bytes = ProtocolBufferEncoder.encode(value, config);
      expect(bytes, [130, 1, 3, 0, 1, 2]);

      final List<int> decode = ProtocolBufferDecoder.decode(bytes, [
        config,
      ]).getBytes(fieldNumber);
      expect(BytesUtils.toHexString(decode), value);
    }
    {
      final int fieldNumber = 16;
      final value = [];
      final config = ProtoFieldConfig.bytes(fieldNumber);
      final bytes = ProtocolBufferEncoder.encode(value, config);
      expect(bytes, [130, 1, 0]);

      final decode = ProtocolBufferDecoder.decode(bytes, [
        config,
      ]).getBytes(fieldNumber);
      expect(decode, value);
    }
    {
      final int fieldNumber = 16;
      final value = [0, 1, 2];
      final config = ProtoFieldConfig.bytes(fieldNumber);
      final bytes = ProtocolBufferEncoder.encode(value, config);
      expect(bytes, [130, 1, 3, 0, 1, 2]);

      final decode = ProtocolBufferDecoder.decode(bytes, [
        config,
      ]).getBytes(fieldNumber);
      expect(decode, value);
    }
  });
}

void _numbers() {
  test("float", () {
    {
      final config = ProtoFieldConfig.float(3);
      expect(
        () => ProtocolBufferEncoder.encode("", config),
        throwsA(isA<ArgumentException>()),
      );
    }
    {
      final int fieldNumber = 11;
      final value = "1230.123";
      final config = ProtoFieldConfig.float(fieldNumber);
      final bytes = ProtocolBufferEncoder.encode(value, config);
      expect(bytes, [93, 240, 195, 153, 68]);

      final decode = ProtocolBufferDecoder.decode(bytes, [
        config,
      ]).getDouble(fieldNumber);
      expect("${decode?.toStringAsFixed(3)}", value);
    }
    {
      final int fieldNumber = 11;
      final value = 1230.123;
      final config = ProtoFieldConfig.float(fieldNumber);
      final bytes = ProtocolBufferEncoder.encode(value, config);
      expect(bytes, [93, 240, 195, 153, 68]);

      final decode = ProtocolBufferDecoder.decode(bytes, [
        config,
      ]).getDouble(fieldNumber);
      expect("${decode?.toStringAsFixed(3)}", "$value");
    }
  });

  test("double", () {
    {
      final int fieldNumber = 12;
      final value = 0.0;
      final config = ProtoFieldConfig.double(fieldNumber);
      final bytes = ProtocolBufferEncoder.encode(value, config);
      expect(bytes, [97, 0, 0, 0, 0, 0, 0, 0, 0]);

      final decode = ProtocolBufferDecoder.decode(bytes, [
        config,
      ]).getDouble(fieldNumber);
      expect(decode, value);
    }
    {
      final int fieldNumber = 12;
      final value = -1.23;
      final config = ProtoFieldConfig.double(fieldNumber);
      final bytes = ProtocolBufferEncoder.encode(value, config);
      expect(bytes, [97, 174, 71, 225, 122, 20, 174, 243, 191]);

      final decode = ProtocolBufferDecoder.decode(bytes, [
        config,
      ]).getDouble(fieldNumber);
      expect(decode, value);
    }
  });

  test("fixed32", () {
    {
      final config = ProtoFieldConfig.fixed32(3);
      expect(
        () => ProtocolBufferEncoder.encode(-1, config),
        throwsA(isA<ArgumentException>()),
      );
      expect(
        () => ProtocolBufferEncoder.encode(BinaryOps.maxUint32 + 1, config),
        throwsA(isA<ArgumentException>()),
      );
    }
    {
      final int fieldNumber = 7;
      final value = BinaryOps.maxUint32;
      final config = ProtoFieldConfig.fixed32(fieldNumber);
      final bytes = ProtocolBufferEncoder.encode(value, config);
      expect(bytes, [61, 255, 255, 255, 255]);

      final decode = ProtocolBufferDecoder.decode(bytes, [
        config,
      ]).getInt(fieldNumber);
      expect(decode, value);
    }
    {
      final int fieldNumber = 7;
      final value = 0;
      final config = ProtoFieldConfig.fixed32(fieldNumber);
      final bytes = ProtocolBufferEncoder.encode(value, config);
      expect(bytes, [61, 0, 0, 0, 0]);

      final decode = ProtocolBufferDecoder.decode(bytes, [
        config,
      ]).getInt(fieldNumber);
      expect(decode, value);
    }
  });
  test("fixed64", () {
    {
      final config = ProtoFieldConfig.fixed64(3);
      expect(
        () => ProtocolBufferEncoder.encode(-BigInt.one, config),
        throwsA(isA<ArgumentException>()),
      );
      expect(
        () => ProtocolBufferEncoder.encode(
          BinaryOps.maskBig64 + BigInt.one,
          config,
        ),
        throwsA(isA<ArgumentException>()),
      );
    }
    {
      final int fieldNumber = 8;
      final value = BigInt.zero;
      final config = ProtoFieldConfig.fixed64(fieldNumber);
      final bytes = ProtocolBufferEncoder.encode(value, config);
      expect(bytes, [65, 0, 0, 0, 0, 0, 0, 0, 0]);

      final decode = ProtocolBufferDecoder.decode(bytes, [
        config,
      ]).getBigInt(fieldNumber);
      expect(decode, value);
    }
    {
      final int fieldNumber = 8;
      final value = BigInt.parse("9223372036854775807");
      final config = ProtoFieldConfig.fixed64(fieldNumber);
      final bytes = ProtocolBufferEncoder.encode(value, config);
      expect(bytes, [65, 255, 255, 255, 255, 255, 255, 255, 127]);

      final decode = ProtocolBufferDecoder.decode(bytes, [
        config,
      ]).getBigInt(fieldNumber);
      expect(decode, value);
    }
  });
  test("s64", () {
    final value = BinaryOps.maxI128;
    final config = ProtoFieldConfig.sint64(3);
    expect(
      () => ProtocolBufferEncoder.encode(value, config),
      throwsA(isA<ArgumentException>()),
    );
    {
      final int fieldNumber = 6;
      final value = BigInt.parse("9223372036854775807");
      final config = ProtoFieldConfig.sint64(fieldNumber);
      final bytes = ProtocolBufferEncoder.encode(value, config);
      expect(bytes, [48, 254, 255, 255, 255, 255, 255, 255, 255, 255, 1]);

      final decode = ProtocolBufferDecoder.decode(bytes, [
        config,
      ]).getBigInt(fieldNumber);
      expect(decode, value);
    }
    {
      final int fieldNumber = 6;
      final value = BigInt.parse("-1");
      final config = ProtoFieldConfig.sint64(fieldNumber);
      final bytes = ProtocolBufferEncoder.encode(value, config);
      expect(bytes, [48, 1]);

      final decode = ProtocolBufferDecoder.decode(bytes, [
        config,
      ]).getBigInt(fieldNumber);
      expect(decode, value);
    }
    {
      final int fieldNumber = 6;
      final value = BigInt.parse("-9223372036854775808");
      final config = ProtoFieldConfig.sint64(fieldNumber);
      final bytes = ProtocolBufferEncoder.encode(value, config);
      expect(bytes, [48, 255, 255, 255, 255, 255, 255, 255, 255, 255, 1]);
      final decode = ProtocolBufferDecoder.decode(bytes, [
        config,
      ]).getBigInt(fieldNumber);
      expect(decode, value);
    }
  });
  test("s32", () {
    {
      final value = -BinaryOps.maxUint32 - 2;
      final config = ProtoFieldConfig.sint32(3);
      expect(
        () => ProtocolBufferEncoder.encode(value, config),
        throwsA(isA<ArgumentException>()),
      );
    }
    {
      final int fieldNumber = 5;
      final value = BinaryOps.minInt32;
      final config = ProtoFieldConfig.sint32(fieldNumber);
      final bytes = ProtocolBufferEncoder.encode(value, config);
      expect(bytes, [40, 255, 255, 255, 255, 15]);
      final decode = ProtocolBufferDecoder.decode(bytes, [
        config,
      ]).getInt(fieldNumber);
      expect(decode, value);
    }
    {
      final int fieldNumber = 5;
      final value = -1;
      final config = ProtoFieldConfig.sint32(fieldNumber);
      final bytes = ProtocolBufferEncoder.encode(value, config);
      expect(bytes, [40, 1]);
      final decode = ProtocolBufferDecoder.decode(bytes, [
        config,
      ]).getInt(fieldNumber);
      expect(decode, value);
    }

    {
      final int fieldNumber = 5;
      final value = 1;
      final config = ProtoFieldConfig.sint32(fieldNumber);
      final bytes = ProtocolBufferEncoder.encode(value, config);
      expect(bytes, [40, 2]);
      final decode = ProtocolBufferDecoder.decode(bytes, [
        config,
      ]).getInt(fieldNumber);
      expect(decode, value);
    }
  });
  test("U64", () {
    {
      final fieldNumber = 4;
      final config = ProtoFieldConfig.uint64(fieldNumber);
      expect(
        () => ProtocolBufferEncoder.encode(-BigInt.one, config),
        throwsA(isA<ArgumentException>()),
      );
    }
    {
      final value = BinaryOps.maxInt64;
      final fieldNumber = 4;
      final config = ProtoFieldConfig.int64(fieldNumber);
      final bytes = ProtocolBufferEncoder.encode(value, config);
      expect(bytes, [32, 255, 255, 255, 255, 255, 255, 255, 255, 127]);
      final decode = ProtocolBufferDecoder.decode(bytes, [
        config,
      ]).getBigInt(fieldNumber);
      expect(decode, value);
    }
    {
      final value = BigInt.from(BinaryOps.maxUint32);
      final fieldNumber = 3;
      final config = ProtoFieldConfig.int64(fieldNumber);
      final bytes = ProtocolBufferEncoder.encode(value, config);
      expect(bytes, [24, 255, 255, 255, 255, 15]);
      final decode = ProtocolBufferDecoder.decode(bytes, [
        config,
      ]).getBigInt(fieldNumber);
      expect(decode, value);
    }
    {
      final value = BigInt.zero;
      final fieldNumber = 4;
      final config = ProtoFieldConfig.int64(fieldNumber);
      final bytes = ProtocolBufferEncoder.encode(value, config);
      expect(bytes, [32, 0]);
      final decode = ProtocolBufferDecoder.decode(bytes, [
        config,
      ]).getBigInt(fieldNumber);
      expect(decode, value);
    }
  });
  test("U32", () {
    {
      final value = -1;
      final config = ProtoFieldConfig.uint32(3);
      expect(
        () => ProtocolBufferEncoder.encode(value, config),
        throwsA(isA<ArgumentException>()),
      );
    }
    {
      final value = BinaryOps.maxUint32;
      final config = ProtoFieldConfig.uint32(3);
      final bytes = ProtocolBufferEncoder.encode(value, config);
      expect(bytes, [24, 255, 255, 255, 255, 15]);
      final decode = ProtocolBufferDecoder.decode(bytes, [config]).getInt(3);
      expect(decode, value);
    }
    {
      final config = ProtoFieldConfig.int32(3);
      final bytes = ProtocolBufferEncoder.encode(0, config);
      expect(bytes, [24, 0]);
      final decode = ProtocolBufferDecoder.decode(bytes, [config]).getInt(3);
      expect(decode, 0);
    }
  });
}

enum MyTestEnum implements ProtobufEnumVariant {
  a(0),
  b(1),
  c(-2);

  const MyTestEnum(this.protoValue);
  @override
  final int protoValue;
}

class _TestNestedMessage with ProtobufEncodableMessage, Equality {
  final int? i;
  final String? b;
  _TestNestedMessage({required this.i, required this.b});
  factory _TestNestedMessage.deserialize(List<int> bytes) {
    final decode = ProtobufEncodableMessage.deserialize(bytes, _bufferFields);

    return _TestNestedMessage(i: decode.getInt(1), b: decode.getString(2));
  }

  static List<ProtoFieldConfig> get _bufferFields => [
    ProtoFieldConfig.int32(1),
    ProtoFieldConfig.string(2),
  ];
  @override
  List<dynamic> get variables => [i, b];

  @override
  List<ProtoFieldConfig> get bufferFields => _bufferFields;

  @override
  List<Object?> get bufferValues => [i, b];
}

class _TestMessage2 with ProtobufEncodableMessage, Equality {
  final int? nestedInt32;
  final String? nestedString;
  final List<int>? repeatedInt32;
  final List<int>? repeatedSInt32;
  final List<int>? repeatedFixed32;
  final List<double>? repeatedFloat;

  final List<int>? repeatedUnpackedInt32;
  final List<BigInt>? repeatedUnpackedSint64;
  final List<_TestMessage2>? repeatedMessage;
  _TestMessage2({
    this.nestedInt32,
    this.nestedString,
    this.repeatedInt32,
    this.repeatedSInt32,
    this.repeatedFixed32,
    this.repeatedFloat,
    this.repeatedMessage,
    this.repeatedUnpackedInt32,
    this.repeatedUnpackedSint64,
  });
  factory _TestMessage2.deserialize(List<int> bytes) {
    final decode = ProtobufEncodableMessage.deserialize(bytes, _bufferFields);
    return _TestMessage2(
      nestedInt32: decode.getInt(1),
      nestedString: decode.getString(2),
      repeatedInt32: decode.getListOrNull(17),
      repeatedSInt32: decode.getListOrNull(18),
      repeatedFixed32: decode.getListOrNull(19),
      repeatedFloat: decode.getListOrNull(20),
      repeatedUnpackedInt32: decode.getListOrNull(22),
      repeatedUnpackedSint64: decode.getListOrNull(23),
      repeatedMessage:
          decode
              .getListOrNull<List<int>>(24)
              ?.map((e) => _TestMessage2.deserialize(e))
              .toList(),
    );
  }
  @override
  List<dynamic> get variables => [
    nestedInt32,
    nestedString,
    repeatedInt32,
    repeatedSInt32,
    repeatedFixed32,
    repeatedFloat,

    ///
    repeatedUnpackedInt32,
    repeatedUnpackedSint64,
    repeatedMessage,
  ];
  static List<ProtoFieldConfig> get _bufferFields => [
    ProtoFieldConfig.int32(1),
    ProtoFieldConfig.string(2),
    ProtoFieldConfig.repeated(
      fieldNumber: 17,
      elementType: ProtoFieldType.int32,
      encoding: ProtoRepeatedEncoding.packed,
    ),

    ProtoFieldConfig.repeated(
      fieldNumber: 18,
      elementType: ProtoFieldType.sint32,
      encoding: ProtoRepeatedEncoding.packed,
    ),
    ProtoFieldConfig.repeated(
      fieldNumber: 19,
      elementType: ProtoFieldType.fixed32,
      encoding: ProtoRepeatedEncoding.packed,
    ),
    ProtoFieldConfig.repeated(
      fieldNumber: 20,
      elementType: ProtoFieldType.float,
      encoding: ProtoRepeatedEncoding.packed,
    ),

    ProtoFieldConfig.repeated(
      fieldNumber: 22,
      elementType: ProtoFieldType.int32,
      encoding: ProtoRepeatedEncoding.unpacked,
    ),
    ProtoFieldConfig.repeated(
      fieldNumber: 23,
      elementType: ProtoFieldType.sint64,
      encoding: ProtoRepeatedEncoding.unpacked,
    ),
    ProtoFieldConfig.repeated(
      fieldNumber: 24,
      elementType: ProtoFieldType.message,
      encoding: ProtoRepeatedEncoding.unpacked,
    ),
  ];
  @override
  List<ProtoFieldConfig> get bufferFields => _bufferFields;

  @override
  List<Object?> get bufferValues => [
    nestedInt32,
    nestedString,
    repeatedInt32,
    repeatedSInt32,
    repeatedFixed32,
    repeatedFloat,
    repeatedUnpackedInt32,
    repeatedUnpackedSint64,
    repeatedMessage,
  ];
}

class _TestMessage with ProtobufEncodableMessage, Equality {
  final int? int32Field;
  final BigInt? int64Field;
  final int? uin32Field;
  final BigInt? uint64Field;
  final int? sInt32Field;
  final BigInt? sInt64Field;
  final int? fixed32;
  final BigInt? fixed64;
  final int? sFixed32;
  final BigInt? sFixed64;
  final double? floatField;
  final double? doubleField;
  final bool? boolField;
  final MyTestEnum? enumField;
  final List<int>? bytesField;
  final String? stringField;
  final List<int>? repeatedInt32;
  final List<int>? repeatedSInt32;
  final List<int>? repeatedFixed32;
  final List<double>? repeatedFloat;
  final List<MyTestEnum>? repeatedEnum;
  final List<int>? repeatedUnpackedInt32;
  final List<BigInt>? repeatedUnpackedSint64;
  final List<_TestNestedMessage>? repeatedMessage;
  final Map<int, String>? mapIntString;
  final Map<String, _TestNestedMessage>? mapStringMessage;
  _TestMessage({
    this.mapStringMessage,
    this.int32Field,
    this.int64Field,
    this.uin32Field,
    this.uint64Field,
    this.sInt32Field,
    this.sInt64Field,
    this.fixed32,
    this.fixed64,
    this.sFixed32,
    this.sFixed64,
    this.floatField,
    this.doubleField,
    this.boolField,
    this.enumField,
    this.bytesField,
    this.stringField,
    this.repeatedInt32,
    this.repeatedSInt32,
    this.repeatedFixed32,
    this.repeatedFloat,
    this.repeatedEnum,
    this.repeatedMessage,
    this.repeatedUnpackedInt32,
    this.repeatedUnpackedSint64,
    this.mapIntString,
  });
  factory _TestMessage.deserialize(List<int> bytes) {
    final decode = ProtobufEncodableMessage.deserialize(bytes, _bufferFields);
    return _TestMessage(
      int32Field: decode.getInt(1),
      int64Field: decode.getBigInt(2),
      uin32Field: decode.getInt(3),
      uint64Field: decode.getBigInt(4),
      sInt32Field: decode.getInt(5),
      sInt64Field: decode.getBigInt(6),
      fixed32: decode.getInt(7),
      fixed64: decode.getBigInt(8),
      sFixed32: decode.getInt(9),
      sFixed64: decode.getBigInt(10),
      floatField: decode.getDouble(11),
      doubleField: decode.getDouble(12),
      boolField: decode.getBool(13),
      enumField: decode.getEnum(14, MyTestEnum.values),
      stringField: decode.getString(15),
      bytesField: decode.getBytes(16),
      repeatedInt32: decode.getListOrNull(17),
      repeatedSInt32: decode.getListOrNull(18),
      repeatedFixed32: decode.getListOrNull(19),
      repeatedFloat: decode.getListOrNull(20),
      repeatedEnum: decode.getReapeatedEnumOrNull(21, MyTestEnum.values),
      repeatedUnpackedInt32: decode.getListOrNull(22),
      repeatedUnpackedSint64: decode.getListOrNull(23),
      repeatedMessage:
          decode
              .getListOrNull<List<int>>(24)
              ?.map((e) => _TestNestedMessage.deserialize(e))
              .toList(),
      mapIntString: decode.getMapOrNull<int, String>(25),
      mapStringMessage: decode
          .getMapOrNull<String, List<int>>(26)
          ?.map((k, v) => MapEntry(k, _TestNestedMessage.deserialize(v))),
    );
  }
  @override
  List<dynamic> get variables => [
    mapStringMessage,
    int32Field,
    int64Field,
    uin32Field,
    uint64Field,
    sInt32Field,
    sInt64Field,
    fixed32,
    fixed64,
    floatField,
    doubleField,
    boolField,
    enumField,

    ///
    stringField,
    bytesField,
    repeatedInt32,
    repeatedSInt32,
    repeatedFixed32,
    repeatedFloat,
    repeatedEnum,

    ///
    repeatedUnpackedInt32,
    repeatedUnpackedSint64,
    repeatedMessage,
    mapIntString,
  ];
  static List<ProtoFieldConfig> get _bufferFields => [
    ProtoFieldConfig.int32(1),
    ProtoFieldConfig.int64(2),
    ProtoFieldConfig.uint32(3),
    ProtoFieldConfig.uint64(4),
    ProtoFieldConfig.sint32(5),
    ProtoFieldConfig.sint64(6),
    ProtoFieldConfig.fixed32(7),
    ProtoFieldConfig.fixed64(8),
    ProtoFieldConfig.sFixed32(9),
    ProtoFieldConfig.sFixed64(10),
    ProtoFieldConfig.float(11),
    ProtoFieldConfig.double(12),
    ProtoFieldConfig.bool(13),
    ProtoFieldConfig.enumType(14),
    ProtoFieldConfig.string(15),
    ProtoFieldConfig.bytes(16),
    ProtoFieldConfig.repeated(
      fieldNumber: 17,
      elementType: ProtoFieldType.int32,
      encoding: ProtoRepeatedEncoding.packed,
    ),

    ProtoFieldConfig.repeated(
      fieldNumber: 18,
      elementType: ProtoFieldType.sint32,
      encoding: ProtoRepeatedEncoding.packed,
    ),
    ProtoFieldConfig.repeated(
      fieldNumber: 19,
      elementType: ProtoFieldType.fixed32,
      encoding: ProtoRepeatedEncoding.packed,
    ),
    ProtoFieldConfig.repeated(
      fieldNumber: 20,
      elementType: ProtoFieldType.float,
      encoding: ProtoRepeatedEncoding.packed,
    ),
    ProtoFieldConfig.repeated(
      fieldNumber: 21,
      elementType: ProtoFieldType.enumType,
      encoding: ProtoRepeatedEncoding.packed,
    ),
    ProtoFieldConfig.repeated(
      fieldNumber: 22,
      elementType: ProtoFieldType.int32,
      encoding: ProtoRepeatedEncoding.unpacked,
    ),
    ProtoFieldConfig.repeated(
      fieldNumber: 23,
      elementType: ProtoFieldType.sint64,
      encoding: ProtoRepeatedEncoding.unpacked,
    ),
    ProtoFieldConfig.repeated(
      fieldNumber: 24,
      elementType: ProtoFieldType.message,
      encoding: ProtoRepeatedEncoding.unpacked,
    ),
    ProtoFieldConfig.map(
      fieldNumber: 25,
      keyType: ProtoFieldType.int32,
      valueType: ProtoFieldType.string,
    ),
    ProtoFieldConfig.map(
      fieldNumber: 26,
      keyType: ProtoFieldType.string,
      valueType: ProtoFieldType.message,
    ),
  ];
  @override
  List<ProtoFieldConfig> get bufferFields => _bufferFields;

  @override
  List<Object?> get bufferValues => [
    int32Field,
    int64Field,
    uin32Field,
    uint64Field,
    sInt32Field,
    sInt64Field,
    fixed32,
    fixed64,
    sFixed32,
    sFixed64,
    floatField,
    doubleField,
    boolField,
    enumField,
    stringField,
    bytesField,
    repeatedInt32,
    repeatedSInt32,
    repeatedFixed32,
    repeatedFloat,
    repeatedEnum,
    repeatedUnpackedInt32,
    repeatedUnpackedSint64,
    repeatedMessage,
    mapIntString,
    mapStringMessage,
  ];
}
