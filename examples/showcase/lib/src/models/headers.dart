/// Models for the header routes.
library;

import 'package:axle_shelf/axle_shelf.dart';

import 'common.dart';

/// What the server understood from the request headers.
@ApiSchema(description: 'The request headers, parsed into typed values.')
class HeaderEcho implements Jsonable {
  /// Creates an echo.
  const HeaderEcho({
    required this.traceId,
    required this.featureFlags,
    required this.retryCount,
    required this.clientTime,
    required this.debug,
    required this.weights,
  });

  /// From `X-Trace-Id`.
  final String? traceId;

  /// From `X-Feature-Flags`, split on commas.
  final List<String> featureFlags;

  /// From `X-Retry-Count`.
  final int? retryCount;

  /// From `X-Client-Time`.
  final DateTime? clientTime;

  /// From `X-Debug`.
  final bool debug;

  /// From `X-Weights`, split on commas.
  final List<double> weights;

  @override
  Map<String, Object?> toJson() => {
    'traceId': traceId,
    'featureFlags': featureFlags,
    'retryCount': retryCount,
    'clientTime': clientTime?.toIso8601String(),
    'debug': debug,
    'weights': weights,
  };
}
