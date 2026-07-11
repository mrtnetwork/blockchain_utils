import 'package:blockchain_utils/bip/address/exception/exception.dart';
import 'package:blockchain_utils/bip/bip/zip32/conf/config.dart';
import 'package:blockchain_utils/bip/bip/zip32/conf/zcash.dart';
import 'package:blockchain_utils/bip/zcash/src/encoding/encoding.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/layout/layout.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';
import 'package:blockchain_utils/utils/json/extension/json.dart';

enum UnifiedReceiverMode {
  address,
  ivk,
  fvk,
  sk;

  String viewName() {
    return switch (this) {
      sk => "Spending key",
      ivk => "Incomming view key",
      fvk => "Full viewing key",
      address => "address",
    };
  }
}

enum Typecode implements Comparable<Typecode> {
  p2pkh(code: 0x00, dataLength: 20, fvkLength: 65, ivkLength: 65, skLength: 74),
  p2sh(code: 0x01, dataLength: 20),
  sapling(
    code: 0x02,
    dataLength: 43,
    fvkLength: 128,
    ivkLength: 64,
    skLength: 169,
  ),
  orchard(
    code: 0x03,
    dataLength: 43,
    fvkLength: 96,
    ivkLength: 64,
    skLength: 32,
  ),
  unknown(code: 0x04);

  const Typecode({
    required this.code,
    this.dataLength,
    this.fvkLength,
    this.ivkLength,
    this.skLength,
  });
  final int code;
  final int? dataLength;
  final int? fvkLength;
  final int? ivkLength;
  final int? skLength;

  static Typecode fromTypecode(int code) {
    if (code >= Typecode.unknown.code &&
        code <= ZcashEncodingUtils.maxTypeCodeValue) {
      return Typecode.unknown;
    }
    return values.firstWhere(
      (e) => e.code == code,
      orElse: () {
        throw AddressConverterException(
          "Ivalid zcash unified address typecode.",
          details: {"typecode": code.toString()},
        );
      },
    );
  }

  static Typecode fromName(String? name) {
    return values.firstWhere(
      (e) => e.name == name,
      orElse: () {
        throw ItemNotFoundException(message: name);
      },
    );
  }

  int? getLength(UnifiedReceiverMode mode) {
    return switch (mode) {
      UnifiedReceiverMode.address => dataLength,
      UnifiedReceiverMode.fvk => fvkLength,
      UnifiedReceiverMode.ivk => ivkLength,
      UnifiedReceiverMode.sk => skLength,
    };
  }

  /// Sort Typecode by its numeric receiver typecode (ZIP-316 requirement)
  @override
  int compareTo(Typecode other) => code.compareTo(other.code);
}

