---
name: codex-impl
description: "Codex CLI に大規模・機械的な実装を委譲する PM モード。**起動条件 (いずれか)**: (1) 10ファイル以上の機械的リネーム/型変更/層横断リファクタ、(2) 新機能の初期 scaffolding、(3) Claude のコンテキストを温存したい長大タスク。**起動しない**: 3ファイル以下、UI 微調整、デバッグ、意図解釈や設計判断を伴うタスク (Claude 直接の方が10倍速く意図も外さない)。ユーザーが 'Codex に実装させて', 'Codex Worker', '実装を依頼' と明示した場合は条件を緩めて起動可。"
---

# Codex Implementation Skill

Claude が PM、実装は Codex Worker に委譲。

## 使う / 使わない

| 場面                                          | 判断 |
| --------------------------------------------- | ---- |
| 10ファイル以上の機械的リネーム/型変更         | ✅   |
| 新機能の scaffolding (層横断)                 | ✅   |
| 数百行超の生成でコンテキスト温存したい        | ✅   |
| 3ファイル以下の修正                           | ❌   |
| UI 微調整・デバッグ・原因調査                 | ❌   |
| 意図解釈や設計判断が必要                      | ❌   |

## Codex の癖 (プロンプトで潰す)

- `.catch(() => {})` でエラー握り潰し → 「空 catch 禁止、throw or log」
- コメント過多 → 「自明な what コメント禁止」
- 意図汲み取り弱い → 抽象指示NG、やる/やらないを具体例で示す

## Claude の操作制限

Read/Glob/Grep と `codex exec` のみ。Edit/Write **禁止**。

## 実行

```bash
echo "{タスク内容}" > /tmp/codex-prompt.md
CODEX=$(command -v codex || echo "/opt/homebrew/bin/codex")

# 1回目
$CODEX exec - < /tmp/codex-prompt.md 2>/dev/null
# 2回目以降
$CODEX exec resume "{session_id}" < /tmp/codex-prompt.md 2>/dev/null
```

## 運用注意

- usage limit で停止リスクあり → plan.md に進捗を残す
- session resume でも文脈は完全に引き継がれない → 制約は毎回プロンプトに含める
