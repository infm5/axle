import 'package:axle_core/axle_core.dart';

@ApiRoute(
  method: ApiMethod.get,
  path: '/headers',
  operationId: 'headers',
  summary: 'Header example',
  description: 'Exercises header parameters.',
  tags: ['Edge'],
  deprecated: true,
  headerParams: [
    ApiHeaderParam(
      'X-Token',
      type: String,
      required: true,
      description: 'A token.',
      example: 'abc',
    ),
  ],
)
Future<Object?> headers(Object? request) async => null;

@ApiRoute(method: ApiMethod.get, path: '/defaults')
Future<Object?> defaults(Object? request) async => null;

@ApiRoute(
  method: ApiMethod.get,
  path: '/teapot',
  responses: [ApiResponse(status: 418)],
)
Future<Object?> teapot(Object? request) async => null;

@ApiRoute(method: ApiMethod.get, path: '/missing/:id')
Future<Object?> missingParam(Object? request) async => null;

@ApiRoute(method: ApiMethod.get, path: '/ignored', ignore: true)
Future<Object?> ignored(Object? request) async => null;

@ApiRoute(
  method: ApiMethod.get,
  path: '/nullable',
  responses: [
    ApiResponse(status: 200, type: String, nullable: true, description: ''),
  ],
)
Future<Object?> nullable(Object? request) async => null;
