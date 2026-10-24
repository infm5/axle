# Development

Workspace tooling for contributors. Canonical command:

```sh
dart pub get
dart run melos run check   # analyze + test + format + spec freshness
```

## Melos scripts

| Script | Command | Scope |
| --- | --- | --- |
| `analyze` | `dart analyze` | Whole workspace |
| `test` | `dart test` per package with a `test/` dir | `axle_core`, `axle_cli`, `axle_relic`, `axle_shelf`, `axle_serverpod` |
| `format` | `dart format --output=none --set-exit-if-changed .` | Whole workspace |
| `gen-check` | `axle gen --check` | Relic example |
| `gen-check-shelf` | `axle gen --check` | Shelf example |
| `check-serverpod-example` | `dart pub get`, `dart analyze`, `axle gen --check` | Serverpod example (nested workspace) |
| `coverage` | `test_with_coverage` per package → `coverage/lcov.info` | Codecov-compatible LCOV |
| `check` | All of the above in order | — |

## CI

`.github/workflows/ci.yml` runs on every push and pull request: checkout, stable
Dart, `dart pub get`, `dart run melos run check`. It validates only —
publishing is handled by per-package tag workflows (`publish-axle_*.yml`)
using GitHub OIDC; no `PUB_CREDENTIALS` secret is required. Per-package tags
(`axle_core-v0.2.0`, …) point at `master` and match the package version.

## Conventions

- Keep every package at its declared version; adapters constrain
  `axle_core: ^0.2.0`, never the CLI.
- Generator errors must name the offending symbol and carry the correct
  sysexits code (`64` / `65` / `70` / `78`).
- Generated example artifacts are committed; `gen --check` is the freshness gate.
- The Serverpod example is a self-contained nested workspace. Keep it out of the
  outer pub workspace and validate it with `melos run check-serverpod-example`.
- No example unit tests — the examples are integration demos.
- Dart floors stay split: core lowest, analyzer-based CLI highest. Do not raise
  an adapter's floor to the CLI's.
