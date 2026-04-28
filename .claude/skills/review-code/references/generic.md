# Generic review reference

言語 / FW / プロジェクトに依存しない **普遍的なコードレビュー観点**。SKILL.md から常時読み込まれる。

使い方: 該当 PR に関係するセクションだけ拾う。全部読まない。該当リポジトリに専用の reference (例: `keibi-force.md`) があれば、そちらの**プロジェクト固有の観点**と併せて適用する。

プロジェクト自身の規約 (`CLAUDE.md` / `rules/` / `.cursor/rules/` 等) がある場合はそちらが最優先。ここの一般論より具体的な規約が上書きする。

---

## Universal

- **PR の宣言と実装が一致しているか**: 「小修正 X」と書いてあるのに無関係なファイルも変わっている、というズレはバグの温床
- **スコープクリープ**: 宣言にない変更が混じっていないか
- **背景コメント**: 一般常識から外れる / 他パターンから逸脱する実装には、**なぜそうしたかのコメント**をコードに残す。背景が失われると半年後に誰も理由を復元できない

## バグ / 正しさ

- Off-by-one、境界条件 (空配列、空文字、単一要素、最初/最後のイテレーション、0/-1/100、期間の最初と最後の日)
- null / undefined / missing key — optional data が存在前提になっていないか
- 非同期の順序: race condition、unhandled promise rejection、リソースを使用前に解放してしまう
- **Race condition (find then create)**: 「既存チェック → 無ければ作成」パターンは UNIQUE 制約か transaction なしでは同時リクエストで重複挿入
- **失敗時の可逆性**: 「下番 → 画像アップロード」の順だと画像失敗で再試行不可。失敗時にユーザーが自己回復できる順序を優先する
- エラーパス: silent swallow になっていないか
- 日時 / タイムゾーン: UTC vs local、DST、月末演算、モジュールロード時の日付評価は TZ バグの温床
- **リリース / migration 境界のデータ整合性**: リリース直後の移行中データ (未確定な派生値、旧形式レコードの残存) を新ロジックが誤判定しないか

## セキュリティ

- **認証・認可**: 全エンドポイントで caller が誰かのチェック + 何を許されているかのチェックがあるか。ログイン済みだけでは不十分
- **認可はバックエンドで強制**: フロントで button を隠すだけでは脆弱
- **テナント / 組織境界**: マルチテナントで全クエリがテナントフィルタ越しになっているか。`findAll` / `SELECT *` でフィルタなしのものに注意
- **入力検証**: 境界で validate されているか。sanitize されていない入力がそのまま下流に流れていないか
- **secret の定義**: 「クライアントに公開される前提かどうか」で判断する。名前が API_KEY でも公開前提なら env で OK、ドメイン制限など別経路で守る
- **secret の取得タイミング**: 動的取得 (SSM, Secrets Manager) はオーバーヘッドあり。ローテーション前提でなければ deploy 時に解決する選択肢もある
- **データマスキングは仕組みで継続**: 新項目追加時のマスク漏れを検知する仕組み (lint / スキーマ / code review の観点) をセットで設計する
- **injection**: SQL / NoSQL / command / header / template / log / path traversal
- **regex DoS**: ユーザー入力が catastrophic backtracking を起こす regex に渡っていないか
- **暗号**: 独自 crypto 禁止、セキュリティ用途で MD5 / SHA-1 禁止、セキュリティ乱数に `Math.random()` 禁止

## パフォーマンス

- **N+1**: ループ内で DB / API を呼ぶパターン
- **Unbounded fetch**: LIMIT / pagination なしのクエリ
- **ページネーションは DB 側で**: 全件取得してアプリで切る実装は NG
- **JOIN の次元爆発**: 多段 JOIN (A × B × C) で数百万行オーダーになる可能性を事前に見積もる。Lambda 15 分 / メモリ制限に引っかからないか
- **グルーピングで呼び出し回数削減**: 同じクエリを N 回回すより 1 回 groupBy
- **インデックス**: 新規 WHERE / ORDER BY 対象列にインデックスがあるか。よくフィルタされる列 / 複合 index の漏れに注意

## テスト

