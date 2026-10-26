/// The OpenAPI 3.1 document model used by axle.
library;

import 'dart:convert';

import 'schema.dart';
import 'security.dart';

/// An OpenAPI 3.1 document.
class OpenApiDocument {
  /// Creates an OpenAPI document.
  const OpenApiDocument({
    this.openApi = '3.1.0',
    required this.info,
    this.servers = const [],
    this.paths = const {},
    this.components = const OpenApiComponents(),
    this.security = const [],
    this.tags = const [],
    this.externalDocs,
  });

  /// The OpenAPI specification version.
  final String openApi;

  /// Metadata about the API.
  final OpenApiInfo info;

  /// The servers that host the API.
  final List<OpenApiServer> servers;

  /// The operations keyed by path.
  final Map<String, OpenApiPathItem> paths;

  /// Reusable components.
  final OpenApiComponents components;

  /// Security requirements applied to all operations by default.
  ///
  /// An empty list omits the document-level `security` member. Individual
  /// operations can override it, including with an empty list for a public
  /// operation.
  final List<OpenApiSecurityRequirement> security;

  /// Global tag metadata.
  final List<OpenApiTag> tags;

  /// Link to external documentation for the API.
  final OpenApiExternalDocs? externalDocs;

  /// Serializes the document to a JSON-compatible map.
  Map<String, Object?> toJson() {
    final result = <String, Object?>{
      'openapi': openApi,
      'info': info.toJson(),
      if (servers.isNotEmpty)
        'servers': [for (final server in servers) server.toJson()],
      if (tags.isNotEmpty) 'tags': [for (final tag in tags) tag.toJson()],
      if (externalDocs != null) 'externalDocs': externalDocs!.toJson(),
      if (security.isNotEmpty)
        'security': [for (final requirement in security) requirement.toJson()],
      'paths': {
        for (final entry in paths.entries) entry.key: entry.value.toJson(),
      },
    };
    if (components.schemas.isNotEmpty ||
        components.securitySchemes.isNotEmpty) {
      result['components'] = components.toJson();
    }
    return result;
  }

  /// Serializes the document to a JSON string.
  String toJsonString({bool pretty = true}) {
    final encoder =
        pretty ? const JsonEncoder.withIndent('  ') : const JsonEncoder();
    return encoder.convert(toJson());
  }
}

/// A link to external documentation.
class OpenApiExternalDocs {
  /// Creates an external docs link.
  const OpenApiExternalDocs({required this.url, this.description});

  /// The documentation URL.
  final String url;

  /// A description of the link.
  final String? description;

  /// Serializes the link to a JSON-compatible map.
  Map<String, Object?> toJson() => {
    'url': url,
    if (description != null) 'description': description,
  };
}

/// Metadata for a documentation tag.
class OpenApiTag {
  /// Creates a tag.
  const OpenApiTag({required this.name, this.description, this.externalDocs});

  /// The tag name.
  final String name;

  /// A description of the tag.
  final String? description;

  /// A link to external documentation for the tag.
  final OpenApiExternalDocs? externalDocs;

  /// Serializes the tag to a JSON-compatible map.
  Map<String, Object?> toJson() => {
    'name': name,
    if (description != null) 'description': description,
    if (externalDocs != null) 'externalDocs': externalDocs!.toJson(),
  };
}

/// Metadata about the API.
class OpenApiInfo {
  /// Creates API metadata.
  const OpenApiInfo({
    required this.title,
    required this.version,
    this.description,
    this.termsOfService,
    this.contact,
    this.license,
  });

  /// The title of the API.
  final String title;

  /// The version of the API.
  final String version;

  /// A description of the API.
  final String? description;

  /// A URL to the API's terms of service.
  final String? termsOfService;

  /// Contact information for the API.
  final OpenApiContact? contact;

  /// License information for the API.
  final OpenApiLicense? license;

