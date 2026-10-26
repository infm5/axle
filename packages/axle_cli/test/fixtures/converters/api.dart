import 'package:axle_core/axle_core.dart';
import 'package:json_annotation/json_annotation.dart';

class Money {
  const Money(this.cents);
  final int cents;
}

class EpochConverter extends JsonConverter<DateTime, int> {
  const EpochConverter();

  @override
  DateTime fromJson(int json) => DateTime.fromMillisecondsSinceEpoch(json);

  @override
  int toJson(DateTime object) => object.millisecondsSinceEpoch;
}

class OpaqueMoneyConverter extends JsonConverter<Money, Object?> {
  const OpaqueMoneyConverter();

  @override
  Money fromJson(Object? json) => Money(json as int);

  @override
  Object? toJson(Money object) => object.cents;
}

DateTime _fromSeconds(int value) =>
    DateTime.fromMillisecondsSinceEpoch(value * 1000);

String _toIso(DateTime value) => value.toIso8601String();

@ApiSchema()
@JsonSerializable()
class Event {
  const Event({
    required this.at,
    required this.maybeAt,
    required this.seen,
    required this.price,
    required this.priceText,
    required this.plain,
  });

  @EpochConverter()
  final DateTime at;

  @EpochConverter()
  final DateTime? maybeAt;

  @JsonKey(fromJson: _fromSeconds, toJson: _toIso)
  final DateTime seen;

  @OpaqueMoneyConverter()
  final Money price;

  @OpaqueMoneyConverter()
  @ApiProperty(type: String)
  final Money? priceText;

  final DateTime plain;
}

@ApiSchema()
@EpochConverter()
class ClassLevel {
  const ClassLevel({required this.when, required this.name});
  final DateTime when;
  final String name;
}

@ApiRoute(
  method: ApiMethod.get,
  path: '/events',
  responses: [ApiResponse.ok(Event), ApiResponse.created(ClassLevel)],
)
Future<Object?> events(Object? request) async => null;
