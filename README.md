# claude-code-saver

Auto-pick the Claude Code account with the most remaining quota. When you type `claude`, it checks every account's usage in the background and silently switches to the one with the most headroom before launching.

Works by swapping macOS Keychain tokens + the `~/.claude.json` identity. Requires multiple Anthropic accounts (different emails, each with its own subscription).

## Install

One-liner (macOS only):

```bash
curl -fsSL https://raw.githubusercontent.com/yousefarifalarif/claude-code-saver/main/install.sh | bash
```

The installer:

1. Copies `claude-code-saver` to `~/.claude/claude-code-saver/`
2. Checks Python + Claude CLI are present
3. Runs `claude-code-saver init` (the setup wizard)

The wizard handles the rest:

- Detects your currently logged-in Claude account, offers to save it
- Walks you through logging out + logging in as your second account
- Saves each account's token to Keychain
- Adds a `claude` alias to your shell rc (zsh/bash/fish)
- Prints next steps

## Daily use

Once installed, just use `claude` normally. The wrapper runs silently when you're under threshold (default 80%). Over threshold, it swaps to the account with the most headroom and shows one line:

```
⚡ alice@example.com: session 20% / weekly 85%
  → bob@example.com: session 20% / weekly 12% (resets in 3h42m)
```

## Commands

| Command | What it does |
|---|---|
| `claude-code-saver init` | First-time setup wizard |
| `claude-code-saver status` | Show all accounts + current usage |
| `claude-code-saver login` | Log out, log in as a different account, save it |
| `claude-code-saver add` | Save the currently logged-in account |
| `claude-code-saver remove <email>` | Remove a saved account |
| `claude-code-saver threshold <10-99>` | Set the auto-switch threshold % |
| `claude-code-saver doctor` | Run diagnostics |
| `claude-code-saver uninstall` | Remove everything (keychain, config, alias) |

## How it works

1. **Registration**: on `add`, we read the live token from Keychain (`Claude Code-credentials`) and the `oauthAccount` from `~/.claude.json`. Both get backed up under our own Keychain service (`com.claude-code-saver[.oauth]`) keyed by a per-account UUID.

2. **Usage check**: calls `GET https://api.anthropic.com/api/oauth/usage` with header `anthropic-beta: oauth-2025-04-20`. Returns `five_hour.utilization` and `seven_day.utilization` as percentages (0–100).

3. **Launch**: when you type `claude`, the wrapper:
   - Checks the live account's session usage (~500ms)
   - If under threshold → `os.execvp` to the real claude binary (no overhead)
   - If over threshold → checks other saved accounts in parallel, picks the lowest, swaps the live Keychain token + `~/.claude.json` identity, launches

4. **Token freshness**: when swapping away from an account, we first back up the current (possibly refreshed) live token to that account's slot. So saved tokens stay fresh.

## Requirements

- macOS (uses Keychain)
- Python 3.7+
- Claude CLI installed (`https://claude.com/claude-code`)
- Two or more Anthropic accounts, each with its own Pro/Max subscription

## Caveats

- Multiple accounts must be used per [Anthropic's terms](https://support.claude.com/en/articles/11145838-using-claude-code-with-your-pro-or-max-plan). This is for stacking your own legitimate subscriptions, not for bypassing limits.
- The alias only applies to interactive shells. Tools that invoke `claude` directly (VS Code extensions, cron jobs, etc.) bypass the wrapper.
- macOS may prompt for Keychain access the first time — click "Always Allow" to avoid repeated prompts.