abstract class ZUnifiedReceiver extends VariantLayoutSerializable
    with Equality
    implements Comparable<ZUnifiedReceiver> {
  final Typecode type;
  final List<int> data;
  final UnifiedReceiverMode mode;
  ZUnifiedReceiver({
    required this.type,
    required this.mode,
    required List<int> data,
  }) : data =
           ZcashEncodingUtils.validateReceiverEncoding(
             data: data,
             typecode: type,
             mode: mode,
           ).asImmutableBytes;
  int get typeCode => type.code;

  factory ZUnifiedReceiver.deserializeJson(
    Map<String, dynamic> json,
    UnifiedReceiverMode mode,
  ) {
    final decode = VariantLayoutSerializable.toVariantDecodeResult(json);
    final type = Typecode.fromName(decode.variantName);
    if (type == Typecode.p2sh && mode != UnifiedReceiverMode.address) {
      throw AddressConverterException.addressValidationFailed();
    }
    return switch (type) {
      Typecode.orchard => ReceiverOrchard.deserializeJson(decode.value, mode),
      Typecode.p2pkh => ReceiverP2pkh.deserializeJson(decode.value, mode),
      Typecode.p2sh => ReceiverP2sh.deserializeJson(decode.value),
      Typecode.sapling => ReceiverSapling.deserializeJson(decode.value, mode),
      Typecode.unknown => ReceiverUnknown.deserializeJson(decode.value, mode),
    };
  }
  static Layout<Map<String, dynamic>> layout({String? property}) {
    return LayoutConst.varintLazyEnum([
      LazyVariantModel(
        layout: ({property}) => ReceiverOrchard.layout(peroperty: property),
        property: Typecode.orchard.name,
        index: Typecode.orchard.code,
      ),
      LazyVariantModel(
        layout: ({property}) => ReceiverSapling.layout(peroperty: property),
        property: Typecode.sapling.name,
        index: Typecode.sapling.code,
      ),
      LazyVariantModel(
        layout: ({property}) => ReceiverP2pkh.layout(peroperty: property),
        property: Typecode.p2pkh.name,
        index: Typecode.p2pkh.code,
      ),
      LazyVariantModel(
        layout: ({property}) => ReceiverP2sh.layout(peroperty: property),
        property: Typecode.p2sh.name,
        index: Typecode.p2sh.code,
      ),
      LazyVariantModel(
        layout: ({property}) => ReceiverUnknown.layout(peroperty: property),
        property: Typecode.unknown.name,
        onNormalizeDecodeResult: (result, variant) {
          final data = result.valueEnsureAsMap<String, dynamic>(
            Typecode.unknown.name,
          );
          return {
            Typecode.unknown.name: {...data, "typeCode": variant},
          };
        },
        onRequestIndex: (source) {
          final data = source.valueEnsureAsMap<String, dynamic>(
            Typecode.unknown.name,
          );
          return data.valueAsInt("typeCode");
        },
        index: null,
      ),
    ], property: property);
  }

  @override
  Layout<Map<String, dynamic>> toVariantLayout({String? property}) {
    return layout(property: property);
  }

  @override
  String get variantName => type.name;

  T cast<T extends ZUnifiedReceiver>() {
    if (this is! T) throw CastFailedException<T>(value: this);
    return this as T;
  }

  @override
  int compareTo(ZUnifiedReceiver other) {
    final c = type.compareTo(other.type);
    if (c != 0) return c;
    return BytesUtils.compareBytes(data, other.data);
  }

  @override
  List<dynamic> get variables => [type, data];
}

class ReceiverOrchard extends ZUnifiedReceiver {
  ReceiverOrchard({required super.data, required super.mode})
    : super(type: Typecode.orchard);
  factory ReceiverOrchard.deserializeJson(
    Map<String, dynamic> json,
    UnifiedReceiverMode mode,
  ) {
    final List<int> bytes = json.valueAsBytes("data");
    return ReceiverOrchard(data: bytes, mode: mode);
  }
  static Layout<Map<String, dynamic>> layout({String? peroperty}) {
    return LayoutConst.struct([
      LayoutConst.varintVector(LayoutConst.u8(), property: "data"),
    ], property: peroperty);
  }

  @override
  Layout<Map<String, dynamic>> toLayout({String? property}) {
    return layout(peroperty: property);
  }

  @override
  Map<String, dynamic> toSerializeJson() {
    return {"data": data};
  }
}

class ReceiverSapling extends ZUnifiedReceiver {
  ReceiverSapling({required super.data, required super.mode})
    : super(type: Typecode.sapling);
  factory ReceiverSapling.deserializeJson(
    Map<String, dynamic> json,
    UnifiedReceiverMode mode,
  ) {
    final List<int> bytes = json.valueAsBytes("data");
    return ReceiverSapling(data: bytes, mode: mode);
  }
  static Layout<Map<String, dynamic>> layout({String? peroperty}) {
    return LayoutConst.struct([
      LayoutConst.varintVector(LayoutConst.u8(), property: "data"),
    ], property: peroperty);
  }

  @override
  Layout<Map<String, dynamic>> toLayout({String? property}) {
    return layout(peroperty: property);
  }

  @override
  Map<String, dynamic> toSerializeJson() {
    return {"data": data};
  }
}

