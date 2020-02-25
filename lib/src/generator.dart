// Copyright (C) 2019, David PHAM-VAN <dev.nfet.net@gmail.com>
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:dart_style/dart_style.dart';

import 'json_intl_data.dart';

String createSourceFromKeys({
  String className,
  bool format = true,
  Map<String, JsonIntlData> intl,
}) {
  final output = <String>[];

  output.add('// This file is generated automatically, do not modify');
  output.add('');
  output.add('class $className {');

  final keys = <String>{};
  for (final entry in intl.entries) {
    keys.addAll(entry.value.keys);
  }

  final variables = <String>{};
  for (final key in keys) {
    var variable = _outputVar(key);

    var index = 0;
    final tempVariable = variable;
    while (variables.contains(variable)) {
      variable = '${tempVariable}_$index';
      index++;
    }
    variables.add(variable);

    for (final entry in intl.entries) {
      if (entry.value.keys.contains(key)) {
        output.add(
            '  /// ${entry.key}: ${_outputStr(entry.value.translate(key))}');
      } else {
        output.add('  /// ${entry.key}: *** NOT TRANSLATED ***');
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
