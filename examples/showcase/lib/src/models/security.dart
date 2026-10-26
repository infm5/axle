/// Models for the security routes.
library;

import 'package:axle_shelf/axle_shelf.dart';

import 'common.dart';

/// Who the server thinks you are.
@ApiSchema(description: 'The caller, as the server identified them.')
class Whoami implements Jsonable {
  /// Creates a result.
  const Whoami({
    required this.scheme,
    required this.subject,
    this.scopes = const [],
  });

  /// The security scheme that matched.
  @ApiProperty(example: 'bearerAuth')
  final String scheme;

  /// Who the credentials belong to.
  final String subject;

  /// The scopes the credentials carry, for OAuth2 and OpenID Connect.
  final List<String> scopes;

  @override
  Map<String, Object?> toJson() => {
    'scheme': scheme,
    'subject': subject,
    'scopes': scopes,
  };
}
