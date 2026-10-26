/// Routes that show content types, in and out.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:axle_shelf/axle_shelf.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../http.dart';
import '../models/common.dart';
import 'shared.dart';

const _tags = ['Media'];

/// Registers the media routes.
void mediaRoutes(Router router) {
  router
    ..get('/media/greeting', greeting)
    ..get('/media/report', report)
    ..get('/media/vendor', vendorGreeting)
    ..get('/media/stream/ndjson', streamNdjson)
    ..get('/media/stream/events', streamEvents)
    ..get('/media/logo', logo)
    ..get('/media/document.pdf', document)
    ..get('/media/blob', readBlob)
    ..put('/media/blob', writeBlob)
    ..post('/media/upload', upload)
    ..options('/media/upload', uploadOptions)
    ..post('/media/login', login)
    ..patch('/media/documents/<id>', patchDocument);
}

// ---------------------------------------------------------------------------
// Text formats: one schema, five representations.

const _greetingTypes = [
  'application/json',
  'application/xml',
  'application/yaml',
  'text/plain',
  'text/html',
  'text/markdown',
];

/// Says hello in the media type the `Accept` header asks for.
@ApiRoute(
  method: ApiMethod.get,
  path: '/media/greeting',
  summary: 'Say hello in the format you ask for',
  description:
      'Send `Accept` with any of the media types below. The same greeting is '
      'rendered as JSON, XML, YAML, plain text, HTML, or Markdown. '
      '`Accept: text/html;q=0.9, application/json;q=0.5` picks HTML.',
  tags: _tags,
  queryParams: [
    ApiQueryParam(
      'name',
      type: String,
      defaultValue: 'axle',
      maxLength: 40,
      description: 'Who to greet.',
      example: 'Ada',
    ),
  ],
  responses: [
    ApiResponse(
      status: 200,
      type: Greeting,
      description: 'The greeting.',
      headers: [
        varyHeader,
        ApiResponseHeader(
          'Content-Language',
          type: String,
          description: 'The language of the greeting.',
          example: 'en',
        ),
      ],
    ),
    ApiResponse(
      status: 200,
      type: Greeting,
      contentTypes: ['application/xml', 'application/yaml'],
    ),
    ApiResponse(
      status: 200,
      type: String,
      contentTypes: ['text/plain', 'text/html', 'text/markdown'],
    ),
    notAcceptable,
    ...catchAllErrors,
  ],
)
Future<Response> greeting(Request request) async {
  final type = negotiate(request, _greetingTypes);
  if (type == null) {
    return problem(
      406,
      'Not Acceptable',
      detail: 'Supported: ${_greetingTypes.join(', ')}.',
    );
  }
  final name = request.url.queryParameters['name'] ?? 'axle';
  final value = Greeting(message: 'Hello, $name!', language: 'en');
  final headers = {'vary': 'Accept', 'content-language': 'en'};
  final message = value.message;

  return switch (type) {
    'application/xml' => text(
      '<?xml version="1.0" encoding="UTF-8"?>\n'
      '<greeting><message>${xmlEscape(message)}</message>'
      '<language>${value.language}</language></greeting>\n',
      contentType: 'application/xml; charset=utf-8',
      headers: headers,
    ),
    'application/yaml' => text(
      'message: ${jsonEncode(message)}\nlanguage: ${value.language}\n',
      contentType: 'application/yaml; charset=utf-8',
      headers: headers,
    ),
    'text/plain' => text(message, headers: headers),
    'text/html' => text(
      '<!doctype html><title>Greeting</title><h1>${xmlEscape(message)}</h1>\n',
      contentType: 'text/html; charset=utf-8',
      headers: headers,
    ),
    'text/markdown' => text(
      '# ${message.replaceAll('#', r'\#')}\n',
      contentType: 'text/markdown; charset=utf-8',
      headers: headers,
    ),
    _ => json(value.toJson(), headers: headers),
  };
}

