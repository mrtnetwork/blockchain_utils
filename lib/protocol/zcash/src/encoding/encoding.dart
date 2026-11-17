import 'package:blockchain_utils/encoding/base58/src/base58_base.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/encoding/bech32/src/bech32_base.dart';
import 'package:blockchain_utils/protocol/bip/bip/bip32/bip32.dart';
import 'package:blockchain_utils/protocol/bip/bip/bip44/base/bip44_base.dart';
import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/encoding/f4jumble/src/f4jumble.dart';
import 'package:blockchain_utils/protocol/zcash/src/types.dart';
import 'package:blockchain_utils/crypto/crypto/crypto.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/encoding/layout/layout.dart';
import 'package:blockchain_utils/utils/binary/src/utils.dart';
import 'package:blockchain_utils/utils/json/extension/json.dart';
import 'package:blockchain_utils/utils/string/string.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

class ZcashEncodingUtils {
  static List<int> validateReceiverEncoding({
    required List<int> data,
    required Typecode typecode,
    required UnifiedReceiverMode mode,
  }) {
    final len = typecode.getLength(mode);
    if (len != null && data.length != len) {
      throw CoreErrors.zcashInvalidUnifiedBytes(mode.viewName());
    }
    switch (mode) {
      case UnifiedReceiverMode.address:
        return data;
      case UnifiedReceiverMode.fvk:
      case UnifiedReceiverMode.ivk:
        if (typecode == Typecode.p2sh) {
          throw CoreErrors.zcashInvalidUnifiedTypeCode(mode.viewName());
        }
        return data;
      case UnifiedReceiverMode.sk:
        if (typecode == Typecode.p2sh || typecode == Typecode.unknown) {
          throw CoreErrors.zcashInvalidUnifiedTypeCode(mode.viewName());
        }
        return data;
    }
  }

  static Layout<List<Map<String, dynamic>>> _unifiedCodecLayout({
    String? property,
  }) {
    return LayoutConst.dynamicVector(
      ZUnifiedReceiver.layout(),
      property: property,
    );
  }

  static const int maxTypeCodeValue = 0x02000000;
  static const int unifiedAddressPaddingLength = 16;
  static String encodeUnifiedObject({
    List<int>? addressBytes,
    List<ZUnifiedReceiver>? receivers,
    required String hrp,
    required UnifiedReceiverMode mode,
  }) {
    final hrpBytes = StringUtils.encode(hrp);
    const int paddingLen = unifiedAddressPaddingLength;
    if (hrpBytes.length > paddingLen) {
      throw CoreErrors.zcashInvalidUnifiedArguments(
        mode.viewName(),
        reason: "Invalid HRP.",
      );
    }
    if (addressBytes == null && receivers == null) {
      throw CoreErrors.zcashInvalidUnifiedArguments(
        mode.viewName(),
        reason: "Missing unified address receivers.",
      );
    }
    try {
      final layout = _unifiedCodecLayout();
      if (receivers == null) {
        final json = layout.deserialize(addressBytes!).value;
        receivers =
            json.map((e) => ZUnifiedReceiver.deserializeJson(e, mode)).toList();
      }
      receivers = validateUnifiedObjects(receivers: receivers, mode: mode);
      addressBytes = layout.serialize(
        receivers.map((e) => e.toSerializeVariantJson()).toList(),
      );
      final pad = List<int>.filled(paddingLen, 0)..setAll(0, hrpBytes);
      final jubmed = F4Jumble.apply([...addressBytes, ...pad]);
      return Bech32Encoder.encode(
        hrp,
        jubmed,
        encoding: Bech32Encodings.bech32m,
      );
    } catch (_) {
      throw CoreErrors.zcashInvalidUnifiedBytes(
        mode.viewName(),
        reason: "Invalid unified address bytes.",
      );
    }
  }

  static List<int> _validateAndRemoveUnfinedChecksum({
    required List<int> encoded,
    required String hrp,
    required UnifiedReceiverMode mode,
  }) {
    final hrpBytes = StringUtils.encode(hrp);
    const int paddingLen = unifiedAddressPaddingLength;
    if (hrpBytes.length > paddingLen) {
      throw CoreErrors.zcashInvalidUnifiedObject(
        mode.viewName(),
        reason: "Invalid hrp.",
      );
    }
    if (encoded.length < paddingLen) {
      throw CoreErrors.zcashInvalidUnifiedObject(
        mode.viewName(),
        reason: "Invalid checkshum.",
      );
    }
    final expectedPadding = List<int>.filled(paddingLen, 0)
      ..setAll(0, hrpBytes);

    final mainPart = encoded.sublist(0, encoded.length - paddingLen);
    final tail = encoded.sublist(encoded.length - paddingLen);
    if (BytesUtils.bytesEqual(tail, expectedPadding)) {
      return mainPart;
    }
    throw CoreErrors.zcashInvalidUnifiedObject(
      mode.viewName(),
      reason: "Invalid checkshum.",
    );
  }

