import 'package:axle_core/axle_core.dart';
import 'package:test/test.dart';

const _spec =
    '{"openapi":"3.1.0","info":{"title":"Test API","version":"1.0.0"},'
    '"paths":{}}';

void main() {
  group('AxleDocs', () {
    test('normalizes paths and derives the title from the spec', () {
      final docs = AxleDocs(
        spec: _spec,
        specPath: 'api/openapi.json',
        docsPath: 'api/docs',
      );

      expect(docs.specJson, _spec);
      expect(docs.specPath, '/api/openapi.json');
      expect(docs.docsPath, '/api/docs');
      expect(docs.title, 'Test API');
      expect(docs.uiHtml, contains('<title>Test API</title>'));
      expect(docs.uiHtml, contains('url: "/api/openapi.json"'));
      expect(docs.headers, {'cache-control': 'no-store'});
    });

    test('uses an explicit title and disables cache headers', () {
      final docs = AxleDocs(spec: _spec, title: 'Custom Docs', noCache: false);

      expect(docs.title, 'Custom Docs');
      expect(docs.uiHtml, contains('<title>Custom Docs</title>'));
      expect(docs.headers, isEmpty);
    });

    test('falls back for a malformed spec title', () {
      final docs = AxleDocs(spec: 'not json');

      expect(docs.title, 'API Docs');
    });

    test('rejects empty and identical paths', () {
      expect(() => AxleDocs(spec: _spec, specPath: '  '), throwsArgumentError);
      expect(() => AxleDocs(spec: _spec, docsPath: ''), throwsArgumentError);
      expect(
        () => AxleDocs(spec: _spec, specPath: '/same', docsPath: '/same'),
        throwsArgumentError,
      );
    });
  });
}
