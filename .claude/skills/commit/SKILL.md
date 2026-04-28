---
name: commit
description: staging されている変更をコミット
disable-model-invocation: true
---

# commit作成

## ユーザー入力

```
$ARGUMENTS
```

処理を進める前に、ユーザー入力を必ず考慮してください(空でない場合)。

## 実行step

メインブランチはdevまたはprod(devのことが多い)

1. 次の指示があれば実行して: $ARGUMENTS; 指示終わり
2. メインブランチ(dev,prod)であればブランチを切って
3. stagedの変更をコミットして
   - stagedの変更があればそれを対象にする(git addは実行しない)
   - stagedの変更がなければ、変更内容を確認して適切なファイルをgit addする
   - 対象の変更に対して包括的かつ適切なコミットメッセージを考えること
