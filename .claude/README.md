# Superpowers (Claude Code Skills)

This repo vendors **[Superpowers](https://github.com/obra/superpowers)** v5.1.0 by
Jesse Vincent (`obra`) — the most popular agentic skills framework for Claude Code.

It enforces a real software-development methodology: brainstorm a spec before
coding, write a reviewable plan, do strict red/green TDD, run subagent-driven
development, and verify before claiming done.

## What's installed

- `skills/` — the 14 Superpowers skills, auto-discovered by Claude Code as
  project skills. Invoke them via the `Skill` tool (they also trigger on their own).
- `hooks/session-start` + `hooks/run-hook.cmd` — the SessionStart hook that
  bootstraps awareness of the `using-superpowers` meta-skill at the start of a session.
- `settings.json` — wires the SessionStart hook (cross-platform: Unix + Windows Git Bash).

## Why vendored instead of `/plugin install`

`/plugin install superpowers@superpowers-marketplace` installs at the user level,
which does not persist in ephemeral/CI environments and isn't shared with the team.
Vendoring into `.claude/` makes the skills travel with the repo: anyone who clones
it and opens Claude Code gets Superpowers automatically, no setup required.

## Updating

```bash
git clone --depth 1 https://github.com/obra/superpowers.git /tmp/superpowers
cp -R /tmp/superpowers/skills/. .claude/skills/
cp /tmp/superpowers/hooks/session-start /tmp/superpowers/hooks/run-hook.cmd .claude/hooks/
```

Licensed under MIT — see `SUPERPOWERS-LICENSE`.
