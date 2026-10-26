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
    this.cookieParams = const [],
    this.body,
    this.bodies = const [],
    this.responses = const [],
    this.security,
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

  /// Cookie parameters accepted by the operation.
  final List<ApiCookieParam> cookieParams;

  /// The request body accepted by the operation.
  final ApiBody? body;

  /// More request bodies, for media types that carry a different schema.
  ///
  /// Use [body] when every media type shares one schema. Add entries here when,
  /// for example, a `PATCH` accepts `application/merge-patch+json` with one
  /// schema and `application/json-patch+json` with another. [body] and these
  /// are merged into one request body; a media type may appear only once.
  final List<ApiBody> bodies;

  /// The responses returned by the operation.
  ///
  /// When this list is empty, the generator emits a `200 OK` response without a
  /// body. Several responses may share a status when their media types differ:
  /// they are merged into one response with one schema per media type.
  final List<ApiResponse> responses;

  /// Security requirements for the operation.
  ///
  /// `null` inherits the document default; an empty list makes the operation
  /// public. Multiple requirements are alternatives (OR); multiple schemes in
  /// one requirement must all be satisfied (AND).
  final List<ApiSecurityRequirement>? security;

  /// Whether the generator should ignore this annotation.
  final bool ignore;
}

/// How a parameter value is serialized in the URL or headers.
///
/// Each style is valid for specific locations: `matrix`, `label` and `simple`
/// for path parameters, `simple` for headers, `form`, `spaceDelimited`,
/// `pipeDelimited` and `deepObject` for query parameters, and `form` for
/// cookies.
enum ApiParameterStyle {
  /// Semicolon-prefixed values (`;id=5`). Path parameters.
  matrix,

  /// Dot-prefixed values (`.5`). Path parameters.
  label,

  /// `key=value` pairs; arrays repeat the key when exploded. Query and cookie
  /// parameters.
  form,

  /// Comma-separated values. Path and header parameters.
  simple,

  /// Space-separated array values. Query parameters.
  spaceDelimited,

  /// Pipe-separated array values. Query parameters.
  pipeDelimited,

  /// Nested object values (`filter[a]=1`). Query parameters.
  deepObject,
}

/// One named example value.
///
/// Use [ApiExample.new] for an inline value, or [ApiExample.external] to point
/// at a document that holds it.
class ApiExample {
  /// Creates an example with an inline [value].
  const ApiExample(this.value, {this.summary, this.description})
    : externalValue = null;

  /// Creates an example whose value lives at [url].
  const ApiExample.external(String url, {this.summary, this.description})
    : externalValue = url,
      value = null;

  /// The example value. Must be a compile-time constant.
  final Object? value;

  /// A URL of a document that contains the example value.
  final String? externalValue;

  /// A short description of the example.
  final String? summary;

  /// A longer description of the example.
  final String? description;
}

/// Describes a path parameter.
class ApiPathParam {
  /// Creates a path parameter annotation.
  const ApiPathParam(
    this.name, {
    required this.type,
    this.description,
    this.example,
    this.examples = const {},
    this.style,
    this.explode,
    this.format,
    this.enumValues = const [],
    this.minimum,
    this.maximum,
    this.minLength,
    this.maxLength,
    this.pattern,
  });

  /// The parameter name, without braces or a leading colon.
  final String name;

  /// The Dart type used to build the JSON Schema.
  final Type type;

  /// A description of the parameter.
  final String? description;

  /// An example value.
  final Object? example;

  /// The JSON Schema format.
  final String? format;

  /// The allowed values, when this is an enum.
  final List<Object?> enumValues;

  /// The inclusive minimum for numeric values.
  final num? minimum;

  /// The inclusive maximum for numeric values.
  final num? maximum;

  /// The minimum string length.
  final int? minLength;

  /// The maximum string length.
  final int? maxLength;

  /// A regular expression the value must match.
  final String? pattern;

  /// Named example values.
  ///
  /// Use either `example` or `examples`, not both.
  final Map<String, ApiExample> examples;

  /// How the value is serialized. Defaults to the OpenAPI default for the
  /// parameter location.
  final ApiParameterStyle? style;

