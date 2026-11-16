import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

void main() {
  group('BuErrorCodec', () {
    test('core round-trip preserves code, message and details', () {
      const e = BuError(
        DefaultErrorType.invalidLength,
        'x must be 2 bytes, got 5',
        details: {'expected': '2', 'actual': '5'},
      );
      final back = BuErrorCodec.decode(bytes: e.toCborBytes());
      expect(back.type, DefaultErrorType.invalidLength);
      expect(back.message, 'x must be 2 bytes, got 5');
      expect(back.details, {'expected': '2', 'actual': '5'});
    });

    test('null details round-trip', () {
      const e = BuError(DefaultErrorType.internal, 'boom');
      final back = BuErrorCodec.decode(bytes: e.toCborBytes());
      expect(back.type, DefaultErrorType.internal);
      expect(back.message, 'boom');
      expect(back.details, isNull);
    });

    test('chain enum round-trip after registration', () {
      BuErrorCodec.registerTypes(_ChainError.values);
      const e = BuError(_ChainError.badKeyImage, 'bad key image');
      final back = BuErrorCodec.decode(bytes: e.toCborBytes());
      expect(back.type, _ChainError.badKeyImage);
      expect(back.message, 'bad key image');
    });

    test('unregistered identifier throws BuError', () {
      expect(
        BuErrorCodec.decode(
          bytes: const BuError(_Unregistered(999999), 'x').toCborBytes(),
        ).type,
        DefaultErrorType.invalidArgument,
      );
    });

    test('corrupt bytes throw BuError (never raw CBOR errors)', () {
      expect(
        () => BuErrorCodec.decode(bytes: [0xff, 0xff]),
        throwsA(isA<BuError>()),
      );
    });

    test('RPCError keeps its full payload', () {
      final e = RPCError(
        message: 'rpc failed',
        errorCode: -32600,
        request: {'method': 'getBlock'},
        jsonRpcErrpr: {'code': -32600},
        statusCode: 500,
        relatedNetwork: BlockchainNetwork.ethereum,
      );
      final back = BuErrorCodec.decode(bytes: e.toCborBytes());
      expect(back, isA<RPCError>());
      final rpc = back as RPCError;
      expect(rpc.type, DefaultErrorType.network);
      expect(rpc.message, 'rpc failed');
      expect(rpc.errorCode, -32600);
      expect(rpc.request, {'method': 'getBlock'});
      expect(rpc.jsonRpcErrpr, {'code': -32600});
      expect(rpc.statusCode, 500);
      expect(rpc.relatedNetwork, BlockchainNetwork.ethereum);
    });

    test('plain network error (2 slots) is not an RPCError', () {
      const e = BuError(DefaultErrorType.network, 'down');
      final back = BuErrorCodec.decode(bytes: e.toCborBytes());
      expect(back, isNot(isA<RPCError>()));
      expect(back.type, DefaultErrorType.network);
    });
  });
}

class _Unregistered implements BuErrorType {
  const _Unregistered(this.id);
  @override
  String get domain => 'test';
  @override
  String get errName => 'unregistered';
  @override
  final int id;

  @override
  bool isValid(int? tag) {
    throw UnimplementedError();
  }
}

enum _ChainError implements BuErrorType {
  badKeyImage(11006),
  proof(11007);

  @override
  String get domain => 'test-chain';
  @override
  String get errName => name;
  @override
  final int id;
  const _ChainError(this.id);

  @override
  bool isValid(int? tag) {
    throw UnimplementedError();
  }
}
