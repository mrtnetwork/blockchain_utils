import 'package:blockchain_utils/crypto/crypto/protocol/jwt/jwt.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:test/test.dart';

import '../../utils.dart';

String _b64(String s) => StringUtils.decode(
  StringUtils.encode(s),
  encoding: StringEncoding.base64UrlSafe,
  b64NoPadding: true,
);

void jwtTest() {
  test('unsigned two-segment tokens keep legacy behavior', () {
    final header = _b64('{"alg":"EdDSA","typ":"JWT"}');
    final payload = _b64('{"iss":"wc","sub":"s","aud":["a"],"exp":1}');
    final jwt = Jwt.deserialize('$header.$payload');
    expect(jwt.header.alg, JwtSupportedAlgorithm.eddsa);
    expect(jwt.header.typ, 'JWT');
    expect(jwt.payload.aud, ['a']);
    expect(jwt.signature, isNull);
    // Single-element audiences serialize back as a plain string
    // (long-standing `toJson` behavior, unchanged here).
    final payloadSingle = _b64('{"iss":"wc","sub":"s","aud":"a","exp":1}');
    expect(jwt.serialize(), '$header.$payloadSingle');
  });

  test('signed OIDC tokens parse with external signature', () {
    final header = _b64('{"alg":"RS256","typ":"JWT","kid":"k1"}');
    final payload = _b64(
      '{"iss":"https://example.com","sub":"u1","aud":"my-dapp"}',
    );
    final sigBytes = List<int>.generate(64, (i) => i);
    final sig = StringUtils.decode(
      sigBytes,
      b64NoPadding: true,
      encoding: StringEncoding.base64UrlSafe,
    );
    final jwt = Jwt.deserializeOidc('$header.$payload.$sig');
    expect(jwt.header.kid, 'k1');
    expect(jwt.header.alg, isNull);
    // String audiences normalize to a single-element list.
    expect(jwt.payload.aud, ['my-dapp']);
    expect(jwt.signature, orderedEquals(sigBytes));
    expect(jwt.serialize(), '$header.$payload.$sig');
  });

  test('attachSignature appends an external signature', () {
    final jwt = Jwt(
      header: JwtHeader(alg: JwtSupportedAlgorithm.eddsa),
      payload: JwtPayload(iss: 'i'),
    );
    final two = jwt.serialize();
    expect(two.split('.'), hasLength(2));
    final sigBytes = List<int>.filled(32, 0x07);
    final three = jwt.attachSignature(sigBytes);
    expect(three.split('.'), hasLength(3));
    expect(Jwt.deserializeOidc(three).signature, orderedEquals(sigBytes));
  });

  test('headers without typ default instead of throwing', () {
    final header = _b64('{"alg":"RS256","kid":"k1"}');
    final payload = _b64('{"sub":"u1"}');
    final jwt = Jwt.deserializeOidc('$header.$payload.sig');
    expect(jwt.header.typ, 'JWT');
  });
}

void main() {
  BlockchainUtilsTestApi.runTest(jwtTest, "Jwt");
}
