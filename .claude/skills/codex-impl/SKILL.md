---
name: codex-impl
description: "Codexに実装を委託する。Use when user mentions 'Codex に実装させて', 'Codex Worker', 'Codex に作らせて', '実装を依頼'."
---

# Codex Implmentation Skill

Codex CLI を使った実装委託モード。 Claude は PM として調整のみ行い、実装は Codex Worker に委譲。

## Claude の役割（PM モード）

Claude は **PM（Project Manager）** として機能。

### 許可される操作

| 操作                  | 許可 | 説明                   |
| --------------------- | ---- | ---------------------- |
| ファイル読み込み      | ✅   | Read, Glob, Grep       |
| Codex Worker 呼び出し | ✅   | `Bash (codex exec)`    |
| plan.md 更新         | ✅   | 状態マーカーの更新のみ |
| Edit/Write            | ❌   | **禁止**               |

## 実行方法

```bash
# プロンプトファイル生成
echo "{タスク内容}" > /tmp/codex-prompt.md

# codex のフルパスを使用（PATH に /opt/homebrew/bin が含まれない環境対策）
CODEX=$(command -v codex || echo "/opt/homebrew/bin/codex")

# 実行（プロンプトは stdin 経由で渡す）（1回目)
$CODEX exec - < /tmp/codex-prompt.md 2>/dev/null
# 実行（2回目以降）
$CODEX exec resume "{session_id}" < /tmp/codex-prompt.md 2>/dev/null
EXIT_CODE=$?
echo "Exit code: $EXIT_CODE"
```
