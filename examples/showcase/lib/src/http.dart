/// Small helpers shared by every route module.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:mime/mime.dart';
import 'package:shelf/shelf.dart';

import 'models/common.dart';

/// The media type of RFC 9457 problem details.
const problemJson = 'application/problem+json';

/// A JSON response.
Response json(
  Object? body, {
  int status = 200,
  Map<String, String> headers = const {},
  String contentType = 'application/json',
}) {
  return Response(
    status,
    body: jsonEncode(body),
    headers: {'content-type': contentType, ...headers},
  );
}

/// A text response of any media type.
Response text(
  String body, {
  int status = 200,
  String contentType = 'text/plain; charset=utf-8',
  Map<String, String> headers = const {},
}) {
  return Response(
    status,
    body: body,
    headers: {'content-type': contentType, ...headers},
  );
}

/// A binary response.
Response binary(
  List<int> body, {
  required String contentType,
  int status = 200,
  Map<String, String> headers = const {},
}) {
  return Response(
    status,
    body: body,
    headers: {
      'content-type': contentType,
      'content-length': '${body.length}',
      ...headers,
    },
  );
}

/// An RFC 9457 problem response.
Response problem(
  int status,
  String title, {
  String? detail,
  Map<String, String> headers = const {},
}) {
  return json(
    Problem(status: status, title: title, detail: detail).toJson(),
    status: status,
    contentType: problemJson,
    headers: headers,
  );
}

/// Escapes text for XML.
String xmlEscape(String value) => value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');

/// Picks the best of [supported] for the request's `Accept` header.
///
/// Returns the first supported type when the header is absent, and `null`
/// when nothing matches, which callers answer with `406`.
String? negotiate(Request request, List<String> supported) {
  final header = request.headers['accept'];
  if (header == null || header.trim().isEmpty) return supported.first;

  final wanted = <({String range, double quality})>[];
  for (final part in header.split(',')) {
    final pieces = part.trim().split(';');
    var quality = 1.0;
    for (final parameter in pieces.skip(1)) {
      final pair = parameter.trim().split('=');
      if (pair.length == 2 && pair[0] == 'q') {
        quality = double.tryParse(pair[1]) ?? 1.0;
      }
    }
    if (pieces.first.trim().isNotEmpty && quality > 0) {
      wanted.add((range: pieces.first.trim().toLowerCase(), quality: quality));
    }
  }
  wanted.sort((a, b) => b.quality.compareTo(a.quality));

  for (final entry in wanted) {
    for (final type in supported) {
      if (_matches(entry.range, type)) return type;
    }
  }
  return null;
}

bool _matches(String range, String type) {
  if (range == '*/*' || range == type) return true;
  if (range.endsWith('/*')) {
    return type.startsWith(range.substring(0, range.length - 1));
  }
  return false;
}

/// The `Cookie` header as a map.
Map<String, String> cookies(Request request) {
  final header = request.headers['cookie'];
  if (header == null) return const {};
  return {
    for (final pair in header.split(';'))
      if (pair.contains('='))
        pair.substring(0, pair.indexOf('=')).trim(): pair
            .substring(pair.indexOf('=') + 1)
            .trim(),
  };
}

/// A part of a `multipart/form-data` body.
class FormPart {
  /// Creates a part.
  const FormPart({
    required this.name,
    required this.bytes,
    this.filename,
    this.contentType,
  });

  /// The form field name.
  final String name;

  /// The file name, for file parts.
  final String? filename;

  /// The part's media type.
  final String? contentType;

  /// The raw content.
  final Uint8List bytes;

  /// The content as text.
  String get text => utf8.decode(bytes, allowMalformed: true);
}

/// Reads every part of a `multipart/form-data` request, or `null` when the
/// request is not multipart.
Future<List<FormPart>?> readMultipart(Request request) async {
  final contentType = request.headers['content-type'];
  if (contentType == null) return null;
  final header = MediaType.parse(contentType);
  final boundary = header.boundary;
  if (header.mime != 'multipart/form-data' || boundary == null) return null;

  final parts = <FormPart>[];
  await for (final part in MimeMultipartTransformer(
    boundary,
  ).bind(request.read())) {
    final disposition = part.headers['content-disposition'] ?? '';
    final builder = BytesBuilder(copy: false);
    await for (final chunk in part) {
      builder.add(chunk);
    }
    parts.add(
      FormPart(
        name: _dispositionValue(disposition, 'name') ?? '',
        filename: _dispositionValue(disposition, 'filename'),
        contentType: part.headers['content-type'],
        bytes: builder.takeBytes(),
      ),
    );
  }
  return parts;
}

String? _dispositionValue(String disposition, String key) {
  final match = RegExp('$key="([^"]*)"').firstMatch(disposition);
  return match?.group(1);
}

/// A tiny parsed `Content-Type`.
class MediaType {
  const MediaType._(this.mime, this.boundary);

  /// The media type without parameters.
  final String mime;

  /// The multipart boundary, when present.
  final String? boundary;

  /// Parses a `Content-Type` header value.
  factory MediaType.parse(String value) {
    final pieces = value.split(';');
    String? boundary;
    for (final parameter in pieces.skip(1)) {
      final pair = parameter.trim().split('=');
      if (pair.length == 2 && pair[0].toLowerCase() == 'boundary') {
        boundary = pair[1].replaceAll('"', '');
      }
    }
    return MediaType._(pieces.first.trim().toLowerCase(), boundary);
  }
}

/// A simple additive checksum, enough to show an upload arrived intact.
int checksum(List<int> bytes) =>
    bytes.fold<int>(0, (sum, byte) => (sum + byte) & 0xFFFFFF);