  /// Whether array and object values produce one parameter per item.
  ///
  /// Defaults to `true` for the `form` style and `false` otherwise.
  final bool? explode;
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
    this.examples = const {},
    this.style,
    this.explode,
    this.defaultValue,
    this.format,
    this.enumValues = const [],
    this.minimum,
    this.maximum,
    this.minLength,
    this.maxLength,
    this.pattern,
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

  /// The JSON Schema format.
  final String? format;

  /// The allowed values, when this is an enum.
  final List<Object?> enumValues;

  /// The inclusive minimum for numeric values.
  final num? minimum;

  /// The inclusive maximum for numeric values.
  final num? maximum;

  /// The minimum string length.
  final int? minLength;

  /// The maximum string length.
  final int? maxLength;

  /// A regular expression the value must match.
  final String? pattern;

  /// Named example values.
  ///
  /// Use either `example` or `examples`, not both.
  final Map<String, ApiExample> examples;

  /// How the value is serialized. Defaults to the OpenAPI default for the
  /// parameter location.
  final ApiParameterStyle? style;

  /// Whether array and object values produce one parameter per item.
  ///
  /// Defaults to `true` for the `form` style and `false` otherwise.
  final bool? explode;
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
    this.examples = const {},
    this.style,
    this.explode,
    this.format,
    this.enumValues = const [],
    this.minimum,
    this.maximum,
    this.minLength,
    this.maxLength,
    this.pattern,
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

  /// The JSON Schema format.
  final String? format;

  /// The allowed values, when this is an enum.
  final List<Object?> enumValues;

  /// The inclusive minimum for numeric values.
  final num? minimum;

  /// The inclusive maximum for numeric values.
  final num? maximum;

  /// The minimum string length.
  final int? minLength;

  /// The maximum string length.
  final int? maxLength;

  /// A regular expression the value must match.
  final String? pattern;

  /// Named example values.
  ///
  /// Use either `example` or `examples`, not both.
  final Map<String, ApiExample> examples;

  /// How the value is serialized. Defaults to the OpenAPI default for the
  /// parameter location.
  final ApiParameterStyle? style;

  /// Whether array and object values produce one parameter per item.
  ///
  /// Defaults to `true` for the `form` style and `false` otherwise.
  final bool? explode;
}

/// Describes a cookie parameter.
class ApiCookieParam {
  /// Creates a cookie parameter annotation.
  const ApiCookieParam(
    this.name, {
    required this.type,
    this.required = false,
    this.description,
    this.example,
    this.examples = const {},
    this.style,
    this.explode,
    this.format,
    this.enumValues = const [],
    this.minimum,
    this.maximum,
    this.minLength,
    this.maxLength,
    this.pattern,
  });

  /// The cookie name.
  final String name;

  /// The Dart type used to build the JSON Schema.
  final Type type;

  /// Whether the cookie is required.
  final bool required;

  /// A description of the cookie.
  final String? description;

  /// An example value.
  final Object? example;

  /// The JSON Schema format.
  final String? format;

  /// The allowed values, when this is an enum.
  final List<Object?> enumValues;

  /// The inclusive minimum for numeric values.
  final num? minimum;

  /// The inclusive maximum for numeric values.
  final num? maximum;

  /// The minimum string length.
  final int? minLength;

  /// The maximum string length.
  final int? maxLength;

  /// A regular expression the value must match.
  final String? pattern;

  /// Named example values.
  ///
  /// Use either `example` or `examples`, not both.
  final Map<String, ApiExample> examples;

  /// How the value is serialized. Defaults to the OpenAPI default for the
  /// parameter location.
  final ApiParameterStyle? style;

  /// Whether array and object values produce one parameter per item.
  ///
  /// Defaults to `true` for the `form` style and `false` otherwise.
  final bool? explode;
}

/// Describes a request body.
class ApiBody {
  /// Creates a request body annotation.
  const ApiBody(
    this.type, {
    this.description,
    this.required = true,
    this.example,
    this.examples = const {},
    this.contentTypes = const ['application/json'],
  });

  /// The Dart type used to build the JSON Schema.
  final Type type;

  /// A description of the body.
  final String? description;

  /// Whether the body is required.
  final bool required;

  /// An example value.
  final Object? example;

  /// The media types accepted by the operation.
  final List<String> contentTypes;

