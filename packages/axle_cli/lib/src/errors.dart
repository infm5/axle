/// Errors and exit codes used by the axle CLI.
library;

/// Standard POSIX exit codes used by axle.
abstract final class AxleExitCode {
  /// The command completed successfully.
  static const success = 0;

  /// The command line was invalid.
  static const usage = 64;

  /// The input or generated data was invalid.
  static const data = 65;

  /// An unexpected internal error occurred.
  static const software = 70;

  /// The project configuration was invalid.
  static const config = 78;
}

/// A position in a Dart source file.
class SourceLocation {
  /// Creates a location. [line] and [column] are 1-based.
  const SourceLocation({
    required this.file,
    required this.line,
    required this.column,
  });

  /// The path of the source file.
  final String file;

  /// The 1-based line number.
  final int line;

  /// The 1-based column number.
  final int column;

  @override
  String toString() => '$file:$line:$column';
}

/// An error with a user-facing message and an exit code.
class AxleException implements Exception {
  /// Creates an error.
  const AxleException(
    this.message, {
    this.exitCode = AxleExitCode.software,
    this.location,
  });

  /// The message written to `stderr`.
  final String message;

  /// The process exit code associated with the error.
  final int exitCode;

  /// The Dart source position the error refers to, when known.
  final SourceLocation? location;

  /// The message prefixed with [location], like compiler diagnostics.
  ///
  /// Editors and terminals make `file:line:column:` prefixes clickable.
  String get formatted =>
      location == null ? message : '$location: error: $message';

  /// Returns a copy that points at [location] unless one is already set.
  AxleException withLocation(SourceLocation? location) {
    if (this.location != null || location == null) return this;
    return AxleException(message, exitCode: exitCode, location: location);
  }

  @override
  String toString() => message;
}

/// Several [AxleException]s collected during one generation run.
class AxleDiagnosticsException extends AxleException {
  /// Creates an error that reports every entry of [diagnostics].
  ///
  /// [diagnostics] must not be empty.
  AxleDiagnosticsException(List<AxleException> diagnostics)
    : diagnostics = List.unmodifiable(diagnostics),
      super(
        diagnostics.map((error) => error.message).join('\n'),
        exitCode: diagnostics.first.exitCode,
      );

  /// The collected errors, in the order they were found.
  final List<AxleException> diagnostics;

  @override
  String get formatted =>
      diagnostics.map((error) => error.formatted).join('\n');
}
