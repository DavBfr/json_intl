// Copyright (c) 2020, David PHAM-VAN <dev.nfet.net@gmail.com>
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

class GeneratorOptions {
  const GeneratorOptions({
    this.defaultLocale = 'en',
    this.className = 'IntlKeys',
    this.format = true,
    this.mangle = false,
    this.builtin = false,
    this.debug = false,
    this.pruneUnused = false,
    this.promoteLater = false,
    this.dryRun = true,
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

  /// Remove unused translation keys from JSON files before generating
  final bool pruneUnused;

  /// Promote JsonIntl.later() strings to translation keys before generating
  final bool promoteLater;

  /// When true, do not write modified JSON/Dart files to disk
  final bool dryRun;

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
    bool? pruneUnused,
    bool? promoteLater,
    bool? dryRun,
    String? source,
    String? output,
  }) => GeneratorOptions(
    defaultLocale: defaultLocale ?? this.defaultLocale,
    className: className ?? this.className,
    format: format ?? this.format,
    mangle: mangle ?? this.mangle,
    builtin: builtin ?? this.builtin,
    debug: debug ?? this.debug,
    pruneUnused: pruneUnused ?? this.pruneUnused,
    promoteLater: promoteLater ?? this.promoteLater,
    dryRun: dryRun ?? this.dryRun,
    source: source ?? this.source,
    output: output ?? this.output,
  );
}
