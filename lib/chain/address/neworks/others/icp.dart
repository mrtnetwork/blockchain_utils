import 'package:blockchain_utils/encoding/base32/src/base32.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/chain/address/utils/addr_key_validator.dart';
import 'package:blockchain_utils/chain/address/types/decoder.dart';
import 'package:blockchain_utils/chain/address/types/encoder.dart';
import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/crypto/crypto/checksum/crc32/crc32.dart';
import 'package:blockchain_utils/crypto/crypto/keys/ed25519/ed25519.dart';
import 'package:blockchain_utils/crypto/crypto/keys/secp256r1/secp256r1.dart';
import 'package:blockchain_utils/crypto/crypto/keys/secp256k1/secp256k1.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/binary/src/utils.dart';
import 'package:blockchain_utils/utils/string/string.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

enum ICPAddressType {
  /// Textual Principal (CRC32 + Base32 + dashes).
  /// Example: `ryjl3-tyaaa-aaaaa-aaaba-cai`
  principal(0),

  /// Classic ICP Ledger Account Identifier (32 bytes → 64 hex chars).
  /// Example: `d3e13d4777e22367532053190b6c6ccf57444a61337e996242b1abfb52cf92c8`
  accountIdentifier(1);

  final int value;
  const ICPAddressType(this.value);

  static ICPAddressType fromValue(int? value) => values.firstWhere(
    (e) => e.value == value,
    orElse:
        () =>
            throw CoreErrors.addressValidationFailed(
              reason: "Invalid ICP address type.",
              details: {"got": value?.toString()},
            ),
  );
}

/// Result of decoding an ICP address.
class ICPDecodedAddress {
  final ICPAddressType type;

  /// For [ICPAddressType.principal] → raw principal bytes (0–29).
  /// For [ICPAddressType.accountIdentifier] → 32-byte account id.
  final List<int> bytes;

  const ICPDecodedAddress({required this.type, required this.bytes});
}

/// Result of encoding an ICP address (optional helper).
class ICPEncodedAddress {
  final ICPAddressType type;

  final String address;

  const ICPEncodedAddress({required this.type, required this.address});
}

/// Constants related to Internet Computer addresses.
class IcpAddrConst {
  // ── Principal ──────────────────────────────────────────────────────────
  static const int maxRawByteLen = 29;
  static const int crcByteLen = 4;
  static const int maxTextualLen = 63;
  static const int minTextualLen = 7;

  // ── Classic Account Identifier ─────────────────────────────────────────
  static const int accountIdByteLen = 32; // 4 (CRC) + 28 (SHA-224)
  static const int accountIdHashLen = 28; // SHA-224
  static const int subaccountByteLen = 32;

  /// Domain separator used by the ICP ledger.
  /// `\x0A` + "account-id"
  static final List<int> accountIdDomain = [
    0x0A,
    ...StringUtils.encode('account-id'),
  ];

  static const int selfAuthenticatedTag = 0x02;
}

class ICPAddrUtils {
  // 3. Self-authenticating principal = SHA-224(DER) ‖ 0x02
  static BuBytes selfAuthenticated(List<int> derBytes) {
    final BuBytes hash = QuickCrypto.sha224Hash(derBytes);
    return BuBytes([...hash, IcpAddrConst.selfAuthenticatedTag]);
  }
}

/// Decodes an ICP address.
///
/// Automatically detects whether the input is a Principal or a classic
/// Account Identifier.
class IcpAddrDecoder implements BlockchainAddressDecoder<ICPDecodedAddress> {
  @override
  ICPDecodedAddress decodeAddr(String addr) {
    final String trimmed = addr.trim();

    // 1. Classic Account Identifier (64 hex characters)
    if (_isAccountIdentifier(trimmed)) {
      return _decodeAccountIdentifier(trimmed);
    }

    // 2. Principal (Base32 + dashes)
    return _decodePrincipal(trimmed);
  }

  // ---------------------------------------------------------------------------
  // Principal
  // ---------------------------------------------------------------------------

