// Copyright (c) 2020, David PHAM-VAN <dev.nfet.net@gmail.com>
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: depend_on_referenced_packages

import 'dart:async';
import 'dart:io';

import 'package:build/build.dart';

import 'generator.dart';

Builder jsonIntlBuilder(BuilderOptions options) {
  final pubspec = File('pubspec.yaml').readAsStringSync();
  final pubspecOptions = GeneratorOptions.builder.loadFromYaml(pubspec);
  return MyBuilder(pubspecOptions);
}

class MyBuilder extends Builder {
  MyBuilder(this.options);

  final GeneratorOptions options;

  @override
  Future<void> build(BuildStep buildStep) async {
    final output = await generateIntl(options);
    await buildStep.writeAsString(buildStep.allowedOutputs.first, output);
  }

  @override
  Map<String, List<String>> get buildExtensions => {
        '${options.source}/strings.json': [options.output],
      };
}
