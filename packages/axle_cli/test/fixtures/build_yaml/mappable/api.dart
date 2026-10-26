import 'package:axle_core/axle_core.dart';
import 'package:dart_mappable/dart_mappable.dart';

/// Mapped, so `enumCaseStyle` applies.
@MappableEnum()
enum Level { highLevel, low }

/// Explicit style wins over the project default.
@MappableEnum(caseStyle: CaseStyle.snakeCase)
enum Tier { topTier }

/// Not annotated, so dart_mappable does not map it and nothing renames it.
enum Unmapped { someValue }

@MappableClass()
class A {
  A(this.userName, this.level, this.tier, this.unmapped);
  final String userName;
  final Level level;
  final Tier tier;
  final Unmapped unmapped;
}

@MappableClass(caseStyle: CaseStyle.paramCase)
class B {
  B(this.userName);
  final String userName;
}

@ApiRoute(
  method: ApiMethod.get,
  path: '/all',
  responses: [
    ApiResponse(status: 200, type: A),
    ApiResponse(status: 201, type: B),
  ],
)
Future<Object?> all(Object? request) async => null;
