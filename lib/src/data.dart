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

class JsonIntlData {
  JsonIntlData([this._debug = false]) : assert(_debug != null);

  final bool _debug;

  final Map<String, String> _localizedValues = <String, String>{};

  List<String> get keys => _localizedValues.keys.toList();

  void append(Map<String, dynamic> map) {
    map.forEach((String key, dynamic value) {
      _localizedValues[key] = value.toString();
    });
  }

  String translate(String key) {
    assert(_localizedValues.keys.contains(key), 'The key $key was not found');

    var value = _localizedValues[key];

    assert(() {
      if (_debug) {
        value = '[$key]($value)';
      }
      return true;
    }());

    return value;
  }

  String translateWithMap(String key, Map<String, dynamic> map) {
    assert(_localizedValues.keys.contains(key), 'The key $key was not found');

    final value = _localizedValues[key];
    var result =
        value.replaceAllMapped(RegExp(r'{{\s*(\w+)\s*}}'), (Match match) {
      final key = match.group(1);
      assert(map.containsKey(key), 'Value "$key" not found');
      var value = map[key].toString();

      assert(() {
        if (_debug) {
          value = '[$key]($value)';
        }
        return true;
      }());

      return value;
    });

    assert(() {
      if (_debug) {
        result = '[$key]($result)';
      }
      return true;
    }());

    return result;
  }
}
