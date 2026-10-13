---
name: onepager-artifact
description: Slack に貼ってそのまま読める 1 ファイルの HTML ページ(Artifact)を作る。起動時に目的と読み手を聞き、図解ペライチ(実画面に近いモック図 + 少ない言葉)か、本文を自由に書くページかを選ぶ。画像・CSS・JS はすべて埋め込み、本文への選択コメントと全入力のコピーが付き、必要なら質問の回答欄も付ける。
disable-model-invocation: true
---

# ペライチ Artifact

## ユーザー入力

```
$ARGUMENTS
```

空でなければ最優先で考慮する。

## 変えない条件(Slack に貼れる HTML)

- 1 ファイルで完結させる。画像・CSS・JS はすべて埋め込む(build.py が行う)。外部から読み込んでよいのは Google Fonts だけで、読めなくても代替フォントで表示が崩れないこと
- **サイズは 10 MB 以下にする。Slack に貼ったときにプレビューが出る条件**。build.py が超えたら警告する
- 本文への選択コメントと「全入力内容をコピー」を付ける(build.py が付ける)。回答・コメントは閲覧者のブラウザに保存されるだけなので、回収は読み手にコピーして送ってもらう

## 1. 目的と読み手を聞く

AskUserQuestion を 1 回だけ使い、次のうち依頼文・会話・計画書から分からないものだけを聞く(全部分かれば聞かない)。

| 項目 | 選択肢の例 |
|---|---|
| 目的 | 伝える / 意見を集める / 判断してもらう / 記録として残す |
| 読み手 | 内容を知らない人(PO・顧客・他チーム・利用者)/ 関係者 / 詳しい人(開発者) |
| 読まれ方 | Slack で流し読み / 会議で画面共有 / じっくり読む |
| 返してほしいもの | なし / コメント / 質問への回答 |

答えから下の layout を決め、「layout と、そう決めた理由」を 1 行で伝えてから作り始める。

## 2. layout を選ぶ

| layout | 合う場面 | 詳細 |
|---|---|---|
| `visual` | 読み手が内容を知らず、画面や操作の変化が主題(機能紹介、仕様の提案、ヒアリング) | `references/visual.md` |
| `free` | それ以外。詳しい人向けの設計メモ、選択肢の比較と推奨、手順書、調査報告、障害報告など | `references/free.md` |

- 迷ったら、読み手が「図を見れば分かる」なら `visual`、「文と表を読まないと判断できない」なら `free`
- `free` では、目的に合わせて構成を毎回考える。例:
  - 判断してもらう → 結論と推奨 → 比較 → 決めてほしいこと(回答欄)
  - 記録として残す → 背景 → 決定 → 却下した案と理由
  - 手順書 → 前提 → 手順 → うまくいかないとき
- 質問の回答欄は「返してほしいもの = 質問への回答」のときだけ付ける。質問は答えによって中身が変わるものだけにする

## 3. 組む

1. layout ごとの詳細(上の表のファイル)に従って中身と図を作る
2. `scripts/build.py spec.json out.html`(spec の例は `examples/spec.*.example.json`)。サイズの警告が出たら直す
3. headless Chrome で全体のスクリーンショットを 1 回撮り、Read で崩れを確認して直す

## 4. 公開

- Artifact ツールで `out.html` を publish する(`icon` は初回だけ)。以後は同じパスで republish
- Slack に貼る用に、`out.html` のパスもユーザーに伝える

## ページ側の仕様(page.js)

- 回答・コメントは `localStorage`(キーは spec の `storage_key`)に自動保存。共有はされない
- 本文の文字を選択するとその場にコメント欄。保存すると橙のハイライト(`::highlight(memo)`)。ハイライトをクリックすると編集・削除。Chrome / Edge / Safari 17.2+ でハイライト表示、非対応でもコメント自体は付く
- 下部バーは、マウス環境では画面下端から 48px 以内にカーソルが来たときに出て、バーより上にカーソルが移ると消える。Tab でフォーカスしても出る。タッチ環境(hover なし)は常に出す
- コピー形式は Markdown(`## 章名` → `### 質問 n: …` / `回答: …` → `### コメント: 「引用」` / 本文)。入力したものだけが入る

## ファイル

- `scripts/build.py` ページ生成(spec JSON → HTML)、`scripts/render.sh` 図の描画(HTML → PNG / JPEG)
- `templates/page.css` ページの見た目と free 用の部品、`templates/interactive.css` / `page.js` 回答欄・選択コメント・下部バー
- `assets/app-shell.css`(実画面風のモック用。`:root` の変数で配色を差し替える)、`assets/figure.css`(概念図)
- `references/visual.md` / `references/free.md` layout ごとの作り方
- `examples/spec.{general,proposal,free}.example.json`、`examples/body.free.example.html`、`examples/mock_*.html` / `figure_concept.html` と `examples/img/`(その描画結果)
