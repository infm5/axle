import 'dart:io';

import 'package:axle_cli/axle_cli.dart';
import 'package:test/test.dart';

/// These cases were checked against the real builders: for each `build.yaml`
/// below, `json_serializable`, `freezed`, and `dart_mappable_builder` were run
/// and their generated encoders compared with the expectations here.
Future<OpenApiGenerator> _generator(
  String name, {
  String scan = 'api.dart',
}) async {
  return OpenApiGenerator(
    config: AxleConfig(title: name, version: '1.0.0', scan: [scan]),
    projectRoot: Directory('test/fixtures/build_yaml/$name'),
  );
}

Future<Map<String, Object?>> _schemas(
  String name, {
  String scan = 'api.dart',
}) async {
  final result = await (await _generator(name, scan: scan)).generate();
  return ((result.document.toJson()['components']! as Map)['schemas']!
      as Map<String, Object?>);
}

List<String> _keys(Map<String, Object?> schemas, String name) =>
    (((schemas[name]! as Map)['properties']! as Map).keys)
        .cast<String>()
        .toList()
      ..sort();

void main() {
  group('json_serializable field_rename', () {
    for (final name in ['json_rename', 'json_global']) {
      group('from ${name == 'json_rename' ? 'targets' : 'global_options'}', () {
        late Map<String, Object?> schemas;
        setUpAll(() async => schemas = await _schemas(name));

        test('applies to a class that leaves fieldRename unset', () {
          expect(_keys(schemas, 'Defaulted'), ['keyed_name', 'user_name']);
        });

        test('yields to an explicit FieldRename.none', () {
          expect(_keys(schemas, 'Overridden'), ['keyedName', 'userName']);
        });

        test('yields to an explicit rename', () {
          expect(_keys(schemas, 'Kebab'), ['user-name']);
        });

        test('does not touch a class json_serializable does not process', () {
          expect(_keys(schemas, 'Plain'), ['userName']);
        });
      });
    }

    test('applies to a freezed class with a fromJson factory', () async {
      final schemas = await _schemas('freezed_rename', scan: 'routes.dart');
      expect(_keys(schemas, 'Account'), ['login_count', 'user_name']);
    });

    test('lets a freezed factory annotation win over the default', () async {
      final schemas = await _schemas('freezed_rename', scan: 'routes.dart');
      expect(_keys(schemas, 'Kept'), ['userName']);
    });
  });

  group('json_serializable ignore_unannotated', () {
    test('build.yaml drops fields without @JsonKey', () async {
      final schemas = await _schemas('json_ignore');
      expect(_keys(schemas, 'Defaulted'), ['keyedName']);
    });

    test('an explicit ignoreUnannotated: false keeps them', () async {
      final schemas = await _schemas('json_ignore');
      expect(_keys(schemas, 'Overridden'), ['keyedName', 'userName']);
    });

    test('a class can ask for it without build.yaml', () async {
      final schemas = await _schemas('json_class_ignore');
      expect(_keys(schemas, 'OnlyKeyed'), ['keyedName']);
      expect(_keys(schemas, 'Everything'), ['keyedName', 'userName']);
    });

    test('a field ignored this way is also not required', () async {
      final schemas = await _schemas('json_ignore');
      expect((schemas['Defaulted']! as Map)['required'], ['keyedName']);
    });
  });

  group('dart_mappable_builder', () {
    late Map<String, Object?> schemas;
    setUpAll(() async => schemas = await _schemas('mappable'));

    test('caseStyle applies to a class that sets none', () {
      expect(_keys(schemas, 'A'), ['level', 'tier', 'unmapped', 'user_name']);
    });

    test('a class-level caseStyle wins', () {
      expect(_keys(schemas, 'B'), ['user-name']);
    });

    test('enumCaseStyle applies to a bare @MappableEnum', () {
      final level = ((schemas['A']! as Map)['properties']! as Map)['level'];
      expect(level, {
        'type': 'string',
        'enum': ['HIGHLEVEL', 'LOW'],
      });
    });

    test('an explicit enum caseStyle wins', () {
      final tier = ((schemas['A']! as Map)['properties']! as Map)['tier'];
      expect(tier, {
        'type': 'string',
        'enum': ['top_tier'],
      });
    });

    test('an enum dart_mappable does not map keeps its names', () {
      final unmapped =
          ((schemas['A']! as Map)['properties']! as Map)['unmapped'];
      expect(unmapped, {
        'type': 'string',
        'enum': ['someValue'],
      });
    });
  });

  group('values axle cannot trust', () {
    Matcher fails(String text) => throwsA(
      isA<AxleException>()
          .having((error) => error.exitCode, 'exit code', AxleExitCode.data)
          .having((error) => error.message, 'message', contains(text)),
    );

    test('an unknown field_rename fails with exit 65', () async {
      await expectLater(
        (await _generator('invalid_rename')).generate(),
        fails('field_rename: shouty'),
      );
    });

    test('the same option set two different ways fails with exit 65', () async {
      await expectLater(
        (await _generator('conflict')).generate(),
        fails('different values'),
      );
    });

    test('a caseStyle the builder ignores fails with exit 65', () async {
      await expectLater(
        (await _generator('mappable_unknown')).generate(),
        fails('upperSnakeCase'),
      );
    });
  });

  group('BuildOptions', () {
    test('is empty without a build.yaml', () {
      final options = BuildOptions.load(Directory('test/fixtures/api'));
      expect(options.jsonFieldRename, isNull);
      expect(options.jsonIgnoreUnannotated, isFalse);
    });

    test('parses dart_mappable custom case styles', () {
      final transform = caseStyleFromString('custom(lu,.)')!;
      expect(transform('userNameId'), 'user.NAME.ID');
      expect(caseStyleFromString('custom(c,-)')!('userName'), 'User-Name');
      expect(caseStyleFromString('nonsense'), isNull);
    });
  });
}
