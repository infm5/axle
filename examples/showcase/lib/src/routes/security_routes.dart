/// One route for every kind of security scheme.
///
/// The schemes themselves are declared once in `axle.yaml`. Each route names
/// the ones it accepts. axle only *describes* security; the checks below are
/// this server's own.
library;

import 'dart:convert';

import 'package:axle_shelf/axle_shelf.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../http.dart';
import '../models/security.dart';
import 'shared.dart';

const _tags = ['Security'];

const _apiKey = 'demo-key';
const _bearer = 'demo-token';
const _oauth = 'demo-oauth';

/// Registers the security routes.
void securityRoutes(Router router) {
  router
    ..get('/security/public', publicRoute)
    ..get('/security/api-key', apiKeyRoute)
    ..get('/security/basic', basicRoute)
    ..get('/security/bearer', bearerRoute)
    ..get('/security/oauth2/items', readItems)
    ..post('/security/oauth2/items', writeItems)
    ..delete('/security/oauth2/items/<id>', deleteItem)
    ..get('/security/openid', openIdRoute)
    ..get('/security/combined', combinedRoute)
    ..get('/security/either', eitherRoute);
}

String? _bearerToken(Request request) {
  final header = request.headers['authorization'];
  if (header == null || !header.toLowerCase().startsWith('bearer ')) {
    return null;
  }
  return header.substring(7).trim();
}

({String user, String password})? _basic(Request request) {
  final header = request.headers['authorization'];
  if (header == null || !header.toLowerCase().startsWith('basic ')) return null;
  try {
    final decoded = utf8.decode(base64Decode(header.substring(6).trim()));
    final index = decoded.indexOf(':');
    if (index < 0) return null;
    return (
      user: decoded.substring(0, index),
      password: decoded.substring(index + 1),
    );
  } on FormatException {
    return null;
  }
}

Response _unauthorized(String challenge) =>
    problem(401, 'Unauthorized', headers: {'www-authenticate': challenge});

Response _who(
  String scheme,
  String subject, [
  List<String> scopes = const [],
]) => json(Whoami(scheme: scheme, subject: subject, scopes: scopes).toJson());

// ---------------------------------------------------------------------------

/// A route that needs nothing.
@ApiRoute(
  method: ApiMethod.get,
  path: '/security/public',
  summary: 'No credentials needed',
  description: '`security: []` makes one route public.',
  tags: _tags,
  security: [],
  responses: [ApiResponse(status: 200, type: Whoami)],
)
Future<Response> publicRoute(Request request) async =>
    _who('none', 'anonymous');

/// An API key in a header, a query parameter, or a cookie.
@ApiRoute(
  method: ApiMethod.get,
  path: '/security/api-key',
  summary: 'An API key, three ways',
  description:
      'Send `demo-key` as the `X-API-Key` header, as `?api_key=`, or as the '
      '`api_session` cookie. Listing three requirements means any one is enough.',
  tags: _tags,
  security: [
    ApiSecurityRequirement(['apiKeyHeader']),
    ApiSecurityRequirement(['apiKeyQuery']),
    ApiSecurityRequirement(['apiKeyCookie']),
  ],
  responses: [
    ApiResponse(status: 200, type: Whoami),
    ...authErrors,
  ],
)
Future<Response> apiKeyRoute(Request request) async {
  if (request.headers['x-api-key'] == _apiKey) {
    return _who('apiKeyHeader', 'key-holder');
  }
  if (request.url.queryParameters['api_key'] == _apiKey) {
    return _who('apiKeyQuery', 'key-holder');
  }
  if (cookies(request)['api_session'] == _apiKey) {
    return _who('apiKeyCookie', 'key-holder');
  }
  return _unauthorized('ApiKey');
}

/// HTTP Basic.
@ApiRoute(
  method: ApiMethod.get,
  path: '/security/basic',
  summary: 'HTTP Basic authentication',
  tags: _tags,
  security: [
    ApiSecurityRequirement(['basicAuth']),
  ],
  responses: [
    ApiResponse(status: 200, type: Whoami),
    ...authErrors,
  ],
)
Future<Response> basicRoute(Request request) async {
  final credentials = _basic(request);
  if (credentials?.user == 'demo' && credentials?.password == 'demo') {
    return _who('basicAuth', 'demo');
  }
  return _unauthorized('Basic realm="showcase"');
}

/// A bearer token.
@ApiRoute(
  method: ApiMethod.get,
  path: '/security/bearer',
  summary: 'A bearer token',
  description: 'Get one from `POST /media/login`, or send `demo-token`.',
  tags: _tags,
  security: [
    ApiSecurityRequirement(['bearerAuth']),
  ],
  responses: [
    ApiResponse(status: 200, type: Whoami),
    ...authErrors,
  ],
)
Future<Response> bearerRoute(Request request) async {
  if (_bearerToken(request) == _bearer) return _who('bearerAuth', 'demo');
  return _unauthorized('Bearer realm="showcase"');
}

