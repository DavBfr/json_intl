// Copyright (c) 2020, David PHAM-VAN <dev.nfet.net@gmail.com>
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: implementation_imports
// ignore_for_file: public_member_api_docs

import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:intl/src/plural_rules.dart' as plural_rules;
import 'package:simple_mustache/simple_mustache.dart';

import 'exception.dart';
import 'json_intl_value.dart';

class JsonIntlData {
  JsonIntlData([this._debug = false]);

  static String? _cachedPluralLocale;

  static plural_rules.PluralRule? _cachedPluralRule;

  final bool _debug;

  final _localizedValues = <Symbol, JsonIntlValue>{};

  List<Symbol> get keys => _localizedValues.keys.toList();

  void append(Map<String, dynamic> map) {
    map.forEach((String key, dynamic value) {
      _localizedValues[Symbol(key)] = JsonIntlValue.fromJson(value);
    });
  }

  void appendBuiltin(Map<Symbol, JsonIntlValue> map) {
    map.forEach((Symbol key, JsonIntlValue value) {
      _localizedValues[key] = value;
    });
  }

  String translate(Symbol key) {
    final message = _localizedValues[key];
    if (message == null) {
      if (_debug) {
        var debug = false;
        assert(() {
          debug = true;
          return true;
        }());
        if (debug) {
          return '[$key]!!';
        }
      }

      throw JsonIntlException('The translation key [$key] was not found');
    }

    var value = message.get(JsonIntlGender.neutral, JsonIntlPlural.other, null);
    if (value == null) {
      if (_debug) {
        var debug = false;
        assert(() {
          debug = true;
          return true;
        }());
        if (debug) {
          return '[$key]!!';
        }
      }

      throw JsonIntlException(
        'Unable to build a translation for [$key]\n  Gender: neutral\n  Plural: other',
      );
    }

    assert(() {
      if (_debug) {
        value = '[$key]($value)';
      }
      return true;
    }());

    return value!;
  }

  static plural_rules.PluralRule? _pluralRule(
    String? locale,
    num howMany,
    int precision,
  ) {
    plural_rules.startRuleEvaluation(howMany, precision);
    final verifiedLocale = Intl.verifiedLocale(
      locale,
      plural_rules.localeHasPluralRules,
      onFailure: (locale) => 'default',
    );
    if (_cachedPluralLocale == verifiedLocale) {
      return _cachedPluralRule;
    } else {
      _cachedPluralRule = plural_rules.pluralRules[verifiedLocale];
      _cachedPluralLocale = verifiedLocale;
      return _cachedPluralRule;
    }
  }

  String translateWithMap(
    Symbol key, {
    Map<String, dynamic>? map,
    Map<String, MustacheFilter>? filters,
    num? count,
    JsonIntlGender? gender,
    int precision = 0,
    String? locale,
    bool? strict,
  }) {
    map ??= <String, dynamic>{'count': count};
    final strictValue = strict ?? true;

    final mustache = Mustache(
      map: map,
      filters: filters ?? const <String, MustacheFilter>{},
      debug: _debug,
    );
    final message = _localizedValues[key];
    if (message == null) {
      if (_debug) {
        var debug = false;
        assert(() {
          debug = true;
          return true;
        }());
        if (debug) {
          return '[$key]!!';
        }
      }

      throw JsonIntlException('The translation key [$key] was not found');
    }

    var plural = JsonIntlPlural.other;
    JsonIntlPlural? direct;

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

    final value = message.get(gender, plural, strictValue ? null : direct);
    if (value == null) {
      if (_debug) {
        var debug = false;
        assert(() {
          debug = true;
          return true;
        }());
        if (debug) {
          return '[$key]!!';
        }
      }
      throw JsonIntlException(
        'Unable to build a translation for [$key]\n  Gender: $gender\n  Plural: $plural\n  Direct: $direct\n  Count: $count\n  Map: $map',
      );
    }

    var result = mustache.convert(value);

    assert(() {
      if (_debug) {
        result = '[$key]($result)';
      }
      return true;
    }());

    return result;
  }

  String later(
    String text, {
    Map<String, dynamic>? map,
    Map<String, MustacheFilter>? filters,
    num? count,
    JsonIntlGender? gender,
    int precision = 0,
    String? locale,
    bool? strict,
  }) {
    map ??= <String, dynamic>{'count': count};

    final mustache = Mustache(
      map: map,
      filters: filters ?? const <String, MustacheFilter>{},
      debug: _debug,
    );
    final message = text;

    final value = message;

    var result = mustache.convert(value);

    assert(() {
      if (_debug) {
        result = '[[$result]]';
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
      final k = entry.key.toString();
      s.write(json.encode(k.substring(8, k.length - 2)));
      s.write(':');
      s.write(entry.value.toString());
    }
    s.write('}');
    return s.toString();
  }
}
