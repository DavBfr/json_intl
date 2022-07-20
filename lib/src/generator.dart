// Copyright (c) 2020, David PHAM-VAN <dev.nfet.net@gmail.com>
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:dart_style/dart_style.dart';

import 'json_intl_data.dart';

extension _SymbolString on Symbol {
  String getString() {
    final s = toString();
    return s.substring(8, s.length - 2);
  }
}

/// Generate dart source code
class Generator {
  /// Create a `Generator`
  const Generator({
    this.defaultLocale = 'en',
    this.className = 'IntlKeys',
    this.format = true,
    required this.intl,
    this.mangle = false,
  });

  /// The default locale
  final String defaultLocale;

  /// The class name to generate
  final String className;

  /// The localization strings
  final Map<String, JsonIntlData> intl;

  /// Format the generated dart file
  final bool format;

  /// Change keys to a random string
  final bool mangle;

  List<String> get _langs {
    final langs = intl.entries.map<String>((e) => e.key).toSet().toList();
    langs.sort(_langCompare);
    return langs;
  }

  String _stripExtension(String a) {
    final i = a.lastIndexOf('.');

    if (i >= 0) {
      return a.substring(0, i);
    }

    return a;
  }

  String? _langTag(String a) {
    final i = a.indexOf('-');

    if (i >= 0) {
      return _stripExtension(a.substring(i + 1));
    }

    return defaultLocale;
  }

  int _langCompare(String a, String b) {
    a = _langTag(a)!;
    b = _langTag(b)!;
    return a.compareTo(b);
  }

  String _generateName(String key, int len) {
    if (len > 6) {
      key = key + len.toString();
      len = 6;
    }
    var radix = key.hashCode.toRadixString(36);
    if (radix.codeUnitAt(0) < 65) {
      radix = 'n$radix';
    }
    return radix.substring(0, len);
  }

  Iterable<String> _createSourceFromKeys([Map<String, String>? names]) sync* {
    yield '/// Internationalization constants';
    yield 'class $className {';

    final keys = <Symbol>{};
    for (final entry in intl.entries) {
      keys.addAll(entry.value.keys);
    }
    final sortedKeys = keys.toList();
    sortedKeys.sort((a, b) => a.getString().compareTo(b.getString()));

    final generatedKeys = <String>{};

    final variables = <String>{};
    for (final sortedKey in sortedKeys) {
      final key = sortedKey.getString();
      var variable = _outputVar(key);

      var index = 0;
      final tempVariable = variable;
      while (variables.contains(variable)) {
        variable = '${tempVariable}_$index';
        index++;
      }
      variables.add(variable);
      if (names != null) {
        names[key] = variable;
      }

      var finalName = key;
      if (mangle) {
        var n = 2;
        do {
          finalName = _generateName(key, n);
          n++;
        } while (generatedKeys.contains(finalName));
        generatedKeys.add(finalName);
      }

      for (final lang in _langs) {
        final entry = intl[lang]!;
        if (entry.keys.contains(sortedKey)) {
          yield '  /// ${_langTag(lang)}: ${_outputStr(entry.translate(sortedKey))}';
        } else {
          yield '  /// ${_langTag(lang)}: *** NOT TRANSLATED ***';
        }
      }
      yield '  static const $variable = #$finalName;';
      yield '';
    }

    yield '}';
    yield '';

    yield '/// Default Locale';
    yield 'const defaultLocale$className = ${_outputStr(defaultLocale)};';
    yield '';

    yield '/// Available Locales';
    yield 'const availableLocales$className = [';
    for (final lang in _langs) {
      yield '  ${_outputStr(_langTag(lang)!)},';
    }
    yield '];';
    yield '';

    yield '/// Supported Locales';
    yield 'const supportedLocales$className = [';
    for (final lang in _langs) {
      yield '  Locale(${_outputStr(_langTag(lang)!)}),';
    }
    yield '];';
  }

  /// Generate a dart class from a list of translation keys
  String createSourceFromKeys() {
    final output = <String>[];

    output.add('// This file is generated automatically, do not modify');
    output.add('');
    output.add('import \'dart:ui\';');
    output.add('');

    output.addAll(_createSourceFromKeys());

    if (format) {
      return DartFormatter().format(output.join('\n')).toString();
    }

    return output.join('\n');
  }

  /// Generate a dart class from a list of translation keys
  String createBuiltinFromKeys() {
    final output = <String>[];

    output.add('// This file is generated automatically, do not modify');
    output.add('');
    output.add('// ignore_for_file: implementation_imports');
    output.add('');
    output.add('import \'dart:ui\';');
    output.add('');
    output.add('import \'package:json_intl/src/json_intl_value.dart\';');
    output.add('');

    final names = <String, String>{};
    output.addAll(_createSourceFromKeys(names));

    output.add('/// Data converted from json strings');
    output.add('const data$className = {');

    for (final lang in _langs) {
      output.add('  ${_outputStr(_langTag(lang)!)}: {');

      final entry = intl[lang]!;
      final Map<String, dynamic> data = json.decode(entry.toString());

      for (final key in data.entries) {
        output.add('$className.${names[key.key]}: JsonIntlValue({');
        for (final gender in key.value.entries) {
          output.add('JsonIntlGender.${gender.key}: {');
          for (final plural in gender.value.entries) {
            output.add(
                'JsonIntlPlural.${plural.key}: ${_outputStr(plural.value)},');
          }
          output.add('},');
        }
        output.add('}),');
      }
      output.add('},');
      output.add('');
    }

    output.add('};');

    if (format) {
      return DartFormatter().format(output.join('\n')).toString();
    }

    return output.join('\n');
  }

  String _outputVar(String s) {
    s = s.replaceAll(RegExp(r'[^A-Za-z0-9]'), ' ');

    final group = s.split(RegExp(r'\s+'));
    final buffer = StringBuffer();

    var first = true;
    for (var word in group) {
      if (first) {
        first = false;
        buffer.write(word.toLowerCase());
      } else {
        buffer.write(word.substring(0, 1).toUpperCase());
        buffer.write(word.substring(1).toLowerCase());
      }
    }

    return buffer.toString();
  }

  String _outputStr(String s) {
    s = s.replaceAll(r'\', r'\\');
    s = s.replaceAll('\n', r'\n');
    s = s.replaceAll('\r', '');
    s = s.replaceAll("'", r"\'");
    return "'$s'";
  }
}
