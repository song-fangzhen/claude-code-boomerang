# Claude Code 回旋镖

简体中文 | [English](./README.md)

> 当 Claude Code 任务完成时接收桌面通知，点击即可跳转到 IDE 窗口。

## 功能特性

- ✅ 常驻通知，智能自动消失（持续监控前台窗口，切回目标项目窗口 5 秒后自动消失）
- ✅ 点击通知跳转到你的 IDE 工作区（支持 VS Code、Cursor、Trae、Trae CN、WebStorm、IntelliJ、PyCharm、GoLand）
- ✅ 智能窗口激活：优先激活已存在的窗口，支持父目录匹配
- ✅ 自动检测 IDE 类型
- ✅ 不同事件使用不同的提示音
- ✅ 每个项目只显示一个通知
- ✅ 零依赖（macOS 原生 + alerter）
- ✅ 支持多种 hook 类型：计划就绪、提问、任务完成、子任务完成
- ✅ 飞书 Webhook 消息推送，随时随地掌握任务动态

## 快速安装

### 插件安装

```bash
# 1. 添加市场
/plugin marketplace add song-fangzhen/claude-code-boomerang

# 2. 安装插件
/plugin install claude-code-boomerang

# 3. 重启 Claude Code
```

完成！插件会自动设置所有必要的 hooks。

## 支持的 IDE

插件会自动检测你的 IDE，点击通知时打开正确的工作区：

| IDE | 自动检测 | URL Scheme | Bundle ID 匹配 |
|-----|---------|------------|----------------|
| Trae CN | ✅ | `trae-cn://file` | `cn.trae.*` |
| Trae | ✅ | `trae://file` | `*trae*` |
| VS Code | ✅ | `vscode://file` | `*vscode*` |
| Cursor | ✅ | `cursor://file` | `*todesktop*` |
| WebStorm | ✅ | `webstorm://open?file=` | `*webstorm*` |
| IntelliJ IDEA | ✅ | `idea://open?file=` | `*intellij*` |
| PyCharm | ✅ | `pycharm://open?file=` | `*pycharm*` |
| GoLand | ✅ | `goland://open?file=` | `*goland*` |

检测基于 `__CFBundleIdentifier` 环境变量。对于 Trae/Trae CN，插件还会检查 `TERM_PRODUCT` 作为备选（因为 Trae 的 `TERM_PROGRAM` 可能为空）。

## 支持的 Hooks

插件监听 3 种 Claude Code hooks，每种使用不同的提示音：

| Hook | 触发时机 | 通知内容 | 提示音 |
|------|---------|----------|--------|
| **PreToolUse** | ExitPlanMode 之前 | 📋 Plan Ready | Hero |
| **PreToolUse** | AskUserQuestion 之前 | ❓ Question | Glass |
| **Notification** | 权限提示 | ❓ Notification | Glass |
| **Stop** | 主任务完成 | ✅ Task Completed | Ping |

## 配置（可选）

在 `~/.claude/settings.json` 中配置插件：

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

**可用选项**:
- `CLAUDE_NOTIFY_DEBUG`: 启用调试日志（`"true"` 或 `"false"`）
- `CLAUDE_NOTIFY_SOUND`: 控制通知音效（`"on"` 或 `"off"`，默认：`"on"`）
- `CLAUDE_NOTIFY_SOUND_PLAN`: Plan Ready 提示音（默认：`"Hero"`）
- `CLAUDE_NOTIFY_SOUND_QUESTION`: Question/Notification 提示音（默认：`"Glass"`）
- `CLAUDE_NOTIFY_SOUND_COMPLETE`: Task Completed 提示音（默认：`"Ping"`）
- `CLAUDE_FEISHU_WEBHOOK`: 飞书机器人 Webhook URL，用于消息推送（未配置则不启用）

**可用声音**: Basso, Blow, Bottle, Frog, Funk, Glass, Hero, Morse, Ping, Pop, Purr, Sosumi, Submarine, Tink

### 飞书通知

如需通过飞书接收通知，先在飞书群中添加自定义机器人获取 Webhook URL，然后配置：

```json
{
  "env": {
    "CLAUDE_FEISHU_WEBHOOK": "https://open.feishu.cn/open-apis/bot/v2/hook/你的webhook-id"
  }
}
```

飞书通知包含以下信息：
- 任务状态（带 emoji 标识）
- Hook 类型（Stop / PreToolUse / Notification）
- 项目名称和目录路径
- 时间戳
- 卡片颜色区分：🟢 绿色=任务完成、🟠 橙色=交互工具、🔵 蓝色=通知提示

## 卸载

```bash
/plugin uninstall claude-code-boomerang
```

## 了解更多

查看 **[GUIDE-ZH.md](./GUIDE-ZH.md)** 了解：
- 详细安装步骤
- 工作原理
- 调试技巧
- 故障排除
- 技术细节

English documentation see **[README.md](./README.md)**

## 许可证

MIT