  static (List<ZUnifiedReceiver>, List<int>, String)? decodeUnifiedObject({
    required String address,
    required UnifiedReceiverMode mode,
    String? expectedHrp,
  }) {
    (String, List<int>) decode;
    try {
      decode = Bech32Decoder.decodeWithoutHRP(
        address,
        encoding: Bech32Encodings.bech32m,
      );
    } catch (_) {
      return null;
    }
    if (!F4Jumble.haveValidLength(decode.$2)) {
      return null;
    }
    List<int>? unjumbled;
    try {
      unjumbled = F4Jumble.applyInv(decode.$2);
    } catch (_) {
      throw CoreErrors.zcashInvalidUnifiedObject(
        mode.viewName(),
        reason: "Invalid checkshum.",
      );
    }
    unjumbled = _validateAndRemoveUnfinedChecksum(
      encoded: unjumbled,
      hrp: decode.$1,
      mode: mode,
    );
    if (expectedHrp != null && expectedHrp != decode.$1) {
      throw CoreErrors.zcashInvalidUnifiedObject(
        mode.viewName(),
        reason: "Mismatch hrp.",
        details: {"expected": expectedHrp, "hrp": decode.$1},
      );
    }
    final layout = _unifiedCodecLayout();
    final receivers =
        layout
            .deserialize(unjumbled)
            .value
            .map((e) => ZUnifiedReceiver.deserializeJson(e, mode))
            .toList();

    return (receivers, unjumbled, decode.$1);
  }

  static String encodeBase58WithCheck({
    required List<int> bytes,
    required List<int> prefix,
  }) {
    return Base58Encoder.encodeWithChecksum([...prefix, ...bytes]);
  }

  static String encodeBech32Address({
    required List<int> bytes,
    required String hrp,
    required Bech32Encodings encoding,
  }) {
    return Bech32Encoder.encode(hrp, bytes, encoding: encoding);
  }

  static (List<int>, String)? tryDecodeBech32({
    required String bech32,
    required Bech32Encodings encoding,
  }) {
    try {
      final decode = Bech32Decoder.decodeWithoutHRP(bech32, encoding: encoding);
      return (decode.$2, decode.$1);
    } catch (_) {}
    return null;
  }

  static (List<int>, List<int>)? tryDecodeBase58WithCheck(
    String base58,
    int prefixLength,
  ) {
    try {
      final decode = Base58Decoder.decodeWithChecksum(base58);
      if (decode.length < prefixLength) return null;
      return (decode.sublist(0, prefixLength), decode.sublist(prefixLength));
    } catch (_) {}
    return null;
  }

  static List<int> decodeSaplingExtendedSpendingKey(
    String extendedKey,
    String hrp,
  ) {
    try {
      final decode = Bech32Decoder.decodeWithoutHRP(extendedKey);
      if (decode.$1 == hrp) return decode.$2;
      throw CoreErrors.zcashInvalidKeyData(
        "Sapling spending",
        reason: "Mismatch network hrp.",
      );
    } on BuError {
      rethrow;
    } catch (_) {
      throw CoreErrors.zcashInvalidKeyData("Sapling spending");
    }
  }

  static List<int> decodeSaplingExtendedFullViewKey(
    String extendedKey, {
    String? hrp,
  }) {
    try {
      final decode = Bech32Decoder.decodeWithoutHRP(extendedKey);
      if (hrp != null && decode.$1 == hrp) return decode.$2;
      throw CoreErrors.zcashInvalidKeyData(
        "Sapling full view.",
        reason: "Mismatch network hrp.",
      );
    } on BuError {
      rethrow;
    } catch (_) {
      throw CoreErrors.zcashInvalidKeyData("Sapling full view.");
    }
  }

  static List<ZUnifiedReceiver> validateUnifiedObjects({
    required List<ZUnifiedReceiver> receivers,
    required UnifiedReceiverMode mode,
  }) {
    if (receivers.isEmpty) {
      throw CoreErrors.zcashInvalidUnifiedArguments(
        mode.viewName(),
        reason: "Empty receivers.",
      );
    }
    final types = receivers.map((e) => e.type).toList();
    List<Typecode> allowedTypeCode = [
      Typecode.sapling,
      Typecode.orchard,
      Typecode.p2pkh,
      if (mode != UnifiedReceiverMode.sk) Typecode.unknown,
      if (mode == UnifiedReceiverMode.address) Typecode.p2sh,
    ];
    if (types.any(
      (e) =>
          !allowedTypeCode.contains(e) || receivers.any((e) => e.mode != mode),
    )) {
      throw CoreErrors.zcashInvalidUnifiedArguments(
        mode.viewName(),
        reason: "Receivers contains invalid type code.",
      );
    }
    if (mode == UnifiedReceiverMode.sk &&
        receivers.length != allowedTypeCode.length) {
      throw CoreErrors.zcashInvalidUnifiedArguments(
        mode.viewName(),
        reason: "Missing some USK type code.",
      );
    }
    if (receivers.toSet().length != receivers.length) {
      throw CoreErrors.zcashInvalidUnifiedArguments(
        mode.viewName(),
        reason: "Duplicate receivers.",
      );
    }
    if (mode == UnifiedReceiverMode.address) {
      if (types.contains(Typecode.p2pkh) && types.contains(Typecode.p2sh)) {
        throw CoreErrors.zcashInvalidUnifiedArguments(
          mode.viewName(),
          reason: "Unified address contains both P2PKH and P2SH receivers.",
        );
      }
    }
    return receivers.clone()..sort((a, b) => a.compareTo(b));
  }

