import 'package:blockchain_utils/encoding/proto/codec/decoder.dart';
import 'package:blockchain_utils/encoding/proto/types/types.dart';
import 'package:blockchain_utils/utils/json/json.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Protocol Buffers - Google's data interchange format
/// Copyright 2008 Google Inc.  All rights reserved.
/// https://developers.google.com/protocol-buffers/
///
/// Redistribution and use in source and binary forms, with or without
/// modification, are permitted provided that the following conditions are
/// met:
///
/// * Redistributions of source code must retain the above copyright
/// notice, this list of conditions and the following disclaimer.
/// * Redistributions in binary form must reproduce the above
/// copyright notice, this list of conditions and the following disclaimer
/// in the documentation and/or other materials provided with the
/// distribution.
/// * Neither the name of Google Inc. nor the names of its
/// contributors may be used to endorse or promote products derived from
/// this software without specific prior written permission.
///
/// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
/// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
/// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
/// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
/// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
/// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
/// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
/// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
/// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
/// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
/// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
/// `Any` contains an arbitrary serialized protocol buffer message along with a
/// URL that describes the type of the serialized message.
///
/// Protobuf library provides support to pack/unpack Any values in the form
/// of utility functions or additional generated methods of the Any type.
///
/// Example 1: Pack and unpack a message in C++.
///
/// Foo foo = ...;
/// Any any;
/// any.PackFrom(foo);
/// ...
/// if (any.UnpackTo(&amp;foo)) {
/// ...
/// }
///
/// Example 2: Pack and unpack a message in Java.
///
/// Foo foo = ...;
/// Any any = Any.pack(foo);
/// ...
/// if (any.is(Foo.class)) {
/// foo = any.unpack(Foo.class);
/// }
/// // or ...
/// if (any.isSameTypeAs(Foo.getDefaultInstance())) {
/// foo = any.unpack(Foo.getDefaultInstance());
/// }
///
/// Example 3: Pack and unpack a message in Python.
///
/// foo = Foo(...)
/// any = Any()
/// any.Pack(foo)
/// ...
/// if any.Is(Foo.DESCRIPTOR):
/// any.Unpack(foo)
/// ...
///
/// Example 4: Pack and unpack a message in Go
///
/// foo := &amp;pb.Foo{...}
/// any, err := anypb.New(foo)
/// if err != nil {
/// ...
/// }
/// ...
/// foo := &amp;pb.Foo{}
/// if err := any.UnmarshalTo(foo); err != nil {
/// ...
/// }
///
/// The pack methods provided by protobuf library will by default use
/// 'type.googleapis.com/full.type.name' as the type URL and the unpack
/// methods only use the fully qualified type name after the last '/'
/// in the type URL, for example "foo.bar.com/x/y.z" will yield type
/// name "y.z".
///
/// JSON
/// ====
/// The JSON representation of an `Any` value uses the regular
/// representation of the deserialized, embedded message, with an
/// additional field `@type` which contains the type URL. Example:
///
/// package google.profile;
/// message Person {
/// string first_name = 1;
/// string last_name = 2;
/// }
///
/// {
/// "@type": "type.googleapis.com/google.profile.Person",
/// "firstName": &lt;string&gt;,
/// "lastName": &lt;string&gt;
/// }
///
/// If the embedded message type is well-known and has a custom JSON
/// representation, that representation will be embedded adding a field
/// `value` which holds the custom JSON in addition to the `@type`
/// field. Example (for message [google.protobuf.Duration][]):
///
/// {
/// "@type": "type.googleapis.com/google.protobuf.Duration",
/// "value": "1.212s"
/// }
///
class ProtoGoogleAny extends IProtoMessage {
  /// A URL/resource name that uniquely identifies the type of the serialized
  /// protocol buffer message. This string must contain at least
  /// one "/" character. The last segment of the URL's path must represent
  /// the fully qualified name of the type (as in
  /// `path/google.protobuf.Duration`). The name should be in a canonical form
  /// (e.g., leading "." is not accepted).
  ///
  /// In practice, teams usually precompile into the binary all types that they
  /// expect it to use in the context of Any. However, for URLs which use the
  /// scheme `http`, `https`, or no scheme, one can optionally set up a type
  /// server that maps type URLs to message definitions as follows:
  ///
  /// * If no scheme is provided, `https` is assumed.
  /// * An HTTP GET on the URL must yield a [google.protobuf.Type][]
  /// value in binary format, or produce an error.
  /// * Applications are allowed to cache lookup results based on the
  /// URL, or have them precompiled into a binary to avoid any
  /// lookup. Therefore, binary compatibility needs to be preserved
  /// on changes to types. (Use versioned type names to manage
  /// breaking changes.)
  ///
  /// Note: this functionality is not currently available in the official
  /// protobuf release, and it is not used for type URLs beginning with
  /// type.googleapis.com. As of May 2023, there are no widely used type server
  /// implementations and no plans to implement one.
  ///
  /// Schemes other than `http`, `https` (or the empty scheme) might be
  /// used with implementation specific semantics.
  ///
  final String typeUrl;

