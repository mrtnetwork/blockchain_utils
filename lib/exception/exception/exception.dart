import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/pedersen_hash/src/exception.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/networks/types/network.dart';
import 'package:blockchain_utils/numbers/src/exception/exception.dart';
import 'package:blockchain_utils/proto/exception/exception.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';
import 'package:blockchain_utils/base58/base58_ex.dart';
import 'package:blockchain_utils/base64/exception/exception.dart';
import 'package:blockchain_utils/bech32/bech32_ex.dart';
import 'package:blockchain_utils/bip/address/exception/exception.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_ex.dart';
import 'package:blockchain_utils/bip/bip/bip44/base/bip44_base_ex.dart';
import 'package:blockchain_utils/bip/bip/zip32/exception/exception.dart';
import 'package:blockchain_utils/bip/electrum/exception.dart';
import 'package:blockchain_utils/bip/mnemonic/src/mnemonic_ex.dart';
import 'package:blockchain_utils/bip/monero/monero_exc.dart';
import 'package:blockchain_utils/bip/substrate/exception/substrate_ex.dart';
import 'package:blockchain_utils/bip/zcash/src/exception.dart';
import 'package:blockchain_utils/crypto/crypto/exception/exception.dart';
import 'package:blockchain_utils/layout/exception/exception.dart';
import 'package:blockchain_utils/secret_wallet/src/exception.dart';
import 'package:blockchain_utils/ss58/ss58_ex.dart';
import 'package:blockchain_utils/utf8/src/exception.dart';
import 'package:blockchain_utils/utils/amount/amount/exception.dart';
import 'package:blockchain_utils/utils/json/exception/exception.dart';
import 'package:blockchain_utils/serialization/identifier.dart';

abstract class IException
    with CborTagSerializable, Equality
    implements Exception {
  final String message;
  final Map<String, String?>? details;
  const IException(this.message, {this.details});
  factory IException.deserialize({List<int>? bytes, CborObject? object}) {
    final values = CborTagSerializable.decodeTaggedValueWithInfo(
      expectedTags: BlockchainUtilsSerializationIdentifier.values,
      cborBytes: bytes,
      cborObject: object,
    );
    final identifier = values.identifier;
    return switch (identifier) {
      BlockchainUtilsSerializationIdentifier.argumentException =>
        ArgumentException.deserialize(object: values.tag),
      BlockchainUtilsSerializationIdentifier.stateException =>
        StateException.deserialize(object: values.tag),
      BlockchainUtilsSerializationIdentifier.itemNotFound =>
        ItemNotFoundException.deserialize(object: values.tag),
      BlockchainUtilsSerializationIdentifier.casting =>
        CastFailedException.deserialize(object: values.tag),
      BlockchainUtilsSerializationIdentifier.rpcError => RPCError.deserialize(
        object: values.tag,
      ),
      BlockchainUtilsSerializationIdentifier.base58Error =>
        Base58ChecksumError.deserialize(object: values.tag),
      BlockchainUtilsSerializationIdentifier.base64Error =>
        B64ConverterException.deserialize(object: values.tag),
      BlockchainUtilsSerializationIdentifier.bech32Error =>
        Bech32Error.deserialize(object: values.tag),
      BlockchainUtilsSerializationIdentifier.addressConverterError =>
        AddressConverterException.deserialize(object: values.tag),
      BlockchainUtilsSerializationIdentifier.bip32KeyError =>
        Bip32KeyError.deserialize(object: values.tag),
      BlockchainUtilsSerializationIdentifier.bip32PathError =>
        Bip32PathError.deserialize(object: values.tag),
      BlockchainUtilsSerializationIdentifier.bip44DepthError =>
        Bip44DepthError.deserialize(object: values.tag),
      BlockchainUtilsSerializationIdentifier.zip32Error =>
        Zip32Error.deserialize(object: values.tag),
      BlockchainUtilsSerializationIdentifier.electrumError =>
        ElectrumException.deserialize(object: values.tag),
      BlockchainUtilsSerializationIdentifier.mnemonicError =>
        MnemonicException.deserialize(object: values.tag),
      BlockchainUtilsSerializationIdentifier.moneroKeyError =>
        MoneroKeyError.deserialize(object: values.tag),
      BlockchainUtilsSerializationIdentifier.substrateKeyError =>
        SubstrateKeyError.deserialize(object: values.tag),
      BlockchainUtilsSerializationIdentifier.substratePathError =>
        SubstratePathError.deserialize(object: values.tag),
      BlockchainUtilsSerializationIdentifier.zcashError =>
        ZcashKeyError.deserialize(object: values.tag),
      BlockchainUtilsSerializationIdentifier.zcashKeyEncodingError =>
        ZcashKeyEncodingError.deserialize(object: values.tag),
      BlockchainUtilsSerializationIdentifier.cborError =>
        CborException.deserialize(object: values.tag),
      BlockchainUtilsSerializationIdentifier.cborSerializationError =>
        CborSerializableException.deserialize(object: values.tag),
      BlockchainUtilsSerializationIdentifier.cryptoError =>
        CryptoException.deserialize(object: values.tag),
      BlockchainUtilsSerializationIdentifier.layoutExceptionError =>
        LayoutException.deserialize(object: values.tag),
      BlockchainUtilsSerializationIdentifier.protoError =>
        ProtoException.deserialize(object: values.tag),
      BlockchainUtilsSerializationIdentifier.secretStorageError =>
        Web3SecretStorageDefinationV3Exception.deserialize(object: values.tag),
      BlockchainUtilsSerializationIdentifier.ss58Error =>
        SS58ChecksumError.deserialize(object: values.tag),
      BlockchainUtilsSerializationIdentifier.utf8Error =>
        Utf8Exception.deserialize(object: values.tag),
      BlockchainUtilsSerializationIdentifier.amountConverterError =>
        AmountConverterException.deserialize(object: values.tag),
      BlockchainUtilsSerializationIdentifier.jsonParserError =>
        JsonParserError.deserialize(object: values.tag),
      BlockchainUtilsSerializationIdentifier.pedersenHashError =>
        PedersenHashException.deserialize(object: values.tag),
      BlockchainUtilsSerializationIdentifier.integerError =>
        IntegerError.deserialize(object: values.tag),
      _ => CborSerializableException.incorrectTagValue(tag: values.tag.tags),
    };
  }

  @override
  List<CborObject?> get serializationItems => [
    message.toCbor(),
    switch (details) {
      null => CborNullValue(),
      Map<String, String?> value => value.toCbor(),
    },
  ];

  @override
  List<dynamic> get variables => [message, details];

  @override
  SerializationIdentifier get serializationIdentifier;

  BlockchainNetwork? get relatedNetwork;

  @override
  String toString() {
    final infos = Map<String, dynamic>.fromEntries(
      details?.entries.where((element) => element.value != null) ?? [],
    );
    if (infos.isEmpty) return message;
    final String msg =
        "$message ${infos.entries.map((e) => "${e.key}: ${e.value}").join(", ")}";
    return msg;
  }
}
