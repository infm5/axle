import '../models/note.dart';

/// An in-memory note repository for the example.
class NoteRepository {
  NoteRepository.seeded() : _notes = _seedNotes(), _nextId = 3;

  final Map<int, Note> _notes;
  late int _nextId;

  /// Returns a filtered, optionally limited list.
  List<Note> list({bool? completed, int? limit}) {
    final notes =
        _notes.values
            .where((note) => completed == null || note.completed == completed)
            .toList()
          ..sort((a, b) => a.id.compareTo(b.id));
    if (limit == null || notes.length <= limit) return notes;
    return notes.take(limit).toList();
  }

  /// Returns one note, if it exists.
  Note? get(int id) => _notes[id];

  /// Creates a note.
  Note create({required String title, String? description}) {
    final note = Note(
      id: _nextId++,
      title: title,
      description: description,
      completed: false,
      createdAt: DateTime.now().toUtc(),
    );
    _notes[note.id] = note;
    return note;
  }

  /// Updates a note, returning `null` when it does not exist.
  Note? update(int id, {String? title, String? description, bool? completed}) {
    final existing = _notes[id];
    if (existing == null) return null;
    final updated = Note(
      id: existing.id,
      title: title ?? existing.title,
      description: description ?? existing.description,
      completed: completed ?? existing.completed,
      createdAt: existing.createdAt,
    );
    _notes[id] = updated;
    return updated;
  }

  /// Deletes a note.
  bool delete(int id) => _notes.remove(id) != null;
}

Map<int, Note> _seedNotes() {
  final now = DateTime.now().toUtc();
  return {
    1: Note(
      id: 1,
      title: 'Try axle_shelf',
      description: 'Open the mounted Swagger UI.',
      completed: false,
      createdAt: now,
    ),
    2: Note(id: 2, title: 'Ship an adapter', completed: false, createdAt: now),
  };
}
