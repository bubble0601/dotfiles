---
name: review-code-blind
description: GitHub PR もしくはローカル作業ツリーを「ブリーフィング (背景・要点・見るべきポイント)」と「findings (具体指摘)」の 2 視点で**相互盲目**にレビューする。2 つの subagent を並列で走らせ、互いの存在・出力を知らせないことで、一方が他方に引っ張られる (角度リストが findings に寄る / findings が角度リストの範囲に閉じる) のを防ぐ。明示起動専用 (`/review-code-blind`)。
argument-hint: "[pr-number | pr-url | branch | base-ref | <empty>]"
disable-model-invocation: true
allowed-tools: Bash(gh *) Bash(git *) Bash(cat *) Bash(ls *) Bash(find *) Bash(wc *) Bash(head *) Bash(tail *) Agent
---

# review-code-blind

通常の review-code との違いは 1 点だけ:

**ブリーフィング (背景・要点・見るべきポイント) と findings (具体指摘) を、互いの存在を知らない 2 つの subagent に並列で生成させ、main agent が整形して出す。**

なぜこの構成にするか — 同一コンテキストで両方を書くと以下の双方向汚染が起きる:

- **角度リスト → findings 方向**: 先に書いた角度リストに寄せた findings しか出なくなり、角度外の盲点が拾えない。
- **findings → 角度リスト方向**: 読みながら見つけたバグが「レビューで特に見るべきポイント」に retrofit され、prospective であるべき角度リストが retrospective な bug 列挙になる。

2 視点を独立に走らせることで、それぞれが自分の mode に集中でき、どちらも他方に引きずられない。出力上は両方の結果をそのまま並べる (重なり検出 / ギャップ分析 / タグ付けはしない)。

---

## Workflow

### Step 1 — Resolve the review target

review-code skill (`${HOME}/.claude/skills/review-code/SKILL.md`) の Step 1 と同一。PR 番号 / URL / ブランチ名 / ref / 引数なし (作業ツリー) を解決し、base branch を特定する。

### Step 2 — Gather the shared context packet

両 subagent に渡す**共有入力**を組み立てる。この段階では main agent は diff を深く読まない (自分の中に findings も narrative も形成しないため)。

**PR モード:**
- `gh pr view <N> --json title,body,author,baseRefName,headRefName,labels,additions,deletions,changedFiles,url,commits`
- `gh pr diff <N>` → 一時ファイルに保存 (両 subagent が参照)
- `gh pr view <N> --comments` → 既存議論
- 本文に `#<num>` があれば `gh issue view`
- `docs/` / `z/plans/` 等で関連ドキュメントを浅くリストアップ (パスだけでよい)

**ローカル diff モード:**
- `git diff --stat <base>` / `git diff <base>` → 一時ファイルに保存
- `git log <base>..HEAD --oneline` / `git status --short`

**レポジトリ判定:**
- `gh repo view --json nameWithOwner` / `git config remote.origin.url`
- `medical-force/keibi-force` であれば `${HOME}/.claude/skills/review-code/references/keibi-force.md` の適用対象にする情報をメモ

main agent はここまでで止め、**次の Step でただちに 2 つの subagent を並列起動する**。自分で診断や findings や角度を先に書き始めないこと。

### Step 3 — Spawn two subagents IN PARALLEL

1 つのメッセージ内で Agent tool を 2 回呼ぶ (並列化のため)。両 subagent には共有コンテキスト (diff へのパス、PR メタデータ、リポジトリ情報、関連ドキュメントのパス) を**同じ内容**で渡す。**互いの存在・役割・出力を一切示唆しない**。

#### Subagent A — briefing-only (subagent_type: general-purpose)

プロンプトの骨子 (実際にはこれを自然な文章で書き起こす):

