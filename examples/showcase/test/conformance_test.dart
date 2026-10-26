/// Checks that the generated `openapi.json` describes what the server does.
///
/// Every case calls a real route and then asks the spec four questions:
///
/// 1. Is the status code declared (exactly, as a range, or as `default`)?
/// 2. Is the response's media type declared for that status?
/// 3. Does a JSON body validate against the declared schema?
/// 4. Are the headers the spec marks `required` actually there?
///
/// If a handler drifts from its annotations, regenerating the spec will not
/// hide it: the test fails.
library;

import 'dart:convert';
import 'dart:io';

import 'package:json_schema/json_schema.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:showcase_example/api.dart';
import 'package:test/test.dart';

void main() {
  late HttpServer server;
  late HttpClient client;
  late Map<String, Object?> spec;

  setUpAll(() async {
    spec =
        jsonDecode(File('openapi.json').readAsStringSync())
            as Map<String, Object?>;
    final router = Router();
    configureApi(router);
    server = await shelf_io.serve(router.call, 'localhost', 0);
    client = HttpClient();
  });

  tearDownAll(() async {
    client.close(force: true);
    await server.close(force: true);
  });

  /// Calls the server and checks the response against the spec.
  Future<_Reply> check(
    String method,
    String specPath,
    String url, {
    Map<String, String> headers = const {},
    Object? body,
    required int status,
    String? mediaType,
  }) async {
    final request = await client.openUrl(
      method,
      Uri.parse('http://localhost:${server.port}$url'),
    );
    request.followRedirects = false;
    headers.forEach(request.headers.set);
    if (body is String) request.write(body);
    if (body is List<int>) request.add(body);
    final response = await request.close();
    final bytes = await response.fold<List<int>>(
      [],
      (all, chunk) => all..addAll(chunk),
    );
    final reply = _Reply(
      status: response.statusCode,
      headers: {
        for (final name in _headerNames(response))
          name: response.headers.value(name)!,
      },
      bytes: bytes,
    );

    expect(reply.status, status, reason: '$method $url status');
    final operation = _operation(spec, specPath, method);
    final declared = _declaredResponse(operation, reply.status);
    expect(
      declared,
      isNotNull,
      reason: '$method $specPath: ${reply.status} is not described by the spec',
    );

    final content = (declared!['content'] as Map<String, Object?>?) ?? {};
    final actualType = (reply.headers['content-type'] ?? '')
        .split(';')
        .first
        .trim();
    if (content.isEmpty || method == 'HEAD') {
      if (method != 'HEAD') {
        expect(reply.bytes, isEmpty, reason: '$method $url has no body');
      }
    } else {
      expect(
        content.keys.map((type) => type.toLowerCase()),
        contains(actualType),
        reason:
            '$method $specPath: `$actualType` is not declared for '
            '${reply.status}',
      );
      if (mediaType != null) expect(actualType, mediaType);
      final media = content[actualType]! as Map<String, Object?>;
      final schema = media['schema'] as Map<String, Object?>?;
      if (schema != null && _isJson(actualType)) {
        _validate(spec, schema, jsonDecode(utf8.decode(reply.bytes)), url);
      } else if (schema != null && actualType == 'application/x-ndjson') {
        for (final line in const LineSplitter().convert(
          utf8.decode(reply.bytes),
        )) {
          _validate(spec, schema, jsonDecode(line), '$url (line)');
        }
      }
    }

    final declaredHeaders =
        (declared['headers'] as Map<String, Object?>?) ?? const {};
    for (final entry in declaredHeaders.entries) {
      final header = entry.value! as Map<String, Object?>;
      if (header['required'] == true) {
        expect(
          reply.headers,
          contains(entry.key.toLowerCase()),
          reason: '$method $specPath: required header ${entry.key}',
        );
      }
    }
    return reply;
  }

  group('media', () {
    for (final type in [
      'application/json',
      'application/xml',
      'application/yaml',
      'text/plain',
      'text/html',
      'text/markdown',
    ]) {
      test('greeting as $type', () async {
        await check(
          'GET',
          '/media/greeting',
          '/media/greeting',
          headers: {'accept': type},
          status: 200,
          mediaType: type,
        );
      });
    }

    test('greeting cannot be an image', () async {
      await check(
        'GET',
        '/media/greeting',
        '/media/greeting',
        headers: {'accept': 'image/gif'},
        status: 406,
      );
    });

    for (final type in [
      'application/json',
      'text/csv',
      'text/tab-separated-values',
    ]) {
      test('report as $type', () async {
        await check(
          'GET',
          '/media/report',
          '/media/report',
          headers: {'accept': type},
          status: 200,
          mediaType: type,
        );
      });
    }

    test('vendor media type', () async {
      await check(
        'GET',
        '/media/vendor',
        '/media/vendor',
        headers: {'accept': 'application/vnd.axle.v2+json'},
        status: 200,
        mediaType: 'application/vnd.axle.v2+json',
      );
    });

    test('ndjson stream', () async {
      final reply = await check(
        'GET',
        '/media/stream/ndjson',
        '/media/stream/ndjson?count=3',
        status: 200,
      );
      expect(
        const LineSplitter().convert(utf8.decode(reply.bytes)),
        hasLength(3),
      );
    });

    test('event stream', () async {
      await check(
        'GET',
        '/media/stream/events',
        '/media/stream/events?count=2',
        status: 200,
        mediaType: 'text/event-stream',
      );
    });

    test('images and conditional logo', () async {
      await check(
        'GET',
        '/media/logo',
        '/media/logo',
        headers: {'accept': 'image/png'},
        status: 200,
        mediaType: 'image/png',
      );
      await check(
        'GET',
        '/media/logo',
        '/media/logo',
        headers: {'accept': 'image/svg+xml'},
        status: 200,
        mediaType: 'image/svg+xml',
      );
      await check(
        'GET',
        '/media/logo',
        '/media/logo',
        headers: {'if-none-match': '"logo-v1"'},
        status: 304,
      );
    });

    test('pdf', () async {
      final reply = await check(
        'GET',
        '/media/document.pdf',
        '/media/document.pdf',
        status: 200,
        mediaType: 'application/pdf',
      );
      expect(utf8.decode(reply.bytes.take(5).toList()), '%PDF-');
    });

    test('blob, ranges, and raw upload', () async {
      await check('GET', '/media/blob', '/media/blob', status: 200);
      final partial = await check(
        'GET',
        '/media/blob',
        '/media/blob',
        headers: {'range': 'bytes=0-9'},
        status: 206,
      );
      expect(partial.bytes, List.generate(10, (i) => i));
      await check(
        'GET',
        '/media/blob',
        '/media/blob',
        headers: {'range': 'bytes=5000-'},
        status: 416,
      );
      await check(
        'PUT',
        '/media/blob',
        '/media/blob',
        headers: {'content-type': 'application/octet-stream'},
        body: [1, 2, 3],
        status: 201,
      );
      await check(
        'PUT',
        '/media/blob',
        '/media/blob',
        headers: {'content-type': 'text/plain'},
        body: 'x',
        status: 415,
      );
    });

    test('multipart upload', () async {
      const boundary = 'axle-boundary';
      String part(String name, String value) =>
          '--$boundary\r\ncontent-disposition: form-data; name="$name"\r\n\r\n'
          '$value\r\n';
      String file(String name, String filename, String data) =>
          '--$boundary\r\ncontent-disposition: form-data; name="$name"; '
          'filename="$filename"\r\ncontent-type: text/plain\r\n\r\n$data\r\n';
      final body = [
        part('title', 'Trip'),
        part('tags', 'a'),
        part('tags', 'b'),
        file('cover', 'cover.txt', 'cover'),
        file('attachments', 'one.txt', '111'),
        file('attachments', 'two.txt', '2222'),
        '--$boundary--\r\n',
      ].join();
      final reply = await check(
        'POST',
        '/media/upload',
        '/media/upload',
        headers: {'content-type': 'multipart/form-data; boundary=$boundary'},
        body: body,
        status: 201,
      );
      final result = jsonDecode(utf8.decode(reply.bytes)) as Map;
      expect((result['files'] as List).length, 3);
      expect(result['tags'], ['a', 'b']);

      await check(
        'POST',
        '/media/upload',
        '/media/upload',
        headers: {'content-type': 'application/json'},
        body: '{}',
        status: 415,
      );
      final options = await check(
        'OPTIONS',
        '/media/upload',
        '/media/upload',
        status: 204,
      );
      expect(options.headers['allow'], 'POST, OPTIONS');
    });

    test('login as a form and as JSON', () async {
      await check(
        'POST',
        '/media/login',
        '/media/login',
        headers: {'content-type': 'application/x-www-form-urlencoded'},
        body: 'username=demo&password=demo',
        status: 200,
      );
      await check(
        'POST',
        '/media/login',
        '/media/login',
        headers: {'content-type': 'application/json'},
        body: '{"username":"demo","password":"demo"}',
        status: 200,
      );
      await check(
        'POST',
        '/media/login',
        '/media/login',
        headers: {'content-type': 'application/json'},
        body: '{"username":"demo","password":"x"}',
        status: 401,
      );
      await check(
        'POST',
        '/media/login',
        '/media/login',
        headers: {'content-type': 'application/xml'},
        body: '<x/>',
        status: 415,
      );
    });

    test('patch in both formats', () async {
      await check(
        'PATCH',
        '/media/documents/{id}',
        '/media/documents/1',
        headers: {'content-type': 'application/merge-patch+json'},
        body: '{"title":"A"}',
        status: 200,
      );
      await check(
        'PATCH',
        '/media/documents/{id}',
        '/media/documents/1',
        headers: {'content-type': 'application/json-patch+json'},
        body: '[{"op":"replace","path":"/title","value":"B"}]',
        status: 200,
      );
      await check(
        'PATCH',
        '/media/documents/{id}',
        '/media/documents/1',
        headers: {'content-type': 'application/json-patch+json'},
        body: '[{"op":"remove","path":"/title"}]',
        status: 422,
      );
      await check(
        'PATCH',
        '/media/documents/{id}',
        '/media/documents/9',
        headers: {'content-type': 'application/merge-patch+json'},
        body: '{}',
        status: 404,
      );
      await check(
        'PATCH',
        '/media/documents/{id}',
        '/media/documents/1',
        headers: {'content-type': 'text/plain'},
        body: 'x',
        status: 415,
      );
    });
  });

  group('headers', () {
    test('conditional GET, HEAD, and If-Match', () async {
      await check(
        'GET',
        '/headers/cache/{id}',
        '/headers/cache/2',
        status: 200,
      );
      await check(
        'GET',
        '/headers/cache/{id}',
        '/headers/cache/2',
        headers: {'if-none-match': '"2-1"'},
        status: 304,
      );
      await check(
        'GET',
        '/headers/cache/{id}',
        '/headers/cache/9',
        status: 404,
      );
      await check(
        'HEAD',
        '/headers/cache/{id}',
        '/headers/cache/2',
        status: 200,
      );
      const item = '{"name":"New","price":5}';
      await check(
        'PUT',
        '/headers/cache/{id}',
        '/headers/cache/2',
        body: item,
        status: 428,
      );
      await check(
        'PUT',
        '/headers/cache/{id}',
        '/headers/cache/2',
        headers: {'if-match': '"2-9"'},
        body: item,
        status: 412,
      );
      await check(
        'PUT',
        '/headers/cache/{id}',
        '/headers/cache/2',
        headers: {'if-match': '*'},
        body: item,
        status: 200,
      );
    });

    test('idempotency keys', () async {
      const key = '8b8e3c8e-6c6f-4e1b-9d3e-0d7c1d2b9a10';
      const body = '{"name":"Lamp","price":2500}';
      final first = await check(
        'POST',
        '/headers/idempotent',
        '/headers/idempotent',
        headers: {'idempotency-key': key, 'x-request-id': 'r1'},
        body: body,
        status: 201,
      );
      expect(first.headers['idempotent-replayed'], 'false');
      final replay = await check(
        'POST',
        '/headers/idempotent',
        '/headers/idempotent',
        headers: {'idempotency-key': key},
        body: body,
        status: 201,
      );
      expect(replay.headers['idempotent-replayed'], 'true');
      await check(
        'POST',
        '/headers/idempotent',
        '/headers/idempotent',
        headers: {'idempotency-key': key},
        body: '{"name":"x"}',
        status: 409,
      );
      await check(
        'POST',
        '/headers/idempotent',
        '/headers/idempotent',
        headers: {'idempotency-key': 'nope'},
        body: '{}',
        status: 400,
      );
    });

    test('rate limit ends in 429 with Retry-After', () async {
      for (var i = 0; i < 5; i++) {
        await check(
          'GET',
          '/headers/rate-limited',
          '/headers/rate-limited',
          status: 200,
        );
      }
      final limited = await check(
        'GET',
        '/headers/rate-limited',
        '/headers/rate-limited',
        status: 429,
      );
      expect(int.parse(limited.headers['retry-after']!), greaterThan(0));
    });

    test('pages, locale, legacy, and typed headers', () async {
      await check(
        'GET',
        '/headers/pages',
        '/headers/pages?page=2&size=5',
        status: 200,
      );
      await check(
        'GET',
        '/headers/pages',
        '/headers/pages?size=0',
        status: 400,
      );
      await check(
        'GET',
        '/headers/locale',
        '/headers/locale',
        headers: {'accept-language': 'de'},
        status: 200,
      );
      await check('GET', '/headers/legacy', '/headers/legacy', status: 200);
      await check(
        'GET',
        '/headers/echo',
        '/headers/echo',
        headers: {
          'x-trace-id': '8b8e3c8e-6c6f-4e1b-9d3e-0d7c1d2b9a10',
          'x-feature-flags': 'a,b',
          'x-retry-count': '2',
          'x-client-time': '2026-10-24T09:00:00Z',
          'x-debug': 'true',
          'x-weights': '0.5,1',
        },
        status: 200,
      );
      await check(
        'GET',
        '/headers/echo',
        '/headers/echo',
        headers: {'x-retry-count': '99'},
        status: 400,
      );
    });
  });

  group('parameters', () {
    test('search and its styles', () async {
      await check(
        'GET',
        '/parameters/search',
        '/parameters/search?q=lamp&tags=a&tags=b&ids=1,2&sort=name|-price'
            '&fields=id%20name&filter%5Bcolor%5D=red&colors=red&page=2',
        status: 200,
      );
      await check(
        'GET',
        '/parameters/search',
        '/parameters/search?ids=x',
        status: 400,
      );
    });

    test('path styles', () async {
      await check(
        'GET',
        '/parameters/simple/{ids}',
        '/parameters/simple/1,2',
        status: 200,
      );
      await check(
        'GET',
        '/parameters/label/{ids}',
        '/parameters/label/.1.2',
        status: 200,
      );
      await check(
        'GET',
        '/parameters/matrix/{ids}',
        '/parameters/matrix/;ids=1,2',
        status: 200,
      );
      await check(
        'GET',
        '/parameters/pair/{kind}/{id}',
        '/parameters/pair/team/3',
        status: 200,
      );
      await check(
        'GET',
        '/parameters/pair/{kind}/{id}',
        '/parameters/pair/x/3',
        status: 404,
      );
    });

    test('cookies and formats', () async {
      await check(
        'GET',
        '/parameters/cookies',
        '/parameters/cookies',
        headers: {'cookie': 'session=abc; visits=2'},
        status: 200,
      );
      await check(
        'GET',
        '/parameters/cookies',
        '/parameters/cookies',
        status: 400,
      );
      await check(
        'GET',
        '/parameters/formats',
        '/parameters/formats?email=a@b.co&zip=94105',
        status: 200,
      );
      await check(
        'GET',
        '/parameters/formats',
        '/parameters/formats?zip=x',
        status: 400,
      );
    });
  });

  group('security', () {
    final cases = <(String, String, Map<String, String>)>[
      ('public', '/security/public', {}),
      ('api-key header', '/security/api-key', {'x-api-key': 'demo-key'}),
      (
        'api-key cookie',
        '/security/api-key',
        {'cookie': 'api_session=demo-key'},
      ),
      (
        'basic',
        '/security/basic',
        {'authorization': 'Basic ${base64Encode(utf8.encode('demo:demo'))}'},
      ),
      ('bearer', '/security/bearer', {'authorization': 'Bearer demo-token'}),
      (
        'oauth2',
        '/security/oauth2/items',
        {'authorization': 'Bearer demo-oauth'},
      ),
      ('openid', '/security/openid', {'authorization': 'Bearer demo-oauth'}),
      (
        'combined',
        '/security/combined',
        {'authorization': 'Bearer demo-token', 'x-api-key': 'demo-key'},
      ),
      ('either', '/security/either', {'authorization': 'Bearer demo-token'}),
    ];
    for (final (name, path, headers) in cases) {
      test('$name accepts its credentials', () async {
        await check('GET', path, path, headers: headers, status: 200);
      });
    }
    for (final path in [
      '/security/api-key',
      '/security/basic',
      '/security/bearer',
      '/security/oauth2/items',
      '/security/openid',
      '/security/combined',
      '/security/either',
    ]) {
      test('$path rejects a caller with no credentials', () async {
        final reply = await check('GET', path, path, status: 401);
        expect(reply.headers, contains('www-authenticate'));
      });
    }
    test('oauth2 write and delete', () async {
      const auth = {'authorization': 'Bearer demo-oauth'};
      await check(
        'POST',
        '/security/oauth2/items',
        '/security/oauth2/items',
        headers: auth,
        status: 200,
      );
      await check(
        'DELETE',
        '/security/oauth2/items/{id}',
        '/security/oauth2/items/4',
        headers: auth,
        status: 200,
      );
    });
  });

  group('schemas', () {
    test('every schema route', () async {
      for (final path in [
        '/schemas/shapes',
        '/schemas/org',
        '/schemas/inventory',
        '/schemas/everything',
        '/schemas/tree?depth=2',
        '/schemas/contact?kind=both',
        '/schemas/contact?kind=email',
        '/schemas/contact?kind=phone',
      ]) {
        await check('GET', path.split('?').first, path, status: 200);
      }
      await check(
        'GET',
        '/schemas/contact',
        '/schemas/contact?kind=x',
        status: 400,
      );
      await check('GET', '/schemas/tree', '/schemas/tree?depth=9', status: 400);
    });

    test('payments union', () async {
      await check(
        'POST',
        '/schemas/payments',
        '/schemas/payments',
        body:
            '{"method":"card","number":"4242424242424242",'
            '"expMonth":12,"expYear":2030}',
        status: 201,
      );
      await check(
        'POST',
        '/schemas/payments',
        '/schemas/payments',
        body: '{"method":"bank","iban":"DE89370400440532013000"}',
        status: 201,
      );
      await check(
        'POST',
        '/schemas/payments',
        '/schemas/payments',
        body: '{"method":"card","number":"1"}',
        status: 422,
      );
      await check(
        'POST',
        '/schemas/payments',
        '/schemas/payments',
        body: '{"method":"cash"}',
        status: 400,
      );
    });
  });

  group('responses', () {
    for (final code in [
      200,
      201,
      204,
      301,
      302,
      304,
      307,
      308,
      404,
      418,
      429,
      503,
    ]) {
      test('status $code is declared exactly', () async {
        await check(
          'GET',
          '/responses/status/{code}',
          '/responses/status/$code',
          status: code,
        );
      });
    }
    for (final code in [299, 399, 499, 599]) {
      test('status $code falls under a range', () async {
        await check(
          'GET',
          '/responses/status/{code}',
          '/responses/status/$code',
          status: code,
        );
      });
    }
    test('status outside the range is a 400', () async {
      await check(
        'GET',
        '/responses/status/{code}',
        '/responses/status/199',
        status: 400,
      );
    });

    test('job lifecycle', () async {
      final started = await check(
        'POST',
        '/responses/jobs',
        '/responses/jobs',
        status: 202,
      );
      final location = started.headers['location']!;
      final specPath = '/responses/jobs/{id}';
      for (var i = 0; i < 3; i++) {
        await check('GET', specPath, location, status: 200);
      }
      await check('DELETE', specPath, location, status: 409);
      final second = await check(
        'POST',
        '/responses/jobs',
        '/responses/jobs',
        status: 202,
      );
      await check('DELETE', specPath, second.headers['location']!, status: 204);
      await check('GET', specPath, '/responses/jobs/999', status: 404);
    });
  });

  test('every operation has a summary, a tag, and a unique id', () {
    final ids = <String>{};
    final paths = spec['paths']! as Map<String, Object?>;
    for (final MapEntry(key: path, value: item) in paths.entries) {
      for (final MapEntry(key: method, value: operation)
          in (item! as Map<String, Object?>).entries) {
        final details = operation! as Map<String, Object?>;
        final where = '${method.toUpperCase()} $path';
        expect(details['summary'], isNotEmpty, reason: '$where summary');
        expect(details['tags'], isNotEmpty, reason: '$where tags');
        expect(
          ids.add(details['operationId']! as String),
          isTrue,
          reason: '$where has a duplicate operationId',
        );
      }
    }
    expect(ids.length, greaterThanOrEqualTo(50));
  });
}

