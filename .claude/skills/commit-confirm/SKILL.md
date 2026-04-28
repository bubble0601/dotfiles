---
name: commit-confirm
description: stage された変更を `git commit` する直前に、必ずユーザーに commit メッセージを見せて feedback を求めるためのワークフロー。複数 commit に分割するときは各回ループで確認。誤って確認なしで commit してしまったら soft reset で巻き戻して再確認する。`git add` の後、`git commit` を実行しようとするあらゆる場面で使うこと。`/commit` slash command 経由でも、ユーザーが「コミットして」「commit お願い」「これで commit して」と言った場合でも、Claude 自身が変更を一区切りつけて commit しようと判断した場面でも、確認をスキップせず必ずこの skill のフローに従う。CLAUDE.md の「stage 後 commit 前に確認」ルールを守るための guard skill。
---

# commit-confirm

stage された変更を commit する前に、ユーザーに commit メッセージを見せて feedback を求める。

## なぜ必要か

Claude が独断で commit すると、コミットメッセージが期待と違ったり意図しない変更が混入したりして、巻き戻しの手間が発生する。確認は数秒、巻き戻しは数分。

## 基本フロー

1. コミットメッセージ案を提示する(プロジェクトの慣例に従う)
2. 「この内容で commit してよいですか?」と聞き、**ユーザーの返答を必ず待つ**。沈黙を承認とみなさない
3. 修正指示があれば反映して再提示
4. OK が出たら `git commit`

複数 commit に分割する場合は、各 commit ごとに上記フローを繰り返す。「以降も同じ要領で」と省略しない。

## 既に commit してしまった場合の巻き戻し

1. `git log --oneline -n 5` で対象 commit を確認
2. `git reset --soft HEAD~N` で staged に戻す
   - `--hard` は使わない(変更が消える)
   - `--mixed`(デフォルト)も使わない(staged が外れる)
3. push 済みなら巻き戻し後に `git push --force-with-lease` で同期
4. その後は基本フローへ

## やってはいけないこと

- 確認なしで `git commit` を実行する
- 巻き戻しに `git reset --hard` を使う
