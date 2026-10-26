/// Annotation constants reused across route modules.
///
/// Annotation arguments are compile-time constants, so a `const` list can be
/// spread into any `responses:` list.
library;

import 'package:axle_shelf/axle_shelf.dart';

import '../http.dart';
import '../models/common.dart';

/// The `Vary` response header.
const varyHeader = ApiResponseHeader(
  'Vary',
  type: String,
  description: 'The request headers the response depends on.',
  example: 'Accept',
);

/// A problem response for [status], sent as `application/problem+json`.
///
/// Used by the module-level lists below.
const badRequest = ApiResponse(
  status: 400,
  type: Problem,
  description: 'The request could not be understood.',
  contentTypes: [problemJson],
);

/// Returned when the request is well formed but cannot be processed.
const unprocessable = ApiResponse(
  status: 422,
  type: Problem,
  description: 'The request was understood but could not be processed.',
  contentTypes: [problemJson],
);

/// Returned when a route cannot produce any `Accept`ed media type.
const notAcceptable = ApiResponse(
  status: 406,
  type: Problem,
  description: 'None of the requested media types can be produced.',
  contentTypes: [problemJson],
);

/// Returned when the request body has a media type the route does not read.
const unsupportedMediaType = ApiResponse(
  status: 415,
  type: Problem,
  description: 'The request body media type is not supported.',
  contentTypes: [problemJson],
);

/// Appended to routes so every undeclared status is still described.
///
/// `4XX` and `5XX` catch the rest of their classes, and `default` catches
/// anything else. An exact status declared on a route wins over these.
const catchAllErrors = [
  ApiResponse.range(
    4,
    type: Problem,
    description: 'Any other client error.',
    contentTypes: [problemJson],
  ),
  ApiResponse.range(
    5,
    type: Problem,
    description: 'Any server error.',
    contentTypes: [problemJson],
  ),
  ApiResponse.defaultResponse(
    type: Problem,
    description: 'Anything else.',
    contentTypes: [problemJson],
  ),
];

/// Returned by every protected route.
const authErrors = [
  ApiResponse(
    status: 401,
    type: Problem,
    description: 'Credentials are missing or wrong.',
    contentTypes: [problemJson],
    headers: [
      ApiResponseHeader(
        'WWW-Authenticate',
        type: String,
        description: 'How to authenticate.',
        example: 'Bearer realm="showcase"',
      ),
    ],
  ),
  ApiResponse(
    status: 403,
    type: Problem,
    description: 'The credentials are valid but not allowed here.',
    contentTypes: [problemJson],
  ),
];
