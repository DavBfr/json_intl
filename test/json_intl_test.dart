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

import 'package:flutter_test/flutter_test.dart';
import 'package:json_intl/src/json_intl_data.dart';
import 'package:json_intl/src/json_intl_value.dart';
import 'package:json_intl/src/mustache.dart';

void main() {
  JsonIntlData data;
  final map = <String, dynamic>{
    'num': 123,
  };

  final fn = <String, MustacheFilter>{
    'tr': (dynamic value) => '"$value"',
  };

  setUpAll(() {
    data = JsonIntlData();
    data.append(<String, dynamic>{
      'key1': 'value',
      'key2': 'value {{ num }}',
      'key3': 'value {{ num | tr }}',
      'key4': <String, dynamic>{
        'zero': 'no value',
        'one': 'one value',
        'two': 'two values',
        'many': 'many values',
        'few': 'few values',
        'other': 'other values',
      },
      'key5': <String, dynamic>{
        'one': 'one value',
        'many': '{{ count }} values',
      },
      'key6': <String, dynamic>{
        'male': 'the boy',
        'female': 'the girl',
        'other': 'the child',
      },
      'key7': <String, dynamic>{
        'male': {
          'one': 'the boy',
          'many': '{{count}} boys',
        },
        'female': {
          'one': 'the girl',
          'many': '{{count}} girls',
        },
        'neutral': {
          'one': 'the child',
          'many': '{{ count}} children',
        }
      },
    });
  });

  test('Simple translation', () {
    expect(data.translate('key1'), 'value');
    expect(data.translate('key2'), 'value {{ num }}');
  });

  test('Map translation', () {
    expect(data.translateWithMap('key1', map, null, null, null), 'value');
    expect(data.translateWithMap('key2', map, null, null, null), 'value 123');
  });

  test('Filter translation', () {
    expect(data.translateWithMap('key1', map, fn, null, null), 'value');
    expect(data.translateWithMap('key2', map, fn, null, null), 'value 123');
    expect(data.translateWithMap('key3', map, fn, null, null), 'value "123"');
  });

  test('Plurial translation', () {
    expect(data.translateWithMap('key4', map, fn, 0, null), 'no value');
    expect(data.translateWithMap('key4', map, fn, 1, null), 'one value');
    expect(data.translateWithMap('key4', map, fn, 2, null), 'two values');
    expect(data.translateWithMap('key4', map, fn, 3, null), 'few values');
    expect(data.translateWithMap('key4', map, fn, 10, null), 'many values');
    expect(data.translateWithMap('key4', map, fn, -1, null), 'other values');
  });

  test('Plurial translation limited', () {
    expect(data.translateWithMap('key5', null, null, 0, null), '0 values');
    expect(data.translateWithMap('key5', null, null, 1, null), 'one value');
    expect(data.translateWithMap('key5', null, null, 2, null), '2 values');
    expect(data.translateWithMap('key5', null, null, 3, null), '3 values');
    expect(data.translateWithMap('key5', null, null, 10, null), '10 values');
    expect(data.translateWithMap('key5', null, null, -1, null), '-1 values');
  });

  test('Gender translation', () {
    expect(data.translateWithMap('key6', null, null, null, null), 'the child');
    expect(data.translateWithMap('key6', null, null, null, JsonIntlGender.male),
        'the boy');
    expect(
        data.translateWithMap('key6', null, null, null, JsonIntlGender.female),
        'the girl');
  });

  test('Gender and plurial translation', () {
    expect(
        data.translateWithMap('key7', null, null, null, null), 'null children');
    expect(data.translateWithMap('key7', null, null, 1, null), 'the child');
    expect(data.translateWithMap('key7', null, null, 2, null), '2 children');
    expect(data.translateWithMap('key7', null, null, 1, JsonIntlGender.male),
        'the boy');
    expect(data.translateWithMap('key7', null, null, 1, JsonIntlGender.female),
        'the girl');
    expect(data.translateWithMap('key7', null, null, 2, JsonIntlGender.male),
        '2 boys');
    expect(data.translateWithMap('key7', null, null, 2, JsonIntlGender.female),
        '2 girls');
  });
}
