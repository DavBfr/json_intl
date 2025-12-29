// Copyright (c) 2020, David PHAM-VAN <dev.nfet.net@gmail.com>
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:path/path.dart' as p;

import 'generator_utils.dart';
import 'reserved.dart';

class PreprocessResult {
  const PreprocessResult({
    required this.updatedIntlJsonByBasename,
    required this.dartFilesUpdated,
    required this.jsonFilesUpdated,
    required this.removedKeysCount,
    required this.addedKeysCount,
    required this.rewrittenLaterCount,
  });

  final Map<String, Map<String, dynamic>> updatedIntlJsonByBasename;
  final int dartFilesUpdated;
  final int jsonFilesUpdated;
  final int removedKeysCount;
  final int addedKeysCount;
  final int rewrittenLaterCount;
}

class _LaterCallSite {
  const _LaterCallSite({
    required this.offset,
    required this.end,
    required this.invocationPrefix,
    required this.text,
    required this.namedArgSource,
  });

  final int offset;
  final int end;
  final String invocationPrefix;
  final String text;

  /// Named args (name -> expression source)
  final Map<String, String> namedArgSource;
}

class _ScanResult {
  const _ScanResult({
    required this.usedKeyVariables,
    required this.laterCallSitesByFile,
  });

  final Set<String> usedKeyVariables;
  final Map<String, List<_LaterCallSite>> laterCallSitesByFile;
}

class _Scanner extends RecursiveAstVisitor<void> {
  _Scanner({required this.source, required this.className});

  final String source;
  final String className;

  final usedKeyVariables = <String>{};
  final laterCallSites = <_LaterCallSite>[];

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (node.prefix.name == className) {
      usedKeyVariables.add(node.identifier.name);
    }
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    final target = node.target;
    if (target is SimpleIdentifier && target.name == className) {
      usedKeyVariables.add(node.propertyName.name);
    }
    super.visitPropertyAccess(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == 'later') {
      final args = node.argumentList.arguments;
      if (args.isNotEmpty && args.first is StringLiteral) {
        final str = args.first as StringLiteral;
        final text = str.stringValue;
        if (text != null) {
          final namedArgSource = <String, String>{};
          for (final arg in args) {
            if (arg is NamedExpression) {
              namedArgSource[arg.name.label.name] = source.substring(
                arg.expression.offset,
                arg.expression.end,
              );
            }
          }

          final operatorLexeme = node.operator?.lexeme;
          final prefix = node.target != null
              ? '${source.substring(node.target!.offset, node.target!.end)}${operatorLexeme ?? '.'}'
              : (operatorLexeme ?? '');

          laterCallSites.add(
            _LaterCallSite(
              offset: node.offset,
              end: node.end,
              invocationPrefix: prefix,
              text: text,
              namedArgSource: namedArgSource,
            ),
          );
        }
      }
    }

    super.visitMethodInvocation(node);
  }
}

Iterable<File> _listDartFiles(Directory root) sync* {
  if (!root.existsSync()) {
    return;
  }

  for (final entity in root.listSync(recursive: true, followLinks: false)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      yield entity;
    }
  }
}

_ScanResult _scanDartSources({required String className, String? excludeFile}) {
  final used = <String>{};
  final laterByFile = <String, List<_LaterCallSite>>{};

  final normalizedExclude = excludeFile == null
      ? null
      : p.normalize(excludeFile);

  for (final dirName in const ['lib', 'bin']) {
    final dir = Directory(dirName);
    for (final file in _listDartFiles(dir)) {
      if (normalizedExclude != null &&
          p.normalize(file.path) == normalizedExclude) {
        continue;
      }
      final source = file.readAsStringSync();
      final parsed = parseString(
        content: source,
        path: file.path,
        throwIfDiagnostics: false,
      );

      final scanner = _Scanner(source: source, className: className);
      parsed.unit.visitChildren(scanner);

      used.addAll(scanner.usedKeyVariables);
      if (scanner.laterCallSites.isNotEmpty) {
        laterByFile[file.path] = List<_LaterCallSite>.from(
          scanner.laterCallSites,
        );
      }
    }
  }

  return _ScanResult(usedKeyVariables: used, laterCallSitesByFile: laterByFile);
}

