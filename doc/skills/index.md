# Agent skills

axle ships agent skills alongside the framework packages. A skill is a
`SKILL.md` file plus focused references that tells a coding agent how to add
and maintain OpenAPI docs in a Dart server.

Skills live in [`skills/`](https://github.com/infm5/axle/tree/master/skills)
at the repo root. They are versioned with axle and validated with
`skills-ref`.

## Available skills

| Skill | What it does |
| --- | --- |
| [`axle-openapi-setup`](/skills/axle-openapi-setup) | Install axle, configure `axle.yaml`, annotate handlers and DTOs, add security, generate artifacts, mount docs, and verify the result. |

## Install

From any project, using the open `skills` CLI:

```sh
npx skills add infm5/axle --skill axle-openapi-setup
```

From the full GitHub URL:

```sh
npx skills add https://github.com/infm5/axle --skill axle-openapi-setup
```

List skills in the repo without installing:

```sh
npx skills add infm5/axle --list
```

The installed skill works with Claude Code, Cursor, Codex, OpenCode,
Windsurf, and other agents that support the open skills format.

## Use when

- Adding OpenAPI or Swagger docs to a Dart server.
- Documenting Relic, Shelf, or Serverpod web-server routes.
- Configuring `axle.yaml` or `axle_cli`.
- Adding security schemes or route-level requirements.
- Generating `openapi.json`, `openapi.yaml`, Swagger UI, or `openapi.g.dart`.
- Troubleshooting missing routes, stale artifacts, or blank docs UI.

## Distribution

GitHub is the canonical source. There is no separate tarball for skills.sh;
it indexes public skills installed through the `skills` CLI.

- **skills.sh:** publish the public repo, then run
  `npx skills add infm5/axle --skill axle-openapi-setup` once to install and
  trigger indexing.
- **agentskill.sh:** submit the direct skill URL at
  `https://agentskill.sh/submit` to import only this skill. Importing the repo
  URL scans every `SKILL.md` in the monorepo:
  `https://raw.githubusercontent.com/infm5/axle/master/skills/axle-openapi-setup/SKILL.md`
- **agentskills.io:** the Agent Skills specification, not a separate upload
  target. Validate locally with
  `npx skills-ref validate ./skills/axle-openapi-setup`.

## Compatibility

Skills target axle `0.3.x`. Steps that need 0.3.0 are marked **(0.3.0)**, for
projects still on `0.2.x`. They require a Dart project with the Dart SDK.
Package installation and Redocly validation need network access. Serverpod
support covers web-server `Route`s, not API-server `Endpoint` RPC methods.

## Source layout

```text
skills/axle-openapi-setup/
├── SKILL.md
├── README.md
├── LICENSE
├── assets/
│   └── axle.yaml
└── references/
    ├── frameworks.md
    ├── annotations-recipes.md
    ├── models.md
    ├── quality-checklist.md
    └── troubleshooting.md
```

The `SKILL.md` body stays under 500 lines. Longer guidance lives in
`references/` and is loaded on demand. Start with
[`axle-openapi-setup`](/skills/axle-openapi-setup) for the full workflow.
