/// Annotated Shelf handlers for the accounts API.
library;

import 'package:axle_shelf/axle_shelf.dart';
import 'package:dart_mappable/dart_mappable.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../models/account.dart';

final _accounts = <int, Account>{
  1: Account(
    id: 1,
    displayName: 'Ada Lovelace',
    status: AccountStatus.active,
    address: const Address(
      streetLine: '12 Analytical Way',
      postalCode: 'N1 9GU',
    ),
    createdAt: DateTime.utc(2026, 1, 5),
  ),
};

/// The path is a constant so the router and the annotation cannot drift.
const accountPath = '/accounts/<id>';

/// Registers the routes on [router].
void configureApi(Router router) {
  router
    ..get(accountPath, getAccount)
    ..post('/accounts', createAccount);
}

/// Returns one account.
@ApiRoute(
  method: ApiMethod.get,
  path: accountPath,
  summary: 'Get an account',
  pathParams: [ApiPathParam('id', type: int, minimum: 1)],
  responses: [ApiResponse.ok(Account), ApiResponse.notFound(ApiError)],
)
Future<Response> getAccount(Request request, String id) async {
  final account = _accounts[int.tryParse(id)];
  if (account == null) {
    return _json(
      404,
      const ApiError(code: 'not_found', message: 'No such account.').toJson(),
    );
  }
  return _json(200, account.toJson());
}

/// Creates an account.
@ApiRoute(
  method: ApiMethod.post,
  path: '/accounts',
  summary: 'Create an account',
  body: ApiBody(NewAccount),
  responses: [
    ApiResponse.created(Account),
    ApiResponse.unprocessableEntity(ApiError),
  ],
)
Future<Response> createAccount(Request request) async {
  final NewAccount input;
  try {
    input = NewAccountMapper.fromJson(await request.readAsString());
  } on MapperException catch (error) {
    return _json(
      422,
      ApiError(code: 'invalid_body', message: error.toString()).toJson(),
    );
  }
  final account = Account(
    id: _accounts.length + 1,
    displayName: input.displayName,
    status: AccountStatus.pendingReview,
    address: input.address,
    nickname: input.nickname,
    createdAt: DateTime.now().toUtc(),
  );
  _accounts[account.id] = account;
  return _json(201, account.toJson());
}

Response _json(int status, String body) =>
    Response(status, body: body, headers: {'content-type': 'application/json'});