String? _extractNeutralOther(dynamic value) {
  if (value is String) {
    return value;
  }

  if (value is Map) {
    final neutral = value['neutral'];
    if (neutral is Map && neutral['other'] is String) {
      return neutral['other'] as String;
    }

    if (value['other'] is String) {
      return value['other'] as String;
    }
  }

  return null;
}

Map<String, String> _buildVariableToJsonKeyMap(Set<String> jsonKeys) {
  final sortedKeys = jsonKeys.toList()..sort();

  final variables = <String>{};
  final variableToJsonKey = <String, String>{};

  for (final key in sortedKeys) {
    var variable = outputVar(key, camelCase: true);

    var index = 0;
    final tempVariable = variable;
    while (variables.contains(variable)) {
      variable = '${tempVariable}_$index';
      index++;
    }

    variables.add(variable);
    variableToJsonKey[variable] = key;
  }

  return variableToJsonKey;
}

String _allocateKeyForText({
  required String text,
  required Set<String> existingKeys,
}) {
  final tokens = RegExp(r'[a-z0-9]+')
      .allMatches(text.toLowerCase())
      .map((m) => m.group(0)!)
      .where((t) => t.isNotEmpty)
      .toList();

  // Filter out tokens that don't start with a-z
  final validTokens = tokens
      .where((t) => t.isNotEmpty && RegExp(r'^[a-z]').hasMatch(t))
      .toList();

  if (validTokens.isEmpty) {
    const base = 'text';
    var n = 2;
    var candidate = base;
    while (existingKeys.contains(candidate) ||
        reservedKeys.contains(candidate)) {
      candidate = '${base}_$n';
      n++;
    }
    return candidate;
  }

  var start = validTokens.length >= 4
      ? 4
      : (validTokens.length >= 3 ? 3 : validTokens.length);
  start = start.clamp(1, validTokens.length);

  String candidateForWords(int words) {
    final w = words.clamp(1, validTokens.length);
    return validTokens.take(w).join('_');
  }

  for (var words = start; words <= 6; words++) {
    final candidate = candidateForWords(words);
    if (!existingKeys.contains(candidate) &&
        !reservedKeys.contains(candidate)) {
      return candidate;
    }
    if (words >= validTokens.length) {
      break;
    }
  }

  // Still colliding at 6 words: suffix with a number.
  final base = candidateForWords(
    validTokens.length < 6 ? validTokens.length : 6,
  );
  var n = 2;
  while (true) {
    final candidate = '${base}_$n';
    if (!existingKeys.contains(candidate) &&
        !reservedKeys.contains(candidate)) {
      return candidate;
    }
    n++;
  }
}

String _encodeJsonSorted(Map<String, dynamic> map) {
  final keys = map.keys.toList()..sort();
  final sorted = <String, dynamic>{for (final k in keys) k: map[k]};
  final je = JsonEncoder.withIndent('  ');
  return je.convert(sorted);
}

String? _pickDefaultLocaleBasename({
  required String defaultLocale,
  required Iterable<String> basenames,
}) {
  if (basenames.contains('strings.json')) {
    return 'strings.json';
  }

  final exact = 'strings-$defaultLocale.json';
  if (basenames.contains(exact)) {
    return exact;
  }

  final withoutDash = basenames.firstWhere(
    (b) => !b.contains('-') && b.endsWith('.json'),
    orElse: () => '',
  );
  if (withoutDash.isNotEmpty) {
    return withoutDash;
  }

  final any = basenames.firstWhere(
    (b) => b.endsWith('.json'),
    orElse: () => '',
  );
  return any.isEmpty ? null : any;
}

