---
name: pr
description: ブランチ作成から PR 作成まで実行
disable-model-invocation: true
---

# ブランチ作成、commit 作成、PR 作成

## ユーザー入力

```
$ARGUMENTS
```

処理を進める前に、ユーザー入力を必ず考慮してください(空でない場合)。

## 実行ステップ

メインブランチは dev または prod(dev のことが多い)

1. メインブランチ(dev,prod)であればブランチを切って
2. 変更をコミットして
   - stagedの変更があればそれを対象にする(git addは実行しない)
   - stagedの変更がなければ、変更内容を確認して適切なファイルをgit addする
   - 変更が何もなければ次へ
3. 変更を push して
4. Github に PR を作成して
   - .github/pull_request_template.md が存在する場合はこのテンプレートに従って内容を書くこと
     - 「動作確認 / 証跡」「関連リンク」は記述不要(見出しだけ残す)
     - 内容は簡潔に
   - PR作成済みの場合はbody(必要ならtitleも)を更新して
