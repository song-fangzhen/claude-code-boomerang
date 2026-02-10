# Claude Code Boomerang

[简体中文](./README-ZH.md) | English

> Get desktop notifications when Claude Code tasks complete. Click to jump to your IDE window.

## Features

- ✅ Persistent notifications with smart auto-dismiss (continuously monitors; auto-dismiss 5s after user returns to target project window)
- ✅ Click to jump to your IDE workspace (VS Code, Cursor, Trae, Trae CN, WebStorm, IntelliJ, PyCharm, GoLand)
- ✅ Smart window activation: prefer existing windows, supports parent directory matching
- ✅ Auto-detect IDE from environment
- ✅ Different notification sounds for different events
- ✅ Only one notification per project
- ✅ Zero dependencies (macOS native + alerter)
- ✅ Support multiple hook types: Plan Ready, Questions, Task Complete, Subagent Complete

## Quick Install

### Plugin Installation

```bash
# 1. Add marketplace
/plugin marketplace add quanru/claude-code-boomerang

# 2. Install plugin
/plugin install claude-code-boomerang

# 3. Restart Claude Code
```

That's it! The plugin will automatically set up all required hooks.

## Supported IDEs

The plugin automatically detects your IDE and opens the correct workspace when you click the notification:

| IDE | Auto-detected | URL Scheme | Bundle ID Pattern |
|-----|--------------|------------|-------------------|
| Trae CN | ✅ | `trae-cn://file` | `cn.trae.*` |
| Trae | ✅ | `trae://file` | `*trae*` |
| VS Code | ✅ | `vscode://file` | `*vscode*` |
| Cursor | ✅ | `cursor://file` | `*todesktop*` |
| WebStorm | ✅ | `webstorm://open?file=` | `*webstorm*` |
| IntelliJ IDEA | ✅ | `idea://open?file=` | `*intellij*` |
| PyCharm | ✅ | `pycharm://open?file=` | `*pycharm*` |
| GoLand | ✅ | `goland://open?file=` | `*goland*` |

Detection is based on the `__CFBundleIdentifier` environment variable. For Trae/Trae CN, the plugin also checks `TERM_PRODUCT` as a fallback since `TERM_PROGRAM` may be empty.

## Supported Hooks

The plugin monitors 3 types of Claude Code hooks with different sounds:

| Hook | Trigger | Notification | Sound |
|------|---------|-------------|-------|
| **PreToolUse** | Before ExitPlanMode | 📋 Plan Ready | Hero |
| **PreToolUse** | Before AskUserQuestion | ❓ Question | Glass |
| **Notification** | Permission prompts | ❓ Notification | Glass |
| **Stop** | Main task completed | ✅ Task Completed | Ping |

## Configuration (Optional)

Configure the plugin in `~/.claude/settings.json`:

```json
{
  "env": {
    "CLAUDE_NOTIFY_DEBUG": "true",
    "CLAUDE_NOTIFY_SOUND": "on",
    "CLAUDE_NOTIFY_SOUND_PLAN": "Hero",
    "CLAUDE_NOTIFY_SOUND_QUESTION": "Glass",
    "CLAUDE_NOTIFY_SOUND_COMPLETE": "Ping"
  }
}
```

**Available options**:
- `CLAUDE_NOTIFY_DEBUG`: Enable debug logging (`"true"` or `"false"`)
- `CLAUDE_NOTIFY_SOUND`: Control notification sounds (`"on"` or `"off"`, default: `"on"`)
- `CLAUDE_NOTIFY_SOUND_PLAN`: Plan Ready sound (default: `"Hero"`)
- `CLAUDE_NOTIFY_SOUND_QUESTION`: Question/Notification sound (default: `"Glass"`)
- `CLAUDE_NOTIFY_SOUND_COMPLETE`: Task Completed sound (default: `"Ping"`)

**Available sounds**: Basso, Blow, Bottle, Frog, Funk, Glass, Hero, Morse, Ping, Pop, Purr, Sosumi, Submarine, Tink

## Uninstall

```bash
/plugin uninstall claude-code-boomerang
```

## Learn More

See **[GUIDE.md](./GUIDE.md)** for:
- Detailed installation steps
- How it works
- Debugging tips
- Troubleshooting
- Technical details

中文文档请查看 **[README-ZH.md](./README-ZH.md)**

## License

MIT
