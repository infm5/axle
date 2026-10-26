import 'dart:io';

import 'package:axle_cli/axle_cli.dart';
import 'package:test/test.dart';

void main() {
  late Map<String, Object?> paths;
  late Map<String, Object?> schemas;

  setUpAll(() async {
    final result = await OpenApiGenerator(
      config: AxleConfig(
        title: 'Media',
        version: '1.0.0',
        scan: const ['test/fixtures/media_types'],
      ),
      projectRoot: Directory.current,
    ).generate();
    final json = result.document.toJson();
    paths = json['paths']! as Map<String, Object?>;
    schemas =
        (json['components']! as Map<String, Object?>)['schemas']!
            as Map<String, Object?>;
  });

  Map<String, Object?> operation(String path, String method) =>
      (paths[path]! as Map)[method]! as Map<String, Object?>;

  Map<String, Object?> content(Map<String, Object?> holder) =>
      holder['content']! as Map<String, Object?>;

  Map<String, Object?> response(String path, String method, String status) =>
      ((operation(path, method)['responses']! as Map)[status]!
          as Map<String, Object?>);

  group('binary media types', () {
    test('raw bytes under a non-JSON media type are format: binary', () {
      final body = content(
        operation('/raw', 'put')['requestBody']! as Map<String, Object?>,
      );
      expect((body['application/octet-stream']! as Map)['schema'], {
        'type': 'string',
        'format': 'binary',
      });
      expect(
        (content(response('/raw', 'put', '200'))['image/png']!
            as Map)['schema'],
        {'type': 'string', 'format': 'binary'},
      );
    });

    test('bytes inside JSON stay base64', () {
      final jsonBytes =
          (content(response('/raw', 'put', '201'))['application/json']!
              as Map)['schema'];
      expect(jsonBytes, {'type': 'string', 'format': 'byte'});
      expect(((schemas['Blob']! as Map)['properties']! as Map)['data'], {
        'type': 'string',
        'format': 'byte',
        'description': 'Bytes inside JSON are base64 text.',
      });
    });

    test('a constraint on a list property describes its items', () {
      final attachments =
          ((schemas['Upload']! as Map)['properties']! as Map)['attachments'];
      expect(attachments, {
        'type': 'array',
        'items': {'type': 'string', 'format': 'binary'},
      });
    });
  });

  group('one status, several media types', () {
    test('responses that share a status merge their media types', () {
      final ok = response('/report', 'get', '200');
      expect(content(ok).keys, [
        'application/json',
        'text/csv',
        'application/x-ndjson',
      ]);
    });

    test('each media type keeps its own schema', () {
      final ok = content(response('/report', 'get', '200'));
      expect((ok['application/json']! as Map)['schema'], {
        r'$ref': '#/components/schemas/Report',
      });
      expect((ok['text/csv']! as Map)['schema'], {'type': 'string'});
    });

    test('headers and the description survive the merge', () {
      final ok = response('/report', 'get', '200');
      expect(ok['headers'], contains('Content-Disposition'));
      expect(ok['description'], 'OK');
    });

    test('other statuses are untouched', () {
      expect((operation('/report', 'get')['responses']! as Map).keys, [
        '200',
        '404',
      ]);
    });
  });

  group('several request bodies', () {
    test('bodies merge into one request body with a schema per media type', () {
      final body =
          operation('/documents/{id}', 'patch')['requestBody']!
              as Map<String, Object?>;
      final media = content(body);
      expect(media.keys, [
        'application/merge-patch+json',
        'application/json-patch+json',
      ]);
      expect((media['application/merge-patch+json']! as Map)['schema'], {
        r'$ref': '#/components/schemas/MergePatch',
      });
      expect((media['application/json-patch+json']! as Map)['schema'], {
        'type': 'array',
        'items': {r'$ref': '#/components/schemas/PatchOperation'},
      });
    });

    test('the body is required when any alternative is', () {
      final body = operation('/documents/{id}', 'patch')['requestBody']! as Map;
      expect(body['required'], true);
    });
  });
}
