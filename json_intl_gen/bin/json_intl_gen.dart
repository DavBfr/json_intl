// Copyright (c) 2020, David PHAM-VAN <dev.nfet.net@gmail.com>
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:json_intl/json_intl_data.dart';
import 'package:json_intl_gen/generator.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

Future<int> main(List<String> arguments) async {
  // Parse CLI arguments
  final parser = ArgParser()
    ..addOption(
      'source',
      abbr: 's',
      defaultsTo: GeneratorOptions.def.source,
      help: 'Source intl directory',
    )
    ..addOption(
      'destination',
      abbr: 'd',
      defaultsTo: GeneratorOptions.def.output,
      help: 'Destination dart file',
    )
    ..addOption(
      'classname',
      abbr: 'c',
      defaultsTo: GeneratorOptions.def.className,
      help: 'Destination class name',
    )
    ..addOption(
      'default-locale',
      abbr: 'l',
      defaultsTo: GeneratorOptions.def.defaultLocale,
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

  final bool verbose = argResults['verbose'];
  final options = GeneratorOptions(
    source: argResults['source'],
    output: argResults['destination'],
    builtin: argResults['builtin'],
    mangle: argResults['mangle'],
    defaultLocale: argResults['default-locale'],
    className: argResults['classname'],
  );

  // Initialize logger
  final log = Logger('json_intl');

  Logger.root
    ..onRecord.listen((record) {
      stderr.writeln(
          '[${record.loggerName}] ${record.level.name}: ${record.message}');
    })
    ..level = verbose ? Level.ALL : Level.WARNING;

  log.info('Checking source directory exists');
  final dirSource = Directory(options.source);
  if (!dirSource.existsSync()) {
    log.severe('Directory ${options.source} not found');
    return 1;
  }

  log.info('Checking output directory');
  Directory(p.basename(options.output));
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

  final sourceData = gen.createSource();

  log.info('Writing ${options.className} to ${options.output}');
  File(options.output).writeAsStringSync(sourceData);

  return 0;
}