class _Reply {
  _Reply({required this.status, required this.headers, required this.bytes});

  final int status;
  final Map<String, String> headers;
  final List<int> bytes;
}

Iterable<String> _headerNames(HttpClientResponse response) {
  final names = <String>[];
  response.headers.forEach((name, _) => names.add(name));
  return names;
}

Map<String, Object?> _operation(
  Map<String, Object?> spec,
  String path,
  String method,
) {
  final item = (spec['paths']! as Map<String, Object?>)[path];
  expect(item, isNotNull, reason: 'the spec has no path $path');
  final operation = (item! as Map<String, Object?>)[method.toLowerCase()];
  expect(operation, isNotNull, reason: 'the spec has no $method on $path');
  return operation! as Map<String, Object?>;
}

/// The response the spec uses for [status]: exact, then range, then default.
Map<String, Object?>? _declaredResponse(
  Map<String, Object?> operation,
  int status,
) {
  final responses = operation['responses']! as Map<String, Object?>;
  final found =
      responses['$status'] ??
      responses['${status ~/ 100}XX'] ??
      responses['default'];
  return found as Map<String, Object?>?;
}

bool _isJson(String mediaType) =>
    mediaType == 'application/json' || mediaType.endsWith('+json');

/// Validates [value] against [schema], resolving `$ref`s into the spec.
///
/// Only `components.schemas` is handed to the validator, as `$defs`, because
/// the rest of `components` (security schemes) is not JSON Schema.
void _validate(
  Map<String, Object?> spec,
  Map<String, Object?> schema,
  Object? value,
  String where,
) {
  const prefix = '#/components/schemas/';
  final components = spec['components']! as Map<String, Object?>;
  final text = jsonEncode({
    ...schema,
    r'$defs': components['schemas'],
  }).replaceAll(prefix, r'#/$defs/');
  final validator = JsonSchema.create(
    jsonDecode(text),
    schemaVersion: SchemaVersion.draft2020_12,
  );
  final result = validator.validate(value);
  expect(
    result.isValid,
    isTrue,
    reason: '$where does not match its schema: ${result.errors.join('; ')}',
  );
}
