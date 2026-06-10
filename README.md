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
- Offers to install the PATH shim (see below)
- Prints next steps

## Daily use

Once installed, just use `claude` normally. The wrapper runs silently when you're under threshold (default 80%). Over threshold, it swaps to the account with the most headroom and shows one line:

```
⚡ alice@example.com: session 20% / weekly 85%
  → bob@example.com: session 20% / weekly 12% (resets in 3h42m)
```

## Where auto-switching works

| Context | Shell alias | PATH shim |
|---|---|---|
| Interactive terminal (`claude` in zsh/bash) | ✓ | ✓ |
| VS Code integrated terminal (interactive shell) | ✓ | ✓ |
| VS Code tasks / launch configs | ✗ | ✓ |
| Python `subprocess` / Node `child_process` calls | ✗ | ✓ |
| Shell scripts run non-interactively | ✗ | ✓ |
| Cursor/VS Code **extension** (bundled binary) | ✗ | ✗ |
| Claude Code **desktop app** (the `.app` bundle) | ✗ | ✗ |

The shell alias (installed by default) covers interactive terminals. The PATH shim covers everything else that calls `claude` via PATH lookup. Bundled binaries (Cursor/VS Code extensions ship their own `claude`) and the packaged desktop app are not affected — they bypass PATH entirely.

## PATH shim

The PATH shim is a tiny shell script placed at `~/.claude/claude-code-saver/bin/claude`. During `install-shim`, the existing `~/.local/bin/claude` symlink is redirected to point to our shim. The real binary path is cached in config, so the wrapper can always reach it without going through PATH.

```bash
claude-code-saver install-shim    # redirect the symlink; works immediately
claude-code-saver uninstall-shim  # restore original symlink
```

**After a Claude Code update**: the updater recreates `~/.local/bin/claude` pointing to the new version binary, overriding our shim redirect. Run `claude-code-saver doctor` to detect this, then `claude-code-saver install-shim` to restore it. The cached `claude_bin` in config auto-updates to the new version on the next launch.

## Commands

| Command | What it does |
|---|---|
| `claude-code-saver init` | First-time setup wizard |
| `claude-code-saver status` | Show all accounts + current usage |
| `claude-code-saver login` | Log out, log in as a different account, save it |
| `claude-code-saver add` | Save the currently logged-in account |
| `claude-code-saver remove <email>` | Remove a saved account |
| `claude-code-saver threshold <10-99>` | Set the auto-switch threshold % |
| `claude-code-saver install-shim` | Install PATH shim (non-interactive shell coverage) |
| `claude-code-saver uninstall-shim` | Remove the PATH shim |
| `claude-code-saver doctor` | Run diagnostics |
| `claude-code-saver uninstall` | Remove everything (keychain, config, alias, shim) |

## How it works

1. **Registration**: on `add`, we read the live token from Keychain (`Claude Code-credentials`) and the `oauthAccount` from `~/.claude.json`. Both get backed up under our own Keychain service (`com.claude-code-saver[.oauth]`) keyed by a per-account UUID.

2. **Usage check**: calls `GET https://api.anthropic.com/api/oauth/usage` with header `anthropic-beta: oauth-2025-04-20`. Returns `five_hour.utilization` and `seven_day.utilization` as percentages (0–100).

3. **Launch**: when `claude` is invoked (via alias or shim):
   - Checks the live account's session usage (~500ms)
   - If under threshold → `os.execvp` to the real claude binary (no overhead)
   - If over threshold → checks other saved accounts in parallel, picks the lowest, swaps the live Keychain token + `~/.claude.json` identity, launches

4. **Token freshness**: when swapping away from an account, we first back up the current (possibly refreshed) live token to that account's slot. So saved tokens stay fresh.

5. **Binary resolution**: `find_claude_bin()` uses the cached real binary path from config (set during `install-shim` or first detection), skipping our shim to avoid infinite recursion. If the cached path is gone after a Claude Code update, it scans the versions directory for the latest executable automatically.

## Requirements

- macOS (uses Keychain)
- Python 3.7+
- Claude CLI installed (`https://claude.com/claude-code`)
- Two or more Anthropic accounts, each with its own Pro/Max subscription

## Caveats

- Multiple accounts must be used per [Anthropic's terms](https://support.claude.com/en/articles/11145838-using-claude-code-with-your-pro-or-max-plan). This is for stacking your own legitimate subscriptions, not for bypassing limits.
- macOS may prompt for Keychain access the first time — click "Always Allow" to avoid repeated prompts.
- After a Claude Code update, re-run `claude-code-saver install-shim` if the PATH shim was active (doctor will warn you).
