/// Models for the parameter routes.
library;

import 'package:axle_shelf/axle_shelf.dart';

import 'common.dart';

/// Item colors.
enum Color { red, green, blue }

/// Item states.
enum Status { draft, active, archived }

/// What a path parameter refers to.
enum Kind { user, team }

/// A filter sent as `filter[color]=red&filter[minSize]=2`.
///
/// This is the `deepObject` style: an object spread over several parameters.
@ApiSchema(description: 'A filter sent as a deepObject.')
class Filter {
  /// Creates a filter.
  const Filter({this.color, this.minSize, this.maxSize});

  /// Only items of this color.
  final Color? color;

  /// Only items at least this large.
  @ApiProperty(minimum: 0)
  final int? minSize;

  /// Only items at most this large.
  @ApiProperty(minimum: 0)
  final int? maxSize;
}

/// What the server parsed from the parameters of a request.
@ApiSchema(description: 'The parameters, as the server understood them.')
class ParsedParameters implements Jsonable {
  /// Creates a result.
  const ParsedParameters({required this.route, required this.values});

  /// The route that parsed them.
  final String route;

  /// Every parameter and its parsed value.
  final Map<String, Object?> values;

  @override
  Map<String, Object?> toJson() => {'route': route, 'values': values};
}
