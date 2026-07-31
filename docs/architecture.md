# Architecture

## The `product-marketing` Foundation

The `product-marketing` skill is the foundation of the whole collection. Every other
skill checks it first to understand the product, audience, and positioning before
doing anything. Skills also cross-reference each other and build on shared context —
see each skill's **Related Skills** section for the full dependency map.

## Skill Categories

Skills are grouped into the following categories (see `README.md` for the live list):

- **SEO & Content** — `seo-audit`, `ai-seo`, `site-architecture`, `programmatic-seo`,
  `schema`, `content-strategy`, `aso`

- **CRO** — `cro`, `signup`, `onboarding`, `popups`, `paywalls`
- **Content & Copy** — `copywriting`, `copy-editing`, `cold-email`, `emails`,
  `social`, `video`, `image`, `sms`

- **Paid & Measurement** — `ads`, `ad-creative`, `ab-testing`, `analytics`,
  `attribution`

- **Growth & Retention** — `referrals`, `free-tools`, `churn-prevention`,
  `community-marketing`, `lead-magnets`, `co-marketing`, `marketing-loops`

- **Sales & GTM** — `revops`, `sales-enablement`, `launch`, `pricing`, `competitors`,
  `competitor-profiling`, `directory-submissions`, `prospecting`

- **Strategy** — `marketing-ideas`, `marketing-psychology`, `marketing-plan`,
  `customer-research`, `marketing-council`, `offers`

Cross-references worth noting:

- `copywriting` ↔ `cro` ↔ `ab-testing`
- `revops` ↔ `sales-enablement` ↔ `cold-email`
- `seo-audit` ↔ `schema` ↔ `ai-seo`
- `customer-research` → `copywriting`, `cro`, `competitors`

## Skill Anatomy

Each skill lives in `skills/<skill-name>/` and follows the
[Agent Skills spec](https://agentskills.io/specification.md):

```
skills/skill-name/
├── SKILL.md        # Required — main instructions (<500 lines)
├── references/     # Optional — detailed docs loaded on demand
├── scripts/        # Optional — executable code
└── assets/         # Optional — templates, data files
```

### Frontmatter Constraints

| Field         | Required | Constraints                                                    |
|---------------|----------|----------------------------------------------------------------|
| `name`        | Yes      | 1–64 chars, lowercase `a-z`, numbers, hyphens; must match dir. |
| `description` | Yes      | 1–1024 chars; describe what it does and when to use it.        |
| `license`     | No       | License name (default: MIT).                                   |
| `metadata`    | No       | Key-value pairs (author, version, etc.).                       |

`name` rules: no leading/trailing hyphen, no consecutive hyphens (`--`), must match
the parent directory name exactly.

## Distribution

This is a **fork** for internal use. It does **not** ship a `marketplace.json`, so it
is not installable via the `/plugin marketplace add` → `/plugin install` flow. It keeps
`.claude-plugin/plugin.json` as the plugin manifest for local plugin development.

Install skills by copying them into `.agents/skills/` (the cross-agent standard) so
they work with Claude Code, Codex, Cursor, Windsurf, and any spec-compliant agent.
