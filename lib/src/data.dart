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
  final Map<String, String> _localizedValues = <String, String>{};

  List<String> get keys => _localizedValues.keys.toList();

  void append(Map<String, dynamic> map) {
    map.forEach((String key, dynamic value) {
      _localizedValues[key] = value.toString();
    });
  }

  String translate(String key) {
    if (!_localizedValues.containsKey(key)) {
      return key;
    }

    return _localizedValues[key];
  }

  String translateWithMap(String key, Map<String, dynamic> map) {
    if (!_localizedValues.containsKey(key)) {
      return key;
    }

    final value = _localizedValues[key];
    return value.replaceAllMapped(RegExp(r'{{\s*(\w+)\s*}}'), (Match match) {
      if (map.containsKey(match.group(1))) {
        return map[match.group(1)].toString();
      }
      assert(false, 'Value "${match.group(1)}" not found');
      return '"${match.group(1)}"';
    });
  }
}
