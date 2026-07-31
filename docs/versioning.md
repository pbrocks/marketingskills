# Versioning

There are **two version layers**, with different rules.

## Repo Release Version

The canonical `x.y.z` number lives in the root `VERSION` file. It is mirrored in:

- `.claude-plugin/plugin.json` → `version` (synced automatically from `VERSION` by
  `.github/scripts/sync-skills.js`)

- `VERSIONS.md` changelog headings

Bump rules:

- **x** — repo-wide changes (restructures, spec changes, breaking changes)
- **y** — new skill(s) added
- **z** — updates to existing skills

Content added to an existing skill is a **z** release no matter how substantial —
a new reference file in `ad-creative` is `2.8.0 → 2.8.1`, not `2.9.0`.

Bump the `VERSION` file in the **same PR** that ships the change; `plugin.json`
follows automatically via the sync script.

!!! note "Docs version source"
    These MkDocs pages read the repo release version from the root `VERSION` file
    via `hooks.py`, and inject it wherever `{{ project_version }}` appears.
    Current version: **{{ project_version }}**.

## Per-Skill Version

Each `SKILL.md` carries `metadata.version`, mirrored in the `VERSIONS.md` table.

Bump on **any** shipped change to that skill:

- **minor** — new capability or new description triggers
- **patch** — fixes and clarifications

The update check compares `VERSIONS.md` against users' local skill metadata, so an
unbumped change is invisible to installed users.

## Checking for Updates

When using any skill from this repo, once per session on first skill use:

1. Fetch `VERSIONS.md` from GitHub:
   `https://raw.githubusercontent.com/coreyhaines31/marketingskills/main/VERSIONS.md`

2. Compare against local skill files.
3. Only prompt if **2+ skills** have updates, or **any** skill has a major version bump.
4. If the user says "update skills", run `git pull` in the marketingskills directory.
