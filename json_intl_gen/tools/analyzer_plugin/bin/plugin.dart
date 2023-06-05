import 'dart:isolate';

import 'package:json_intl_gen/analyser_plugin.dart';

void main(List<String> args, SendPort sendPort) {
  start(args, sendPort);
}
