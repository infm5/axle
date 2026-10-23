/// HTML helpers for serving Swagger UI.
library;

import 'dart:convert';

/// The default base URL for the Swagger UI distribution.
const defaultSwaggerUiUrl =
    'https://cdn.jsdelivr.net/npm/swagger-ui-dist@5.34.0';

/// The SRI hash for the default Swagger UI stylesheet.
const defaultSwaggerUiCssIntegrity =
    'sha384-4c3vsE5f+trhFyHrFrLM1fFGUn531NIaC7dcqEWIJdoRQJ5CkJbSuSCwXLpaS1KF';

/// The SRI hash for the default Swagger UI bundle.
const defaultSwaggerUiBundleIntegrity =
    'sha384-9Td7MKiIr2S83E1kZyyVi8KdJw/S8CpAvu0llLyMeg0xq/hDGiZJfVn0fV4llCmK';

/// Builds the HTML shell for a Swagger UI documentation page.
///
/// The page loads Swagger UI from [swaggerUiUrl] and fetches the OpenAPI
/// document from [specUrl]. Both values are escaped before they are written
/// into the document. When the default asset URL is used, the default SRI
/// hashes are applied. Pass [swaggerUiCssIntegrity] and
/// [swaggerUiBundleIntegrity] for a custom CDN, or leave them `null` for local
/// assets.
String swaggerUiHtml({
  String specUrl = '/openapi.json',
  String title = 'API Docs',
  String swaggerUiUrl = defaultSwaggerUiUrl,
  String? swaggerUiCssIntegrity,
  String? swaggerUiBundleIntegrity,
  bool persistAuthorization = true,
  bool displayRequestDuration = true,
}) {
  final baseUrl =
      swaggerUiUrl.endsWith('/')
          ? swaggerUiUrl.substring(0, swaggerUiUrl.length - 1)
          : swaggerUiUrl;
  final safeTitle = const HtmlEscape(HtmlEscapeMode.element).convert(title);
  final safeBaseUrl = const HtmlEscape(
    HtmlEscapeMode.attribute,
  ).convert(baseUrl);
  final encodedSpecUrl = jsonEncode(specUrl).replaceAll('<', r'\u003c');
  final resolvedCssIntegrity =
      swaggerUiCssIntegrity ??
      (baseUrl == defaultSwaggerUiUrl ? defaultSwaggerUiCssIntegrity : null);
  final resolvedBundleIntegrity =
      swaggerUiBundleIntegrity ??
      (baseUrl == defaultSwaggerUiUrl ? defaultSwaggerUiBundleIntegrity : null);
  final cssIntegrityAttribute = _integrityAttribute(resolvedCssIntegrity);
  final bundleIntegrityAttribute = _integrityAttribute(resolvedBundleIntegrity);

  return '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>$safeTitle</title>
  <link rel="stylesheet" href="$safeBaseUrl/swagger-ui.css"$cssIntegrityAttribute>
</head>
<body>
  <div id="swagger-ui"></div>
  <script src="$safeBaseUrl/swagger-ui-bundle.js"$bundleIntegrityAttribute></script>
  <script>
    window.onload = function () {
      window.ui = SwaggerUIBundle({
        url: $encodedSpecUrl,
        dom_id: '#swagger-ui',
        deepLinking: true,
        persistAuthorization: $persistAuthorization,
        displayRequestDuration: $displayRequestDuration
      });
    };
  </script>
</body>
</html>
''';
}

String _integrityAttribute(String? integrity) {
  if (integrity == null) return '';
  final safe = const HtmlEscape(HtmlEscapeMode.attribute).convert(integrity);
  return ' integrity="$safe" crossorigin="anonymous"';
}
