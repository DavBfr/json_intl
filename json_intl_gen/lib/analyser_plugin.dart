import 'dart:io';
import 'dart:isolate';

import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer_plugin/plugin/plugin.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/starter.dart';
import 'package:path/path.dart' as path;

void start(List<String> args, SendPort sendPort) {
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
    final f = File('lint.txt');
    final s = f.openWrite(mode: FileMode.append);
    s.write('$path\n');
    s.close();

    final root = analysisContext.contextRoot.root.path;

    final isAnalyzed = analysisContext.contextRoot.isAnalyzed(path);
    final isExcluded = !isAnalyzed;
    if (isExcluded) {
      channel.sendNotification(
        AnalysisErrorsParams(
          path,
          <AnalysisError>[],
        ).toNotification(),
      );
      return;
    }
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
    final errors = _check(root, path, analysisResult.unit, analysisResult);
    channel.sendNotification(
      AnalysisErrorsParams(
        path,
        errors.map((e) => e.error).toList(),
      ).toNotification(),
    );
  }

  List<AnalysisErrorFixes> _check(
    String? root,
    String filePath,
    CompilationUnit unit,
    ResolvedUnitResult analysisResult,
  ) {
    final errors = <AnalysisErrorFixes>[];

    var relative = '';
    if (root != null) {
      relative = path.relative(filePath, from: root);
    }

    final visitor = MyVisitor<dynamic>(
      filePath: filePath,
      unit: unit,
      foundSomething: (location) {
        final content = analysisResult.content;

        errors.add(
          AnalysisErrorFixes(
            AnalysisError(
              AnalysisErrorSeverity('WARNING'),
              AnalysisErrorType.LINT,
              location,
              'Found function call:',
              'pouet',
              correction: 'Do something! ($filePath) ($relative)',
              hasFix: false,
            ),
            // fixes: [
            //   ...?_extractStringFix(
            //     analysisOptions,
            //     arbFile,
            //     filePath,
            //     foundIntl,
            //     analysisResult,
            //   ),
            //   fix,
            // ],
          ),
        );
      },
    );
    unit.visitChildren(visitor);
    return errors;
  }
}

class MyVisitor<R> extends GeneralizingAstVisitor<R> {
  MyVisitor({
    required this.filePath,
    required this.unit,
    required this.foundSomething,
  }) : lineInfo = unit.lineInfo;

  final String filePath;
  final CompilationUnit unit;
  final LineInfo? lineInfo;

  final void Function(Location l) foundSomething;

  @override
  R? visitFunctionReference(FunctionReference node) {
    final lineInfo = unit.lineInfo;
    final begin = node.beginToken.charOffset;
    final end = node.endToken.charEnd;
    final loc = lineInfo.getLocation(begin);
    final locEnd = lineInfo.getLocation(end);

    foundSomething(Location(
      filePath,
      node.offset,
      node.length,
      loc.lineNumber,
      loc.columnNumber,
      endLine: locEnd.lineNumber,
      endColumn: locEnd.columnNumber,
    ));

    return super.visitFunctionReference(node);
  }
}