  ICPDecodedAddress _decodePrincipal(String addr) {
    final String normalized = addr.toLowerCase();
    final String noDashes = normalized.replaceAll('-', '');

    if (normalized.length > IcpAddrConst.maxTextualLen ||
        normalized.length < IcpAddrConst.minTextualLen ||
        !RegExp(r'^[a-z2-7]+$').hasMatch(noDashes)) {
      throw CoreErrors.addressValidationFailed(
        details: {'address': addr},
      );
    }
    late final List<int> decoded;
    try {
      decoded = Base32Decoder.decode(noDashes.toUpperCase());
    } catch (_) {
      throw CoreErrors.addressValidationFailed(
        details: {'address': addr},
      );
    }
    if (decoded.length < IcpAddrConst.crcByteLen) {
      throw CoreErrors.addressValidationFailed(
        details: {'address': addr},
      );
    }

    final List<int> checksum = decoded.sublist(0, IcpAddrConst.crcByteLen);
    final List<int> raw = decoded.sublist(IcpAddrConst.crcByteLen);

    if (raw.length > IcpAddrConst.maxRawByteLen) {
      throw CoreErrors.addressValidationFailed(
        reason:
            'Raw principal longer than ${IcpAddrConst.maxRawByteLen} bytes.',
        details: {'address': addr},
      );
    }

    final List<int> expected = Crc32().checksum(raw);
    if (!BytesUtils.bytesEqual(checksum, expected)) {
      throw CoreErrors.addressValidationFailed(
        reason: 'Invalid principal CRC-32 checksum.',
        details: {'address': addr},
      );
    }

    return ICPDecodedAddress(type: ICPAddressType.principal, bytes: raw);
  }

  // ---------------------------------------------------------------------------
  // Classic Account Identifier
  // ---------------------------------------------------------------------------

  bool _isAccountIdentifier(String addr) {
    return StringUtils.isHexBytes(
      addr,
      lengthInBytes: IcpAddrConst.accountIdByteLen,
    );
  }

  ICPDecodedAddress _decodeAccountIdentifier(String addr) {
    late final List<int> bytes;
    try {
      bytes = BytesUtils.fromHexString(addr);
    } catch (_) {
      throw CoreErrors.addressValidationFailed(
        details: {'address': addr},
      );
    }

    if (bytes.length != IcpAddrConst.accountIdByteLen) {
      throw CoreErrors.addressValidationFailed(
        reason: 'Account Identifier must be 32 bytes.',
        details: {'address': addr},
      );
    }

    final List<int> checksum = bytes.sublist(0, IcpAddrConst.crcByteLen);
    final List<int> hash = bytes.sublist(IcpAddrConst.crcByteLen);

    final List<int> expected = Crc32().checksum(hash);
    if (!BytesUtils.bytesEqual(checksum, expected)) {
      throw CoreErrors.addressValidationFailed(
        reason: 'Invalid Account Identifier CRC-32 checksum.',
        details: {'address': addr},
      );
    }

    return ICPDecodedAddress(
      type: ICPAddressType.accountIdentifier,
      bytes: bytes, // full 32 bytes (CRC + hash)
    );
  }
}

/// Encodes an ICP address.
class IcpAddrEncoder implements BlockchainAddressEncoder {
  @override
  String encodeKey(
    List<int> publicKey, {
    ICPAddressType addrType = ICPAddressType.principal,
    List<int>? subaccount,
    CryptoKeyType? curveType,
  }) {
    final CryptoKeyType type = AddrKeyValidator.getConfigArg(
      curveType,
      'curveType',
    );
    // 1. Validate & normalize the public key
    final pubkey = switch (type) {
      CryptoKeyType.secp256k1 => AddrKeyValidator.validateAndGetSecp256k1Key(
        publicKey,
      ),
      CryptoKeyType.ed25519 => AddrKeyValidator.validateAndGetEd25519PubKey(
        publicKey,
      ),
      CryptoKeyType.ed25519Kholaw =>
        AddrKeyValidator.validateAndGetEd25519PubKey(
          publicKey,
          type: CryptoKeyType.ed25519Kholaw,
        ),
      CryptoKeyType.nist256p1 => AddrKeyValidator.validateAndGetNist256p1Key(
        publicKey,
      ),
      _ =>
        throw CoreErrors.missingOrInvalidAddressArguments(
          reason: "Unsupported curve type.",
        ),
    };

    // 2. DER-encode (required by the ICP self-authenticating principal formula)
    final BuBytes derBytes = switch (pubkey) {
      Secp256k1PublicKey secp => secp.toDer(
        pubKeyMode: CryptoKeyEncoding.uncompressed,
      ),
      Secp256r1PublicKey secp => secp.toDer(
        pubKeyMode: CryptoKeyEncoding.uncompressed,
      ),
      ED25519KholawPublicKey kh => kh.toDer(),
      ED25519PublicKey ed => ed.toDer(),
      _ => throw CoreErrors.addressKeyValidationFailed(),
    };

    final BuBytes principalBytes = ICPAddrUtils.selfAuthenticated(derBytes);

    // 4. Encode according to requested type
    final addr = switch (addrType) {
      ICPAddressType.principal => _encodePrincipal(principalBytes),
      ICPAddressType.accountIdentifier => _encodeAccountIdentifier(
        principalBytes,
        subaccount,
      ),
    };
    return addr.address;
  }

