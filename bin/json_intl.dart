// Copyright (c) 2020, David PHAM-VAN <dev.nfet.net@gmail.com>
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:json_intl/src/json_intl_data.dart';
import 'package:json_intl/src/generator.dart';
import 'package:json_intl/src/pubspec.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

Future<int> main(List<String> arguments) async {
  // Parse CLI arguments
  final parser = ArgParser()
    ..addOption(
      'source',
      abbr: 's',
      defaultsTo: 'assets/intl',
      help: 'Source intl directory',
    )
    ..addOption(
      'destination',
      abbr: 'd',
      defaultsTo: 'lib/intl.dart',
      help: 'Destination dart file',
    )
    ..addOption(
      'classname',
      abbr: 'c',
      defaultsTo: 'IntlKeys',
      help: 'Destination class name',
    )
    ..addOption(
      'default-locale',
      abbr: 'l',
      defaultsTo: 'en',
      help: 'Default generated locale',
    )
    ..addFlag(
      'builtin',
      abbr: 'b',
      negatable: false,
      help: 'Generate full built-in localizations',
    )
    ..addFlag(
      'mangle',
      abbr: 'm',
      negatable: false,
      help: 'Change keys to a random string',
    )
    ..addFlag(
      'verbose',
      abbr: 'v',
      negatable: false,
      help: 'Verbose output',
    )
    ..addFlag(
      'version',
      negatable: false,
      help: 'Print the version information',
    )
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Shows usage information',
    );

  final argResults = parser.parse(arguments);

  if (argResults['help']) {
    print(Pubspec.description);
    print('');
    print('Usage:   ${Pubspec.name} [options...]');
    print('');
    print('Options:');
    print(parser.usage);
    return 0;
  }

  if (argResults['version']) {
    print('${Pubspec.name} version ${Pubspec.versionFull}');
    return 0;
  }

  final String source = argResults['source'];
  final String destination = argResults['destination'];
  final bool verbose = argResults['verbose'];
  final bool builtin = argResults['builtin'];
  final bool mangle = argResults['mangle'];
  final String defaultLocale = argResults['default-locale'];

  // Initialize logger
  Logger.root.level = verbose ? Level.ALL : Level.SEVERE;
  Logger.root.onRecord.listen((LogRecord rec) {
    print('${rec.level.name}: ${rec.time}: ${rec.message}');
  });
  final log = Logger('main');

  log.info('Checking source directory exists');
  final dirSource = Directory(source);
  if (!dirSource.existsSync()) {
    log.severe('Directory $source not found');
    return 1;
  }

  log.info('Checking output directory');
  Directory(p.basename(destination));
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
    className: argResults['classname'],
    defaultLocale: defaultLocale,
    mangle: mangle,
  );

  final sourceData =
      builtin ? gen.createBuiltinFromKeys() : gen.createSourceFromKeys();

  log.info('Writing ${argResults['classname']} to $destination');
  File(destination).writeAsStringSync(sourceData);

  return 0;
}
