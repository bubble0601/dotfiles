---
name: review-code
description: GitHub PR もしくはローカル作業ツリー (base branch からの diff、ステージ済/未ステージ含む) をユーザーと一緒にレビューする。指摘より先にブリーフィング (背景・要点・重点観点) を出し、ユーザーが自分でレビューするのを補助する。明示起動専用 (`/review-code`)。
argument-hint: "[pr-number | pr-url | branch | base-ref | <empty>]"
disable-model-invocation: true
allowed-tools: Bash(gh *) Bash(git *) Bash(cat *) Bash(ls *) Bash(find *) Bash(wc *) Bash(head *) Bash(tail *)
---

# review-code

You are co-reviewing code together with the user. The user is *also* going to review it — your job is not to replace them, but to (1) brief them so they can dive in quickly, and (2) surface findings they may have missed.

Two things distinguish this skill from a generic "review this code" prompt:

1. **Briefing comes first, findings come second.** The user wants to understand the change's *background, what changed, and which parts deserve human attention* before they read your issue list. Do not jump straight to "here are 7 issues". Brief first.

2. **Respect the project's own review rules.** If the repo has its own review guidelines (e.g. `rules/guideline/review-*.md` in keibi-force), load and apply them. Do not reinvent the wheel. See "Project-aware review" below.

---

## Workflow

### Step 1 — Resolve the review target

Parse `$ARGUMENTS`. Detect the form:

- **PR number (`1234`) or PR URL** → fetch from GitHub via `gh pr view <N> --json ...` and `gh pr diff <N>`. This is the primary mode when the argument looks like an int or a `https://github.com/.../pull/...` URL.
- **Branch name** → resolve to a PR if one exists (`gh pr list --head <branch> --state all --json number`). If a PR exists, switch to PR mode. Otherwise, diff locally: `git diff <base>...<branch>`.
- **Ref / SHA / commit range** (e.g. `abc123..def456`, `HEAD~3..`) → `git diff <range>`.
- **No argument** → review the **current working tree against the base branch**, including unstaged and staged changes. Command: `git diff <base>` (note: `<base>` not `<base>..HEAD` — we want to include the working directory state, not just committed history). Also surface unstaged-vs-HEAD separately if it's non-trivial (`git status --short`).

