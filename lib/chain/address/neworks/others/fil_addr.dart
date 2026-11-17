import 'package:blockchain_utils/chain/address/neworks/others/eth_addr.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/encoding/base32/base32.dart';
import 'package:blockchain_utils/chain/address/utils/addr_dec_utils.dart';
import 'package:blockchain_utils/chain/address/utils/addr_key_validator.dart';
import 'package:blockchain_utils/chain/address/types/decoder.dart';
import 'package:blockchain_utils/chain/address/types/encoder.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/encoding/layout/constant/constant.dart';
import 'package:blockchain_utils/utils/binary/src/binary_operation.dart';
import 'package:blockchain_utils/utils/binary/src/utils.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Constants (mirrors go-address/constants.go)
// ─────────────────────────────────────────────────────────────────────────────

class FilAddrConst {
  static const String base32Alphabet = "abcdefghijklmnopqrstuvwxyz234567";
  static const int payloadHashLength = 20; // blake2b-160
  static const int checksumHashLength = 4; // blake2b-4
  static const int blsPublicKeyBytes = 48;
  static const int maxSubaddressLen = 54;
  static const int maxAddressStringLength = 2 + 19 + 1 + 93; // 115
}

// ─────────────────────────────────────────────────────────────────────────────
// Network
// ─────────────────────────────────────────────────────────────────────────────

enum FilNetwork {
  mainnet("f", 0),
  testnet("t", 1);

  final String prefix;
  final int value;
  const FilNetwork(this.prefix, this.value);
  static FilNetwork fromPrefix(String prefix) {
    return values.firstWhere(
      (e) => e.prefix == prefix,
      orElse:
          () =>
              throw CoreErrors.addressValidationFailed(
                reason: "Unknown network prefix",

                details: {"prefix": prefix},
              ),
    );
  }

