/// OpenAPI security scheme and requirement models.
library;

/// A reusable OpenAPI security scheme.
///
/// Exactly which fields are relevant depends on [type]:
///
/// - `http` uses [scheme] and optionally [bearerFormat].
/// - `apiKey` uses [name] and [location].
/// - `oauth2` uses [flows].
/// - `openIdConnect` uses [openIdConnectUrl].
class OpenApiSecurityScheme {
  /// Creates a security scheme.
  const OpenApiSecurityScheme({
    required this.type,
    this.description,
    this.name,
    this.location,
    this.scheme,
    this.bearerFormat,
    this.flows,
    this.openIdConnectUrl,
  });

  /// Creates an HTTP basic authentication scheme.
  const OpenApiSecurityScheme.httpBasic({this.description})
    : type = 'http',
      name = null,
      location = null,
      scheme = 'basic',
      bearerFormat = null,
      flows = null,
      openIdConnectUrl = null;

  /// Creates an HTTP bearer authentication scheme.
  const OpenApiSecurityScheme.httpBearer({this.description, this.bearerFormat})
    : type = 'http',
      name = null,
      location = null,
      scheme = 'bearer',
      flows = null,
      openIdConnectUrl = null;

  /// Creates an API key authentication scheme.
  const OpenApiSecurityScheme.apiKey({
    required this.name,
    required this.location,
    this.description,
  }) : type = 'apiKey',
       scheme = null,
       bearerFormat = null,
       flows = null,
       openIdConnectUrl = null;

  /// The security scheme type: `http`, `apiKey`, `oauth2`, or `openIdConnect`.
  final String type;

  /// A description of the scheme.
  final String? description;

  /// The API key parameter name for `apiKey` schemes.
  final String? name;

  /// The API key location (`query`, `header`, or `cookie`).
  final String? location;

  /// The HTTP authentication scheme for `http` schemes.
  final String? scheme;

  /// The bearer token format hint for `http` bearer schemes.
  final String? bearerFormat;

  /// The OAuth2 flows for `oauth2` schemes.
  final OpenApiOAuthFlows? flows;

  /// The OpenID Connect discovery URL for `openIdConnect` schemes.
  final String? openIdConnectUrl;

  /// Serializes the scheme to a JSON-compatible map.
  Map<String, Object?> toJson() => {
    'type': type,
    if (description != null) 'description': description,
    if (name != null) 'name': name,
    if (location != null) 'in': location,
    if (scheme != null) 'scheme': scheme,
    if (bearerFormat != null) 'bearerFormat': bearerFormat,
    if (flows != null) 'flows': flows!.toJson(),
    if (openIdConnectUrl != null) 'openIdConnectUrl': openIdConnectUrl,
  };
}

/// The supported OAuth2 flow configurations.
class OpenApiOAuthFlows {
  /// Creates an OAuth2 flows object.
  const OpenApiOAuthFlows({
    this.implicit,
    this.password,
    this.clientCredentials,
    this.authorizationCode,
  });

  /// The implicit flow.
  final OpenApiOAuthFlow? implicit;

  /// The resource owner password flow.
  final OpenApiOAuthFlow? password;

  /// The client credentials flow.
  final OpenApiOAuthFlow? clientCredentials;

  /// The authorization code flow.
  final OpenApiOAuthFlow? authorizationCode;

  /// Serializes the flows to a JSON-compatible map.
  Map<String, Object?> toJson() => {
    if (implicit != null) 'implicit': implicit!.toJson(),
    if (password != null) 'password': password!.toJson(),
    if (clientCredentials != null)
      'clientCredentials': clientCredentials!.toJson(),
    if (authorizationCode != null)
      'authorizationCode': authorizationCode!.toJson(),
  };
}

/// One OAuth2 flow.
class OpenApiOAuthFlow {
  /// Creates an OAuth2 flow.
  const OpenApiOAuthFlow({
    this.authorizationUrl,
    this.tokenUrl,
    this.refreshUrl,
    this.scopes = const {},
  });

  /// The authorization URL for implicit and authorization-code flows.
  final String? authorizationUrl;

  /// The token URL for password, client-credentials, and authorization-code
  /// flows.
  final String? tokenUrl;

  /// The optional refresh URL.
  final String? refreshUrl;

  /// The available scopes, keyed by scope name.
  final Map<String, String> scopes;

  /// Serializes the flow to a JSON-compatible map.
  Map<String, Object?> toJson() => {
    if (authorizationUrl != null) 'authorizationUrl': authorizationUrl,
    if (tokenUrl != null) 'tokenUrl': tokenUrl,
    if (refreshUrl != null) 'refreshUrl': refreshUrl,
    'scopes': scopes,
  };
}

/// One OpenAPI security requirement.
///
/// Every scheme in [requirements] must be satisfied (logical AND). Use multiple
/// requirements on an operation for alternatives (logical OR).
class OpenApiSecurityRequirement {
  /// Creates a security requirement.
  const OpenApiSecurityRequirement(this.requirements);

  /// Scheme names mapped to the OAuth2 scopes required for each scheme.
  final Map<String, List<String>> requirements;

  /// Serializes the requirement to a JSON-compatible map.
  Map<String, Object?> toJson() => {
    for (final entry in requirements.entries) entry.key: entry.value,
  };
}