  // Convenience wrapper that returns the typed result.
  ICPEncodedAddress encode(
    List<int> keyBytes, {
    ICPAddressType addrType = ICPAddressType.principal,
    List<int>? subaccount,
  }) {
    return switch (addrType) {
      ICPAddressType.principal => _encodePrincipal(keyBytes),
      ICPAddressType.accountIdentifier => _encodeAccountIdentifier(
        keyBytes,
        subaccount,
      ),
    };
  }
  // ---------------------------------------------------------------------------
  // Principal
  // ---------------------------------------------------------------------------

  ICPEncodedAddress _encodePrincipal(List<int> keyBytes) {
    final BuBytes raw = keyBytes.asImmutableBytes;

    if (raw.length > IcpAddrConst.maxRawByteLen) {
      throw CoreErrors.addressBytesValidationFailed(
        reason: 'Invalid principal length.',
        details: {
          'expected_max': IcpAddrConst.maxRawByteLen.toString(),
          'length': raw.length.toString(),
        },
      );
    }

    final BuBytes checksum = Crc32().checksum(raw);
    final List<int> payload = [...checksum, ...raw];

    String b32 = Base32Encoder.encodeNoPaddingBytes(payload).toLowerCase();
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < b32.length; i++) {
      if (i > 0 && i % 5 == 0) buffer.write('-');
      buffer.write(b32[i]);
    }
    return ICPEncodedAddress(
      type: ICPAddressType.principal,
      address: buffer.toString(),
    );
  }

  // ---------------------------------------------------------------------------
  // Classic Account Identifier
  // ---------------------------------------------------------------------------

  ICPEncodedAddress _encodeAccountIdentifier(
    List<int> principalBytes, [
    List<int>? subaccount,
  ]) {
    final BuBytes principal = principalBytes.asImmutableBytes;

    if (principal.length > IcpAddrConst.maxRawByteLen) {
      throw CoreErrors.addressBytesValidationFailed(
        reason: 'Invalid principal length for Account Identifier.',
        details: {
          'expected_max': IcpAddrConst.maxRawByteLen.toString(),
          'length': principal.length.toString(),
        },
      );
    }

    // Default subaccount = 32 zero bytes
    final List<int> sub =
        (subaccount == null || subaccount.isEmpty)
            ? List<int>.filled(IcpAddrConst.subaccountByteLen, 0)
            : subaccount.asImmutableBytes;

    if (sub.length != IcpAddrConst.subaccountByteLen) {
      throw CoreErrors.addressBytesValidationFailed(
        reason: 'Subaccount must be exactly 32 bytes.',
        details: {'length': sub.length.toString()},
      );
    }

    // h = SHA-224( domain ‖ principal ‖ subaccount )
    final List<int> preimage = [
      ...IcpAddrConst.accountIdDomain,
      ...principal,
      ...sub,
    ];
    final BuBytes hash = QuickCrypto.sha224Hash(preimage); // 28 bytes

    // account_id = CRC32(h) ‖ h
    final BuBytes checksum = Crc32().checksum(hash);
    final List<int> accountId = [...checksum, ...hash]; // 32 bytes

    return ICPEncodedAddress(
      type: ICPAddressType.accountIdentifier,
      address: BytesUtils.toHexString(accountId),
    );
  }
}
