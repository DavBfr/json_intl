// Copyright (c) 2020, David PHAM-VAN <dev.nfet.net@gmail.com>
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:dart_style/dart_style.dart';

import 'json_intl_data.dart';

String _stripExtension(String a) {
  final i = a.lastIndexOf('.');

  if (i >= 0) {
    return a.substring(0, i);
  }

  return a;
}

int _langCompare(String a, String b) {
  a = _stripExtension(a);
  b = _stripExtension(b);
  return a.compareTo(b);
}

/// Generate a dart class from a list of translation keys
String createSourceFromKeys({
  String className,
  bool format = true,
  Map<String, JsonIntlData> intl,
}) {
  final output = <String>[];

  output.add('// This file is generated automatically, do not modify');
  output.add('');
  output.add('/// Internationalization constants');
  output.add('class $className {');

  final keys = <String>{};
  for (final entry in intl.entries) {
    keys.addAll(entry.value.keys);
  }
  final sortedKeys = keys.toList();
  sortedKeys.sort();

  final langs = intl.entries.map<String>((e) => e.key).toSet().toList();
  langs.sort(_langCompare);

  final variables = <String>{};
  for (final key in sortedKeys) {
    var variable = _outputVar(key);

    var index = 0;
    final tempVariable = variable;
    while (variables.contains(variable)) {
      variable = '${tempVariable}_$index';
      index++;
    }
    variables.add(variable);

    for (final lang in langs) {
      final entry = intl[lang];
      if (entry.keys.contains(key)) {
        output.add('  /// $lang: ${_outputStr(entry.translate(key))}');
      } else {
        output.add('  /// $lang: *** NOT TRANSLATED ***');
      }
    }
    output.add('  static const $variable = ${_outputStr(key)};');
    output.add('');
  }

  output.add('}');

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