  static FilNetwork fromValue(int? value) {
    return values.firstWhere(
      (e) => e.value == value,
      orElse:
          () =>
              throw CoreErrors.addressValidationFailed(
                reason: "Unknown network value.",
                details: {"got": value?.toString()},
              ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Protocol / Address Types
// ─────────────────────────────────────────────────────────────────────────────

enum FilAddrType {
  id(0, "ID"),
  secp256k1(1, "SECP256K1"),
  actor(2, "Actor"),
  bls(3, "BLS"),
  delegated(4, "Delegated");

  final int value;
  final String displayName;

  const FilAddrType(this.value, this.displayName);

  static FilAddrType fromValue(int? v) {
    return values.firstWhere(
      (e) => e.value == v,
      orElse:
          () =>
              throw CoreErrors.addressValidationFailed(
                reason: "Unknown Filecoin protocol: $v",
              ),
    );
  }
}

class _Uvarint {
  static List<int> encode(BigInt value) {
    if (value.isNegative) {
      throw CoreErrors.addressValidationFailed(
        reason: "uvarint value must be non-negative",
      );
    }
    return LayoutConst.lebU64().serialize(value);
  }

  static ({BigInt value, int length}) decode(List<int> bytes) {
    final decode = LayoutConst.lebU64().deserialize(bytes);
    return (value: decode.value, length: decode.consumed);
  }
}

class FilDecodedAddress {
  final FilNetwork network;
  final FilAddrType type;
  final List<int> bytes;
  final BigInt? namespace;
  final BuBytes? subaddr;
  final BigInt? id;
  FilDecodedAddress({
    required this.network,
    required this.type,
    this.namespace,
    List<int>? subaddr,
    this.id,
    required List<int> bytes,
  }) : bytes = bytes.asImmutableBytes,
       subaddr = subaddr?.asImmutableBytes;
}

class FilEncodedAddress {
  final FilNetwork network;
  final FilAddrType type;
  final String address;
  FilEncodedAddress({
    required this.network,
    required this.type,
    required this.address,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Internal utilities
// ─────────────────────────────────────────────────────────────────────────────

class FilAddrUtils {
  static String _getPrefix(FilNetwork network) => network.prefix;

  // Validate network prefix and return remaining string + detected network
  static ({FilNetwork network, FilAddrType type, String raw}) _validatePrefix(
    String addr,
  ) {
    if (addr.isEmpty) {
      throw CoreErrors.addressValidationFailed(reason: "Empty address");
    }
    if (addr.length > FilAddrConst.maxAddressStringLength || addr.length < 3) {
      throw CoreErrors.addressValidationFailed(
        reason: "Invalid address length",
      );
    }
    final network = FilNetwork.fromPrefix(addr[0]);
    final type = FilAddrType.fromValue(int.tryParse(addr[1]));
    return (network: network, type: type, raw: addr.substring(2));
  }

  // Checksum = blake2b-4([protocol, ...payload])
  static List<int> computeChecksum(List<int> payload, FilAddrType addrType) {
    final List<int> input = [addrType.value, ...payload];
    return QuickCrypto.blake2b32Hash(input);
  }

  // Validate checksum against payload
  static void _validateChecksum(
    List<int> payload,
    List<int> checksum,
    FilAddrType addrType,
  ) {
    final expected = computeChecksum(payload, addrType);
    if (!BytesUtils.bytesEqual(expected, checksum)) {
      throw CoreErrors.addressValidationFailed(
        reason: "Invalid address checksum.",
      );
    }
  }

  static String encodeMaskedEthereum(BigInt id) {
    return EthAddrUtils.addressBytesToChecksumAddress([
      0xff,
      ...List<int>.filled(11, 0),
      ...id.toU64BeBytes(),
    ]);
  }

  static FilDecodedAddress decodeId(String addr) {
    final p = _validatePrefix(addr);
    if (p.type != FilAddrType.id) {
      throw CoreErrors.addressValidationFailed(reason: "Invalid ID address");
    }
    final idStr = p.raw;
    final id = BigInt.tryParse(idStr);
    if (id == null || id.isNegative) {
      throw CoreErrors.addressValidationFailed(
        reason: "Invalid ID address payload",
      );
    }
    // Filecoin restricts IDs to < 2^63
    if (id > BinaryOps.maxInt64) {
      throw CoreErrors.addressValidationFailed(
        reason: "ID must be less than 2^63",
      );
    }
    return FilDecodedAddress(
      network: p.network,
      type: FilAddrType.id,
      bytes: _Uvarint.encode(id),
      id: id,
    );
  }

  static String encodeId(FilNetwork network, {List<int>? payload, BigInt? id}) {
    if ([id, payload].where((e) => e != null).length != 1) {
      throw CoreErrors.missingOrInvalidAddressArguments(
        reason: "Exactly one of id or payload must be provided.",
      );
    }
    if (payload != null) {
      final decoded = _Uvarint.decode(payload);
      if (decoded.length != payload.length) {
        throw CoreErrors.addressValidationFailed(
          reason: "ID payload contains extra bytes",
        );
      }
      id = decoded.value;
    }

    if (id == null || id > BinaryOps.maxInt64) {
      throw CoreErrors.addressValidationFailed(
        reason: "ID must be less than 2^63",
      );
    }
    return "${_getPrefix(network)}0$id";
  }

  // ── SECP256K1 / Actor / BLS (protocols 1, 2, 3) ──
  static FilDecodedAddress decodeHashAddr(
    String addr,
    FilAddrType addrType, {
    required int expectedPayloadLen,
  }) {
    try {
      final p = _validatePrefix(addr);
      if (addrType != p.type) {
        throw CoreErrors.addressValidationFailed(
          reason: "Invalid address type",
        );
      }

      final List<int> addrDecBytes = Base32Decoder.decode(
        p.raw,
        FilAddrConst.base32Alphabet,
      );

      if (addrDecBytes.length !=
          expectedPayloadLen + FilAddrConst.checksumHashLength) {
        throw CoreErrors.addressValidationFailed(
          reason: "Invalid address length",
        );
      }

      final payload = addrDecBytes.sublist(0, expectedPayloadLen);
      final checksum = addrDecBytes.sublist(expectedPayloadLen);

      _validateChecksum(payload, checksum, addrType);
      return FilDecodedAddress(
        network: p.network,
        type: p.type,
        bytes: payload,
      );
    } on BuError {
      throw CoreErrors.addressValidationFailed(reason: "Invalid address.");
    }
  }

  static String encodeHashAddr(
    List<int> payload,
    FilAddrType addrType,
    FilNetwork network, {
    required int expectedPayloadLen,
  }) {
    AddrDecUtils.validateAddressKeyBytesLength(payload, expectedPayloadLen);
    final checksum = computeChecksum(payload, addrType);
    final bytesWithChecksum = [...payload, ...checksum];
    final String b32Enc = Base32Encoder.encodeNoPaddingBytes(
      bytesWithChecksum,
      FilAddrConst.base32Alphabet,
    );
    return "${_getPrefix(network)}${addrType.value}$b32Enc";
  }

  // ── Delegated (protocol 4) ──
  static FilDecodedAddress decodeDelegated(String addr) {
    final p = _validatePrefix(addr);
    if (p.type != FilAddrType.delegated) {
      throw CoreErrors.addressValidationFailed(
        reason: "Invalid delegated address",
      );
    }

    final raw = p.raw;
    final index = raw.indexOf("f");
    if (index.isNegative) {
      throw CoreErrors.addressValidationFailed(
        reason: "Invalid delegated address format",
      );
    }

    final namespaceStr = raw.substring(0, index);
    final subaddrStr = raw.substring(index + 1);

    final namespace = BigInt.tryParse(namespaceStr);
    if (namespace == null || namespace.isNegative) {
      throw CoreErrors.addressValidationFailed(
        reason: "Invalid delegated namespace",
      );
    }
    if (namespace > BinaryOps.maxInt64) {
      throw CoreErrors.addressValidationFailed(
        reason: "Namespace must be less than 2^63",
      );
    }

    final subaddrcksm = Base32Decoder.decode(
      subaddrStr,
      FilAddrConst.base32Alphabet,
    );
    if (subaddrcksm.length < FilAddrConst.checksumHashLength) {
      throw CoreErrors.addressValidationFailed(
        reason: "Delegated address too short",
      );
    }

    final subaddr = subaddrcksm.sublist(
      0,
      subaddrcksm.length - FilAddrConst.checksumHashLength,
    );
    final checksum = subaddrcksm.sublist(
      subaddrcksm.length - FilAddrConst.checksumHashLength,
    );

    if (subaddr.length > FilAddrConst.maxSubaddressLen) {
      throw CoreErrors.addressValidationFailed(reason: "Subaddress too long");
    }

    final payload = [..._Uvarint.encode(namespace), ...subaddr];
    _validateChecksum(payload, checksum, FilAddrType.delegated);
    return FilDecodedAddress(
      network: p.network,
      type: FilAddrType.delegated,
      bytes: payload,
      namespace: namespace,
      subaddr: subaddr,
    );
  }

  static String encodeDelegated(
    List<int> payload,
    FilNetwork network, {
    BigInt? nameSpace,
  }) {
    List<int> subaddr;

    if (nameSpace == null) {
      final namespaceRes = _Uvarint.decode(payload);
      subaddr = payload.sublist(namespaceRes.length);
      nameSpace = namespaceRes.value;
    } else {
      subaddr = payload.clone();
      payload = [..._Uvarint.encode(nameSpace), ...subaddr];
    }
    if (subaddr.length > FilAddrConst.maxSubaddressLen) {
      throw CoreErrors.addressValidationFailed(reason: "Subaddress too long");
    }
    if (nameSpace > BinaryOps.maxInt64) {
      throw CoreErrors.addressValidationFailed(
        reason: "Namespace must be less than 2^63",
      );
    }

    final checksum = computeChecksum(payload, FilAddrType.delegated);
    final toEncode = [...subaddr, ...checksum];

    final b32 = Base32Encoder.encodeNoPaddingBytes(
      toEncode,
      FilAddrConst.base32Alphabet,
    );

    return "${_getPrefix(network)}4${nameSpace}f$b32";
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Decoders
// ═════════════════════════════════════════════════════════════════════════════

class FilIdAddrDecoder implements BlockchainAddressDecoder<BuBytes> {
  @override
  BuBytes decodeAddr(String addr, {FilNetwork? network}) {
    final decode = FilAddrUtils.decodeId(addr);
    if (network != null && network != decode.network) {
      throw CoreErrors.addressValidationFailed(
        reason: "Address network mismatch.",
        details: {"network": decode.network.name},
      );
    }
    return BuBytes(decode.bytes);
  }
}

class FilSecp256k1AddrDecoder implements BlockchainAddressDecoder<BuBytes> {
  @override
  BuBytes decodeAddr(String addr, {FilNetwork? network}) {
    final decode = FilAddrUtils.decodeHashAddr(
      addr,
      FilAddrType.secp256k1,
      expectedPayloadLen: FilAddrConst.payloadHashLength,
    );
    if (network != null && network != decode.network) {
      throw CoreErrors.addressValidationFailed(
        reason: "Address network mismatch.",
        details: {"network": decode.network.name},
      );
    }
    return BuBytes(decode.bytes);
  }
}

class FilActorAddrDecoder implements BlockchainAddressDecoder<BuBytes> {
  @override
  BuBytes decodeAddr(String addr, {FilNetwork? network}) {
    final decode = FilAddrUtils.decodeHashAddr(
      addr,
      FilAddrType.actor,
      expectedPayloadLen: FilAddrConst.payloadHashLength,
    );
    if (network != null && network != decode.network) {
      throw CoreErrors.addressValidationFailed(
        reason: "Address network mismatch.",
        details: {"network": decode.network.name},
      );
    }
    return BuBytes(decode.bytes);
  }
}

class FilBlsAddrDecoder implements BlockchainAddressDecoder<BuBytes> {
  @override
  BuBytes decodeAddr(String addr, {FilNetwork? network}) {
    final decode = FilAddrUtils.decodeHashAddr(
      addr,
      FilAddrType.bls,
      expectedPayloadLen: FilAddrConst.blsPublicKeyBytes,
    );
    if (network != null && network != decode.network) {
      throw CoreErrors.addressValidationFailed(
        reason: "Address network mismatch.",
        details: {"network": decode.network.name},
      );
    }
    return BuBytes(decode.bytes);
  }
}

class FilDelegatedAddrDecoder implements BlockchainAddressDecoder<BuBytes> {
  @override
  BuBytes decodeAddr(String addr, {FilNetwork? network}) {
    final decode = FilAddrUtils.decodeDelegated(addr);
    if (network != null && network != decode.network) {
      throw CoreErrors.addressValidationFailed(
        reason: "Address network mismatch.",
        details: {"network": decode.network.name},
      );
    }
    return BuBytes(decode.bytes);
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Encoders
// ═════════════════════════════════════════════════════════════════════════════

class FilIdAddrEncoder implements BlockchainAddressEncoder {
  const FilIdAddrEncoder();

  String encode(BigInt id, {FilNetwork network = FilNetwork.mainnet}) {
    return FilAddrUtils.encodeId(network, id: id);
  }

  @override
  String encodeKey(
    List<int> payload, {
    FilNetwork network = FilNetwork.mainnet,
  }) {
    return FilAddrUtils.encodeId(network, payload: payload);
  }
}

class FilSecp256k1AddrEncoder implements BlockchainAddressEncoder {
  const FilSecp256k1AddrEncoder();
  String encode(List<int> keyBytes, {FilNetwork network = FilNetwork.mainnet}) {
    AddrDecUtils.validateBytesLength(keyBytes, FilAddrConst.payloadHashLength);
    return FilAddrUtils.encodeHashAddr(
      keyBytes,
      FilAddrType.secp256k1,
      network,
      expectedPayloadLen: FilAddrConst.payloadHashLength,
    );
  }

  @override
  String encodeKey(
    List<int> pubKey, {
    FilNetwork network = FilNetwork.mainnet,
  }) {
    final pubkey = AddrKeyValidator.validateAndGetSecp256k1Key(pubKey);
    final tobytes = pubkey.toBytes(mode: CryptoKeyEncoding.uncompressed);
    final hash = QuickCrypto.blake2b160Hash(tobytes);
    return FilAddrUtils.encodeHashAddr(
      hash,
      FilAddrType.secp256k1,
      network,
      expectedPayloadLen: FilAddrConst.payloadHashLength,
    );
  }
}

class FilActorAddrEncoder implements BlockchainAddressEncoder {
  const FilActorAddrEncoder();
  String encode(List<int> data, {FilNetwork network = FilNetwork.mainnet}) {
    return FilAddrUtils.encodeHashAddr(
      data,
      FilAddrType.actor,
      network,
      expectedPayloadLen: FilAddrConst.payloadHashLength,
    );
  }

  /// Encodes an actor address from arbitrary data (the data is hashed with blake2b-160).
  @override
  String encodeKey(List<int> data, {FilNetwork network = FilNetwork.mainnet}) {
    final hash = QuickCrypto.blake2b160Hash(data);
    return FilAddrUtils.encodeHashAddr(
      hash,
      FilAddrType.actor,
      network,
      expectedPayloadLen: FilAddrConst.payloadHashLength,
    );
  }
}

class FilBlsAddrEncoder implements BlockchainAddressEncoder {
  const FilBlsAddrEncoder();
  String encode(List<int> keyBytes, {FilNetwork network = FilNetwork.mainnet}) {
    return FilAddrUtils.encodeHashAddr(
      keyBytes,
      FilAddrType.bls,
      network,
      expectedPayloadLen: FilAddrConst.blsPublicKeyBytes,
    );
  }

  @override
  String encodeKey(
    List<int> pubKey, {
    FilNetwork network = FilNetwork.mainnet,
  }) {
    final key = AddrKeyValidator.validateAndGetBlsG1PublicKey(pubKey);
    return FilAddrUtils.encodeHashAddr(
      key.toBytes(mode: CryptoKeyEncoding.base),
      FilAddrType.bls,
      network,
      expectedPayloadLen: FilAddrConst.blsPublicKeyBytes,
    );
  }
}

class FilDelegatedAddrEncoder implements BlockchainAddressEncoder {
  const FilDelegatedAddrEncoder();

  String encode(
    List<int> subaddr, {
    FilNetwork network = FilNetwork.mainnet,
    BigInt? nameSpace,
  }) {
    final n = AddrKeyValidator.getAddrArg<BigInt>(nameSpace, "nameSpace");
    return FilAddrUtils.encodeDelegated(subaddr, network, nameSpace: n);
  }

  /// [pubKey] here is the full payload: uvarint(namespace) + subaddress bytes.
  @override
  String encodeKey(
    List<int> payload, {
    FilNetwork network = FilNetwork.mainnet,
  }) {
    return FilAddrUtils.encodeDelegated(payload, network);
  }
}

class FilAddrEncoder implements BlockchainAddressEncoder {
  const FilAddrEncoder();

  FilEncodedAddress encode(
    List<int> keyBytes, {
    FilNetwork network = FilNetwork.mainnet,
    FilAddrType? type,
  }) {
    if (keyBytes.isEmpty) {
      throw CoreErrors.addressKeyValidationFailed(
        reason: "Invalid key bytes length.",
      );
    }
    final t = FilAddrType.fromValue(keyBytes[0]);
    if (type != null && t != type) {
      throw CoreErrors.addressValidationFailed(
        reason: "Address type mismatch.",
        details: {"type": t.name},
      );
    }
    keyBytes = keyBytes.sublist(1);
    final addr = switch (t) {
      FilAddrType.id => FilIdAddrEncoder().encodeKey(
        keyBytes,
        network: network,
      ),
      FilAddrType.secp256k1 => FilSecp256k1AddrEncoder().encode(
        keyBytes,
        network: network,
      ),
      FilAddrType.actor => FilActorAddrEncoder().encode(
        keyBytes,
        network: network,
      ),
      FilAddrType.bls => FilBlsAddrEncoder().encode(keyBytes, network: network),
      FilAddrType.delegated => FilDelegatedAddrEncoder().encode(
        keyBytes,
        network: network,
      ),
    };
    return FilEncodedAddress(network: network, type: t, address: addr);
  }

  /// [pubKey] here is the full payload: uvarint(namespace) + subaddress bytes.
  @override
  String encodeKey(
    List<int> keyBytes, {
    FilNetwork network = FilNetwork.mainnet,
    FilAddrType? type,
  }) {
    final t = AddrKeyValidator.getAddrArg<FilAddrType>(type, "type");
    return switch (t) {
      FilAddrType.id => FilIdAddrEncoder().encodeKey(
        keyBytes,
        network: network,
      ),
      FilAddrType.secp256k1 => FilSecp256k1AddrEncoder().encodeKey(
        keyBytes,
        network: network,
      ),
      FilAddrType.actor => FilActorAddrEncoder().encodeKey(
        keyBytes,
        network: network,
      ),
      FilAddrType.bls => FilBlsAddrEncoder().encodeKey(
        keyBytes,
        network: network,
      ),
      FilAddrType.delegated => FilDelegatedAddrEncoder().encodeKey(
        keyBytes,
        network: network,
      ),
    };
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Generic auto-detect decoder (optional convenience)
// ═════════════════════════════════════════════════════════════════════════════

class FilAddrDecoder implements BlockchainAddressDecoder<BuBytes> {
  FilDecodedAddress decode(String addr, {FilNetwork? network}) {
    if (addr.isEmpty) {
      throw CoreErrors.addressValidationFailed(reason: "Empty address.");
    }
    if (addr.length < 2) {
      throw CoreErrors.addressValidationFailed(reason: "Address too short");
    }
    final n = FilNetwork.fromPrefix(addr[0]);
    final type = FilAddrType.fromValue(int.tryParse(addr[1]));
    if (network != null && network != n) {
      throw CoreErrors.addressValidationFailed(
        reason: "Address network mismatch.",
        details: {"network": n.name},
      );
    }
    return FilDecodedAddress(
      network: n,
      type: type,
      bytes: switch (type) {
        FilAddrType.id => FilIdAddrDecoder().decodeAddr(addr),
        FilAddrType.secp256k1 => FilSecp256k1AddrDecoder().decodeAddr(addr),
        FilAddrType.actor => FilActorAddrDecoder().decodeAddr(addr),
        FilAddrType.bls => FilBlsAddrDecoder().decodeAddr(addr),
        FilAddrType.delegated => FilDelegatedAddrDecoder().decodeAddr(addr),
      },
    );
  }

  @override
  BuBytes decodeAddr(String addr, {FilNetwork? network}) {
    return BuBytes(decode(addr).bytes);
  }
}
