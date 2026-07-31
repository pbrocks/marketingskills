# Marketing Skills v{{ project_version }}

Documentation for the **Marketing Skills** repository — a collection of
[Agent Skills](https://agentskills.io/specification.md) for AI agents, focused on
marketing tasks: conversion optimization, copywriting, SEO, paid ads, ad creative,
and growth engineering.

This is a **fork** maintained for internal use — it is not distributed as a Claude
Code plugin marketplace. It keeps `.claude-plugin/plugin.json` as the plugin manifest
but has no `marketplace.json`; install skills by copying into `.agents/skills/`.

- **Creator:** Corey Haines
- **GitHub:** [coreyhaines31/marketingskills](https://github.com/coreyhaines31/marketingskills)
- **License:** MIT

## Purpose of These Docs

The `docs/` directory is both human-readable team documentation and a persistent
context window for AI agent sessions. Point an agent at the relevant page at the
start of a session so it loads the right context without re-explanation.

`AGENTS.md` (symlinked as `CLAUDE.md`) holds standing conventions; these docs hold
depth — architecture, versioning rules, and the tools registry.

!!! note "Fork, not a marketplace"
    This is a fork for internal use. It is not published as a Claude Code plugin
    marketplace and has no `marketplace.json`. Use the skills by copying them into
    `.agents/skills/`.

## Repository Structure

```
marketingskills/
├── .claude-plugin/
│   └── plugin.json        # Plugin manifest (version synced from VERSION)
├── VERSION                # Canonical repo release version (x.y.z)
├── skills/                # Agent Skills (one directory per skill, each with SKILL.md)
├── tools/
│   ├── clis/              # Zero-dependency Node.js CLI tools
│   ├── composio/          # Composio integration layer
│   ├── integrations/      # Per-tool API integration guides
│   └── REGISTRY.md        # Tool index with capabilities
├── docs/                  # This documentation (MkDocs)
├── AGENTS.md              # Agent guidelines (CLAUDE.md → symlink)
├── VERSIONS.md            # Changelog + per-skill version table
├── CONTRIBUTING.md
├── LICENSE
└── README.md
```

## Where to Look Next

- [Architecture](architecture.md) — how skills relate and the `product-marketing` foundation
- [Versioning](versioning.md) — the two-layer version scheme and when to bump each
- [Tools](tools.md) — the tools registry and integration guides

## Serving & Deploying These Docs

```bash
./mkdocs-serve.sh        # local live-reload preview on http://127.0.0.1:8000
./mkdocs-deploy.sh       # build + rsync deploy (requires DOCS_SSH_* in root .env)
mkdocs build --clean     # build only, output to site/
```
