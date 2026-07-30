---
name: commit-noconfirm
description: 現在の変更を確認なしで即座に commit する user-invocation only の skill。commit-confirm の承認ステップを意図的にスキップしたいときの逃げ道。
disable-model-invocation: true
---

# commit-noconfirm

現在の working tree の変更を **ユーザー確認なしで** 即座に commit する。

`disable-model-invocation: true` により、この skill はユーザーが `/commit-noconfirm` と明示 invoke した場合のみ起動する。

## フロー

1. `git status` で現状を把握
2. staged が空なら、tracked ファイルの変更のみ `git add -u` で stage
   - 新規ファイル (untracked) は **含めない** — 承認なしで新規ファイルを混入させると secrets 混入リスクがある
   - 新規ファイルも含めたい場合はユーザーが事前に自分で `git add` してあるはず
3. `git diff --staged --stat` で変更概要 (ファイル一覧と行数) だけ簡潔に表示
4. `git diff --staged --name-only` の結果からファイル名に `.env`, `credentials`, `secret`, `.pem`, `id_rsa`, `id_ed25519` などが含まれていたら **一度だけ止めて確認** (secrets 混入の最終ガード)
5. commit メッセージを自動生成 (CLAUDE.md のルール: 日本語主体、英語併用可)
6. `git commit` を即実行
7. `git log --oneline -1` で結果を報告

**通常の内容確認はスキップ。step 4 以外はユーザーに聞かない。**

## push について

commit のみ。push は含めない。push が必要な場合はユーザーが別途指示する。

## やってはいけないこと

- untracked ファイルを勝手に add する
- push まで走らせる
- secrets 疑いのあるファイルを step 4 のガード無しで通す