String _buildReplacementInvocation({
  required String prefix,
  required String className,
  required String keyVariable,
  required Map<String, String> namedArgs,
}) {
  final keyExpr = '$className.$keyVariable';

  final map = namedArgs['map'];
  final filters = namedArgs['filters'];
  final count = namedArgs['count'];
  final gender = namedArgs['gender'];
  final precision = namedArgs['precision'];
  final locale = namedArgs['locale'];
  final strict = namedArgs['strict'];

  final hasCount = count != null;
  final hasGender = gender != null;
  final hasPrecision = precision != null;
  final hasLocale = locale != null;
  final hasStrict = strict != null;

  var mustUseTranslate = false;
  if (hasLocale || hasPrecision) {
    mustUseTranslate = true;
  }
  if (hasGender && hasStrict) {
    mustUseTranslate = true;
  }
  if (hasGender && hasCount) {
    mustUseTranslate = true;
  }

  if (mustUseTranslate) {
    final parts = <String>[keyExpr];
    if (hasGender) {
      parts.add('gender: $gender');
    }
    if (hasCount) {
      parts.add('count: $count');
    }
    if (map != null) {
      parts.add('map: $map');
    }
    if (filters != null) {
      parts.add('filters: $filters');
    }
    if (precision != null) {
      parts.add('precision: $precision');
    }
    if (locale != null) {
      parts.add('locale: $locale');
    }
    if (strict != null) {
      parts.add('strict: $strict');
    }

    return '${prefix}translate(${parts.join(', ')})';
  }

  if (hasGender) {
    final parts = <String>[gender, keyExpr];
    if (map != null) {
      parts.add('map: $map');
    }
    if (filters != null) {
      parts.add('filters: $filters');
    }
    return '${prefix}gender(${parts.join(', ')})';
  }

  if (hasCount) {
    final parts = <String>[count, keyExpr];
    if (map != null) {
      parts.add('map: $map');
    }
    if (filters != null) {
      parts.add('filters: $filters');
    }
    if (strict != null) {
      parts.add('strict: $strict');
    }
    return '${prefix}count(${parts.join(', ')})';
  }

  // Default: get()
  if (map == null && filters == null) {
    return '${prefix}get($keyExpr)';
  }
  if (map != null && filters == null) {
    return '${prefix}get($keyExpr, $map)';
  }
  if (map == null && filters != null) {
    return '${prefix}get($keyExpr, null, $filters)';
  }
  return '${prefix}get($keyExpr, $map, $filters)';
}

