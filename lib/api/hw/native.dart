import 'package:blockchain_utils/api/hw/api.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// [HwApi] backed by the native (FFI/platform) implementation.
///
/// Thin wrapper over the connector [BuHwApi] (held `Bu.hw`, Rust `hw`
/// core). Transport stays with the caller via [BuHwTransport].
class NativeHwApi implements HwApi {
  /// Underlying connector backend (held `Bu.hw`, Rust `hw` core).
  final BuHwApi api;

  /// Creates a native hardware-wallet backend over [api].
  const NativeHwApi(this.api);

  /// Offline curve-table check whether [device] supports [coin]; throws [CryptoException] on native failure.
  @override
  bool supportsCoin({required int device, required int coin}) {
    return api
        .supportsCoin(device: device, coin: coin)
        .unwrapOrThrowCryptoError();
  }

  /// Returns whether [device] is QR/SD-only; throws [CryptoException] on native failure.
  @override
  bool isAirgap({required int device}) {
    return api.isAirgap(device: device).unwrapOrThrowCryptoError();
  }

  /// Parses BIP path string [path] to `<u32 LE>` bytes; throws [CryptoException] on native failure.
  @override
  BuBytes parsePath(String path) {
    return api.parsePath(path).unwrapOrThrowCryptoError();
  }

  /// Validates [pathU32] shape for [device] and [coin]; throws [CryptoException] on native failure.
  @override
  void validatePath({
    required int device,
    required int coin,
    required BuBytes pathU32,
  }) {
    api
        .validatePath(device: device, coin: coin, pathU32: pathU32)
        .unwrapOrThrowCryptoError();
  }

  /// Builds USB request bytes for [device], [coin] and [pathU32]; throws [CryptoException] on native failure.
  @override
  BuBytes getAddressRequest({
    required int device,
    required int coin,
    required BuBytes pathU32,
  }) {
    return api
        .getAddressRequest(device: device, coin: coin, pathU32: pathU32)
        .unwrapOrThrowCryptoError();
  }

  /// Parses USB [response] bytes for [device] to pubkey/address bytes; throws [CryptoException] on native failure.
  @override
  BuBytes parseAddressResponse({
    required int device,
    required BuBytes response,
  }) {
    return api
        .parseAddressResponse(device: device, response: response)
        .unwrapOrThrowCryptoError();
  }

  /// Builds Ledger v2 `GET_MASTER_FINGERPRINT` request; throws [CryptoException] on native failure.
  @override
  BuBytes ledgerFingerprint() {
    return api.ledgerFingerprint().unwrapOrThrowCryptoError();
  }

  /// Parses 4-byte fingerprint; throws [CryptoException] on native failure.
  @override
  BuBytes ledgerFingerprintParse({required BuBytes response}) {
    return api
        .ledgerFingerprintParse(response: response)
        .unwrapOrThrowCryptoError();
  }

  /// Builds sign-request bytes; throws [CryptoException] on native failure.
  @override
  BuBytes signRequest({
    required int device,
    required int coin,
    required BuBytes pathU32,
    required BuBytes payload,
  }) {
    return api
        .signRequest(
          device: device,
          coin: coin,
          pathU32: pathU32,
          payload: payload,
        )
        .unwrapOrThrowCryptoError();
  }

  /// Parses sign response to signature bytes; throws [CryptoException] on native failure.
  @override
  BuBytes parseSignResponse({required int device, required BuBytes response}) {
    return api
        .parseSignResponse(device: device, response: response)
        .unwrapOrThrowCryptoError();
  }

  /// Builds request then exchanges via [transport] and parses signature; throws [CryptoException] on native failure.
  @override
  Future<BuBytes> executeSign({
    required int device,
    required int coin,
    required BuBytes pathU32,
    required BuBytes payload,
    required BuHwTransport transport,
  }) async {
    final result = await api.executeSign(
      device: device,
      coin: coin,
      pathU32: pathU32,
      payload: payload,
      transport: transport,
    );
    return result.unwrapOrThrowCryptoError();
  }

