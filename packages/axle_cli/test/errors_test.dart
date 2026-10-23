import 'package:axle_cli/axle_cli.dart';
import 'package:test/test.dart';

void main() {
  test('AxleException renders its user-facing message', () {
    const error = AxleException(
      'something failed',
      exitCode: AxleExitCode.data,
    );

    expect(error.toString(), 'something failed');
  });
}
