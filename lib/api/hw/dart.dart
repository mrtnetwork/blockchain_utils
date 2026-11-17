import 'package:blockchain_utils/api/hw/api.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// [HwApi] pure-Dart backend.
///
/// Every method throws [BuError]: the pure-Dart package has no USB
/// transport and ships no HW message codecs yet. Use [NativeHwApi] via
/// `blockchainUtils.setRustApi()` (Rust `hw` core) instead.
class DartHwApi implements HwApi {
  /// Creates a pure-Dart hardware-wallet backend; every method throws [BuError].
  const DartHwApi();

  static BuError _un(String op) => BuError(
    DefaultErrorType.unsupported,
    'DartHwApi.$op: pure-Dart backend has no hardware-wallet support; '
    'use NativeHwApi via blockchainUtils.setRustApi().',
  );

  /// Offline curve-table check whether [device] supports [coin]; pure-Dart stub always throws [BuError].
  @override
  bool supportsCoin({required int device, required int coin}) {
    throw _un('supportsCoin');
  }

  /// Returns whether [device] is QR/SD-only; pure-Dart stub always throws [BuError].
  @override
  bool isAirgap({required int device}) {
    throw _un('isAirgap');
  }

  /// Parses BIP path string [path] to `<u32 LE>` bytes; pure-Dart stub always throws [BuError].
  @override
  BuBytes parsePath(String path) {
    throw _un('parsePath');
  }

  /// Validates [pathU32] shape for [device] and [coin]; pure-Dart stub always throws [BuError].
  @override
  void validatePath({
    required int device,
    required int coin,
    required BuBytes pathU32,
  }) {
    throw _un('validatePath');
  }

  /// Builds USB request bytes for [device], [coin] and [pathU32]; pure-Dart stub always throws [BuError].
  @override
  BuBytes getAddressRequest({
    required int device,
    required int coin,
    required BuBytes pathU32,
  }) {
    throw _un('getAddressRequest');
  }

  /// Parses USB [response] bytes for [device] to pubkey/address bytes; pure-Dart stub always throws [BuError].
  @override
  BuBytes parseAddressResponse({
    required int device,
    required BuBytes response,
  }) {
    throw _un('parseAddressResponse');
  }

  /// Builds Ledger v2 `GET_MASTER_FINGERPRINT` request; pure-Dart stub always throws [BuError].
  @override
  BuBytes ledgerFingerprint() {
    throw _un('ledgerFingerprint');
  }

  /// Parses 4-byte fingerprint; pure-Dart stub always throws [BuError].
  @override
  BuBytes ledgerFingerprintParse({required BuBytes response}) {
    throw _un('ledgerFingerprintParse');
  }

  /// Builds sign-request bytes; pure-Dart stub always throws [BuError].
  @override
  BuBytes signRequest({
    required int device,
    required int coin,
    required BuBytes pathU32,
    required BuBytes payload,
  }) {
    throw _un('signRequest');
  }

  /// Parses sign response; pure-Dart stub always throws [BuError].
  @override
  BuBytes parseSignResponse({required int device, required BuBytes response}) {
    throw _un('parseSignResponse');
  }

  /// Builds request then exchanges via [transport]; pure-Dart stub always throws [BuError].
  @override
  Future<BuBytes> executeSign({
    required int device,
    required int coin,
    required BuBytes pathU32,
    required BuBytes payload,
    required BuHwTransport transport,
  }) {
    throw _un('executeSign');
  }

  /// Opens a Trezor `SignTx` session; pure-Dart stub always throws [BuError].
  @override
  BuBytes signTxStart({
    required int device,
    required int coin,
    required int inputsCount,
    required int outputsCount,
  }) {
    throw _un('signTxStart');
  }

  /// Parses one `TxRequest`; pure-Dart stub always throws [BuError].
  @override
  (int, int) parseTxRequest({required int device, required BuBytes response}) {
    throw _un('parseTxRequest');
  }

  /// `TXFINISHED` signature bytes; pure-Dart stub always throws [BuError].
  @override
  BuBytes txRequestSignature({required int device, required BuBytes response}) {
    throw _un('txRequestSignature');
  }

  /// `TXFINISHED` serialized transaction; pure-Dart stub always throws [BuError].
  @override
  BuBytes txRequestSerialized({
    required int device,
    required BuBytes response,
  }) {
    throw _un('txRequestSerialized');
  }

  /// `TxRequest` prev-tx hash; pure-Dart stub always throws [BuError].
  @override
  BuBytes txRequestTxHash({required int device, required BuBytes response}) {
    throw _un('txRequestTxHash');
  }

  /// `TxAck` for `TXMETA`; pure-Dart stub always throws [BuError].
  @override
  BuBytes txAckMeta({
    required int version,
    required int lockTime,
    required int inputsCount,
    required int outputsCount,
  }) {
    throw _un('txAckMeta');
  }

