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

// ignore_for_file: implementation_imports

import 'dart:convert';
import 'dart:ui';

import 'package:intl/intl.dart';
import 'package:intl/src/plural_rules.dart' as plural_rules;

import 'json_intl_value.dart';
import 'mustache.dart';

class JsonIntlData {
  JsonIntlData([this._debug = false]) : assert(_debug != null);

  static String _cachedPluralLocale;

  static plural_rules.PluralRule _cachedPluralRule;

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

  static plural_rules.PluralRule _pluralRule(
      String locale, num howMany, int precision) {
    plural_rules.startRuleEvaluation(howMany, precision);
    final verifiedLocale = Intl.verifiedLocale(
        locale, plural_rules.localeHasPluralRules,
        onFailure: (locale) => 'default');
    if (_cachedPluralLocale == verifiedLocale) {
      return _cachedPluralRule;
    } else {
      _cachedPluralRule = plural_rules.pluralRules[verifiedLocale];
      _cachedPluralLocale = verifiedLocale;
      return _cachedPluralRule;
    }
  }

  String translateWithMap(
    String key, {
    Map<String, dynamic> map,
    Map<String, MustacheFilter> filters,
    num count,
    JsonIntlGender gender,
    int precision = 0,
    Locale locale,
  }) {
    assert(_localizedValues.keys.contains(key), 'The key $key was not found');

    map ??= <String, dynamic>{'count': count};

    final mustache = Mustache(
      map: map,
      filters: filters ?? const <String, MustacheFilter>{},
      debug: _debug,
    );
    final message = _localizedValues[key];

    var plurial = JsonIntlPlurial.other;

    if (count != null) {
      final pluralRule = _pluralRule(locale?.toLanguageTag(), count, precision);
      if (pluralRule != null) {
        switch (pluralRule.call()) {
          case plural_rules.PluralCase.ZERO:
            plurial = JsonIntlPlurial.zero;
            break;
          case plural_rules.PluralCase.ONE:
            plurial = JsonIntlPlurial.one;
            break;
          case plural_rules.PluralCase.TWO:
            plurial = JsonIntlPlurial.two;
            break;
          case plural_rules.PluralCase.FEW:
            plurial = JsonIntlPlurial.few;
            break;
          case plural_rules.PluralCase.MANY:
            plurial = JsonIntlPlurial.many;
            break;
          case plural_rules.PluralCase.OTHER:
            plurial = JsonIntlPlurial.other;
            break;
        }
      }
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
