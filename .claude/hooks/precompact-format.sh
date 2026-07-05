#!/bin/bash
# PreCompact hook: 要約の形式を指定する。
# stdout に書いた内容が compact 用の追加コンテキストとして注入される。

cat <<'EOF'
Compact 後の要約は必ず以下の Markdown フォーマットで出力してください。
各セクションは順序を守り、該当する情報がない場合は "(none)" と明記して省略しないでください。

## Active Plan
現在進行中のプラン全体の目的と、完了までに残っている大きなステップを箇条書きで。

## Current Phase
Active Plan の中で「今まさに手をつけている」フェーズ / サブタスク。
何を、なぜ、どの成果物を出す段階なのかを1〜3行で。

## TaskList Summary
TaskCreate などで管理している task を `[x] 完了 / [ ] 未完 / [~] 進行中` の形式で列挙。
task が無ければ "(none)"。

## Session Decisions
このセッション中にユーザーと合意した設計方針・命名・トレードオフの結論・
やらないと決めたこと・ユーザーからの feedback を箇条書きで。
git log や CLAUDE.md から復元できない「会話でだけ生まれた情報」に絞る。

## Editing Files
編集中 or 直近で編集したファイルを `path — 状態 (未 commit / commit 済み / 予定)` の形式で列挙。
各行に、そのファイルで何を変更した/変更予定かを1行で添える。
EOF
