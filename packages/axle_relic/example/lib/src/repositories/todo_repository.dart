import '../models/todo.dart';

/// An in-memory todo repository for the example.
class TodoRepository {
  /// Creates a repository, optionally seeded with [seed].
  TodoRepository({Iterable<Todo> seed = const []})
    : _todos = {for (final todo in seed) todo.id: todo},
      _nextId =
          seed.fold<int>(
            0,
            (largest, todo) => todo.id > largest ? todo.id : largest,
          ) +
          1;

  final Map<int, Todo> _todos;
  int _nextId;

  /// Creates a repository with a few example todos.
  factory TodoRepository.seeded() {
    final now = DateTime.now().toUtc();
    return TodoRepository(
      seed: [
        Todo(
          id: 1,
          title: 'Design the axle roadmap',
          description: 'Document scope, architecture, and phases.',
          completed: true,
          createdAt: now.subtract(const Duration(days: 2)),
          updatedAt: now.subtract(const Duration(days: 1)),
        ),
        Todo(
          id: 2,
          title: 'Build the Relic adapter',
          completed: false,
          createdAt: now.subtract(const Duration(days: 1)),
          updatedAt: now.subtract(const Duration(days: 1)),
        ),
      ],
    );
  }

  /// Lists todos, optionally filtered by completion state and limited.
  List<Todo> list({bool? completed, int? limit}) {
    var result = _todos.values.where(
      (todo) => completed == null || todo.completed == completed,
    );
    if (limit != null && limit >= 0) {
      result = result.take(limit);
    }
    return result.toList()..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  /// Gets one todo by id.
  Todo? get(int id) => _todos[id];

  /// Creates a todo.
  Todo create({required String title, String? description}) {
    final now = DateTime.now().toUtc();
    final todo = Todo(
      id: _nextId++,
      title: title,
      description: description,
      completed: false,
      createdAt: now,
      updatedAt: now,
    );
    _todos[todo.id] = todo;
    return todo;
  }

  /// Updates a todo, returning `null` when it does not exist.
  Todo? update(int id, {String? title, String? description, bool? completed}) {
    final existing = _todos[id];
    if (existing == null) return null;
    final updated = Todo(
      id: existing.id,
      title: title ?? existing.title,
      description: description ?? existing.description,
      completed: completed ?? existing.completed,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now().toUtc(),
    );
    _todos[id] = updated;
    return updated;
  }

  /// Deletes a todo, returning whether it existed.
  bool delete(int id) => _todos.remove(id) != null;
}
