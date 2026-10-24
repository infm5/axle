/// The `axle init` command.
library;

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import '../config.dart';
import '../errors.dart';

/// Creates `axle.yaml` and prints the integration steps.
class InitCommand extends Command<int> {
  /// Creates the command.
  InitCommand() {
    argParser
      ..addOption(
        'project',
        abbr: 'p',
        defaultsTo: '.',
        help: 'The Dart package root.',
      )
      ..addFlag(
        'force',
        abbr: 'f',
        negatable: false,
        help: 'Overwrite an existing axle.yaml.',
      );
  }

  @override
  String get name => 'init';

  @override
  String get description => 'Create axle.yaml and print the setup steps.';

  @override
  Future<int> run() async {
    final root = Directory(argResults!.option('project')!).absolute;
    final pubspec = readPubspecInfo(root);
    final configFile = File(p.join(root.path, AxleConfig.fileName));

    if (configFile.existsSync() && !argResults!.flag('force')) {
      throw AxleException(
        '${configFile.path} already exists. Use --force to overwrite it.',
        exitCode: AxleExitCode.config,
      );
    }

    final config = AxleConfig.fromPubspec(root);
    configFile.writeAsStringSync(config.toYamlString());

    stdout.writeln('Created ${p.relative(configFile.path, from: root.path)}.');

    stdout
      ..writeln()
      ..writeln('Next steps:')
      ..writeln(
        '  1. Add an axle adapter for your server framework and the CLI to',
      )
      ..writeln('     pubspec.yaml (if not already present):')
      ..writeln('       dependencies:')
      ..writeln('         # e.g. axle_relic: ^0.2.0')
      ..writeln('       dev_dependencies:')
      ..writeln('         axle_cli: ^0.2.0')
      ..writeln()
      ..writeln('  2. Review axle.yaml. It is the source of truth for API')
      ..writeln('     identity and generator paths.')
      ..writeln()
      ..writeln('  3. Annotate top-level handlers with @ApiRoute:')
      ..writeln('       @ApiRoute(')
      ..writeln('         method: ApiMethod.get,')
      ..writeln("         path: '/users/:id',")
      ..writeln("         pathParams: [ApiPathParam('id', type: int)],")
      ..writeln('         responses: [ApiResponse.ok(UserDto)],')
      ..writeln('       )')
      ..writeln('       Future<Result> getUser(Request request) async { ... }')
      ..writeln()
      ..writeln('  4. Mount the generated docs with your adapter:')
      ..writeln("       import 'package:your_adapter/your_adapter.dart';")
      ..writeln(
        "       import 'package:${pubspec.name}/src/generated/openapi.g.dart';",
      )
      ..writeln()
      ..writeln('       app.mountAxleDocs(spec: axleOpenApiJson);')
      ..writeln()
      ..writeln('  5. Generate the document:')
      ..writeln('       dart run axle_cli:axle gen');

    return AxleExitCode.success;
  }
}
