/// Routes that show request and response headers.
library;

import 'dart:convert';
import 'dart:io' show HttpDate;

import 'package:axle_shelf/axle_shelf.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../http.dart';
import '../models/common.dart';
import '../models/headers.dart';
import 'shared.dart';

const _tags = ['Headers'];

/// Registers the header routes.
void headerRoutes(Router router) {
  router
    ..get('/headers/cache/<id>', getCached)
    ..head('/headers/cache/<id>', headCached)
    ..put('/headers/cache/<id>', putCached)
    ..post('/headers/idempotent', createIdempotent)
    ..get('/headers/rate-limited', rateLimited)
    ..get('/headers/pages', pages)
    ..get('/headers/locale', locale)
    ..get('/headers/legacy', legacy)
    ..get('/headers/echo', echoHeaders);
}

// ---------------------------------------------------------------------------
// Conditional requests.

final _lastModified = DateTime.utc(2026, 1, 1);
const _lastModifiedText = 'Thu, 01 Jan 2026 00:00:00 GMT';

final _cached = <int, ({Item item, int revision})>{
  for (var i = 1; i <= 3; i++)
    i: (item: Item(id: i, name: 'Cached $i', price: i * 100), revision: 1),
};

String _etag(int id, int revision) => '"$id-$revision"';

const _etagHeader = ApiResponseHeader(
  'ETag',
  type: String,
  description: 'Identifies this version of the item.',
  example: '"1-1"',
);

const _lastModifiedHeader = ApiResponseHeader(
  'Last-Modified',
  type: String,
  description: 'When the item last changed, as an HTTP date.',
  example: _lastModifiedText,
);

const _cacheControlHeader = ApiResponseHeader(
  'Cache-Control',
  type: String,
  description: 'Caches may store this response for a minute.',
  example: 'private, max-age=60, must-revalidate',
);

const _notFound = ApiResponse(
  status: 404,
  type: Problem,
  description: 'No such item.',
  contentTypes: [problemJson],
);

/// A conditional GET.
@ApiRoute(
  method: ApiMethod.get,
  path: '/headers/cache/<id>',
  summary: 'Conditional GET with ETag and Last-Modified',
  description:
      'Repeat the request with `If-None-Match` set to the `ETag`, or with '
      '`If-Modified-Since`, and the server answers `304` without a body.',
  tags: _tags,
  pathParams: [ApiPathParam('id', type: int, minimum: 1, maximum: 3)],
  headerParams: [
    ApiHeaderParam(
      'If-None-Match',
      type: String,
      description: 'An `ETag` from an earlier response.',
      example: '"1-1"',
    ),
    ApiHeaderParam(
      'If-Modified-Since',
      type: String,
      description: 'An HTTP date from an earlier `Last-Modified`.',
      example: _lastModifiedText,
    ),
  ],
  responses: [
    ApiResponse(
      status: 200,
      type: Item,
      description: 'The item.',
      headers: [_etagHeader, _lastModifiedHeader, _cacheControlHeader],
    ),
    ApiResponse(
      status: 304,
      description: 'The cached copy is still current.',
      headers: [_etagHeader, _cacheControlHeader],
    ),
    _notFound,
  ],
)
Future<Response> getCached(Request request, String id) async {
  final entry = _cached[int.tryParse(id)];
  if (entry == null) return problem(404, 'Not Found');
  final etag = _etag(entry.item.id, entry.revision);
  final headers = {
    'etag': etag,
    'last-modified': _lastModifiedText,
    'cache-control': 'private, max-age=60, must-revalidate',
  };

  final noneMatch = request.headers['if-none-match'];
  if (noneMatch != null) {
    final matches = noneMatch.split(',').map((tag) => tag.trim());
    if (matches.contains(etag) || noneMatch.trim() == '*') {
      return Response(304, headers: headers);
    }
  } else {
    final since = request.headers['if-modified-since'];
    if (since != null) {
      try {
        if (!_lastModified.isAfter(HttpDate.parse(since))) {
          return Response(304, headers: headers);
        }
      } on Object {
        // An unparsable date is ignored, as RFC 9110 says.
      }
    }
  }
  return json(entry.item.toJson(), headers: headers);
}

