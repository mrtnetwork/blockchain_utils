/*
The MIT License (MIT)
Copyright (c) 2015-2018 Peter A. Bigot
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
The 3-Clause BSD License
 */
/* 
  Copyright (c) 2023 Mohsen Haydari (MRTNETWORK)
  All rights reserved.

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are met:

  1. Redistributions of source code must retain the above copyright notice, this
     list of conditions, and the following disclaimer.
  2. Redistributions in binary form must reproduce the above copyright notice, this
     list of conditions, and the following disclaimer in the documentation and/or
     other materials provided with the distribution.
  3. Neither the name of the [organization] nor the names of its contributors may be
     used to endorse or promote products derived from this software without
     specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
  IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
  INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
  BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
  OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
  OF THE POSSIBILITY OF SUCH DAMAGE.
*/

import 'package:blockchain_utils/layout/byte/byte_handler.dart';
import 'package:blockchain_utils/layout/exception/exception.dart';

typedef LayoutFunc<T> = Layout<T> Function({String? property});

enum LayoutAction { span, encode, decode }

typedef ConditionalLayoutFunc<T> = Layout<T> Function(
    {String? property,
    required T? sourceOrResult,
    required LayoutAction action,
    required int remindBytes});

abstract class BaseLazyLayout<T> {
  abstract final String? property;
  Layout<T> layout(
      {required LayoutAction action,
      required T? sourceOrResult,
      required int remindBytes});
}

class LazyLayout<T> extends BaseLazyLayout<T> {
  final LayoutFunc<T> _layout;
  // final ConditionalLayoutFunc<T> layout;
  @override
  final String? property;
  LazyLayout({
    required LayoutFunc<T> layout,
    required this.property,
  }) : _layout = layout;
  @override
  Layout<T> layout(
      {required LayoutAction action,
      required T? sourceOrResult,
      required int remindBytes}) {
    return _layout(property: property);
  }
}

class ConditionalLazyLayout<T> extends BaseLazyLayout<T> {
  final ConditionalLayoutFunc<T> _layout;
  @override
  final String? property;
  ConditionalLazyLayout(
      {required ConditionalLayoutFunc<T> layout, required this.property})
      : _layout = layout;

  @override
  Layout<T> layout(
      {required LayoutAction action,
      required T? sourceOrResult,
      required int remindBytes}) {
    assert(action == LayoutAction.span || sourceOrResult != null,
        "source cannot be null in ${action.name}");
    return _layout(
        property: property,
        action: action,
        sourceOrResult: sourceOrResult,
        remindBytes: remindBytes);
  }
}

/// Base class for layout objects.
///
/// **NOTE:** This is an abstract base class; you can create instances if it amuses you,
/// but they won't support the [encode] or [decode] functions.
///
/// - [span] : Initializer for [span]. The parameter must be an integer;
/// a negative value signifies that the span is [value-specific].
/// - [property] (optional): Initializer for [property].
abstract class Layout<T> {
  final int span;
  final String? property;
  const Layout(this.span, {this.property});

  LayoutDecodeResult<T> decode(LayoutByteReader bytes, {int offset = 0});
  int encode(T source, LayoutByteWriter writer, {int offset = 0});
  int getSpan(LayoutByteReader? bytes, {int offset = 0, T? source}) {
    if (span < 0) {
      throw LayoutException("Invalid layout span.",
          details: {"property": property, "span": span});
    }
    return span;
  }

  Layout clone({String? newProperty});
  List<int> serialize(T source) {
    final LayoutByteWriter data = LayoutByteWriter(span);
    final enc = encode(source, data);
    final encodeBytes = span > 0 ? data.toBytes() : data.sublist(0, enc);
    return encodeBytes;
  }

  LayoutDecodeResult<T> deserialize(List<int> bytes) {
    final reader = LayoutByteReader(bytes);
    final decodeBytes = decode(reader);
    return decodeBytes;
  }
}

typedef GetLayoutSpan = List<int> Function(int);

class LayoutDecodeResult<T> {
  final int consumed;
  final T value;
  const LayoutDecodeResult({required this.consumed, required this.value});
}
