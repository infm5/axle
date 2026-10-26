/// Routes that show every way a parameter can travel.
library;

import 'package:axle_shelf/axle_shelf.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../http.dart';
import '../models/common.dart';
import '../models/parameters.dart';
import 'shared.dart';

const _tags = ['Parameters'];

/// Registers the parameter routes.
void parameterRoutes(Router router) {
  router
    ..get('/parameters/search', search)
    ..get('/parameters/simple/<ids>', simplePath)
    ..get('/parameters/label/<ids>', labelPath)
    ..get('/parameters/matrix/<ids>', matrixPath)
    ..get('/parameters/pair/<kind>/<id>', pairPath)
    ..get('/parameters/cookies', cookieParameters)
    ..get('/parameters/formats', formats);
}

Response _parsed(String route, Map<String, Object?> values) =>
    json(ParsedParameters(route: route, values: values).toJson());

Response _bad(String detail) => problem(400, 'Bad Request', detail: detail);

// ---------------------------------------------------------------------------
// Query parameters: arrays and objects.

/// A search that takes every query style.
@ApiRoute(
  method: ApiMethod.get,
  path: '/parameters/search',
  summary: 'Every way to send arrays and objects in a query string',
  description:
      '| Parameter | Style | Looks like |\n'
      '| --- | --- | --- |\n'
      '| `tags` | `form`, exploded | `tags=a&tags=b` |\n'
      '| `ids` | `form`, not exploded | `ids=1,2,3` |\n'
      '| `sort` | `pipeDelimited` | `sort=name|price` |\n'
      '| `fields` | `spaceDelimited` | `fields=a%20b` |\n'
      '| `filter` | `deepObject` | `filter[color]=red&filter[minSize]=2` |\n\n'
      'The response shows what the server parsed.',
  tags: _tags,
  queryParams: [
    ApiQueryParam(
      'q',
      type: String,
      minLength: 1,
      maxLength: 80,
      description: 'Free text, with two named examples.',
      examples: {
        'word': ApiExample('lamp', summary: 'One word'),
        'phrase': ApiExample('desk lamp', summary: 'A phrase'),
      },
    ),
    ApiQueryParam(
      'tags',
      type: List<String>,
      description: 'Repeat the parameter: `tags=a&tags=b`.',
      example: ['red', 'sale'],
    ),
    ApiQueryParam(
      'ids',
      type: List<int>,
      explode: false,
      minimum: 1,
      description: 'One comma-separated value: `ids=1,2,3`.',
      example: [1, 2, 3],
    ),
    ApiQueryParam(
      'sort',
      type: List<String>,
      style: ApiParameterStyle.pipeDelimited,
      explode: false,
      enumValues: ['name', 'price', '-name', '-price'],
      description: 'Sort keys joined with `|`. A leading `-` sorts descending.',
      example: ['name', '-price'],
    ),
    ApiQueryParam(
      'fields',
      type: List<String>,
      style: ApiParameterStyle.spaceDelimited,
      explode: false,
      description: 'Field names joined with a space.',
      example: ['id', 'name'],
    ),
    ApiQueryParam(
      'filter',
      type: Filter,
      style: ApiParameterStyle.deepObject,
      description: 'An object spread over `filter[...]` parameters.',
    ),
    ApiQueryParam('status', type: Status, defaultValue: 'active'),
    ApiQueryParam(
      'colors',
      type: List<Color>,
      description: 'Enum values repeat like any other array.',
    ),
    ApiQueryParam('page', type: int, defaultValue: 1, minimum: 1),
    ApiQueryParam(
      'size',
      type: int,
      defaultValue: 20,
      minimum: 1,
      maximum: 100,
    ),
    ApiQueryParam(
      'since',
      type: DateTime,
      description: 'Only items changed since this moment.',
      example: '2026-01-01T00:00:00Z',
    ),
  ],
  responses: [
    ApiResponse(status: 200, type: ParsedParameters),
    badRequest,
    ...catchAllErrors,
  ],
)
Future<Response> search(Request request) async {
  final all = request.url.queryParametersAll;
  final query = request.url.queryParameters;

  final ids = <int>[];
  for (final part in (query['ids'] ?? '').split(',')) {
    if (part.isEmpty) continue;
    final id = int.tryParse(part);
    if (id == null || id < 1) return _bad('`ids` holds positive integers.');
    ids.add(id);
  }
  final sort = (query['sort'] ?? '').split('|').where((s) => s.isNotEmpty);
  const sortKeys = {'name', 'price', '-name', '-price'};
  if (!sort.every(sortKeys.contains)) return _bad('Unknown `sort` key.');

  final filter = <String, String>{
    for (final entry in query.entries)
      if (entry.key.startsWith('filter[') && entry.key.endsWith(']'))
        entry.key.substring(7, entry.key.length - 1): entry.value,
  };
  final color = filter['color'];
  if (color != null && !Color.values.any((c) => c.name == color)) {
    return _bad('`filter[color]` is red, green, or blue.');
  }

  final status = query['status'] ?? 'active';
  if (!Status.values.any((s) => s.name == status)) {
    return _bad('`status` is draft, active, or archived.');
  }
  final size = int.tryParse(query['size'] ?? '20');
  if (size == null || size < 1 || size > 100) {
    return _bad('`size` is 1 to 100.');
  }
  return _parsed('/parameters/search', {
    'q': query['q'],
    'tags': all['tags'] ?? const <String>[],
    'ids': ids,
    'sort': sort.toList(),
    'fields': (query['fields'] ?? '')
        .split(' ')
        .where((s) => s.isNotEmpty)
        .toList(),
    'filter': filter,
    'status': status,
    'colors': all['colors'] ?? const <String>[],
    'page': int.tryParse(query['page'] ?? '1') ?? 1,
    'size': size,
    'since': DateTime.tryParse(query['since'] ?? '')?.toIso8601String(),
  });
}

