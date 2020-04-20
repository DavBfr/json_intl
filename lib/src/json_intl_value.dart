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

import 'package:meta/meta.dart';

enum JsonIntlGender {
  male,
  female,
  neutral,
}

enum JsonIntlPlurial {
  zero,
  one,
  two,
  many,
  few,
  other,
}

@immutable
class JsonIntlValue {
  const JsonIntlValue(this._messages);

  factory JsonIntlValue.fromJson(dynamic message) {
    final map = <JsonIntlGender, Map<JsonIntlPlurial, String>>{};

    if (message is String) {
      map[JsonIntlGender.neutral] ??= <JsonIntlPlurial, String>{};
      map[JsonIntlGender.neutral][JsonIntlPlurial.other] = message;
    } else if (message is Map) {
      _loadGender(map, message);
    }

    return JsonIntlValue(map);
  }

  final Map<JsonIntlGender, Map<JsonIntlPlurial, String>> _messages;

  String get(JsonIntlGender gender, JsonIntlPlurial plurial) {
    final p = _messages[gender] ??
        _messages[JsonIntlGender.neutral] ??
        _messages[JsonIntlGender.male] ??
        _messages[JsonIntlGender.female];

    if (p == null) {
      return null;
    }

    if (p.containsKey(plurial)) {
      return p[plurial];
    }

    switch (plurial) {
      case JsonIntlPlurial.zero:
        return p[JsonIntlPlurial.few] ??
            p[JsonIntlPlurial.many] ??
            p[JsonIntlPlurial.other];
      case JsonIntlPlurial.one:
        return p[JsonIntlPlurial.other];
      case JsonIntlPlurial.two:
        return p[JsonIntlPlurial.few] ??
            p[JsonIntlPlurial.many] ??
            p[JsonIntlPlurial.other];
      case JsonIntlPlurial.many:
        return p[JsonIntlPlurial.other];
      case JsonIntlPlurial.few:
        return p[JsonIntlPlurial.many] ?? p[JsonIntlPlurial.other];
      default:
        return p[JsonIntlPlurial.few] ?? p[JsonIntlPlurial.many];
    }
  }

  static void _loadGender(Map map, Map<String, dynamic> message) {
    for (final key in message.keys) {
      switch (key) {
        case 'male':
          map[JsonIntlGender.male] ??= <JsonIntlPlurial, String>{};
          _loadPlurial(map[JsonIntlGender.male], message[key]);
          break;
        case 'female':
          map[JsonIntlGender.female] ??= <JsonIntlPlurial, String>{};
          _loadPlurial(map[JsonIntlGender.female], message[key]);
          break;
        case 'neutral':
          map[JsonIntlGender.neutral] ??= <JsonIntlPlurial, String>{};
          _loadPlurial(map[JsonIntlGender.neutral], message[key]);
          break;
        default:
          map[JsonIntlGender.neutral] ??= <JsonIntlPlurial, String>{};
          _loadPlurial(map[JsonIntlGender.neutral], message);
      }
    }
  }

  static void _loadPlurial(Map map, dynamic message) {
    if (message is String) {
      map[JsonIntlPlurial.other] = message;
      return;
    }

    for (final key in message.keys) {
      switch (key) {
        case 'zero':
          map[JsonIntlPlurial.zero] = message[key];
          break;
        case 'one':
          map[JsonIntlPlurial.one] = message[key];
          break;
        case 'two':
          map[JsonIntlPlurial.two] = message[key];
          break;
        case 'few':
          map[JsonIntlPlurial.few] = message[key];
          break;
        case 'many':
          map[JsonIntlPlurial.many] = message[key];
          break;
        default:
          map[JsonIntlPlurial.other] = message[key];
      }
    }
  }

  @override
  String toString() {
    var s = '{';
    _messages.forEach((key, value) {
      s += json.encode(key.toString().substring(15)) + ':{';
      value.forEach((key, value) {
        s += json.encode(key.toString().substring(16)) +
            ':' +
            json.encode(value) +
            ',';
      });
      s = s.substring(0, s.length - 1) + '},';
    });
    return s.substring(0, s.length - 1) + '}';
  }
}
