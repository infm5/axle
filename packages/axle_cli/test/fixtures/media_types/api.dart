import 'dart:typed_data';

import 'package:axle_core/axle_core.dart';

@ApiSchema()
class Upload {
  late final String title;

  @ApiProperty(format: 'binary')
  late final Uint8List cover;

  @ApiProperty(format: 'binary')
  late final List<Uint8List> attachments;
}

@ApiSchema()
class Report {
  late final int rows;
}

@ApiSchema()
class Blob {
  /// Bytes inside JSON are base64 text.
  late final Uint8List data;
}

@ApiSchema()
class MergePatch {
  late final String? title;
}

@ApiSchema()
class PatchOperation {
  late final String op;
  late final String path;
}

@ApiRoute(
  method: ApiMethod.put,
  path: '/raw',
  body: ApiBody(Uint8List, contentTypes: ['application/octet-stream']),
  responses: [
    ApiResponse(status: 200, type: Uint8List, contentTypes: ['image/png']),
    ApiResponse(status: 201, type: Uint8List),
    ApiResponse(status: 202, type: Blob),
  ],
)
Future<Object?> raw(Object? request) async => null;

@ApiRoute(
  method: ApiMethod.post,
  path: '/upload',
  body: ApiBody(Upload, contentTypes: ['multipart/form-data']),
)
Future<Object?> upload(Object? request) async => null;

@ApiRoute(
  method: ApiMethod.get,
  path: '/report',
  responses: [
    ApiResponse(status: 200, type: Report),
    ApiResponse(
      status: 200,
      type: String,
      description: 'Comma-separated rows.',
      contentTypes: ['text/csv'],
      headers: [ApiResponseHeader('Content-Disposition', type: String)],
    ),
    ApiResponse(
      status: 200,
      type: Report,
      contentTypes: ['application/x-ndjson'],
    ),
    ApiResponse.notFound(),
  ],
)
Future<Object?> report(Object? request) async => null;

@ApiRoute(
  method: ApiMethod.patch,
  path: '/documents/{id}',
  pathParams: [ApiPathParam('id', type: int)],
  body: ApiBody(MergePatch, contentTypes: ['application/merge-patch+json']),
  bodies: [
    ApiBody(
      List<PatchOperation>,
      contentTypes: ['application/json-patch+json'],
      required: false,
    ),
  ],
)
Future<Object?> patchDocument(Object? request) async => null;
