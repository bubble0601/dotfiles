---
name: fixup
description: staged の変更を適切な過去 commit に fixup する
disable-model-invocation: true
allowed-tools:
  - Bash(git commit:*)
  - Bash(git rebase:*)
---

# fixup

## ユーザー入力

```
$ARGUMENTS
```

処理を進める前に、ユーザー入力を必ず考慮してください(空でない場合)。

## 実行内容

git addは実行禁止。stagedの変更を対象にすること
直近10件のcommitの中からstagedの変更を含めるべき適切なcommitを特定し、以下の手順でfixupしてください

1. `git commit --fixup <対象commitのハッシュ>` でfixup commitを作成する
2. `GIT_SEQUENCE_EDITOR=true git rebase -i --autosquash <対象commitの一つ前のハッシュ>` でautosquashを実行する