  /// Serializes the metadata to a JSON-compatible map.
  Map<String, Object?> toJson() => {
    'title': title,
    'version': version,
    if (description != null) 'description': description,
    if (termsOfService != null) 'termsOfService': termsOfService,
    if (contact != null) 'contact': contact!.toJson(),
    if (license != null) 'license': license!.toJson(),
  };
}

/// Contact information for an API.
class OpenApiContact {
  /// Creates contact information.
  const OpenApiContact({this.name, this.url, this.email});

  /// The name of the contact.
  final String? name;

  /// The URL of the contact.
  final String? url;

  /// The email address of the contact.
  final String? email;

  /// Serializes the contact information to a JSON-compatible map.
  Map<String, Object?> toJson() => {
    if (name != null) 'name': name,
    if (url != null) 'url': url,
    if (email != null) 'email': email,
  };
}

/// License information for an API.
class OpenApiLicense {
  /// Creates license information.
  const OpenApiLicense({required this.name, this.identifier, this.url});

  /// The license name.
  final String name;

  /// The SPDX license identifier, when known.
  final String? identifier;

  /// The URL of the license text.
  final String? url;

  /// Serializes the license information to a JSON-compatible map.
  Map<String, Object?> toJson() => {
    'name': name,
    if (identifier != null) 'identifier': identifier,
    if (url != null) 'url': url,
  };
}

/// A server that hosts the API.
class OpenApiServer {
  /// Creates a server entry.
  const OpenApiServer({required this.url, this.description});

  /// The base URL of the server.
  final String url;

  /// A description of the server.
  final String? description;

  /// Serializes the server to a JSON-compatible map.
  Map<String, Object?> toJson() => {
    'url': url,
    if (description != null) 'description': description,
  };
}

/// Reusable components referenced by the document.
class OpenApiComponents {
  /// Creates a component collection.
  const OpenApiComponents({
    this.schemas = const {},
    this.securitySchemes = const {},
  });

  /// The reusable schemas keyed by component name.
  final Map<String, OpenApiSchema> schemas;

  /// The reusable security schemes keyed by scheme name.
  final Map<String, OpenApiSecurityScheme> securitySchemes;

  /// Serializes the components to a JSON-compatible map.
  Map<String, Object?> toJson() => {
    if (schemas.isNotEmpty)
      'schemas': {
        for (final entry in schemas.entries) entry.key: entry.value.toJson(),
      },
    if (securitySchemes.isNotEmpty)
      'securitySchemes': {
        for (final entry in securitySchemes.entries)
          entry.key: entry.value.toJson(),
      },
  };
}

/// The operations available at one path.
class OpenApiPathItem {
  /// Creates a path item.
  const OpenApiPathItem(this.operations);

  /// The operations keyed by lowercase HTTP method.
  final Map<String, OpenApiOperation> operations;

  /// The order in which methods are serialized.
  static const _methodOrder = [
    'get',
    'put',
    'post',
    'delete',
    'options',
    'head',
    'patch',
    'trace',
  ];

  /// Serializes the path item to a JSON-compatible map.
  Map<String, Object?> toJson() {
    final methods =
        operations.keys.toList()..sort((a, b) {
          final aIndex = _methodOrder.indexOf(a);
          final bIndex = _methodOrder.indexOf(b);
          return (aIndex == -1 ? _methodOrder.length : aIndex).compareTo(
            bIndex == -1 ? _methodOrder.length : bIndex,
          );
        });
    return {for (final method in methods) method: operations[method]!.toJson()};
  }
}

/// One HTTP operation.
class OpenApiOperation {
  /// Creates an operation.
  const OpenApiOperation({
    required this.responses,
    this.operationId,
    this.summary,
    this.description,
    this.tags = const [],
    this.deprecated = false,
    this.parameters = const [],
    this.requestBody,
    this.security,
  });

  /// A stable identifier for the operation.
  final String? operationId;

  /// A short summary of the operation.
  final String? summary;

  /// A longer description of the operation.
  final String? description;

  /// The tags used to group the operation.
  final List<String> tags;

  /// Whether the operation is deprecated.
  final bool deprecated;

