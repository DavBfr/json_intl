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

import 'package:flutter/widgets.dart';

import 'json_intl_data.dart';
import 'json_intl_mock_data.dart';
import 'json_intl_value.dart';
import 'mustache.dart';

class JsonIntl {
  const JsonIntl(this.locale, this._data);

  final Locale locale;

  final JsonIntlData _data;

  static const mock = JsonIntl(Locale('en', 'US'), JsonIntlMockData());

  static JsonIntl of(BuildContext context) {
    return Localizations.of<JsonIntl>(context, JsonIntl) ?? mock;
  }

  String get(
    String key, [
    Map<String, dynamic> map,
    Map<String, MustacheFilter> filters,
  ]) {
    if (map == null) {
      return _data.translate(key);
    }

    return _data.translateWithMap(key, map, filters, null, null);
  }

  String count(
    num value,
    String key, [
    Map<String, dynamic> map,
    Map<String, MustacheFilter> filters,
  ]) {
    return _data.translateWithMap(key, map, filters, value, null);
  }

  String gender(
    JsonIntlGender gender,
    String key, [
    Map<String, dynamic> map,
    Map<String, MustacheFilter> filters,
  ]) {
    return _data.translateWithMap(key, map, filters, null, gender);
  }

  String genderCount(
    JsonIntlGender gender,
    int count,
    String key, [
    Map<String, dynamic> map,
    Map<String, MustacheFilter> filters,
  ]) {
    return _data.translateWithMap(key, map, filters, count, gender);
  }
}
