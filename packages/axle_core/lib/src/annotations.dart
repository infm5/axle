/// Annotations used to describe HTTP operations and data models.
library;

/// HTTP methods supported by [ApiRoute].
enum ApiMethod {
  /// The `GET` method.
  get,

  /// The `POST` method.
  post,

  /// The `PUT` method.
  put,

  /// The `PATCH` method.
  patch,

  /// The `DELETE` method.
  delete,

  /// The `HEAD` method.
  head,

  /// The `OPTIONS` method.
  options,

  /// The `TRACE` method.
  trace,
}

/// Describes one HTTP operation.
///
/// Apply this annotation to a top-level handler function. The generator creates
/// one OpenAPI operation per annotation, so a handler can be annotated more than
/// once to document multiple methods. Set a unique `operationId` on each
/// annotation when you do.
///
/// ```dart
/// @ApiRoute(
///   method: ApiMethod.get,
///   path: '/users/:id',
///   pathParams: [ApiPathParam('id', type: int)],
///   responses: [ApiResponse.ok(UserDto)],
/// )
/// Future<Result> getUser(Request request) async { ... }
/// ```
class ApiRoute {
  /// Creates a route annotation.
  const ApiRoute({
    required this.method,
    required this.path,
    this.summary,
    this.description,
    this.operationId,
    this.tags = const [],
    this.deprecated = false,
    this.pathParams = const [],
    this.queryParams = const [],
    this.headerParams = const [],
    this.body,
    this.responses = const [],
    this.ignore = false,
  });

  /// The HTTP method of the operation.
  final ApiMethod method;

  /// The route path, using Relic syntax such as `/users/:id`.
  ///
  /// OpenAPI-style placeholders such as `/users/{id}` are also accepted.
  final String path;

  /// A short summary of the operation.
  final String? summary;

  /// A longer description of the operation.
  final String? description;

  /// A stable identifier for the operation.
  ///
  /// Defaults to the name of the annotated function.
  final String? operationId;

  /// The tags used to group the operation in documentation.
  final List<String> tags;

  /// Whether the operation is deprecated.
  final bool deprecated;

  /// Path parameters declared by the operation.
  final List<ApiPathParam> pathParams;

  /// Query parameters accepted by the operation.
  final List<ApiQueryParam> queryParams;

  /// Header parameters accepted by the operation.
  final List<ApiHeaderParam> headerParams;

  /// The request body accepted by the operation.
  final ApiBody? body;

  /// The responses returned by the operation.
  ///
  /// When this list is empty, the generator emits a `200 OK` response without a
  /// body.
  final List<ApiResponse> responses;

  /// Whether the generator should ignore this annotation.
  final bool ignore;
}

/// Describes a path parameter.
class ApiPathParam {
  /// Creates a path parameter annotation.
  const ApiPathParam(
    this.name, {
    required this.type,
    this.description,
    this.example,
  });

  /// The parameter name, without braces or a leading colon.
  final String name;

  /// The Dart type used to build the JSON Schema.
  final Type type;

  /// A description of the parameter.
  final String? description;

  /// An example value.
  final Object? example;
}

/// Describes a query parameter.
class ApiQueryParam {
  /// Creates a query parameter annotation.
  const ApiQueryParam(
    this.name, {
    required this.type,
    this.required = false,
    this.description,
    this.example,
    this.defaultValue,
  });

  /// The parameter name.
  final String name;

  /// The Dart type used to build the JSON Schema.
  final Type type;

  /// Whether the parameter is required.
  final bool required;

  /// A description of the parameter.
  final String? description;

  /// An example value.
  final Object? example;

  /// The default value used when the parameter is omitted.
  final Object? defaultValue;
}

/// Describes a header parameter.
class ApiHeaderParam {
  /// Creates a header parameter annotation.
  const ApiHeaderParam(
    this.name, {
    required this.type,
    this.required = false,
    this.description,
    this.example,
  });

  /// The header name.
  final String name;

  /// The Dart type used to build the JSON Schema.
  final Type type;

  /// Whether the header is required.
  final bool required;

  /// A description of the header.
  final String? description;

  /// An example value.
  final Object? example;
}

/// Describes a JSON request body.
class ApiBody {
  /// Creates a request body annotation.
  const ApiBody(
    this.type, {
    this.description,
    this.required = true,
    this.example,
  });

  /// The Dart type used to build the JSON Schema.
  final Type type;

  /// A description of the body.
  final String? description;

  /// Whether the body is required.
  final bool required;

  /// An example value.
  final Object? example;
}

/// Describes one response returned by an operation.
class ApiResponse {
  /// Creates a response annotation with an explicit status code.
  const ApiResponse({
    required this.status,
    this.type,
    this.description = '',
    this.nullable = false,
    this.example,
  });

  /// Creates a `200 OK` response.
  const ApiResponse.ok([this.type, this.description = 'OK', this.example])
    : status = 200,
      nullable = false;

  /// Creates a `201 Created` response.
  const ApiResponse.created([
    this.type,
    this.description = 'Created',
    this.example,
  ]) : status = 201,
       nullable = false;

  /// Creates a `204 No Content` response.
  const ApiResponse.noContent([this.description = 'No Content'])
    : status = 204,
      type = null,
      nullable = false,
      example = null;

  /// Creates a `400 Bad Request` response.
  const ApiResponse.badRequest([
    this.type,
    this.description = 'Bad Request',
    this.example,
  ]) : status = 400,
       nullable = false;

  /// Creates a `404 Not Found` response.
  const ApiResponse.notFound([
    this.type,
    this.description = 'Not Found',
    this.example,
  ]) : status = 404,
       nullable = false;

  /// Creates a `500 Internal Server Error` response.
  const ApiResponse.internalServerError([
    this.type,
    this.description = 'Internal Server Error',
    this.example,
  ]) : status = 500,
       nullable = false;

  /// The HTTP status code.
  final int status;

  /// The Dart type of the response body, or `null` when there is no body.
  final Type? type;

  /// A description of the response.
  final String description;

  /// Whether the response body may be `null`.
  final bool nullable;

  /// An example response body.
  final Object? example;
}

/// Marks a class as an OpenAPI schema.
///
/// Referenced classes are discovered automatically. Apply this annotation when
/// a class should also be included in `components.schemas` even if no operation
/// references it, or when its schema name or description needs an override.
class ApiSchema {
  /// Creates a schema annotation.
  const ApiSchema({this.name, this.description, this.ignore = false});

  /// An optional override for the schema name.
  final String? name;

  /// An optional description of the schema.
  final String? description;

  /// Whether the generator should skip auto-including the class.
  ///
  /// Referenced classes are still generated because the document needs them.
  final bool ignore;
}

/// Customizes how one field is represented in a generated schema.
class ApiProperty {
  /// Creates a property annotation.
  const ApiProperty({
    this.name,
    this.description,
    this.example,
    this.required,
    this.ignore = false,
  });

  /// An optional override for the JSON property name.
  ///
  /// When omitted, `JsonKey.name` is used, followed by the Dart field name.
  final String? name;

  /// A description of the property.
  final String? description;

  /// An example value.
  final Object? example;

  /// Whether the property is required.
  ///
  /// When omitted, non-nullable fields without a default value are required.
  final bool? required;

  /// Whether the generator should skip this field.
  final bool ignore;
}
