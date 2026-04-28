# keibi-force 固有レビュー参照

現在のリポジトリが `medical-force/keibi-force` のときだけ読み込む。`generic.md` (言語 / FW 非依存の普遍観点) は常時ロードされているので、ここには**プロジェクト固有のもの**だけを書く。

「地図」として使う — PR で変更された領域に該当するセクションだけを拾い読みし、該当しないセクションはスキップする。

---

## 1. リポジトリ概要

- モノレポ: Yarn 4 workspaces + Turbo、Node 22、TypeScript 5.9 strict
- `apps/api` — Hono + Prisma、DDD (presentation / usecase / infra / domain)、DI は Inversify、CQRS 分離、`softDelete` Prisma 拡張
- `apps/web` — Next.js App Router、権限は CASL、データ取得は SWR + Aspida、ステート管理 Jotai、並列ルート `@pc`/`@sp`
- `apps/admin` — Next.js、社内管理画面
- `apps/mobile` — Next.js + LINE LIFF
- `packages/domain`、`packages/value-object`、`packages/interface` (Command/Query/DTO)、`packages/lib` (Aspida API 定義 — 新規の共通化置き場としては deprecated)、`packages/ui`
- マルチテナント: Brand / Company / SharingCompanyGroup。Permission は 4 種 (Default / SharingCompany / OtherSharing / Brand)。行レベルセキュリティは `companyId IN permission.companyIds`
- 日時: DB/API は ISO UTC 文字列。コード内は `Time` / `KeyDate` value object を経由 (JST 基準)。生の `new Date()` は禁止
- チーム運用: Greptile bot が一次レビューを自動実行、人間レビューが補完

---

## 2. 変更領域 → 適用ガイドライン

PR で変更されたパスに該当するガイドラインを読んでから指摘を組み立てる。全部読まず該当するものだけ。

| 変更パス                  | 読むファイル (すべて `rules/guideline/` 配下)                                                                 |
| :------------------------ | :----------------------------------------------------------------------------------------------------------- |
| `apps/api/`               | `review-common.md` + `review-api.md`                                                                         |
| `apps/web/`               | `review-common.md` + `review-frontend-common.md` + `review-web.md`                                           |
| `apps/admin/`             | `review-common.md` + `review-frontend-common.md` + `review-admin.md`                                         |
| `apps/mobile/`            | `review-common.md` + `review-frontend-common.md` + `review-mobile.md`                                        |
| `packages/domain/`        | `review-common.md` + `review-api.md`                                                                         |
| `packages/value-object/`  | `review-common.md` + `review-api.md`                                                                         |
| `packages/lib/`           | `review-common.md` + `review-lib.md`                                                                         |
| `packages/interface/`     | `review-common.md` + `interface.md`                                                                          |

常時適用の補助ファイル (PR がそのトピックに触れる場合のみ):

- 日時 / スケジュール / 勤怠ロジック → `datetime.md`
- 権限 / ability / CASL / role / authority → `permission.md`
- pay / wage / salary / premium / dayOff の命名 → `backend-domain.md`
- Repository と QueryService の使い分け → `backend-repository.md`
- 新規 migration → `apps/api/prisma/migrations/` 配下の既存実装を参照

---

## 3. 認可 / 権限

- **新しい authority 追加時の横展開漏れ**: migration / `packages/domain/user/model.ts` / CASL subject 定義 / `userForm.tsx` (admin 版も) / ヘッダ・メニュー表示 (`can('read', SUBJECT)`) のすべてに反映されているか
- **既存ユーザーへのデフォルト付与方針を明示**: 新権限追加時に既存ユーザーに ON / OFF どちらで配るかは暗黙にせず合意形成する
- `presentation/private/*.ts` の新規 GET route には `checkAuthority` が必須 (ID 指定 fetch でも存在有無の情報漏洩になる)
- **Permission 種別の使い分け**: 配置・支社またぎが絡む fetch は `SharingCompanyPermission`、単一ブランド内は `BrandPermission`。配置データは「アクセス元事業所と隊員所属事業所が違う」ケースを必ず考慮
- **permission は repository に埋め込まず呼び出し側で差し替える**: repository は受け取った permission を使うだけ。支社またぎが要る呼び出し側で `SharingCompanyPermission` を渡す構造にする

