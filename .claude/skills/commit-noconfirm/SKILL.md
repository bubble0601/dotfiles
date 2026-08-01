---
name: commit-noconfirm
description: 現在の変更を確認なしで即座に commit する user-invocation only の skill。commit-confirm の承認ステップを意図的にスキップしたいときの逃げ道。
disable-model-invocation: true
---

# commit-noconfirm

現在の working tree の変更を確認なしで commit する。push はしない。

まず `git status` で現状を確認する。commit を分割するか単一にまとめるかは状況に応じて判断する。commit メッセージは CLAUDE.md ルールに従い日本語主体で自動生成する。
