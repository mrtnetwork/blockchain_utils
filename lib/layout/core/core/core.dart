// The MIT License (MIT)
// Copyright (c) 2015-2018 Peter A. Bigot
// Copyright (c) 2023 Mohsen Haydari (MRTNETWORK)
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import 'package:blockchain_utils/layout/byte/byte_handler.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';

typedef LayoutFunc<T> = Layout<T> Function({String? property});
typedef ONFINALIZEDECODE<T, R extends LayoutRepository> =
    dynamic Function(
      T layoutResult,
      Map<String, dynamic> structResult,
      R? repository,
    );
typedef ONFINALIZEENCODE<T, R extends LayoutRepository> =
    void Function(T source, Map<String, dynamic> structSource, R? repository);

enum LayoutAction {
  encode,
  decode;

  bool get isEncode => this == encode;
  bool get isDecode => this == decode;
}

class RequestLayoutParams<R extends LayoutRepository> {
  final LayoutAction action;
  final Map<String, dynamic> sourceOrResult;
  final int remainBytes;
  final R? repository;
  const RequestLayoutParams({
    required this.action,
    required this.sourceOrResult,
    required this.remainBytes,
    required this.repository,
  });
}

typedef ConditionalLayoutFunc<T> =
    Layout<T> Function(String? property, RequestLayoutParams params);

abstract class LayoutRepository {}

abstract class BaseLazyStructLayoutBuilder<T, R extends LayoutRepository> {
  abstract final String? property;
  Layout<T> layout({
    required LayoutAction action,
    required Map<String, dynamic> sourceOrResult,
    required int remainBytes,
    R? repository,
  });
  dynamic onFinalizeDecode(
    T layoutResult,
    Map<String, dynamic> structResult,
    R? repository,
  ) => layoutResult;

  void onFinalizeEncode(
    T source,
    Map<String, dynamic> structSource,
    R? repository,
  ) {}
}

class LazyStructLayoutBuilder<T, R extends LayoutRepository>
    extends BaseLazyStructLayoutBuilder<T, R> {
  final ConditionalLayoutFunc<T> _layout;
  final ONFINALIZEDECODE<T, R>? finalizeDecode;
  final ONFINALIZEENCODE<T, R>? finalizeEncode;
  @override
  final String? property;
  LazyStructLayoutBuilder({
    required ConditionalLayoutFunc<T> layout,
    this.finalizeDecode,
    this.finalizeEncode,
    required this.property,
  }) : _layout = layout;

  @override
  Layout<T> layout({
    required LayoutAction action,
    required Map<String, dynamic> sourceOrResult,
    required int remainBytes,
    R? repository,
  }) {
    return _layout(
      property,
      RequestLayoutParams(
        action: action,
        sourceOrResult: sourceOrResult,
        repository: repository,
        remainBytes: remainBytes,
      ),
    );
  }

  @override
  dynamic onFinalizeDecode(
    T layoutResult,
    Map<String, dynamic> structResult,
    R? repository,
  ) {
    if (finalizeDecode == null) return layoutResult;
    return finalizeDecode!(layoutResult, structResult, repository);
  }

  @override
  void onFinalizeEncode(
    T source,
    Map<String, dynamic> structSource,
    R? repository,
  ) {
    if (finalizeEncode == null) return;
    {
      return finalizeEncode!(source, structSource, repository);
    }
  }
}

abstract class Layout<T> {
  final int span;
  final String? property;
  const Layout(this.span, {this.property});

  LayoutDecodeResult<T> decode(LayoutByteReader bytes, {int offset = 0});
  int encode(T source, LayoutByteWriter writer, {int offset = 0});
  int getSpan() => span;

  Layout clone({String? newProperty});
  List<int> serialize(T source) {
    final LayoutByteWriter data = LayoutByteWriter(span);
    final enc = encode(source, data);
    final encodeBytes = span > 0 ? data.toBytes() : data.sublist(0, enc);
    return encodeBytes;
  }

  String serializeHex(T source, {String? prefix}) {
    return BytesUtils.toHexString(serialize(source), prefix: prefix);
  }

  LayoutDecodeResult<T> deserialize(List<int> bytes, {int offset = 0}) {
    final reader = LayoutByteReader(bytes);
    final decodeBytes = decode(reader, offset: offset);
    return decodeBytes;
  }
}

typedef GetLayoutSpan = List<int> Function(int);

class LayoutDecodeResult<T> {
  final int consumed;
  final T value;
  const LayoutDecodeResult({required this.consumed, required this.value});
}