## 4. マルチテナント / 行レベルセキュリティ

- **`findManyBy*` / `update*` / `delete*` の WHERE には `companyId IN permission.companyIds` を必ず含める**。欠けるとテナント越境
- **`findById` は permission 不要** — ID を知っている前提で単一レコード取得する用途
- ただし findById 結果を起点に別テーブルを引く場合は、その場所で permission を適用する
- admin / `bypass` Prisma クライアントは意図的な cross-tenant のみで使用
- **共有マスタの扱い** (SharingCompanyGroup 内でどこまで共有するか):
  - **原則共有** (グループ内で同じものを使う): 申請シフト種別 / 業務パターン / 資格 / 従業員区分 / 隊員タグ / 備品
  - **場合によって共有** (会社ごとに分かれるケースもある): クライアント / 予定 / 隊員
  - 新規マスタ追加 / 既存マスタの共有範囲変更 PR では、上のカテゴリどちらに倣うべきかを明示し、それに沿って `SharingCompanyPermission` / `BrandPermission` / `DefaultPermission` を選ぶ

## 5. Migration

- **RLS**: 新規テーブルには RLS policy が必要。`prisma migrate` と deploy script の二重管理を避ける
- **UPDATE / DELETE は件数検証**: `GET DIAGNOSTICS` + `RAISE NOTICE`、想定外件数なら `RAISE EXCEPTION`。0 件成功でサイレント失敗を防ぐ
- **soft delete と組み合わせた unique 制約**: PostgreSQL では NULL 同士は等価と見なされない → `CREATE UNIQUE INDEX ... WHERE "deletedAt" IS NULL` の部分インデックス。Prisma の `@@unique` ではネイティブ表現できない
- **softDelete 対象に NOT NULL カラム追加時の履歴データ**: backfill は削除済みレコードも含めて埋める (NOT NULL 制約エラー防止)
- **TZ の明示**: SQL 内で `CURRENT_TIMESTAMP` を直接使うときは `TO_CHAR(... 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"')` 等で UTC であることを明示。JST 基準のフィールド (`scheduleのstartAt` など) との変換を忘れない
- **同一機能の migration は 1 本に統合**: PR 内で機能的に一体の migration が複数あれば統合を提案
- **`schema.prisma` は自動生成ファイル** (`apps/api/src/infra/repositories/*/schema.prisma`)。diff に現れたら flag
- migration で値を保証したら、コード側で `|| fallback` を書かない。二重防御はバグの温床

## 6. Domain / model (ドメイン設計)

- **集約境界を越える参照・更新を禁止**: ある集約の repository から別集約のテーブルへ直接クエリ / 更新しない。別集約のデータを持ちたくなったら repository / queryService の責務分離を疑う
- **Bounded Context を壊してまで既存資産を流用しない**: 「採用文脈の資格要件」と「管制文脈の資格」など、コンテキストが違うなら relation を張らない
- **3 メソッドパターン**: `construct()` / `update*()` / `reconstructFromRepository()` 以外が増えていたら疑う
- **バリデーションは `create` / `update*` に書く、`constructor` (= reconstruct) に書かない**: constructor は DB からの復元でも呼ばれる。別値更新や復元時に無関係な制約チェックが走ると問題
- **`update*()` は新インスタンスを返す (immutable)**。戻り値を捨てている caller はバグ
- **ドメイン制約 (数値範囲、cross-field invariants) は domain model 側に置く**。usecase / repository に散らばっていたら domain に寄せる方向で指摘
- **複数値の同時更新強制**: ドメイン上不可分なフィールド (退職日と事由、status と period、税込/税抜、交通手段→料金など「片方が真実で他方は導出」の関係) は単一の update メソッドで更新させる。片方だけの update メソッドがあれば整合性が崩れる
- **VO の `create` / `construct` は自分自身の型以外を返してはいけない**。null を返しうるなら VO 自体を `T | null` にして呼び出し側の責務にする
- **VO のメソッドの第一引数は自身の型**: `RestTimeRecord.method(first: RestTimeRecord, ...)` のように。そうでないなら VO のメソッドではなく汎用関数に切り出す
- **`T?` / `T | undefined` より `T | null` を明示** (domain 層)

