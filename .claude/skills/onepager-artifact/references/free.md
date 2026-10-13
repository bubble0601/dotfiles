# layout: free(本文を自由に書く)

図解ペライチが合わないときは、本文の HTML 断片を毎回書く。殻(1 ファイル化・テーマ・選択コメント・コピー)は build.py が付ける。

## spec

```json
{"layout": "free", "title": "…", "storage_key": "…", "width": "narrow", "body": "body.html"}
```

- `width`: `"narrow"`(本文 800px。文章中心のとき)/ 省略(1120px。図や表が主のとき)
- `body` の HTML 断片の書き方:
  - `<html>` `<head>` `<body>` は書かない
  - 画像は `<img src="相対パス">` で書けば base64 で埋め込まれる
  - 外部の CSS / JS / 画像は読み込まない。Slack からダウンロードして開いたときに読めないため
  - ページ固有の見た目は、断片の中の `<style>` に書く
- 図は、画面モックなら visual と同じ手順(`references/visual.md` の手順 2〜5)で描く。構成図・流れ図はインライン SVG で直接書いてよい

## 本文の骨組み(必須)

コメントは `<header>` / `<section>` 単位でまとめられ、コピーの見出しにもなる。そのため次の形にする。

```html
<header><div class="eyebrow">種類 / 読み手</div><h1>結論を 1 文で</h1><p class="lead">何を読めば何が分かるか</p></header>
<section><h2>章の見出し</h2> … </section>
```

## 共通の部品(templates/page.css)

| 部品 | マークアップ |
|---|---|
| 注記 | `<div class="callout">` / `.callout.warn` / `.callout.good`。先頭の `<b>` が見出しになる |
| 表 | `<div class="tbl"><table>…</table></div>`。数値の列は `class="num"` |
| 手順 | `<ol class="steps"><li>…</li></ol>` |
| 比較カード | `<div class="cols"><div class="card"><h4>…</h4>…</div><div class="card pick">…</div></div>`(`.pick` は推奨案) |
| 要点 3 つ | `<div class="points"><div class="point"><b>見出し</b><span>説明</span></div>…</div>` |
| 注意点 | `<ul class="notes"><li><b>見出し</b><span>説明</span></li></ul>` |
| 図 | `<figure><img src="img/a.jpg" alt="…"><figcaption>…</figcaption></figure>` |
| 質問 + 回答欄 | 下記 |

```html
<div class="qs">
  <div class="q"><div class="n">質問 1</div><p>質問文</p><small>補足(いまの案など)</small>
    <label class="ans"><span>回答</span><textarea data-kind="q" rows="2" placeholder="ここに回答を書く"></textarea></label></div>
</div>
```

`textarea` の id は build.py が振る。回答欄が 1 つでもあると、下部バーの文言とコピーの見出しが「回答・コメント」になる。

## 部品が足りないとき

断片の `<style>` に足す。色は `page.css` の変数(`--ink` `--muted` `--line` `--surface` `--bg` `--accent` `--warm` `--good` と各 `-soft`)だけを使う。変数を使えばダークテーマにも追従する。

同じ部品を 2〜3 回書いたら `page.css` に移し、上の表に足す。同じ構成のページを 2〜3 回作ったら、visual のように spec から組める layout にする。