  /// Opens a Trezor `SignTx` session; throws [CryptoException] on native failure.
  @override
  BuBytes signTxStart({
    required int device,
    required int coin,
    required int inputsCount,
    required int outputsCount,
  }) {
    return api
        .signTxStart(
          device: device,
          coin: coin,
          inputsCount: inputsCount,
          outputsCount: outputsCount,
        )
        .unwrapOrThrowCryptoError();
  }

  /// Parses one `TxRequest`; throws [CryptoException] on native failure.
  @override
  (int, int) parseTxRequest({required int device, required BuBytes response}) {
    return api
        .parseTxRequest(device: device, response: response)
        .unwrapOrThrowCryptoError();
  }

  /// `TXFINISHED` signature bytes; throws [CryptoException] on native failure.
  @override
  BuBytes txRequestSignature({required int device, required BuBytes response}) {
    return api
        .txRequestSignature(device: device, response: response)
        .unwrapOrThrowCryptoError();
  }

  /// `TXFINISHED` serialized transaction; throws [CryptoException] on native failure.
  @override
  BuBytes txRequestSerialized({
    required int device,
    required BuBytes response,
  }) {
    return api
        .txRequestSerialized(device: device, response: response)
        .unwrapOrThrowCryptoError();
  }

  /// `TxRequest` prev-tx hash; throws [CryptoException] on native failure.
  @override
  BuBytes txRequestTxHash({required int device, required BuBytes response}) {
    return api
        .txRequestTxHash(device: device, response: response)
        .unwrapOrThrowCryptoError();
  }

  /// `TxAck` for `TXMETA`; throws [CryptoException] on native failure.
  @override
  BuBytes txAckMeta({
    required int version,
    required int lockTime,
    required int inputsCount,
    required int outputsCount,
  }) {
    return api
        .txAckMeta(
          version: version,
          lockTime: lockTime,
          inputsCount: inputsCount,
          outputsCount: outputsCount,
        )
        .unwrapOrThrowCryptoError();
  }

  /// `TxAck` for `TXINPUT`; throws [CryptoException] on native failure.
  @override
  BuBytes txAckInput({
    required BuBytes prevHash32,
    required int prevIndex,
    required BuBytes pathU32,
    required int amountSat,
    required BuBytes scriptSig,
    required int scriptType,
  }) {
    return api
        .txAckInput(
          prevHash32: prevHash32,
          prevIndex: prevIndex,
          pathU32: pathU32,
          amountSat: amountSat,
          scriptSig: scriptSig,
          scriptType: scriptType,
        )
        .unwrapOrThrowCryptoError();
  }

  /// `TxAck` for `TXOUTPUT` (address); throws [CryptoException] on native failure.
  @override
  BuBytes txAckOutput({
    required String address,
    required int amountSat,
    required int scriptType,
  }) {
    return api
        .txAckOutput(
          address: address,
          amountSat: amountSat,
          scriptType: scriptType,
        )
        .unwrapOrThrowCryptoError();
  }

  /// `TxAck` for `TXOUTPUT` (change); throws [CryptoException] on native failure.
  @override
  BuBytes txAckChange({
    required BuBytes pathU32,
    required int amountSat,
    required int scriptType,
  }) {
    return api
        .txAckChange(
          pathU32: pathU32,
          amountSat: amountSat,
          scriptType: scriptType,
        )
        .unwrapOrThrowCryptoError();
  }

  /// `TxAck` for previous-transaction `TXOUTPUT`; throws [CryptoException] on native failure.
  @override
  BuBytes txAckBinOutput({
    required BuBytes scriptPubKey,
    required int amountSat,
  }) {
    return api
        .txAckBinOutput(scriptPubKey: scriptPubKey, amountSat: amountSat)
        .unwrapOrThrowCryptoError();
  }

