---
name: lsp-setup
description: |
  为当前代码仓库配置 LSP 代码智能——安装 LSP 语言服务器、配置 Codex LSP MCP、
  安装 LSP 会话 hook、写入检索规则到项目 CLAUDE.md / AGENTS.md。
  所有配置写入项目工作目录（.claude/ .codex/），不污染全局。
  触发场景：lsp-setup、配置 LSP、装 LSP、LSP 不工作、goToDefinition 不能用、
  findReferences 失败、hover 没反应、新项目配环境、开发环境初始化、dev setup。
---

# LSP Setup

为当前代码仓库配置 LSP 代码智能，让 AI coding agent 从第一秒就能精准定位符号。

## 安装范围

| 类别 | 安装到哪 | 为什么 |
|------|---------|--------|
| LSP 二进制（vtsls / gopls / pyright） | 全局（系统工具） | 所有项目共用同一个语言服务器 |
| Claude Code LSP 插件启用 | `~/.claude/settings.json` | 插件注册是全局的 |
| LSP 会话 hook | **项目** `.claude/hooks/lsp-session.sh` | 只有本项目的会话才提醒用 LSP |
| hook 配置 | **项目** `.claude/settings.local.json` | 项目级 SessionStart hook |
| Codex lsp-mcp 二进制 | `~/.codex/tools/lsp-mcp/` | 工具本体全局一份 |
| Codex lsp-mcp MCP 注册 | `~/.codex/config.toml` | Codex MCP 注册是全局的 |
| Codex lsp-mcp 项目配置 | **项目** `.lsp-mcp.json` | 每个项目的语言和 preset 不同 |
| 检索规则 | **项目** `CLAUDE.md` / `.codex/AGENTS.md` | agent 指令跟着项目走 |
| 本地忽略 | **项目** `.git/info/exclude` | 不改 tracked `.gitignore` |

## 执行流程

### 第 1 步：运行诊断脚本

```bash
bash ~/.claude/skills/lsp-setup/scripts/lsp-doctor.sh --project-dir "$(pwd)"
```

看输出里有没有 `[MISSING]`。有的话加 `--fix` 自动修复：

```bash
bash ~/.claude/skills/lsp-setup/scripts/lsp-doctor.sh --fix --project-dir "$(pwd)"
```

只装 Codex LSP MCP 时用窄模式：

```bash
CODEX_HOME="${CODEX_HOME:-$HOME/.codex}" bash ~/.claude/skills/lsp-setup/scripts/lsp-doctor.sh --fix --codex-lsp-only --project-dir "$(pwd)"
```

脚本检查并修复以下部分：

#### 1a. Claude Code LSP 插件

检测并补齐：
1. `ENABLE_LSP_TOOL` 环境变量 → `~/.claude/settings.json`
2. 注册 marketplace → `Piebald-AI/claude-code-lsps`
3. 启用语言插件 → 按项目语言自动选择 `vtsls`/`gopls`/`pyright`/`rust-analyzer`

#### 1b. LSP 语言服务器二进制

| 项目标志文件 | LSP Server | 安装命令 |
|-------------|-----------|---------|
| `tsconfig.json` / `package.json` | `vtsls` | `npm i -g @vtsls/language-server` |
| `go.mod` | `gopls` | `go install golang.org/x/tools/gopls@latest` |
| `pyproject.toml` / `requirements.txt` | `pyright` | `pip3 install pyright` |
| `Cargo.toml` | `rust-analyzer` | `rustup component add rust-analyzer` |

#### 1c. Codex LSP MCP

| 检查项 | 缺失时 `--fix` 行为 |
|--------|---------------------|
| `~/.codex/tools/lsp-mcp/target/release/lsp-mcp` | clone/build `BumpyClock/lsp-mcp`，应用兼容补丁 |
| `~/.codex/config.toml` `[mcp_servers.lsp-mcp]` | 写入全局 MCP 注册，不写固定 `--workspace-root` |
| **项目** `.lsp-mcp.json` | 按项目语言写入本地配置 |
| **项目** `.git/info/exclude` | 本地忽略 `.lsp-mcp/`、`.lsp-mcp.json` |

当前补丁修复：stale diagnostics 过滤、documentSymbol 不取 snippet、嵌套符号不逐个 hover、多字节字符 panic。

#### 1d. 项目依赖

| 锁文件 | 命令 |
|--------|------|
| `pnpm-lock.yaml` | `pnpm install --frozen-lockfile` |
| `package-lock.json` | `npm ci` |
| `go.mod` | `go mod download` |

#### 1e. 检索规则

自动检测**项目工作目录**的 `CLAUDE.md` 和 `.codex/AGENTS.md`，没有"代码检索"部分就追加。
如果 `CLAUDE.md` 已被 Git 跟踪，不自动改它，避免本地 AI 检索说明进团队 PR。
Codex 版只写当前可用工具集：`documentSymbol`、`goToDefinition`、`findReferences`、`hover`、`getDiagnostics`。

### 第 2 步：安装 LSP 会话 hook

将本 skill 自带的 hook 脚本复制到**项目工作目录**：

```bash
mkdir -p .claude/hooks
cp ~/.claude/skills/lsp-setup/hooks/lsp-session.sh .claude/hooks/lsp-session.sh
chmod +x .claude/hooks/lsp-session.sh
```

在**项目** `.claude/settings.local.json` 中添加 SessionStart hook：

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup|resume|clear|compact",
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/hooks/lsp-session.sh"
          }
        ]
      }
    ]
  }
}
```

注意：用**相对路径** `.claude/hooks/lsp-session.sh`，不要写绝对路径。

### 第 3 步：本地忽略

确认 `.git/info/exclude` 包含：

```
.claude/hooks/
.claude/settings.local.json
.lsp-mcp/
.lsp-mcp.json
```

## 如果脚本修不了

- **gopls 缓存过期**：`pkill -f gopls`，重开会话
- **LSP 首次冷启动慢**：等 3-5 秒再重试
- **node_modules 过期**：删掉 `node_modules` 再跑 `--fix`
- **Codex 新会话没暴露 LSP MCP**：确认 `~/.codex/config.toml` 有 `[mcp_servers.lsp-mcp]`，完全新开 Codex 窗口