/// HEAD for the same resource: headers only.
@ApiRoute(
  method: ApiMethod.head,
  path: '/headers/cache/<id>',
  summary: 'Read the validators without the body',
  tags: _tags,
  pathParams: [ApiPathParam('id', type: int, minimum: 1, maximum: 3)],
  responses: [
    ApiResponse(
      status: 200,
      description: 'The headers a GET would send.',
      headers: [_etagHeader, _lastModifiedHeader],
    ),
    ApiResponse(status: 404, description: 'No such item.'),
  ],
)
Future<Response> headCached(Request request, String id) async {
  final entry = _cached[int.tryParse(id)];
  if (entry == null) return Response.notFound(null);
  return Response.ok(
    null,
    headers: {
      'etag': _etag(entry.item.id, entry.revision),
      'last-modified': _lastModifiedText,
    },
  );
}

/// An update guarded by `If-Match`.
@ApiRoute(
  method: ApiMethod.put,
  path: '/headers/cache/<id>',
  summary: 'Update only if nobody else changed it',
  description:
      '`If-Match` is required. Send the `ETag` you last read: a stale value '
      'gives `412`, and no value gives `428`.',
  tags: _tags,
  pathParams: [ApiPathParam('id', type: int, minimum: 1, maximum: 3)],
  headerParams: [
    ApiHeaderParam(
      'If-Match',
      type: String,
      required: true,
      description: 'The `ETag` of the version you are replacing.',
      example: '"1-1"',
    ),
  ],
  body: ApiBody(
    Item,
    examples: {
      'rename': ApiExample({'id': 1, 'name': 'Renamed', 'price': 150}),
    },
  ),
  responses: [
    ApiResponse(
      status: 200,
      type: Item,
      description: 'The item after the update.',
      headers: [_etagHeader],
    ),
    badRequest,
    _notFound,
    ApiResponse(
      status: 412,
      type: Problem,
      description: '`If-Match` does not match the current `ETag`.',
      contentTypes: [problemJson],
      headers: [_etagHeader],
    ),
    ApiResponse(
      status: 428,
      type: Problem,
      description: 'The request must be conditional.',
      contentTypes: [problemJson],
    ),
  ],
)
Future<Response> putCached(Request request, String id) async {
  final key = int.tryParse(id);
  final entry = _cached[key];
  if (key == null || entry == null) return problem(404, 'Not Found');
  final ifMatch = request.headers['if-match'];
  if (ifMatch == null) {
    return problem(428, 'Precondition Required', detail: 'Send If-Match.');
  }
  final current = _etag(key, entry.revision);
  if (ifMatch.trim() != current && ifMatch.trim() != '*') {
    return problem(412, 'Precondition Failed', headers: {'etag': current});
  }
  final Map<String, Object?> body;
  try {
    body = (await _readJson(request)).cast<String, Object?>();
  } on Object {
    return problem(400, 'Bad Request', detail: 'Send a JSON item.');
  }
  final name = body['name'];
  final price = body['price'];
  if (name is! String || price is! int) {
    return problem(
      400,
      'Bad Request',
      detail: '`name` and `price` are needed.',
    );
  }
  final updated = (
    item: Item(id: key, name: name, price: price),
    revision: entry.revision + 1,
  );
  _cached[key] = updated;
  return json(
    updated.item.toJson(),
    headers: {'etag': _etag(key, updated.revision)},
  );
}

Future<Map<Object?, Object?>> _readJson(Request request) async {
  final decoded = await request.readAsString();
  return Map<Object?, Object?>.of(
    (const JsonDecoder().convert(decoded) as Map).cast<Object?, Object?>(),
  );
}

// ---------------------------------------------------------------------------
// Idempotency keys.

final _uuid = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
  caseSensitive: false,
);

final _idempotent = <String, ({String body, Item item})>{};

