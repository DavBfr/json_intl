/*
 * Copyright (C) 2019, David PHAM-VAN <dev.nfet.net@gmail.com>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:ui';

import 'json_intl_data.dart';
import 'json_intl_value.dart';
import 'mustache.dart';

class JsonIntlMockData implements JsonIntlData {
  const JsonIntlMockData();

  @override
  void append(Map<String, dynamic> map) {}

  @override
  List<String> get keys => const <String>[];

  @override
  String translate(String key) => key;

  @override
  String translateWithMap(
    String key, {
    Map<String, dynamic> map,
    Map<String, MustacheFilter> filters,
    num count,
    JsonIntlGender gender,
    int precision = 0,
    Locale locale,
  }) =>
      key;
}
