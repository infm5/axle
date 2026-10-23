import 'package:axle_shelf/axle_shelf.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../http/responses.dart';
import '../models/note.dart';
import '../repositories/note_repository.dart';

late NoteRepository _repository;

/// Registers the Todo API routes on [router].
void configureApi(Router router, {NoteRepository? repository}) {
  _repository = repository ?? NoteRepository.seeded();
  router
    ..get('/health', health)
    ..get('/notes', listNotes)
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
  if (query.containsKey('limit') && limit == null) {
    return jsonError(
      400,
      'invalid_query',
      '`limit` must be a positive integer.',
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
  responses: [ApiResponse.created(Note), ApiResponse.badRequest(ApiError)],
)
Future<Response> createNote(Request request) async {
  final body = await readJsonObject(request);
  if (body == null) {
    return jsonError(400, 'invalid_body', 'The body must be a JSON object.');
  }
  final title = body['title'];
  if (title is! String || title.trim().isEmpty) {
    return jsonError(400, 'invalid_title', '`title` is required.');
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
  return jsonResponse(note.toJson(), status: 201);
}

/// Gets one note.
@ApiRoute(
  method: ApiMethod.get,
  path: '/notes/:id',
  summary: 'Get a note',
  tags: ['Notes'],
  pathParams: [ApiPathParam('id', type: int, description: 'The note id.')],
  responses: [
    ApiResponse.ok(Note),
    ApiResponse.badRequest(ApiError),
    ApiResponse.notFound(ApiError),
  ],
)
Future<Response> getNote(Request request, String id) async {
  final noteId = int.tryParse(id);
  if (noteId == null) {
    return jsonError(400, 'invalid_id', '`id` must be an integer.');
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
  pathParams: [ApiPathParam('id', type: int, description: 'The note id.')],
  body: ApiBody(UpdateNote),
  responses: [
    ApiResponse.ok(Note),
    ApiResponse.badRequest(ApiError),
    ApiResponse.notFound(ApiError),
  ],
)
Future<Response> updateNote(Request request, String id) async {
  final noteId = int.tryParse(id);
  if (noteId == null) {
    return jsonError(400, 'invalid_id', '`id` must be an integer.');
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
  if (title != null && (title is! String || title.trim().isEmpty)) {
    return jsonError(
      400,
      'invalid_title',
      '`title` must be a non-empty string.',
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
  pathParams: [ApiPathParam('id', type: int, description: 'The note id.')],
  responses: [
    ApiResponse.noContent(),
    ApiResponse.badRequest(ApiError),
    ApiResponse.notFound(ApiError),
  ],
)
Future<Response> deleteNote(Request request, String id) async {
  final noteId = int.tryParse(id);
  if (noteId == null) {
    return jsonError(400, 'invalid_id', '`id` must be an integer.');
  }
  if (!_repository.delete(noteId)) {
    return jsonError(404, 'note_not_found', 'Note $noteId does not exist.');
  }
  return Response(204);
}