/// A create that is safe to retry.
@ApiRoute(
  method: ApiMethod.post,
  path: '/headers/idempotent',
  summary: 'Create once, however many times you retry',
  description:
      'Send the same `Idempotency-Key` with the same body and you get the '
      'original response back with `Idempotent-Replayed: true`. The same key '
      'with a different body is a `409`.',
  tags: _tags,
  headerParams: [
    ApiHeaderParam(
      'Idempotency-Key',
      type: String,
      required: true,
      format: 'uuid',
      description: 'A unique key per logical request.',
      example: '8b8e3c8e-6c6f-4e1b-9d3e-0d7c1d2b9a10',
    ),
    ApiHeaderParam(
      'X-Request-Id',
      type: String,
      description: 'Echoed back so you can match logs.',
      example: 'req-42',
    ),
  ],
  body: ApiBody(
    Item,
    examples: {
      'lamp': ApiExample({'id': 1, 'name': 'Lamp', 'price': 2500}),
    },
  ),
  responses: [
    ApiResponse(
      status: 201,
      type: Item,
      description: 'Created, or replayed from an earlier request.',
      headers: [
        ApiResponseHeader(
          'Location',
          type: String,
          description: 'Where the item lives.',
          example: '/headers/cache/1',
        ),
        ApiResponseHeader(
          'Idempotent-Replayed',
          type: bool,
          description: 'True when this is a replay.',
          example: false,
        ),
        ApiResponseHeader('X-Request-Id', type: String, example: 'req-42'),
      ],
    ),
    badRequest,
    ApiResponse(
      status: 409,
      type: Problem,
      description: 'The key was used with a different body.',
      contentTypes: [problemJson],
    ),
  ],
)
Future<Response> createIdempotent(Request request) async {
  final key = request.headers['idempotency-key'];
  if (key == null || !_uuid.hasMatch(key)) {
    return problem(
      400,
      'Bad Request',
      detail: '`Idempotency-Key` must be a UUID.',
    );
  }
  final raw = await request.readAsString();
  final Map<String, Object?> body;
  try {
    body = (const JsonDecoder().convert(raw) as Map).cast<String, Object?>();
  } on Object {
    return problem(400, 'Bad Request', detail: 'Send a JSON item.');
  }
  final requestId = request.headers['x-request-id'];
  Map<String, String> headers(bool replayed, int id) => {
    'location': '/headers/cache/$id',
    'idempotent-replayed': '$replayed',
    'x-request-id': ?requestId,
  };

  final previous = _idempotent[key];
  if (previous != null) {
    if (previous.body != raw) {
      return problem(409, 'Conflict', detail: 'That key was used before.');
    }
    return json(
      previous.item.toJson(),
      status: 201,
      headers: headers(true, previous.item.id),
    );
  }
  final item = Item(
    id: 100 + _idempotent.length,
    name: '${body['name'] ?? 'Unnamed'}',
    price: (body['price'] as int?) ?? 0,
  );
  _idempotent[key] = (body: raw, item: item);
  return json(item.toJson(), status: 201, headers: headers(false, item.id));
}

// ---------------------------------------------------------------------------
// Rate limits.

const _rateLimit = 5;
var _windowStart = DateTime.now();
var _windowCount = 0;

/// Allows five calls per minute.
@ApiRoute(
  method: ApiMethod.get,
  path: '/headers/rate-limited',
  summary: 'A route with a rate limit',
  description:
      'Five calls per minute. Every response says how many are left; the '
      'sixth gets `429` and `Retry-After`.',
  tags: _tags,
  responses: [
    ApiResponse(
      status: 200,
      type: Greeting,
      description: 'Within the limit.',
      headers: [
        ApiResponseHeader(
          'X-RateLimit-Limit',
          type: int,
          description: 'Calls allowed per window.',
          example: 5,
        ),
        ApiResponseHeader(
          'X-RateLimit-Remaining',
          type: int,
          description: 'Calls left in this window.',
          example: 4,
        ),
        ApiResponseHeader(
          'X-RateLimit-Reset',
          type: int,
          description: 'When the window ends, in Unix seconds.',
          example: 1767225600,
        ),
      ],
    ),
    ApiResponse(
      status: 429,
      type: Problem,
      description: 'Too many calls.',
      contentTypes: [problemJson],
      headers: [
        ApiResponseHeader(
          'Retry-After',
          type: int,
          required: true,
          description: 'Seconds to wait before trying again.',
          example: 30,
        ),
      ],
    ),
  ],
)
Future<Response> rateLimited(Request request) async {
  final now = DateTime.now();
  if (now.difference(_windowStart) >= const Duration(minutes: 1)) {
    _windowStart = now;
    _windowCount = 0;
  }
  final reset = _windowStart.add(const Duration(minutes: 1));
  final resetSeconds = reset.millisecondsSinceEpoch ~/ 1000;
  if (_windowCount >= _rateLimit) {
    final wait = reset.difference(now).inSeconds + 1;
    return problem(
      429,
      'Too Many Requests',
      headers: {
        'retry-after': '$wait',
        'x-ratelimit-limit': '$_rateLimit',
        'x-ratelimit-remaining': '0',
        'x-ratelimit-reset': '$resetSeconds',
      },
    );
  }
  _windowCount++;
  return json(
    const Greeting(message: 'Within the limit', language: 'en').toJson(),
    headers: {
      'x-ratelimit-limit': '$_rateLimit',
      'x-ratelimit-remaining': '${_rateLimit - _windowCount}',
      'x-ratelimit-reset': '$resetSeconds',
    },
  );
}

