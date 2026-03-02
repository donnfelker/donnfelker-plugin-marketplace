# Output Format Templates

## Release Notes Format

Use the following template for `RELEASE_NOTES.md`:

```markdown
# Release Notes — v{VERSION}

**Release Date:** {YYYY-MM-DD}

{One-paragraph summary of the release highlighting the most significant changes.}

## BREAKING CHANGES

{Only include this section if there are breaking changes.}

- **{scope}:** {description} — {migration note from BREAKING CHANGE footer or body}

## Features

- **{scope}:** {description} ({short-hash})
- {description (no scope)} ({short-hash})

## Bug Fixes

- **{scope}:** {description} ({short-hash})

## Performance Improvements

- **{scope}:** {description} ({short-hash})

## Documentation

- **{scope}:** {description} ({short-hash})

{Continue with remaining non-empty sections in standard order...}

---

**Full Changelog:** {link to compare view if remote URL available, e.g., https://github.com/org/repo/compare/v1.0.0...v2.0.0}
```

### Release Notes Rules

1. Include a brief summary paragraph at the top describing the release theme
2. Only include sections that have entries — omit empty sections entirely
3. Use the 7-character short hash in parentheses for each entry
4. When a scope is present, bold it and follow with a colon
5. Breaking changes appear both in the dedicated section AND in their type section
6. In the breaking changes section, include migration context from the BREAKING CHANGE footer or commit body
7. Link issue/PR references from `Refs:` footers as `#number`
8. End with a full changelog comparison link if a git remote URL is available

## Changelog Format

Use the following template for entries prepended to `CHANGELOG.md`:

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [{VERSION}] — {YYYY-MM-DD}

### BREAKING CHANGES

- **{scope}:** {description} — {migration note}

### Added

- **{scope}:** {description} ({short-hash})

### Fixed

- **{scope}:** {description} ({short-hash})

### Changed

- **{scope}:** {description} ({short-hash})

### Removed

- {description} ({short-hash})

### Other

- {description} ({short-hash})

[{VERSION}]: https://github.com/org/repo/compare/{PREV_TAG}...v{VERSION}
```

### Changelog Section Mapping

The changelog uses [Keep a Changelog](https://keepachangelog.com/) section names:

| Commit Type | Changelog Section |
|-------------|------------------|
| feat | Added |
| fix | Fixed |
| perf | Changed |
| refactor | Changed |
| docs | Changed |
| style | Changed |
| build | Changed |
| ci | Changed |
| test | Changed |
| chore | Other |
| revert | Changed (use Removed only when the revert undoes a previously added feature) |
| other | Other |

### Changelog Rules

1. The file header (title + description) is only written when creating a new `CHANGELOG.md`
2. When appending to an existing file, insert the new version block after the header and before existing entries
3. Use Keep a Changelog section names (Added, Fixed, Changed, Removed, Other)
4. Only include sections that have entries
5. Include the comparison link at the bottom of each version block
6. Breaking changes appear in the dedicated section AND in their mapped section
7. Maintain reverse chronological order (newest version at top)
8. Preserve the `[Unreleased]` section if one exists in the file

## Example: Complete Release Notes

```markdown
# Release Notes — v2.1.0

**Release Date:** 2026-03-02

This release introduces Polish language support and fixes a critical rate
limiting issue on public API endpoints. One breaking change affects
authentication — see migration notes below.

## BREAKING CHANGES

- **auth:** Replace session-based auth with JWT tokens — Clients must update
  to handle the token refresh flow. Session cookies are no longer issued or
  accepted. See the migration guide in docs/auth-migration.md.

## Features

- **auth:** Replace session-based auth with JWT tokens (a1b2c3d)
- **lang:** Add Polish language support (e4f5g6h)
- Add dark mode toggle to settings page (i7j8k9l)

## Bug Fixes

- **api:** Add rate limiting to public endpoints (m0n1o2p)
- **http:** Prevent racing of concurrent requests (q3r4s5t)

## Documentation

- Correct spelling in CHANGELOG (u6v7w8x)

---

**Full Changelog:** https://github.com/org/repo/compare/v2.0.0...v2.1.0
```

## Example: Complete Changelog Entry

```markdown
## [2.1.0] — 2026-03-02

### BREAKING CHANGES

- **auth:** Replace session-based auth with JWT tokens — Clients must update
  to handle the token refresh flow. Session cookies are no longer issued or
  accepted.

### Added

- **auth:** Replace session-based auth with JWT tokens (a1b2c3d)
- **lang:** Add Polish language support (e4f5g6h)
- Add dark mode toggle to settings page (i7j8k9l)

### Fixed

- **api:** Add rate limiting to public endpoints (m0n1o2p)
- **http:** Prevent racing of concurrent requests (q3r4s5t)

### Changed

- Correct spelling in CHANGELOG (u6v7w8x)

[2.1.0]: https://github.com/org/repo/compare/v2.0.0...v2.1.0
```

## Scope Grouping (Optional)

When multiple entries share a scope within a section, group them:

```markdown
## Features

- **auth:**
  - Replace session-based auth with JWT tokens (a1b2c3d)
  - Add remember-me checkbox to login form (y9z0a1b)
- **lang:** Add Polish language support (e4f5g6h)
- Add dark mode toggle to settings page (i7j8k9l)
```

Apply scope grouping when 3 or more entries share the same scope within a single section. For fewer entries, keep them as flat list items with bold scope prefix.

## Git Remote URL Detection

To generate comparison links, detect the remote URL:

```bash
git remote get-url origin 2>/dev/null
```

Convert SSH URLs to HTTPS:
- `git@github.com:org/repo.git` → `https://github.com/org/repo`
- `https://github.com/org/repo.git` → `https://github.com/org/repo`

If no remote is configured, omit the comparison link.
