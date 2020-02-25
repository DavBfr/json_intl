/*
 * Copyright (C) 2019, David PHAM-VAN <dev.nfet.net@gmail.com>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

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

  final sourceData = createSourceFromKeys(
    intl: intl,
    className: argResults['classname'],
  );

  log.info('Writing ${argResults['classname']} to $destination');
  File(destination).writeAsStringSync(sourceData);

  return 0;
}