// ---------------------------------------------------------------------------
// Pagination with Link headers.

final _catalog = [
  for (var i = 1; i <= 23; i++)
    Item(id: i, name: 'Item $i', price: i * 50, tags: [if (i.isEven) 'even']),
];

/// A paged list that links to its neighbours in the `Link` header.
@ApiRoute(
  method: ApiMethod.get,
  path: '/headers/pages',
  summary: 'Pagination with Link headers',
  description:
      'The body is a generic `Page<Item>`. The `Link` header (RFC 8288) points '
      'to the first, previous, next, and last pages.',
  tags: _tags,
  queryParams: [
    ApiQueryParam('page', type: int, defaultValue: 1, minimum: 1),
    ApiQueryParam(
      'size',
      type: int,
      defaultValue: 10,
      minimum: 1,
      maximum: 100,
    ),
  ],
  responses: [
    ApiResponse(
      status: 200,
      type: Page<Item>,
      headers: [
        ApiResponseHeader(
          'Link',
          type: String,
          description: 'Neighbouring pages.',
          example:
              '</headers/pages?page=2&size=10>; rel="next", '
              '</headers/pages?page=3&size=10>; rel="last"',
        ),
        ApiResponseHeader(
          'X-Total-Count',
          type: int,
          description: 'Items across all pages.',
          example: 23,
        ),
      ],
    ),
    badRequest,
  ],
)
Future<Response> pages(Request request) async {
  final query = request.url.queryParameters;
  final page = int.tryParse(query['page'] ?? '1');
  final size = int.tryParse(query['size'] ?? '10');
  if (page == null || size == null || page < 1 || size < 1 || size > 100) {
    return problem(400, 'Bad Request', detail: 'Check `page` and `size`.');
  }
  final last = (_catalog.length / size).ceil().clamp(1, 1 << 20);
  String link(int target, String rel) =>
      '</headers/pages?page=$target&size=$size>; rel="$rel"';
  final links = [
    link(1, 'first'),
    if (page > 1) link(page - 1, 'prev'),
    if (page < last) link(page + 1, 'next'),
    link(last, 'last'),
  ];
  final start = (page - 1) * size;
  final slice = _catalog.skip(start).take(size).toList();
  return json(
    Page<Item>(
      items: slice,
      page: page,
      size: size,
      total: _catalog.length,
    ).toJson(),
    headers: {'link': links.join(', '), 'x-total-count': '${_catalog.length}'},
  );
}

// ---------------------------------------------------------------------------
// Language negotiation.

const _greetings = {
  'en': 'Hello!',
  'fr': 'Bonjour !',
  'de': 'Hallo!',
  'ja': 'こんにちは！',
};

/// A greeting in the language you accept.
@ApiRoute(
  method: ApiMethod.get,
  path: '/headers/locale',
  summary: 'Pick a language with Accept-Language',
  tags: _tags,
  headerParams: [
    ApiHeaderParam(
      'Accept-Language',
      type: String,
      description: 'Languages in order of preference, with optional weights.',
      example: 'fr-CH, fr;q=0.9, en;q=0.5',
    ),
  ],
  responses: [
    ApiResponse(
      status: 200,
      type: Greeting,
      headers: [
        ApiResponseHeader('Content-Language', type: String, example: 'fr'),
        ApiResponseHeader('Vary', type: String, example: 'Accept-Language'),
      ],
    ),
  ],
)
Future<Response> locale(Request request) async {
  final header = request.headers['accept-language'] ?? 'en';
  final wanted = <({String language, double quality})>[];
  for (final part in header.split(',')) {
    final pieces = part.trim().split(';');
    final language = pieces.first.trim().split('-').first.toLowerCase();
    var quality = 1.0;
    for (final parameter in pieces.skip(1)) {
      if (parameter.trim().startsWith('q=')) {
        quality = double.tryParse(parameter.trim().substring(2)) ?? 1.0;
      }
    }
    wanted.add((language: language, quality: quality));
  }
  wanted.sort((a, b) => b.quality.compareTo(a.quality));
  final chosen = wanted
      .map((entry) => entry.language)
      .firstWhere(_greetings.containsKey, orElse: () => 'en');
  return json(
    Greeting(message: _greetings[chosen]!, language: chosen).toJson(),
    headers: {'content-language': chosen, 'vary': 'Accept-Language'},
  );
}