PreprocessResult preprocessIntl({
  required String sourceDir,
  required String defaultLocale,
  required String className,
  String? generatedOutputDartFile,
  required bool pruneUnused,
  required bool promoteLater,
  required bool dryRun,
}) {
  final dir = Directory(sourceDir);
  if (!dir.existsSync()) {
    throw StateError('Directory $sourceDir not found');
  }

  const decoder = JsonDecoder();

  final intlJsonByBasename = <String, Map<String, dynamic>>{};
  for (final entity in dir.listSync(followLinks: false)) {
    if (entity is File && entity.path.endsWith('.json')) {
      final jsonData = entity.readAsStringSync();
      final decoded = decoder.convert(jsonData);
      if (decoded is! Map<String, dynamic>) {
        throw StateError('Invalid JSON in ${entity.path}: expected object');
      }
      intlJsonByBasename[p.basename(entity.path)] = decoded;
    }
  }

  final defaultBasename = _pickDefaultLocaleBasename(
    defaultLocale: defaultLocale,
    basenames: intlJsonByBasename.keys,
  );
  if (defaultBasename == null ||
      !intlJsonByBasename.containsKey(defaultBasename)) {
    throw StateError(
      'Unable to determine default locale JSON file in $sourceDir',
    );
  }

  final scan = _scanDartSources(
    className: className,
    excludeFile: generatedOutputDartFile,
  );

  // Union of JSON keys across locales.
  final allJsonKeys = <String>{};
  for (final json in intlJsonByBasename.values) {
    allJsonKeys.addAll(json.keys);
  }

  // Build var->jsonKey mapping consistent with generator.
  final variableToJsonKey = _buildVariableToJsonKeyMap(allJsonKeys);

  final usedJsonKeys = <String>{};
  for (final usedVar in scan.usedKeyVariables) {
    final jsonKey = variableToJsonKey[usedVar];
    if (jsonKey != null) {
      usedJsonKeys.add(jsonKey);
    }
  }

  var rewrittenLaterCount = 0;
  var addedKeysCount = 0;

  // Promote later() sites.
  if (promoteLater) {
    final defaultJson = intlJsonByBasename[defaultBasename]!;

    String? findExistingKeyForText(String text) {
      for (final entry in defaultJson.entries) {
        final v = _extractNeutralOther(entry.value);
        if (v != null && v == text) {
          return entry.key;
        }
      }
      return null;
    }

    final existingKeys = <String>{...allJsonKeys};

    // Deterministic processing order.
    final laterEntries = scan.laterCallSitesByFile.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    // Track chosen keys to reuse within this run.
    final promotedTextToKey = <String, String>{};

    for (final entry in laterEntries) {
      final sites = entry.value.toList()
        ..sort((a, b) => a.offset.compareTo(b.offset));

      for (final site in sites) {
        final text = site.text;

        final existing =
            promotedTextToKey[text] ?? findExistingKeyForText(text);
        final key =
            existing ??
            _allocateKeyForText(text: text, existingKeys: existingKeys);

        promotedTextToKey[text] = key;

        if (!existingKeys.contains(key)) {
          existingKeys.add(key);
          allJsonKeys.add(key);
          defaultJson[key] = text;
          addedKeysCount++;
        }

        usedJsonKeys.add(key);
      }
    }

    // Recompute var mapping with newly added keys.
    final updatedVarToJsonKey = _buildVariableToJsonKeyMap(allJsonKeys);
    final jsonKeyToVar = <String, String>{
      for (final e in updatedVarToJsonKey.entries) e.value: e.key,
    };

    // Rewrite Dart files.
    for (final entry in laterEntries) {
      final filePath = entry.key;
      final sites = entry.value.toList()
        ..sort((a, b) => a.offset.compareTo(b.offset));
      var source = File(filePath).readAsStringSync();

      final edits = <({int offset, int end, String replacement})>[];

      for (final site in sites) {
        final key =
            promotedTextToKey[site.text] ?? findExistingKeyForText(site.text);
        if (key == null) {
          continue;
        }

        final keyVar = jsonKeyToVar[key];
        if (keyVar == null) {
          continue;
        }

        // Keep only supported named args.
        final named = <String, String>{};
        for (final name in const [
          'map',
          'filters',
          'count',
          'gender',
          'precision',
          'locale',
          'strict',
        ]) {
          final v = site.namedArgSource[name];
          if (v != null) {
            named[name] = v;
          }
        }

        final replacement = _buildReplacementInvocation(
          prefix: site.invocationPrefix,
          className: className,
          keyVariable: keyVar,
          namedArgs: named,
        );

        edits.add((
          offset: site.offset,
          end: site.end,
          replacement: replacement,
        ));
      }

      if (edits.isEmpty) {
        continue;
      }

      // Apply edits from end to start.
      for (final edit in edits.reversed) {
        source = source.replaceRange(edit.offset, edit.end, edit.replacement);
      }

      rewrittenLaterCount += edits.length;

      if (!dryRun) {
        File(filePath).writeAsStringSync(source);
      }
    }
  }

  // Prune unused keys.
  var removedKeysCount = 0;
  var jsonFilesUpdated = 0;

  if (pruneUnused) {
    for (final entry in intlJsonByBasename.entries) {
      final json = entry.value;
      final before = json.length;
      json.removeWhere((k, v) => !usedJsonKeys.contains(k));
      final removed = before - json.length;
      if (removed > 0) {
        removedKeysCount += removed;
        jsonFilesUpdated++;
      }
    }
  }

  // Write JSON files (if requested) with stable ordering.
  if (!dryRun && (pruneUnused || promoteLater)) {
    for (final entry in intlJsonByBasename.entries) {
      final outPath = p.join(sourceDir, entry.key);
      final encoded = _encodeJsonSorted(entry.value);
      File(outPath).writeAsStringSync('$encoded\n');
    }
  }

  return PreprocessResult(
    updatedIntlJsonByBasename: intlJsonByBasename,
    dartFilesUpdated: dryRun
        ? 0
        : (promoteLater ? scan.laterCallSitesByFile.length : 0),
    jsonFilesUpdated: dryRun ? 0 : jsonFilesUpdated,
    removedKeysCount: removedKeysCount,
    addedKeysCount: addedKeysCount,
    rewrittenLaterCount: rewrittenLaterCount,
  );
}
