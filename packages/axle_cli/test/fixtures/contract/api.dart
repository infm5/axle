import 'package:axle_core/axle_core.dart';

@ApiSchema()
class Item {
  late final int id;
  late final String name;
}

@ApiSchema()
class ApiError {
  late final String message;
}

@ApiSchema()
class Filter {
  late final String color;
  late final int? size;
}

/// Shared by every protected route; const lists can be spread into annotations.
const protectedErrors = [
  ApiResponse.unauthorized(ApiError),
  ApiResponse.forbidden(ApiError),
  ApiResponse.tooManyRequests(ApiError),
];

@ApiRoute(
  method: ApiMethod.get,
  path: '/items',
  queryParams: [
    ApiQueryParam('ids', type: List<int>, explode: false),
    ApiQueryParam('tags', type: List<String>),
    ApiQueryParam(
      'sort',
      type: List<String>,
      style: ApiParameterStyle.pipeDelimited,
    ),
    ApiQueryParam('filter', type: Filter, style: ApiParameterStyle.deepObject),
    ApiQueryParam(
      'q',
      type: String,
      examples: {
        'word': ApiExample('cat', summary: 'One word'),
        'phrase': ApiExample('black cat', description: 'Several words.'),
      },
    ),
  ],
  headerParams: [ApiHeaderParam('X-Ids', type: List<int>, explode: true)],
  responses: [
    ApiResponse.ok(Item),
    ...protectedErrors,
    ApiResponse.conflict(ApiError),
    ApiResponse.unprocessableEntity(ApiError),
    ApiResponse.range(4, type: ApiError),
    ApiResponse.range(5),
    ApiResponse.defaultResponse(type: ApiError),
  ],
)
Future<Object?> listItems(Object? request) async => null;

@ApiRoute(
  method: ApiMethod.get,
  path: '/items/{id}',
  pathParams: [ApiPathParam('id', type: int, style: ApiParameterStyle.label)],
  responses: [
    ApiResponse.ok(Item),
    ApiResponse.notFound(ApiError),
    ApiResponse.defaultResponse(),
  ],
)
Future<Object?> getItem(Object? request) async => null;

@ApiRoute(
  method: ApiMethod.post,
  path: '/items',
  body: ApiBody(
    Item,
    examples: {
      'minimal': ApiExample({'id': 1, 'name': 'Lamp'}, summary: 'Smallest'),
      'external': ApiExample.external('https://example.com/item.json'),
    },
  ),
  responses: [
    ApiResponse(
      status: 201,
      type: Item,
      examples: {
        'created': ApiExample({'id': 2, 'name': 'Desk'}),
      },
    ),
  ],
)
Future<Object?> createItem(Object? request) async => null;
