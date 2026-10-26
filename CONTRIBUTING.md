# Contributing to axle

Thanks for helping. axle is small and the maintainers read every issue.

## Good first issues

- A fixture and golden spec for a Dart shape that axle gets wrong
  (see `packages/axle_cli/test/fixtures` and `test/golden`).
- An adapter for another framework; start with
  [`docs/adapter-authoring.md`](docs/adapter-authoring.md).
- Docs fixes: anything on https://axle.infms.dev that is unclear or out of date.

If you are unsure whether something fits, open an issue first.

## Setup

```sh
dart pub get
dart run melos run check   # analyze + test + format + spec freshness
```

`melos run check` is what CI runs. Individual scripts: `analyze`, `test`,
`format`, `gen-check`, `gen-check-shelf`, `check-serverpod-example`, `coverage`.

## Changing the generator

1. Add a fixture under `packages/axle_cli/test/fixtures/<name>/` that shows the
   Dart shape.
2. Add it to `_fixtures` in `packages/axle_cli/test/golden_test.dart` and write
   the golden with `AXLE_UPDATE_GOLDEN=1 dart test test/golden_test.dart`.
   Review the diff of `test/golden/<name>.json`; it is the contract.
3. Add assertions for the parts that matter in a focused test.
4. Update the docs in `doc/`, the README, and the package `CHANGELOG.md`.

Errors must carry a location (`locationOf(element)`), and unsupported input
should fail loudly instead of guessing.

## Validating generated specs

CI lints the example specs and the golden specs with Redocly:

```sh
npx @redocly/cli@2.71.0 lint packages/axle_relic/example/openapi.json --config redocly.yaml
npx @redocly/cli@2.71.0 lint packages/axle_cli/test/golden/*.json --config packages/axle_cli/test/golden/redocly.yaml
```

Rule exceptions live in those config files, each with its reason.