// ---------------------------------------------------------------------------
// Deprecation.

/// A route that is on its way out.
@ApiRoute(
  method: ApiMethod.get,
  path: '/headers/legacy',
  summary: 'A deprecated route',
  description: 'Use `/headers/pages` instead. The response says when it goes.',
  tags: _tags,
  deprecated: true,
  responses: [
    ApiResponse(
      status: 200,
      type: Greeting,
      description: 'Still works, for now.',
      headers: [
        ApiResponseHeader(
          'Deprecation',
          type: String,
          description: 'When the route was deprecated (RFC 9745).',
          example: '@1767225600',
        ),
        ApiResponseHeader(
          'Sunset',
          type: String,
          description: 'When the route stops working (RFC 8594).',
          example: 'Wed, 01 Jan 2031 00:00:00 GMT',
        ),
        ApiResponseHeader(
          'Link',
          type: String,
          description: 'Where to go instead.',
          example: '</headers/pages>; rel="successor-version"',
        ),
      ],
    ),
  ],
)
Future<Response> legacy(Request request) async {
  return json(
    const Greeting(message: 'Use /headers/pages', language: 'en').toJson(),
    headers: {
      'deprecation': '@1767225600',
      'sunset': 'Wed, 01 Jan 2031 00:00:00 GMT',
      'link': '</headers/pages>; rel="successor-version"',
    },
  );
}

// ---------------------------------------------------------------------------
// Typed request headers.

/// Reads typed request headers.
@ApiRoute(
  method: ApiMethod.get,
  path: '/headers/echo',
  summary: 'Request headers of every type',
  description:
      'Headers carry strings, so axle describes the type each one parses to: a '
      'UUID, a comma-separated list, a bounded integer, a date-time, a boolean, '
      'and a list of numbers.',
  tags: _tags,
  headerParams: [
    ApiHeaderParam(
      'X-Trace-Id',
      type: String,
      format: 'uuid',
      example: '8b8e3c8e-6c6f-4e1b-9d3e-0d7c1d2b9a10',
    ),
    ApiHeaderParam(
      'X-Feature-Flags',
      type: List<String>,
      description: 'Comma-separated, because headers use the `simple` style.',
      example: ['beta', 'dark-mode'],
    ),
    ApiHeaderParam('X-Retry-Count', type: int, minimum: 0, maximum: 10),
    ApiHeaderParam(
      'X-Client-Time',
      type: DateTime,
      example: '2026-10-24T09:00:00Z',
    ),
    ApiHeaderParam('X-Debug', type: bool, example: true),
    ApiHeaderParam(
      'X-Weights',
      type: List<double>,
      minimum: 0,
      maximum: 1,
      description: 'Comma-separated numbers; the bounds apply to each one.',
      example: [0.25, 0.75],
    ),
  ],
  responses: [
    ApiResponse(status: 200, type: HeaderEcho),
    badRequest,
  ],
)
Future<Response> echoHeaders(Request request) async {
  List<String> list(String? value) => value == null || value.trim().isEmpty
      ? const []
      : value.split(',').map((part) => part.trim()).toList();

  final traceId = request.headers['x-trace-id'];
  if (traceId != null && !_uuid.hasMatch(traceId)) {
    return problem(400, 'Bad Request', detail: '`X-Trace-Id` must be a UUID.');
  }
  final retry = int.tryParse(request.headers['x-retry-count'] ?? '');
  if (retry != null && (retry < 0 || retry > 10)) {
    return problem(400, 'Bad Request', detail: '`X-Retry-Count` is 0 to 10.');
  }
  final weights = [
    for (final text in list(request.headers['x-weights']))
      if (double.tryParse(text) case final double weight) weight,
  ];
  return json(
    HeaderEcho(
      traceId: traceId,
      featureFlags: list(request.headers['x-feature-flags']),
      retryCount: retry,
      clientTime: DateTime.tryParse(request.headers['x-client-time'] ?? ''),
      debug: request.headers['x-debug'] == 'true',
      weights: weights,
    ).toJson(),
  );
}
