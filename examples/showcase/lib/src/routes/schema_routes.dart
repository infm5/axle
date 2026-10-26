/// Routes that show how Dart shapes become schemas.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:axle_shelf/axle_shelf.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../http.dart';
import '../models/common.dart';
import '../models/parameters.dart';
import '../models/schemas.dart';
import 'shared.dart';

const _tags = ['Schemas'];

/// Registers the schema routes.
void schemaRoutes(Router router) {
  router
    ..get('/schemas/shapes', shapes)
    ..get('/schemas/contact', contact)
    ..get('/schemas/org', org)
    ..post('/schemas/payments', pay)
    ..get('/schemas/tree', tree)
    ..get('/schemas/inventory', inventory)
    ..get('/schemas/everything', everything);
}

/// A sealed class as `oneOf`.
@ApiRoute(
  method: ApiMethod.get,
  path: '/schemas/shapes',
  summary: 'A sealed class becomes oneOf',
  description:
      '`Shape` is sealed. axle finds `Circle`, `Rectangle`, and `Polygon` in '
      'the same library and emits `oneOf` with the `type` discriminator.',
  tags: _tags,
  responses: [ApiResponse.ok(List<Shape>)],
)
Future<Response> shapes(Request request) async {
  return json([
    const Circle(radius: 2).toJson(),
    const Rectangle(width: 3, height: 4).toJson(),
    const Polygon(points: [Point(0, 0), Point(4, 0), Point(0, 3)]).toJson(),
  ]);
}

/// `anyOf`.
@ApiRoute(
  method: ApiMethod.get,
  path: '/schemas/contact',
  summary: 'anyOf: match one schema or several',
  description:
      '`?kind=email`, `?kind=phone`, or `?kind=both`. Unlike `oneOf`, a value '
      'may satisfy more than one schema, which is why `both` is valid.',
  tags: _tags,
  queryParams: [
    ApiQueryParam(
      'kind',
      type: String,
      defaultValue: 'both',
      enumValues: ['email', 'phone', 'both'],
    ),
  ],
  responses: [ApiResponse.ok(Contact), badRequest],
)
Future<Response> contact(Request request) async {
  final kind = request.url.queryParameters['kind'] ?? 'both';
  const email = EmailContact('ada@example.com');
  const phone = PhoneContact('+14155550123');
  return switch (kind) {
    'email' => json(email.toJson()),
    'phone' => json(phone.toJson()),
    'both' => json({...email.toJson(), ...phone.toJson()}),
    _ => problem(400, 'Bad Request', detail: 'kind is email, phone, or both.'),
  };
}

/// `allOf` three levels deep.
@ApiRoute(
  method: ApiMethod.get,
  path: '/schemas/org',
  summary: 'allOf: inheritance, three levels deep',
  description:
      '`Manager` is `allOf` `Employee`, which is `allOf` `Person`. Each level '
      'lists only the fields it adds.',
  tags: _tags,
  responses: [ApiResponse.ok(Manager)],
)
Future<Response> org(Request request) async {
  return json(
    const Manager(
      id: 1,
      name: 'Grace',
      department: 'Compilers',
      salary: 20000000,
      reports: [
        Employee(id: 2, name: 'Alan', department: 'Compilers'),
        Employee(id: 3, name: 'Edsger', department: 'Compilers', salary: 1),
      ],
    ).toJson(),
  );
}