class ReceiverP2pkh extends ZUnifiedReceiver {
  ReceiverP2pkh({required super.data, required super.mode})
    : super(type: Typecode.p2pkh);
  factory ReceiverP2pkh.deserializeJson(
    Map<String, dynamic> json,
    UnifiedReceiverMode mode,
  ) {
    final List<int> bytes = json.valueAsBytes("data");
    return ReceiverP2pkh(data: bytes, mode: mode);
  }
  static Layout<Map<String, dynamic>> layout({String? peroperty}) {
    return LayoutConst.struct([
      LayoutConst.varintVector(LayoutConst.u8(), property: "data"),
    ], property: peroperty);
  }

  @override
  Layout<Map<String, dynamic>> toLayout({String? property}) {
    return layout(peroperty: property);
  }

  @override
  Map<String, dynamic> toSerializeJson() {
    return {"data": data};
  }
}

class ReceiverP2sh extends ZUnifiedReceiver {
  ReceiverP2sh(List<int> data)
    : super(type: Typecode.p2sh, data: data, mode: UnifiedReceiverMode.address);
  factory ReceiverP2sh.deserializeJson(Map<String, dynamic> json) {
    return ReceiverP2sh(json.valueAsBytes("data"));
  }
  static Layout<Map<String, dynamic>> layout({String? peroperty}) {
    return LayoutConst.struct([
      LayoutConst.varintVector(LayoutConst.u8(), property: "data"),
    ], property: peroperty);
  }

  @override
  Layout<Map<String, dynamic>> toLayout({String? property}) {
    return layout(peroperty: property);
  }

  @override
  Map<String, dynamic> toSerializeJson() {
    return {"data": data};
  }
}

class ReceiverUnknown extends ZUnifiedReceiver {
  ReceiverUnknown._({
    required super.data,
    required this.typeCode,
    required super.mode,
  }) : super(type: Typecode.unknown);
  factory ReceiverUnknown({
    required List<int> data,
    required int typeCode,
    required UnifiedReceiverMode mode,
  }) {
    if (typeCode > ZcashEncodingUtils.maxTypeCodeValue ||
        typeCode < Typecode.unknown.code) {
      throw AddressConverterException("Invalid zcash address typecode.");
    }
    return ReceiverUnknown._(data: data, typeCode: typeCode, mode: mode);
  }
  ReceiverUnknown copyWith({
    List<int>? data,
    int? typeCode,
    UnifiedReceiverMode? mode,
  }) {
    return ReceiverUnknown(
      data: data ?? this.data,
      typeCode: typeCode ?? this.typeCode,
      mode: mode ?? this.mode,
    );
  }

  factory ReceiverUnknown.deserializeJson(
    Map<String, dynamic> json,
    UnifiedReceiverMode mode,
  ) {
    return ReceiverUnknown(
      data: json.valueAsBytes("data"),
      typeCode: json.valueAsInt("typeCode"),
      mode: mode,
    );
  }
  @override
  final int typeCode;
  static Layout<Map<String, dynamic>> layout({String? peroperty}) {
    return LayoutConst.struct([
      LayoutConst.varintVector(LayoutConst.u8(), property: "data"),
    ], property: peroperty);
  }

  @override
  Layout<Map<String, dynamic>> toLayout({String? property}) {
    return layout(peroperty: property);
  }

  @override
  Map<String, dynamic> toSerializeJson() {
    return {"data": data, "typeCode": typeCode};
  }

  @override
  List<dynamic> get variables => [type, data, typeCode];
}

enum ZcashNetwork {
  mainnet("Mainnet", 1),
  testnet("Testnet", 2),
  regtest("Regtest", 3);

  const ZcashNetwork(this.name, this.value);
  final String name;
  final int value;
  static ZcashNetwork fromValue(int? value) {
    return values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw ItemNotFoundException(name: "ZcashNetwork"),
    );
  }

  ZIP32CoinConfig config() {
    final conf = ZcashConf();
    return conf.fromNetwork(this);
  }
}
