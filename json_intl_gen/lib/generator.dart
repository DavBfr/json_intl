// Copyright (c) 2020, David PHAM-VAN <dev.nfet.net@gmail.com>
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:json_intl/json_intl_data.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

import 'generator.dart';

export 'package:json_intl_gen/src/generator_options.dart';
export 'package:json_intl_gen/src/pubspec.dart';
export 'package:json_intl_gen/src/source_generator.dart';

Future<String> generateIntl(GeneratorOptions options, {basedir = '.'}) async {
  final log = Logger('json_intl');

  log.info('Checking source directory exists');
  final dirSource = Directory(p.join(basedir, options.source));
  if (!dirSource.existsSync()) {
    log.severe('Directory ${dirSource.absolute.path} not found');
    throw Exception('Directory ${dirSource.absolute.path} not found');
  }

  const decoder = JsonDecoder();
  final intl = <String, JsonIntlData>{};

  await for (FileSystemEntity file in dirSource.list()) {
    if (file is File) {
      log.info('Loading ${file.path}');
      final jsonData = file.readAsStringSync();
      final Map<String, dynamic> json = decoder.convert(jsonData);
      final intlData = JsonIntlData();
      intlData.append(json);
      intl[p.basename(file.path)] = intlData;
    }
  }

  final gen = Generator(
    intl: intl,
    options: options,
  );

  return gen.createSource();
}
