import 'dart:convert';

import 'package:axle_serverpod/axle_serverpod.dart';
import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import '../greetings/greeting_endpoint.dart';

/// Path used by both the OpenAPI annotation and the web-server route.
const greetingPath = '/greeting';

/// Returns a greeting from the generated Serverpod endpoint.
///
/// The response schema is the generated `Greeting` model, so the OpenAPI
/// document stays in sync with the Serverpod protocol model.
@ApiRoute(
  method: ApiMethod.get,
  path: greetingPath,
  summary: 'Get a greeting',
  tags: ['Greeting'],
  queryParams: [
    ApiQueryParam(
      'name',
      type: String,
      description: 'The name to greet.',
      defaultValue: 'World',
    ),
  ],
  responses: [ApiResponse.ok(Greeting)],
)
Future<Response> getGreeting(Session session, Request request) async {
  final requestedName = request.url.queryParameters['name']?.trim();
  final name = requestedName == null || requestedName.isEmpty
      ? 'World'
      : requestedName;
  final greeting = await GreetingEndpoint().hello(session, name);

  // Remove the Serverpod protocol discriminator so the REST response matches
  // the OpenAPI schema exactly.
  final json = greeting.toJson()..remove('__className__');
  return Response.ok(
    body: Body.fromString(jsonEncode(json), mimeType: MimeType.json),
  );
}

/// Serverpod web-server route backed by [getGreeting].
class GreetingRoute extends Route {
  /// Creates the route.
  GreetingRoute() : super(methods: {Method.get});

  @override
  Future<Result> handleCall(Session session, Request request) =>
      getGreeting(session, request);
}
