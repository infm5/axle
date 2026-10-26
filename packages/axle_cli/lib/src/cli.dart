/// The axle command-line interface.
library;

import 'dart:io';

import 'package:args/command_runner.dart';

import 'commands/gen_command.dart';
import 'commands/init_command.dart';
import 'errors.dart';

/// Runs the CLI and returns a process exit code.
Future<int> runCli(List<String> args) async {
  final runner =
      CommandRunner<int>(
          'axle',
          'Generate OpenAPI 3.1 documents for Dart servers.',
        )
        ..addCommand(InitCommand())
        ..addCommand(GenCommand());

  try {
    return await runner.run(args) ?? AxleExitCode.success;
  } on UsageException catch (error) {
    stderr
      ..writeln(error.message)
      ..writeln()
      ..writeln(error.usage);
    return AxleExitCode.usage;
  } on AxleException catch (error) {
    for (final line in error.formatted.split('\n')) {
      stderr.writeln('axle: $line');
    }
    return error.exitCode;
  } on Object catch (error, stackTrace) {
    stderr.writeln('axle: unexpected error: $error');
    if (args.contains('--verbose') || args.contains('-v')) {
      stderr.writeln(stackTrace);
    }
    return AxleExitCode.software;
  }
}
