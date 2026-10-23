import 'package:axle_core/axle_core.dart';
import 'package:test/test.dart';

void main() {
  group('annotations', () {
    test('use documented defaults', () {
      const route = ApiRoute(method: ApiMethod.get, path: '/users');
      expect(route.summary, isNull);
      expect(route.description, isNull);
      expect(route.operationId, isNull);
      expect(route.tags, isEmpty);
      expect(route.deprecated, isFalse);
      expect(route.pathParams, isEmpty);
      expect(route.queryParams, isEmpty);
      expect(route.headerParams, isEmpty);
      expect(route.body, isNull);
      expect(route.responses, isEmpty);
      expect(route.ignore, isFalse);

      const pathParam = ApiPathParam('id', type: int);
      expect(pathParam.description, isNull);
      expect(pathParam.example, isNull);

      const queryParam = ApiQueryParam('limit', type: int);
      expect(queryParam.required, isFalse);
      expect(queryParam.description, isNull);
      expect(queryParam.example, isNull);
      expect(queryParam.defaultValue, isNull);

      const headerParam = ApiHeaderParam('X-Token', type: String);
      expect(headerParam.required, isFalse);
      expect(headerParam.description, isNull);
      expect(headerParam.example, isNull);

      const body = ApiBody(String);
      expect(body.description, isNull);
      expect(body.required, isTrue);
      expect(body.example, isNull);

      const response = ApiResponse(status: 200);
      expect(response.type, isNull);
      expect(response.description, isEmpty);
      expect(response.nullable, isFalse);
      expect(response.example, isNull);

      expect(const ApiResponse.ok().status, 200);
      expect(const ApiResponse.ok().description, 'OK');
      expect(const ApiResponse.created().status, 201);
      expect(const ApiResponse.created().description, 'Created');
      expect(const ApiResponse.noContent().status, 204);
      expect(const ApiResponse.badRequest().status, 400);
      expect(const ApiResponse.notFound().status, 404);
      expect(const ApiResponse.internalServerError().status, 500);

      const schema = ApiSchema();
      expect(schema.name, isNull);
      expect(schema.description, isNull);
      expect(schema.ignore, isFalse);

      const property = ApiProperty();
      expect(property.name, isNull);
      expect(property.description, isNull);
      expect(property.example, isNull);
      expect(property.required, isNull);
      expect(property.ignore, isFalse);
    });
  });
}