  /// `TxAck` for `TXINPUT`; pure-Dart stub always throws [BuError].
  @override
  BuBytes txAckInput({
    required BuBytes prevHash32,
    required int prevIndex,
    required BuBytes pathU32,
    required int amountSat,
    required BuBytes scriptSig,
    required int scriptType,
  }) {
    throw _un('txAckInput');
  }

  /// `TxAck` for `TXOUTPUT` (address); pure-Dart stub always throws [BuError].
  @override
  BuBytes txAckOutput({
    required String address,
    required int amountSat,
    required int scriptType,
  }) {
    throw _un('txAckOutput');
  }

  /// `TxAck` for `TXOUTPUT` (change); pure-Dart stub always throws [BuError].
  @override
  BuBytes txAckChange({
    required BuBytes pathU32,
    required int amountSat,
    required int scriptType,
  }) {
    throw _un('txAckChange');
  }

  /// `TxAck` for previous-transaction `TXOUTPUT`; pure-Dart stub always throws [BuError].
  @override
  BuBytes txAckBinOutput({
    required BuBytes scriptPubKey,
    required int amountSat,
  }) {
    throw _un('txAckBinOutput');
  }

  /// BitBox02: opens initiator session; pure-Dart stub always throws [BuError].
  @override
  void bitboxHsNew({
    required BuBytes staticPriv32,
    required BuBytes ephemeralPriv32,
  }) {
    throw _un('bitboxHsNew');
  }

  /// BitBox02: handshake m1; pure-Dart stub always throws [BuError].
  @override
  BuBytes bitboxHsM1() {
    throw _un('bitboxHsM1');
  }

  /// BitBox02: ingests handshake m2; pure-Dart stub always throws [BuError].
  @override
  void bitboxHsM2({required BuBytes m2}) {
    throw _un('bitboxHsM2');
  }

  /// BitBox02: handshake m3; pure-Dart stub always throws [BuError].
  @override
  BuBytes bitboxHsM3() {
    throw _un('bitboxHsM3');
  }

  /// BitBox02: splits into transport keys; pure-Dart stub always throws [BuError].
  @override
  void bitboxHsSplit() {
    throw _un('bitboxHsSplit');
  }

  /// BitBox02: encrypts one message; pure-Dart stub always throws [BuError].
  @override
  BuBytes bitboxEncrypt({required BuBytes plaintext}) {
    throw _un('bitboxEncrypt');
  }

  /// BitBox02: decrypts one message; pure-Dart stub always throws [BuError].
  @override
  BuBytes bitboxDecrypt({required BuBytes ciphertext}) {
    throw _un('bitboxDecrypt');
  }

  /// BitBox02: handshake hash; pure-Dart stub always throws [BuError].
  @override
  BuBytes bitboxHsHash() {
    throw _un('bitboxHsHash');
  }

  /// BitBox02: closes session; pure-Dart stub always throws [BuError].
  @override
  void bitboxFree() {
    throw _un('bitboxFree');
  }

  /// BitBox02: builds `Request{btc_pub}`; pure-Dart stub always throws [BuError].
  @override
  BuBytes bitboxBtcPubRequest({
    required int coin,
    required BuBytes pathU32,
    required int xpubType,
    required bool display,
  }) {
    throw _un('bitboxBtcPubRequest');
  }

  /// BitBox02: parses `Response` to xpub string; pure-Dart stub always throws [BuError].
  @override
  String bitboxPubParse({required BuBytes response}) {
    throw _un('bitboxPubParse');
  }

  /// BitBox02: builds `Request{btc_sign_init}`; pure-Dart stub always throws [BuError].
  @override
  BuBytes bitboxSignInit({
    required int coin,
    required BuBytes pathU32,
    required int simpleType,
    required int version,
    required int inputsCount,
    required int outputsCount,
    required int locktime,
  }) {
    throw _un('bitboxSignInit');
  }

  /// BitBox02: parses `sign_next`; pure-Dart stub always throws [BuError].
  @override
  (int, int) bitboxSignNextParse({required BuBytes response}) {
    throw _un('bitboxSignNextParse');
  }

  /// BitBox02: extracts `DONE` signature; pure-Dart stub always throws [BuError].
  @override
  BuBytes bitboxSignNextSignature({required BuBytes response}) {
    throw _un('bitboxSignNextSignature');
  }

  /// BitBox02: extracts `prev_index`; pure-Dart stub always throws [BuError].
  @override
  int bitboxSignNextPrevIndex({required BuBytes response}) {
    throw _un('bitboxSignNextPrevIndex');
  }

  /// BitBox02: builds `Request{btc_sign_input}`; pure-Dart stub always throws [BuError].
  @override
  BuBytes bitboxSignInput({
    required BuBytes prevHash32,
    required int prevIndex,
    required int amountSat,
    required int sequence,
    required BuBytes pathU32,
    required int scriptConfigIndex,
  }) {
    throw _un('bitboxSignInput');
  }

