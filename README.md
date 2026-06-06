# AI Dev Pipeline

12 个 Claude Code Skill 组成的完整 AI 辅助开发管线。

核心哲学：**管好你的 AI Agent** — 让 AI 变聪明、给好工具和最小必要干预、反制 AI slop。

## 安装

```bash
git clone https://github.com/suyuanzhao/ai-dev-pipeline.git
cd ai-dev-pipeline

# 链接到 Claude Code
for d in skills/*/; do ln -sf "$(pwd)/$d" ~/.claude/skills/$(basename "$d"); done

# 链接到 Codex（指向 Claude Code 的同一份，更新只需一处）
for d in ~/.claude/skills/*/; do ln -sf "$d" ~/.codex/skills/$(basename "$d"); done
```

更新时 `git pull` 即可，两边同时生效。

## 项目初始化

```
/lsp-setup    ← 安装 LSP 语言服务器 + 会话 hook
```

## 管线流程

```
想法 → /grill-with-docs → /prototype(可选) → /to-prd → /to-issues(可选)
                                                            ↓
                    /bugfix ← FAIL ← /e2e-verify ← thermo-nuclear + Codex Review ← TDD 编码
                                                                                      ↓
                                                           /functional-test ← 提交 PR
```

完整图文版见 [`docs/pipeline.html`](docs/pipeline.html)（浏览器打开，28 页翻页式）。

## Skill 一览

| Skill | 作用 | 人参与？ |
|-------|------|---------|
| `/grill-with-docs` | 拷问想法，挖出所有细节 | ◆ |
| `/prototype` | 快速原型验证（可选） | |
| `/to-prd` | 对话 → PRD → 写入 Issue | ◆ 确认 |
| `/to-issues` | PRD → 垂直切片 Issue | |
| `/tdd` | 测试驱动开发 | |
| `/thermo-nuclear-code-quality-review` | 热核级代码质量审查 | |
| `/e2e-verify` | 按验收标准自动验证 | |
| `/bugfix` | 7 阶段诊断循环 | |
| `/functional-test` | 分组手测，AI 陪测查数据 | ◆ |
| `/handoff` | 上下文快满时断点续传 | |
| `/improve-codebase-architecture` | 架构深化，沉淀编码规范 | |
| `/lsp-setup` | 安装 LSP 语言服务器 | 跑一次 |

> ◆ = 需要人参与。12 个 skill 中只有 3 个需要你动脑。

## CLAUDE.md 路由模板

将以下内容复制到项目的 `CLAUDE.md` 中。Agent 每次会话启动时读取，知道什么情况该用什么 skill。

```markdown
## 开发管线

按场景路由到对应 skill，不要跳步：

| 场景 | 做什么 |
|------|--------|
| 新功能 / 新想法 | `/grill-with-docs` → `/to-prd` → TDD 编码 |
| 想先看看效果 | `/prototype`（grill 之后、to-prd 之前） |
| 需求大，想并行 | `/to-issues` 垂直切片 → 多窗口并行 |
| 代码写完了 | `/thermo-nuclear-code-quality-review` → `/e2e-verify` |
| 验证不通过 | `/bugfix`，修完回 `/e2e-verify` |
| 上线前手测 | `/functional-test` |
| Bug / 报错 / 性能退化 | `/bugfix` |
| 上下文快满 | `/handoff` |
| 想改善代码结构 | `/improve-codebase-architecture` |
```

## 知识沉淀

管线运行过程中持续积累三类文档：

- **CONTEXT.md** — 业务术语表
- **docs/adr/** — 技术决策记录
- **docs/specs/** — 已知陷阱

## License

MIT
