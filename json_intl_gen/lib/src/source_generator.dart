// Copyright (c) 2020, David PHAM-VAN <dev.nfet.net@gmail.com>
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:dart_style/dart_style.dart';
import 'package:json_intl/json_intl_data.dart';

import 'generator_options.dart';
import 'generator_utils.dart';

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
    required this.intl,
    required this.options,
  });

  /// Generator options
  final GeneratorOptions options;

  /// The localization strings
  final Map<String, JsonIntlData> intl;

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

    return options.defaultLocale;
  }

  int _langCompare(String a, String b) {
    final a1 = _langTag(a)!;
    final b1 = _langTag(b)!;
    return a1.compareTo(b1);
  }

  String _generateName(String key, int len) {
    var key_ = key;
    var len_ = len;
    if (len_ > 6) {
      key_ = key_ + len_.toString();
      len_ = 6;
    }
    var radix = key_.hashCode.toRadixString(36);
    if (radix.codeUnitAt(0) < 65) {
      radix = 'n$radix';
    }
    return radix.substring(0, len_);
  }

  Iterable<String> _createSourceFromKeys([Map<String, String>? names]) sync* {
    yield '/// Internationalization constants';
    yield 'mixin ${options.className} {';

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
      var variable = outputVar(key, camelCase: true);

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
      if (options.mangle) {
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
          yield '  /// ${_langTag(lang)}: ${outputStr(entry.translate(sortedKey))}';
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
    yield 'const defaultLocale${options.className} = ${outputStr(options.defaultLocale)};';
    yield '';

    yield '/// Available Locales';
    yield 'const availableLocales${options.className} = [';
    for (final lang in _langs) {
      yield '  ${outputStr(_langTag(lang)!)},';
    }
    yield '];';
    yield '';

    yield '/// Supported Locales';
    yield 'const supportedLocales${options.className} = [';
    for (final lang in _langs) {
      yield '  Locale(${outputStr(_langTag(lang)!)}),';
    }
    yield '];';
  }

  String createSource() {
    return options.builtin
        ? _createBuiltinFromKeys()
        : _createSourceFromKeys1();
  }

  /// Generate a dart class from a list of translation keys
  String _createSourceFromKeys1() {
    final output = <String>[];

    output.add('// This file is generated automatically, do not modify');
    output.add('');
    output.add('import \'dart:ui\';');
    output.add('');
    output.add('import \'package:json_intl/json_intl.dart\';');
    output.add('');

    output.add('const jsonIntlDelegate = JsonIntlDelegate(');
    if (options.source != GeneratorOptions.def.source) {
      output.add('base: ${outputStr(options.source)},');
    }
    output.add('availableLocales: availableLocalesIntlKeys,');
    if (options.debug) {
      output.add('debug: true,');
    }
    output.add(');');

    output.addAll(_createSourceFromKeys());

    if (options.format) {
      return DartFormatter().format(output.join('\n')).toString();
    }

    return output.join('\n');
  }

  /// Generate a dart class from a list of translation keys
  String _createBuiltinFromKeys() {
    final output = <String>[];

    output.add('// This file is generated automatically, do not modify');
    output.add('');
    output.add('// ignore_for_file: avoid_redundant_argument_values');
    output.add('');
    output.add('import \'dart:ui\';');
    output.add('');
    output.add('import \'package:json_intl/json_intl.dart\';');
    output.add('import \'package:json_intl/json_intl_data.dart\';');
    output.add('');

    output.add('const jsonIntlDelegate = JsonIntlDelegateBuiltin(');
    output.add('data: data${options.className},');
    output.add('defaultLocale: defaultLocale${options.className},');
    if (options.debug) {
      output.add('debug: true,');
    }
    output.add(');');

    final names = <String, String>{};
    output.addAll(_createSourceFromKeys(names));

    output.add('/// Data converted from json strings');
    output.add('const data${options.className} = {');

    for (final lang in _langs) {
      output.add('  ${outputStr(_langTag(lang)!)}: {');

      final entry = intl[lang]!;
      final Map<String, dynamic> data = json.decode(entry.toString());

      for (final key in data.entries) {
        output.add('${options.className}.${names[key.key]}: JsonIntlValue({');
        for (final gender in key.value.entries) {
          output.add('JsonIntlGender.${gender.key}: {');
          for (final plural in gender.value.entries) {
            output.add(
                'JsonIntlPlural.${plural.key}: ${outputStr(plural.value)},');
          }
          output.add('},');
        }
        output.add('}),');
      }
      output.add('},');
      output.add('');
    }

    output.add('};');

    if (options.format) {
      return DartFormatter().format(output.join('\n')).toString();
    }

    return output.join('\n');
  }
}
