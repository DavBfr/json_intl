// Copyright (c) 2020, David PHAM-VAN <dev.nfet.net@gmail.com>
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:json_intl/json_intl_data.dart';
import 'package:json_intl_gen/generator.dart';
import 'package:json_intl_gen/src/preprocess.dart';
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
      'prune-unused',
      negatable: false,
      help:
          'Scan lib/ and bin/ for used keys and remove unused translations from JSON before generating',
    )
    ..addFlag(
      'promote-later',
      negatable: false,
      help:
          'Scan lib/ and bin/ for JsonIntl.later() and promote strings to keys (updates default JSON and rewrites Dart callsites)',
    )
    ..addFlag(
      'write',
      negatable: false,
      help:
          'Write changes to JSON/Dart sources (default is dry-run when using prune/promote)',
    )
    ..addFlag('verbose', abbr: 'v', negatable: false, help: 'Verbose output')
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

  final verbose = argResults['verbose'] as bool;

  final pruneUnused = argResults['prune-unused'] as bool;
  final promoteLater = argResults['promote-later'] as bool;
  final dryRun =
      (pruneUnused || promoteLater) && !(argResults['write'] as bool);
  final options = GeneratorOptions(
    source: argResults['source'],
    output: argResults['destination'],
    builtin: argResults['builtin'],
    mangle: argResults['mangle'],
    defaultLocale: argResults['default-locale'],
    className: argResults['classname'],
    pruneUnused: pruneUnused,
    promoteLater: promoteLater,
    dryRun: dryRun,
  );

  // Initialize logger
  final log = Logger('json_intl');

  Logger.root
    ..onRecord.listen((record) {
      stderr.writeln(
        '[${record.loggerName}] ${record.level.name}: ${record.message}',
      );
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

  Map<String, Map<String, dynamic>>? updatedJsonByBasename;
  if (options.pruneUnused || options.promoteLater) {
    log.info('Pre-processing sources (scan lib/ + bin/)');
    final result = preprocessIntl(
      sourceDir: options.source,
      defaultLocale: options.defaultLocale,
      className: options.className,
      generatedOutputDartFile: options.output,
      pruneUnused: options.pruneUnused,
      promoteLater: options.promoteLater,
      dryRun: options.dryRun,
    );

    updatedJsonByBasename = result.updatedIntlJsonByBasename;

    if (options.pruneUnused) {
      log.warning(
        'Prune unused: removed ${result.removedKeysCount} keys ${options.dryRun ? '(dry-run)' : ''}',
      );
    }
    if (options.promoteLater) {
      log.warning(
        'Promote later: added ${result.addedKeysCount} keys, rewrote ${result.rewrittenLaterCount} callsites ${options.dryRun ? '(dry-run)' : ''}',
      );
    }
  }

  if (updatedJsonByBasename != null) {
    for (final entry in updatedJsonByBasename.entries) {
      final intlData = JsonIntlData();
      intlData.append(entry.value);
      intl[entry.key] = intlData;
    }
  } else {
    await for (final FileSystemEntity file in dirSource.list()) {
      if (file is File && file.path.endsWith('.json')) {
        log.info('Loading ${file.path}');
        final jsonData = file.readAsStringSync();
        final Map<String, dynamic> json = decoder.convert(jsonData);
        final intlData = JsonIntlData();
        intlData.append(json);
        intl[p.basename(file.path)] = intlData;
      }
    }
  }

  final gen = Generator(intl: intl, options: options);

  final sourceData = gen.createSource();

  log.info('Writing ${options.className} to ${options.output}');
  File(options.output).writeAsStringSync(sourceData);

  return 0;
}
