import 'dart:io';

import 'package:axle_cli/axle_cli.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  _cliTests();

  group('diagnostics', () {
    late AxleDiagnosticsException error;

    setUpAll(() async {
      final config = AxleConfig(
        title: 'Broken API',
        version: '1.0.0',
        scan: const ['test/fixtures/multi_error'],
      );
      try {
        await OpenApiGenerator(
          config: config,
          projectRoot: Directory.current,
        ).generate();
        fail('Expected generation to fail.');
      } on AxleDiagnosticsException catch (caught) {
        error = caught;
      }
    });

    test('collects every problem instead of stopping at the first', () {
      expect(error.diagnostics.map((e) => e.message), [
        contains('Duplicate route GET /duplicate'),
        contains('declares unused path parameters: other'),
        contains('Unsupported Dart type'),
      ]);
      expect(error.exitCode, AxleExitCode.data);
    });

    test('reports a broken DTO once, however many routes use it', () {
      final unsupported = error.diagnostics.where(
        (e) => e.message.contains('Unsupported Dart type'),
      );
      expect(unsupported, hasLength(1));
    });

    test('points route errors at the handler', () {
      final duplicate = error.diagnostics.first.location!;
      expect(p.basename(duplicate.file), 'api.dart');
      expect(duplicate.line, 12);
      expect(duplicate.column, 17);
    });

    test('points DTO errors at the offending field', () {
      final location = error.diagnostics.last.location!;
      expect(location.line, 5);
    });

    test('formats like a compiler diagnostic', () {
      final lines = error.formatted.split('\n');
      expect(lines, hasLength(3));
      for (final line in lines) {
        expect(line, matches(RegExp(r'api\.dart:\d+:\d+: error: ')));
      }
    });
  });

  test('AxleException without a location formats as its message', () {
    const error = AxleException('plain');
    expect(error.formatted, 'plain');
    final located = error.withLocation(
      const SourceLocation(file: 'a.dart', line: 3, column: 4),
    );
    expect(located.formatted, 'a.dart:3:4: error: plain');
    expect(
      located
          .withLocation(
            const SourceLocation(file: 'b.dart', line: 1, column: 1),
          )
          .location!
          .file,
      'a.dart',
    );
  });
}

void _cliTests() {
  test('axle gen prints one located line per problem and exits 65', () async {
    final buffer = StringBuffer();
    final sink = _CapturedSink(buffer);
    final code = await IOOverrides.runZoned(
      () => runCli(['gen', '--config', 'test/fixtures/multi_error.yaml']),
      stderr: () => sink,
    );

    expect(code, AxleExitCode.data);
    final lines = buffer.toString().trim().split('\n');
    expect(lines, hasLength(3));
    for (final line in lines) {
      expect(line, matches(RegExp(r'^axle: .*api\.dart:\d+:\d+: error: ')));
    }
  });
}

class _CapturedSink implements Stdout {
  _CapturedSink(this._buffer);

  final StringBuffer _buffer;

  @override
  void writeln([Object? object = '']) => _buffer.writeln(object);

  @override
  void write(Object? object) => _buffer.write(object);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
