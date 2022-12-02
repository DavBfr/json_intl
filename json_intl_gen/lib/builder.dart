// Copyright (c) 2020, David PHAM-VAN <dev.nfet.net@gmail.com>
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: depend_on_referenced_packages

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';
import 'package:json_intl/json_intl_data.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import 'src/generator_options.dart';
import 'src/source_generator.dart';

Builder jsonIntlBuilder(BuilderOptions options) {
  final pubspec = loadYaml(File('pubspec.yaml').readAsStringSync()) as Map;

  var options = GeneratorOptions.builder;

  if (pubspec.containsKey('json_intl')) {
    final opt = pubspec['json_intl'] as Map;
    options = options.copyWith(
      className: opt['class_name'],
      defaultLocale: opt['default_locale'],
      mangle: opt['mangle'],
      debug: opt['debug'],
      builtin: opt['builtin'],
      source: opt['source'],
      output: opt['output'],
      format: opt['format'],
    );
  }

  return MyBuilder(options);
}

class MyBuilder extends Builder {
  MyBuilder(this.options);

  final GeneratorOptions options;

  @override
  Future<void> build(BuildStep buildStep) async {
    const decoder = JsonDecoder();
    final intl = <String, JsonIntlData>{};

    print('BUILD');

    await for (final file in Glob('${options.source}/*.json').list()) {
      log.info('Loading ${file.path}');
      final jsonData = await File(file.path).readAsString();
      final Map<String, dynamic> json = decoder.convert(jsonData);
      final intlData = JsonIntlData();
      intlData.append(json);
      intl[p.basename(file.path)] = intlData;
    }

    final gen = Generator(intl: intl, options: options);

    final output = gen.createSource();

    await buildStep.writeAsString(buildStep.allowedOutputs.first, output);
  }

  @override
  Map<String, List<String>> get buildExtensions => {
        '${options.source}/strings.json': [options.output],
      };
}
