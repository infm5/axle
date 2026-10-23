import 'dart:convert';

import 'package:relic/relic.dart';

/// Returns a JSON response with [status].
Response jsonResponse(Object? value, {int status = 200}) {
  return Response(
    status,
    body: Body.fromString(jsonEncode(value), mimeType: MimeType.json),
  );
}

/// Returns a JSON error response.
Response jsonError(int status, String code, String message) {
  return jsonResponse({'code': code, 'message': message}, status: status);
}

/// Reads a JSON object from [request], or `null` when the body is invalid.
Future<Map<String, Object?>?> readJsonObject(Request request) async {
  try {
    final decoded = jsonDecode(await request.readAsString());
    return decoded is Map<String, Object?> ? decoded : null;
  } on Object {
    return null;
  }
}

/// Parses an optional boolean query value.
bool? parseQueryBool(String? value) {
  return switch (value) {
    'true' => true,
    'false' => false,
    _ => null,
  };
}

/// Parses an optional integer query value.
int? parseQueryInt(String? value) {
  return value == null ? null : int.tryParse(value);
}
