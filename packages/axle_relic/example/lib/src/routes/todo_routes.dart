import 'package:axle_relic/axle_relic.dart';
import 'package:relic/relic.dart';

import '../http/responses.dart';
import '../models/todo.dart';
import '../repositories/todo_repository.dart';

late TodoRepository _repository;

const _demoApiKey = 'demo-key';
const _vendorJson = MimeType('application', 'vnd.axle+json');
const _windows = {'all', 'active', 'completed'};

/// Registers the Todo API routes on [app].
void configureApi(RelicApp app, {TodoRepository? repository}) {
  _repository = repository ?? TodoRepository.seeded();
  app
    ..get('/health', health)
    ..get('/todos', listTodos)
    ..get('/todos/stats', todoStats)
    ..get('/todos/activity', todoActivity)
    ..post('/todos/import', importTodos)
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
      minimum: 1,
      maximum: 100,
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
  if (query.containsKey('limit') &&
      (limit == null || limit < 1 || limit > 100)) {
    return jsonError(
      400,
      'invalid_query',
      '`limit` must be an integer between 1 and 100.',
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
  responses: [
    ApiResponse(
      status: 201,
      type: Todo,
      description: 'Created',
      headers: [
        ApiResponseHeader(
          'Location',
          type: String,
          description: 'URL of the created todo.',
        ),
      ],
    ),
    ApiResponse.badRequest(ApiError),
  ],
)
Future<Result> createTodo(Request request) async {
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

  final todo = _repository.create(
    title: title.trim(),
    description: description as String?,
  );
  return jsonResponse(
    todo.toJson(),
    status: 201,
    headers: {'Location': '/todos/${todo.id}'},
  );
}

/// Gets one todo.
@ApiRoute(
  method: ApiMethod.get,
  path: '/todos/:id',
  summary: 'Get a todo',
  tags: ['Todos'],
  pathParams: [
    ApiPathParam('id', type: int, minimum: 1, description: 'The todo id.'),
  ],
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
  pathParams: [
    ApiPathParam('id', type: int, minimum: 1, description: 'The todo id.'),
  ],
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
  pathParams: [
    ApiPathParam('id', type: int, minimum: 1, description: 'The todo id.'),
  ],
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

/// Returns a summary of todos.
@ApiRoute(
  method: ApiMethod.get,
  path: '/todos/stats',
  summary: 'Get todo statistics',
  tags: ['Todos'],
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
      type: TodoStats,
      description: 'Todo statistics.',
      contentTypes: ['application/json', 'application/vnd.axle+json'],
      headers: [
        ApiResponseHeader(
          'X-Total-Count',
          type: int,
          description: 'The total number of todos.',
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
Future<Result> todoStats(Request request) async {
  if (!_isAuthorized(request)) return _unauthorized();

  final window = request.url.queryParameters['window'] ?? 'all';
  if (!_windows.contains(window)) {
    return jsonError(
      400,
      'invalid_window',
      '`window` must be `all`, `active`, or `completed`.',
    );
  }

  final todos = _repository.list();
  final completed = todos.where((todo) => todo.completed).length;
  final active = todos.length - completed;
  final matching = switch (window) {
    'active' => active,
    'completed' => completed,
    _ => todos.length,
  };
  final stats = TodoStats(
    window: window,
    total: todos.length,
    completed: completed,
    active: active,
    matching: matching,
  );
  final session =
      request.headers.cookie?.getCookie('session')?.value ?? 'anonymous';
  final wantsVendor = (request.headers['accept']?.join(',') ?? '').contains(
    'application/vnd.axle+json',
  );
  return jsonResponse(
    stats.toJson(),
    headers: {'X-Total-Count': '${stats.total}', 'X-Session': session},
    mimeType: wantsVendor ? _vendorJson : MimeType.json,
  );
}

/// Lists recent todo activity.
@ApiRoute(
  method: ApiMethod.get,
  path: '/todos/activity',
  summary: 'List todo activity',
  tags: ['Todos'],
  responses: [ApiResponse.ok(List<TodoEvent>)],
)
Future<Result> todoActivity(Request request) async {
  final events = <TodoEvent>[];
  for (final todo in _repository.list()) {
    events.add(TodoCreatedEvent(todoId: todo.id, title: todo.title));
    if (todo.completed) {
      events.add(TodoCompletedEvent(todoId: todo.id, title: todo.title));
    }
  }
  return jsonResponse([for (final event in events) event.toJson()]);
}

/// Accepts a multipart todo import upload.
@ApiRoute(
  method: ApiMethod.post,
  path: '/todos/import',
  summary: 'Import todos from a multipart upload',
  tags: ['Todos'],
  body: ApiBody(TodoImport, contentTypes: ['multipart/form-data']),
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
Future<Result> importTodos(Request request) async {
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
    headers: {'Location': '/todos'},
  );
}

bool _isAuthorized(Request request) {
  final values = request.headers['x-api-key'];
  return values != null && values.contains(_demoApiKey);
}

Response _unauthorized() {
  return jsonError(
    401,
    'unauthorized',
    'Send the example API key in the X-API-Key header.',
  );
}

int? _parseId(Request request) {
  final raw = request.pathParameters.raw[#id];
  final id = raw == null ? null : int.tryParse(raw);
  return id == null || id < 1 ? null : id;
}