  /// BitBox02: builds external `Request{btc_sign_output}`; pure-Dart stub always throws [BuError].
  @override
  BuBytes bitboxSignOutput({
    required int outputType,
    required int amountSat,
    required BuBytes payload,
  }) {
    throw _un('bitboxSignOutput');
  }

  /// BitBox02: builds change `Request{btc_sign_output}`; pure-Dart stub always throws [BuError].
  @override
  BuBytes bitboxSignChange({
    required BuBytes pathU32,
    required int amountSat,
    required int scriptConfigIndex,
  }) {
    throw _un('bitboxSignChange');
  }

  /// BitBox02: builds `prevtx_init`; pure-Dart stub always throws [BuError].
  @override
  BuBytes bitboxSignPrevtxInit({
    required int version,
    required int inputsCount,
    required int outputsCount,
    required int locktime,
  }) {
    throw _un('bitboxSignPrevtxInit');
  }

  /// BitBox02: builds `prevtx_input`; pure-Dart stub always throws [BuError].
  @override
  BuBytes bitboxSignPrevtxInput({
    required BuBytes prevHash32,
    required int prevIndex,
    required BuBytes scriptSig,
    required int sequence,
  }) {
    throw _un('bitboxSignPrevtxInput');
  }

  /// BitBox02: builds `prevtx_output`; pure-Dart stub always throws [BuError].
  @override
  BuBytes bitboxSignPrevtxOutput({
    required int amountSat,
    required BuBytes script,
  }) {
    throw _un('bitboxSignPrevtxOutput');
  }

  /// Trezor: encodes `IdentityType`; pure-Dart stub always throws [BuError].
  @override
  BuBytes identityEncode({
    required String proto,
    String user = '',
    String host = '',
    String port = '',
    String path = '',
    int index = 0,
  }) {
    throw _un('identityEncode');
  }

  /// Trezor: builds framed `SignIdentity`; pure-Dart stub always throws [BuError].
  @override
  BuBytes signIdentityRequest({
    required BuBytes identity,
    required BuBytes hidden,
    String visual = '',
    int curve = 0,
  }) {
    throw _un('signIdentityRequest');
  }

  /// Trezor: parses `SignedIdentity.address`; pure-Dart stub always throws [BuError].
  @override
  String signedIdentityAddress({required BuBytes response}) {
    throw _un('signedIdentityAddress');
  }

  /// Trezor: parses `SignedIdentity.public_key`; pure-Dart stub always throws [BuError].
  @override
  BuBytes signedIdentityPubkey({required BuBytes response}) {
    throw _un('signedIdentityPubkey');
  }

  /// Trezor: parses `SignedIdentity.signature`; pure-Dart stub always throws [BuError].
  @override
  BuBytes signedIdentitySignature({required BuBytes response}) {
    throw _un('signedIdentitySignature');
  }

  /// Builds airgap QR string for [device], [coin] and [pathU32]; pure-Dart stub always throws [BuError].
  @override
  String qrRequest({
    required int device,
    required int coin,
    required BuBytes pathU32,
  }) {
    throw _un('qrRequest');
  }

  /// Parses single-part airgap QR [qr] for [device] to payload bytes; pure-Dart stub always throws [BuError].
  @override
  BuBytes qrParse({required int device, required String qr}) {
    throw _un('qrParse');
  }

  /// Returns `(inputCount, outputCount)` for PSBT [psbt]; pure-Dart stub always throws [BuError].
  @override
  (int, int) psbtCounts({required BuBytes psbt}) {
    throw _un('psbtCounts');
  }

  /// Encodes [payload] as single-part `ur:<type>/...` string; pure-Dart stub always throws [BuError].
  @override
  String urEncode({required String type, required BuBytes payload}) {
    throw _un('urEncode');
  }

  /// Decodes UR [ur] to payload bytes; pure-Dart stub always throws [BuError].
  @override
  BuBytes urDecodePayload(String ur) {
    throw _un('urDecodePayload');
  }

  /// Decodes UR [ur] to its type string; pure-Dart stub always throws [BuError].
  @override
  String urDecodeType(String ur) {
    throw _un('urDecodeType');
  }

  /// Builds request then exchanges via [transport] and parses address bytes; pure-Dart stub always throws [BuError].
  @override
  Future<BuBytes> executeGetAddress({
    required int device,
    required int coin,
    required BuBytes pathU32,
    required BuHwTransport transport,
  }) {
    throw _un('executeGetAddress');
  }

  /// Chunks [payload] into concatenated 64-byte HID reports; pure-Dart stub always throws [BuError].
  @override
  BuBytes hidFrame({
    required BuBytes payload,
    int channel = BuHwHid.channelDefault,
    int tag = BuHwHid.tagApdu,
  }) {
    throw _un('hidFrame');
  }

  /// Reassembles concatenated 64-byte HID [reports]; pure-Dart stub always throws [BuError].
  @override
  BuBytes hidUnframe({
    required BuBytes reports,
    int channel = BuHwHid.channelDefault,
    int tag = BuHwHid.tagApdu,
  }) {
    throw _un('hidUnframe');
  }
}
