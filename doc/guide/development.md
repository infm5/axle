# Development

Workspace tooling for contributors. Canonical command:

```sh
dart pub get
dart run melos run check   # analyze + test + format + spec freshness
```

## Melos scripts

| Script | Command | Scope |
| --- | --- | --- |
| `analyze` | `dart analyze packages` | Every package; examples under `examples/` run their own `check-*-example` script |
| `test` | `dart test` per package with a `test/` dir | `axle_core`, `axle_cli`, `axle_relic`, `axle_shelf`, `axle_serverpod` |
| `format` | `dart format --output=none --set-exit-if-changed .` | Whole workspace |
| `gen-check` | `axle gen --check` | Relic example |
| `gen-check-shelf` | `axle gen --check` | Shelf example |
| `check-serverpod-example` | `dart pub get`, `dart analyze`, `axle gen --check` | Serverpod example (nested workspace) |
| `check-dart-mappable-example` | `dart pub get`, `dart analyze`, `axle gen --check` | `examples/dart_mappable` |
| `check-freezed-example` | Activates `axle_cli` globally, then the same three steps | `examples/freezed_unions` |
| `check-showcase-example` | `dart pub get`, `dart analyze`, `axle gen --check`, `dart test` | `examples/showcase` (its conformance test) |
| `coverage` | `test_with_coverage` per package → `coverage/lcov.info` | Codecov-compatible LCOV |
| `check` | All of the above in order | — |

## CI

`.github/workflows/ci.yml` runs on every push and pull request: checkout, stable
Dart, `dart pub get`, `dart run melos run check`, the documentation build,
Redocly validation, and coverage upload. It validates only. Publishing is handled
by one tag workflow (`publish.yml`) using GitHub OIDC; no `PUB_CREDENTIALS`
secret is required. Push a per-package tag (`axle_core-v0.3.0`, …) and only that
package is verified and published. The tag must point at `master` and match the
package version. Tags pushed together publish side by side, and every package
except `axle_core` waits for `axle_core` to appear on pub.dev first.

Redocly lints two sets of specs. The example specs use `redocly.yaml` at the
repository root, and the golden specs use
`packages/axle_cli/test/golden/redocly.yaml`. Each config lists the rules it
turns off and why.

## Golden specs

`packages/axle_cli/test/golden/` holds a generated spec for each supported Dart
shape. `golden_test.dart` regenerates them from `test/fixtures/` and compares.
After an intended change, rewrite the files and review the diff, because it is the
contract:

```sh
cd packages/axle_cli
AXLE_UPDATE_GOLDEN=1 dart test test/golden_test.dart
```

## Conventions

- Keep every package at its declared version; adapters constrain
  `axle_core: ^0.3.0`, never the CLI.
- Generator errors must name the offending symbol, carry a source location
  (`locationOf(element)`), and use the correct sysexits code
  (`64` / `65` / `70` / `78`).
- Generated example artifacts are committed; `gen --check` is the freshness gate.
- The Serverpod example is a self-contained nested workspace. Keep it out of the
  outer pub workspace and validate it with `melos run check-serverpod-example`.
- `examples/` holds standalone packages with their own dependencies, because
  `build_runner` generators and `axle_cli` cannot always share one resolution.
  Each has a `pubspec_overrides.yaml` that points at the local packages.
- No example unit tests. The examples are integration demos, checked by
  `gen --check` and by comparing the spec with real responses.
- Dart floors stay split: core lowest, analyzer-based CLI highest. Do not raise
  an adapter's floor to the CLI's.
