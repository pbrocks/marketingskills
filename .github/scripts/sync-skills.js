#!/usr/bin/env node
/**
 * Sync README.md and plugin.json with the skills directory.
 *
 * Scans the skills/ directory for valid skills (directories containing SKILL.md)
 * and updates the README skills table to match. Also syncs plugin.json's `version`
 * field from the canonical root VERSION file.
 *
 * Note: this fork does not ship a marketplace.json; it is not distributed as a
 * Claude Code plugin marketplace.
 */

const fs = require("fs");
const path = require("path");

const SKILLS_DIR = "skills";
const PLUGIN_FILE = ".claude-plugin/plugin.json";
const VERSION_FILE = "VERSION";
const README_FILE = "README.md";

/**
 * Parse YAML frontmatter from a SKILL.md file
 */
function parseFrontmatter(content) {
  const match = content.match(/^---\n([\s\S]*?)\n---/);
  if (!match) return {};

  const frontmatter = {};
  const lines = match[1].split("\n");

  for (const line of lines) {
    const colonIndex = line.indexOf(":");
    if (colonIndex === -1) continue;

    const key = line.slice(0, colonIndex).trim();
    let value = line.slice(colonIndex + 1).trim();

    // Remove quotes if present
    if ((value.startsWith('"') && value.endsWith('"')) ||
        (value.startsWith("'") && value.endsWith("'"))) {
      value = value.slice(1, -1);
    }

    frontmatter[key] = value;
  }

  return frontmatter;
}

/**
 * Get all skills with their metadata
 */
function getSkillsWithMetadata() {
  if (!fs.existsSync(SKILLS_DIR)) {
    return [];
  }

  return fs
    .readdirSync(SKILLS_DIR, { withFileTypes: true })
    .filter((entry) => {
      if (!entry.isDirectory()) return false;
      const skillFile = path.join(SKILLS_DIR, entry.name, "SKILL.md");
      return fs.existsSync(skillFile);
    })
    .map((entry) => {
      const skillFile = path.join(SKILLS_DIR, entry.name, "SKILL.md");
      const content = fs.readFileSync(skillFile, "utf8");
      const frontmatter = parseFrontmatter(content);

      return {
        dir: entry.name,
        path: `./${SKILLS_DIR}/${entry.name}`,
        name: frontmatter.name || entry.name,
        description: frontmatter.description || "",
      };
    })
    .sort((a, b) => a.name.localeCompare(b.name));
}

/**
 * Truncate description to a maximum length
 */
function truncateDescription(description, maxLength = 120) {
  if (description.length <= maxLength) return description;

  // Find last space before maxLength to avoid cutting words
  const truncated = description.slice(0, maxLength);
  const lastSpace = truncated.lastIndexOf(" ");

  return truncated.slice(0, lastSpace) + "...";
}

/**
 * Generate the skills table for README
 */
function generateSkillsTable(skills) {
  const header = "| Skill | Description |\n|-------|-------------|";
  const rows = skills.map((skill) => {
    const link = `[${skill.name}](skills/${skill.dir}/)`;
    const description = truncateDescription(skill.description);
    return `| ${link} | ${description} |`;
  });

  return [header, ...rows].join("\n");
}

/**
 * Update README.md with new skills table
 */
function updateReadme(skills) {
  const content = fs.readFileSync(README_FILE, "utf8");

  // Match content between skill list markers
  const tableRegex = /(<!-- SKILLS:START -->\n)[\s\S]*?(\n<!-- SKILLS:END -->)/;
  const newTable = generateSkillsTable(skills);

  if (!tableRegex.test(content)) {
    console.log("WARNING: Could not find skill markers in README.md");
    return false;
  }

  const newContent = content.replace(tableRegex, `$1${newTable}$2`);

  if (newContent === content) {
    return false;
  }

  fs.writeFileSync(README_FILE, newContent);
  return true;
}

/**
 * Update plugin.json's `version` field to match the canonical root VERSION file.
 * Claude Code uses plugin.json's version for the update check
 * (`claude plugin update`); if it drifts from VERSION the update path silently
 * breaks.
 */
function updatePluginVersion() {
  if (!fs.existsSync(PLUGIN_FILE) || !fs.existsSync(VERSION_FILE)) {
    return { updated: false };
  }

  const version = fs.readFileSync(VERSION_FILE, "utf8").trim();
  const plugin = JSON.parse(fs.readFileSync(PLUGIN_FILE, "utf8"));

  if (!version) return { updated: false };
  if (plugin.version === version) return { updated: false };

  const oldVersion = plugin.version;
  plugin.version = version;
  fs.writeFileSync(PLUGIN_FILE, JSON.stringify(plugin, null, 2) + "\n");
  return { updated: true, oldVersion, newVersion: version };
}

function main() {
  const skills = getSkillsWithMetadata();

  const readmeUpdated = updateReadme(skills);
  const pluginResult = updatePluginVersion();

  if (!readmeUpdated && !pluginResult.updated) {
    console.log("Everything is already in sync");
    return;
  }

  if (pluginResult.updated) {
    console.log(`Bumped plugin.json version: ${pluginResult.oldVersion} → ${pluginResult.newVersion}`);
  }

  if (readmeUpdated) {
    console.log("Updated README.md skills table");
  }
}

main();
