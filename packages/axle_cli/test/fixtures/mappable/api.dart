import 'package:axle_core/axle_core.dart';
import 'package:dart_mappable/dart_mappable.dart';

@MappableEnum(caseStyle: CaseStyle.upperSnakeCase)
enum Level {
  lowLevel,
  highLevel,
  @MappableValue('top')
  topLevel,
}

@MappableClass(caseStyle: CaseStyle.snakeCase)
class Account {
  Account(this.userName, this.loginCount, this.emailAddress, this.level);

  final String userName;
  final int loginCount;

  @MappableField(key: 'mail')
  final String? emailAddress;

  final Level level;
}

@MappableClass(caseStyle: CaseStyle.paramCase)
class KebabAccount {
  KebabAccount(this.userName);
  final String userName;
}

@MappableClass(caseStyle: CaseStyle.pascalCase)
class PascalAccount {
  PascalAccount(this.userName);
  final String userName;
}

@MappableClass(caseStyle: CaseStyle.upperSnakeCase)
class ConstantAccount {
  ConstantAccount(this.userName);
  final String userName;
}

@MappableClass()
class PlainAccount {
  PlainAccount(this.userName);
  final String userName;
}

@ApiRoute(
  method: ApiMethod.get,
  path: '/accounts',
  responses: [
    ApiResponse.ok(Account),
    ApiResponse.created(KebabAccount),
    ApiResponse.badRequest(PascalAccount),
    ApiResponse(status: 409, type: ConstantAccount),
    ApiResponse(status: 410, type: PlainAccount),
  ],
)
Future<Object?> accounts(Object? request) async => null;
