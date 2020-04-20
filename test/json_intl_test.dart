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

import 'dart:ui';

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
          'one': 'a boy',
          'many': '{{count}} boys',
        },
        'female': {
          'one': 'a girl',
          'many': '{{count }} girls',
        },
        'neutral': {
          'one': 'a child',
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
    expect(data.translateWithMap('key1', map: map), 'value');
    expect(data.translateWithMap('key2', map: map), 'value 123');
  });

  test('Filter translation', () {
    expect(data.translateWithMap('key1', map: map, filters: fn), 'value');
    expect(data.translateWithMap('key2', map: map, filters: fn), 'value 123');
    expect(data.translateWithMap('key3', map: map, filters: fn), 'value "123"');
  });

  test('Plurial translation ar_AR', () {
    const locale = Locale('ar', 'AR');
    expect(
      data.translateWithMap('key4',
          map: map, filters: fn, count: 0, locale: locale),
      'no value',
    );
    expect(
        data.translateWithMap('key4',
            map: map, filters: fn, count: 1, locale: locale),
        'one value');
    expect(
        data.translateWithMap('key4',
            map: map, filters: fn, count: 2, locale: locale),
        'two values');
    expect(
        data.translateWithMap('key4',
            map: map, filters: fn, count: 3, locale: locale),
        'few values');
    expect(
        data.translateWithMap('key4',
            map: map, filters: fn, count: 100, locale: locale),
        'other values');
    expect(
        data.translateWithMap('key4',
            map: map, filters: fn, count: -1, locale: locale),
        'many values');
  });

  test('Plurial translation en_US', () {
    const locale = Locale('en', 'US');
    expect(
      data.translateWithMap('key4',
          map: map, filters: fn, count: 0, locale: locale),
      'other values',
    );
    expect(
        data.translateWithMap('key4',
            map: map, filters: fn, count: 1, locale: locale),
        'one value');
    expect(
        data.translateWithMap('key4',
            map: map, filters: fn, count: 2, locale: locale),
        'other values');
    expect(
        data.translateWithMap('key4',
            map: map, filters: fn, count: 3, locale: locale),
        'other values');
    expect(
        data.translateWithMap('key4',
            map: map, filters: fn, count: 100, locale: locale),
        'other values');
    expect(
        data.translateWithMap('key4',
            map: map, filters: fn, count: -1, locale: locale),
        'other values');
  });

  test('Plurial translation limited', () {
    expect(data.translateWithMap('key5', count: 0), '0 values');
    expect(data.translateWithMap('key5', count: 1), 'one value');
    expect(data.translateWithMap('key5', count: 2), '2 values');
    expect(data.translateWithMap('key5', count: 3), '3 values');
    expect(data.translateWithMap('key5', count: 10), '10 values');
    expect(data.translateWithMap('key5', count: -1), '-1 values');
  });

  test('Gender translation', () {
    expect(data.translateWithMap('key6'), 'the child');
    expect(
        data.translateWithMap('key6', gender: JsonIntlGender.male), 'the boy');
    expect(data.translateWithMap('key6', gender: JsonIntlGender.female),
        'the girl');
  });

  test('Gender and plurial translation', () {
    expect(data.translateWithMap('key7'), 'null children');
    expect(data.translateWithMap('key7', count: 1), 'a child');
    expect(data.translateWithMap('key7', count: 2), '2 children');
    expect(data.translateWithMap('key7', count: 1, gender: JsonIntlGender.male),
        'a boy');
    expect(
        data.translateWithMap('key7', count: 1, gender: JsonIntlGender.female),
        'a girl');
    expect(data.translateWithMap('key7', count: 2, gender: JsonIntlGender.male),
        '2 boys');
    expect(
        data.translateWithMap('key7', count: 2, gender: JsonIntlGender.female),
        '2 girls');
  });
}