/// A union as a request body.
@ApiRoute(
  method: ApiMethod.post,
  path: '/schemas/payments',
  summary: 'A oneOf request body',
  description: 'Send a card payment or a bank payment; `method` says which.',
  tags: _tags,
  body: ApiBody(
    Payment,
    examples: {
      'card': ApiExample({
        'method': 'card',
        'number': '4242424242424242',
        'expMonth': 12,
        'expYear': 2030,
      }, summary: 'Pay by card'),
      'bank': ApiExample({
        'method': 'bank',
        'iban': 'DE89370400440532013000',
      }, summary: 'Pay by bank transfer'),
    },
  ),
  responses: [ApiResponse.created(Receipt), badRequest, unprocessable],
)
Future<Response> pay(Request request) async {
  final Map<String, Object?> body;
  try {
    body = (jsonDecode(await request.readAsString()) as Map)
        .cast<String, Object?>();
  } on Object {
    return problem(400, 'Bad Request', detail: 'Send a JSON payment.');
  }
  final method = body['method'];
  if (method == 'card') {
    final number = body['number'];
    if (number is! String || !RegExp(r'^\d{13,19}$').hasMatch(number)) {
      return problem(422, 'Unprocessable Entity', detail: 'Bad card number.');
    }
    return json(
      const Receipt(id: 'rcpt-1', method: 'card', amount: 2500).toJson(),
      status: 201,
    );
  }
  if (method == 'bank') {
    final iban = body['iban'];
    if (iban is! String || iban.length < 15) {
      return problem(422, 'Unprocessable Entity', detail: 'Bad IBAN.');
    }
    return json(
      const Receipt(id: 'rcpt-2', method: 'bank', amount: 2500).toJson(),
      status: 201,
    );
  }
  return problem(400, 'Bad Request', detail: '`method` is card or bank.');
}

TreeNode _tree(int depth, String label) => TreeNode(
  label: label,
  children: depth <= 0
      ? const []
      : [for (var i = 1; i <= 2; i++) _tree(depth - 1, '$label.$i')],
);

/// A recursive schema.
@ApiRoute(
  method: ApiMethod.get,
  path: '/schemas/tree',
  summary: 'A schema that refers to itself',
  tags: _tags,
  queryParams: [
    ApiQueryParam('depth', type: int, defaultValue: 2, minimum: 0, maximum: 5),
  ],
  responses: [ApiResponse.ok(TreeNode), badRequest],
)
Future<Response> tree(Request request) async {
  final depth = int.tryParse(request.url.queryParameters['depth'] ?? '2');
  if (depth == null || depth < 0 || depth > 5) {
    return problem(400, 'Bad Request', detail: '`depth` is 0 to 5.');
  }
  return json(_tree(depth, '1').toJson());
}

/// A map as a response.
@ApiRoute(
  method: ApiMethod.get,
  path: '/schemas/inventory',
  summary: 'A map with object values',
  description: 'The keys are SKUs; the schema uses `additionalProperties`.',
  tags: _tags,
  responses: [ApiResponse.ok(Map<String, Item>)],
)
Future<Response> inventory(Request request) async {
  return json({
    'sku-1': const Item(id: 1, name: 'Lamp', price: 2500).toJson(),
    'sku-2': const Item(
      id: 2,
      name: 'Desk',
      price: 18000,
      tags: ['wood'],
    ).toJson(),
  });
}

/// One of everything.
@ApiRoute(
  method: ApiMethod.get,
  path: '/schemas/everything',
  summary: 'A model with a field of every type',
  description:
      'Integers, floats, booleans, strings, dates, durations, URIs, big '
      'numbers, bytes, enums, lists, sets, maps, nested and nullable objects, '
      'and every constraint keyword.',
  tags: _tags,
  responses: [ApiResponse.ok(KitchenSink)],
)
Future<Response> everything(Request request) async {
  return json(
    KitchenSink(
      integer: 42,
      decimal: 3.14,
      number: 7,
      flag: true,
      text: 'hello',
      timestamp: DateTime.utc(2026, 10, 24, 9),
      elapsed: const Duration(hours: 1, minutes: 30),
      link: Uri.parse('https://axle.infms.dev'),
      bigNumber: BigInt.from(12345678901234),
      bytes: Uint8List.fromList([1, 2, 3, 4]),
      color: Color.green,
      list: const ['a', 'b'],
      unique: const {1, 2, 3},
      counts: const {'x': 1, 'y': 2},
      grouped: const {
        'cheap': [Item(id: 1, name: 'Lamp', price: 2500)],
      },
      matrix: const [
        [1, 2],
        [3, 4],
      ],
      item: const Item(id: 9, name: 'Chair', price: 7000),
      anything: const {'any': 'thing'},
      email: 'ada@example.com',
      rating: 4,
      code: 'EUR',
      original: 'renamed on the wire',
      secret: 'never sent',
    ).toJson(),
  );
}
