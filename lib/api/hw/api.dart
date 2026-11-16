import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Hardware-wallet codec API (Ledger / Trezor / BitBox02 / airgap QR).
///
/// Device and coin ids are the connector constants [BuHwDevice] and
/// [BuHwCoin] (must match Rust `DeviceKind::ALL` / `WELL_KNOWN_COINS` order).
/// Paths cross the boundary as `<u32 LE>` bytes — see [u32sToLeBytes].
///
/// Backends: [DartHwApi] (pure Dart — unimplemented, throws
/// [UnimplementedError]) and [NativeHwApi] (Rust `hw` core via [BuHwApi]).
/// Transport (USB/BLE/NFC) is never in this API — see [BuHwTransport].
abstract interface class HwApi {
  /// True when the device family can derive the coin's curve.
  bool supportsCoin({required int device, required int coin});

  /// True for QR/SD-only devices (Passport / Keystone / Coldcard-QR / Jade-QR).
  bool isAirgap({required int device});

  /// `"m/44'/0'/0'/0/0"` → `<u32 LE>` bytes for the calls below.
  BuBytes parsePath(String path);

  /// Throws on bad shape (wrong purpose/coin, soft index on ed25519, …).
  void validatePath({
    required int device,
    required int coin,
    required BuBytes pathU32,
  });

  /// USB request bytes (Ledger APDU / Trezor `?##` frame). Airgap → throws.
  BuBytes getAddressRequest({
    required int device,
    required int coin,
    required BuBytes pathU32,
  });

  /// USB response bytes → pubkey/address bytes.
  BuBytes parseAddressResponse({
    required int device,
    required BuBytes response,
  });

  /// Ledger v2 `GET_MASTER_FINGERPRINT` request (no input, no UI).
  BuBytes ledgerFingerprint();

  /// 4-byte root fingerprint from `DATA || 0x9000`.
  BuBytes ledgerFingerprintParse({required BuBytes response});

  /// Sign-request bytes (Trezor `SignMessage` frame; Ledger errors —
  /// app-bitcoin v2 signs via the PSBT wallet flow).
  BuBytes signRequest({
    required int device,
    required int coin,
    required BuBytes pathU32,
    required BuBytes payload,
  });

  /// Sign response bytes → signature bytes.
  BuBytes parseSignResponse({
    required int device,
    required BuBytes response,
  });

  /// Build request → [transport.exchange] → parse. USB devices only.
  Future<BuBytes> executeSign({
    required int device,
    required int coin,
    required BuBytes pathU32,
    required BuBytes payload,
    required BuHwTransport transport,
  });

  /// Open a Trezor `SignTx` session (inputs/outputs counts).
  BuBytes signTxStart({
    required int device,
    required int coin,
    required int inputsCount,
    required int outputsCount,
  });

  /// One `TxRequest` → `(requestType, requestIndex)` (-1 = absent).
  (int, int) parseTxRequest({
    required int device,
    required BuBytes response,
  });

  /// `TXFINISHED` signature bytes.
  BuBytes txRequestSignature({
    required int device,
    required BuBytes response,
  });

  /// `TXFINISHED` consensus-serialized transaction.
  BuBytes txRequestSerialized({
    required int device,
    required BuBytes response,
  });

  /// `TxRequest` prev-tx hash (32 bytes).
  BuBytes txRequestTxHash({
    required int device,
    required BuBytes response,
  });

  /// `TxAck` answering `TXMETA`.
  BuBytes txAckMeta({
    required int version,
    required int lockTime,
    required int inputsCount,
    required int outputsCount,
  });

  /// `TxAck` answering `TXINPUT`.
  BuBytes txAckInput({
    required BuBytes prevHash32,
    required int prevIndex,
    required BuBytes pathU32,
    required int amountSat,
    required BuBytes scriptSig,
    required int scriptType,
  });

  /// `TxAck` answering `TXOUTPUT` (pay to address).
  BuBytes txAckOutput({
    required String address,
    required int amountSat,
    required int scriptType,
  });

  /// `TxAck` answering `TXOUTPUT` (change back to path).
  BuBytes txAckChange({
    required BuBytes pathU32,
    required int amountSat,
    required int scriptType,
  });

  /// `TxAck` answering `TXOUTPUT` of a PREVIOUS transaction.
  BuBytes txAckBinOutput({
    required BuBytes scriptPubKey,
    required int amountSat,
  });

  /// BitBox02: open initiator session (fails if one is already open).
  void bitboxHsNew({
    required BuBytes staticPriv32,
    required BuBytes ephemeralPriv32,
  });

  /// BitBox02: handshake m1 (32 B).
  BuBytes bitboxHsM1();

  /// BitBox02: ingest handshake m2 (96 B).
  void bitboxHsM2({required BuBytes m2});

  /// BitBox02: handshake m3 (64 B).
  BuBytes bitboxHsM3();

  /// BitBox02: split into transport keys.
  void bitboxHsSplit();

  /// BitBox02: encrypt one post-handshake message.
  BuBytes bitboxEncrypt({required BuBytes plaintext});

