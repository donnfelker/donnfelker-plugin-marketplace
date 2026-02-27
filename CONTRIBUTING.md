# Contributing

Thanks for your interest in contributing to this plugin marketplace! This guide will help you add new plugins or improve existing ones.

## Requesting a Plugin

You can suggest new plugins by [opening an issue](https://github.com/donnfelker/donnfelker-plugin-marketplace/issues/new).

## Adding a New Plugin

### 1. Create the plugin directory

```bash
mkdir -p plugins/your-plugin-name/.claude-plugin
mkdir -p plugins/your-plugin-name/skills/your-skill-name
```

### 2. Create the plugin manifest

Every plugin needs a `.claude-plugin/plugin.json`:

```json
{
  "name": "your-plugin-name",
  "description": "Brief description of what the plugin does",
  "version": "1.0.0"
}
```

### 3. Create a skill

Each skill needs a `SKILL.md` file with YAML frontmatter:

```yaml
---
name: your-skill-name
description: When to use this skill. Include trigger phrases and keywords that help agents identify relevant tasks.
---

# Your Skill Name

Instructions for the agent go here...
```

### 4. Follow the naming conventions

- **Directory name**: lowercase, kebab-case (e.g., `git-commit`)
- **Name field**: must match directory name exactly
- **Description**: include trigger phrases for reliable activation

### 5. Structure your plugin

```
plugins/your-plugin-name/
├── .claude-plugin/
│   └── plugin.json        # Required - plugin manifest
├── skills/                # Skill definitions
│   └── your-skill/
│       └── SKILL.md
├── commands/              # Optional - slash commands
├── agents/                # Optional - subagent definitions
└── hooks/                 # Optional - event hooks
```

### 6. Update the marketplace

Add your plugin to `.claude-plugin/marketplace.json`:

```json
{
  "name": "your-plugin-name",
  "source": "./plugins/your-plugin-name",
  "description": "Brief description"
}
```

And add it to the table in `README.md` and `CHANGELOG.md`.

## Improving Existing Plugins

1. Read the existing plugin thoroughly
2. Test your changes locally
3. Keep changes focused and minimal
4. Update the version in `plugin.json` if making significant changes

## Submitting Your Contribution

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/new-plugin-name`)
3. Make your changes
4. Test locally with Claude Code
5. Submit a pull request

## Plugin Quality Checklist

- [ ] `name` in `plugin.json` matches directory name
- [ ] Skill `description` clearly explains when to use it
- [ ] Instructions are clear and actionable
- [ ] No sensitive data or credentials
- [ ] Follows existing plugin patterns in the repo
- [ ] Added to `marketplace.json`
- [ ] Added to `README.md` plugins table
- [ ] Added to `CHANGELOG.md`

## Questions?

Open an issue if you have questions or need help with your contribution.
