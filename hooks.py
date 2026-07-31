"""
MkDocs hooks for the Marketing Skills docs.

Two build-time behaviors:

1. Version injection — replace {{ project_version }} in every page with the repo
   release version (canonical source: the root VERSION file).

2. Auto-nav for skills and tools — the docs/skills and docs/tools symlinks point at
   the repo's skills/ and tools/ trees. Rather than hand-list ~300 pages in
   mkdocs.yml, on_config appends a "Skills" section and a "Tools" section to the nav,
   generated from those trees. New skills/tools appear automatically with no config
   edits.
"""

import json
import os
import re

DOCS_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "docs")

# Files treated as a folder's landing page, in priority order.
_INDEX_NAMES = ("SKILL.md", "index.md", "README.md")


# ── Version injection ────────────────────────────────────────────────────────


def get_project_version():
    """Read the version from common project version sources."""
    project_root = os.path.dirname(os.path.abspath(__file__))

    # package.json (Node / npm)
    pkg = os.path.join(project_root, "package.json")
    if os.path.isfile(pkg):
        with open(pkg) as f:
            data = json.load(f)
        if "version" in data:
            return data["version"]

    # composer.json (PHP / Laravel)
    composer = os.path.join(project_root, "composer.json")
    if os.path.isfile(composer):
        with open(composer) as f:
            data = json.load(f)
        if "version" in data:
            return data["version"]

    # pyproject.toml (Python)
    pyproject = os.path.join(project_root, "pyproject.toml")
    if os.path.isfile(pyproject):
        with open(pyproject) as f:
            for line in f:
                m = re.match(r'^version\s*=\s*["\']([^"\']+)["\']', line)
                if m:
                    return m.group(1)

    # Plain VERSION file
    version_file = os.path.join(project_root, "VERSION")
    if os.path.isfile(version_file):
        return open(version_file).read().strip()

    return "unknown"


PROJECT_VERSION = get_project_version()


def on_page_markdown(markdown, **kwargs):
    """Replace {{ project_version }} in every page before rendering."""
    return markdown.replace("{{ project_version }}", PROJECT_VERSION)


# ── Auto-nav generation ──────────────────────────────────────────────────────


def _prettify(name):
    """Turn a directory or file stem into a human-readable title."""
    words = re.split(r"[-_]", name)
    out = []
    for w in words:
        if not w:
            continue
        # Preserve short all-caps-ish tokens (e.g. CRO, SMS, ASO, GA4, GTM).
        if len(w) <= 4 and (w.isupper() or w.isdigit() or re.fullmatch(r"[a-z0-9]+", w) and any(c.isdigit() for c in w)):
            out.append(w.upper())
        else:
            out.append(w[:1].upper() + w[1:])
    return " ".join(out) if out else name


def _first_h1(abs_path):
    """Return the first ATX H1 in a markdown file, skipping frontmatter and code fences."""
    try:
        with open(abs_path, encoding="utf-8") as f:
            lines = f.readlines()
    except OSError:
        return None

    in_frontmatter = False
    in_fence = False
    for i, raw in enumerate(lines):
        line = raw.rstrip("\n")
        if i == 0 and line.strip() == "---":
            in_frontmatter = True
            continue
        if in_frontmatter:
            if line.strip() == "---":
                in_frontmatter = False
            continue
        if line.lstrip().startswith("```"):
            in_fence = not in_fence
            continue
        if in_fence:
            continue
        m = re.match(r"#\s+(.+?)\s*#*\s*$", line)
        if m:
            return m.group(1).strip()
    return None


def _page_title(abs_path, fallback_stem):
    """Best title for a page: first H1, else prettified filename stem."""
    return _first_h1(abs_path) or _prettify(fallback_stem)


def _list_md(abs_dir):
    """Return (subdirs, md_files) for a directory, each sorted by name."""
    subdirs, md_files = [], []
    for entry in sorted(os.listdir(abs_dir)):
        if entry.startswith("."):
            continue
        full = os.path.join(abs_dir, entry)
        if os.path.isdir(full):
            subdirs.append(entry)
        elif entry.endswith(".md"):
            md_files.append(entry)
    return subdirs, md_files


def _build_section(abs_dir, rel_dir):
    """
    Recursively build a MkDocs nav list mirroring a directory tree.

    rel_dir is the path relative to docs_dir, using forward slashes, so nav entries
    resolve correctly. A folder's landing page (SKILL.md / index.md / README.md) is
    emitted first as "Overview"; remaining files and subfolders follow, sorted.
    """
    subdirs, md_files = _list_md(abs_dir)
    items = []

    # Landing page first, labeled "Overview".
    index_file = next((n for n in _INDEX_NAMES if n in md_files), None)
    if index_file:
        md_files.remove(index_file)
        items.append({"Overview": f"{rel_dir}/{index_file}"})

    # Nested folders (references, evals, integrations, ...) as sub-sections.
    for sub in subdirs:
        child = _build_section(os.path.join(abs_dir, sub), f"{rel_dir}/{sub}")
        if child:
            items.append({_prettify(sub): child})

    # Remaining loose markdown files.
    for name in md_files:
        stem = name[:-3]
        title = _page_title(os.path.join(abs_dir, name), stem)
        items.append({title: f"{rel_dir}/{name}"})

    return items


def _skills_section():
    """Build the 'Skills' nav section: one collapsible entry per skill."""
    skills_dir = os.path.join(DOCS_DIR, "skills")
    if not os.path.isdir(skills_dir):
        return None

    entries = []
    for name in sorted(os.listdir(skills_dir)):
        abs_dir = os.path.join(skills_dir, name)
        if name.startswith(".") or not os.path.isdir(abs_dir):
            continue
        section = _build_section(abs_dir, f"skills/{name}")
        if not section:
            continue
        # A skill with only an Overview collapses to a single page entry.
        if len(section) == 1 and "Overview" in section[0]:
            entries.append({_prettify(name): section[0]["Overview"]})
        else:
            entries.append({_prettify(name): section})
    return entries or None


def _tools_section():
    """Build the 'Tools' nav section from the tools/ tree, led by the overview page."""
    tools_dir = os.path.join(DOCS_DIR, "tools")
    if not os.path.isdir(tools_dir):
        return None

    items = []
    if os.path.isfile(os.path.join(DOCS_DIR, "tools.md")):
        items.append({"Overview": "tools.md"})
    items.extend(_build_section(tools_dir, "tools"))
    return items or None


def on_config(config):
    """Append auto-generated Skills and Tools sections to the configured nav."""
    nav = config.get("nav")
    if not isinstance(nav, list):
        return config

    # Drop any placeholder Skills/Tools entries so we don't duplicate.
    def _key(item):
        return next(iter(item)) if isinstance(item, dict) else None

    nav = [item for item in nav if _key(item) not in ("Skills", "Tools")]

    skills = _skills_section()
    if skills:
        nav.append({"Skills": skills})

    tools = _tools_section()
    if tools:
        nav.append({"Tools": tools})

    config["nav"] = nav
    return config
