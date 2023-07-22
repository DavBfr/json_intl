import 'dart:io';
import 'dart:isolate';

import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer_plugin/plugin/plugin.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/starter.dart';
import 'package:logging/logging.dart';
import 'package:logging_appenders/logging_appenders.dart';
import 'package:path/path.dart' as path;

final _log = Logger('json_intl');

void start(List<String> args, SendPort sendPort) {
  Logger.root.clearListeners();
  Logger.root.level = Level.ALL;
  final home = Platform.environment['HOME']!;
  final appender = RotatingFileAppender(
    baseFilePath: path.join(home, 'json_intl.log.txt'),
  );
  appender.attachToLogger(Logger.root);

  _log.info('START');

  ServerPluginStarter(
          MyPlugin(resourceProvider: PhysicalResourceProvider.INSTANCE))
      .start(sendPort);
}

class MyPlugin extends ServerPlugin {
  MyPlugin({required super.resourceProvider});

  @override
  List<String> get fileGlobsToAnalyze => <String>['**/*.dart'];

  @override
  String get name => 'Json Intl';

  @override
  String get version => '1.0.0';

  @override
  Future<void> analyzeFile({
    required AnalysisContext analysisContext,
    required String path,
  }) async {
    if (!path.endsWith('.dart')) {
      return;
    }

    final errors = <AnalysisErrorFixes>[];

    final analysisResult =
        await analysisContext.currentSession.getResolvedUnit(path);

    if (analysisResult is! ResolvedUnitResult) {
      channel.sendNotification(
        AnalysisErrorsParams(
          path,
          [],
        ).toNotification(),
      );
      return;
    }

    final visitor = JsonIntlVisitor<dynamic>(
      errors,
      path,
      analysisResult,
    );

    analysisResult.unit.visitChildren(visitor);

    channel.sendNotification(
      AnalysisErrorsParams(
        path,
        errors.map((e) => e.error).toList(),
      ).toNotification(),
    );
  }
}

class JsonIntlVisitor<R> extends GeneralizingAstVisitor<R> {
  JsonIntlVisitor(this.errors, this.path, this.analysisResult);

  final List<AnalysisErrorFixes> errors;

  final String path;

  final ResolvedUnitResult analysisResult;

  @override
  R? visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == 'later' &&
        node.realTarget?.staticType?.element?.name == 'JsonIntl') {
      _log.warning('${node.offset} ${node.length} ${node.end}');

      final arg = node.argumentList.arguments.first;

      errors.add(
        AnalysisErrorFixes(
          AnalysisError(
            AnalysisErrorSeverity('WARNING'),
            AnalysisErrorType.LINT,
            Location(
              path,
              node.offset,
              node.length,
              0,
              0,
            ),
            'Using later translation',
            'json_intl_later',
            correction: 'Replace with get, count, gender or translate',
            hasFix: true,
          ),
          fixes: [
            PrioritizedSourceChange(
              1,
              SourceChange(
                'Do it',
                edits: [
                  SourceFileEdit(
                    path,
                    analysisResult.exists ? 0 : -1,
                    edits: [
                      SourceEdit(arg.offset, arg.length, '\'COUCOU\''),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return super.visitMethodInvocation(node);
  }
}
