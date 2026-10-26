/// Annotated Shelf handlers for the orders API.
library;

import 'dart:convert';

import 'package:axle_shelf/axle_shelf.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../models/order.dart';

final _orders = <int, Order>{
  1: const Order(
    id: 1,
    method: PaymentMethod.card(last4: '4242', expMonth: 12, expYear: 2030),
    itemSkus: ['sku-1', 'sku-2'],
  ),
};

/// The path is a constant so the router and the annotation cannot drift.
const orderPath = '/orders/<id>';

/// Registers the routes on [router].
void configureApi(Router router) {
  router
    ..get(orderPath, getOrder)
    ..post('/orders', createOrder);
}

/// Returns one order.
@ApiRoute(
  method: ApiMethod.get,
  path: orderPath,
  summary: 'Get an order',
  pathParams: [ApiPathParam('id', type: int, minimum: 1)],
  responses: [ApiResponse.ok(Order), ApiResponse.notFound(ApiError)],
)
Future<Response> getOrder(Request request, String id) async {
  final order = _orders[int.tryParse(id)];
  if (order == null) {
    return _json(
      404,
      const ApiError(code: 'not_found', message: 'No such order.').toJson(),
    );
  }
  return _json(200, order.toJson());
}

/// Creates an order.
@ApiRoute(
  method: ApiMethod.post,
  path: '/orders',
  summary: 'Create an order',
  body: ApiBody(NewOrder),
  responses: [
    ApiResponse.created(Order),
    ApiResponse.unprocessableEntity(ApiError),
  ],
)
Future<Response> createOrder(Request request) async {
  final NewOrder input;
  try {
    input = NewOrder.fromJson(
      jsonDecode(await request.readAsString()) as Map<String, dynamic>,
    );
  } on Object catch (error) {
    return _json(
      422,
      ApiError(code: 'invalid_body', message: '$error').toJson(),
    );
  }
  final order = Order(
    id: _orders.length + 1,
    method: input.method,
    itemSkus: input.itemSkus,
    customerNote: input.customerNote,
  );
  _orders[order.id] = order;
  return _json(201, order.toJson());
}

Response _json(int status, Map<String, dynamic> body) => Response(
  status,
  body: jsonEncode(body),
  headers: {'content-type': 'application/json'},
);