- **境界 / エッジケースをテストしているか**: 空、null、最大値、ほんとに問題になる稀な状態
- **Given / When / Then で構造化**: 上から下に読める形に
- **assertion 強度を目的に合わせる**: 「このテストは税額を検証したいわけではない」なら `expect.any(Number)` に弱めて、意図と無関係な変更で落ちないようにする
- **テスト名はプロダクト用語で書く**: 変数名ではなく、ユーザーが使う画面・帳票・操作の語彙で
- **実装 vs テスト**: 齟齬があればどちらが正しいか判断する。迷うなら実装者に確認

## API 設計 (バックエンド)

- **RESTful URL**: `/resources/:resourceId` は単体 GET、一覧は `/resources?filter=...` のクエリで
- **POST vs GET**: 単純なフィルタは GET、複雑な構造や機密がクエリに乗るときは JSON body の POST
- **無駄なパラメータ / フィールドを乗せない**: ページネーションしない endpoint に `count` / `currentPage` を返さない、親 ID から derive できる子 ID は request に不要
- **レスポンスに異質なものを混ぜない**: 「A の fetch なのに B の情報も返す」は分離するか名前を変える
- **endpoint の分割 vs 統一**: 処理が異なるなら分ける、同系統の登録処理は Command のフラグで統一する判断軸
- **レスポンス形状の一貫性**: フィールド名、エラー形式
- **handler は委譲のみ**: onSuccess / onError は usecase 側に定義、handler はそれを呼ぶだけ。handler に usecase ロジックが表出しないように

## エラーハンドリング

- **レイヤー境界でエラー型を分ける**: infra で起きるのは `InfraError`、usecase で起きるのは `UsecaseError` のように、依存方向と整合するエラー型
- **複数エラーをまとめる**: 1 つずつ throw させず `CompoundError` 的に束ねて返す設計を検討。都度修正させないため
- **ログレベルが意味と合っているか**: ユーザー起因の HTTP 4xx を `Logger.error` に出すと監視ツールのノイズになる。`warn` / `info` に落とす
- **生の `Error` を throw しない**: ドメイン型のエラーを定義して投げる

## フロントエンド

- **コンポーネントの責務**: 1 つが fetch + transform + 表示 + イベント + state 全部やっていないか
- **state の位置**: ローカルで十分なのに上に持ち上げてないか / 逆もまた然り
- **書き込み可能 state の公開範囲は最小に**: グローバル化 (store / atom) するより component 内に閉じ込められるなら閉じる
- **set* より on* で props を受ける**: `setIsOpen` 直渡しより `onOpenChange`。親子の結合を弱め、親が state を持たない実装にも差し替えやすい
- **effect の依存**: 依存配列が正しいか、ループしないか
- **再レンダリング hotspot**: 親の再レンダー毎に重いコンポーネントが再レンダーされていないか (memo 漏れ)
- **`useEffect` でのフォーム値同期はアンチパターン**: `useEffect(() => setX(...), [watchedValue])` の形は避ける。controlled form で完結させる
- **`useMemo` の内側で副作用禁止**: store.set など副作用を memo に書かない
- **非同期 handler の loading 状態**: ボタンに loading prop を接続、二度押し防止
- **Tailwind 等の静的 class scan の罠**: 動的に組み立てた class 名 (`` `text-${color}` ``) は scan されず効かない。動的な色・サイズは `style` 属性で
- **CSS で済むことを JS でやらない**: サイズ計算や媒体分岐を `useEffect` で書くより CSS 側で解決できないか。例: ビューポート基準は `100dvh`/`100svh`、コンテナサイズ連動は container query / `clamp()`、動的な値は CSS 変数 + `calc()`、表示切替は `@media` / `@container`
- **文字数 split は壊れる**: サロゲートペア / 絵文字 / 結合文字で意図しない位置で切れる。`truncate` クラスや `Intl.Segmenter` を使う
- **画面遷移後の復元 vs 一時値**: 復元したいなら cookie / sessionStorage、一時値は URL query で分ける
- **JS 無効 / 低性能環境の考慮**: 遷移は `<Link>` 系で、JS を前提にしない構造が取れないか (対象ユーザー層次第)

## DB / マイグレーション