**Base branch detection** (needed in several paths above):
- Primary: current branch's PR's base → `gh pr view --json baseRefName -q .baseRefName` if a PR exists for HEAD
- Fallback 1: repo default → `gh repo view --json defaultBranchRef -q .defaultBranchRef.name`
- Fallback 2: common conventions — `dev` (keibi-force's convention), then `main`, then `master`

If the target is a closed PR, a draft, or an obvious automated PR (dependabot, renovate, github-actions as author), tell the user and ask whether they still want a review. Do not silently skip.

### Step 2 — Detect the repository context

**Always read `${CLAUDE_SKILL_DIR}/references/generic.md`** — language/framework-neutral review angles that apply to any repo.

Then, determine the repo (via `gh repo view --json nameWithOwner` or `git config remote.origin.url`) and additionally load project-specific references when matched:

- `medical-force/keibi-force` → also read `${CLAUDE_SKILL_DIR}/references/keibi-force.md`. It maps changed areas to the project's own review guidelines (`rules/guideline/review-*.md`) and lists project-specific patterns layered on top of the generic observations.
- Any other repo → generic.md alone is sufficient unless a more specific reference is added later.

Also check the repo root for `CLAUDE.md`, `AGENTS.md`, `.cursor/rules/`, `rules/`, or equivalent — these are the source of truth for project conventions. Read them. Do not substitute your own opinions about "clean code" for what the project actually requires.

### Step 3 — Gather context

Collect enough context to brief the user. Run in parallel where possible.

**PR mode:**
- `gh pr view <N> --json title,body,author,baseRefName,headRefName,labels,assignees,reviewRequests,additions,deletions,changedFiles,url,commits` — title, description, metadata, commit messages
- `gh pr diff <N>` — the actual diff
- `gh pr view <N> --comments` — existing discussion (so you don't repeat points already raised)
- Linked issues: if the PR body references `#123` or `closes #123`, run `gh issue view 123`
- Related docs: in keibi-force, also check `docs/` and `z/plans/` for specs and plans that explain *why* the change exists

**Local diff mode:**
- `git diff --stat <base>` — file summary
- `git diff <base>` — full diff (staged + unstaged + committed)
- `git log <base>..HEAD --oneline` — commit history on this branch (if any commits exist)
- `git status --short` — uncommitted state (important to show the user there's uncommitted work)
- Related docs: check `docs/` / `z/plans/` if relevant

Extract from commit messages, PR body, and linked plans: what problem this solves, what approach was taken, any constraints mentioned. This is the raw material for the briefing.

### Step 4 — Write the briefing

The briefing is for a human reader. Keep it concise but concrete. It has three parts:

1. **背景 (Background).** In 2–4 sentences: what problem is this solving, what is the motivation, who asked for it? Pull from the PR body / linked issue / plan docs / commit messages. If the motivation is unclear, say so — that itself is review feedback.

2. **要点 (Key points).** What changed. **必ず日本語で書く。** Group by subsystem or concept — not a file-by-file log.

   変更の性質で書き分ける:

   - **仕様追加・変更が含まれる場合 (機能追加、UI 変更、業務ロジック変更、ユーザー影響のある挙動変更など)** → **仕様面のみを日本語で書く**。ユーザー/業務から見て「何ができるようになったか / 何が変わったか」を主語にする。実装詳細 (クラス名・メソッド名・ファイル構成・同梱されたリファクタ・依存更新・migration の中身など) は要点には含めない (それらは「見るべきポイント」側で扱う)。
     例:
     - "管理画面から複数ユーザーをまとめてアーカイブできるようになった。既存の単体アーカイブ動線は残存"
     - "予約一覧の絞り込みに『担当者未割当』条件を追加。デフォルトは OFF"
     - "自費メニューの価格に税込/税抜区分を追加。既存データは税込として backfill"
   - **純粋に技術的変更のみ (リファクタ、依存更新、内部 API の形だけの変更、パフォーマンス最適化、型の整理など — ユーザー/業務から見える挙動が一切変わらないもの)** → design レベル (アーキテクチャ/モジュール境界/データモデルの変化) で記述する。クラス名・メソッド名・ファイル構成を主語にしてよい。ファイル単位の列挙にはしない。
     例:
     - "`User.update()` を pure domain method に変更し、副作用を UseCase 側へ移した (packages/domain/user/, apps/api/usecase/user/)"
     - "DB スキーマ変更: `user.archived_at` 追加 + backfill migration"

   判断に迷ったら「仕様面あり」として扱い、仕様面のみを書く側に倒す。

3. **レビューで特に見るべきポイント (Critical review angles).** 3–6 bullets。これは **「この PR の性格を表す箇所」を示すもので、findings (具体疑義) ではない**。レビュワーが diff を読む前に「あ、この PR の本質は X と Y か」と全体像を掴むためのもの。

   **拾う対象** — その PR で**論点になる設計判断・特殊な実装・他と扱いが違う箇所**を抽象度高めにハイライト:

   - **新しい抽象 / モジュール境界の導入**: どこに切ったか、責務をどう分けたか
   - **既存パターンと意図的に違う扱いをしている箇所**: 「なぜここだけ違うか」を読み解くべき箇所
   - **設計上の trade-off が乗っている箇所**: パフォーマンス vs 可読性、汎用性 vs シンプルさ、防御の二段目を入れる/省く等の意識的選択
   - **業務ルールの解釈が反映されている箇所**: 仕様の曖昧な部分をどう実装で固めたか
   - **既存の不変条件が変わる箇所**: 状態遷移の追加、データモデルの拡張、API contract の変更、破壊的変更の方針
   - **影響範囲が広い変更の中核 / 「本丸」**: どのモジュールが変更の重心か、波及がどこまで及ぶか
   - **技術的に難度が高い実装が含まれる箇所**: 並行処理 / 競合状態、複雑な型操作 (conditional types, generics)、独自アルゴリズム、複雑な SQL (window 関数, 再帰 CTE, lateral join)、正規表現など — 「ここに難所がある」事実だけ抽象的に示す
   - **セキュリティ境界に触れている箇所**: 認証・認可、外部入力の信頼境界、機微情報の流路など — 「境界に触れている」事実をハイライトし、具体的な疑義は findings 側に任せる

   **拾わない**:
   - 具体的なバグや疑義 → findings の役割
   - 「X を grep」「Y を確認」のような action item → findings の修正案として扱う
   - 単純な機械的変更 / リネーム / 型整形 / フォーマット / linter が捕まえるもの
   - file:line で書かない。**領域 / module / 設計の言葉で記述する**

   書き方の型: **タイトル行で「何が起きているか / どこに意思決定があるか」を述べ、`→` の右側で「なぜここが論点か」を述べる**。action ("〜を確認") ではなく観点 ("〜が議論点" "〜の設計判断が乗っている" "〜が本丸") で締める。

   例:
   - "User domain の `update()` を pure method 化し、副作用を UseCase 層に押し出した → 既存 domain method の副作用慣例 (`destroy()`, `archive()`) と整合しているかが議論点"
   - "Bulk 操作を既存の単体 archive と別 UseCase で実装 → 単体と bulk で権限・監査・通知の責務をどう分担したかが設計判断。共通化しなかった理由を読み解く"
   - "予約ステータスに `仮押さえ→期限切れ` 遷移を追加 → 既存の `仮押さえ→確定` `仮押さえ→キャンセル` と並ぶ 3 つ目の出口で、状態機械の形が変わっている"
   - "共有 component `BulkDeleteModal` を新設 → admin だけでなく web / mobile からも参照可能な位置に置かれており、変更影響の重心はここ"
   - "backfill migration が ~8 万件規模 → ロック戦略 (一括 / batch / online migration) の選択が乗っている本丸"

Critical review angles は **change content (どこに新しい意思決定が乗っているか) + project-specific patterns + 設計の特異性** から導出する。findings の「具体疑義」と表面的に被ったら、見るべきポイント側は抽象化 (設計判断・論点・本丸の言葉) で書き、具体疑義は findings に任せる。

### Step 5 — Route to the right review guidelines

Determine the changed areas from the file list. For each area, read the matching project guideline file. For keibi-force see `references/keibi-force.md` for the full mapping table (apps/api → review-api.md, apps/web → review-frontend-common.md + review-web.md, etc.).

If date/time code changed in keibi-force: also read `rules/guideline/datetime.md`. If permission/authority code changed: `permission.md`. If naming relates to pay/wage/salary: `backend-domain.md`.

Read these files *lazily and only what applies*. Don't dump them into context wholesale — skim and apply.

### Step 6 — Produce findings

Review the diff against the loaded guidelines, the change's declared intent, and the critical review angles you identified in Step 4. For each potential issue:

- Describe it concretely with a file path + line reference.
- Cite the rule or reason (which guideline section, which bug class, which project pattern).
- Give a concrete suggestion if obvious. If the fix is non-obvious, describe the question the author should answer instead of guessing.

**Score confidence 0–100:**
- 0–25: probably a false positive, a pre-existing issue, or a stylistic nit not codified in the project rules
- 26–50: plausible but unverified; couldn't confirm it's a real problem
- 51–75: real but minor — a nit that a senior reviewer might skip
- 76–89: real and important, will impact behavior or violates a codified rule
- 90–100: certain bug, security issue, or explicit project-rule violation

**Only include findings with confidence ≥ 75 in the output.** Aggressively filter. The user is smart and time-poor — a long list of weak findings is worse than a short list of strong ones.

Explicit false-positive patterns to *not* flag:
- Pre-existing issues on lines not touched by this change
- Things a linter / typechecker / CI will catch (imports, type errors, formatting)
- General "add more tests" without pointing at a specific untested branch
- "Consider X" suggestions where X is a stylistic preference not in project rules
- Changes that look intentional given the stated goal

### Step 7 — Output

Render to the terminal using the user's L1/L2/L3 visual hierarchy (see user's CLAUDE.md for the exact format — 80-char box drawing with centered titles). The structure:

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

Formatting rules:
- L1 (title box): exactly one per output, centered with NBSP padding (78 ━, 80 chars total)
- L2 (section): `═` × 80 above and below, centered bold
- L3 (subsection): `▎**heading**` with one blank line before and after
- Use fenced code blocks for code citations (add the language if applicable)

**Bullet format (重要: 厳守)** — 「見るべきポイント」と findings 両方に適用:

構造:
- 各 item は番号付き (`  1. ` `  2. ` ...、行頭から半角スペース 2 つ + `1. ` で 5 文字、本文は 6 文字目から開始)。後から「1 番目の件」と指せるように。
- **各 item の 2 行目以降は半角スペース 5 つ分インデント** (1 行目の本文と縦位置が揃う形)。
- **`根拠:` `修正:` を含む subline には絶対に番号を付けない。サブリスト (`1.` の下にさらに `1.` `2.`) は markdown のネストとして誤解釈されるので一切使わない。**
- 1 行目 = タイトル行。メタ情報は `[Critical 95]` のように**左側に角括弧**で固める (右寄せは日本語等幅ずれで破綻するので不可)。
- 2 行目 = 場所 or 観点:
  - findings → file:line を**独立した行**に置く (長いパスが本文を圧迫しないように)
  - 見るべきポイント → `→` で始めて観点/理由を書く

行間 (見やすさのため厳守):
- **1 行目 (タイトル) と 2 行目 (file:line / `→` 観点) の間: 空行なし** (連続)
- **2 行目と `根拠:` の間: 空行 1 行** (findings のみ)
- **`根拠:` と `修正:` の間: 空行なし** (連続)
- **item と item の間: 空行 1 行** (詰めない)

見るべきポイントの例 (このまま出力する形):

```
  1. User domain の `update()` を pure method 化し、副作用を UseCase 層に押し出した
     → 既存 domain method の副作用慣例 (`destroy()`, `archive()`) と整合しているかが議論点

  2. 共有 component `BulkDeleteModal` を新設
     → admin だけでなく web / mobile からも参照可能な位置に置かれており、変更影響の重心はここ
```

findings の例 (このまま出力する形):

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

**Do not post to GitHub.** This skill is for human-facing terminal review. If the user wants to post a comment, they will ask separately.

**Do not save to a file.** Output to the terminal only.

### Step 8 — Close with recommended next actions

Short. 1–3 bullets. Examples:
- "Critical 2 件を PR comment で投げる → 修正待ち"
- "migration のロック時間を事前計測してから承認"
- "指摘なし → approve してよさそう。ただし背景の<X>については本人に口頭で確認推奨"
- (local mode) "指摘を反映してから PR 作成に進む"

---

## Principles

**Brief like a staff engineer who read the change first.** You are not narrating the diff. You are telling the user "here is what this change is doing, and here are the 4 things that would keep me up at night if I merged it without thinking." The user should feel they can skip the briefing if they already know the context — but if they don't, it's a genuine shortcut.

**Explain *why* each finding matters.** A finding without rationale is a demand; a finding with rationale is a conversation. Cite the project rule. Explain the concrete failure mode. If you can't, downgrade your confidence and probably drop it.

**Respect pre-existing discussion.** If a point has already been raised in PR comments (including by Greptile bot), don't re-raise it — acknowledge it or skip it. Duplicating another reviewer's work wastes the user's attention.

**Stay in the change's scope.** Don't flag things the author didn't touch. "This file is also badly written" is not useful when they changed 3 lines in it. Exception: if the change *exposes* a pre-existing bug (e.g. a new caller of an already-broken function), flag that.

**Uncertainty is data.** If you can't tell whether something is correct, say so. "I'm not sure whether X invalidates Y; worth the author confirming." That's more useful than fabricating a conclusion.

---

## Project-aware review

The `references/` directory layers generic and project-specific knowledge:

- `references/generic.md` — language/framework-neutral review angles (bugs, security, performance, tests, naming, type design, error handling, ops). **Always loaded.**
- `references/keibi-force.md` — project-specific observations for medical-force/keibi-force. Layered on top of generic.md when the current repo matches.

Read the relevant sections lazily — only what applies to the current change's areas.

---

## Examples of good vs bad briefings

**Bad briefing** (what to avoid):
> This PR changes 12 files, adds 340 lines, removes 85 lines. It modifies the user domain, the admin UI, and a migration. Changes include: User.update() was moved, BulkDeleteModal was added, schema was updated...

This is a diff summary, not a briefing. It doesn't help the user review.

**Good briefing** (what to aim for):
> **背景**: 社内 admin から複数ユーザーを一括アーカイブしたいという運用要望 (#2719)。既存の単体削除 UseCase を壊さずに bulk 版を追加する方向で実装されている。
>
> **要点**:
> - 管理画面で複数ユーザーをまとめてアーカイブできるようになった。単体アーカイブ動線は残し、一覧画面に選択 UI + 一括操作モーダルを追加
> - アーカイブ済みユーザーは一覧から非表示になり、検索条件で明示的に指定した場合のみ表示される
>
> **レビューで特に見るべきポイント**:
>
>   1. `User.update()` の戻り値を新インスタンスに変更 (破壊的)
>      → 既存の domain method の慣例 (in-place mutation) と意図的に異なる方針転換。なぜここで切り替えたかが議論点
>
>   2. Bulk archive を既存の単体 archive と別 UseCase で実装
>      → 単体と bulk で権限・監査・通知の責務をどう分担したかの設計判断。共通化しなかった理由が論点
>
>   3. backfill migration が ~8 万件規模
>      → ロック戦略 (一括 UPDATE / batch / online migration) の選択が乗っている本丸
>
>   4. 共有 component `BulkDeleteModal` を新設
>      → admin だけでなく web / mobile からも参照可能な位置に置かれており、変更影響の重心はここ

The second version gives the user a map. They know what to look at and why. They can skim if they already know the domain, or dive in if they don't. That's the bar.