// ---------------------------------------------------------------------------
// Tabular formats: a structured response and two flat ones.

const _reportTypes = [
  'application/json',
  'text/csv',
  'text/tab-separated-values',
];

Report _report() => Report(
  title: 'Quarterly scores',
  generatedAt: DateTime.utc(2026, 10, 24, 9),
  rows: [
    for (var i = 1; i <= 4; i++)
      ReportRow(id: i, name: 'Team $i', score: i / 5),
  ],
);

/// A report as JSON, CSV, or TSV.
@ApiRoute(
  method: ApiMethod.get,
  path: '/media/report',
  summary: 'A report as JSON, CSV, or TSV',
  description:
      'The JSON form has a schema. The CSV and TSV forms are flat text with a '
      'header row, sent as an attachment so browsers download them.',
  tags: _tags,
  responses: [
    ApiResponse(
      status: 200,
      type: Report,
      description: 'The report.',
      headers: [varyHeader],
    ),
    ApiResponse(
      status: 200,
      type: String,
      contentTypes: ['text/csv', 'text/tab-separated-values'],
      headers: [
        ApiResponseHeader(
          'Content-Disposition',
          type: String,
          description: 'Asks the browser to save the file.',
          example: 'attachment; filename="report.csv"',
        ),
      ],
    ),
    notAcceptable,
    ...catchAllErrors,
  ],
)
Future<Response> report(Request request) async {
  final type = negotiate(request, _reportTypes);
  if (type == null) return problem(406, 'Not Acceptable');
  final value = _report();
  if (type == 'application/json') {
    return json(value.toJson(), headers: {'vary': 'Accept'});
  }
  final separator = type == 'text/csv' ? ',' : '\t';
  final extension = type == 'text/csv' ? 'csv' : 'tsv';
  final lines = [
    ['id', 'name', 'score'].join(separator),
    for (final row in value.rows) [row.id, row.name, row.score].join(separator),
  ];
  return text(
    '${lines.join('\n')}\n',
    contentType: '$type; charset=utf-8',
    headers: {
      'vary': 'Accept',
      'content-disposition': 'attachment; filename="report.$extension"',
    },
  );
}

// ---------------------------------------------------------------------------
// Vendor media types.

/// Greeting under a versioned vendor media type.
@ApiRoute(
  method: ApiMethod.get,
  path: '/media/vendor',
  summary: 'Content negotiation with a vendor media type',
  description:
      'Send `Accept: application/vnd.axle.v2+json` for the versioned form, or '
      '`application/json` for the default.',
  tags: _tags,
  responses: [
    ApiResponse(
      status: 200,
      type: Greeting,
      contentTypes: ['application/vnd.axle.v2+json', 'application/json'],
      headers: [varyHeader],
    ),
    notAcceptable,
  ],
)
Future<Response> vendorGreeting(Request request) async {
  const types = ['application/vnd.axle.v2+json', 'application/json'];
  final type = negotiate(request, types);
  if (type == null) return problem(406, 'Not Acceptable');
  return json(
    const Greeting(message: 'Hello from v2', language: 'en').toJson(),
    contentType: type,
    headers: {'vary': 'Accept'},
  );
}

// ---------------------------------------------------------------------------
// Streams.