  /// The parameters accepted by the operation.
  final List<OpenApiParameter> parameters;

  /// The request body accepted by the operation.
  final OpenApiRequestBody? requestBody;

  /// Security requirements overriding the document default.
  ///
  /// `null` inherits the document default; an empty list makes the operation
  /// public.
  final List<OpenApiSecurityRequirement>? security;

  /// The responses keyed by status code.
  final Map<String, OpenApiResponse> responses;

  /// Serializes the operation to a JSON-compatible map.
  Map<String, Object?> toJson() => {
    if (tags.isNotEmpty) 'tags': tags,
    if (summary != null) 'summary': summary,
    if (description != null) 'description': description,
    if (operationId != null) 'operationId': operationId,
    if (parameters.isNotEmpty)
      'parameters': [for (final parameter in parameters) parameter.toJson()],
    if (requestBody != null) 'requestBody': requestBody!.toJson(),
    if (security != null)
      'security': [for (final requirement in security!) requirement.toJson()],
    'responses': {
      for (final entry in responses.entries) entry.key: entry.value.toJson(),
    },
    if (deprecated) 'deprecated': true,
  };
}

/// Where an operation parameter is located.
enum OpenApiParameterLocation {
  /// A path parameter.
  path,

  /// A query parameter.
  query,

  /// A header parameter.
  header,

  /// A cookie parameter.
  cookie,
}

/// One operation parameter.
class OpenApiParameter {
  /// Creates a parameter.
  const OpenApiParameter({
    required this.name,
    required this.location,
    required this.schema,
    this.required = false,
    this.description,
    this.example,
    this.examples = const {},
    this.style,
    this.explode,
    this.deprecated = false,
  });

  /// The parameter name.
  final String name;

  /// Where the parameter is located.
  final OpenApiParameterLocation location;

  /// The parameter schema.
  final OpenApiSchema schema;

  /// Whether the parameter is required.
  final bool required;

  /// A description of the parameter.
  final String? description;

  /// An example value. Mutually exclusive with [examples].
  final Object? example;

  /// Named example values, keyed by name. Mutually exclusive with [example].
  final Map<String, OpenApiExample> examples;

  /// The serialization style, or `null` for the default of the location.
  final String? style;

  /// Whether array and object values produce one parameter per item, or `null`
  /// for the default of the style.
  final bool? explode;

  /// Whether the parameter is deprecated.
  final bool deprecated;

  /// Serializes the parameter to a JSON-compatible map.
  Map<String, Object?> toJson() => {
    'name': name,
    'in': location.name,
    if (description != null) 'description': description,
    'required': required,
    if (deprecated) 'deprecated': true,
    if (style != null) 'style': style,
    if (explode != null) 'explode': explode,
    'schema': schema.toJson(),
    if (example != null) 'example': example,
    if (examples.isNotEmpty)
      'examples': {
        for (final entry in examples.entries) entry.key: entry.value.toJson(),
      },
  };
}

/// The request body of an operation.
class OpenApiRequestBody {
  /// Creates a request body.
  ///
  /// Provide either [content] or the [schema] convenience field. The latter
  /// emits a single `application/json` media type.
  const OpenApiRequestBody({
    this.schema,
    this.description,
    this.required = true,
    this.example,
    this.content = const {},
  });

  /// The body schema for a single JSON media type.
  final OpenApiSchema? schema;

  /// A description of the body.
  final String? description;

  /// Whether the body is required.
  final bool required;

  /// An example body for the single JSON media type.
  final Object? example;

  /// The media types accepted by the operation, keyed by media type.
  final Map<String, OpenApiMediaType> content;

  /// Serializes the body to a JSON-compatible map.
  Map<String, Object?> toJson() {
    final mediaTypes =
        content.isNotEmpty
            ? content
            : schema == null
            ? const <String, OpenApiMediaType>{}
            : {
              'application/json': OpenApiMediaType(
                schema: schema!,
                example: example,
              ),
            };
    return {
      if (description != null) 'description': description,
      'required': required,
      if (mediaTypes.isNotEmpty)
        'content': {
          for (final entry in mediaTypes.entries)
            entry.key: entry.value.toJson(),
        },
    };
  }
}

