import 'package:blockchain_utils/crypto/crypto/keys/keys.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/chain/signer/ed25519/ed25519.dart';
import 'package:blockchain_utils/chain/signer/secp256k1/secp256k1_signer.dart';
import 'package:blockchain_utils/chain/signer/secp256r1/secp256r1_signer.dart';
import 'package:blockchain_utils/utils/string/string.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// JWS algorithms supported for signing/verifying a [Jwt].
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

/// The decoded JOSE header of a [Jwt].
class JwtHeader {
  final JwtSupportedAlgorithm? alg;

  /// Raw `alg` string as it appears in the token (kept verbatim so
  /// unknown algorithms such as `RS256` survive the round trip).
  final String? algName;
  final String typ;
  final String? kid;
  final String? cty;
  final Map<String, dynamic>? customClaims;

  factory JwtHeader.fromJson(Map<String, dynamic> json) {
    json = json.clone();
    return JwtHeader(
      alg: JwtSupportedAlgorithm.fromName(json['alg']),
      algName: json['alg']?.toString(),
      typ: json['typ'] ?? 'JWT',
      kid: json['kid'],
      cty: json['cty'],
      customClaims:
          json..removeWhere((k, v) => ['typ', 'kid', 'cty'].contains(k)),
    );
  }

  JwtHeader({
    this.alg = JwtSupportedAlgorithm.eddsa,
    String? algName,
    this.typ = 'JWT',
    this.kid,
    this.cty,
    Map<String, dynamic>? customClaims,
  }) : algName = algName ?? alg?.name,
       customClaims = customClaims?.immutable;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'alg': alg?.name ?? algName, 'typ': typ};
    if (kid != null) map['kid'] = kid;
    if (cty != null) map['cty'] = cty;
    if (customClaims != null) {
      map.addAll(customClaims!);
    }
    return map;
  }
}

/// The decoded claims set of a [Jwt].
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
    final aud = json['aud'];
    return JwtPayload(
      iss: json['iss'],
      sub: json['sub'],
      aud: aud is String ? [aud] : (aud as List?)?.cast<String>(),
      exp: json['exp'],
      iat: json['iat'],
      nbf: json['nbf'],
      jti: json['jti'],
      name: json['name'],
      customClaims:
          json..removeWhere(
            (k, v) => [
              'name',
              'jti',
              'nbf',
              'iat',
              'iss',
              'sub',
              'aud',
              'exp',
            ].contains(k),
          ),
    );
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

/// A JSON Web Token: a [JwtHeader] plus a [JwtPayload], with signing
/// and verification.
///
/// The [signature] is the raw third-segment bytes when the token was
/// produced externally (e.g. OIDC IdP signatures, which cannot be generated
/// here). Unsigned flows (e.g. WalletConnect) leave it null and keep the
/// historical two-segment serialization untouched.
class Jwt {
  final JwtHeader header;
  final JwtPayload payload;

  /// Raw signature bytes (third compact-serialization segment), if any.
  final List<int>? signature;

  const Jwt({required this.header, required this.payload, this.signature});

  static Map<String, dynamic> _decodeSegment(String segment) {
    return StringUtils.decodeJson<Map<String, dynamic>>(
      StringUtils.encode(
        segment,
        validateB64Padding: false,
        encoding: StringEncoding.base64,
      ),
    );
  }

  factory Jwt.deserialize(String jwt) {
    final parts = jwt.split('.');
    if (parts.length != 2) {
      throw BuError(
        DefaultErrorType.invalidArgument,
        "Invalid serialized jwt.",
      );
    }
    return Jwt(
      header: JwtHeader.fromJson(_decodeSegment(parts[0])),
      payload: JwtPayload.fromJson(_decodeSegment(parts[1])),
    );
  }

  /// Parses a signed compact serialization (`header.payload.signature`),
  /// keeping the third segment as [signature] instead of verifying it.
  /// Signature verification (OIDC, JWKs, …) happens at the call site.
  factory Jwt.deserializeOidc(String jwt) {
    final parts = jwt.split('.');
    if (parts.length != 3) {
      throw BuError(
        DefaultErrorType.invalidArgument,
        "Invalid serialized OIDC jwt.",
      );
    }
    return Jwt(
      header: JwtHeader.fromJson(_decodeSegment(parts[0])),
      payload: JwtPayload.fromJson(_decodeSegment(parts[1])),
      signature: StringUtils.encode(
        parts[2],
        validateB64Padding: false,
        encoding: StringEncoding.base64,
      ),
    );
  }

