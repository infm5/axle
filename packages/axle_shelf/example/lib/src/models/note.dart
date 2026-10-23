/// DTOs used by the Shelf Todo API.
library;

/// A todo returned by the API.
class Note {
  /// Creates a todo.
  const Note({
    required this.id,
    required this.title,
    required this.completed,
    required this.createdAt,
    this.description,
  });

  /// The numeric note id.
  final int id;

  /// The note title.
  final String title;

  /// An optional longer description.
  final String? description;

  /// Whether the note is completed.
  final bool completed;

  /// When the note was created.
  final DateTime createdAt;

  /// Serializes the note.
  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    if (description != null) 'description': description,
    'completed': completed,
    'createdAt': createdAt.toIso8601String(),
  };
}

/// The request body for creating a note.
class CreateNote {
  /// Creates a note request.
  const CreateNote({required this.title, this.description});

  /// The note title.
  final String title;

  /// An optional longer description.
  final String? description;
}

/// The request body for updating a note.
class UpdateNote {
  /// Creates an update request.
  const UpdateNote({this.title, this.description, this.completed});

  /// The new title.
  final String? title;

  /// The new description.
  final String? description;

  /// The new completion state.
  final bool? completed;
}

/// A health check response.
class Health {
  /// Creates a health response.
  const Health({required this.status, required this.checkedAt});

  /// The service status.
  final String status;

  /// When the check ran.
  final DateTime checkedAt;

  /// Serializes the response.
  Map<String, Object?> toJson() => {
    'status': status,
    'checkedAt': checkedAt.toIso8601String(),
  };
}

/// An API error response.
class ApiError {
  /// Creates an error response.
  const ApiError({required this.code, required this.message});

  /// A stable error code.
  final String code;

  /// A human-readable message.
  final String message;

  /// Serializes the error.
  Map<String, Object?> toJson() => {'code': code, 'message': message};
}