  /// Named example bodies.
  ///
  /// Use either [example] or [examples], not both.
  final Map<String, ApiExample> examples;
}

/// Describes one response header.
class ApiResponseHeader {
  /// Creates a response header annotation.
  const ApiResponseHeader(
    this.name, {
    required this.type,
    this.description,
    this.example,
    this.required = false,
    this.deprecated = false,
  });

  /// The header name.
  final String name;

  /// The Dart type used to build the JSON Schema.
  final Type type;

  /// A description of the header.
  final String? description;

  /// An example value.
  final Object? example;

  /// Whether the header is required.
  final bool required;

  /// Whether the header is deprecated.
  final bool deprecated;
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
    this.examples = const {},
    this.headers = const [],
    this.contentTypes = const ['application/json'],
  }) : key = null;

  /// Creates a `200 OK` response.
  const ApiResponse.ok([Type? type, String description = 'OK', Object? example])
    : this(status: 200, type: type, description: description, example: example);

  /// Creates a `201 Created` response.
  const ApiResponse.created([
    Type? type,
    String description = 'Created',
    Object? example,
  ]) : this(
         status: 201,
         type: type,
         description: description,
         example: example,
       );

  /// Creates a `204 No Content` response.
  const ApiResponse.noContent([String description = 'No Content'])
    : this(status: 204, description: description);

  /// Creates a `400 Bad Request` response.
  const ApiResponse.badRequest([
    Type? type,
    String description = 'Bad Request',
    Object? example,
  ]) : this(
         status: 400,
         type: type,
         description: description,
         example: example,
       );

  /// Creates a `401 Unauthorized` response.
  const ApiResponse.unauthorized([
    Type? type,
    String description = 'Unauthorized',
    Object? example,
  ]) : this(
         status: 401,
         type: type,
         description: description,
         example: example,
       );

  /// Creates a `403 Forbidden` response.
  const ApiResponse.forbidden([
    Type? type,
    String description = 'Forbidden',
    Object? example,
  ]) : this(
         status: 403,
         type: type,
         description: description,
         example: example,
       );

  /// Creates a `404 Not Found` response.
  const ApiResponse.notFound([
    Type? type,
    String description = 'Not Found',
    Object? example,
  ]) : this(
         status: 404,
         type: type,
         description: description,
         example: example,
       );

  /// Creates a `409 Conflict` response.
  const ApiResponse.conflict([
    Type? type,
    String description = 'Conflict',
    Object? example,
  ]) : this(
         status: 409,
         type: type,
         description: description,
         example: example,
       );

  /// Creates a `422 Unprocessable Entity` response.
  const ApiResponse.unprocessableEntity([
    Type? type,
    String description = 'Unprocessable Entity',
    Object? example,
  ]) : this(
         status: 422,
         type: type,
         description: description,
         example: example,
       );

  /// Creates a `429 Too Many Requests` response.
  const ApiResponse.tooManyRequests([
    Type? type,
    String description = 'Too Many Requests',
    Object? example,
  ]) : this(
         status: 429,
         type: type,
         description: description,
         example: example,
       );

  /// Creates a `500 Internal Server Error` response.
  const ApiResponse.internalServerError([
    Type? type,
    String description = 'Internal Server Error',
    Object? example,
  ]) : this(
         status: 500,
         type: type,
         description: description,
         example: example,
       );

  /// Creates the `default` response, which covers every status code that no
  /// other response declares.
  ///
  /// It takes named options like the main constructor, so it can carry a
  /// different media type, for example `application/problem+json`.
  const ApiResponse.defaultResponse({
    this.type,
    this.description = 'Unexpected error',
    this.nullable = false,
    this.example,
    this.examples = const {},
    this.headers = const [],
    this.contentTypes = const ['application/json'],
  }) : status = 0,
       key = 'default';

  /// Creates a response for a whole class of status codes.
  ///
  /// [hundreds] is the first digit, from 1 to 5: `ApiResponse.range(4)` is the
  /// `4XX` response. An exact status code declared on the same operation takes
  /// precedence over the range. The other options are named, like the main
  /// constructor.
  const ApiResponse.range(
    int hundreds, {
    this.type,
    this.description = '',
    this.nullable = false,
    this.example,
    this.examples = const {},
    this.headers = const [],
    this.contentTypes = const ['application/json'],
  }) : assert(hundreds >= 1 && hundreds <= 5, 'hundreds must be 1 to 5'),
       status = hundreds * 100,
       key = '${hundreds}XX';

  /// The HTTP status code, or the first status of a [range].
  ///
  /// It is `0` for the `default` response.
  final int status;

  /// The response key when it is not a plain status code: `default` or a range
  /// such as `4XX`. `null` for an exact status code.
  final String? key;

  /// The Dart type of the response body, or `null` when there is no body.
  final Type? type;

  /// A description of the response.
  final String description;

  /// Whether the response body may be `null`.
  final bool nullable;

  /// An example response body.
  ///
  /// Use either [example] or [examples], not both.
  final Object? example;

  /// Named example response bodies.
  final Map<String, ApiExample> examples;

  /// Response headers.
  final List<ApiResponseHeader> headers;

  /// The media types produced by the response.
  final List<String> contentTypes;
}