- **デプロイ中の後方互換**: 本番トラフィックに対して安全に走るか。列 rename と使用を 1 つのデプロイでやらない。add + backfill + switch + remove に分割
- **ロック**: 大規模テーブル (>10k 行) の UPDATE / ALTER TABLE は書き込みをロックする。chunked backfill
- **ロールバック計画**: 逆転可能か、少なくとも中断時の mitigation があるか
- **インデックス**: よくフィルタされる列、複合 index の漏れ。primary key には重ねない
- **FK 制約**: 参照列には FK を付ける。同じ migration で他の参照列には付いているのにここだけ無いのは怪しい
- **カラム命名の一貫性**: camelCase / snake_case の混在、単数 / 複数の不揃い
- **migration の順序依存**: ゼロから走らせても落ちない状態を保つ。hotfix の先行 migration を暗黙に前提にしない
- **dev / staging と本番のスペック差**: dev で通っても本番で timeout する可能性を考える

## 命名 / 可読性

- **boolean は `is*` / `has*` / `can*` / `should*` / 状態動詞の 3 人称単数現在**: `active` より `isActive`
- **`check*` で始まる命名は true/false の意味が曖昧**: `checkOverlap` は重複あり時に true なのか false なのか不明 → `hasOverlap` のように意味を明示
- **動作より意味で命名**: `epochTo`(何の終わりか不明) より `dueDate` のように「何」を示す名前に。汎用すぎず / 具体すぎず
- **略語を避ける**: `assign` より `Assignment`、`perf` より `performance`
- **constants と enum 系の string literal union は UPPER_SNAKE_CASE**: `type Status = 'draft' | 'approved'` より `type Status = 'DRAFT' | 'APPROVED'`
- **JSX を返す関数は `render*`**
- **ディレクトリ名は機能拡張時に見直す**: `approve` だけだったのが `reject` も入ったら `decision` / `review` に
- **ディレクトリ階層を兄弟で揃える**

## 型設計

- **型で表現できるならランタイムチェックに落とさない**: 例えば URL バリデーションなら `HttpsUrl` 型を受け取る関数にして、ランタイムチェックを呼び出し側に押し出す
- **Discriminated union で分岐を型安全に**: フィールドの形が種類ごとに違うなら type による分岐
- **`filter` の返り値に type predicate**: `.filter((x): x is T & { perf: NonNullable<...> } => ...)` とすると後段で narrow が効く
- **引数は最小限**: 親オブジェクトを受け取るなら子 ID は渡さない (derive 可能)。使わないパラメータを interface に残さない
- **`??` と `||` の使い分け**: `??` は null/undefined 用、`||` は空文字・0 なども弾くとき。**同一関数や register/update の pair で混ざる**と空文字の扱いが非対称になり重大バグ
- **部分更新で null 上書き**: spread による部分更新は null を上書きしない。明示的な null 代入が必要
- **`as` は最後の手段**: `as any` / `as unknown as T` / 非 null `!` は赤信号。理由のコメントなしで通さない

## コード構造

- **単一責任**: 1 関数が 1 つのことをする、1 モジュールに 1 テーマ
- **重複**: 3 箇所以上に同じロジックがコピペされていると、1 箇所だけ直すバグ待ち
- **dead code**: 使われていない export、到達不能なブランチ、古い feature flag、deprecated なまま残ったファイル
- **抽象化レベル**: 呼び出し側が 1 つなら抽象化不要、3 つあるならインラインでなく切り出し

## 運用 / 変更管理

- **terraform / IaC の適用状況**: インフラ PR マージ後に `terraform plan` に差分が残っていないか (適用漏れ検出)
- **削除漏れ / 残り物**: 機能削除 PR で、使われなくなった schema / migration / テンプレ / interface / props / 不要フィールドが残っていないか
- **無関係なコミットの混入**: 別タスクの migration や変更が紛れ込んでいたら削除提案
- **外部サービス制約の UX 迂回**: サービス側の制約 (送信ドメイン固定、上限サイズ) を、ユーザーが意識しないで済む形で逃がす (replyTo、署名 URL アップロードなど)

## 影響範囲 / 整合性

- **横展開漏れ**: 新しい要素を追加する PR で、同じ要素を扱う別箇所 (form、model、migration、UI、ability 定義など) に反映漏れがないか
- **対称性**: 同じ業務ロジックを異なる主体に適用するケース (通常 ⟷ 例外、自社 ⟷ 外部、デモ ⟷ 本番) で、片方だけ変わっていないか
- **同じ正規化処理が複数箇所に重複していないか**: VO / ドメイン model の `construct` に集約できないか
- **仕様 / seed / feature flag / 本番データの意味論矛盾**: 名前と中身、flag と UI の整合
