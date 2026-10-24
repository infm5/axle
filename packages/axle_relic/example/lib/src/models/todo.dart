import 'dart:typed_data';

import 'package:axle_relic/axle_relic.dart';

/// A todo item.
@ApiSchema(description: 'A todo item.')
class Todo {
  /// The numeric id.
  final int id;

  /// The todo title.
  @ApiProperty(minLength: 1, maxLength: 120)
  final String title;

  /// An optional longer description.
  final String? description;

  /// Whether the todo is complete.
  final bool completed;

  /// When the todo was created.
  @ApiProperty(name: 'created_at')
  final DateTime createdAt;

  /// When the todo was last updated.
  @ApiProperty(name: 'updated_at')
  final DateTime updatedAt;

  /// Creates a todo item.
  const Todo({
    required this.id,
    required this.title,
    this.description,
    required this.completed,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Converts the todo to JSON.
  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    if (description != null) 'description': description,
    'completed': completed,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}

/// The request body for creating a todo.
@ApiSchema(description: 'The request body for creating a todo.')
class CreateTodo {
  /// The todo title.
  @ApiProperty(minLength: 1, maxLength: 120)
  final String title;

  /// An optional longer description.
  final String? description;

  /// Creates a create-todo request.
  const CreateTodo({required this.title, this.description});
}

/// The request body for updating a todo.
@ApiSchema(description: 'The request body for updating a todo.')
class UpdateTodo {
  /// The new title, when changing it.
  @ApiProperty(minLength: 1, maxLength: 120)
  final String? title;

  /// The new description, when changing it.
  final String? description;

  /// The new completion state, when changing it.
  final bool? completed;

  /// Creates an update-todo request.
  const UpdateTodo({this.title, this.description, this.completed});
}

/// A health check response.
@ApiSchema(description: 'A health check response.')
class Health {
  /// The service status.
  final String status;

  /// When the check was performed.
  @ApiProperty(name: 'checked_at')
  final DateTime checkedAt;

  /// Creates a health check response.
  const Health({required this.status, required this.checkedAt});

  /// Converts the health check to JSON.
  Map<String, Object?> toJson() => {
    'status': status,
    'checked_at': checkedAt.toIso8601String(),
  };
}

/// An API error.
@ApiSchema(description: 'An API error.')
class ApiError {
  /// A stable machine-readable error code.
  final String code;

  /// A human-readable error message.
  final String message;

  /// Creates an API error.
  const ApiError({required this.code, required this.message});

  /// Converts the error to JSON.
  Map<String, Object?> toJson() => {'code': code, 'message': message};
}

/// A summary of todos for a selected window.
@ApiSchema(description: 'A summary of todos for a selected window.')
class TodoStats {
  /// The selected window.
  final String window;

  /// The total number of todos.
  @ApiProperty(minimum: 0)
  final int total;

  /// The number of completed todos.
  @ApiProperty(minimum: 0)
  final int completed;

  /// The number of active todos.
  @ApiProperty(minimum: 0)
  final int active;

  /// The number of todos matching [window].
  @ApiProperty(minimum: 0)
  final int matching;

  /// Creates a todo summary.
  const TodoStats({
    required this.window,
    required this.total,
    required this.completed,
    required this.active,
    required this.matching,
  });

  /// Converts the summary to JSON.
  Map<String, Object?> toJson() => {
    'window': window,
    'total': total,
    'completed': completed,
    'active': active,
    'matching': matching,
  };
}

/// A todo activity event.
@ApiSchema(
  description: 'A todo activity event.',
  oneOf: [TodoCreatedEvent, TodoCompletedEvent],
  discriminator: ApiDiscriminator(
    'type',
    mapping: {'created': 'TodoCreatedEvent', 'completed': 'TodoCompletedEvent'},
  ),
)
sealed class TodoEvent {
  /// Creates an event.
  const TodoEvent();

  /// Converts the event to JSON.
  Map<String, Object?> toJson();
}

/// A todo was created.
@ApiSchema(description: 'A todo was created.')
class TodoCreatedEvent extends TodoEvent {
  /// The event discriminator.
  @ApiProperty(required: true)
  final String type = 'created';

  /// The todo id.
  @ApiProperty(name: 'todo_id', minimum: 1)
  final int todoId;

  /// The todo title.
  final String title;

  /// Creates a creation event.
  const TodoCreatedEvent({required this.todoId, required this.title});

  @override
  Map<String, Object?> toJson() => {
    'type': type,
    'todo_id': todoId,
    'title': title,
  };
}

/// A todo was completed.
@ApiSchema(description: 'A todo was completed.')
class TodoCompletedEvent extends TodoEvent {
  /// The event discriminator.
  @ApiProperty(required: true)
  final String type = 'completed';

  /// The todo id.
  @ApiProperty(name: 'todo_id', minimum: 1)
  final int todoId;

  /// The todo title.
  final String title;

  /// Creates a completion event.
  const TodoCompletedEvent({required this.todoId, required this.title});

  @override
  Map<String, Object?> toJson() => {
    'type': type,
    'todo_id': todoId,
    'title': title,
  };
}

/// A multipart todo import file.
@ApiSchema(description: 'A multipart todo import file.')
class TodoImport {
  /// The CSV file to import.
  @ApiProperty(format: 'binary', description: 'The CSV file to import.')
  final Uint8List file;

  /// Creates an import upload.
  const TodoImport(this.file);
}

/// The result of accepting an import upload.
@ApiSchema(description: 'The result of accepting an import upload.')
class ImportResult {
  /// The number of bytes received.
  @ApiProperty(minimum: 0)
  final int bytes;

  /// Creates an import result.
  const ImportResult({required this.bytes});

  /// Converts the result to JSON.
  Map<String, Object?> toJson() => {'bytes': bytes};
}