  /// BitBox02: opens initiator session; throws [CryptoException] on native failure.
  @override
  void bitboxHsNew({
    required BuBytes staticPriv32,
    required BuBytes ephemeralPriv32,
  }) {
    api
        .bitboxHsNew(
          staticPriv32: staticPriv32,
          ephemeralPriv32: ephemeralPriv32,
        )
        .unwrapOrThrowCryptoError();
  }

  /// BitBox02: handshake m1; throws [CryptoException] on native failure.
  @override
  BuBytes bitboxHsM1() {
    return api.bitboxHsM1().unwrapOrThrowCryptoError();
  }

  /// BitBox02: ingests handshake m2; throws [CryptoException] on native failure.
  @override
  void bitboxHsM2({required BuBytes m2}) {
    api.bitboxHsM2(m2: m2).unwrapOrThrowCryptoError();
  }

  /// BitBox02: handshake m3; throws [CryptoException] on native failure.
  @override
  BuBytes bitboxHsM3() {
    return api.bitboxHsM3().unwrapOrThrowCryptoError();
  }

  /// BitBox02: splits into transport keys; throws [CryptoException] on native failure.
  @override
  void bitboxHsSplit() {
    api.bitboxHsSplit().unwrapOrThrowCryptoError();
  }

  /// BitBox02: encrypts one message; throws [CryptoException] on native failure.
  @override
  BuBytes bitboxEncrypt({required BuBytes plaintext}) {
    return api
        .bitboxEncrypt(plaintext: plaintext)
        .unwrapOrThrowCryptoError();
  }

  /// BitBox02: decrypts one message; throws [CryptoException] on native failure.
  @override
  BuBytes bitboxDecrypt({required BuBytes ciphertext}) {
    return api
        .bitboxDecrypt(ciphertext: ciphertext)
        .unwrapOrThrowCryptoError();
  }

  /// BitBox02: handshake hash; throws [CryptoException] on native failure.
  @override
  BuBytes bitboxHsHash() {
    return api.bitboxHsHash().unwrapOrThrowCryptoError();
  }

  /// BitBox02: closes session; throws [CryptoException] on native failure.
  @override
  void bitboxFree() {
    api.bitboxFree().unwrapOrThrowCryptoError();
  }

  /// BitBox02: builds `Request{btc_pub}`; throws [CryptoException] on native failure.
  @override
  BuBytes bitboxBtcPubRequest({
    required int coin,
    required BuBytes pathU32,
    required int xpubType,
    required bool display,
  }) {
    return api
        .bitboxBtcPubRequest(
          coin: coin,
          pathU32: pathU32,
          xpubType: xpubType,
          display: display,
        )
        .unwrapOrThrowCryptoError();
  }

  /// BitBox02: parses `Response` to xpub string; throws [CryptoException] on native failure.
  @override
  String bitboxPubParse({required BuBytes response}) {
    return api
        .bitboxPubParse(response: response)
        .unwrapOrThrowCryptoError();
  }

