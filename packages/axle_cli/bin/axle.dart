import 'dart:io';

import 'package:axle_cli/src/cli.dart';

Future<void> main(List<String> args) async {
  exitCode = await runCli(args);
}