  String serialize() {
    final headerJson = header.toJson();

    final encodedHeader = StringUtils.decode(
      StringUtils.encodeJson(headerJson),
      b64NoPadding: true,
      encoding: StringEncoding.base64UrlSafe,
    );
    final encodedPayload = StringUtils.decode(
      StringUtils.encodeJson(payload.toJson()),
      b64NoPadding: true,
      encoding: StringEncoding.base64UrlSafe,
    );
    final unsigned = '$encodedHeader.$encodedPayload';
    final sig = signature;
    if (sig == null) return unsigned;
    final encodedSignature = StringUtils.decode(
      sig,
      b64NoPadding: true,
      encoding: StringEncoding.base64UrlSafe,
    );
    return '$unsigned.$encodedSignature';
  }

  /// Attaches an externally produced [signature] (e.g. IdP JWT signatures)
  /// and returns the full three-segment compact serialization.
  String attachSignature(List<int> signature) {
    final encodedSignature = StringUtils.decode(
      signature,
      b64NoPadding: true,
      encoding: StringEncoding.base64UrlSafe,
    );
    return '${serialize()}.$encodedSignature';
  }

  String sign({required List<int> key, JwtSupportedAlgorithm? alg}) {
    alg ??= header.alg;
    if (alg == null) {
      throw BuError(
        DefaultErrorType.invalidArgument,
        "Unknown signing algorithm.",
      );
    }
    final signingInput = serialize();

    final signInputBytes = StringUtils.encode(signingInput);
    List<int>? signature;
    switch (alg) {
      case JwtSupportedAlgorithm.eddsa:
        final signingKey = BaseEd25519PrivateKey.fromBytes(
          bytes: key.sublist(0, Ed25519KeysConst.privKeyByteLen),
          type: CryptoKeyType.ed25519,
        );
        final signer = ED25519Signer(signingKey);
        try {
          signature = signer.sign(signInputBytes).encoded;
        } finally {
          signingKey.sk.zero();
        }
        break;
      case JwtSupportedAlgorithm.hs256:
        signature = QuickCrypto.hmacsha256Hash(key, signInputBytes);
        break;
      case JwtSupportedAlgorithm.hs384:
        signature = QuickCrypto.hmacSha384Hash(key, signInputBytes);
        break;
      case JwtSupportedAlgorithm.hs512:
        signature = QuickCrypto.hmacSha512Hash(key, signInputBytes);
        break;
      case JwtSupportedAlgorithm.es256:
        final signingKey = Secp256r1PrivateKey.fromBytes(key);
        final signer = Secp256r1Signer(signingKey);
        try {
          signature =
              signer.sign(QuickCrypto.sha256Hash(signInputBytes)).encoded;
        } finally {
          signingKey.dispose();
        }
        break;
      case JwtSupportedAlgorithm.es384:
        final signingKey = Secp256r1PrivateKey.fromBytes(key);
        final signer = Secp256r1Signer(signingKey);
        try {
          signature =
              signer.sign(QuickCrypto.sha384Hash(signInputBytes)).encoded;
        } finally {
          signingKey.dispose();
        }
        break;
      case JwtSupportedAlgorithm.es512:
        final signingKey = Secp256r1PrivateKey.fromBytes(key);
        final signer = Secp256r1Signer(signingKey);
        try {
          signature =
              signer.sign(QuickCrypto.sha512Hash(signInputBytes)).encoded;
        } finally {
          signingKey.dispose();
        }
        break;
      case JwtSupportedAlgorithm.es256k:
        final signingKey = Secp256k1PrivateKey.fromBytes(key);
        final signer = Secp256k1Signer(signingKey);
        try {
          signature =
              signer.sign(QuickCrypto.sha256Hash(signInputBytes)).encoded;
        } finally {
          signingKey.dispose();
        }
        break;
    }
    final encodedSignature = StringUtils.decode(
      signature,
      b64NoPadding: true,
      encoding: StringEncoding.base64UrlSafe,
    );
    return '$signingInput.$encodedSignature';
  }
}