  /// BitBox02: builds `Request{btc_sign_init}`; throws [CryptoException] on native failure.
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
    return api
        .bitboxSignInit(
          coin: coin,
          pathU32: pathU32,
          simpleType: simpleType,
          version: version,
          inputsCount: inputsCount,
          outputsCount: outputsCount,
          locktime: locktime,
        )
        .unwrapOrThrowCryptoError();
  }

  /// BitBox02: parses `sign_next`; throws [CryptoException] on native failure.
  @override
  (int, int) bitboxSignNextParse({required BuBytes response}) {
    return api
        .bitboxSignNextParse(response: response)
        .unwrapOrThrowCryptoError();
  }

  /// BitBox02: extracts `DONE` signature; throws [CryptoException] on native failure.
  @override
  BuBytes bitboxSignNextSignature({required BuBytes response}) {
    return api
        .bitboxSignNextSignature(response: response)
        .unwrapOrThrowCryptoError();
  }

  /// BitBox02: extracts `prev_index`; throws [CryptoException] on native failure.
  @override
  int bitboxSignNextPrevIndex({required BuBytes response}) {
    return api
        .bitboxSignNextPrevIndex(response: response)
        .unwrapOrThrowCryptoError();
  }

  /// BitBox02: builds `Request{btc_sign_input}`; throws [CryptoException] on native failure.
  @override
  BuBytes bitboxSignInput({
    required BuBytes prevHash32,
    required int prevIndex,
    required int amountSat,
    required int sequence,
    required BuBytes pathU32,
    required int scriptConfigIndex,
  }) {
    return api
        .bitboxSignInput(
          prevHash32: prevHash32,
          prevIndex: prevIndex,
          amountSat: amountSat,
          sequence: sequence,
          pathU32: pathU32,
          scriptConfigIndex: scriptConfigIndex,
        )
        .unwrapOrThrowCryptoError();
  }

  /// BitBox02: builds external `Request{btc_sign_output}`; throws [CryptoException] on native failure.
  @override
  BuBytes bitboxSignOutput({
    required int outputType,
    required int amountSat,
    required BuBytes payload,
  }) {
    return api
        .bitboxSignOutput(
          outputType: outputType,
          amountSat: amountSat,
          payload: payload,
        )
        .unwrapOrThrowCryptoError();
  }

  /// BitBox02: builds change `Request{btc_sign_output}`; throws [CryptoException] on native failure.
  @override
  BuBytes bitboxSignChange({
    required BuBytes pathU32,
    required int amountSat,
    required int scriptConfigIndex,
  }) {
    return api
        .bitboxSignChange(
          pathU32: pathU32,
          amountSat: amountSat,
          scriptConfigIndex: scriptConfigIndex,
        )
        .unwrapOrThrowCryptoError();
  }

  /// BitBox02: builds `prevtx_init`; throws [CryptoException] on native failure.
  @override
  BuBytes bitboxSignPrevtxInit({
    required int version,
    required int inputsCount,
    required int outputsCount,
    required int locktime,
  }) {
    return api
        .bitboxSignPrevtxInit(
          version: version,
          inputsCount: inputsCount,
          outputsCount: outputsCount,
          locktime: locktime,
        )
        .unwrapOrThrowCryptoError();
  }

  /// BitBox02: builds `prevtx_input`; throws [CryptoException] on native failure.
  @override
  BuBytes bitboxSignPrevtxInput({
    required BuBytes prevHash32,
    required int prevIndex,
    required BuBytes scriptSig,
    required int sequence,
  }) {
    return api
        .bitboxSignPrevtxInput(
          prevHash32: prevHash32,
          prevIndex: prevIndex,
          scriptSig: scriptSig,
          sequence: sequence,
        )
        .unwrapOrThrowCryptoError();
  }

  /// BitBox02: builds `prevtx_output`; throws [CryptoException] on native failure.
  @override
  BuBytes bitboxSignPrevtxOutput({
    required int amountSat,
    required BuBytes script,
  }) {
    return api
        .bitboxSignPrevtxOutput(amountSat: amountSat, script: script)
        .unwrapOrThrowCryptoError();
  }

  /// Trezor: encodes `IdentityType`; throws [CryptoException] on native failure.
  @override
  BuBytes identityEncode({
    required String proto,
    String user = '',
    String host = '',
    String port = '',
    String path = '',
    int index = 0,
  }) {
    return api
        .identityEncode(
          proto: proto,
          user: user,
          host: host,
          port: port,
          path: path,
          index: index,
        )
        .unwrapOrThrowCryptoError();
  }

  /// Trezor: builds framed `SignIdentity`; throws [CryptoException] on native failure.
  @override
  BuBytes signIdentityRequest({
    required BuBytes identity,
    required BuBytes hidden,
    String visual = '',
    int curve = 0,
  }) {
    return api
        .signIdentityRequest(
          identity: identity,
          hidden: hidden,
          visual: visual,
          curve: curve,
        )
        .unwrapOrThrowCryptoError();
  }

  /// Trezor: parses `SignedIdentity.address`; throws [CryptoException] on native failure.
  @override
  String signedIdentityAddress({required BuBytes response}) {
    return api
        .signedIdentityAddress(response: response)
        .unwrapOrThrowCryptoError();
  }

  /// Trezor: parses `SignedIdentity.public_key`; throws [CryptoException] on native failure.
  @override
  BuBytes signedIdentityPubkey({required BuBytes response}) {
    return api
        .signedIdentityPubkey(response: response)
        .unwrapOrThrowCryptoError();
  }

  /// Trezor: parses `SignedIdentity.signature`; throws [CryptoException] on native failure.
  @override
  BuBytes signedIdentitySignature({required BuBytes response}) {
    return api
        .signedIdentitySignature(response: response)
        .unwrapOrThrowCryptoError();
  }

  /// Builds airgap QR string for [device], [coin] and [pathU32]; throws [CryptoException] on native failure.
  @override
  String qrRequest({
    required int device,
    required int coin,
    required BuBytes pathU32,
  }) {
    return api
        .qrRequest(device: device, coin: coin, pathU32: pathU32)
        .unwrapOrThrowCryptoError();
  }

  /// Parses single-part airgap QR [qr] for [device] to payload bytes; throws [CryptoException] on native failure.
  @override
  BuBytes qrParse({required int device, required String qr}) {
    return api
        .qrParse(device: device, qr: qr)
        .unwrapOrThrowCryptoError();
  }

  /// Returns `(inputCount, outputCount)` for PSBT [psbt]; throws [CryptoException] on native failure.
  @override
  (int, int) psbtCounts({required BuBytes psbt}) {
    return api.psbtCounts(psbt: psbt).unwrapOrThrowCryptoError();
  }

  /// Encodes [payload] as single-part `ur:<type>/...` string; throws [CryptoException] on native failure.
  @override
  String urEncode({required String type, required BuBytes payload}) {
    return api
        .urEncode(type: type, payload: payload)
        .unwrapOrThrowCryptoError();
  }

  /// Decodes UR [ur] to payload bytes; throws [CryptoException] on native failure.
  @override
  BuBytes urDecodePayload(String ur) {
    return api.urDecodePayload(ur).unwrapOrThrowCryptoError();
  }

  /// Decodes UR [ur] to its type string; throws [CryptoException] on native failure.
  @override
  String urDecodeType(String ur) {
    return api.urDecodeType(ur).unwrapOrThrowCryptoError();
  }

  /// Chunks [payload] into concatenated 64-byte HID reports; throws [CryptoException] on native failure.
  @override
  BuBytes hidFrame({
    required BuBytes payload,
    int channel = BuHwHid.channelDefault,
    int tag = BuHwHid.tagApdu,
  }) {
    return api
        .hidFrame(payload: payload, channel: channel, tag: tag)
        .unwrapOrThrowCryptoError();
  }

  /// Reassembles concatenated 64-byte HID [reports]; throws [CryptoException] on native failure.
  @override
  BuBytes hidUnframe({
    required BuBytes reports,
    int channel = BuHwHid.channelDefault,
    int tag = BuHwHid.tagApdu,
  }) {
    return api
        .hidUnframe(reports: reports, channel: channel, tag: tag)
        .unwrapOrThrowCryptoError();
  }

  /// Builds request then exchanges via [transport] and parses address bytes; throws [CryptoException] on native failure.
  @override
  Future<BuBytes> executeGetAddress({
    required int device,
    required int coin,
    required BuBytes pathU32,
    required BuHwTransport transport,
  }) async {
    final result = await api.executeGetAddress(
      device: device,
      coin: coin,
      pathU32: pathU32,
      transport: transport,
    );
    return result.unwrapOrThrowCryptoError();
  }
}