  static List<ZUnifiedReceiver> decodeUnifiedSpendKey(List<int> bytes) {
    const int orchardEra = 5;
    final layout = LayoutConst.struct([
      LayoutConst.u32(property: "era"),
      LayoutConst.dynamicVector(
        ZUnifiedReceiver.layout(),
        property: "receivers",
      ),
    ]);
    final decode = layout.deserialize(bytes).value;
    final int era = decode.valueAsInt("era");
    final receiversJson = decode.valueEnsureAsList<Map<String, dynamic>>(
      "receivers",
    );
    if (era != orchardEra) {
      throw CoreErrors.zcashInvalidUnifiedBytes(
        UnifiedReceiverMode.sk.viewName(),
        reason: "Duplicate receivers.",
      );
    }
    List<ZUnifiedReceiver> receivers =
        receiversJson
            .map(
              (e) =>
                  ZUnifiedReceiver.deserializeJson(e, UnifiedReceiverMode.sk),
            )
            .toList();
    return validateUnifiedObjects(
      mode: UnifiedReceiverMode.sk,
      receivers: receivers,
    );
  }

  static List<int> encodeUnifiedSpendKey(List<ZUnifiedReceiver> receivers) {
    receivers = validateUnifiedObjects(
      receivers: receivers,
      mode: UnifiedReceiverMode.sk,
    );
    const int orchardEra = 5;
    final layout = LayoutConst.struct([
      LayoutConst.u32(property: "era"),
      LayoutConst.dynamicVector(
        ZUnifiedReceiver.layout(),
        property: "receivers",
      ),
    ]);
    final json = {
      "receivers": receivers.map((e) => e.toSerializeVariantJson()).toList(),
      "era": orchardEra,
    };
    return layout.serialize(json);
  }

  static BuBytes encodeBip44Fvk(Bip32Slip10Secp256k1 bip32) {
    if (bip32.type != CryptoKeyType.secp256k1) {
      throw CoreErrors.zcashInvalidKeyData(
        "Transparent full view.",
        reason: "Invalid key type.",
      );
    }
    return BuBytes([
      ...bip32.chainCode.toBytes(),
      ...bip32.publicKey.toPublicKeyBytes(),
    ]);
  }

  static Bip32Slip10Secp256k1 decodeBip44Fvk(List<int> bytes) {
    if (bytes.length != 65) {
      throw BuError(
        DefaultErrorType.invalidLength,
        "Invalid transparent fvk bytes length.",
      );
    }
    return Bip32Slip10Secp256k1.fromPublicKey(
      bytes.sublist(Bip32KeyDataConst.chaincodeByteLen),
      keyData: Bip32KeyData(
        chainCode: Bip32ChainCode(
          bytes.sublist(0, Bip32KeyDataConst.chaincodeByteLen),
        ),
        depth: Bip32Depth(3),
        fingerPrint: Bip32FingerPrint([0xff, 0xff, 0xff, 0xff]),
        index: Bip32KeyIndex.hardenIndex(0),
      ),
    );
  }

  static Bip32PublicKey decodeBip32Fvk(List<int> bytes) {
    if (bytes.length != 65) {
      throw BuError(
        DefaultErrorType.invalidLength,
        "Invalid transparent fvk bytes length.",
      );
    }
    return Bip32PublicKey.fromBytes(
      bytes.sublist(Bip32KeyDataConst.chaincodeByteLen),
      Bip32KeyData(
        depth: Bip32Depth(4),
        fingerPrint: Bip32FingerPrint([0xff, 0xff, 0xff, 0xff]),
        index: Bip32KeyIndex(Bip44Changes.chainExt.value),
        chainCode: Bip32ChainCode(
          bytes.sublist(0, Bip32KeyDataConst.chaincodeByteLen),
        ),
      ),
      Bip32Const.mainNetKeyNetVersions,
      CryptoKeyType.secp256k1,
    );
  }

  static BuBytes encodeBip32Fvk(Bip32PublicKey bip32) {
    if (bip32.type != CryptoKeyType.secp256k1) {
      throw CoreErrors.zcashInvalidKeyData(
        "Transparent full view.",
        reason: "Invalid key type.",
      );
    }
    return BuBytes([...bip32.chainCode.toBytes(), ...bip32.toPublicKeyBytes()]);
  }
}