  /// BitBox02: decrypt one post-handshake message.
  BuBytes bitboxDecrypt({required BuBytes ciphertext});

  /// BitBox02: handshake hash (pairing-code source).
  BuBytes bitboxHsHash();

  /// BitBox02: close + wipe session (idempotent).
  void bitboxFree();

  /// BitBox02: `Request{btc_pub}` bytes.
  BuBytes bitboxBtcPubRequest({
    required int coin,
    required BuBytes pathU32,
    required int xpubType,
    required bool display,
  });

  /// BitBox02: `Response` → xpub string.
  String bitboxPubParse({required BuBytes response});

  /// BitBox02: `Request{btc_sign_init}` bytes.
  BuBytes bitboxSignInit({
    required int coin,
    required BuBytes pathU32,
    required int simpleType,
    required int version,
    required int inputsCount,
    required int outputsCount,
    required int locktime,
  });

  /// BitBox02: `sign_next` → `(requestType, index)` (-1 = absent).
  (int, int) bitboxSignNextParse({required BuBytes response});

  /// BitBox02: `DONE` signature (64 B R||S).
  BuBytes bitboxSignNextSignature({required BuBytes response});

  /// BitBox02: `prev_index` for PREVTX_* (-1 = absent).
  int bitboxSignNextPrevIndex({required BuBytes response});

  /// BitBox02: `Request{btc_sign_input}` bytes.
  BuBytes bitboxSignInput({
    required BuBytes prevHash32,
    required int prevIndex,
    required int amountSat,
    required int sequence,
    required BuBytes pathU32,
    required int scriptConfigIndex,
  });

  /// BitBox02: `Request{btc_sign_output}` bytes (external address).
  BuBytes bitboxSignOutput({
    required int outputType,
    required int amountSat,
    required BuBytes payload,
  });

  /// BitBox02: `Request{btc_sign_output}` bytes (change).
  BuBytes bitboxSignChange({
    required BuBytes pathU32,
    required int amountSat,
    required int scriptConfigIndex,
  });

  /// BitBox02: `Request{btc: BTCRequest{prevtx_init}}` bytes.
  BuBytes bitboxSignPrevtxInit({
    required int version,
    required int inputsCount,
    required int outputsCount,
    required int locktime,
  });

  /// BitBox02: `Request{btc: BTCRequest{prevtx_input}}` bytes.
  BuBytes bitboxSignPrevtxInput({
    required BuBytes prevHash32,
    required int prevIndex,
    required BuBytes scriptSig,
    required int sequence,
  });

  /// BitBox02: `Request{btc: BTCRequest{prevtx_output}}` bytes.
  BuBytes bitboxSignPrevtxOutput({
    required int amountSat,
    required BuBytes script,
  });

  /// Trezor `IdentityType` bytes (`proto` selects ssh/gpg/…).
  BuBytes identityEncode({
    required String proto,
    String user = '',
    String host = '',
    String port = '',
    String path = '',
    int index = 0,
  });

  /// Trezor framed `SignIdentity` (`curve`: 0 omit, 1 secp256k1, 2 nist256p1).
  BuBytes signIdentityRequest({
    required BuBytes identity,
    required BuBytes hidden,
    String visual = '',
    int curve = 0,
  });

  /// `SignedIdentity.address` string.
  String signedIdentityAddress({required BuBytes response});

  /// `SignedIdentity.public_key` bytes.
  BuBytes signedIdentityPubkey({required BuBytes response});

  /// `SignedIdentity.signature` bytes.
  BuBytes signedIdentitySignature({required BuBytes response});

  /// Airgap: string to show as QR (`ur:bytes/...`). USB → throws.
  String qrRequest({
    required int device,
    required int coin,
    required BuBytes pathU32,
  });

  /// Airgap: scanned single-part QR → payload bytes.
  /// (Multipart: assemble with [BuUrAssembler] first.)
  BuBytes qrParse({required int device, required String qr});

  /// PSBT bytes → `(inputCount, outputCount)`.
  (int, int) psbtCounts({required BuBytes psbt});

  /// `ur:<type>/<body>` (single-part envelope).
  String urEncode({required String type, required BuBytes payload});

  /// UR shard → payload bytes.
  BuBytes urDecodePayload(String ur);

  /// UR shard → type string (e.g. `bytes`, `crypto-psbt`).
  String urDecodeType(String ur);

  /// Build request → [transport.exchange] → parse. USB devices only.
  Future<BuBytes> executeGetAddress({
    required int device,
    required int coin,
    required BuBytes pathU32,
    required BuHwTransport transport,
  });

  /// Chunk [payload] into concatenated 64-byte HID reports (real USB/WebHID).
  BuBytes hidFrame({
    required BuBytes payload,
    int channel = BuHwHid.channelDefault,
    int tag = BuHwHid.tagApdu,
  });

  /// Reassemble concatenated 64-byte [reports] (length % 64 == 0).
  BuBytes hidUnframe({
    required BuBytes reports,
    int channel = BuHwHid.channelDefault,
    int tag = BuHwHid.tagApdu,
  });
}
