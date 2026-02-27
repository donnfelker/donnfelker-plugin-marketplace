# Engineering Plugins for Claude Code

A collection of Claude Code plugins for common engineering workflows and use cases. Each plugin can be installed independently — pick only what you need.

Built by [Donn Felker](https://donnfelker.com).

**Contributions welcome!** Found a way to improve a plugin or have a new one to add? [Open a PR](#contributing).

Run into a problem or have a question? [Open an issue](https://github.com/donnfelker/donnfelker-plugin-marketplace/issues).

## What are Plugins?

Plugins are packages of skills, commands, agents, and hooks that extend Claude Code with specialized capabilities. Each plugin in this marketplace focuses on a specific engineering workflow and can be installed independently.

## How Plugins Work

Unlike a single monolithic plugin, each plugin here is independent. Install only what you need for your workflow.

```
donnfelker-plugins (marketplace)
│
├── Git & Dev Workflow
│   └── git-commit
│
├── Documentation (coming soon)
│
├── Code Review (coming soon)
│
├── Technical Analysis (coming soon)
│
└── Presentations & Media (coming soon)
```

## Available Plugins

<!-- PLUGINS:START -->
| Plugin | Description |
|--------|-------------|
| [git-commit](plugins/git-commit/) | Git commit formatting skill based on Chris Beams' seven rules of great git commit messages |
<!-- PLUGINS:END -->

## Installation

### Option 1: CLI Install (Recommended)

Use [npx skills](https://github.com/vercel-labs/skills) to install skills directly:

```bash
# Install all plugins
npx skills add donnfelker/donnfelker-plugin-marketplace

# Install specific plugins
npx skills add donnfelker/donnfelker-plugin-marketplace --skill git-commit

# List available plugins
npx skills add donnfelker/donnfelker-plugin-marketplace --list
```

This automatically installs to your `.claude/skills/` directory.

### Option 2: Claude Code Plugin

Install via Claude Code's built-in plugin system:

```bash
# Add the marketplace
/plugin marketplace add donnfelker/donnfelker-plugin-marketplace

# Install a specific plugin
/plugin install git-commit@donnfelker-plugins
```

### Option 3: Clone and Copy

Clone the repo and copy the plugins you want:

```bash
git clone https://github.com/donnfelker/donnfelker-plugin-marketplace.git
cp -r donnfelker-plugin-marketplace/plugins/git-commit .claude/plugins/
```

### Option 4: Git Submodule

Add as a submodule for easy updates:

```bash
git submodule add https://github.com/donnfelker/donnfelker-plugin-marketplace.git .claude/donnfelker-plugins
```

Then reference plugins from `.claude/donnfelker-plugins/plugins/`.

### Option 5: Fork and Customize

1. Fork this repository
2. Customize plugins for your specific needs
3. Clone your fork into your projects

### Option 6: SkillKit (Multi-Agent)

Use [SkillKit](https://github.com/rohitg00/skillkit) to install skills across multiple AI agents (Claude Code, Cursor, Copilot, etc.):

```bash
# Install all plugins
npx skillkit install donnfelker/donnfelker-plugin-marketplace

# Install specific plugins
npx skillkit install donnfelker/donnfelker-plugin-marketplace --skill git-commit

# List available plugins
npx skillkit install donnfelker/donnfelker-plugin-marketplace --list
```

## Usage

Once installed, just use the skills naturally:

```
"Commit this"
→ Uses git-commit plugin

"Write a commit message for these changes"
→ Uses git-commit plugin
```

Or invoke skills directly:

```
/git-commit-formatter
```

## Plugin Categories

### Git & Dev Workflow
- `git-commit` — Commit message formatting based on Chris Beams' seven rules

### Documentation
- Coming soon

### Code Review
- Coming soon

### Technical Analysis
- Coming soon

### Presentations & Media
- Coming soon

## Contributing

Found a way to improve a plugin? Have a new one to suggest? PRs and issues welcome!

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

[MIT](LICENSE) — use these however you want.
