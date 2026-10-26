/// Models that show how Dart shapes become schemas.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:axle_shelf/axle_shelf.dart';

import 'common.dart';
import 'parameters.dart';

// ---------------------------------------------------------------------------
// A sealed class becomes `oneOf`; the discriminator tells variants apart.

/// A shape. Sealed, so its variants are found in this library.
@ApiSchema(
  description: 'A shape. The `type` property says which one.',
  discriminator: ApiDiscriminator(
    'type',
    mapping: {
      'circle': 'Circle',
      'rectangle': 'Rectangle',
      'polygon': 'Polygon',
    },
  ),
)
sealed class Shape implements Jsonable {
  const Shape();
}

/// A circle.
final class Circle extends Shape {
  /// Creates a circle.
  const Circle({required this.radius});

  /// The discriminator.
  final String type = 'circle';

  /// The radius.
  @ApiProperty(minimum: 0)
  final double radius;

  @override
  Map<String, Object?> toJson() => {'type': type, 'radius': radius};
}

/// A rectangle.
final class Rectangle extends Shape {
  /// Creates a rectangle.
  const Rectangle({required this.width, required this.height});

  /// The discriminator.
  final String type = 'rectangle';

  /// The width.
  @ApiProperty(minimum: 0)
  final double width;

  /// The height.
  @ApiProperty(minimum: 0)
  final double height;

  @override
  Map<String, Object?> toJson() => {
    'type': type,
    'width': width,
    'height': height,
  };
}

/// A point.
@ApiSchema(description: 'A point on a plane.')
class Point implements Jsonable {
  /// Creates a point.
  const Point(this.x, this.y);

  /// Horizontal position.
  final double x;

  /// Vertical position.
  final double y;

  @override
  Map<String, Object?> toJson() => {'x': x, 'y': y};
}

/// A polygon.
final class Polygon extends Shape {
  /// Creates a polygon.
  const Polygon({required this.points});

  /// The discriminator.
  final String type = 'polygon';

  /// The corners, at least three.
  final List<Point> points;

  @override
  Map<String, Object?> toJson() => {
    'type': type,
    'points': [for (final point in points) point.toJson()],
  };
}

// ---------------------------------------------------------------------------
// `anyOf`: a value may match several schemas at once.

/// Someone you can reach. A contact may have an email, a phone, or both.
@ApiSchema(
  anyOf: [EmailContact, PhoneContact],
  description: 'Reachable by email, by phone, or both.',
)
abstract interface class Contact implements Jsonable {}

/// An email contact.
@ApiSchema(description: 'An email address.')
class EmailContact implements Contact {
  /// Creates an email contact.
  const EmailContact(this.email);

  /// The address.
  @ApiProperty(format: 'email', example: 'ada@example.com')
  final String email;

  @override
  Map<String, Object?> toJson() => {'email': email};
}

/// A phone contact.
@ApiSchema(description: 'A phone number.')
class PhoneContact implements Contact {
  /// Creates a phone contact.
  const PhoneContact(this.phone);

  /// The number, in E.164 form.
  @ApiProperty(pattern: r'^\+[1-9]\d{6,14}$', example: '+14155550123')
  final String phone;

  @override
  Map<String, Object?> toJson() => {'phone': phone};
}

// ---------------------------------------------------------------------------
// `allOf`: inheritance, written once per level.

/// A person.
@ApiSchema(description: 'A person.')
class Person implements Jsonable {
  /// Creates a person.
  const Person({required this.id, required this.name});

  /// The id.
  @ApiProperty(minimum: 1)
  final int id;

  /// The name.
  final String name;

  @override
  Map<String, Object?> toJson() => {'id': id, 'name': name};
}

/// A person who works somewhere.
///
/// `allOf: [Person]` references the base and adds only the fields declared
/// here.
@ApiSchema(allOf: [Person], description: 'A person with a job.')
class Employee extends Person {
  /// Creates an employee.
  const Employee({
    required super.id,
    required super.name,
    required this.department,
    this.salary,
  });

  /// Where they work.
  final String department;

  /// Their yearly salary in cents, when known.
  @ApiProperty(minimum: 0)
  final int? salary;

  @override
  Map<String, Object?> toJson() => {
    ...super.toJson(),
    'department': department,
    'salary': salary,
  };
}

/// An employee with reports.
@ApiSchema(allOf: [Employee], description: 'An employee who manages others.')
class Manager extends Employee {
  /// Creates a manager.
  const Manager({
    required super.id,
    required super.name,
    required super.department,
    super.salary,
    required this.reports,
  });

  /// The people they manage.
  final List<Employee> reports;

  @override
  Map<String, Object?> toJson() => {
    ...super.toJson(),
    'reports': [for (final report in reports) report.toJson()],
  };
}

// ---------------------------------------------------------------------------
// An explicit `oneOf` as a *request* body.

/// How to pay. Pick a method with `method`.
@ApiSchema(
  oneOf: [CardPayment, BankPayment],
  description: 'How to pay.',
  discriminator: ApiDiscriminator(
    'method',
    mapping: {'card': 'CardPayment', 'bank': 'BankPayment'},
  ),
)
abstract interface class Payment {}

/// Pay by card.
@ApiSchema(description: 'Pay by card.')
class CardPayment implements Payment {
  /// Creates a card payment.
  const CardPayment({
    required this.number,
    required this.expMonth,
    required this.expYear,
  });