## 7. Usecase

- 振る舞いが絡むなら repository 直接呼び出しではなく domain model を経由
- CSV / PDF / Excel のバイトレスポンス (`Uint8Array`) は shared util 経由
- **queryService は薄く保つ**: パラメータに応じて DTO を返すだけ。判定ロジック・条件分岐は usecase 側に置く。queryService で if を増やさない
- **非同期 job 経由ではログインユーザーは DIContainer から**: getter で引き回さず inject
- **エラー型はレイヤーで使い分ける**: `DomainError` (ドメイン制約違反、domain model から) / `UsecaseError` (ユースケース実行時の業務エラー、権限・状態遷移など) / `InfraError` (DB / 外部 API / ストレージ等のインフラ失敗) / `ParseError` (Command / Query 層での入力パース失敗)。依存方向 (infra → usecase → domain は NG、逆方向は OK) と整合させる

## 8. Repository / Prisma

- **命名**: `findBy*` は単数返し、`findManyBy*` は複数返し、`findMany` / `findManyBy*` が基本 (`findAll` より filter/pagination 前提の `findMany` 系を推奨)
- **soft delete と `deletedAt IS NULL` の扱い**:
  - raw SQL: Prisma extension が効かないので **どのテーブルに対しても自前で `deletedAt IS NULL` を付ける**
  - QueryService / 通常の Prisma 呼び出し: 1 層目 (`prisma.guard.findMany` なら `guard`) は extension が自動付与するので **不要**。ただし `include` / `select` で relation 取得する側 (例: `assignment`) には extension が効かない → **relation 側には明示が必要**
- **1 対多の FK は多側に**: FK を 1 側のテーブルに持たせていたら逆転させる

## 9. `as` 型アサーションの分類

generic.md の「`as` は最後の手段」を受けて、keibi-force ではさらに文脈別に扱う。

| 形                                    | 例                                                | 対応                                                                             |
| :------------------------------------ | :------------------------------------------------ | :------------------------------------------------------------------------------- |
| (a) DB 取得 `string \| null` を enum に  | `record.type as PresetType`                       | **flag**。type guard 関数で narrow する                                           |
| (b) VO 内部値への二重アサーション     | `vo as unknown as Decimal`                        | **flag**。VO に `.toDecimal()` / `.value` アクセサを追加                          |
| (c) Interface 層 string → branded Id   | `(command.wageTypeId as WageTypeId) ?? null`      | **弱めに flag**。VO factory 経由を提案しつつ branded id は許容される場合もある    |
| (d) FW のジェネリック制約             | `name as FieldPathValue<Form, ...>`               | **flag しない**。react-hook-form などの制約上不可避                              |

## 10. 日時

- `new Date()` 禁止。`Time.construct()` / `KeyDate.construct()` を使う
- ISO 経由ではなく `Time.getJapanKeyDate()`
- **dayjs オブジェクトをテンプレートリテラルに直接埋め込まない** — `${time}` は `toString()` 経由でタイムゾーン付き英語日付形式になり、S3 key / ファイル名 / URL など外部キーで壊れる。明示的な `format*` メソッドを使う
- **JST 基準と UTC 基準の混在**: 同一関数内で JST 系 (`todayJst`, `Time.getCurrent()` など) と UTC 系 (`KeyMonth.*` 一部) を混ぜると、JST 深夜 0〜9 時に日付が 1 日ズレる
- TZ 依存でテストが落ちたとき、まず直す先は VO 化 (テストを patch するのではなく)

## 11. Frontend

- **Server Components デフォルト**、`"use client"` はインタラクションの leaf のみ
- ハンドラは `useCallback`
- **controlled form は `createForm` + `zodResolver`**。エラーメッセージは日本語
- **SWR `revalidateOnFocus` の罠**:
  - `isValidating` を loading 条件に使っていると、フォーム編集中のタブ切り替え復帰で Skeleton が瞬間表示 → 初回のみの `isLoading` を使う
  - `useEffect` で SWR data を local state にコピーしていると、編集中の値が無警告でリセットされる
