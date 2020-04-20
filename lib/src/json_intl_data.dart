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

import 'dart:convert';

import 'json_intl_value.dart';
import 'mustache.dart';

class JsonIntlData {
  JsonIntlData([this._debug = false]) : assert(_debug != null);

  final bool _debug;

  final Map<String, JsonIntlValue> _localizedValues = <String, JsonIntlValue>{};

  List<String> get keys => _localizedValues.keys.toList();

  void append(Map<String, dynamic> map) {
    map.forEach((String key, dynamic value) {
      _localizedValues[key] = JsonIntlValue.fromJson(value);
    });
  }

  String translate(String key) {
    assert(_localizedValues.keys.contains(key), 'The key $key was not found');

    final message = _localizedValues[key];
    var value = message.get(JsonIntlGender.neutral, JsonIntlPlurial.other);

    assert(() {
      if (_debug) {
        value = '[$key]($value)';
      }
      return true;
    }());

    return value;
  }

  String translateWithMap(
    String key,
    Map<String, dynamic> map,
    Map<String, MustacheFilter> filters,
    num count,
    JsonIntlGender gender,
  ) {
    assert(_localizedValues.keys.contains(key), 'The key $key was not found');

    map ??= <String, dynamic>{'count': count};

    final mustache = Mustache(
      map: map,
      filters: filters ?? const <String, MustacheFilter>{},
      debug: _debug,
    );
    final message = _localizedValues[key];

    JsonIntlPlurial plurial;
    if (count == null) {
      plurial = JsonIntlPlurial.other;
    } else if (count == 0) {
      plurial = JsonIntlPlurial.zero;
    } else if (count == 1) {
      plurial = JsonIntlPlurial.one;
    } else if (count == 2) {
      plurial = JsonIntlPlurial.two;
    } else if (count > 0 && count < 10) {
      plurial = JsonIntlPlurial.few;
    } else if (count < 0) {
      plurial = JsonIntlPlurial.other;
    } else {
      plurial = JsonIntlPlurial.many;
    }

    var result = mustache.convert(message.get(gender, plurial));

    assert(() {
      if (_debug) {
        result = '[$key]($result)';
      }
      return true;
    }());

    return result;
  }

  @override
  String toString() {
    var s = '{';
    _localizedValues.forEach((key, value) {
      s += json.encode(key) + ':' + value.toString() + ',';
    });
    return s.substring(0, s.length - 1) + '}';
  }
}
