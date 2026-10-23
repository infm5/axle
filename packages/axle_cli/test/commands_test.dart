import 'dart:convert';
import 'dart:io';

import 'package:axle_cli/axle_cli.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void main() {
  group('init command', () {
    test('creates axle.yaml and refuses to overwrite it', () async {
      final temp = Directory.systemTemp.createTempSync('axle_init_');
      addTearDown(() => temp.deleteSync(recursive: true));
      Directory(p.join(temp.path, 'lib')).createSync();
      File(p.join(temp.path, 'pubspec.yaml')).writeAsStringSync('''
name: sample_api
version: 0.4.0
description: A sample API.
dependencies:
  relic: ^2.0.0-rc.2
''');

      final code = await runCli(['init', '--project', temp.path]);
      expect(code, AxleExitCode.success);

      final configFile = File(p.join(temp.path, AxleConfig.fileName));
      expect(configFile.existsSync(), isTrue);

      final config = AxleConfig.load(temp);
      expect(config.title, 'Sample Api');
      expect(config.version, '0.4.0');
      expect(config.description, 'A sample API.');
      expect(config.scan, ['lib']);
      expect(config.swaggerUiOutput, 'assets/swagger-ui');

      final secondRun = await runCli(['init', '--project', temp.path]);
      expect(secondRun, AxleExitCode.config);

      final forced = await runCli(['init', '--project', temp.path, '--force']);
      expect(forced, AxleExitCode.success);
      expect(AxleConfig.load(temp).title, 'Sample Api');
    });

    test('rejects removed title and version flags', () async {
      final temp = Directory.systemTemp.createTempSync('axle_init_');
      addTearDown(() => temp.deleteSync(recursive: true));
      Directory(p.join(temp.path, 'lib')).createSync();
      File(p.join(temp.path, 'pubspec.yaml')).writeAsStringSync('''
name: sample_api
version: 0.4.0
''');

      final code = await runCli([
        'init',
        '--project',
        temp.path,
        '--title',
        'Forced API',
      ]);
      expect(code, AxleExitCode.usage);
    });

    test('fails outside a Dart package', () async {
      final temp = Directory.systemTemp.createTempSync('axle_init_');
      addTearDown(() => temp.deleteSync(recursive: true));

      final code = await runCli(['init', '--project', temp.path]);
      expect(code, AxleExitCode.config);
    });
  });

  group('gen command', () {
    test('writes and checks JSON, YAML, and Dart artifacts', () async {
      final root = Directory.current;
      final outputDir = Directory(p.join(root.path, '.dart_tool', 'axle_test'));
      if (outputDir.existsSync()) outputDir.deleteSync(recursive: true);
      addTearDown(() {
        if (outputDir.existsSync()) outputDir.deleteSync(recursive: true);
      });

      final args = [
        'gen',
        '--project',
        root.path,
        '--config',
        'test/fixtures/axle_test.yaml',
      ];

      final code = await runCli(args);
      expect(code, AxleExitCode.success);

      final jsonFile = File(p.join(outputDir.path, 'openapi.json'));
      final yamlFile = File(p.join(outputDir.path, 'openapi.yaml'));
      final dartFile = File(p.join(outputDir.path, 'openapi.g.dart'));
      final uiDirectory = Directory(p.join(outputDir.path, 'swagger-ui'));
      final uiCss = File(p.join(uiDirectory.path, 'swagger-ui.css'));
      final uiBundle = File(p.join(uiDirectory.path, 'swagger-ui-bundle.js'));
      expect(jsonFile.existsSync(), isTrue);
      expect(yamlFile.existsSync(), isTrue);
      expect(dartFile.existsSync(), isTrue);
      expect(uiCss.existsSync(), isTrue);
      expect(uiBundle.existsSync(), isTrue);
      expect(uiCss.lengthSync(), greaterThan(1000));
      expect(uiBundle.lengthSync(), greaterThan(1000000));

      final json = jsonDecode(jsonFile.readAsStringSync()) as Map;
      expect(json['info']['title'], 'Axle CLI Test');
      expect(json.containsKey('servers'), isFalse);
      final yaml = loadYaml(yamlFile.readAsStringSync()) as YamlMap;
      expect(yaml['info']['title'], 'Axle CLI Test');
      expect(
        dartFile.readAsStringSync(),
        contains('const String axleOpenApiJson ='),
      );

      final check = await runCli([...args, '--check']);
      expect(check, AxleExitCode.success);

      dartFile.writeAsStringSync('// stale');
      final staleDart = await runCli([...args, '--check']);
      expect(staleDart, AxleExitCode.data);

      yamlFile.writeAsStringSync('stale: true\n');
      final staleYaml = await runCli([...args, '--check']);
      expect(staleYaml, AxleExitCode.data);

      jsonFile.writeAsStringSync('// stale');
      final staleJson = await runCli([...args, '--check']);
      expect(staleJson, AxleExitCode.data);

      uiCss.writeAsStringSync('/* stale */');
      final staleUi = await runCli([...args, '--check']);
      expect(staleUi, AxleExitCode.data);
    });

    test(
      'writes an empty spec and verbose details with no libraries',
      () async {
        final temp = Directory.systemTemp.createTempSync('axle_gen_');
        addTearDown(() => temp.deleteSync(recursive: true));
        Directory(p.join(temp.path, 'lib')).createSync();
        File(p.join(temp.path, AxleConfig.fileName)).writeAsStringSync('''
openapi: 3.1.0
info:
  title: Empty API
  version: 1.0.0
generate:
  scan: [lib]
  output:
    json: .dart_tool/openapi.json
    ui: .dart_tool/swagger-ui
    dart: .dart_tool/openapi.g.dart
''');

        final code = await runCli(['gen', '--project', temp.path, '--verbose']);

        expect(code, AxleExitCode.success);
        final jsonFile = File(p.join(temp.path, '.dart_tool', 'openapi.json'));
        final yamlFile = File(p.join(temp.path, '.dart_tool', 'openapi.yaml'));
        final dartFile = File(
          p.join(temp.path, '.dart_tool', 'openapi.g.dart'),
        );
        final uiCss = File(
          p.join(temp.path, '.dart_tool', 'swagger-ui', 'swagger-ui.css'),
        );
        expect(jsonFile.existsSync(), isTrue);
        expect(yamlFile.existsSync(), isTrue);
        expect(dartFile.existsSync(), isTrue);
        expect(uiCss.existsSync(), isTrue);
        expect(
          loadYaml(yamlFile.readAsStringSync())['info']['title'],
          'Empty API',
        );
        expect(jsonDecode(jsonFile.readAsStringSync()), {
          'openapi': '3.1.0',
          'info': {'title': 'Empty API', 'version': '1.0.0'},
          'paths': <String, Object?>{},
        });
      },
    );
  });

  test('rejects unknown commands with a usage error', () async {
    expect(await runCli(['unknown']), AxleExitCode.usage);
  });
}
