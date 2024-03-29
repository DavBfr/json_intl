// Copyright (c) 2020, David PHAM-VAN <dev.nfet.net@gmail.com>
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:simple_mustache/simple_mustache.dart';

import 'json_intl_data.dart';
import 'json_intl_value.dart';

// ignore_for_file: public_member_api_docs

class JsonIntlMockData implements JsonIntlData {
  const JsonIntlMockData();

  @override
  void append(Map<String, dynamic> map) {}

  @override
  void appendBuiltin(Map<Symbol, JsonIntlValue> map) {}

  @override
  List<Symbol> get keys => const <Symbol>[];

  @override
  String translate(Symbol key) => key.toString();

  @override
  String translateWithMap(
    Symbol key, {
    Map<String, dynamic>? map,
    Map<String, MustacheFilter>? filters,
    num? count,
    JsonIntlGender? gender,
    int precision = 0,
    String? locale,
    bool? strict,
  }) =>
      translate(key);

  @override
  String later(
    String text, {
    Map<String, dynamic>? map,
    Map<String, MustacheFilter>? filters,
    num? count,
    JsonIntlGender? gender,
    int precision = 0,
    String? locale,
    bool? strict,
  }) =>
      text;
}
