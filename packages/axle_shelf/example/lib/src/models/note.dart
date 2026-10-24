/// DTOs used by the Shelf Todo API.
library;

import 'dart:typed_data';

import 'package:axle_shelf/axle_shelf.dart';

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
  @ApiProperty(minLength: 1, maxLength: 120)
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
  @ApiProperty(minLength: 1, maxLength: 120)
  final String title;

  /// An optional longer description.
  final String? description;
}

/// The request body for updating a note.
class UpdateNote {
  /// Creates an update request.
  const UpdateNote({this.title, this.description, this.completed});

  /// The new title.
  @ApiProperty(minLength: 1, maxLength: 120)
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

/// A summary of notes for a selected window.
@ApiSchema(description: 'A summary of notes for a selected window.')
class NoteStats {
  /// Creates a note summary.
  const NoteStats({
    required this.window,
    required this.total,
    required this.completed,
    required this.active,
    required this.matching,
  });

  /// The selected window.
  final String window;

  /// The total number of notes.
  @ApiProperty(minimum: 0)
  final int total;

  /// The number of completed notes.
  @ApiProperty(minimum: 0)
  final int completed;

  /// The number of active notes.
  @ApiProperty(minimum: 0)
  final int active;

  /// The number of notes matching [window].
  @ApiProperty(minimum: 0)
  final int matching;

  /// Serializes the summary.
  Map<String, Object?> toJson() => {
    'window': window,
    'total': total,
    'completed': completed,
    'active': active,
    'matching': matching,
  };
}

/// A note activity event.
@ApiSchema(
  description: 'A note activity event.',
  oneOf: [NoteCreatedEvent, NoteCompletedEvent],
  discriminator: ApiDiscriminator(
    'type',
    mapping: {'created': 'NoteCreatedEvent', 'completed': 'NoteCompletedEvent'},
  ),
)
sealed class NoteEvent {
  /// Creates an event.
  const NoteEvent();

  /// Serializes the event.
  Map<String, Object?> toJson();
}

/// A note was created.
@ApiSchema(description: 'A note was created.')
class NoteCreatedEvent extends NoteEvent {
  /// Creates a creation event.
  const NoteCreatedEvent({required this.noteId, required this.title});

  /// The event discriminator.
  @ApiProperty(required: true)
  final String type = 'created';

  /// The note id.
  @ApiProperty(minimum: 1)
  final int noteId;

  /// The note title.
  final String title;

  @override
  Map<String, Object?> toJson() => {
    'type': type,
    'noteId': noteId,
    'title': title,
  };
}

/// A note was completed.
@ApiSchema(description: 'A note was completed.')
class NoteCompletedEvent extends NoteEvent {
  /// Creates a completion event.
  const NoteCompletedEvent({required this.noteId, required this.title});

  /// The event discriminator.
  @ApiProperty(required: true)
  final String type = 'completed';

  /// The note id.
  @ApiProperty(minimum: 1)
  final int noteId;

  /// The note title.
  final String title;

  @override
  Map<String, Object?> toJson() => {
    'type': type,
    'noteId': noteId,
    'title': title,
  };
}

/// A multipart note import file.
@ApiSchema(description: 'A multipart note import file.')
class NoteImport {
  /// Creates an import upload.
  const NoteImport(this.file);

  /// The CSV file to import.
  @ApiProperty(format: 'binary', description: 'The CSV file to import.')
  final Uint8List file;
}

/// The result of accepting an import upload.
@ApiSchema(description: 'The result of accepting an import upload.')
class ImportResult {
  /// Creates an import result.
  const ImportResult({required this.bytes});

  /// The number of bytes received.
  @ApiProperty(minimum: 0)
  final int bytes;

  /// Serializes the result.
  Map<String, Object?> toJson() => {'bytes': bytes};
}