/// OAuth2 with a scope per operation.
@ApiRoute(
  method: ApiMethod.get,
  path: '/security/oauth2/items',
  summary: 'OAuth2: read scope',
  description:
      'The scope is part of the requirement, so Swagger UI asks for exactly '
      '`items:read` when you authorize.',
  tags: _tags,
  security: [
    ApiSecurityRequirement(
      ['oauth2'],
      scopes: {
        'oauth2': ['items:read'],
      },
    ),
  ],
  responses: [
    ApiResponse(status: 200, type: Whoami),
    ...authErrors,
  ],
)
Future<Response> readItems(Request request) async {
  if (_bearerToken(request) == _oauth) {
    return _who('oauth2', 'demo', ['items:read']);
  }
  return _unauthorized('Bearer');
}

/// OAuth2 with a write scope.
@ApiRoute(
  method: ApiMethod.post,
  path: '/security/oauth2/items',
  summary: 'OAuth2: write scope',
  tags: _tags,
  security: [
    ApiSecurityRequirement(
      ['oauth2'],
      scopes: {
        'oauth2': ['items:write'],
      },
    ),
  ],
  responses: [
    ApiResponse(status: 200, type: Whoami),
    ...authErrors,
  ],
)
Future<Response> writeItems(Request request) async {
  if (_bearerToken(request) == _oauth) {
    return _who('oauth2', 'demo', ['items:write']);
  }
  return _unauthorized('Bearer');
}

/// OAuth2 with two scopes at once.
@ApiRoute(
  method: ApiMethod.delete,
  path: '/security/oauth2/items/<id>',
  summary: 'OAuth2: several scopes',
  description: 'A requirement can list more than one scope for one scheme.',
  tags: _tags,
  pathParams: [ApiPathParam('id', type: int, minimum: 1)],
  security: [
    ApiSecurityRequirement(
      ['oauth2'],
      scopes: {
        'oauth2': ['items:write', 'admin'],
      },
    ),
  ],
  responses: [
    ApiResponse(status: 200, type: Whoami),
    ...authErrors,
  ],
)
Future<Response> deleteItem(Request request, String id) async {
  if (_bearerToken(request) == _oauth) {
    return _who('oauth2', 'demo', ['items:write', 'admin']);
  }
  return _unauthorized('Bearer');
}

/// OpenID Connect.
@ApiRoute(
  method: ApiMethod.get,
  path: '/security/openid',
  summary: 'OpenID Connect',
  description: 'Swagger UI reads the discovery document to find the endpoints.',
  tags: _tags,
  security: [
    ApiSecurityRequirement(['openId']),
  ],
  responses: [
    ApiResponse(status: 200, type: Whoami),
    ...authErrors,
  ],
)
Future<Response> openIdRoute(Request request) async {
  if (_bearerToken(request) == _oauth) return _who('openId', 'demo');
  return _unauthorized('Bearer');
}

/// Two schemes that must both pass.
@ApiRoute(
  method: ApiMethod.get,
  path: '/security/combined',
  summary: 'Two schemes at once (AND)',
  description:
      'Schemes listed in one requirement must all be satisfied. This route '
      'needs the bearer token and the API key.',
  tags: _tags,
  security: [
    ApiSecurityRequirement(['bearerAuth', 'apiKeyHeader']),
  ],
  responses: [
    ApiResponse(status: 200, type: Whoami),
    ...authErrors,
  ],
)
Future<Response> combinedRoute(Request request) async {
  if (_bearerToken(request) == _bearer &&
      request.headers['x-api-key'] == _apiKey) {
    return _who('bearerAuth+apiKeyHeader', 'demo');
  }
  return _unauthorized('Bearer realm="showcase"');
}

/// Either of two schemes.
@ApiRoute(
  method: ApiMethod.get,
  path: '/security/either',
  summary: 'Bearer token or Basic (OR)',
  tags: _tags,
  security: [
    ApiSecurityRequirement(['bearerAuth']),
    ApiSecurityRequirement(['basicAuth']),
  ],
  responses: [
    ApiResponse(status: 200, type: Whoami),
    ...authErrors,
  ],
)
Future<Response> eitherRoute(Request request) async {
  if (_bearerToken(request) == _bearer) return _who('bearerAuth', 'demo');
  final credentials = _basic(request);
  if (credentials?.user == 'demo' && credentials?.password == 'demo') {
    return _who('basicAuth', 'demo');
  }
  return _unauthorized('Bearer realm="showcase", Basic realm="showcase"');
}
