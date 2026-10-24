import 'package:axle_shelf/axle_shelf.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../http/responses.dart';
import '../models/note.dart';
import '../repositories/note_repository.dart';

late NoteRepository _repository;

const _demoApiKey = 'demo-key';
const _vendorJson = 'application/vnd.axle+json';
const _windows = {'all', 'active', 'completed'};

/// Registers the Todo API routes on [router].
void configureApi(Router router, {NoteRepository? repository}) {
  _repository = repository ?? NoteRepository.seeded();
  router
    ..get('/health', health)
    ..get('/notes', listNotes)
    ..get('/notes/stats', noteStats)
    ..get('/notes/activity', noteActivity)
    ..post('/notes/import', importNotes)
    ..post('/notes', createNote)
    ..get('/notes/<id>', getNote)
    ..patch('/notes/<id>', updateNote)
    ..delete('/notes/<id>', deleteNote);
}

/// Health check.
@ApiRoute(
  method: ApiMethod.get,
  path: '/health',
  summary: 'Check service health',
  tags: ['System'],
  responses: [ApiResponse.ok(Health)],
)
Future<Response> health(Request request) async {
  return jsonResponse(Health(status: 'ok', checkedAt: DateTime.now()).toJson());
}

/// Lists notes.
@ApiRoute(
  method: ApiMethod.get,
  path: '/notes',
  summary: 'List notes',
  tags: ['Notes'],
  queryParams: [
    ApiQueryParam(
      'completed',
      type: bool,
      description: 'Filter by completion state.',
    ),
    ApiQueryParam(
      'limit',
      type: int,
      minimum: 1,
      maximum: 100,
      description: 'Maximum number of notes to return.',
    ),
  ],
  responses: [ApiResponse.ok(List<Note>), ApiResponse.badRequest(ApiError)],
)
Future<Response> listNotes(Request request) async {
  final query = request.url.queryParameters;
  final completed = parseQueryBool(query['completed']);
  if (query.containsKey('completed') && completed == null) {
    return jsonError(
      400,
      'invalid_query',
      '`completed` must be either `true` or `false`.',
    );
  }
  final limit = parseQueryInt(query['limit']);
  if (query.containsKey('limit') && (limit == null || limit > 100)) {
    return jsonError(
      400,
      'invalid_query',
      '`limit` must be an integer between 1 and 100.',
    );
  }

  final notes = _repository.list(completed: completed, limit: limit);
  return jsonResponse([for (final note in notes) note.toJson()]);
}

/// Creates a note.
@ApiRoute(
  method: ApiMethod.post,
  path: '/notes',
  summary: 'Create a note',
  tags: ['Notes'],
  body: ApiBody(CreateNote),
  responses: [
    ApiResponse(
      status: 201,
      type: Note,
      description: 'Created',
      headers: [
        ApiResponseHeader(
          'Location',
          type: String,
          description: 'URL of the created note.',
        ),
      ],
    ),
    ApiResponse.badRequest(ApiError),
  ],
)
Future<Response> createNote(Request request) async {
  final body = await readJsonObject(request);
  if (body == null) {
    return jsonError(400, 'invalid_body', 'The body must be a JSON object.');
  }
  final title = body['title'];
  if (title is! String || title.trim().isEmpty || title.trim().length > 120) {
    return jsonError(
      400,
      'invalid_title',
      '`title` must be between 1 and 120 characters.',
    );
  }
  final description = body['description'];
  if (description != null && description is! String) {
    return jsonError(
      400,
      'invalid_description',
      '`description` must be a string.',
    );
  }

  final note = _repository.create(
    title: title.trim(),
    description: description as String?,
  );
  return jsonResponse(
    note.toJson(),
    status: 201,
    headers: {'Location': '/notes/${note.id}'},
  );
}

