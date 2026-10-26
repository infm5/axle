import 'package:axle_core/axle_core.dart';

@ApiSchema()
class UserDto {
  const UserDto(this.name);
  final String name;
}

@ApiSchema(name: 'Item')
class ItemDto {
  const ItemDto(this.id);
  final int id;
}

@ApiSchema(description: 'A page of results.')
class Page<T> {
  const Page(this.items, this.total, this.next);
  final List<T> items;
  final int total;
  final T? next;
}

class Envelope<T> {
  const Envelope(this.data, this.meta);
  final T data;
  final Map<String, T> meta;
}

class Pair<A, B> {
  const Pair(this.first, this.second);
  final A first;
  final B second;
}

class Audited<T> extends Envelope<T> {
  const Audited(super.data, super.meta, this.by);
  final String by;
}

class UserPage extends Page<UserDto> {
  const UserPage(super.items, super.total, super.next);
}

class Tree<T> {
  const Tree(this.value, this.children);
  final T value;
  final List<Tree<T>> children;
}

@ApiRoute(
  method: ApiMethod.get,
  path: '/users',
  responses: [ApiResponse.ok(Page<UserDto>)],
)
Future<Object?> users(Object? request) async => null;

@ApiRoute(
  method: ApiMethod.get,
  path: '/items',
  responses: [ApiResponse.ok(Page<ItemDto>)],
)
Future<Object?> items(Object? request) async => null;

@ApiRoute(
  method: ApiMethod.get,
  path: '/names',
  responses: [ApiResponse.ok(Page<String>)],
)
Future<Object?> names(Object? request) async => null;

@ApiRoute(
  method: ApiMethod.get,
  path: '/nested',
  responses: [ApiResponse.ok(Envelope<Page<UserDto>>)],
)
Future<Object?> nested(Object? request) async => null;

@ApiRoute(
  method: ApiMethod.get,
  path: '/pair',
  responses: [ApiResponse.ok(Pair<UserDto, List<int>>)],
)
Future<Object?> pair(Object? request) async => null;

@ApiRoute(
  method: ApiMethod.get,
  path: '/audited',
  responses: [ApiResponse.ok(Audited<ItemDto>)],
)
Future<Object?> audited(Object? request) async => null;

@ApiRoute(
  method: ApiMethod.get,
  path: '/user-page',
  responses: [ApiResponse.ok(UserPage)],
)
Future<Object?> userPage(Object? request) async => null;

@ApiRoute(
  method: ApiMethod.get,
  path: '/tree',
  responses: [ApiResponse.ok(Tree<int>)],
)
Future<Object?> tree(Object? request) async => null;