/// Streams report rows, one JSON object per line.
@ApiRoute(
  method: ApiMethod.get,
  path: '/media/stream/ndjson',
  summary: 'Stream rows as newline-delimited JSON',
  description:
      'Each line is one `ReportRow`. Read the response as it arrives instead '
      'of waiting for the end.',
  tags: _tags,
  queryParams: [
    ApiQueryParam(
      'count',
      type: int,
      defaultValue: 5,
      minimum: 1,
      maximum: 1000,
      description: 'How many rows to send.',
    ),
  ],
  responses: [
    ApiResponse(
      status: 200,
      type: ReportRow,
      description: 'One JSON object per line.',
      contentTypes: ['application/x-ndjson'],
      headers: [
        ApiResponseHeader(
          'Transfer-Encoding',
          type: String,
          description: 'The body is streamed in chunks.',
          example: 'chunked',
        ),
      ],
    ),
    badRequest,
  ],
)
Future<Response> streamNdjson(Request request) async {
  final count = int.tryParse(request.url.queryParameters['count'] ?? '5');
  if (count == null || count < 1 || count > 1000) {
    return problem(400, 'Bad Request', detail: '`count` must be 1 to 1000.');
  }
  final lines = Stream.fromIterable([
    for (var i = 1; i <= count; i++)
      utf8.encode(
        '${jsonEncode(ReportRow(id: i, name: 'Row $i', score: i / count).toJson())}\n',
      ),
  ]);
  return Response.ok(lines, headers: {'content-type': 'application/x-ndjson'});
}

/// Sends server-sent events.
@ApiRoute(
  method: ApiMethod.get,
  path: '/media/stream/events',
  summary: 'Server-sent events',
  description:
      'Each event has an `id`, an `event` name, and JSON in `data`. Use '
      '`EventSource` in a browser.',
  tags: _tags,
  queryParams: [
    ApiQueryParam('count', type: int, defaultValue: 3, minimum: 1, maximum: 20),
  ],
  responses: [
    ApiResponse(
      status: 200,
      type: String,
      description:
          'An endless-style event stream; this one ends after `count`.',
      contentTypes: ['text/event-stream'],
      headers: [
        ApiResponseHeader('Cache-Control', type: String, example: 'no-cache'),
      ],
      example: 'id: 1\nevent: tick\ndata: {"n":1}\n\n',
    ),
    badRequest,
  ],
)
Future<Response> streamEvents(Request request) async {
  final count = int.tryParse(request.url.queryParameters['count'] ?? '3');
  if (count == null || count < 1 || count > 20) {
    return problem(400, 'Bad Request', detail: '`count` must be 1 to 20.');
  }
  final events = Stream.periodic(
    const Duration(milliseconds: 250),
    (i) => utf8.encode('id: ${i + 1}\nevent: tick\ndata: {"n":${i + 1}}\n\n'),
  ).take(count);
  return Response.ok(
    events,
    headers: {'content-type': 'text/event-stream', 'cache-control': 'no-cache'},
  );
}

// ---------------------------------------------------------------------------
// Binary downloads.

// A 1x1 transparent PNG.
final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

const _svg =
    '<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64">'
    '<circle cx="32" cy="32" r="30" fill="#6c5ce7"/></svg>\n';

const _logoEtag = '"logo-v1"';

/// The logo as PNG or SVG.
@ApiRoute(
  method: ApiMethod.get,
  path: '/media/logo',
  summary: 'An image as PNG or SVG',
  description:
      'PNG is binary, so its schema is `string` with `format: binary`. SVG is '
      'text. Send `If-None-Match` with the `ETag` to get `304`.',
  tags: _tags,
  headerParams: [
    ApiHeaderParam(
      'If-None-Match',
      type: String,
      description: 'An `ETag` from an earlier response.',
      example: _logoEtag,
    ),
  ],
  responses: [
    ApiResponse(
      status: 200,
      type: Uint8List,
      description: 'The image.',
      contentTypes: ['image/png'],
      headers: [
        ApiResponseHeader('ETag', type: String, example: _logoEtag),
        ApiResponseHeader(
          'Cache-Control',
          type: String,
          example: 'public, max-age=86400, immutable',
        ),
        varyHeader,
      ],
    ),
    ApiResponse(status: 200, type: String, contentTypes: ['image/svg+xml']),
    ApiResponse(
      status: 304,
      description: 'The cached copy is still current.',
      headers: [ApiResponseHeader('ETag', type: String, example: _logoEtag)],
    ),
    notAcceptable,
  ],
)
Future<Response> logo(Request request) async {
  final type = negotiate(request, ['image/png', 'image/svg+xml']);
  if (type == null) return problem(406, 'Not Acceptable');
  final headers = {
    'etag': _logoEtag,
    'cache-control': 'public, max-age=86400, immutable',
    'vary': 'Accept',
  };
  if (request.headers['if-none-match'] == _logoEtag) {
    return Response(304, headers: headers);
  }
  return type == 'image/png'
      ? binary(_png, contentType: type, headers: headers)
      : text(_svg, contentType: type, headers: headers);
}

