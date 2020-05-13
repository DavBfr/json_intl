// Copyright (c) 2020, David PHAM-VAN <dev.nfet.net@gmail.com>
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: implementation_imports
// ignore_for_file: public_member_api_docs

import 'dart:convert';

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
    var value = message.get(
      JsonIntlGender.neutral,
      JsonIntlPlural.other,
      null,
    );

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
    String locale,
    bool strict,
  }) {
    assert(_localizedValues.keys.contains(key), 'The key $key was not found');

    map ??= <String, dynamic>{'count': count};
    final _strict = strict ?? true;

    final mustache = Mustache(
      map: map,
      filters: filters ?? const <String, MustacheFilter>{},
      debug: _debug,
    );
    final message = _localizedValues[key];

    var plural = JsonIntlPlural.other;
    JsonIntlPlural direct;

    if (count != null) {
      if (count == 0) {
        direct = JsonIntlPlural.zero;
      } else if (count == 1) {
        direct = JsonIntlPlural.one;
      } else if (count == 2) {
        direct = JsonIntlPlural.two;
      }

      final pluralRule = _pluralRule(locale, count, precision);
      if (pluralRule != null) {
        switch (pluralRule.call()) {
          case plural_rules.PluralCase.ZERO:
            plural = JsonIntlPlural.zero;
            break;
          case plural_rules.PluralCase.ONE:
            plural = JsonIntlPlural.one;
            break;
          case plural_rules.PluralCase.TWO:
            plural = JsonIntlPlural.two;
            break;
          case plural_rules.PluralCase.FEW:
            plural = JsonIntlPlural.few;
            break;
          case plural_rules.PluralCase.MANY:
            plural = JsonIntlPlural.many;
            break;
          case plural_rules.PluralCase.OTHER:
            plural = JsonIntlPlural.other;
            break;
        }
      }
    }

    var result = mustache.convert(message.get(
      gender,
      plural,
      _strict ? null : direct,
    ));

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
    final s = StringBuffer('{');
    var first = true;
    for (final entry in _localizedValues.entries) {
      if (!first) {
        s.write(',');
      }
      first = false;
      s.write(json.encode(entry.key));
      s.write(':');
      s.write(entry.value.toString());
    }
    s.write('}');
    return s.toString();
  }
}
