// Copyright (c) 2020, David PHAM-VAN <dev.nfet.net@gmail.com>
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:csv/csv_settings_autodetection.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

import '../generator.dart';

export 'package:json_intl_gen/src/generator_options.dart';
export 'package:json_intl_gen/src/pubspec.dart';
export 'package:json_intl_gen/src/source_generator.dart';

class CsvGenerator {
  CsvGenerator({
    required this.options,
    this.basedir = '.',
    this.filename = 'strings.csv',
  });

  final GeneratorOptions options;

  final String basedir;

  final String filename;

  Future<void> export() async {
    final log = Logger('json_intl');

    log.info('Checking source directory exists');
    final dirSource = Directory(p.join(basedir, options.source));
    if (!dirSource.existsSync()) {
      log.severe('Directory ${dirSource.absolute.path} not found');
      throw Exception('Directory ${dirSource.absolute.path} not found');
    }

    const decoder = JsonDecoder();
    final intl = <String, Map<String, dynamic>>{};
    final keys = <String>{};

    await for (FileSystemEntity file in dirSource.list()) {
      if (file is File) {
        log.info('Loading ${file.path}');
        final jsonData = file.readAsStringSync();
        final Map<String, dynamic> json = decoder.convert(jsonData);
        keys.addAll(json.keys);

        intl[_langTag(p.basename(file.path))] = json;
      }
    }

    final langs = [...intl.keys];
    langs.sort((a, b) => a == options.defaultLocale ? -1 : a.compareTo(b));

    final output = <List<String>>[
      ['key', ...langs]
    ];

    for (final key in keys) {
      addLine(output, key, [for (final lang in langs) intl[lang]![key]]);
    }

    final csv = const ListToCsvConverter().convert(output);

    await File(filename).writeAsString(csv);
  }

  Future<void> import() async {
    final log = Logger('json_intl');

    log.info('Checking source directory exists');
    final dirSource = Directory(p.join(basedir, options.source));
    if (!dirSource.existsSync()) {
      log.severe('Directory ${dirSource.absolute.path} not found');
      throw Exception('Directory ${dirSource.absolute.path} not found');
    }

    final csv = await File(filename).readAsString();
    final intl = const CsvToListConverter(
      csvSettingsDetector: FirstOccurrenceSettingsDetector(
        eols: ['\n', '\r\n'],
        fieldDelimiters: [',', ';'],
      ),
    ).convert(csv);

    final langs = intl.removeAt(0);
    langs.removeAt(0);

    final files = <String, Map<String, dynamic>>{for (final l in langs) l: {}};

    for (final line in intl) {
      final key = line[0];
      var n = 1;
      for (final l in langs) {
        final w = line[n];
        if (w != '') {
          makeJsonKey(files[l]!, key, w);
        }
        n += 1;
      }
    }

    const enc = JsonEncoder.withIndent('  ');

    for (final l in langs) {
      final filename = p.join(options.source,
          'strings${l == options.defaultLocale ? '' : '-$l'}.json');
      await File(filename).writeAsString(enc.convert(files[l]));
    }
  }

  void makeJsonKey(Map<String, dynamic> file, String key, String value) {
    final re = RegExp(r'([^[]+)\[([\w]+)\]');
    final m = re.firstMatch(key);
    if (m?.group(2) != null) {
      final k = m!.group(1)!;
      file[k] ??= <String, dynamic>{};
      final sk = m.group(2)! + key.substring(m.end);
      makeJsonKey(file[k], sk, value);
    } else {
      file[key] = value;
    }
  }

  void addLine(List<List<String>> output, String key, List<dynamic> intl) {
    if (intl.fold(false, (p, e) => p || e is Map)) {
      final k = intl
          .fold<Set<String>>({}, (p, e) => {...p, ...(e is Map ? e.keys : [])});
      for (final p in k) {
        addLine(
            output,
            '$key[$p]',
            intl
                .map<String>(
                  (e) => e is Map ? e[p] : null,
                )
                .toList());
      }
    } else {
      output.add([key, ...intl.map((e) => e == null ? '' : e.toString())]);
    }
  }

  String _stripExtension(String a) {
    final i = a.lastIndexOf('.');

    if (i >= 0) {
      return a.substring(0, i);
    }

    return a;
  }

  String _langTag(String a) {
    final i = a.indexOf('-');

    if (i >= 0) {
      return _stripExtension(a.substring(i + 1));
    }

    return options.defaultLocale;
  }

  // int _langCompare(String a, String b) {
  //   final a1 = _langTag(a);
  //   final b1 = _langTag(b);
  //   return a1.compareTo(b1);
  // }
}
