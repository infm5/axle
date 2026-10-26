import 'dart:io';

import 'package:axle_cli/axle_cli.dart';
import 'package:test/test.dart';

void main() {
  test(
    'discovers routes on methods, mixins, and top-level variables',
    () async {
      final result = await OpenApiGenerator(
        config: AxleConfig(
          title: 'Targets',
          version: '1.0.0',
          scan: const ['test/fixtures/route_targets'],
        ),
        projectRoot: Directory.current,
      ).generate();
      final paths = result.document.toJson()['paths']! as Map<String, Object?>;

      expect(paths.keys, [
        '/health',
        '/notes',
        '/ping',
        '/todos',
        '/todos/{id}',
        '/top',
      ]);
      String id(String path) =>
          ((paths[path]! as Map)['get']! as Map)['operationId']! as String;
      expect(id('/todos'), 'TodoRoutes_list');
      expect(id('/notes'), 'NoteRoutes_list');
      expect(id('/todos/{id}'), 'TodoRoutes_get');
      expect(id('/health'), 'HealthRoutes_health');
      expect(id('/ping'), 'ping');
      expect(id('/top'), 'top');
    },
  );
}
