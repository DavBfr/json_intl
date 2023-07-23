import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:path/path.dart' as p;

import '../../generator.dart';
import '../generator_utils.dart';

class UsingLater extends DartLintRule {
  const UsingLater() : super(code: _code);

  static const _code = LintCode(
    name: 'json_intl_later',
    problemMessage: 'Using later translation with text {0}',
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addMethodInvocation((node) {
      if (node.methodName.name == 'later' &&
          node.realTarget?.staticType?.element?.name == 'JsonIntl') {
        final arg = node.argumentList.arguments.first;
        reporter.reportErrorForNode(code, node, [arg.toSource()]);
      }
    });
  }

  @override
  List<Fix> getFixes() => [_AddLaterFix()];
}

class _AddLaterFix extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    AnalysisError analysisError,
    List<AnalysisError> others,
  ) {
    final f = File(
        '/Users/dad/Documents/Perso/llConvertAS/vendor/json_intl/json_intl_gen/OUTPUT.txt');

    var path = p.dirname(resolver.path);
    var pubspecFile = '';
    while (true) {
      pubspecFile = p.join(path, 'pubspec.yaml');
      if (File(pubspecFile).existsSync()) {
        break;
      }
      final newPath = p.dirname(path);
      if (newPath == path) return;
      path = newPath;
    }

    f.writeAsStringSync(pubspecFile);

    final pubspec = File(pubspecFile).readAsStringSync();
    final pubspecOptions = GeneratorOptions.builder.loadFromYaml(pubspec);

    context.registry.addMethodInvocation((node) {
      if (!analysisError.sourceRange.intersects(node.sourceRange)) {
        return;
      }

      if (node.methodName.name != 'later' ||
          node.realTarget?.staticType?.element?.name != 'JsonIntl') {
        return;
      }

      final arg = node.argumentList.arguments.first;
      if (arg is! SimpleStringLiteral) {
        return;
      }

      final newSymbol = outputVar(arg.toSource(), camelCase: true);
      final newKey = outputVar(arg.toSource(), sep: '_').toLowerCase();
      final intlDir =
          Directory(p.join(p.dirname(pubspecFile), pubspecOptions.source));
      if (!intlDir.existsSync()) {
        intlDir.createSync(recursive: true);
      }
      final strings = File(p.join(
          p.dirname(pubspecFile), pubspecOptions.source, 'strings.json'));

      final changeBuilder = reporter.createChangeBuilder(
        message: 'Add translation key "$newKey"',
        priority: 1,
      );
      changeBuilder.addDartFileEdit((builder) {
        builder.addReplacement(arg.sourceRange, (builder) {
          var tr = {};
          if (strings.existsSync()) {
            tr = json.decode(strings.readAsStringSync());
          }
          tr[newKey] = arg.value;
          const enc = JsonEncoder.withIndent('  ');
          strings.writeAsStringSync('${enc.convert(tr)}\n');

          generateIntl(pubspecOptions, basedir: p.dirname(pubspecFile))
              .then((value) {
            File(p.join(p.dirname(pubspecFile), pubspecOptions.output))
                .writeAsStringSync(value);
          });

          builder.addSimpleLinkedEdit(
              'later', '${pubspecOptions.className}.$newSymbol');
        });
        builder.addReplacement(node.methodName.sourceRange, (builder) {
          if (node.argumentList.arguments.length == 1) {
            builder.addSimpleLinkedEdit('later', 'get');
          } else {
            builder.addSimpleLinkedEdit('later', 'translate');
          }
        });
      });
    });
  }
}