/// One HTTP response header.
class OpenApiHeader {
  /// Creates a response header.
  const OpenApiHeader({
    required this.schema,
    this.description,
    this.example,
    this.required = false,
    this.deprecated = false,
  });

  /// The header value schema.
  final OpenApiSchema schema;

  /// A description of the header.
  final String? description;

  /// An example value.
  final Object? example;

  /// Whether the header is required.
  final bool required;

  /// Whether the header is deprecated.
  final bool deprecated;

  /// Serializes the header to a JSON-compatible map.
  Map<String, Object?> toJson() => {
    if (description != null) 'description': description,
    if (required) 'required': true,
    if (deprecated) 'deprecated': true,
    'schema': schema.toJson(),
    if (example != null) 'example': example,
  };
}

/// One response returned by an operation.
class OpenApiResponse {
  /// Creates a response.
  ///
  /// Provide either [content] or the [schema] convenience field. The latter
  /// emits a single `application/json` media type.
  const OpenApiResponse({
    required this.description,
    this.schema,
    this.example,
    this.headers = const {},
    this.content = const {},
  });

  /// A description of the response.
  final String description;

  /// The response body schema for a single JSON media type.
  final OpenApiSchema? schema;

  /// An example response body for the single JSON media type.
  final Object? example;

  /// Response headers keyed by header name.
  final Map<String, OpenApiHeader> headers;

  /// Response media types keyed by media type.
  final Map<String, OpenApiMediaType> content;

  /// Serializes the response to a JSON-compatible map.
  Map<String, Object?> toJson() {
    final mediaTypes =
        content.isNotEmpty
            ? content
            : schema == null
            ? const <String, OpenApiMediaType>{}
            : {
              'application/json': OpenApiMediaType(
                schema: schema!,
                example: example,
              ),
            };
    return {
      'description': description,
      if (headers.isNotEmpty)
        'headers': {
          for (final entry in headers.entries) entry.key: entry.value.toJson(),
        },
      if (mediaTypes.isNotEmpty)
        'content': {
          for (final entry in mediaTypes.entries)
            entry.key: entry.value.toJson(),
        },
    };
  }
}

/// One named example value.
class OpenApiExample {
  /// Creates an example with an inline [value].
  const OpenApiExample({this.value, this.summary, this.description})
    : externalValue = null;

  /// Creates an example whose value lives at [url].
  const OpenApiExample.external(String url, {this.summary, this.description})
    : externalValue = url,
      value = null;

  /// The example value, when it is inline.
  final Object? value;

  /// A URL of a document that holds the example value.
  final String? externalValue;

  /// A short description of the example.
  final String? summary;

  /// A longer description of the example.
  final String? description;

  /// Serializes the example to a JSON-compatible map.
  Map<String, Object?> toJson() => {
    if (summary != null) 'summary': summary,
    if (description != null) 'description': description,
    if (externalValue != null)
      'externalValue': externalValue
    else
      'value': value,
  };
}

/// The media type wrapper used for request and response bodies.
class OpenApiMediaType {
  /// Creates a media type entry.
  const OpenApiMediaType({
    required this.schema,
    this.example,
    this.examples = const {},
  });

  /// The schema for this media type.
  final OpenApiSchema schema;

  /// An example value. Mutually exclusive with [examples].
  final Object? example;

  /// Named example values, keyed by name. Mutually exclusive with [example].
  final Map<String, OpenApiExample> examples;

  /// Serializes the media type to a JSON-compatible map.
  Map<String, Object?> toJson() => {
    'schema': schema.toJson(),
    if (example != null) 'example': example,
    if (examples.isNotEmpty)
      'examples': {
        for (final entry in examples.entries) entry.key: entry.value.toJson(),
      },
  };
}
