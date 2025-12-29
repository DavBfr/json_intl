// Copyright (c) 2020, David PHAM-VAN <dev.nfet.net@gmail.com>
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:meta/meta.dart';

/// Type of gender to use
enum JsonIntlGender {
  /// male gender, like 'a boy'
  male,

  /// female gender, like 'a girl'
  female,

  /// neutral gender, like 'a kid'
  neutral,
}

/// Type of Plural to use as [count]
enum JsonIntlPlural {
  /// count is 0
  zero,

  /// count is 1
  one,

  /// count is 2
  two,

  /// count is more than 2
  few,

  /// count is more than a few
  many,

  /// count is any other value
  other,
}

/// Represents a translated string with all variations
@immutable
class JsonIntlValue {
  /// Create a translated string from a map
  const JsonIntlValue(this._messages);

  /// Create a translated string from a json object
  factory JsonIntlValue.fromJson(dynamic message) {
    final map = <JsonIntlGender, Map<JsonIntlPlural, String>>{};

    if (message is String) {
      map[JsonIntlGender.neutral] ??= <JsonIntlPlural, String>{};
      map[JsonIntlGender.neutral]![JsonIntlPlural.other] = message;
    } else if (message is Map<String, dynamic>) {
      _loadGender(map, message);
    }

    return JsonIntlValue(map);
  }

  final Map<JsonIntlGender, Map<JsonIntlPlural, String>> _messages;

  /// Get the right translated string variant depending on a gender and a count
  String? get(
    JsonIntlGender? gender,
    JsonIntlPlural plural,
    JsonIntlPlural? direct,
  ) {
    final p =
        _messages[gender] ??
        _messages[JsonIntlGender.neutral] ??
        _messages[JsonIntlGender.male] ??
        _messages[JsonIntlGender.female];

    if (p == null) {
      return null;
    }

    if (direct != null && p.containsKey(direct)) {
      return p[direct];
    }

    if (p.containsKey(plural)) {
      return p[plural];
    }

    switch (plural) {
      case JsonIntlPlural.zero:
        return p[JsonIntlPlural.few] ??
            p[JsonIntlPlural.many] ??
            p[JsonIntlPlural.other];
      case JsonIntlPlural.one:
        return p[JsonIntlPlural.other];
      case JsonIntlPlural.two:
        return p[JsonIntlPlural.few] ??
            p[JsonIntlPlural.many] ??
            p[JsonIntlPlural.other];
      case JsonIntlPlural.many:
        return p[JsonIntlPlural.other];
      case JsonIntlPlural.few:
        return p[JsonIntlPlural.many] ?? p[JsonIntlPlural.other];
      default:
        return p[JsonIntlPlural.few] ?? p[JsonIntlPlural.many];
    }
  }

  static void _loadGender(
    Map<dynamic, dynamic> map,
    Map<String, dynamic> message,
  ) {
    for (final key in message.keys) {
      switch (key) {
        case 'male':
          map[JsonIntlGender.male] ??= <JsonIntlPlural, String>{};
          _loadPlural(map[JsonIntlGender.male], message[key]);
          break;
        case 'female':
          map[JsonIntlGender.female] ??= <JsonIntlPlural, String>{};
          _loadPlural(map[JsonIntlGender.female], message[key]);
          break;
        case 'neutral':
          map[JsonIntlGender.neutral] ??= <JsonIntlPlural, String>{};
          _loadPlural(map[JsonIntlGender.neutral], message[key]);
          break;
        default:
          map[JsonIntlGender.neutral] ??= <JsonIntlPlural, String>{};
          _loadPlural(map[JsonIntlGender.neutral], message);
      }
    }
  }

  static void _loadPlural(Map<dynamic, dynamic> map, dynamic message) {
    if (message is String) {
      map[JsonIntlPlural.other] = message;
      return;
    }

    for (final key in message.keys) {
      switch (key) {
        case 'zero':
          map[JsonIntlPlural.zero] = message[key];
          break;
        case 'one':
          map[JsonIntlPlural.one] = message[key];
          break;
        case 'two':
          map[JsonIntlPlural.two] = message[key];
          break;
        case 'few':
          map[JsonIntlPlural.few] = message[key];
          break;
        case 'many':
          map[JsonIntlPlural.many] = message[key];
          break;
        default:
          map[JsonIntlPlural.other] = message[key];
      }
    }
  }

  @override
  String toString() {
    final s = StringBuffer('{');
    var first = true;
    for (final entry in _messages.entries) {
      if (!first) {
        s.write(',');
      }
      first = false;
      s.write(json.encode(entry.key.toString().substring(15)));
      s.write(':{');
      var subFirst = true;
      for (final entry in entry.value.entries) {
        if (!subFirst) {
          s.write(',');
        }
        subFirst = false;
        s.write(json.encode(entry.key.toString().substring(15)));
        s.write(':');
        s.write(json.encode(entry.value));
      }
      s.write('}');
    }
    s.write('}');
    return s.toString();
  }
}
