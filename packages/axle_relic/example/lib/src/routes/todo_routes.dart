import 'package:axle_relic/axle_relic.dart';
import 'package:relic/relic.dart';

import '../http/responses.dart';
import '../models/todo.dart';
import '../repositories/todo_repository.dart';

late TodoRepository _repository;

/// Registers the Todo API routes on [app].
void configureApi(RelicApp app, {TodoRepository? repository}) {
  _repository = repository ?? TodoRepository.seeded();
  app
    ..get('/health', health)
    ..get('/todos', listTodos)
    ..post('/todos', createTodo)
    ..get('/todos/:id', getTodo)
    ..patch('/todos/:id', updateTodo)
    ..delete('/todos/:id', deleteTodo);
}

/// Health check.
@ApiRoute(
  method: ApiMethod.get,
  path: '/health',
  summary: 'Check service health',
  tags: ['System'],
  responses: [ApiResponse.ok(Health)],
)
Future<Result> health(Request request) async {
  return jsonResponse(
    Health(status: 'ok', checkedAt: DateTime.now().toUtc()).toJson(),
  );
}

/// Lists todos.
@ApiRoute(
  method: ApiMethod.get,
  path: '/todos',
  summary: 'List todos',
  tags: ['Todos'],
  queryParams: [
    ApiQueryParam(
      'completed',
      type: bool,
      description: 'Filter by completion state.',
    ),
    ApiQueryParam(
      'limit',
      type: int,
      description: 'Maximum number of todos to return.',
    ),
  ],
  responses: [ApiResponse.ok(List<Todo>)],
)
Future<Result> listTodos(Request request) async {
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
  if (query.containsKey('limit') && (limit == null || limit < 1)) {
    return jsonError(
      400,
      'invalid_query',
      '`limit` must be a positive integer.',
    );
  }

  final todos = _repository.list(completed: completed, limit: limit);
  return jsonResponse([for (final todo in todos) todo.toJson()]);
}

/// Creates a todo.
@ApiRoute(
  method: ApiMethod.post,
  path: '/todos',
  summary: 'Create a todo',
  tags: ['Todos'],
  body: ApiBody(CreateTodo),
  responses: [ApiResponse.created(Todo), ApiResponse.badRequest(ApiError)],
)
Future<Result> createTodo(Request request) async {
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

  final todo = _repository.create(
    title: title.trim(),
    description: description as String?,
  );
  return jsonResponse(todo.toJson(), status: 201);
}

/// Gets one todo.
@ApiRoute(
  method: ApiMethod.get,
  path: '/todos/:id',
  summary: 'Get a todo',
  tags: ['Todos'],
  pathParams: [ApiPathParam('id', type: int, description: 'The todo id.')],
  responses: [
    ApiResponse.ok(Todo),
    ApiResponse.badRequest(ApiError),
    ApiResponse.notFound(ApiError),
  ],
)
Future<Result> getTodo(Request request) async {
  final id = _parseId(request);
  if (id == null) {
    return jsonError(400, 'invalid_id', '`id` must be an integer.');
  }
  final todo = _repository.get(id);
  if (todo == null) {
    return jsonError(404, 'todo_not_found', 'Todo $id does not exist.');
  }
  return jsonResponse(todo.toJson());
}

/// Updates a todo.
@ApiRoute(
  method: ApiMethod.patch,
  path: '/todos/:id',
  summary: 'Update a todo',
  tags: ['Todos'],
  pathParams: [ApiPathParam('id', type: int, description: 'The todo id.')],
  body: ApiBody(UpdateTodo),
  responses: [
    ApiResponse.ok(Todo),
    ApiResponse.badRequest(ApiError),
    ApiResponse.notFound(ApiError),
  ],
)
Future<Result> updateTodo(Request request) async {
  final id = _parseId(request);
  if (id == null) {
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

  final todo = _repository.update(
    id,
    title: title is String ? title.trim() : null,
    description: description as String?,
    completed: completed as bool?,
  );
  if (todo == null) {
    return jsonError(404, 'todo_not_found', 'Todo $id does not exist.');
  }
  return jsonResponse(todo.toJson());
}

/// Deletes a todo.
@ApiRoute(
  method: ApiMethod.delete,
  path: '/todos/:id',
  summary: 'Delete a todo',
  tags: ['Todos'],
  pathParams: [ApiPathParam('id', type: int, description: 'The todo id.')],
  responses: [
    ApiResponse.noContent(),
    ApiResponse.badRequest(ApiError),
    ApiResponse.notFound(ApiError),
  ],
)
Future<Result> deleteTodo(Request request) async {
  final id = _parseId(request);
  if (id == null) {
    return jsonError(400, 'invalid_id', '`id` must be an integer.');
  }
  if (!_repository.delete(id)) {
    return jsonError(404, 'todo_not_found', 'Todo $id does not exist.');
  }
  return Response.noContent();
}

int? _parseId(Request request) {
  final raw = request.pathParameters.raw[#id];
  return raw == null ? null : int.tryParse(raw);
}
