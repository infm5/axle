import 'dart:io';

import 'package:axle_cli/axle_cli.dart';
import 'package:test/test.dart';

/// Keeps the schemas printed in `doc/models/` honest: the fixtures hold the
/// models shown there, and these tests hold the JSON shown there.
void main() {
  test(
    'doc/models/json-serializable.md shows the real Profile schema',
    () async {
      final result = await OpenApiGenerator(
        config: AxleConfig(
          title: 'Docs',
          version: '1.0.0',
          scan: const ['test/fixtures/docs_snippets'],
        ),
        projectRoot: Directory.current,
      ).generate();
      final schemas =
          (result.document.toJson()['components']! as Map)['schemas']! as Map;

      expect(schemas['Profile'], {
        'type': 'object',
        'properties': {
          'KeepsName': {
            'type': ['string', 'null'],
          },
          'joined_at': {'type': 'integer'},
          'status': {
            'type': 'string',
            'enum': ['active_user', 'pending_review'],
          },
          'user_id': {'type': 'integer'},
        },
        'required': ['joined_at', 'status', 'user_id'],
      });
      expect(result.warnings, isEmpty);
    },
  );
}
