/// Framework-neutral helpers for exposing an OpenAPI document and Swagger UI.
library;

import 'dart:convert';

import 'swagger_ui.dart';

/// The framework-neutral payload for an axle documentation endpoint.
///
/// Adapters use this class to expose the generated spec and Swagger UI without
/// duplicating path normalization, title resolution, cache policy, or HTML
/// generation.
class AxleDocs {
  /// Creates a documentation payload from a generated OpenAPI [spec].
  ///
  /// [specPath] and [docsPath] are normalized to start with `/`. Empty paths
  /// and identical paths are rejected. When [title] is omitted, the title is
  /// read from the spec's `info.title` and falls back to `API Docs`.
  AxleDocs({
    required String spec,
    String specPath = '/openapi.json',
    String docsPath = '/docs',
    String? title,
    this.swaggerUiUrl = defaultSwaggerUiUrl,
    this.swaggerUiCssIntegrity,
    this.swaggerUiBundleIntegrity,
    this.noCache = true,
  }) : specJson = spec,
       specPath = _normalizePath(specPath, 'specPath'),
       docsPath = _normalizePath(docsPath, 'docsPath'),
       title = title ?? _titleFromSpec(spec) {
    if (this.specPath == this.docsPath) {
      throw ArgumentError('specPath and docsPath must be different.');
    }
  }

  /// The generated OpenAPI document as a JSON string.
  final String specJson;

  /// The normalized path where the spec is served.
  final String specPath;

  /// The normalized path where Swagger UI is served.
  final String docsPath;

  /// The browser title for the Swagger UI page.
  final String title;

  /// The base URL for the Swagger UI assets.
  final String swaggerUiUrl;

  /// The optional SRI hash for the Swagger UI stylesheet.
  final String? swaggerUiCssIntegrity;

  /// The optional SRI hash for the Swagger UI bundle.
  final String? swaggerUiBundleIntegrity;

  /// Whether responses should tell clients and intermediaries not to cache.
  final bool noCache;

  /// The HTML shell for the Swagger UI page.
  String get uiHtml => swaggerUiHtml(
    specUrl: specPath,
    title: title,
    swaggerUiUrl: swaggerUiUrl,
    swaggerUiCssIntegrity: swaggerUiCssIntegrity,
    swaggerUiBundleIntegrity: swaggerUiBundleIntegrity,
  );

  /// Default response headers for the spec and UI endpoints.
  Map<String, String> get headers =>
      noCache ? const {'cache-control': 'no-store'} : const {};

  static String _normalizePath(String path, String name) {
    final trimmed = path.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(path, name, 'must not be empty');
    }
    return trimmed.startsWith('/') ? trimmed : '/$trimmed';
  }

  static String _titleFromSpec(String spec) {
    try {
      final decoded = jsonDecode(spec);
      if (decoded is Map && decoded['info'] is Map) {
        final title = (decoded['info'] as Map)['title'];
        if (title is String && title.trim().isNotEmpty) return title;
      }
    } on Object {
      // Fall through to the default title for malformed input.
    }
    return 'API Docs';
  }
}