/// Describes one security requirement.
///
/// Multiple requirements on an operation are alternatives (OR). All schemes in
/// one requirement must be satisfied (AND).
class ApiSecurityRequirement {
  /// Creates a security requirement.
  const ApiSecurityRequirement(this.schemes, {this.scopes = const {}});

  /// Scheme names that must all be satisfied.
  final List<String> schemes;

  /// OAuth2 scopes keyed by scheme name.
  final Map<String, List<String>> scopes;
}

/// Describes a discriminator for a `oneOf` schema.
class ApiDiscriminator {
  /// Creates a discriminator annotation.
  const ApiDiscriminator(this.propertyName, {this.mapping = const {}});

  /// The property whose value selects the schema.
  final String propertyName;

  /// Optional values mapped to schema names.
  final Map<String, String> mapping;
}

/// Marks a class as an OpenAPI schema.
///
/// Referenced classes are discovered automatically. Apply this annotation when
/// a class should also be included in `components.schemas` even if no operation
/// references it, or when its schema name or description needs an override.
class ApiSchema {
  /// Creates a schema annotation.
  const ApiSchema({
    this.name,
    this.description,
    this.oneOf = const [],
    this.allOf = const [],
    this.anyOf = const [],
    this.discriminator,
    this.ignore = false,
  });

  /// An optional override for the schema name.
  final String? name;

  /// An optional description of the schema.
  final String? description;

  /// Concrete types that satisfy this schema.
  ///
  /// When non-empty, the generated schema is a `oneOf` over the referenced
  /// component schemas instead of a component built from this class's fields.
  final List<Type> oneOf;

  /// Types whose schemas this schema extends.
  ///
  /// When non-empty, the generated schema is an `allOf` over the referenced
  /// component schemas. Fields the class declares itself (not inherited ones)
  /// are added as a final inline object, which is the usual way to model
  /// `class Child extends Base` in OpenAPI. Set only one of [oneOf], [allOf],
  /// and [anyOf].
  final List<Type> allOf;

  /// Concrete types of which at least one satisfies this schema.
  ///
  /// Behaves like [oneOf] but emits `anyOf`.
  final List<Type> anyOf;

  /// The discriminator used with [oneOf] or [anyOf].
  final ApiDiscriminator? discriminator;

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
    this.type,
    this.description,
    this.example,
    this.required,
    this.format,
    this.enumValues = const [],
    this.minimum,
    this.maximum,
    this.minLength,
    this.maxLength,
    this.pattern,
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

  /// The JSON Schema format.
  final String? format;

  /// The allowed values, when this is an enum.
  final List<Object?> enumValues;

  /// The inclusive minimum for numeric values.
  final num? minimum;

  /// The inclusive maximum for numeric values.
  final num? maximum;

  /// The minimum string length.
  final int? minLength;

  /// The maximum string length.
  final int? maxLength;

  /// A regular expression the value must match.
  final String? pattern;

  /// Whether the generator should skip this field.
  final bool ignore;

  /// The type that describes this property in JSON.
  ///
  /// Use it when a custom converter changes the wire format, for example a
  /// `DateTime` field that is serialized as an `int`. When omitted, axle uses
  /// the converter's JSON type if it can find one, and the field's Dart type
  /// otherwise. Nullability still comes from the field.
  final Type? type;
}