  /// Must be a valid serialized protocol buffer of the above specified type.
  final Object? value;
  final bool isBinary;

  const ProtoGoogleAny._({
    required this.typeUrl,
    this.value,
    required this.isBinary,
  });

  factory ProtoGoogleAny.binary(String typeUrl, List<int> bytes) {
    return ProtoGoogleAny._(typeUrl: typeUrl, value: bytes, isBinary: true);
  }
  factory ProtoGoogleAny.json(String typeUrl, Map<String, dynamic> value) {
    return ProtoGoogleAny._(typeUrl: typeUrl, value: value, isBinary: false);
  }

  @override
  ProtoMessageConfig protoConfig() => protoConfigStatic();

  static ProtoMessageConfig protoConfigStatic() {
    return ProtoMessageConfig(
      syntax: ProtoSyntax.v3,
      options: const [],
      fields: [ProtoFieldConfig.string(1), ProtoFieldConfig.bytes(2)],
    );
  }

  @override
  BuBytes toBuffer() {
    if (!isBinary) {
      throw BuError(DefaultErrorType.invalidArgument,
        "Cannot encode Any to protobuf bytes because its value is not binary.",
      );
    }
    return super.toBuffer();
  }

  @override
  List<Object?> get protoValues => [typeUrl, value];

  @override
  Map<String, dynamic> toJson({
    ProtoJsonConfig config = DefaultProtoJsonConfig.defaultConfig,
  }) {
    if (isBinary) {
      return {
        '@type': typeUrl,
        "value": config.encodeBinary(JsonParser.valueAsBytes(value)),
      };
    }
    final v = value;
    return {'@type': typeUrl, if (v case Map()) ...v};
  }

  factory ProtoGoogleAny.fromJson(
    Map<String, dynamic> json, {
    ProtoJsonConfig config = DefaultProtoJsonConfig.defaultConfig,
  }) {
    String key = json.hasValue("type_url") ? "type_url" : "@type";
    final String typeUrl = json.valueAsString<String>(key);
    final value = Map<String, dynamic>.from(json)
      ..removeWhere((k, v) => k == key);
    List<int>? decode;
    if (value.length == 1 && value.hasValue("value")) {
      try {
        decode = value.valueAsBytes("value", encoding: config.binaryEncoding);
      } catch (_) {}
    }
    bool isBinary = decode != null;
    return ProtoGoogleAny._(
      typeUrl: typeUrl,
      value: decode ?? value,
      isBinary: isBinary,
    );
  }

  factory ProtoGoogleAny.deserialize(List<int> bytes) {
    final decode = ProtoBufferDecoder.decode(
      bytes: bytes,
      messageConfig: protoConfigStatic(),
    );
    return ProtoGoogleAny._(
      typeUrl: decode.getString<String>(1),
      value: decode.getBytes<List<int>?>(2),
      isBinary: true,
    );
  }
}
