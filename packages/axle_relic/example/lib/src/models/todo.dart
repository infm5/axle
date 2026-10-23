import 'package:axle_relic/axle_relic.dart';

/// A todo item.
@ApiSchema(description: 'A todo item.')
class Todo {
  /// The numeric id.
  final int id;

  /// The todo title.
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