/// Builds a one-page PDF that says [message].
Uint8List _pdf(String message) {
  final content =
      'BT /F1 18 Tf 20 50 Td (${message.replaceAll('(', '')}) Tj ET';
  final objects = <String>[
    '<< /Type /Catalog /Pages 2 0 R >>',
    '<< /Type /Pages /Kids [3 0 R] /Count 1 >>',
    '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 240 100] '
        '/Contents 4 0 R /Resources << /Font << /F1 5 0 R >> >> >>',
    '<< /Length ${content.length} >>\nstream\n$content\nendstream',
    '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>',
  ];
  final out = StringBuffer('%PDF-1.4\n');
  final offsets = <int>[];
  for (var i = 0; i < objects.length; i++) {
    offsets.add(out.length);
    out.write('${i + 1} 0 obj\n${objects[i]}\nendobj\n');
  }
  final xref = out.length;
  out.write('xref\n0 ${objects.length + 1}\n0000000000 65535 f \n');
  for (final offset in offsets) {
    out.write('${offset.toString().padLeft(10, '0')} 00000 n \n');
  }
  out.write(
    'trailer\n<< /Size ${objects.length + 1} /Root 1 0 R >>\n'
    'startxref\n$xref\n%%EOF\n',
  );
  return Uint8List.fromList(latin1.encode(out.toString()));
}

/// A generated PDF.
@ApiRoute(
  method: ApiMethod.get,
  path: '/media/document.pdf',
  summary: 'Download a PDF',
  tags: _tags,
  responses: [
    ApiResponse(
      status: 200,
      type: Uint8List,
      description: 'A one-page PDF.',
      contentTypes: ['application/pdf'],
      headers: [
        ApiResponseHeader(
          'Content-Disposition',
          type: String,
          example: 'inline; filename="showcase.pdf"',
        ),
        ApiResponseHeader('Content-Length', type: int, example: 640),
      ],
    ),
  ],
)
Future<Response> document(Request request) async {
  return binary(
    _pdf('axle showcase'),
    contentType: 'application/pdf',
    headers: {'content-disposition': 'inline; filename="showcase.pdf"'},
  );
}

// ---------------------------------------------------------------------------
// Raw bytes, with ranges.

final _blob = Uint8List.fromList([for (var i = 0; i < 1000; i++) i % 256]);

/// Downloads 1000 bytes, whole or in a range.
@ApiRoute(
  method: ApiMethod.get,
  path: '/media/blob',
  summary: 'Download bytes, with range support',
  description:
      'Send `Range: bytes=0-99` for a partial response. The blob is 1000 '
      'bytes, byte `i` has value `i % 256`.',
  tags: _tags,
  headerParams: [
    ApiHeaderParam(
      'Range',
      type: String,
      pattern: r'^bytes=\d*-\d*$',
      description: 'A single byte range.',
      example: 'bytes=0-99',
    ),
  ],
  responses: [
    ApiResponse(
      status: 200,
      type: Uint8List,
      description: 'All 1000 bytes.',
      contentTypes: ['application/octet-stream'],
      headers: [
        ApiResponseHeader('Accept-Ranges', type: String, example: 'bytes'),
      ],
    ),
    ApiResponse(
      status: 206,
      type: Uint8List,
      description: 'The requested range.',
      contentTypes: ['application/octet-stream'],
      headers: [
        ApiResponseHeader(
          'Content-Range',
          type: String,
          required: true,
          example: 'bytes 0-99/1000',
        ),
      ],
    ),
    ApiResponse(
      status: 416,
      type: Problem,
      description: 'The range cannot be satisfied.',
      contentTypes: [problemJson],
      headers: [
        ApiResponseHeader(
          'Content-Range',
          type: String,
          example: 'bytes */1000',
        ),
      ],
    ),
  ],
)
Future<Response> readBlob(Request request) async {
  final range = request.headers['range'];
  const type = 'application/octet-stream';
  if (range == null) {
    return binary(
      _blob,
      contentType: type,
      headers: {'accept-ranges': 'bytes'},
    );
  }
  final match = RegExp(r'^bytes=(\d*)-(\d*)$').firstMatch(range);
  int? start;
  int? end;
  if (match != null) {
    final first = int.tryParse(match.group(1)!);
    final last = int.tryParse(match.group(2)!);
    if (first == null && last != null) {
      start = (_blob.length - last).clamp(0, _blob.length - 1);
      end = _blob.length - 1;
    } else if (first != null) {
      start = first;
      end = (last ?? _blob.length - 1).clamp(0, _blob.length - 1);
    }
  }
  if (start == null || end == null || start > end || start >= _blob.length) {
    return problem(
      416,
      'Range Not Satisfiable',
      headers: {'content-range': 'bytes */${_blob.length}'},
    );
  }
  return binary(
    _blob.sublist(start, end + 1),
    contentType: type,
    status: 206,
    headers: {'content-range': 'bytes $start-$end/${_blob.length}'},
  );
}

/// Accepts raw bytes.
@ApiRoute(
  method: ApiMethod.put,
  path: '/media/blob',
  summary: 'Upload raw bytes',
  description: 'The body is the file itself, not JSON and not multipart.',
  tags: _tags,
  body: ApiBody(Uint8List, contentTypes: ['application/octet-stream']),
  responses: [
    ApiResponse(
      status: 201,
      type: StoredFile,
      description: 'The bytes were received.',
      headers: [
        ApiResponseHeader('Location', type: String, example: '/media/blob'),
      ],
    ),
    badRequest,
    unsupportedMediaType,
  ],
)
Future<Response> writeBlob(Request request) async {
  final type = request.headers['content-type'] ?? '';
  if (!type.startsWith('application/octet-stream')) {
    return problem(415, 'Unsupported Media Type', detail: 'Send octet-stream.');
  }
  final bytes = await request.read().expand((chunk) => chunk).toList();
  if (bytes.isEmpty) return problem(400, 'Bad Request', detail: 'Empty body.');
  return json(
    StoredFile(
      field: 'body',
      filename: null,
      contentType: type,
      size: bytes.length,
      checksum: checksum(bytes),
    ).toJson(),
    status: 201,
    headers: {'location': '/media/blob'},
  );
}

// ---------------------------------------------------------------------------
// Forms.

/// Receives a multipart upload: fields, one cover, and many attachments.
@ApiRoute(
  method: ApiMethod.post,
  path: '/media/upload',
  summary: 'Upload files with multipart/form-data',
  description:
      'Fields: `title` (text), `tags` (text, repeat it), `cover` (one file), '
      '`attachments` (any number of files). The server reads every part and '
      'reports what arrived.',
  tags: _tags,
  body: ApiBody(UploadForm, contentTypes: ['multipart/form-data']),
  responses: [
    ApiResponse(
      status: 201,
      type: UploadResult,
      description: 'Everything that arrived.',
    ),
    badRequest,
    ApiResponse(
      status: 413,
      type: Problem,
      description: 'The upload is larger than 5 MB.',
      contentTypes: [problemJson],
    ),
    unsupportedMediaType,
  ],
)
Future<Response> upload(Request request) async {
  final parts = await readMultipart(request);
  if (parts == null) {
    return problem(415, 'Unsupported Media Type', detail: 'Send multipart.');
  }
  final size = parts.fold<int>(0, (sum, part) => sum + part.bytes.length);
  if (size > 5 * 1024 * 1024) return problem(413, 'Payload Too Large');
  final title = parts.where((p) => p.name == 'title').firstOrNull?.text.trim();
  if (title == null || title.isEmpty) {
    return problem(400, 'Bad Request', detail: '`title` is required.');
  }
  return json(
    UploadResult(
      title: title,
      tags: [for (final p in parts.where((p) => p.name == 'tags')) p.text],
      files: [
        for (final p in parts.where((p) => p.filename != null))
          StoredFile(
            field: p.name,
            filename: p.filename,
            contentType: p.contentType,
            size: p.bytes.length,
            checksum: checksum(p.bytes),
          ),
      ],
    ).toJson(),
    status: 201,
  );
}

/// Describes what `/media/upload` accepts.
@ApiRoute(
  method: ApiMethod.options,
  path: '/media/upload',
  summary: 'What can I send to the upload route?',
  tags: _tags,
  responses: [
    ApiResponse(
      status: 204,
      description: 'The methods and media types the route accepts.',
      headers: [
        ApiResponseHeader('Allow', type: String, example: 'POST, OPTIONS'),
        ApiResponseHeader(
          'Accept-Post',
          type: String,
          example: 'multipart/form-data',
        ),
      ],
    ),
  ],
)
Future<Response> uploadOptions(Request request) async {
  return Response(
    204,
    headers: {'allow': 'POST, OPTIONS', 'accept-post': 'multipart/form-data'},
  );
}

/// Signs in with a form or with JSON.
@ApiRoute(
  method: ApiMethod.post,
  path: '/media/login',
  summary: 'Sign in with a form or JSON',
  description:
      'The same `LoginForm` schema is accepted as '
      '`application/x-www-form-urlencoded` or `application/json`. Use `demo` '
      'and `demo`.',
  tags: _tags,
  body: ApiBody(
    LoginForm,
    contentTypes: ['application/x-www-form-urlencoded', 'application/json'],
    examples: {
      'demo': ApiExample({
        'username': 'demo',
        'password': 'demo',
      }, summary: 'The demo account'),
      'wrong': ApiExample({
        'username': 'demo',
        'password': 'nope',
      }, summary: 'Rejected with 401'),
    },
  ),
  responses: [
    ApiResponse(
      status: 200,
      type: Token,
      description: 'Signed in.',
      headers: [
        ApiResponseHeader(
          'Set-Cookie',
          type: String,
          description: 'Also sets the session cookie `api_session`.',
          example: 'api_session=demo-key; HttpOnly; SameSite=Strict; Path=/',
        ),
      ],
    ),
    badRequest,
    ApiResponse(
      status: 401,
      type: Problem,
      description: 'Wrong credentials.',
      contentTypes: [problemJson],
    ),
    unsupportedMediaType,
  ],
)
Future<Response> login(Request request) async {
  final type = MediaType.parse(request.headers['content-type'] ?? '').mime;
  final Map<String, Object?> fields;
  try {
    final body = await request.readAsString();
    if (type == 'application/x-www-form-urlencoded') {
      fields = Uri.splitQueryString(body);
    } else if (type == 'application/json') {
      fields = (jsonDecode(body) as Map).cast<String, Object?>();
    } else {
      return problem(415, 'Unsupported Media Type');
    }
  } on Object {
    return problem(400, 'Bad Request', detail: 'The body is malformed.');
  }
  if (fields['username'] != 'demo' || fields['password'] != 'demo') {
    return problem(
      401,
      'Unauthorized',
      headers: {'www-authenticate': 'Basic realm="showcase"'},
    );
  }
  return json(
    const Token(accessToken: 'demo-token', expiresIn: 3600).toJson(),
    headers: {
      'set-cookie': 'api_session=demo-key; HttpOnly; SameSite=Strict; Path=/',
    },
  );
}

// ---------------------------------------------------------------------------
// PATCH with two patch formats.

final _documents = <int, DocumentRecord>{
  1: const DocumentRecord(id: 1, title: 'Draft', completed: false, revision: 1),
};

/// Changes a document with a merge patch or a JSON Patch.
@ApiRoute(
  method: ApiMethod.patch,
  path: '/media/documents/<id>',
  summary: 'Patch a document in either patch format',
  description:
      'Send `application/merge-patch+json` with the fields to change, or '
      '`application/json-patch+json` with a list of operations. This route '
      'supports `replace` and `test` on `/title` and `/completed`.',
  tags: _tags,
  pathParams: [ApiPathParam('id', type: int, minimum: 1, example: 1)],
  body: ApiBody(
    MergePatch,
    contentTypes: ['application/merge-patch+json'],
    examples: {
      'rename': ApiExample({'title': 'Final'}, summary: 'Change the title'),
      'finish': ApiExample({'completed': true}),
    },
  ),
  bodies: [
    ApiBody(
      List<PatchOperation>,
      contentTypes: ['application/json-patch+json'],
      examples: {
        'rename': ApiExample([
          {'op': 'replace', 'path': '/title', 'value': 'Final'},
        ]),
      },
    ),
  ],
  responses: [
    ApiResponse(
      status: 200,
      type: DocumentRecord,
      description: 'The document after the patch.',
      headers: [ApiResponseHeader('ETag', type: String, example: '"2"')],
    ),
    badRequest,
    ApiResponse(
      status: 404,
      type: Problem,
      description: 'No such document.',
      contentTypes: [problemJson],
    ),
    unsupportedMediaType,
    ApiResponse(
      status: 422,
      type: Problem,
      description: 'A patch operation is not supported or failed.',
      contentTypes: [problemJson],
    ),
  ],
)
Future<Response> patchDocument(Request request, String id) async {
  final document = _documents[int.tryParse(id)];
  if (document == null) return problem(404, 'Not Found');

  final type = MediaType.parse(request.headers['content-type'] ?? '').mime;
  if (type != 'application/merge-patch+json' &&
      type != 'application/json-patch+json') {
    return problem(
      415,
      'Unsupported Media Type',
      detail: 'Send merge-patch+json or json-patch+json.',
    );
  }
  var title = document.title;
  var completed = document.completed;
  try {
    final body = jsonDecode(await request.readAsString());
    if (type == 'application/merge-patch+json') {
      final patch = (body as Map).cast<String, Object?>();
      if (patch['title'] is String) title = patch['title']! as String;
      if (patch['completed'] is bool) completed = patch['completed']! as bool;
    } else {
      for (final step in (body as List).cast<Map<String, Object?>>()) {
        final path = step['path'];
        final op = step['op'];
        if ((op != 'replace' && op != 'test') ||
            (path != '/title' && path != '/completed')) {
          return problem(422, 'Unprocessable Entity', detail: '$op $path');
        }
        if (op == 'test') {
          final current = path == '/title' ? title : completed;
          if (current != step['value']) {
            return problem(422, 'Unprocessable Entity', detail: 'test failed');
          }
        } else if (path == '/title') {
          title = step['value']! as String;
        } else {
          completed = step['value']! as bool;
        }
      }
    }
  } on Object {
    return problem(400, 'Bad Request', detail: 'The patch is malformed.');
  }

  final updated = DocumentRecord(
    id: document.id,
    title: title,
    completed: completed,
    revision: document.revision + 1,
  );
  _documents[updated.id] = updated;
  return json(updated.toJson(), headers: {'etag': '"${updated.revision}"'});
}
