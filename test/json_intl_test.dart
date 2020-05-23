// Copyright (c) 2020, David PHAM-VAN <dev.nfet.net@gmail.com>
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:json_intl/src/json_intl_data.dart';
import 'package:json_intl/src/json_intl_value.dart';
import 'package:simple_mustache/simple_mustache.dart';

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

  test('Export translations', () {
    var file = File('test/data/strings.json');
    if (!file.existsSync()) {
      file = File('data/strings.json');
    }

    final json = data.toString();
    expect(json, file.readAsStringSync());
    file.writeAsStringSync(json);
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

  test('Plural translation ar_AR', () {
    const locale = 'ar-AR';
    expect(
        data.translateWithMap('key4',
            map: map, filters: fn, count: 0, locale: locale),
        'no value');
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

  test('Plural translation en_US', () {
    const locale = 'en-US';
    expect(
        data.translateWithMap('key4',
            map: map, filters: fn, count: 0, locale: locale),
        'other values');
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

  test('Plural translation en_US relaxed', () {
    const locale = 'en-US';
    expect(
        data.translateWithMap('key4',
            map: map, filters: fn, count: 0, locale: locale, strict: false),
        'no value');
    expect(
        data.translateWithMap('key4',
            map: map, filters: fn, count: 1, locale: locale, strict: false),
        'one value');
    expect(
        data.translateWithMap('key4',
            map: map, filters: fn, count: 2, locale: locale, strict: false),
        'two values');
    expect(
        data.translateWithMap('key4',
            map: map, filters: fn, count: 3, locale: locale, strict: false),
        'other values');
    expect(
        data.translateWithMap('key4',
            map: map, filters: fn, count: 100, locale: locale, strict: false),
        'other values');
    expect(
        data.translateWithMap('key4',
            map: map, filters: fn, count: -1, locale: locale, strict: false),
        'other values');
  });

  test('Plural translation limited', () {
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

  test('Gender and plural translation', () {
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
