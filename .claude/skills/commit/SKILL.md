---
name: commit
description: 現在の変更を確認なしで即座に commit する。user-invocation only。
disable-model-invocation: true
---

# commit作成

## ユーザー入力

```
$ARGUMENTS
```

処理を進める前に、ユーザー入力を必ず考慮してください(空でない場合)。

## 前提

この skill は**ユーザーが明示的に呼び出したときだけ**発動する。呼び出した時点で承認とみなし、**commit-confirm の確認ステップは踏まない**。push もしない。

## 実行step

メインブランチはdevまたはprod(devのことが多い)

1. 次の指示があれば実行して: $ARGUMENTS; 指示終わり
2. `git status` で現状を確認する
3. メインブランチ(dev,prod)であればブランチを切って
4. stagedの変更をコミットして
   - stagedの変更があればそれを対象にする(git addは実行しない)
   - stagedの変更がなければ、変更内容を確認して適切なファイルをgit addする
   - 対象の変更に対して包括的かつ適切なコミットメッセージを考えること(CLAUDE.md のルールに従い日本語主体)
   - commit を分割するか単一にまとめるかは状況に応じて判断する
