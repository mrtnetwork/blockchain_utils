import 'package:blockchain_utils/blockchain_utils.dart';

enum JwtSupportedAlgorithm {
  hs256('HS256'),
  hs384('HS384'),
  hs512('HS512'),
  es256('ES256'),
  es256k('ES256K'),
  es384('ES384'),
  es512('ES512'),
  eddsa('EdDSA');

  final String name;
  const JwtSupportedAlgorithm(this.name);

  static JwtSupportedAlgorithm? fromName(String? alg) {
    return values.firstWhereNullable((e) => e.name == alg);
  }

  @override
  String toString() => name;
}

class JwtHeader {
  final JwtSupportedAlgorithm? alg;
  final String typ;
  final String? kid;
  final String? cty;
  final Map<String, dynamic>? customClaims;

  factory JwtHeader.fromJson(Map<String, dynamic> json) {
    json = json.clone();
    return JwtHeader(
        alg: JwtSupportedAlgorithm.fromName(json['alg']),
        typ: json['typ'],
        kid: json['kid'],
        cty: json['cty'],
        customClaims: json
          ..removeWhere((k, v) => ['typ', 'kid', 'cty'].contains(k)));
  }

  JwtHeader({
    this.alg = JwtSupportedAlgorithm.eddsa,
    this.typ = 'JWT',
    this.kid,
    this.cty,
    Map<String, dynamic>? customClaims,
  }) : customClaims = customClaims?.immutable;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'alg': alg?.name,
      'typ': typ,
    };
    if (kid != null) map['kid'] = kid;
    if (cty != null) map['cty'] = cty;
    if (customClaims != null) {
      map.addAll(customClaims!);
    }
    return map;
  }
}

class JwtPayload {
  final String? iss; // Issuer
  final String? sub; // Subject
  final List<String>? aud; // Audience (usually a list)
  final int? exp; // Expiration time (epoch seconds)
  final int? nbf; // Not before (epoch seconds)
  final int? iat; // Issued at (epoch seconds)
  final String? jti; // JWT ID (unique identifier)
  final Map<String, dynamic>? customClaims; // Any additional custom claims
  final String? name;

  factory JwtPayload.fromJson(Map<String, dynamic> json) {
    json = json.clone();
    return JwtPayload(
        iss: json['iss'],
        sub: json['sub'],
        aud: json['aud'],
        exp: json['exp'],
        iat: json['iat'],
        nbf: json['nbf'],
        jti: json['jti'],
        name: json['name'],
        customClaims: json
          ..removeWhere((k, v) => [
                'name',
                'jti',
                'nbf',
                'iat',
                'iss',
                'sub',
                'aud',
                'exp',
              ].contains(k)));
  }

  JwtPayload({
    this.iss,
    this.sub,
    this.aud,
    this.exp,
    this.nbf,
    this.iat,
    this.jti,
    this.name,
    this.customClaims,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (iss != null) map['iss'] = iss;
    if (sub != null) map['sub'] = sub;
    if (name != null) map['name'] = name;
    if (aud != null) map['aud'] = aud!.length == 1 ? aud!.first : aud;
    if (nbf != null) map['nbf'] = nbf;
    if (iat != null) map['iat'] = iat;
    if (jti != null) map['jti'] = jti;
    if (exp != null) map['exp'] = exp;
    if (customClaims != null) {
      map.addAll(customClaims!);
    }
    return map;
  }
}

class Jwt {
  final JwtHeader header;
  final JwtPayload payload;
  const Jwt({required this.header, required this.payload});

  factory Jwt.deserialize(String jwt) {
    final parts = jwt.split('.');
    if (parts.length != 2) {
      throw CryptoException("Invalid serialized jwt.");
    }
    final header = StringUtils.decodeJson<Map<String, dynamic>>(
        StringUtils.encode(parts[0],
            validateB64Padding: false, type: StringEncoding.base64));
    final payload = StringUtils.decodeJson<Map<String, dynamic>>(
        StringUtils.encode(parts[1],
            validateB64Padding: false, type: StringEncoding.base64));
    return Jwt(
        header: JwtHeader.fromJson(header),
        payload: JwtPayload.fromJson(payload));
  }

  String serialize() {
    final headerJson = header.toJson();

    final encodedHeader = StringUtils.decode(StringUtils.encodeJson(headerJson),
        b64NoPadding: true, type: StringEncoding.base64UrlSafe);
    final encodedPayload = StringUtils.decode(
        StringUtils.encodeJson(payload.toJson()),
        b64NoPadding: true,
        type: StringEncoding.base64UrlSafe);
    return '$encodedHeader.$encodedPayload';
  }

  String sign({required List<int> key, JwtSupportedAlgorithm? alg}) {
    alg ??= header.alg;
    if (alg == null) {
      throw CryptoException("Unknow signing algorithm.");
    }
    final signingInput = serialize();

    final signInputBytes = signingInput.codeUnits;
    List<int>? signature;
    switch (alg) {
      case JwtSupportedAlgorithm.eddsa:
        final signer = Ed25519Signer.fromKeyBytes(
            key.sublist(0, Ed25519KeysConst.privKeyByteLen));
        signature = signer.sign(signInputBytes);
        break;
      case JwtSupportedAlgorithm.hs256:
        signature = HMAC.hmac(() => SHA256(), key, signInputBytes);
        break;
      case JwtSupportedAlgorithm.hs384:
        signature = HMAC.hmac(() => SHA384(), key, signInputBytes);
        break;
      case JwtSupportedAlgorithm.hs512:
        signature = HMAC.hmac(() => SHA512(), key, signInputBytes);
        break;
      case JwtSupportedAlgorithm.es256:
        final signer = Nist256p1Signer.fromKeyBytes(key);
        signature = signer.sign(SHA256.hash(signInputBytes));

        break;
      case JwtSupportedAlgorithm.es384:
        final signer = Nist256p1Signer.fromKeyBytes(key);
        signature = signer.sign(SHA384.hash(signInputBytes));
        break;
      case JwtSupportedAlgorithm.es512:
        final signer = Nist256p1Signer.fromKeyBytes(key);
        signature = signer.sign(SHA512.hash(signInputBytes));
        break;
      case JwtSupportedAlgorithm.es256k:
        final signer = Secp256k1Signer.fromKeyBytes(key);
        signature = signer.sign(SHA256.hash(signInputBytes));
        break;
    }
    final encodedSignature = StringUtils.decode(signature,
        b64NoPadding: true, type: StringEncoding.base64UrlSafe);
    return '$signingInput.$encodedSignature';
  }
}
