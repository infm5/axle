# axle docs

VitePress site for axle. Source lives here in `doc/`; the `docs/` directory at
the repo root holds the internal design notes this site is built from.

## Develop

```sh
cd doc
npm install
npm run docs:dev
```

## Build

```sh
cd doc
npm run docs:build   # output in doc/.vitepress/dist
npm run docs:preview
```

## Layout

- `guide/` — introduction, getting started, how it works, examples.
- `packages/` — one page per package (`core`, `cli`, `relic`, `shelf`, `serverpod`) plus an overview.
- `adapters/` — how to build an adapter for another framework.
- `reference/` — `axle.yaml` and annotation/DTO-mapping references.
