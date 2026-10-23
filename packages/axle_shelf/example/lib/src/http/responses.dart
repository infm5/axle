import 'dart:convert';

import 'package:shelf/shelf.dart';

/// Encodes [body] as a JSON response.
Response jsonResponse(Object? body, {int status = 200}) {
  return Response(
    status,
    body: jsonEncode(body),
    headers: {'content-type': 'application/json'},
  );
}

/// Builds a JSON error response.
Response jsonError(int status, String code, String message) {
  return jsonResponse({'code': code, 'message': message}, status: status);
}

/// Reads a JSON object request body.
Future<Map<String, dynamic>?> readJsonObject(Request request) async {
  try {
    final decoded = jsonDecode(await request.readAsString());
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return decoded.cast<String, dynamic>();
  } on Object {
    // Invalid JSON is reported as a bad request by the route.
  }
  return null;
}

/// Parses an optional boolean query parameter.
bool? parseQueryBool(String? value) {
  return switch (value) {
    'true' => true,
    'false' => false,
    _ => null,
  };
}

/// Parses an optional positive integer query parameter.
int? parseQueryInt(String? value) {
  final parsed = value == null ? null : int.tryParse(value);
  return parsed == null || parsed < 1 ? null : parsed;
}
