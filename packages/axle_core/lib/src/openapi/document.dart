/// The OpenAPI 3.1 document model used by axle.
library;

import 'dart:convert';

import 'schema.dart';

/// An OpenAPI 3.1 document.
class OpenApiDocument {
  /// Creates an OpenAPI document.
  const OpenApiDocument({
    this.openApi = '3.1.0',
    required this.info,
    this.servers = const [],
    this.paths = const {},
    this.components = const OpenApiComponents(),
  });

  /// The OpenAPI specification version.
  final String openApi;

  /// Metadata about the API.
  final OpenApiInfo info;

  /// The servers that host the API.
  final List<OpenApiServer> servers;

  /// The operations keyed by path.
  final Map<String, OpenApiPathItem> paths;

  /// Reusable component schemas.
  final OpenApiComponents components;

  /// Serializes the document to a JSON-compatible map.
  Map<String, Object?> toJson() {
    final result = <String, Object?>{
      'openapi': openApi,
      'info': info.toJson(),
      if (servers.isNotEmpty)
        'servers': [for (final server in servers) server.toJson()],
      'paths': {
        for (final entry in paths.entries) entry.key: entry.value.toJson(),
      },
    };
    if (components.schemas.isNotEmpty) {
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

/// Metadata about the API.
class OpenApiInfo {
  /// Creates API metadata.
  const OpenApiInfo({
    required this.title,
    required this.version,
    this.description,
    this.contact,
    this.license,
  });

  /// The title of the API.
  final String title;

  /// The version of the API.
  final String version;

  /// A description of the API.
  final String? description;

  /// Contact information for the API.
  final OpenApiContact? contact;

  /// License information for the API.
  final OpenApiLicense? license;

  /// Serializes the metadata to a JSON-compatible map.
  Map<String, Object?> toJson() => {
    'title': title,
    'version': version,
    if (description != null) 'description': description,
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
  const OpenApiComponents({this.schemas = const {}});

  /// The reusable schemas keyed by component name.
  final Map<String, OpenApiSchema> schemas;

  /// Serializes the components to a JSON-compatible map.
  Map<String, Object?> toJson() => {
    'schemas': {
      for (final entry in schemas.entries) entry.key: entry.value.toJson(),
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

  /// An example value.
  final Object? example;

  /// Whether the parameter is deprecated.
  final bool deprecated;

  /// Serializes the parameter to a JSON-compatible map.
  Map<String, Object?> toJson() => {
    'name': name,
    'in': location.name,
    if (description != null) 'description': description,
    'required': required,
    if (deprecated) 'deprecated': true,
    'schema': schema.toJson(),
    if (example != null) 'example': example,
  };
}

/// The request body of an operation.
class OpenApiRequestBody {
  /// Creates a request body.
  const OpenApiRequestBody({
    required this.schema,
    this.description,
    this.required = true,
    this.example,
  });

  /// The body schema.
  final OpenApiSchema schema;

  /// A description of the body.
  final String? description;

  /// Whether the body is required.
  final bool required;

  /// An example body.
  final Object? example;

  /// Serializes the body to a JSON-compatible map.
  Map<String, Object?> toJson() => {
    if (description != null) 'description': description,
    'required': required,
    'content': {
      'application/json':
          OpenApiMediaType(schema: schema, example: example).toJson(),
    },
  };
}

/// One response returned by an operation.
class OpenApiResponse {
  /// Creates a response.
  const OpenApiResponse({required this.description, this.schema, this.example});

  /// A description of the response.
  final String description;

  /// The response body schema, or `null` when there is no body.
  final OpenApiSchema? schema;

  /// An example response body.
  final Object? example;

  /// Serializes the response to a JSON-compatible map.
  Map<String, Object?> toJson() => {
    'description': description,
    if (schema != null)
      'content': {
        'application/json':
            OpenApiMediaType(schema: schema!, example: example).toJson(),
      },
  };
}

/// The media type wrapper used for request and response bodies.
class OpenApiMediaType {
  /// Creates a media type entry.
  const OpenApiMediaType({required this.schema, this.example});

  /// The schema for this media type.
  final OpenApiSchema schema;

  /// An example value.
  final Object? example;

  /// Serializes the media type to a JSON-compatible map.
  Map<String, Object?> toJson() => {
    'schema': schema.toJson(),
    if (example != null) 'example': example,
  };
}