- **feature flag フックの loading 時挙動**: `useIsXxxEnabled` がロード前に `true` を返す実装だと `false` の会社でも enabled 側 UI が一瞬見える。loading 判定を噛ませる
- **jotai イディオム**: `useAtomCallback` は最新値参照用、`useSetAtom` は setter のみ欲しいとき。不要な読み取りで再レンダーを起こさない
- **並列ルート**: web は `@pc` / `@sp`、mobile は 44x44px タッチターゲット
- **承認ワークフロー画面**: 承認後の編集変化を検知する仕組み (`useApprovalChangeDetector` 系) の配線漏れに注意
- **cookie は `cookieManager` 経由**: クライアントから直接 set/get、共通ユーティリティを使う

## 12. Greptile との役割分担

Greptile bot が積極的に拾うもの:

- 型アサーション / 非 null アサーション濫用
- `??` / `||` の混在、`?? 0` による null → 0 誤変換
- JOIN 先テーブルで `deletedAt: null` 欠落
- repository メソッドの `companyId` スコープ漏れ
- `findBy*` / `findManyBy*` 命名違反
- N+1 クエリ
- cross-field validation 不足
- タイムゾーン依存テスト
- `useEffect` フォーム同期アンチパターン
- SWR `revalidateOnFocus` 副作用
- feature flag loading 中の誤 true
- 生 `Error` throw (UsecaseError 未使用)
- 4xx エラーを `Logger.error` で記録
- Migration の件数検証欠落 / 部分インデックス欠落 / FK 制約欠落

**Greptile と重複する指摘は出さない。** 既存 PR コメント (`gh pr view <N> --comments`) を先に読んで、既出なら省く。Dismiss されたまま未対応なら re-raise してよい。

**人間レビュアーが bot の上にのせる価値** (= 本 skill で重点的に狙う層):

- **ドメイン意味論**: 警備業務ルール (シフト締め、深夜跨ぎ割増、keyDate 境界) への適合
- **集約境界・Bounded Context の越境**: 便利に見える既存資産の流用が境界を壊していないか
- **バリデーション配置** (constructor vs create/update)
- **承認 / 編集 / 再承認 workflow の整合**
- **権限追加の横展開完了度** (複数ファイル sweep)
- **リリース / migration 境界データの整合** (警備固有の keyDate / 勤怠締めが絡むと効く)
- **共有マスタの範囲判断** (SharingCompany / Brand / Default の選択)
- **協力会社 ⟷ 自社隊員** など業務主体の対称性

## 13. 避けるべき誤指摘パターン

bot や一般的なレビュアーがやりがちだが、このリポジトリでは却下されているもの:

- **`packages/lib` への共通化提案** — deprecated。共通化先は usecase 配下 (`apps/api/src/usecase/*/shared/`) や呼び出し側近く
- **小規模配列の `useMemo` メモ化提案** — コスト対効果が低く無視されがち
- **全フィールド null のハッピーパステスト追加提案** — 他テストで担保済みのことが多い
- **反射的な "VO にせよ"** — §9 分類表参照。branded id や FW 制約は VO 化が不自然
- **セルフチェックリストの自動生成** — bot が既に生成していて読まれていない。ユーザー明示要求時のみ

## 14. ドメイン語彙 (警備業界)

コード・コメントに登場する文脈語:

- 隊員 (警備員) / 現場 / 配置 / 実績
- 上番 (シフト開始) / 下番 (シフト終了) / 連勤
- 割増 / 法定内労働 / 法定外労働 / 法定休日
- 交通費 / 手当 / 締め (月末締め)
- 苦情処理簿 / 巡察 / 教育
- 1 号警備 = 施設警備
- keyDate = 勤怠 / 給与計算の JST 基準日境界

PR がこれらの概念に触れるとき、コードが現実の業務ルール (日跨ぎの連勤、深夜跨ぎの割増、月末締めの境界) を尊重しているかを確認する。