  /// The discriminator.
  final String method = 'card';

  /// The card number.
  @ApiProperty(pattern: r'^\d{13,19}$', example: '4242424242424242')
  final String number;

  /// The expiry month.
  @ApiProperty(minimum: 1, maximum: 12)
  final int expMonth;

  /// The expiry year.
  @ApiProperty(minimum: 2026)
  final int expYear;
}

/// Pay by bank transfer.
@ApiSchema(description: 'Pay by bank transfer.')
class BankPayment implements Payment {
  /// Creates a bank payment.
  const BankPayment({required this.iban});

  /// The discriminator.
  final String method = 'bank';

  /// The account.
  @ApiProperty(
    pattern: r'^[A-Z]{2}\d{2}[A-Z0-9]{11,30}$',
    example: 'DE89370400440532013000',
  )
  final String iban;
}

/// What a payment produced.
@ApiSchema(description: 'What a payment produced.')
class Receipt implements Jsonable {
  /// Creates a receipt.
  const Receipt({required this.id, required this.method, required this.amount});

  /// The receipt id.
  final String id;

  /// How it was paid.
  final String method;

  /// The amount in cents.
  @ApiProperty(minimum: 1)
  final int amount;

  @override
  Map<String, Object?> toJson() => {
    'id': id,
    'method': method,
    'amount': amount,
  };
}

// ---------------------------------------------------------------------------
// Recursion.

/// A node in a tree. It refers to itself.
@ApiSchema(description: 'A tree node. Children are tree nodes.')
class TreeNode implements Jsonable {
  /// Creates a node.
  const TreeNode({required this.label, this.children = const []});

  /// The label.
  final String label;

  /// The child nodes.
  final List<TreeNode> children;

  @override
  Map<String, Object?> toJson() => {
    'label': label,
    'children': [for (final child in children) child.toJson()],
  };
}

// ---------------------------------------------------------------------------
// Every type.

/// One field of every type axle understands.
@ApiSchema(description: 'One field of every type axle understands.')
class KitchenSink implements Jsonable {
  /// Creates the sample.
  const KitchenSink({
    required this.integer,
    required this.decimal,
    required this.number,
    required this.flag,
    required this.text,
    required this.timestamp,
    required this.elapsed,
    required this.link,
    required this.bigNumber,
    required this.bytes,
    required this.color,
    required this.list,
    required this.unique,
    required this.counts,
    required this.grouped,
    required this.matrix,
    required this.item,
    this.maybeItem,
    this.optional,
    this.anything,
    required this.email,
    required this.rating,
    required this.code,
    required this.original,
    required this.secret,
  });

  /// A whole number.
  final int integer;

  /// A fractional number.
  final double decimal;

  /// Either.
  final num number;

  /// A boolean.
  final bool flag;

  /// Text.
  final String text;

  /// A moment in time (`date-time`).
  final DateTime timestamp;

  /// A span of time (ISO 8601 `duration`).
  final Duration elapsed;

  /// A URL (`uri`).
  final Uri link;

  /// A number too big for most JSON parsers (`int64`).
  final BigInt bigNumber;

  /// Bytes, as base64 text inside JSON (`byte`).
  final Uint8List bytes;

  /// An enum, as a string with allowed values.
  final Color color;

  /// A list.
  final List<String> list;

  /// A set. It becomes an array; axle does not add `uniqueItems` yet.
  final Set<int> unique;

  /// A map from text to numbers.
  final Map<String, int> counts;

  /// A map whose values are lists of objects.
  final Map<String, List<Item>> grouped;

  /// A list of lists.
  final List<List<int>> matrix;

  /// A nested object.
  final Item item;

  /// A nested object that may be null.
  final Item? maybeItem;

  /// A string that may be null.
  final String? optional;

  /// Any JSON value.
  final Object? anything;

  /// Constrained by `format`.
  @ApiProperty(format: 'email', example: 'ada@example.com')
  final String email;

  /// Constrained by bounds.
  @ApiProperty(minimum: 1, maximum: 5, example: 4)
  final int rating;

  /// Constrained by length and pattern.
  @ApiProperty(
    minLength: 3,
    maxLength: 3,
    pattern: r'^[A-Z]{3}$',
    example: 'EUR',
  )
  final String code;

  /// Named differently on the wire than in Dart.
  @ApiProperty(name: 'renamed_field')
  final String original;

  /// Hidden from the schema.
  @ApiProperty(ignore: true)
  final String secret;

  @override
  Map<String, Object?> toJson() => {
    'integer': integer,
    'decimal': decimal,
    'number': number,
    'flag': flag,
    'text': text,
    'timestamp': timestamp.toIso8601String(),
    'elapsed': _isoDuration(elapsed),
    'link': link.toString(),
    'bigNumber': bigNumber.toInt(),
    'bytes': base64Encode(bytes),
    'color': color.name,
    'list': list,
    'unique': unique.toList(),
    'counts': counts,
    'grouped': {
      for (final entry in grouped.entries)
        entry.key: [for (final item in entry.value) item.toJson()],
    },
    'matrix': matrix,
    'item': item.toJson(),
    'maybeItem': maybeItem?.toJson(),
    'optional': optional,
    'anything': anything,
    'email': email,
    'rating': rating,
    'code': code,
    'renamed_field': original,
  };
}

String _isoDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);
  return 'PT${hours}H${minutes}M${seconds}S';
}
