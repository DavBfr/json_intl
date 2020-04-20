/*
 * Copyright (C) 2019, David PHAM-VAN <dev.nfet.net@gmail.com>
 *
 * Licensed under the Apache License, Version 2.0 (the 'License');
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an 'AS IS' BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

// implements a part of the specification: https://mustache.github.io/mustache.5.html

import 'dart:convert';

import 'package:meta/meta.dart';

typedef MustacheFilter = dynamic Function(dynamic value);

class Mustache extends Converter<String, String> {
  Mustache({
    this.map = const <String, dynamic>{},
    this.filters = const <String, MustacheFilter>{},
    @required this.debug,
  })  : assert(map != null),
        assert(filters != null),
        assert(debug != null);

  final Map<String, dynamic> map;

  final Map<String, MustacheFilter> filters;

  final bool debug;

  final _mustache =
      RegExp(r'({{\s*([#/^]?) *([\w\d_]*)\s*\|?\s*([\w\d\s_\|]*)}})');

  final _filter = RegExp(r'([\w\d_]+)\s*\|?\s*');

  dynamic _applyFilters(dynamic value, List<String> _filters) {
    if (_filters.isEmpty) {
      return value;
    }

    for (final filter in _filters) {
      assert(filters.containsKey(filter), 'filter $filter not found');
      value = filters[filter](value);
      assert(() {
        if (debug) {
          value = '$filter($value)';
        }
        return true;
      }());
    }

    return value;
  }

  @override
  String convert(String input) {
    final output = StringBuffer();
    var start = 0;
    var eat = false;
    var eatField = '';
    final context = <String, dynamic>{};
    var inputLoop = 0;
    var array = <dynamic>[];
    final _map = <String, dynamic>{};
    _map.addAll(map);

    for (final m in _mustache.allMatches(input)) {
      final modifier = m.group(2);
      final field = m.group(3);
      final _filters = <String>[];

      if (m.group(4).isNotEmpty) {
        for (final n in _filter.allMatches(m.group(4))) {
          _filters.add(n.group(1));
        }
      }

      // end tag
      if (modifier == '/') {
        if (!eat) {
          output.write(input.substring(start, m.start));
          if (array.isNotEmpty) {
            start = inputLoop;
            _map.clear();
            _map.addAll(context);
            _map.addAll(array.first);
            array.removeAt(0);
            continue;
          }
          _map.clear();
          _map.addAll(context);
        }
        if (eatField == field) {
          eat = false;
          eatField = '';
        }

        start = m.end;
        continue;
      }

      if (eat) {
        start = m.end;
        continue;
      }

      // start tag
      if (modifier == '#') {
        output.write(input.substring(start, m.start));
        if (_map.containsKey(field)) {
          final dynamic value = _map[field];
          if (value is bool) {
            eat = !value;
          } else {
            eat = false;
          }
          if (value is List) {
            context.clear();
            context.addAll(_map);
            array = value;
            _map.clear();
            _map.addAll(context);
            _map.addAll(array.first);
            array.removeAt(0);
            inputLoop = m.end;
          }
        } else {
          eat = true;
        }
        eatField = field;
        start = m.end;
        continue;
      }

      // inverted start tag
      if (modifier == '^') {
        output.write(input.substring(start, m.start));
        if (_map.containsKey(field)) {
          final dynamic value = _map[field];
          if (value is bool) {
            eat = value;
          } else {
            eat = true;
          }
        }
        eatField = field;
        start = m.end;
        continue;
      }

      assert(_map.containsKey(field), 'field $field not found');
      output.write(input.substring(start, m.start));
      dynamic value = _applyFilters(_map[field], _filters);
      assert(() {
        if (debug) {
          value = '[$field]($value)';
        }
        return true;
      }());
      output.write(value);
      start = m.end;
    }

    output.write(input.substring(start));
    return output.toString();
  }
}
