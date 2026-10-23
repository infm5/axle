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

/// An error with a user-facing message and an exit code.
class AxleException implements Exception {
  /// Creates an error.
  const AxleException(this.message, {this.exitCode = AxleExitCode.software});

  /// The message written to `stderr`.
  final String message;

  /// The process exit code associated with the error.
  final int exitCode;

  @override
  String toString() => message;
}