/// Gets one note.
@ApiRoute(
  method: ApiMethod.get,
  path: '/notes/:id',
  summary: 'Get a note',
  tags: ['Notes'],
  pathParams: [
    ApiPathParam('id', type: int, minimum: 1, description: 'The note id.'),
  ],
  responses: [
    ApiResponse.ok(Note),
    ApiResponse.badRequest(ApiError),
    ApiResponse.notFound(ApiError),
  ],
)
Future<Response> getNote(Request request, String id) async {
  final noteId = int.tryParse(id);
  if (noteId == null || noteId < 1) {
    return jsonError(400, 'invalid_id', '`id` must be a positive integer.');
  }
  final note = _repository.get(noteId);
  if (note == null) {
    return jsonError(404, 'note_not_found', 'Note $noteId does not exist.');
  }
  return jsonResponse(note.toJson());
}

/// Updates a note.
@ApiRoute(
  method: ApiMethod.patch,
  path: '/notes/:id',
  summary: 'Update a note',
  tags: ['Notes'],
  pathParams: [
    ApiPathParam('id', type: int, minimum: 1, description: 'The note id.'),
  ],
  body: ApiBody(UpdateNote),
  responses: [
    ApiResponse.ok(Note),
    ApiResponse.badRequest(ApiError),
    ApiResponse.notFound(ApiError),
  ],
)
Future<Response> updateNote(Request request, String id) async {
  final noteId = int.tryParse(id);
  if (noteId == null || noteId < 1) {
    return jsonError(400, 'invalid_id', '`id` must be a positive integer.');
  }
  final body = await readJsonObject(request);
  if (body == null) {
    return jsonError(400, 'invalid_body', 'The body must be a JSON object.');
  }
  if (!body.containsKey('title') &&
      !body.containsKey('description') &&
      !body.containsKey('completed')) {
    return jsonError(
      400,
      'no_fields',
      'Provide at least one of `title`, `description`, or `completed`.',
    );
  }

  final title = body['title'];
  if (title != null &&
      (title is! String || title.trim().isEmpty || title.trim().length > 120)) {
    return jsonError(
      400,
      'invalid_title',
      '`title` must be between 1 and 120 characters.',
    );
  }
  final description = body['description'];
  if (description != null && description is! String) {
    return jsonError(
      400,
      'invalid_description',
      '`description` must be a string.',
    );
  }
  final completed = body['completed'];
  if (completed != null && completed is! bool) {
    return jsonError(
      400,
      'invalid_completed',
      '`completed` must be a boolean.',
    );
  }

  final note = _repository.update(
    noteId,
    title: title is String ? title.trim() : null,
    description: description as String?,
    completed: completed as bool?,
  );
  if (note == null) {
    return jsonError(404, 'note_not_found', 'Note $noteId does not exist.');
  }
  return jsonResponse(note.toJson());
}

/// Deletes a note.
@ApiRoute(
  method: ApiMethod.delete,
  path: '/notes/:id',
  summary: 'Delete a note',
  tags: ['Notes'],
  pathParams: [
    ApiPathParam('id', type: int, minimum: 1, description: 'The note id.'),
  ],
  responses: [
    ApiResponse.noContent(),
    ApiResponse.badRequest(ApiError),
    ApiResponse.notFound(ApiError),
  ],
)
Future<Response> deleteNote(Request request, String id) async {
  final noteId = int.tryParse(id);
  if (noteId == null || noteId < 1) {
    return jsonError(400, 'invalid_id', '`id` must be a positive integer.');
  }
  if (!_repository.delete(noteId)) {
    return jsonError(404, 'note_not_found', 'Note $noteId does not exist.');
  }
  return Response(204);
}

