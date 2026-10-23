import 'package:axle_core/axle_core.dart';
import 'package:test/test.dart';

void main() {
  group('swaggerUiHtml', () {
    test('includes the spec URL and Swagger UI assets', () {
      final html = swaggerUiHtml(specUrl: '/api/openapi.json', title: 'My API');

      expect(html, contains('<title>My API</title>'));
      expect(html, contains('url: "/api/openapi.json"'));
      expect(html, contains('swagger-ui.css'));
      expect(html, contains('swagger-ui-bundle.js'));
      expect(html, contains('persistAuthorization: true'));
    });

    test('pins the default Swagger UI and applies SRI hashes', () {
      final html = swaggerUiHtml();

      expect(html, contains('swagger-ui-dist@5.34.0'));
      expect(html, contains('integrity="sha384-'));
      expect(html, contains('crossorigin="anonymous"'));
      expect(
        html,
        contains(
          'integrity="sha384-4c3vsE5f+trhFyHrFrLM1fFGUn531NIaC7dcqEWIJdoRQJ5CkJbSuSCwXLpaS1KF"',
        ),
      );
      expect(
        html,
        contains(
          'integrity="sha384-9Td7MKiIr2S83E1kZyyVi8KdJw/S8CpAvu0llLyMeg0xq/hDGiZJfVn0fV4llCmK"',
        ),
      );
    });

    test('normalizes a trailing slash in the Swagger UI base URL', () {
      final html = swaggerUiHtml(swaggerUiUrl: 'https://example.com/assets/');

      expect(
        html,
        contains('href="https://example.com/assets/swagger-ui.css"'),
      );
      expect(
        html,
        contains('src="https://example.com/assets/swagger-ui-bundle.js"'),
      );
      expect(html, isNot(contains('assets//')));
    });

    test('escapes the title, spec URL, and base URL', () {
      final html = swaggerUiHtml(
        title: '</title><script>alert(1)</script>',
        specUrl: '</script><script>alert(2)</script>',
        swaggerUiUrl: 'https://example.com/assets"onload="alert(1)',
      );

      expect(html, contains('&lt;/title&gt;'));
      expect(html, isNot(contains('<script>alert(1)</script>')));
      expect(html, isNot(contains('<script>alert(2)</script>')));
      expect(html, contains(r'\u003c/script'));
      expect(html, contains('&quot;onload=&quot;alert(1)'));
    });
  });
}
