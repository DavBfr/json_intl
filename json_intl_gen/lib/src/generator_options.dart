// Copyright (c) 2020, David PHAM-VAN <dev.nfet.net@gmail.com>
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:yaml/yaml.dart';

class GeneratorOptions {
  const GeneratorOptions({
    this.defaultLocale = 'en',
    this.className = 'IntlKeys',
    this.format = true,
    this.mangle = false,
    this.builtin = false,
    this.debug = false,
    this.source = 'assets/intl',
    this.output = 'lib/intl.dart',
  });

  static const def = GeneratorOptions();

  static const builder = GeneratorOptions(builtin: true);

  /// The default locale
  final String defaultLocale;

  /// The class name to generate
  final String className;

  /// Format the generated dart file
  final bool format;

  /// Include the translations into the output dart source
  final bool builtin;

  /// Change keys to a random string
  final bool mangle;

  /// Generate debug strings
  final bool debug;

  /// Source directory
  final String source;

  /// Output filename
  final String output;

  GeneratorOptions copyWith({
    String? defaultLocale,
    String? className,
    bool? format,
    bool? mangle,
    bool? builtin,
    bool? debug,
    String? source,
    String? output,
  }) =>
      GeneratorOptions(
        defaultLocale: defaultLocale ?? this.defaultLocale,
        className: className ?? this.className,
        format: format ?? this.format,
        mangle: mangle ?? this.mangle,
        builtin: builtin ?? this.builtin,
        debug: debug ?? this.debug,
        source: source ?? this.source,
        output: output ?? this.output,
      );

  GeneratorOptions loadFromYaml(String yaml) {
    final pubspec = loadYaml(yaml) as Map;

    if (pubspec.containsKey('json_intl')) {
      final opt = pubspec['json_intl'] as Map;
      return copyWith(
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

    return this;
  }
}