/// Returns a summary of notes.
@ApiRoute(
  method: ApiMethod.get,
  path: '/notes/stats',
  summary: 'Get note statistics',
  tags: ['Notes'],
  queryParams: [
    ApiQueryParam(
      'window',
      type: String,
      enumValues: ['all', 'active', 'completed'],
      defaultValue: 'all',
      description: 'The subset used for the matching count.',
    ),
  ],
  cookieParams: [
    ApiCookieParam(
      'session',
      type: String,
      description: 'Optional session id echoed in X-Session.',
    ),
  ],
  security: [
    ApiSecurityRequirement(['apiKey']),
  ],
  responses: [
    ApiResponse(
      status: 200,
      type: NoteStats,
      description: 'Note statistics.',
      contentTypes: ['application/json', 'application/vnd.axle+json'],
      headers: [
        ApiResponseHeader(
          'X-Total-Count',
          type: int,
          description: 'The total number of notes.',
        ),
        ApiResponseHeader(
          'X-Session',
          type: String,
          description: 'The session cookie value, or anonymous.',
        ),
      ],
    ),
    ApiResponse.badRequest(ApiError),
    ApiResponse(
      status: 401,
      type: ApiError,
      description: 'Missing or invalid API key.',
    ),
  ],
)
Future<Response> noteStats(Request request) async {
  if (!_isAuthorized(request)) return _unauthorized();

  final window = request.url.queryParameters['window'] ?? 'all';
  if (!_windows.contains(window)) {
    return jsonError(
      400,
      'invalid_window',
      '`window` must be `all`, `active`, or `completed`.',
    );
  }

  final notes = _repository.list();
  final completed = notes.where((note) => note.completed).length;
  final active = notes.length - completed;
  final matching = switch (window) {
    'active' => active,
    'completed' => completed,
    _ => notes.length,
  };
  final stats = NoteStats(
    window: window,
    total: notes.length,
    completed: completed,
    active: active,
    matching: matching,
  );
  final session = _cookieValue(request, 'session') ?? 'anonymous';
  final wantsVendor = (request.headers['accept'] ?? '').contains(_vendorJson);
  return jsonResponse(
    stats.toJson(),
    headers: {'X-Total-Count': '${stats.total}', 'X-Session': session},
    contentType: wantsVendor ? _vendorJson : 'application/json',
  );
}

/// Lists recent note activity.
@ApiRoute(
  method: ApiMethod.get,
  path: '/notes/activity',
  summary: 'List note activity',
  tags: ['Notes'],
  responses: [ApiResponse.ok(List<NoteEvent>)],
)
Future<Response> noteActivity(Request request) async {
  final events = <NoteEvent>[];
  for (final note in _repository.list()) {
    events.add(NoteCreatedEvent(noteId: note.id, title: note.title));
    if (note.completed) {
      events.add(NoteCompletedEvent(noteId: note.id, title: note.title));
    }
  }
  return jsonResponse([for (final event in events) event.toJson()]);
}

/// Accepts a multipart note import upload.
@ApiRoute(
  method: ApiMethod.post,
  path: '/notes/import',
  summary: 'Import notes from a multipart upload',
  tags: ['Notes'],
  body: ApiBody(NoteImport, contentTypes: ['multipart/form-data']),
  security: [
    ApiSecurityRequirement(['apiKey']),
  ],
  responses: [
    ApiResponse(
      status: 201,
      type: ImportResult,
      description: 'The upload was accepted.',
      headers: [
        ApiResponseHeader(
          'Location',
          type: String,
          description: 'The import collection URL.',
        ),
      ],
    ),
    ApiResponse.badRequest(ApiError),
    ApiResponse(
      status: 401,
      type: ApiError,
      description: 'Missing or invalid API key.',
    ),
  ],
)
Future<Response> importNotes(Request request) async {
  if (!_isAuthorized(request)) return _unauthorized();

  final bytes = await request.read().fold<int>(
    0,
    (total, chunk) => total + chunk.length,
  );
  if (bytes == 0) {
    return jsonError(400, 'empty_import', 'The upload body is empty.');
  }
  return jsonResponse(
    ImportResult(bytes: bytes).toJson(),
    status: 201,
    headers: {'Location': '/notes'},
  );
}

bool _isAuthorized(Request request) =>
    request.headers['x-api-key'] == _demoApiKey;

Response _unauthorized() {
  return jsonError(
    401,
    'unauthorized',
    'Send the example API key in the X-API-Key header.',
  );
}

String? _cookieValue(Request request, String name) {
  final header = request.headers['cookie'];
  if (header == null) return null;
  for (final part in header.split(';')) {
    final pair = part.trim().split('=');
    if (pair.length >= 2 && pair.first == name) {
      return Uri.decodeComponent(pair.sublist(1).join('='));
    }
  }
  return null;
}