// ---------------------------------------------------------------------------
// Path parameters: three ways to write a list.

List<int>? _ints(String text) {
  final result = <int>[];
  for (final part in text.split(',')) {
    final value = int.tryParse(part);
    if (value == null) return null;
    result.add(value);
  }
  return result;
}

/// Path array, `simple` style.
@ApiRoute(
  method: ApiMethod.get,
  path: '/parameters/simple/<ids>',
  summary: 'Path array, simple style',
  description: 'Values are comma-separated: `/parameters/simple/1,2,3`.',
  tags: _tags,
  pathParams: [
    ApiPathParam('ids', type: List<int>, minimum: 1, example: [1, 2, 3]),
  ],
  responses: [
    ApiResponse(status: 200, type: ParsedParameters),
    badRequest,
  ],
)
Future<Response> simplePath(Request request, String ids) async {
  final values = _ints(ids);
  if (values == null) return _bad('`ids` holds integers.');
  return _parsed('simple', {'style': 'simple', 'ids': values});
}

/// Path array, `label` style.
@ApiRoute(
  method: ApiMethod.get,
  path: '/parameters/label/<ids>',
  summary: 'Path array, label style',
  description: 'Values start with a dot: `/parameters/label/.1.2.3`.',
  tags: _tags,
  pathParams: [
    ApiPathParam(
      'ids',
      type: List<int>,
      style: ApiParameterStyle.label,
      example: [1, 2, 3],
    ),
  ],
  responses: [
    ApiResponse(status: 200, type: ParsedParameters),
    badRequest,
  ],
)
Future<Response> labelPath(Request request, String ids) async {
  if (!ids.startsWith('.')) return _bad('Label style starts with a dot.');
  final values = _ints(ids.substring(1).replaceAll('.', ','));
  if (values == null) return _bad('`ids` holds integers.');
  return _parsed('label', {'style': 'label', 'ids': values});
}

/// Path array, `matrix` style.
@ApiRoute(
  method: ApiMethod.get,
  path: '/parameters/matrix/<ids>',
  summary: 'Path array, matrix style',
  description: 'Values carry their name: `/parameters/matrix/;ids=1,2,3`.',
  tags: _tags,
  pathParams: [
    ApiPathParam(
      'ids',
      type: List<int>,
      style: ApiParameterStyle.matrix,
      example: [1, 2, 3],
    ),
  ],
  responses: [
    ApiResponse(status: 200, type: ParsedParameters),
    badRequest,
  ],
)
Future<Response> matrixPath(Request request, String ids) async {
  if (!ids.startsWith(';ids=')) return _bad('Matrix style is `;ids=1,2,3`.');
  final values = _ints(ids.substring(5));
  if (values == null) return _bad('`ids` holds integers.');
  return _parsed('matrix', {'style': 'matrix', 'ids': values});
}

