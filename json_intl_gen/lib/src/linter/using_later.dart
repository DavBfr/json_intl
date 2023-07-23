import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

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
    context.registry.addMethodInvocation((node) {
      if (!analysisError.sourceRange.intersects(node.sourceRange)) {
        return;
      }

      final arg = node.argumentList.arguments.first;
      final newSymbol = outputVar(arg.toSource(), camelCase: true);
      final newKey = outputVar(arg.toSource(), sep: '_').toLowerCase();

      final changeBuilder = reporter.createChangeBuilder(
        message: 'Add translation key $newSymbol ($newKey)',
        priority: 1,
      );
      changeBuilder.addDartFileEdit((builder) {
        builder.addReplacement(arg.sourceRange, (builder) {
          builder.addSimpleLinkedEdit('later', 'IntlKeys.$newSymbol');
        });
        builder.addReplacement(node.methodName.sourceRange, (builder) {
          builder.addSimpleLinkedEdit('later', 'get');
        });
      });
    });
  }
}
