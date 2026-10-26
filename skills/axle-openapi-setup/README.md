# axle-openapi-setup

Agent skill for adding **OpenAPI 3.1 documentation to Dart HTTP APIs** with
[axle](https://github.com/infm5/axle).

It covers the full path from install to useful docs:

- install `axle_core`, `axle_cli`, and the right adapter
- initialize and configure `axle.yaml`
- model DTOs and schemas
- annotate routes, parameters, bodies, responses, headers, cookies, security,
  media types, multipart uploads, and `oneOf`
- generate JSON/YAML/Dart artifacts and local Swagger UI assets
- mount docs in Relic, Shelf, Serverpod 4 web routes, or a custom adapter
- verify generated specs and improve documentation quality

## Install

```sh
npx skills add infm5/axle --skill axle-openapi-setup
```

Install from the full GitHub URL:

```sh
npx skills add https://github.com/infm5/axle --skill axle-openapi-setup
```

List the skills in the repository without installing:

```sh
npx skills add infm5/axle --list
```

## Use when

- Adding OpenAPI or Swagger docs to a Dart server.
- Documenting Relic, Shelf, or Serverpod web-server routes.
- Configuring `axle.yaml` or `axle_cli`.
- Adding security schemes or route-level security requirements.
- Generating `openapi.json`, `openapi.yaml`, Swagger UI, or `openapi.g.dart`.
- Troubleshooting missing routes, stale artifacts, or blank docs UI.

## Compatibility

Requires a Dart project and the Dart SDK. Package installation and Redocly
validation need network access. The skill targets axle 0.3.x; Serverpod support
is limited to web-server `Route`s, not API-server `Endpoint` RPC methods.

## Distribution

GitHub is the canonical source. There is no separate tarball to upload to
skills.sh; it indexes public skills installed through the `skills` CLI.

- **skills.sh:** publish the public repo, then run
  `npx skills add infm5/axle --skill axle-openapi-setup` once to install and
  trigger indexing.
- **agentskill.sh:** submit the direct skill URL below at
  <https://agentskill.sh/submit> to import only this skill. Importing the repo
  URL scans every `SKILL.md` in the monorepo.
  `https://raw.githubusercontent.com/infm5/axle/master/skills/axle-openapi-setup/SKILL.md`
- **agentskills.io:** this is the Agent Skills specification, not a separate
  upload target. Validate with `npx skills-ref validate ./skills/axle-openapi-setup`.

## Source

- Repository: https://github.com/infm5/axle
- Skill instructions: [`SKILL.md`](SKILL.md)
- License: MIT