/// Two path parameters.
@ApiRoute(
  method: ApiMethod.get,
  path: '/parameters/pair/<kind>/<id>',
  summary: 'Two path parameters, one an enum',
  tags: _tags,
  pathParams: [
    ApiPathParam('kind', type: Kind, description: 'What the id refers to.'),
    ApiPathParam('id', type: int, minimum: 1, example: 7),
  ],
  responses: [
    ApiResponse(status: 200, type: ParsedParameters),
    badRequest,
    ApiResponse(
      status: 404,
      type: Problem,
      description: 'Unknown kind.',
      contentTypes: [problemJson],
    ),
  ],
)
Future<Response> pairPath(Request request, String kind, String id) async {
  if (!Kind.values.any((k) => k.name == kind)) {
    return problem(404, 'Not Found', detail: 'Unknown kind `$kind`.');
  }
  final number = int.tryParse(id);
  if (number == null || number < 1) return _bad('`id` is a positive integer.');
  return _parsed('pair', {'kind': kind, 'id': number});
}

// ---------------------------------------------------------------------------
// Cookies.

/// Cookie parameters.
@ApiRoute(
  method: ApiMethod.get,
  path: '/parameters/cookies',
  summary: 'Cookie parameters',
  description:
      'Send `Cookie: theme=dark; visits=3; consent=true; session=abc`. Cookies '
      'are strings on the wire; axle documents the type each one parses to.',
  tags: _tags,
  cookieParams: [
    ApiCookieParam(
      'session',
      type: String,
      required: true,
      minLength: 3,
      example: 'abc',
    ),
    ApiCookieParam('theme', type: String, enumValues: ['light', 'dark']),
    ApiCookieParam('visits', type: int, minimum: 0),
    ApiCookieParam('consent', type: bool),
  ],
  responses: [
    ApiResponse(status: 200, type: ParsedParameters),
    badRequest,
  ],
)
Future<Response> cookieParameters(Request request) async {
  final jar = cookies(request);
  final session = jar['session'];
  if (session == null || session.length < 3) {
    return _bad('The `session` cookie is required.');
  }
  return _parsed('cookies', {
    'session': session,
    'theme': jar['theme'] ?? 'light',
    'visits': int.tryParse(jar['visits'] ?? '') ?? 0,
    'consent': jar['consent'] == 'true',
  });
}

// ---------------------------------------------------------------------------
// Formats and patterns.

/// Parameters that use JSON Schema formats.
@ApiRoute(
  method: ApiMethod.get,
  path: '/parameters/formats',
  summary: 'Formats, patterns, and bounds',
  description:
      'Each parameter has a `format` or `pattern`. Swagger UI shows them as '
      'hints; clients can validate before sending.',
  tags: _tags,
  queryParams: [
    ApiQueryParam('email', type: String, format: 'email', example: 'a@b.co'),
    ApiQueryParam(
      'id',
      type: String,
      format: 'uuid',
      example: '8b8e3c8e-6c6f-4e1b-9d3e-0d7c1d2b9a10',
    ),
    ApiQueryParam('website', type: String, format: 'uri'),
    ApiQueryParam('day', type: String, format: 'date', example: '2026-10-24'),
    ApiQueryParam('ipv4', type: String, format: 'ipv4', example: '192.0.2.1'),
    ApiQueryParam('ipv6', type: String, format: 'ipv6', example: '2001:db8::1'),
    ApiQueryParam('host', type: String, format: 'hostname'),
    ApiQueryParam('int32', type: int, format: 'int32', minimum: -2147483648),
    ApiQueryParam('int64', type: int, format: 'int64'),
    ApiQueryParam(
      'float',
      type: double,
      format: 'float',
      minimum: 0,
      maximum: 1,
    ),
    ApiQueryParam(
      'zip',
      type: String,
      pattern: r'^\d{5}(-\d{4})?$',
      example: '94105',
    ),
    ApiQueryParam('rating', type: int, minimum: 1, maximum: 5),
    ApiQueryParam('code', type: String, minLength: 3, maxLength: 3),
  ],
  responses: [
    ApiResponse(status: 200, type: ParsedParameters),
    badRequest,
  ],
)
Future<Response> formats(Request request) async {
  final query = request.url.queryParameters;
  final email = query['email'];
  if (email != null && !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
    return _bad('`email` is not an email address.');
  }
  final zip = query['zip'];
  if (zip != null && !RegExp(r'^\d{5}(-\d{4})?$').hasMatch(zip)) {
    return _bad('`zip` does not match the pattern.');
  }
  final rating = int.tryParse(query['rating'] ?? '');
  if (rating != null && (rating < 1 || rating > 5)) {
    return _bad('`rating` is 1 to 5.');
  }
  return _parsed('formats', {for (final e in query.entries) e.key: e.value});
}
