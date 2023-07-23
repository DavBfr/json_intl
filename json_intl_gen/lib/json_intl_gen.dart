import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'src/linter/using_later.dart';

/// This is the entrypoint of our plugin.
PluginBase createPlugin() => _JsonIntlLint();

class _JsonIntlLint extends PluginBase {
  @override
  List<LintRule> getLintRules(configs) => const [
        UsingLater(),
      ];

  @override
  List<Assist> getAssists() => [];
}