> あなたは PR / 変更のブリーフィングを書く役割。コードレビュー (バグ指摘) はしない。
>
> 入力: `<diff のパス>`, `<PR メタデータ>`, `<関連ドキュメントのパス>`, `<リポジトリ情報>`。必要なら `${HOME}/.claude/skills/review-code/references/generic.md` と (該当すれば) `${HOME}/.claude/skills/review-code/references/keibi-force.md` を参考にしてよい。
>
> 出力は以下の 3 セクションのみ (日本語):
>
> 1. **背景** (2–4 文): 何を解決しようとしているか、動機、誰の要望か。PR body / linked issue / plan docs / commit messages から抽出。動機不明なら「不明」と書く。
> 2. **要点**: 変更内容を subsystem/concept 単位でグルーピングして列挙。ファイル単位の列挙は禁止。
>    - 仕様追加・変更が含まれるなら、**仕様面を先に日本語で**書く (ユーザー/業務から見て何ができるようになった・変わったか)。実装詳細は補助的に添える。
>    - 純粋に技術的変更のみ (ユーザー挙動が一切変わらない) であれば design レベル (アーキテクチャ / モジュール境界 / データモデル) で書く。
>    - 両方含まれるなら仕様面を先、技術面を後。
> 3. **レビューで特に見るべきポイント** (3–6 件): **prospective** に "どこを見るべきか + なぜここが重要か" を列挙。
>    - 各 bullet は「〜を確認」「〜がないか検査」「〜の挙動を本人に確認」といった **prospective な表現**で書く。
>    - 焦点はコアロジック / 意思決定箇所 / 業務ロジック分岐 / 状態遷移 / 権限・tenant 境界 / データ整合性 / 設計上の意思決定 / 外部影響の起点 / 技術的に高度な部分 (並行処理・複雑な型・独自アルゴリズム等) / セキュリティリスクのある箇所 (認証・インジェクション・機微情報露出等)。
>    - mechanical なリネーム・型整形・linter が捕まえるものは拾わない。
>    - **フォーマット**: 各 item は番号付き (`1.` `2.` ...)、item 間に空行 1 行。1 行目にタイトル (何が触れられた / 何を見るべきか)、2 行目に `→` で始めて観点/理由。例:
>
>      ```
>        1. 認可ロジック (permission.companyIds) に触れている
>           → tenant 跨ぎが起きないか。全経路で WHERE 句に companyIds が入っているか確認
>
>        2. User.update() の戻り値が新インスタンスに変更
>           → 戻り値を捨てて呼んでいる既存 caller が残っていないか (grep: `user.update(`)
>      ```
>
> **禁止事項** (重要):
> - 具体的な findings (「file.ts:42 でバグ」のような file:line 付き指摘) は書かない。読みながら怪しい箇所を見つけても、**prospective な角度**に変換する (例: "この判定が `>` か `>=` か意図通りか確認") に留め、「バグである」と断定しない。
> - 「問題なし」「修正不要」等の judgement を書かない。角度の提示に留める。
> - コードの正誤判定、修正提案、confidence スコアは書かない。
>
> 出力はプレーンテキスト (markdown 可)、外枠の装飾 (L1/L2/L3 罫線) は付けない — main agent 側で整形する。

#### Subagent B — findings-only (subagent_type: general-purpose)

プロンプトの骨子:

> あなたは PR / 変更を読み、**具体的な findings (懸念点)** のみを出す役割。ブリーフィング (背景・要点・概要) は書かない。
>
> 入力: `<diff のパス>`, `<PR メタデータ>`, `<関連ドキュメントのパス>`, `<リポジトリ情報>`。必要に応じて `${HOME}/.claude/skills/review-code/references/generic.md`、該当すれば `${HOME}/.claude/skills/review-code/references/keibi-force.md` と `rules/guideline/review-*.md` 等のプロジェクトガイドラインを lazily に読む。
>
> **重点的に見る領域** (レビュワーが見落としやすい順):
> - コアロジック / 意思決定が乗っている箇所 (業務ロジック分岐、状態遷移、権限・tenant 境界、データ整合性の要、設計上の意思決定、外部影響の起点)
> - 技術的に高度な部分 (並行処理・競合状態、非同期順序、複雑な型操作、独自アルゴリズム、パフォーマンス最適化、複雑な SQL、正規表現)
> - セキュリティリスクのある箇所 (認証・セッション、SQL/command/HTML/path の injection、権限昇格、機微情報の露出、依存追加)
>
> 各 finding には:
> - 具体的な file:line 参照
> - 問題の記述 (何が / どう壊れるか)
> - 根拠 (どのルール・どの失敗モード・どのプロジェクトパターンに違反するか)
> - 修正案 (明らかなら具体案、非自明なら「本人に確認すべき問い」)
> - **confidence 0–100** スコア
>
> **confidence ≥ 75 のもののみ出力する。** 下回るものは破棄する。
>
> **拾わない (false-positive パターン)**:
> - この変更が触っていない行の既存問題
> - linter / typechecker / CI が自動で捕まえるもの (import, 型エラー, フォーマット)
> - 具体箇所を伴わない「テスト追加すべき」一般論
> - プロジェクトルールに明記されていないスタイル好み
> - 変更の declared intent に照らして意図的に見える箇所
> - PR 既存コメント (Greptile 含む) で既に指摘されているもの
>
> **禁止事項** (重要):
> - 背景・要点・変更概要・「この PR は〜を解決する」といった文章を書かない。
> - prospective な「〜を確認」系の角度リストは書かない (具体 findings でなければ出さない)。
> - 変更全体の評価や approve 可否の判断を書かない。
>
> 出力フォーマット (重要度グループごとに列挙、プレーンテキスト):
>
> ```
> [Critical (信頼度 90+)]
>
>   1. [Critical 95] <問題のタイトル>
>      path/to/file.ts:123
>
>      根拠: ...
>      修正: ...
>
>   2. [Critical 92] <問題のタイトル>
>      path/to/another.ts:45
>
>      根拠: ...
>      修正: ...
>
> [Important (信頼度 75–89)]
>
>   1. [Important 85] ...
>      path/...:...
>
>      根拠: ...
>      修正: ...
>
> [強み / 明示的によかった点]  (任意、0–3 件)
>
>   - <一言で>
> ```
>
> フォーマット規則:
> - グループ内の各 item は番号付き (`1.` `2.` ...)、item 間に空行 1 行
> - 1 行目にメタ情報 `[Critical 95]` + 問題タイトル (短く、何が壊れるか)
> - 2 行目に file:line を独立した行で (長いパスが本文を圧迫しないように)
> - 空行を挟んで `根拠:` / `修正:` を各 1 行
> - 外枠の装飾 (L1/L2/L3 罫線) は付けない — main agent 側で整形する

2 つの Agent tool 呼び出しは**同一メッセージ内**で発行すること (並列実行)。

### Step 4 — Assemble (main agent)

両 subagent の出力を受け取ったら、main agent は単純に**順序どおりに並べて整形する**だけ:

1. briefing subagent の出力 → L2 ブリーフィング (背景・要点・見るべきポイント) として配置
2. findings subagent の出力 → L2 レビュー指摘として配置

**やらないこと** (重要):

- 角度リストと findings の重なり検出・タグ付け (`[一致]` / `[角度外]` 等) はしない
- ギャップ分析セクションは作らない
- 新規の findings や角度を main agent が追加しない (独立性を損なう)

2 視点それぞれが独立に出した結果を、そのまま並べて出すことに徹する。文言の軽微な整形 (句点揃え、bullet format の統一) は可。

### Step 5 — Output

L1/L2/L3 ビジュアル階層 (ユーザーの CLAUDE.md に従う) で出力:

```
┏━━━ L1: <PR #<N>: title> もしくは <ブランチ名> ━━━┓

════════ L2: ブリーフィング ════════
  ▎背景
  ▎要点
  ▎レビューで特に見るべきポイント

════════ L2: レビュー指摘 ════════
  ▎Critical (信頼度 90+): N 件
  ▎Important (信頼度 75–89): M 件
  ▎強み / よかった点

════════ L2: 推奨 Next Action ════════
```

整形ルールは review-code と同一 (80 文字の box drawing、NBSP による中央寄せ)。

**Bullet format (重要: 見づらさを避けるため厳守)** — 「見るべきポイント」と findings 両方に適用:

- **各 item は番号付き** (`1.` `2.` ...)。後から「1 番目の件」と指せるように。
- **item 間に空行を 1 行**。詰めない。
- **1 行目 = タイトル行**: 何が / 何を見るべきか。メタ情報は `[Critical 95]` のように**左側に角括弧**で固める (右寄せは日本語等幅ずれで破綻するので不可)。
- **2 行目 = 場所 or 理由**:
  - findings の場合 → file:line を**独立した行**に置く (長いパスが本文を圧迫しないように)。
  - 見るべきポイントの角度の場合 → `→` で始めて観点/理由を書く。
- **3 行目以降 (findings のみ)**: 空行を挟まず続けて `根拠:` `修正:` を 1 行ずつ。

見るべきポイントの例:

```
  1. 認可ロジック (permission.companyIds) に触れている
     → tenant 跨ぎが起きないか。全経路で WHERE 句に companyIds が入っているか確認

  2. User.update() の戻り値が新インスタンスに変更
     → 戻り値を捨てて呼んでいる既存 caller が残っていないか (grep: `user.update(`)
```

findings の例:

```
  1. [Critical 95] tenant_id が WHERE 句に含まれていない
     apps/api/src/features/reservation/usecases/bulk-archive.ts:123

     根拠: review-api.md §3 — 認可チェックは WHERE 句で明示
     修正: permission.companyIds を WHERE 句に含める

  2. [Important 85] ログに生 email を出力している
     apps/api/src/features/user/usecases/archive-user.ts:47

     根拠: 個人情報のログ出力は禁止 (review-api.md §7)
     修正: masked ヘルパ (`a***@example.com`) を通す
```

**GitHub に投稿しない。ファイルに保存しない。** ターミナル出力のみ。

### Step 6 — Next actions

1–3 件の短い bullet。例:

- "Critical 2 件を PR comment で投げる → 修正待ち"
- "migration のロック時間を事前計測してから承認"
- "指摘なし → approve してよさそう"

---

## Principles

**2 視点の独立性を絶対に壊さない。** main agent が context gathering の段階で diff を深く読んで自分の findings や角度を形成してしまうと、subagent の独立性は意味を失う。Step 2 では diff をファイルに落とすまでに留め、深読みは subagent に任せること。

**独立生成こそが価値。** このスキルの独自価値は「angle を書くときは angle に集中、findings を出すときは findings に集中」という mode の分離にある。出力構成は普通の review-code と似るが、中身 (汚染のなさ) が違う。main agent が横着して両 subagent の出力を編集・統合しすぎると価値が薄れる。

**コスト意識。** diff とガイドラインを 2 回ロードする token コストが発生する。大規模 PR (数千行超) では main agent が事前に diff を適切な粒度で要約・分割して渡すことも検討してよい (ただし要約時に findings を形成しないよう注意 — mechanical な分割に留める)。

**既存 review-code との棲み分け**:
- 通常の PR / 中規模以下 → `review-code` で十分。
- 意思決定密度の高い変更、セキュリティ境界に触れる変更、角度と findings の相互汚染を避けたい変更 → `review-code-blind`。
